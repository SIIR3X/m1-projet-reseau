class_name BoardController extends GridContainer

# VARIABLES

## Size of the board.
@export var board_size_on_startup: int = 10
@export_file("*.tscn") var button_template: String

# ENGINE

func _ready() -> void:
	var button_scene: PackedScene = load(button_template)
	columns = board_size_on_startup

	for i in range(board_size_on_startup * board_size_on_startup):
		var x: int = i / board_size_on_startup
		var y: int = i % board_size_on_startup

		var button: Button = button_scene.instantiate()
		button.pressed.connect(_on_cell_pressed.bind(x, y))
		add_child(button)

	remove_button_focus_visuals()


# METHODS

## Gets the button at the desired coordinates.
func get_button(x: int, y: int) -> Button:
	assert(x >= 0 && x < board_size_on_startup, "x out of bound")
	assert(y >= 0 && y < board_size_on_startup, "y out of bound")
	
	return get_child(x * board_size_on_startup + y) as Button


func disable_interactions() -> void:
	for i in range(get_child_count()):
		var btn := get_child(i)
		if btn is Button:
			btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
			btn.focus_mode = Control.FOCUS_NONE


func remove_button_focus_visuals() -> void:
	for i in get_child_count():
		var btn := get_child(i)
		if btn is Button:
			btn.focus_mode = Control.FOCUS_NONE
			btn.mouse_filter = Control.MOUSE_FILTER_PASS


func set_cell_color(x: int, y: int, color: Color) -> void:
	var button := get_button(x, y)
	if button:
		button.modulate = color


func reset_cell_color(x: int, y: int) -> void:
	var button := get_button(x, y)
	if button:
		button.modulate = Color(1, 1, 1)


func set_cell_result(x: int, y: int, result: int) -> void:
	var button := get_button(x, y)
	if button == null:
		return

	# After a shot, disable the button to prevent from shooting it back
	button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.focus_mode = Control.FOCUS_NONE

	match result:
		Shot.ShotResult.MISS:
			button.modulate = Color(0.2, 0.4, 1.0)  # Blue
		Shot.ShotResult.HIT:
			button.modulate = Color(1.0, 0.0, 0.0)  # Red
		_:
			button.modulate = Color.BLACK           # Default case


func _on_cell_pressed(x: int, y: int) -> void:
	# Send a shot to the server
	API.send(
		SendableAPIMessage.new(
			"Player.hit",
			[float(x), float(y)]
		)
	)
