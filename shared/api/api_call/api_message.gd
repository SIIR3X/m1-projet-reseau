class_name APIMessage extends RefCounted

# CONSTANTS

# Segments.

## Command segment in an API message.
const SEGMENT_COMMAND: String = "command"

## Arguments segment in an API message.
const SEGMENT_ARGS: String = "args"

# VARIABLES

## Original packet message.
var packet_message: PacketMessage

## Data segment of the original packet.
var data: Dictionary = {}

## API command.
var api_command: String = ""

## Arguments.
var arguments: Array = []