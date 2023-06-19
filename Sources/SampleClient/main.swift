//
//  main.swift
//  
//
//  Created by Kit Transue on 2023-04-17.
//  Copyright © 2023 Kit Transue
//  SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Combine
import OBSAsyncAPI
import DeftLog

var subscriptions = Set<AnyCancellable>()

DeftLog.settings = [("com", .trace)]
let client = OBSClient(port: 4665, password: "TalkToMe", eventSubscriptions: .allLowVolume)

client.events.sink { event in
        switch(event) {
        case .currentPreviewSceneChanged(let info):
            print("Scene changed to \(info.sceneName)")
        default: break
        }
    }
    .store(in: &subscriptions)

try! await client.connect()
let scenes = try! await client.getSceneList()
for scene in scenes.scenes {
    print(scene.sceneName)
}

try await Task.sleep(nanoseconds: 10_000_000_000)
