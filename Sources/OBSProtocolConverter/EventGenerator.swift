//
//  EventGenerator.swift
//  OBSProtocolConverter
//
//  Created by Kit Transue on 2022-12-25.
//  Copyright © 2022 Kit Transue
//  SPDX-License-Identifier: Apache-2.0
//

import Foundation

struct EventGenerator {
    let event: OBSWebservicesDescription.Event
    let fields: [FieldGenerator]
    
    init(event: OBSWebservicesDescription.Event) {
        self.event = event

        let hint: String?
        switch event.eventType {
        case "SceneItemListReindexed":
            hint = "IndexedSceneItem"

//            SourceFilterListReindexed, SourceFilterCreated(x2), InputCreated(x2?)
            // InputAudioTracksChanged, InputVolumeMeters, SceneItemTransformChanged, SceneListChanged
            // VendorEvent, CustomEvent
        default:
            hint = nil
        }
        
        let replacement: [FieldReplacement]?
        switch event.eventType {
        case "RecordStateChanged":
            replacement = [
                FieldReplacement(name: "outputState", originalType: "String", replacementType: "ObsOutputState"),
//                FieldReplacement(name: "outputPath", originalType: "String", replacementType: "String", valueOptional: true),
                ]
        default:
            replacement = nil
        }
        
        fields = event.dataFields.map{ FieldGenerator(field: $0, objectHint: hint, replace: replacement) }
    }
    
    // FIXME: substantial overlap with response. Refactor.
    func codingKey() -> String {
        "        case \(enumName) = \"\(structName)\"\n"
    }
    
    func eventEnum() -> String {
        let docC = Generator.docC(comment: event.description
            .appending("\n\nDelivered with ``EventSubscription/\(category)`` subscription."))
        let associated = fields.isEmpty ? "" : "(\(structName))"
        return docC.appending("    case \(enumName)\(associated)\n")
    }
    
    func eventDecode() -> String {
        if fields.isEmpty {
            return """
                case .\(enumName):
                    self = .\(enumName)
        """
        }
        
        return """
                case .\(enumName):
                    let data = try values.decode(\(structName).self, forKey: .eventData)
                    self = .\(enumName)(data)
        """
    }
    
    func eventStruct() -> String? {
        guard !fields.isEmpty else {
            return nil
        }
        // assuming names will be scoped in OBSEvent enum namespace:
        let name = event.eventType
        
        var text = "    public struct \(name): Codable, Sendable {\n"
        text.append(fields
            .map { field in
                return field.docC().appending("        public let \(field.valueName): \(field.type())\n")
            }
            .joined(separator: "\n"))
        text.append("    }\n")
        return text
    }
    var structName: String { event.eventType }
    var enumName: String { Generator.lowerFirst(identifier: structName) }
    var category: String { Generator.lowerFirst(identifier: event.eventSubscription) }
}

extension OBSWebservicesDescription.DataField: FieldSpec {
    var valueOptional: Bool {
        valueDescription.contains(OBSWebservicesDescription.nullReturnDocumentation)
    }
}
