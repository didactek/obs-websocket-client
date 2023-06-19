//
//  OBSWebsocketError.swift
//  
//
//  Created by Kit Transue on 2022-12-28.
//  Copyright © 2022 Kit Transue
//  SPDX-License-Identifier: Apache-2.0
//

import Foundation

public enum OBSWebsocketError: Error {
    case requestError(RequestStatus)
    case requestFromServerUnexpected
    case attemptToSendResponseToServer
    case attemptToSendEventToServer
    case unimplemented
    case codingError
    case identifiedResponse(id: String, encapsulatedError: Error)
}
