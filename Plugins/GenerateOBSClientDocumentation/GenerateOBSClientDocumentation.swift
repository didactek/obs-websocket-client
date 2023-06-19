//
//  GenerateOBSClientDocumentation.swift
//  
//
//  Created by Kit Transue on 2023-05-06.
//  Copyright © 2023 Kit Transue
//  SPDX-License-Identifier: Apache-2.0
//

import Foundation
import PackagePlugin

enum PluginError: Error {
    case platform(String)
    case converting(String)
}

@main
struct GenerateOBSClientDocumentation: CommandPlugin {
    func performCommand(context: PackagePlugin.PluginContext, arguments: [String]) async throws {
        guard #available(macOS 13.0, *) else {
            throw PluginError.platform("Plugin can only be built on macOS 13+")
        }

        let converter = try context.tool(named: "OBSProtocolConverter")
        let executable = URL(filePath: converter.path.string)
        let inputFile = context.package.directory.appending(subpath: "Sources/OBSProtocolConverter/protocol.json")
        
        let targets = try context.package.targets(named: ["OBSAsyncAPI"])
        for target in targets {
            guard let target = target as? SourceModuleTarget else {
                continue
            }
            
            let doccDir = target.directory.appending(["OBSAsyncAPI.docc"])

            let process = try Process.run(executable, arguments: [
                "docc",
                "\(inputFile)",
                "\(doccDir)"
            ])
            
            process.waitUntilExit()
            
            if process.terminationReason == .exit && process.terminationStatus == 0 {
                    print("Generated DocC in \(doccDir).")
                }
                else {
                    let problem = "\(process.terminationReason):\(process.terminationStatus)"
                    throw PluginError.converting("Formatting invocation failed: \(problem)")
                }
        }
    }
}
