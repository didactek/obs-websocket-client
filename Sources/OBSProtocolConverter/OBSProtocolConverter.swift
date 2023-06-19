//
//  OBSProtocolConverter.swift
//  OBSProtocolConverter
//
//  Created by Kit Transue on 2022-11-18.
//  Copyright © 2022 Kit Transue
//  SPDX-License-Identifier: Apache-2.0
//

import Foundation

@main
public struct OBSProtocolConverter {
    enum CommandlineError: Error {
        case wrongArguments(String)
    }
    public static func main() throws {
        // FIXME: is ArgumentParser worth the dependency?
        guard CommandLine.arguments.count == 4 else {
            throw CommandlineError.wrongArguments("websocket|asyncapi|docc jsonInput outputDirectory")
        }
        
        let subcommand = CommandLine.arguments[1]
        let specURL = URL(filePath: CommandLine.arguments[2])
        let outputDirectory = CommandLine.arguments[3]
        
//        let specURL = Bundle.module.url(forResource: "protocol", withExtension: "json")!
        let specJSON = try Data(contentsOf: specURL)

        let generator = Generator(json: specJSON, outputDirectory: outputDirectory)

        switch subcommand {
        case "websocket":
            generator.writeWebsocketFiles()
        case "asyncapi":
            generator.writeAPIFiles()
        case "docc":
            generator.writeDocC()
        default:
            throw CommandlineError.wrongArguments("Unknown subcommand \(subcommand)")
        }
    }
}

