//
//  SpecExtensions.swift
//  OBSProtocolConverter
//
//  Created by Kit Transue on 2022-11-24.
//  Copyright © 2022 Kit Transue
//  SPDX-License-Identifier: Apache-2.0
//

import Foundation
import RegexBuilder

extension OBSWebservicesDescription.EnumCase {
    func isOptionSetStatic() -> [String]? {
        // FIXME: items like "(General | Config | Scenes | Inputs | Transitions | Filters | Outputs | SceneItems | MediaInputs | Vendors | Ui)" will need to be re-expressed as statics; need plan for this.
        let regex = Regex {
            Capture {
                ZeroOrMore(.word)
            }
            ZeroOrMore(.whitespace)
            "|"
            ZeroOrMore(.whitespace)
            Capture {
                OneOrMore(.word)
            }
            ZeroOrMore(.whitespace)
        }
        
        let matches = enumValue.matches(of: regex)
        guard !matches.isEmpty else {
            return nil
        }
        return matches.flatMap { match in
            [ String(match.1), String(match.2) ]
                .filter { !$0.isEmpty }
        }
    }
    
    func docC() -> String {
        return Generator.docC(comment: description)
    }
    
    var swiftName: String { get {
        if enumIdentifier.hasPrefix("OBS_WEBSOCKET_OUTPUT_") {
            return enumIdentifier.replacingOccurrences(of: "OBS_WEBSOCKET_OUTPUT_", with: "").lowercased()
        }
        return Generator.lowerFirst(identifier: enumIdentifier)
    }}
}


extension OBSWebservicesDescription.EnumDefinition {
    func mayBeOptionSet() -> Bool {
        for e in enumIdentifiers {
            if e.isOptionSetStatic() != nil {
                return true
            }
        }
        return false
    }
    
    func isDeprecated() -> Bool {
        !enumIdentifiers.contains { !$0.isReallyDeprecated }
    }
}
