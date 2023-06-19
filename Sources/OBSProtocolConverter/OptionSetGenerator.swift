//
//  OptionSetGenerator.swift
//  OBSProtocolConverter
//
//  Created by Kit Transue on 2022-11-24.
//  Copyright © 2022 Kit Transue
//  SPDX-License-Identifier: Apache-2.0
//

import Foundation
import RegexBuilder


struct OptionSetGenerator {
    let spec: OBSWebservicesDescription.EnumDefinition
    var structName: String { spec.enumType }
    
    func asSwift() -> String {
        var statics = ""
        
        for e in spec.enumIdentifiers {
            guard !e.isReallyDeprecated else {continue}

            statics.append("\n")
            statics.append(e.docC())

            statics.append("    public static let \(e.swiftName)")
            if let union = e.isOptionSetStatic() {
                let set = union.map {".\(Generator.lowerFirst(identifier: $0))"}
                    .joined(separator: ", ")
                statics.append(": \(structName) = [ \(set) ]\n")
            }
            else if e.enumValue == "0" {
                statics.append(": \(structName) = []\n")  // empty OptionSet idiomatic zero
            }
            else if let m = e.enumValue.firstMatch(of: shiftExpression) {
                statics.append(" = \(structName)(rawValue: 1 << \(m.1))\n")  // shift OK in OptionSet struct
            }
            else {
                statics.append(" = \(structName)(rawValue: \(e.enumValue))\n")
            }
        }
        return """
            public struct \(spec.enumType): OptionSet, Codable {
                public let rawValue: Int
                public init(rawValue: Int) {
                    self.rawValue = rawValue
                }
            \(statics)
            }
            """
    }
}

private let shiftExpression = Regex {
    // THis is a lot of work just to tidy parens
    "("
    ZeroOrMore(.whitespace)
    "1"
    ZeroOrMore(.whitespace)
    "<<"
    ZeroOrMore(.whitespace)
    // FIXME: name cpature
    Capture {
        OneOrMore(.digit)
    }
    ZeroOrMore(.whitespace)
    ")"
}
