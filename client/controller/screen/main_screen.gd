extends Control

# VARIABLES

@export_file("*.tscn") var on_play_scene: String

@onready var play_button: Button = %PlayButton
@onready var quit_button: Button = %QuitButton

@onready var login_popup: LoginPopup = %LoginPopup
@onready var signup_popup: LoginPopup = %SignupPopup

@onready var username_text: Label = %Username
@onready var login_button: Button = %LoginButton
@onready var signup_button: Button = %SignupButton
@onready var logout_button: Button = %LogoutButton

# ENGINE

func _ready() -> void:
	# Event binding.
	quit_button.pressed.connect(_on_quit_pressed)
	play_button.pressed.connect(_on_play_pressed)
	
	login_button.pressed.connect(_on_login_pressed)
	signup_button.pressed.connect(_on_signup_pressed)
	logout_button.pressed.connect(_on_logout_pressed)
	
	# Login popup bindings.
	login_popup.on_submit.connect(_on_login_request)
	login_popup.on_cancel.connect(_on_login_cancel)
	login_popup.close_requested.connect(_on_login_cancel)
	
	# Signup popup bindings.
	signup_popup.on_submit.connect(_on_signup_request)
	signup_popup.on_cancel.connect(_on_signup_cancel)
	signup_popup.close_requested.connect(_on_signup_cancel)
	
	if Players.is_logged_in:
		_show_connected_interface()
	else:
		_show_not_connected_interface()

# METHODS

func _show_connected_interface() -> void:
	# Disassemblies
	username_text.text = Players.local_name
	play_button.disabled = false
	
	(login_button.get_parent() as Control).visible = false
	(logout_button.get_parent() as Control).visible = true
	
	LoginService.user_disconnected.connect(func(_id: int):
		_show_not_connected_interface()
	
	, CONNECT_ONE_SHOT)

func _show_not_connected_interface() -> void:
	# Disassemblies
	(logout_button.get_parent() as Control).visible = false
	(login_button.get_parent() as Control).visible = true
	
	username_text.text = ""
	play_button.disabled = true

	LoginService.user_connected.connect(func(_id: int, _username: String):
		_show_connected_interface()
		
	, CONNECT_ONE_SHOT)	

# CALLBACKS

func _on_play_pressed() -> void:
	# User is connected.
	get_tree().change_scene_to_file(on_play_scene)

func _on_login_pressed() -> void:
	if not Players.is_logged_in:
		login_popup.visible = true

func _on_login_request(username: String, password: String) -> void:
	LoginService.make_login_attempt(username, LoginService.hash_password(password))
	_on_login_cancel()

func _on_login_cancel() -> void:
	login_popup.visible = false
	login_popup.clear_fields()

func _on_signup_pressed() -> void:
	if not Players.is_logged_in:
		signup_popup.visible = true

func _on_signup_request(username: String, password: String) -> void:
	LoginService.make_signup_attempt(username, LoginService.hash_password(password))
	_on_signup_cancel()

func _on_signup_cancel() -> void:
	signup_popup.visible = false
	signup_popup.clear_fields()

func _on_logout_pressed() -> void:
	if Players.is_logged_in:
		LoginService.make_logout_attempt()

func _on_quit_pressed() -> void:
	get_tree().quit()
