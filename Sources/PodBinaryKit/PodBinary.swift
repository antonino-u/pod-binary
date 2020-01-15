//
//  PodBinary.swift
//  
//
//  Created by Antonino Urbano on 2020-01-12.
//

import Foundation
import Files
import XCFrameworkKit
import Shell

public struct PodBinary {
    
    let podsFolder: Folder
    let project: String
    let scheme: String
    let outputDirectory: Folder
    let buildDirectory: Folder
    let verbose: Bool
    
    static let podsManifestName = "Manifest.lock"
    static let xcframeworksOutputDirectoryName = "XcodeFrameworks"
    static let bundlesOutputDirectoryName = "Bundles"
    static let cacheOutputDirectoryName = "Cache"
    
    func xcframeworksOutputDirectory() throws -> Folder {
        
        let result = try outputDirectory.createSubfolderIfNeeded(at: Self.xcframeworksOutputDirectoryName)
        try? result.subfolders.delete()
        return result
    }
    
    func bundlesOutputDirectory() throws -> Folder {
        
        let result = try outputDirectory.createSubfolderIfNeeded(at: Self.bundlesOutputDirectoryName)
        try? result.subfolders.delete()
        return result
    }
    
    func cacheOutputDirectory() throws -> Folder {
        
        let result = try outputDirectory.createSubfolderIfNeeded(at: Self.cacheOutputDirectoryName)
        try? result.subfolders.delete()
        return result
    }
    
    public init(podsFolder: Folder, project: String, scheme: String, outputDirectory: Folder, buildDirectory: Folder, verbose: Bool) {
        
        self.podsFolder = podsFolder
        self.project =  project
        self.scheme = scheme
        self.outputDirectory = outputDirectory
        self.buildDirectory = buildDirectory
        self.verbose = verbose
    }
    
    public func build() -> Result<(), GenericError> {
        
        guard let xcframeworksOutputDirectory = try? self.xcframeworksOutputDirectory() else {
            return .failure(GenericError(message: "Couldn't create frameworks output directory"))
        }
        
        guard let bundlesOutputDirectory = try? self.bundlesOutputDirectory() else {
            return .failure(GenericError(message: "Couldn't create bundle output directory"))
        }
        
        guard let cacheOutputDirectory = try? self.cacheOutputDirectory() else {
            return .failure(GenericError(message: "Couldn't create cache output directory"))
        }
        
        guard let podsManifest = try? self.podsFolder.file(at: Self.podsManifestName) else {
            return .failure(GenericError(message: "Couldn't find \(Self.podsManifestName) in \(self.podsFolder.path)"))
        }
        
        do {
            //If the cache exists and is valid, restore it and return success
            let cache = Cache(baseFolder: cacheOutputDirectory)
            if cache.isValid(comparedToPodsManifest: podsManifest) {
                print("Cache is valid, restoring...")
                try cache.restore(cache: .xcframeworks, to: xcframeworksOutputDirectory)
                try cache.restore(cache: .bundles, to: bundlesOutputDirectory)
                print("Restored cache! Done!")
                return .success(())
            } else {
                print("Cache is invalid, rebuilding...")
            }
            
            var archives: [XCFrameworkKit.Archive]
            
            //Create all the archives and put the xcframeworks into xcframeworksOutputDirectory
            print("Building the Pods scheme \(self.scheme) and moving the frameworks into the frameworks output folder...")
            
            let createXCFrameworks = XCFrameworkBuilder { (builder) in
                
                builder.project = self.project
                builder.iOSScheme = self.scheme
                builder.outputDirectory = xcframeworksOutputDirectory.path
                builder.buildDirectory = self.buildDirectory.path
                builder.verbose = self.verbose
                builder.keepArchives = true
            }
            
            switch createXCFrameworks.build() {
            case .success(let resultingArchives):
                archives = resultingArchives
            case .failure(let error):
                return .failure(GenericError(message: error.description))
            }
            
            //Extract all the .bundles from the first archive (they should be the same regarless of architecture since they're resources) and copy them to xcframeworksOutputDirectory
            print("Moving the compiled xcframeworks to the xcframeworks output folder...")
            
            if let archive = archives.first {
                let productsPath = archive.path + "/Products/" + XCFrameworkBuilder.archiveInstallPath
                let productsFolder = try Folder(path: productsPath)
                try productsFolder.copySubfolders(recursively: false, toFolder: bundlesOutputDirectory, withCondition: Folder.extensionCondition(withExtension: ".bundle"))
            }
            
            //Extract all the .bundles from the Pods folder and copy them to bundleOutputDirectory
            print("Moving the pre-compiled bundles from the Pods folder to the bundles output folder...")
            try podsFolder.copySubfolders(recursively: true, toFolder: bundlesOutputDirectory, withCondition: Folder.extensionCondition(withExtension: ".bundle"))
            
            //Backup the created things
            try? cacheOutputDirectory.files.delete()
            try? cacheOutputDirectory.subfolders.delete()
            try cache.save(location: xcframeworksOutputDirectory, toCache: .xcframeworks)
            try cache.save(location: bundlesOutputDirectory, toCache: .bundles)
            try cache.save(location: podsManifest, toCache: .podsManifest)
            
            //Delete the xcarchives that XCFrameworkBuilder created
            print("Cleaning up...")
            try? buildDirectory.delete()
        } catch let error {
            if let error = error as? LocationError {
                return .failure(GenericError(message: "Folder error: path '\(error.path)' gave error \(error.description)"))
            } else if let error = error as? GenericError {
                return .failure(error)
            }
            return .failure(GenericError(message: error.localizedDescription))
        }
        
        return .success(())
    }
}
