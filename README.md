# obs-websocket-client

Swift libraries for communicating with OBS Studio. Supports both Codable serialization
and an async/await calling pattern.

## Overview

obs-websocket-client includes two libraries for working with OBS
Studio from Swift. The libraries are clients of v5.x of
[obs-websocket](https://github.com/obsproject/obs-websocket).

OBSWebsocket is a set of JSON-Codable datatypes to
support communicating with an OBS server using the obs-websocket
protocol.

OBSAsyncAPI is a wrapper for OBS requests that takes care of managing
the request ID and routes the OBS response as a return from the async
request call. OBSAsyncAPI includes a Combine publisher for OBS events.

Both libraries are generated from the OBS
[JSON API description](https://github.com/obsproject/obs-websocket/blob/master/docs/generated/protocol.json)
and include DocC from the protocol specification.

## OBSAsyncAPI usage

Requests are made using a functional pattern:

```swift
import Foundation
import OBSAsyncAPI

let client = OBSClient(port: 4655, password: "abc")
try! await client.connect()
let scenes = try! await client.getSceneList()
for scene in scenes.scenes {
    print(scene.sceneName)
}
```

Events can be monitored using a Combine subscribe pattern:

```swift
import Foundation
import Combine
import OBSAsyncAPI

var subscriptions = Set<AnyCancellable>()

let client = OBSClient(port: 4655, password: "abc",
                       eventSubscriptions: .allLowVolume)

client.events.sink { event in
        switch(event) {
        case .currentPreviewSceneChanged(let info):
            print("Scene changed to \(info.sceneName)")
        default: break
        }
    }
    .store(in: &subscriptions)

try! await client.connect()

// Listen a little bit for messages
try await Task.sleep(nanoseconds: 10_000_000_000)
```

## Documentation

- [DocC for OBSAsyncAPI](https://didactek.github.io/obs-websocket-client/OBSAsyncAPI/documentation/obsasyncapi)
- [DocC for OBSWebsocket](https://didactek.github.io/obs-websocket-client/OBSWebsocket/documentation/obswebsocket)


## Plugin

obs-websocket-client is built around OBSProtocolConverter, which generates
Swift code from the OBS protocol.json specification. The converter is called
as a plugin in two contexts:

- build plugin: converts protocol.json into structure and async helpers
- command: to write topics DocC to the repository

The DocC topic organization should be checked in for release versions.
To update the topic organization extension, run:

```
swift package plugin extract-obsclient-docc-extension
```


## Swift Package Manager

The libraries are available as Swift Package Manager packages.

In the <code>Package.swift</code> package dependencies, import the
package:

```swift
.package(url: "https://github.com/didactek/obs-websocket-client.git", from: "1.0.0"),
```

For each target that uses a library, identify the library from obs-websocket-client
as a dependency for the target:

```swift
.product(name: "OBSAsyncAPI", package: "obs-websocket-client"),
```


## License

Apache 2.0.


## Acknowledgments

Omar at ObscuredPixel for an excellent example of
[adapting Apple's websockets to async/await](https://obscuredpixels.com/awaiting-websockets-in-swiftui).

Rudrank Riyam has a really clear
[write-up of Codable and JSON](https://blog.logrocket.com/simplify-json-parsing-swift-using-codable/#dynamic-objects-example)
that helped me with building and parsing the exchanged websocket messages.

And of course: the OBS Project for making the incredibly useful,
inspiring, and open source [OBS Studio](https://obsproject.com).
