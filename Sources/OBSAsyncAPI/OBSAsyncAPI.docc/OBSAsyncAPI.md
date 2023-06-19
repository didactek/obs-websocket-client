 # ``OBSAsyncAPI``

A Swift async interface to OBS using OBS Websockets.

## Overview

OBSAsyncAPI provides an idiomatic Swift interface to an
underlying, strongly-typed OBSWebsocket implementation.

OBS requests are made using async/try await on ``OBSClient`` methods.
While the calling function waits, the framework sends the message to
the OBS server, then returns to monitoring the messages from OBS.
Once the response corresponding to the request arrives, the framework
continues the waiting function with the result from the server.

An OBSClient object also provides ``OBSClient/events``, which is a
Combine publisher for subscribed OBS events.


## Usage

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

## Types

Both events and request responses are communicated by the API as structs
defined and documented in the OBSWebsocket module.

In general, these are structs with fields that correspond to the fields
described in obs-websocket documentation.

### "OBSUntypedObject"

The obs-websocket describes some values as having type "Object": these
are JSON dictionaries where no commitment is made by the OBS specification about
the names of the keys, the types for values, or consistency of representation
from call to call.

"Object" is used in request arguments, request responses, and in events.

The OBSWebsocket module hardcodes additional knowledge about some of
these cases, and tries to use richer, full-typed structs where possible. 

In all other cases, the API uses OBSUntypedObject to represent these objects.
OBSUntypedObject represents the nested/hierarchical key/value dictionaries
typical of obs-websocket Object types.


## Requests

### Parse errors

If the OBS response to a request can't be parsed, the response
JSON text is included in a 
``APIError/jsonParseError(encapsulateError:source:)`` exception object.
The implementor may catch this exception and parse the JSON on their own.

This pattern gives the implementor a chance to soften any
brittleness that comes with the strongly-typed API.

### Limitations

Batch requests (and their responses) are not implemented.


## Events

Events are published on the ``OBSClient/events`` attribute.

### Event Example

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

## Logging

OBSAsyncAPI uses DeftLog to set its log level on startup. The identifier for
all messages is "com.didactek.obswebsocket".

DeftLog uses an ordered configuration that associates identifier prefixes
with a log level.
To use DeftLog, set this <code>DeftLog.settings</code> configuration before
libraries start requesting their loggers.

```swift
import DeftLog

@main
struct StudioClientApp: App {
    let obs: OBSClient
    init() {
        DeftLog.settings = [
            ("com.didactek.obswebsocket", .trace),
            ("com.didactek", .debug),
        ]
	obs = OBSClient(port: 4655, password: "abc")
    }
}
```


## Topics

### Client

- ``OBSClient``
