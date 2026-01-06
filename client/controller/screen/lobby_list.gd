extends Control

# VARIABLES

@export_file("*.tscn") var return_scene: String
@export_file("*.tscn") var game_scene: String
@export_file("*.tscn") var party_creation_scene: String

@export var party_list_item_canvas: PackedScene

@onready var return_button: Button = %ReturnButton

@onready var refresh_button: Button = %RefreshButton

@onready var create_party_button: Button = %CreatePartyButton
@onready var party_code_box: LineEdit = %PartyCode

@onready var loading_label: Label = %LoadingLabel
@onready var no_party_label: Label = %NoPartyLabel

@onready var party_scroll: ScrollContainer = %PartyScroll
@onready var party_list: VBoxContainer = %PartyList

@onready var fetch_timer: Timer = %FetchTimer

# ENGINE

func _ready() -> void:
	# Binding.
	return_button.pressed.connect(_on_return_button_pressed)
	refresh_button.pressed.connect(_on_refresh_pressed)
	create_party_button.pressed.connect(_on_party_creation)
	
	# Lobby binding.
	LobbyService.party_list_received.connect(_on_party_list_received)
	LobbyService.created_party_status.connect(_on_party_created)
	
	# Early request.
	fetch_timer.timeout.connect(_on_refresh_pressed)
	_on_refresh_pressed()

# METHODS.

func _create_list_item(party: Party) -> LobbyListItem:
	var item: LobbyListItem = party_list_item_canvas.instantiate()
	
	# Parenting is required to load @onready fields !
	party_list.add_child(item)

	# Player info.	
	item.player_name.text = party.creator_name
	
	# Show the code if needed
	if not party.password.is_empty():
		item.party_code_box.visible = true
	
	return item

# CALLBACKS

func _on_return_button_pressed() -> void:
	get_tree().change_scene_to_file(return_scene)

func _on_party_creation() -> void:
	LobbyService.create_party(party_code_box.text)	

func _on_party_created(status: bool) -> void:
	# True means created.
	if status:
		get_tree().change_scene_to_file(party_creation_scene)

func _on_party_join(party_id: int, password_box: LineEdit) -> void:
	# If the box is passed, that means the password is necessary. If the text is empty, doesn't send anything.
	if password_box != null:
		# Password required
		if password_box.text.is_empty():
			return
		LobbyService.join_party(party_id, password_box.text)
	else:
		# No password required
		LobbyService.join_party(party_id, "")

func _on_refresh_pressed() -> void:
	loading_label.visible = true
	party_scroll.visible = false
	no_party_label.visible = false
	
	LobbyService.fetch_list()

func _on_party_list_received(list: Array[Party]) -> void:
	# Disables loading text.
	loading_label.visible = false

	# Clearing old parties in the list.
	for elm: Node in party_list.get_children():
		elm.queue_free()
	
	# No item in list.
	if list.size() == 0:
		party_scroll.visible = false
		no_party_label.visible = true
	
	# There are parties in said list.
	else:
		# Generates all children per game.
		for party: Party in list:
			var item: LobbyListItem = _create_list_item(party)
			item.join_button.pressed.connect(_on_party_join.bind(
				party.id, 
				null if party.password.is_empty() else item.party_code_box
			))
		
		no_party_label.visible = false
		party_scroll.visible = true
