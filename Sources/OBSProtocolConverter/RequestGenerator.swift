//
//  RequestGenerator.swift
//  OBSProtocolConverter
//
//  Created by Kit Transue on 2022-12-04.
//  Copyright © 2022 Kit Transue
//  SPDX-License-Identifier: Apache-2.0
//

import Foundation

struct RequestGenerator {
    let request: OBSWebservicesDescription.Request
    let fields: [FieldGenerator]
    let responseFields: [FieldGenerator]
    
    enum ReturnKind {
        case noReturn
        case simpleValue(field: FieldGenerator)
        case structReturn
    }
    let returnKind: ReturnKind
    var noReturnValue: Bool { get { if case .noReturn = returnKind {return true } else {return false}}}

    init(request: OBSWebservicesDescription.Request) {
        let hint: String?

        switch request.requestType {
        case "SetSceneItemTransform", "SceneItemTransform":
            hint = "SceneItemTransform"
        case "GetSceneList":
            hint = "IndexedScene"
        case "GetSceneItemList", "GetGroupSceneItemList":
            hint = "SceneSource"
        case "TriggerHotkeyByKeySequence":
            hint = "KeyModifiers"
        default:
            hint = nil
        }
        
        self.request = request
        fields = request.requestFields
            .filter { !$0.valueName.contains(".") }
            .map { FieldGenerator(field: $0, objectHint: hint) }
        responseFields = request.responseFields.map { FieldGenerator(field: $0, objectHint: hint) }
        switch responseFields.count {
        case 0:
            returnKind = .noReturn
        case 1:
            returnKind = .simpleValue(field: responseFields[0])
        default:
            returnKind = .structReturn
        }
    }

    var hasArguments: Bool { get { !fields.isEmpty }}

    var structName: String { get { request.requestType } }
    var enumName: String { get {  Generator.lowerFirst(identifier: request.requestType) } }

    func requestEnum() -> String {
        let associatedValue = hasArguments ? "(\(request.requestType))" : ""
        let docC = Generator.docC(comment: request.description)
        return docC.appending("    case \(enumName)\(associatedValue)\n")
    }

    func requestStruct() -> String {
        guard hasArguments else { return "    // \(structName) takes no arguments\n" }

        // assuming names will be scoped in OBSRequest enum namespace:
        var text = "    public struct \(structName): Codable {\n"
        text.append(fields.map {$0.structField()}.joined(separator: "\n"))
        
        let initFields = fields.map { "\($0.valueName): \($0.type())" }
            .joined(separator: ", ")
        text.append("        public init(\(initFields)) {\n")
        for field in fields {
            text.append("            self.\(field.valueName) = \(field.valueName)\n")
        }
        text.append("        }\n")

        
        text.append("    }\n")
        return text
    }
    
    func codingKey() -> String {
        "    case \(enumName) = \"\(structName)\"\n"
    }
    
    /// Make an async API for this call, with DocC.
    func prettyAPI() -> String {
        var doc = [request.description, ""]
        doc.append(contentsOf: fields.map {$0.paramDocC()})
        if case .simpleValue(let field) = returnKind {
            doc.append("- Returns: \(field.valueDescription)")
        }

        var src = Generator.docC(comment: doc.joined(separator: "\n"))

        // signature, params
        let params = fields.map {$0.decl}.joined(separator: ", ")
        let ret: String
        switch returnKind {
        case .noReturn:
            ret = ""
        case .simpleValue(let field):
            ret = "-> \(field.type()) "
        case .structReturn:
            ret = "-> OBSResponse.\(structName) "
        }
        src.append("    public func \(enumName)(\(params)) async throws \(ret) {\n")

        let assocValue: String
        if hasArguments {
            let xfer = fields.map {$0.paramToInit()}
                .joined(separator: ", ")
            src.append("        let requestData = OBSRequest.\(structName)(\(xfer))\n")
            assocValue = "(requestData)"
        }
        else {
            assocValue = ""
        }
        
        src.append("        let response = try await request(.\(enumName)\(assocValue))\n")
        
        switch returnKind {
        case .noReturn:
            src.append("""
                    guard case .empty = response else {
                        logger.notice("Got wrong response type in reply to \(enumName).")
                        throw(APIError.mismatchedResponse(request: "\(enumName)", got: response))
                    }
                    return
                }
            
            """)
        case .simpleValue(let field):
            src.append("""
                    guard case let .\(enumName)(data) = response else {
                        logger.notice("Got wrong response type in reply to \(enumName).")
                        throw(APIError.mismatchedResponse(request: "\(enumName)", got: response))
                    }
                    return data.\(field.valueName)
                }
            
            """)
        case .structReturn:
            src.append("""
                    guard case let .\(enumName)(data) = response else {
                        logger.notice("Got wrong response type in reply to \(enumName).")
                        throw(APIError.mismatchedResponse(request: "\(enumName)", got: response))
                    }
                    return data
                }
                
            """)
        }
        return src
    }
    

    func requestEncode() -> String {
        let binding = hasArguments ? "(requestData: let requestData)" : ""
        let data = hasArguments ? "\n            try values.encode(requestData, forKey: .requestData)" : ""
        return """
                case .\(enumName)\(binding):
                    try values.encode(Key.\(enumName), forKey: .requestType)\(data)
        
        """
    }
    
    func responseEnum() -> String {
        let associatedValue = noReturnValue ? "" : "(\(structName))"
        let docC = Generator.docC(comment: "Response to \"\(request.description)\"  ")
        return docC.appending("    case \(enumName)\(associatedValue)\n")
    }
    
    func responseStruct() -> String {
        // assuming names will be scoped in OBSResponse enum namespace:
        let name = request.requestType
        guard !noReturnValue else { return "    // \(name) returns no values\n" }
        
        var text = "    public struct \(name): Codable, Sendable {\n"
        text.append(responseFields
            .map { field in
                return field.docC().appending("        public let \(field.valueName): \(field.type())\n")
            }
            .joined(separator: "\n"))
        text.append("    }\n")
        return text
    }
    
    func responseDecode() -> String {
        let responseSetter = noReturnValue ? "                responseData = .empty" : """
                        let reply = try values.decode(OBSResponse.\(structName).self, forKey: .responseData)
                        responseData = .\(enumName)(reply)
        """
        return "            case .\(enumName):\n\(responseSetter)"
    }
}
