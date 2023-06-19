//
//  OBSOpCode.swift
//  
//
//  Created by Kit Transue on 2022-09-03.
//  Copyright © 2022 Kit Transue
//  SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SwiftUI


public enum OpCode {
    case hello(Hello)
    case identify(Identify)
    case identified
    case reidentify(Reidentify)
    case event(OBSEvent)
    case request(RequestEnvelope)
    case response(ResponseEnvelope) // aka: requestResponse
    case requestBatch  // FIXME: unsure how to handle
    case requestBatchResponse // FIXME: unsure how to handle
}

public struct Hello: Codable, Equatable {
    public let obsWebSocketVersion: String
    public let rpcVersion: Int
    public let authentication: Authentication?
    
    public struct Authentication: Codable, Equatable {
        public let challenge: String
        public let salt: String
    }
}

public struct Identify: Codable, Equatable {
    public let rpcVersion: Int
    public let authentication: String?
    public let eventSubscriptions: EventSubscription?
    
    public init(rpcVersion: Int, authentication: String?, eventSubscriptions: EventSubscription?) {
        self.rpcVersion = rpcVersion
        self.authentication = authentication
        self.eventSubscriptions = eventSubscriptions
    }
}

public struct Reidentify: Codable, Equatable {
    public let eventSubscriptions: EventSubscription?

    public init(eventSubscriptions: EventSubscription?) {
        self.eventSubscriptions = eventSubscriptions
    }
}


extension OpCode: Codable {
    // ========
    // Three sections of boilerplate for init/encode/OpCodeKey need to be
    // adapted for each OpCode:
    // ========

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try values.decode(WebSocketOpCode.self, forKey: .op)
        
        switch kind {
        case .hello:
            let welcome = try values.decode(Hello.self, forKey: .d)
            self = .hello(welcome)
        case .identify:
            let requirements = try values.decode(Identify.self, forKey: .d)
            self = .identify(requirements)
        case .reidentify:
            let subscriptions = try values.decode(Reidentify.self, forKey: .d)
            self = .reidentify(subscriptions)
        case .identified:
            self = .identified
        case .event:
            let event = try values.decode(OBSEvent.self, forKey: .d)
            self = .event(event)
        case .request:
            throw OBSWebsocketError.requestFromServerUnexpected
        case .requestResponse:
            let response = try values.decode(ResponseEnvelope.self, forKey: .d)
            self = .response(response)
        case .requestBatchResponse:
            throw OBSWebsocketError.unimplemented
        case .requestBatch:
            throw OBSWebsocketError.requestFromServerUnexpected
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        
        try values.encode(op, forKey: .op)
        switch self {
        case .hello(let body):
            try values.encode(body, forKey: .d)
        case .identify(let body):
            try values.encode(body, forKey: .d)
        case .reidentify(let body):
            try values.encode(body, forKey: .d)
        case .identified:
            break
        case .event:
            throw OBSWebsocketError.attemptToSendEventToServer
        case .request(let body):
            try values.encode(body, forKey: .d)
        case .response:
            throw OBSWebsocketError.attemptToSendResponseToServer
        case .requestBatch:
            throw OBSWebsocketError.unimplemented
        case .requestBatchResponse:
            throw OBSWebsocketError.unimplemented
        }
    }
    
    var op: WebSocketOpCode { get {
        switch self {
        case .hello:
            return .hello
        case .identify:
            return .identify
        case .identified:
            return .identified
        case .event:
            return .event
        case .request:
            return .request
        case .response:
            return .requestResponse
        case .reidentify:
            return .reidentify
        case .requestBatch:
            return .requestBatch
        case .requestBatchResponse:
            return .requestBatchResponse
        }}
    }

    // =======
    // Stable: all OpCodes provide only the op code and its associated data:
    // =======
    enum CodingKeys: String, CodingKey {
        case d
        case op
    }
}
