# ``OBSWebsocket``

Swift JSON-Codable datatypes to support communicating with an OBS
server using the obs-websocket protocol.

## Overview

OBSWebsocket maps obs-websocket messages to Swift datatypes (structs, enums, etc.).

The datatypes:

- follow Swift case conventions
- support Swift idioms like OptionSet or enumerations with associated values
- conform to Codable
- serialize matching obs-websocket keys
- are largely generated from the protocol.json provided by the obs-websocket project
- provide DocC documentation (carried from the obs-websocket project where possible)
- have some additional semantic typing in special cases

## Specializations

In limited cases, OBSWebsocket provides more type detail than described
in the obs-websocket protocol.json.

obs-webserver sometimes describes entities as having a generic type "Object".

This may simplify describing the interface where covariants are
required (the entity may have different fields depending on circumstance).
There may be cases where the fields cannot be known to the API definition
("what fields are required to describe this camera source?"), so this
flexibility is necessary.

As implementor and user, I have found other cases where the implementation
seems stable/consistent enough to allow a static definition. In these cases,
having a type with semantic fields saves a lot of work--both in writing code
and in looking through obs-websocket source to find the particular value
used by an enumeration. I have extended some types to encode what I discovered
from this research.

- Note: Specialized type descriptions may not be complete, or stable, or
otherwise useful. Please report limitations or errors to this project.

See ``SceneItemTransform`` (and ``ItemAlignment``) as an example.

<!--## Topics-->
<!---->
<!--### <!--@START_MENU_TOKEN@-->Group<!--@END_MENU_TOKEN@-->-->
<!---->
<!--- <!--@START_MENU_TOKEN@-->``Symbol``<!--@END_MENU_TOKEN@-->-->
