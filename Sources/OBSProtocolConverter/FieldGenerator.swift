//
//  FieldGenerator.swift
//  OBSProtocolConverter
//
//  Created by Kit Transue on 2022-12-04.
//  Copyright © 2022 Kit Transue
//  SPDX-License-Identifier: Apache-2.0
//

import Foundation

protocol FieldSpec {
    var valueDescription: String {get}
    var valueName: String {get}
    var valueType: String {get}
    var valueOptional: Bool {get}
}

extension OBSWebservicesDescription.ResponseField: FieldSpec {
    var valueOptional: Bool { get { false } }
}

extension OBSWebservicesDescription.RequestField: FieldSpec {
}

struct FieldReplacement {
    let name: String
    /// For validation; abort if the spec has changed
    let originalType: String
    let replacementType: String
    let valueOptional: Bool
    
    init(name: String, originalType: String, replacementType: String, valueOptional: Bool = false) {
        self.name = name
        self.originalType = originalType
        self.replacementType = replacementType
        self.valueOptional = valueOptional
    }
}

struct ReplacedField: FieldSpec {
    let valueDescription: String
    let valueName: String
    let valueType: String
    let valueOptional: Bool
    
    init(original: FieldSpec, replacement: FieldReplacement) {
        guard replacement.originalType == original.valueType else {
            fatalError("Field \(original.valueName) no longer described by OBS as having type \(replacement.originalType)")
        }
        
        valueDescription = original.valueDescription
        valueName = original.valueName
        valueType = replacement.replacementType
        valueOptional = replacement.valueOptional
    }
}

struct FieldGenerator {
    let field: FieldSpec
    let objectHint: String
    
    var valueName: String { get { field.valueName }}
    var valueType: String { get { field.valueType }}
    var valueDescription: String { get { field.valueDescription }}
    var valueOptional: Bool { get { field.valueOptional }}

    var decl: String { get { "\(field.valueName): \(type())" } }
    
    init(field: FieldSpec, objectHint: String?, replace: [FieldReplacement]? = nil) {
        if let replacement = replace?.first(where: {field.valueName == $0.name}) {
            self.field = ReplacedField(original: field, replacement: replacement)
        }
        else {
            self.field = field
        }
        self.objectHint = objectHint ?? "OBSUntypedObject"
    }
    
    func structField() -> String {
        var text = docC()
        text.append("        public let \(decl)\n")
        return text
    }
    
    func paramToInit() -> String {
        "\(field.valueName): \(valueName)"
    }
    
    func docC() -> String {
        Generator.docC(comment: valueDescription, indentLevel: 2)
    }
            
    func paramDocC() -> String {
        "- Parameter \(valueName): \(valueDescription)"
    }
    
    func type() -> String {
        let baseType: String
        
        switch(valueType) {
            // not worth being clever; just enumerate all options:
        case "Any":
            baseType = "OBSUntypedObject"
        case "Array<Object>":
            baseType = "[\(objectHint)]"
        case "Array<String>":
            baseType = "[String]"
        case "Boolean":
            baseType = "Bool"
        case "Number":
            // This is going to take some heuristics:
            // - if name ends in 'Id', then Number is probably an Int
            // - lots of things may be Ints instead of Doubles
            // - the API might be better in seconds than ms?
            if valueName.hasSuffix("Id") || valueName.contains("Index") {
                // Probably an index
                baseType = "Int"
            }
            else {
                baseType = "Double"
            }
        case "Object":
            baseType = objectHint
        case "String":
            baseType = "String"
        default:
            // Presumably overridden using ReplacedField
            // fatalError("Unexpected type \(valueType)")
            baseType = valueType

        }

        return baseType . appending(valueOptional ? "?" : "")
    }
}

