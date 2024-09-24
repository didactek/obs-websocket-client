//
//  Generator.swift
//  OBSProtocolConverter
//
//  Created by Kit Transue on 2022-11-22.
//  Copyright © 2022 Kit Transue
//  SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct Generator {
    let spec: OBSWebservicesDescription
    let requestGenerators: [RequestGenerator]
    let eventGenerators: [EventGenerator]
    let outputDirectory: URL
    
    public init(json: Data, outputDirectory: String) {
        self.outputDirectory = URL(filePath: outputDirectory)

        let decoder = JSONDecoder()
        spec = try! decoder.decode(OBSWebservicesDescription.self, from: json)
        requestGenerators = spec.requests.filter { r in !r.deprecated }
            .map { RequestGenerator(request: $0) }
        eventGenerators = spec.events
            .filter { !$0.deprecated }
            .map { EventGenerator(event: $0) }
    }
    
    func writeFile(filename: String, _ source: String...) {
        let copyright: String
        if filename.hasSuffix(".md") {
            // DocC doesn't like it when the comment precedes the heading
            copyright = ""
        } else {
            copyright = """
            //
            // \(filename)
            //
            // Generated from docs/generated/protocol.json
            // https://github.com/obsproject/obs-websocket
            //
            
            
            """
        }

        let body = source.joined(separator: "\n\n")
        let full = copyright.appending(body)
        
        let url = outputDirectory.appending(path: filename)
        try! full.write(to: url, atomically: false, encoding: .utf8)
    }
    
    
    public func writeWebsocketFiles() {
        writeFile(filename: "OBSWSTypes.swift", wsTypes())
        writeFile(filename: "RequestCodingKey.swift", requestCodingKeys())
        
        writeFile(filename: "OBSEvent.swift", events())
        
        writeFile(filename: "OBSRequest.swift", requests())
        
        writeFile(filename: "RequestEnvelopeEncode.swift", requestEncode())
        
        writeFile(filename: "OBSResponse.swift", responses())
        writeFile(filename: "ResponseEnvelopeDecode.swift", responseDecode())
    }

    /// Write API extensions.
    ///
    /// - note: OBSClient DocC is processed in non-target pass and must be updated in Source tree.
    public func writeAPIFiles() {
        writeFile(filename: "OBSAsyncAPIExtensions.swift", apiAdapters())
    }
    
    /// Write DocC topic sections for OBSClient.
    public func writeDocC() {
        writeFile(filename: "OBSClient.md", docCTopics())
    }
    
    func wsTypes() -> String {
        spec.enums
            .filter { !$0.isDeprecated() }
            .map { $0.mayBeOptionSet()
                ? OptionSetGenerator(spec: $0).asSwift()
                : EnumGenerator(spec: $0).asSwift()}
            .joined(separator: "\n\n").appending("\n")
    }
    
    func events() -> String {
        var src = "public enum OBSEvent: Sendable {\n"
        src.append(eventGenerators.map{$0.eventEnum()}.joined(separator: "\n"))
        src.append(eventGenerators.compactMap{$0.eventStruct()}.joined(separator: "\n"))
        src.append("}\n")
        src.append("""
            extension OBSEvent: Decodable {
                enum CodingKeys: String, CodingKey {
                    case eventType
                    case eventData
                }
                enum EventTypeKeyword: String, Codable {

            """)
        src.append(eventGenerators.map { $0.codingKey() }.joined())
        src.append("    }\n")
        
        src.append("""
            public init(from decoder: Decoder) throws {
                let values = try decoder.container(keyedBy: CodingKeys.self)
                let kind = try values.decode(EventTypeKeyword.self, forKey: .eventType)
                
                switch kind {
        
        """)
        src.append(eventGenerators.map { $0.eventDecode() }.joined(separator: "\n"))
        src.append("""
        
                }
            }
        }
        
        """)
        return src
    }
    
    func requests() -> String {
        var src = "public enum OBSRequest {\n"
        src.append(requestGenerators
            .map {$0.requestEnum()}
            .joined(separator: "\n")
        )
        
        src.append("\n\n")

        // supporting structures:
        src.append(requestGenerators.map {$0.requestStruct()}.joined(separator: "\n"))

        src.append("}  // END enum OBSRequest\n")
        return src
    }
    
    func responses() -> String {
        var src = "public enum OBSResponse: Sendable {\n    case empty\n\n"

        src.append(requestGenerators.map {$0.responseEnum()}.joined(separator: "\n"))
        
        src.append("\n\n")

        // supporting structures:
        src.append(requestGenerators.map {$0.responseStruct()}.joined(separator: "\n"))

        src.append("}  // END enum OBSResponse\n")
        return src
    }
    
    func requestCodingKeys() -> String {
        var src = "enum RequestCodingKey: String, Codable {\n"
        src.append( requestGenerators
            .map {$0.codingKey()}
            .joined()
        )
        src.append("}\n")
        return src
    }
    
    func requestEncode() -> String {
        let boilerplate = requestGenerators.map {$0.requestEncode()}
                .joined()
        
        return """
        extension RequestEnvelope: Encodable {
            enum RequestKeys: String, CodingKey {
                case requestType
                case requestId
                case requestData
            }
            public func encode(to encoder: Encoder) throws {
                var values = encoder.container(keyedBy: RequestKeys.self)
                
                try values.encode(id, forKey: .requestId)
                
                typealias Key = RequestCodingKey
                switch request {
        \(boilerplate)
                }
            }
        }
        
        """
    }
    
    func responseDecode() -> String {
        let boilerplate = requestGenerators.map { $0.responseDecode() }
            .joined(separator: "\n")
        
        return """
        extension ResponseEnvelope: Decodable {
            enum ResponseKeys: String, CodingKey {
                case requestType
                case requestId
                case requestStatus
                case responseData
            }
        
            public init(from decoder: Decoder) throws {
                let values = try decoder.container(keyedBy: ResponseKeys.self)
                let id = try values.decode(String.self, forKey: .requestId)
                do {
                    let kind = try values.decode(RequestCodingKey.self, forKey: .requestType)

                    enum StatusKeys: String, CodingKey {
                        case code
                        // case result
                    }
                    let requestStatus = try values.nestedContainer(keyedBy: StatusKeys.self, forKey: .requestStatus)
                    let status = try requestStatus.decode(RequestStatus.self, forKey: .code)
                    guard case .success = status else {
                        throw OBSWebsocketError.requestError(status)
                    }
            
                    let responseData: OBSResponse
            
                    switch(kind) {
            \(boilerplate)
                    }
                    self.init(response: responseData, id: id)
                }
                catch {
                    throw OBSWebsocketError.identifiedResponse(id: id, encapsulatedError: error)
                }
            }
        }
        
        """
    }
    
    func apiAdapters() -> String {
        let functions = requestGenerators.map { $0.prettyAPI() }
            .joined(separator: "\n")
        return """
        import OBSWebsocket
        
        extension OBSClient {
        \(functions)
        }
        
        """
    }
    
    func docCTopics() -> String {
        var topicCatalog = [String: [RequestGenerator]]()
        
        for request in requestGenerators {
            let key = request.request.category
            if topicCatalog[key] == nil {topicCatalog[key] = []}
            topicCatalog[key]!.append(request)
        }
        
        var markdown = """
        # ``OBSAsyncAPI/OBSClient``

        ## Topics

        ### Connecting

        - ``init(hostname:port:connectTimeout:password:eventSubscriptions:)``
        - ``connect()``
        - ``isConnected``
        - ``connectTimeout``

        ### Events

        - ``events``
        - ``eventSubscriptions``
        """
        for (topic, requests) in topicCatalog {
            let pretty: String
            if topic.count <= 3 {
                pretty = topic.uppercased()
            } else {
                let singular = topic.dropLast(topic.hasSuffix("s") ? 1 : 0)
                pretty = singular.capitalized
            }
            
            markdown.append("\n\n### \(pretty) Requests\n\n")
            for request in requests {
                let parms = request.fields.map {"\($0.valueName):"}.joined()
                markdown.append("- ``\(request.enumName)(\(parms))``\n")
            }
        }
        return markdown
    }
    
    /// Convert comment into DocC block.
    ///
    /// - Parameter comment: Text to be turned into a documentation comment.
    /// - Parameter indentLevel: Number of 4-space indents to prefix to each line of comment text.
    static func docC(comment: String, indentLevel: Int = 1) -> String {
        let prefix = String(repeating: " ", count: 4 * indentLevel).appending("/// ")
        return comment
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map { prefix.appending($0) }
            .joined(separator: "\n")
            .appending("\n")
    }
    
    static func lowerFirst(identifier: String) -> String {
        "\(identifier.first!.lowercased())\(identifier.dropFirst())"
    }
}
