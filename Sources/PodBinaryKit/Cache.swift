//
//  File.swift
//  
//
//  Created by Antonino Urbano on 2020-01-15.
//

import Foundation
import Files
import Shell

enum CacheType: CaseIterable {
    
    case xcframeworks
    case bundles
    case podsManifest
    
    var compressed: Bool {
        
        switch self {
            
        case .xcframeworks, .bundles:
            return true
        case .podsManifest:
            return false
        }
    }
    
    var cachedFolderName: String {
        
        switch self {
        case .xcframeworks:
            return PodBinary.xcframeworksOutputDirectoryName
        case .bundles:
            return PodBinary.bundlesOutputDirectoryName
        case .podsManifest:
            return "Manifest.lock"
        }
    }
    
    var cacheName: String {
        
        switch self {
        case .xcframeworks:
            return PodBinary.xcframeworksOutputDirectoryName + ".tar.gz"
        case .bundles:
            return PodBinary.bundlesOutputDirectoryName + ".tar.gz"
        case .podsManifest:
            return "Manifest.lock"
        }
    }
    
    func exists(baseFolder: Folder) -> Bool {
        
        (try? baseFolder.file(at: self.cacheName)) != nil
    }
    
    func path(with baseFolder: Folder) -> String {
        
        baseFolder.path + self.cacheName
    }
}

struct Cache {
    
    private let fileManager = FileManager()
    
    let baseFolder: Folder
    
    func isValid(comparedToPodsManifest podsManifest: File) -> Bool {
        
        //check if all the caches exist
        for cache in CacheType.allCases {
            if !cache.exists(baseFolder: self.baseFolder) {
                return false
            }
        }
        guard let cachedPodsManifest = try? File(path: CacheType.podsManifest.path(with: self.baseFolder)) else {
            return false
        }
        
        let diffResult = shell.usr.bin.diff.dynamicallyCall(withArguments: ["\"" + cachedPodsManifest.path + "\"", "\"" + podsManifest.path + "\""])
        return diffResult.isSuccess
    }
    
    func save<T: Location>(location: T, toCache type: CacheType) throws {
        
        try? (try? Folder(path: type.path(with: self.baseFolder)))?.delete()
        let cachePath = type.path(with: self.baseFolder)
        
        print("Caching \(location.path) to \(cachePath)")
        
        if type.compressed {
            let arguments = ["-zcvf", "\"" + cachePath + "\"", "-C", "\"" + (location.parent?.path ?? "") + "\"", type.cachedFolderName]
            let result = shell.usr.bin.tar.dynamicallyCall(withArguments: arguments)
            if !result.isSuccess {
                throw GenericError(message: "Error: \(result.stderr)\nThe failed command was: shell.usr.bin \(arguments.joined(separator: " "))")
            }
        } else {
            let source = location as? File
            try source?.copy(to: self.baseFolder)
        }
    }
    
    func restore<T: Location>(cache type: CacheType, to folder: T) throws {
        
        let failure = { print("Couldn't restore cache \(type) to \(folder.path)") }
        
        guard let cachedLocation = try? File(path: type.path(with: self.baseFolder)) else {
            
            return failure()
        }
        
        switch type {
        case .xcframeworks, .bundles:
            let arguments = ["-zxvf", "\"" + cachedLocation.path + "\"", "-C", "\"" + (self.baseFolder.parent?.path ?? "") + "\""]
            let result = shell.usr.bin.tar.dynamicallyCall(withArguments: arguments)
            if !result.isSuccess {
                throw GenericError(message: "Error: \(result.stderr)\nThe failed command was: shell.usr.bin \(arguments.joined(separator: " "))")
            }
        case .podsManifest:
            break;
        }
    }
}
