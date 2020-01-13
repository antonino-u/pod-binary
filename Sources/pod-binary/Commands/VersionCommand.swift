//
//  VersionCommand.swift
//  
//
//  Created by Antonino Urbano on 2020-01-12.
//

import Foundation
import Commandant
import PodBinaryKit

struct VersionCommand: CommandProtocol {
    // MARK: - CommandProtocol

    let verb = "version"
    let function = "Display the current version of pod-binary"

    func run(_ options: NoOptions<CommandantError<()>>) -> Result<(), CommandantError<()>> {
        print(Version.current.value)
        return .success(())
    }
}
