//
//  RequestEnvelope.swift
//
//
//  Created by Kit Transue on 2022-12-28.
//  Copyright © 2022 Kit Transue
//  SPDX-License-Identifier: Apache-2.0
//

public struct RequestEnvelope {
    public let request: OBSRequest
    public let id: String
    
    public init(request: OBSRequest, id: String) {
        self.request = request
        self.id = id
    }
}
