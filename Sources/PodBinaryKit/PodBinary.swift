//
//  PodBinary.swift
//  
//
//  Created by Antonino Urbano on 2020-01-12.
//

import Foundation
import Files
import XCFrameworkKit

public struct PodBinary {
    
    let podsFolder: Folder
    let project: String
    let scheme: String
    let outputDirectory: Folder
    let buildDirectory: Folder
    let verbose: Bool
    
    func xcframeworksOutputDirectory() throws -> Folder {
        
        let result = try outputDirectory.createSubfolderIfNeeded(at: "XcodeFrameworks")
        try? result.subfolders.delete()
        return result
    }
    
    func bundlesOutputDirectory() throws -> Folder {
        
        let result = try outputDirectory.createSubfolderIfNeeded(at: "Bundles")
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
                
        var archives: [Archive]
        
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
        
        do {
            
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
            
        } catch let error {
            if let error = error as? LocationError {
                return .failure(GenericError(message: "Folder error: path '\(error.path)' gave error \(error.description)"))
            }
            return .failure(GenericError(message: error.localizedDescription))
        }
        
        return .success(())
    }
}
