//
//  File.swift
//  
//
//  Created by Antonino Urbano on 2020-01-13.
//

import Foundation
import Files

extension Folder {
    
    typealias FolderCondition = ((Folder) -> Bool)
    static func extensionCondition(withExtension extension: String) -> FolderCondition {
        
        let `extension` = `extension`.hasPrefix(".") ? String(`extension`.dropFirst()) : `extension`
        return { (folder: Folder) in
            folder.extension == `extension`
        }
    }
    
    func findSubfolder(recursively: Bool, withCondition condition: FolderCondition) -> [Folder] {
        
        var folders = [Folder]()
        let subfolders = recursively ? self.subfolders.recursive : self.subfolders
        subfolders.forEach { (folder) in
            
            if condition(folder) {
                folders.append(folder)
            }
        }
        return folders
    }
    
    func copySubfolders(recursively: Bool, toFolder destination: Folder, withCondition condition: FolderCondition) throws {
        
        let folders = self.findSubfolder(recursively: recursively, withCondition: condition)
        for folder in folders {
            try folder.copy(to: destination)
        }
    }
}
