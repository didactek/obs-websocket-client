//
//  GenerateOBSWebServices.swift
//  
//
//  Created by Kit Transue on 2022-11-19.
//  Copyright © 2022 Kit Transue
//  SPDX-License-Identifier: Apache-2.0
//

import PackagePlugin
import Foundation

@main
struct GenerateOBSWebservices: BuildToolPlugin {
    // A Build Tool is most approriate: we know exactly what files
    // we will be generating, and we know our input file.
    //
    // We do want to generate DocC, though, and I'm not sure how/if the DocC
    // can be included. I guess we find out....
    func createBuildCommands(context: PackagePlugin.PluginContext, target: PackagePlugin.Target) async throws -> [PackagePlugin.Command] {
        
        guard let target = target as? SourceModuleTarget else {
            // This does *not* appear to be where DocC shows up.
            return []
        }

        let inputFile = context.package.directory.appending(subpath: "Sources/OBSProtocolConverter/protocol.json")
        
        switch target.name {
        case "OBSWebsocket":
            let outputs = [
                "OBSEvent.swift",
                "OBSRequest.swift",
                "OBSResponse.swift",
                "OBSWSTypes.swift",
                "RequestCodingKey.swift",
                "RequestEnvelopeEncode.swift",
                "ResponseEnvelopeDecode.swift",
            ].map { context.pluginWorkDirectory.appending($0) }
            return [ .buildCommand(displayName: "",
                                   executable: try context.tool(named: "OBSProtocolConverter").path,
                                   arguments: ["websocket",
                                               "\(inputFile)",
                                               "\(context.pluginWorkDirectory)"],
                                   inputFiles: [inputFile],
                                   outputFiles: outputs),
            ]
        case "OBSAsyncAPI":
            let outputs = [
                "OBSAsyncAPIExtensions.swift",
                // "OBSAsyncAPI.docc/OBSClient.md",  // FIXME: generated DocC is not incorporated into documentation
            ].map { context.pluginWorkDirectory.appending($0) }
            return [ .buildCommand(displayName: "",
                                   executable: try context.tool(named: "OBSProtocolConverter").path,
                                   arguments: ["asyncapi",
                                               "\(inputFile)",
                                               "\(context.pluginWorkDirectory)"],
                                   inputFiles: [inputFile],
                                   outputFiles: outputs)
            ]
        default:
            return []
        }
    }
}
