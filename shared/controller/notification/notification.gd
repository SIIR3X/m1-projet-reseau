class_name Notification extends Control

# VARIABLES

var text_to_assign: String

@export var wait_time: float = 3.0

@onready var text: Label = %Text
@onready var bar: ProgressBar = %Bar

# ENGINE

func _ready() -> void:
	text.text = text_to_assign
	
	bar.max_value = wait_time
	bar.min_value = 0
	
	bar.value = bar.max_value

func _process(delta: float) -> void:
	# Message disappearance when timer reached end.
	if bar.value == 0:
		queue_free()
	
	bar.value = maxf(bar.value - delta, 0.0)