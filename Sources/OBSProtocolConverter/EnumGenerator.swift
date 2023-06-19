//
//  EnumGenerator.swift
//  OBSProtocolConverter
//
//  Created by Kit Transue on 2022-11-22.
//  Copyright © 2022 Kit Transue
//  SPDX-License-Identifier: Apache-2.0
//

import Foundation


struct EnumGenerator {
    let spec: OBSWebservicesDescription.EnumDefinition
    
    // FIXME: OK to have this here, but express as extension?
    func asSwift() -> String {
        let raw = spec.enumIdentifiers
            .filter { !$0.isReallyDeprecated }
        
        let cases = raw
            .map { asSwift(enumCase: $0 ) }
            .joined(separator: "\n")
        
        // FIXME: should maybe check string/integer is consistent?
        let type = raw.contains(where: { isInt(enumCase: $0) == nil }) ? "String" : "Int"
        
        return """
        public enum \(spec.enumType): \(type), Codable {
        \(cases)
        }
        """
    }

    func isInt(enumCase:  OBSWebservicesDescription.EnumCase) -> Int? {
        if let x = Int(enumCase.enumValue) {
            return x
        }
        return nil
    }
    
    func asSwift(enumCase: OBSWebservicesDescription.EnumCase) -> String {
        guard !enumCase.isReallyDeprecated else { return "" }
        
        let value: String
        if let x = isInt(enumCase: enumCase) {
            value = "\(x)"
        } else {
            value = "\"\(enumCase.enumValue)\""
        }

        return enumCase.docC().appending("    case \(enumCase.swiftName) = \(value)\n")
    }
}
