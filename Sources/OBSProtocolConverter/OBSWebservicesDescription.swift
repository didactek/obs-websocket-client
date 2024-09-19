//
//  OBSWebservicesDescription.swift
//  OBSProtocolConverter
//
//  Created by Kit Transue on 2022-11-19.
//  Copyright © 2022 Kit Transue
//  SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct OBSWebservicesDescription: Codable {
    /// Optional values in responses or events are not explicitly indicated by the protocol,
    /// but the description generally describes a null return. Pattern that should identify
    /// these cases.
    static let nullReturnDocumentation = #/`null`|Can be null/#

    public struct EnumCase: Codable {
        let description: String
        let enumIdentifier: String
        let deprecated: Bool
        let enumValue: String
        
        var isReallyDeprecated: Bool { deprecated && !enumIdentifier.hasPrefix("OBS_WEBSOCKET_OUTPUT")}
        
        public init(from decoder: Decoder) throws {
            let container: KeyedDecodingContainer<OBSWebservicesDescription.EnumCase.CodingKeys> = try decoder.container(keyedBy: OBSWebservicesDescription.EnumCase.CodingKeys.self)
            self.description = try container.decode(String.self, forKey: OBSWebservicesDescription.EnumCase.CodingKeys.description)
            self.enumIdentifier = try container.decode(String.self, forKey: OBSWebservicesDescription.EnumCase.CodingKeys.enumIdentifier)
            self.deprecated = try container.decode(Bool.self, forKey: OBSWebservicesDescription.EnumCase.CodingKeys.deprecated)
            
            //
            if let number = try? container.decode(Int.self, forKey: OBSWebservicesDescription.EnumCase.CodingKeys.enumValue) {
                self.enumValue = "\(number)"
            }
            else {
                self.enumValue = try! container.decode(String.self, forKey: OBSWebservicesDescription.EnumCase.CodingKeys.enumValue)
            }
        }
    }
    public struct EnumDefinition: Codable {
        let enumType: String
        let enumIdentifiers: [EnumCase]
    }
    
    let enums: [EnumDefinition]
    
    public struct RequestField: Codable {
        let valueName: String
        let valueType: String
        let valueDescription: String
        let valueOptional: Bool
        // valueRestrictions  ??
        // valueOptionalBehavior  ??
    }
    public struct ResponseField: Codable {
        let valueName: String
        let valueType: String
        let valueDescription: String
    }
    public struct Request: Codable {
        let description: String
        let requestType: String
        let category: String
        let deprecated: Bool
        let requestFields: [RequestField]
        let responseFields: [ResponseField]
    }
    let requests: [Request]
    
    struct DataField: Codable {
        let valueName: String
        let valueType: String
        let valueDescription: String
    }
    
    struct Event: Codable {
        let description: String
        let eventType: String
        let deprecated: Bool
        let dataFields: [DataField]
        let category: String
        let eventSubscription: String
    }
    let events: [Event]
}
