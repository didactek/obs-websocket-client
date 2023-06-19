# ``OBSProtocolConverter``

OBSProtocolConverter is a command-line program for generating Swift source
from the "protocol.json" file provided by OBS that describes the OBS
webservices API.


## Overview

OBSProtocolConverter is designed to be used as a Swift Package Manager
plug-in to generate Swift sources and documentation for Othe BSWebsocket
and OBSAsyncAPI libraries.

OBSProtocolConverter can produce output for:

- OBSWebsocket datatypes (Codable objects for encoding websocket conversations)
- the OBSAsynAPI class OBSClient and its methods that wrap websocket calls
- DocC topics to organize OBSClient methods

## Topics

### Parsing JSON

- ``OBSWebservicesDescription``

### Output

- ``OBSProtocolConverter/OBSProtocolConverter``
- ``Generator``
