class_name PacketMessage extends RefCounted

# CONSTANTS

# Segments.

## Client ID segment in a message.
const SEGMENT_CLIENT_ID: String = "client_id"

## Type segment in a message.
const SEGMENT_REQUEST_TYPE: String = "type"

## data segment in a message.
const SEGMENT_DATA: String = "data"

# VARIABLES

## ID of the client. Is used on both clients & server.
## The client uses it to embed it in its requests.
## The server uses it to determine to whom the request may be sent.
var client_id: int = -1

## Request type. See constants in [Request].
var type: String = ""

## Data segment.
var data: Variant = null