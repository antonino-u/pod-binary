//
//  BuildCommand.swift
//  
//
//  Created by Antonino Urbano on 2020-01-13.
//

import Foundation
import Commandant
import PodBinaryKit
import Files

struct BuildCommand: CommandProtocol {
    
    // MARK: - CommandProtocol
    
    let verb = "build"
    let function = "Build all the binaries and bundle resources from a Pods project."
    
    // MARK: - OptionsProtocol
    
    struct Options: OptionsProtocol {
        
        let scheme: String?
        let podsFolder: String
        let project: String?
        let outputDirectory: String
        let buildDirectory: String
        let verbose: Bool
        
        static func create(_ scheme: String?) -> (String) -> (String?) -> (String) -> (String) -> (Bool) -> Options {
            return { podsFolder in { project in { outputDirectory in { buildDirectory in { verbose in Options(scheme: scheme, podsFolder: podsFolder, project: project, outputDirectory: outputDirectory, buildDirectory: buildDirectory, verbose: verbose)} } } } }
        }
        
        static func evaluate(_ mode: CommandMode) -> Result<Options, CommandantError<CommandantError<()>>> {
            
            let defaultPodsDirectory = "/Pods"
            let defaultOutputDirectory = "/PodsBinaries"
            let defaultBuildDirectory = "\(defaultOutputDirectory)/tmp/"
            return create
                <*> mode <| Option(key: "scheme", defaultValue: nil, usage: "REQUIRED: The scheme from the Pods project to build.")
                <*> mode <| Option(key: "podsFolder", defaultValue: FileManager.default.currentDirectoryPath.appending(defaultPodsDirectory), usage: "The folder containing all the pods.")
                <*> mode <| Option(key: "project", defaultValue: nil, usage: "The xcodeproj for your Pods. Default value is <podsFolder>/Pods.xcodeproj.")
                <*> mode <| Option(key: "outputDirectory", defaultValue: FileManager.default.currentDirectoryPath.appending(defaultOutputDirectory), usage: "The output directory (default: \(defaultOutputDirectory)")
                <*> mode <| Option(key: "buildDirectory", defaultValue: FileManager.default.currentDirectoryPath.appending(defaultBuildDirectory), usage: "The build directory (default: \(defaultBuildDirectory)")
                <*> mode <| Switch(key: "verbose", usage: "Enable verbose logs.")
        }
    }
    
    func run(_ options: Options) -> Result<(), CommandantError<()>> {
        
        guard let scheme = options.scheme else {
            return .failure(.usageError(description: "parameter scheme is required."))
        }

        let project = options.project ?? options.podsFolder + "/Pods.xcodeproj"
        
        do {
            let podBinary = PodBinary(podsFolder: try Folder.init(path: options.podsFolder),
                                      project: project,
                                      scheme: scheme,
                                      outputDirectory: try Folder.root.createSubfolderIfNeeded(at: options.outputDirectory),
                                      buildDirectory: try Folder.root.createSubfolderIfNeeded(at: options.buildDirectory),
                                      verbose: options.verbose)
            let result = podBinary.build()
            switch result {
            case .success():
                return .success(())
            case .failure(let error):
                return .failure(.usageError(description: error.message + "\nPlease run 'pod-binary help build' to see the full list of parameters for this command."))
            }
        } catch let error {
            if let error = error as? LocationError {
                return .failure(.usageError(description: "Couldn't create a valid folder reference to \(error.path)."))
            }
            return .failure(.usageError(description: error.localizedDescription))
        }
    }
}
