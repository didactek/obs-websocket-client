//
//  OBSUntypedObject.swift
//  
//
//  Created by Kit Transue on 2022-12-27.
//  Copyright © 2022 Kit Transue
//  SPDX-License-Identifier: Apache-2.0
//

import Foundation

// FIXME: should this be deprecated or hidden?
// Concern about surfacing it in the APIs: it's weird.
// Alternate implementation: simply throw the JSON for
// all cases that return Object; accept JSON (and convert
// implicitly to this weird to facilitate injection into encoding)
// where needed for arguments.
//
// Arguments for keeping:
// - it provides a restricted structure for creating these things
// - users could convert to JSON and then pull whatever they want using Encodable
// - could provide a "recast as" function using JSON to map..


/// Value for ``OBSUntypedObject`` dictionaries.
public enum OBSUntypedValue: Codable {
    case string(String)
    case number(Double)
    case nested(OBSUntypedObject)
    
    public init(from decoder: Decoder) throws {
        let single = try! decoder.singleValueContainer()
        if let num = try? single.decode(Double.self) {
            self = .number(num)
        }
        else if let str = try? single.decode(String.self) {
            self = .string(str)
        }
        else if let nested = try? single.decode(OBSUntypedObject.self) {
            self = .nested(nested)
        }
        else {
            throw OBSWebsocketError.codingError
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let str):
            try container.encode(str)
        case .number(let num):
            try container.encode(num)
        case .nested(let nested):
            try container.encode(nested)
        }
    }
}

/// Dictionary of String to Number/String/hierarchical Dictionary, used by OBS to
/// convey variant return types or "Object" references that are not strongly-typed
/// in the API specification.
public typealias OBSUntypedObject = [String: OBSUntypedValue]
