class_name LoginPopup extends Window

# VARIABLES

@export var is_login: bool = true

@onready var username_box: LineEdit = %UsernameBox
@onready var password_box: LineEdit = %PasswordBox

@onready var cancel_button: Button = %CancelButton
@onready var login_button: Button = %LoginButton

# SIGNALS

signal on_submit(username: String, password: String)
signal on_cancel()

# ENGINE

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	login_button.text = "Login" if is_login else "Sign up"

	login_button.pressed.connect(_on_login)
	cancel_button.pressed.connect(_on_cancel)

# METHODS

## Clears texts.
func clear_fields() -> void:
	username_box.text = ""
	password_box.text = ""

# CALLBACK

## When the login button is clicked.
func _on_login() -> void:
	if username_box.text.is_empty():
		NotificationService.show_message("Le nom d'utilisateur ne peut pas être vide")
		return
		
	if password_box.text.is_empty():
		NotificationService.show_message("Le mot-de-passe ne peut pas être vide")
		return
	
	on_submit.emit(username_box.text, password_box.text)

## When the cancel button is clicked.
func _on_cancel() -> void:
	on_cancel.emit()
