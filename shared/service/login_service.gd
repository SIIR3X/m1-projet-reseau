extends Service

# CONSTANTS.

## Section for users.
const SECTION_USERS: String = "users"

## Section for credentials.
const SECTION_CREDENTIALS: String = "credentials"

## Username field.
const FIELD_CREDENTIAL_USER: String = "user"

## Password field.
const FIELD_CREDENTIAL_PASSWORD: String = "password"

## Name of DB.
const DB_NAME: String = "server_users_db.cfg"

## Name of credentials.
const CREDENTIALS_NAME: String = "credentials.cfg"

# SIGNALS

## Whenever an account got logged-in.
signal user_connected(id: int, account_name: String)

## Whenever an account got disconnected.
signal user_disconnected(id: int)

# ENGINE

func _ready() -> void:
	# Editor check.
	if not is_in_editor():
		# Creates config file if non-existent.
		var cfg: ConfigFile = ConfigFile.new()
		
		# For server, it's the DB path
		if is_server():
			var path: String = get_exec_dir().path_join(DB_NAME)
		
			var err: Error = cfg.load(path)
			if err == Error.ERR_FILE_NOT_FOUND and not is_in_editor():
				cfg.save(path)
				
		# For client, it's the credentials one
		else:
			# When the client is connected to the server, sends stored credentials.
			NetworkService.client_connection.connected_to_server.connect(_on_connected_to_server, CONNECT_ONE_SHOT)
			
			# When the user disconnects, remove the credentials.
			user_disconnected.connect(_on_user_disconnected)
		

# METHODS

## Makes account login for client.
func make_login_attempt(username: String, password: String) -> void:
	# Makes API call.
	var ret: SendableAPIMessage = SendableAPIMessage.new("Login.login", [username, password])
	API.send(ret, -1, NetworkService.TransmissionMethod.METHOD_UDP)
	
	# Binds to user_connected with the passed password to automatically write the credentials..
	if not is_in_editor() and not user_connected.is_connected(_on_sent_credentials_response):
		user_connected.connect(_on_sent_credentials_response.bind(password), CONNECT_ONE_SHOT)

## Makes account signup for client.
func make_signup_attempt(username: String, password: String) -> void:
	# Makes API call.
	var ret: SendableAPIMessage = SendableAPIMessage.new("Login.signup", [username, password])
	API.send(ret, -1, NetworkService.TransmissionMethod.METHOD_UDP)
	
## Makes account logout for client.
func make_logout_attempt() -> void:
	# Makes API call.
	var ret: SendableAPIMessage = SendableAPIMessage.new("Login.logout", [])
	API.send(ret, -1, NetworkService.TransmissionMethod.METHOD_UDP)

## Hashes passwords based on SHA-256.
func hash_password(password: String) -> String:
	# Fetches the result.
	return str(password.hash())

## Adds user to DB.
func _add_user_to_db(username: String, password_hash: String) -> Error:
	# Loads the UsersDB.
	var db: ConfigFile = ConfigFile.new()
	var path: String = get_exec_dir().path_join(DB_NAME)
	
	# Verifies file existence.
	var err: Error = db.load(path)
	
	# Return in case of error.
	if err != Error.OK:
		return err
	
	# Sets value.
	db.set_value(SECTION_USERS, username, password_hash)
	
	# Saves.
	return db.save(path)	

## Loads the users DB.
func _load_users_db() -> Dictionary[String, UserEntry]:
	# Loads the UsersDB.
	var db: ConfigFile = ConfigFile.new()
	var path: String = get_exec_dir().path_join(DB_NAME)
	
	# Verifies file existence.
	if db.load(path) != Error.OK:
		return {}
	
	# No users.
	if not db.has_section(SECTION_USERS):
		return {}
	
	var res: Dictionary[String, UserEntry] = {}
	
	for username: String in db.get_section_keys(SECTION_USERS):
		var passhash: String = db.get_value(SECTION_USERS, username, "")
		
		# If no value (shouldn't happen) we continue.
		if passhash.is_empty():
			continue
		
		# We bind in the dict result.
		var entry: UserEntry = UserEntry.new(username, passhash)
		res[username] = entry
	
	return res

## Server account login API command.
func _server_account_login(player: Player, username: String, password: String) -> void:
	# Someone is already connected under those credentials.
	if Players.get_player_by_username(username):
		return

	# Fetch the db.
	var db: Dictionary[String, UserEntry] = _load_users_db()
	
	# Finds the current username login attempt.
	var entry: UserEntry = db.get(username)
	
	# The account doesn't exist or the password doesn't match..
	if not entry or not entry.password_match(password):
		NotificationService.make_show_request(player.peer_id, "Identifiants ou mot-de-passe invalide")
		return
	
	# Gives login capabilities.
	player.name = username
	player.is_logged_in = true
	
	# If the player was in a game, try to reconnect it
	GameService.on_player_reconnected(player)

	# Sends back a message to the client.
	var ret: SendableAPIMessage = SendableAPIMessage.new("Login.login", [username])
	API.send(ret, player.peer_id, NetworkService.TransmissionMethod.METHOD_UDP)
	
	# Emits signal : successful account login.
	user_connected.emit(player.peer_id)

func _server_account_logout(player: Player) -> void:
	player.name = "Player_%d" % player.peer_id
	player.is_logged_in = false
	
	# Sends back a message to the client.
	var ret: SendableAPIMessage = SendableAPIMessage.new("Login.login", [""])
	API.send(ret, player.peer_id, NetworkService.TransmissionMethod.METHOD_UDP)
	
	# Emits signal.
	user_disconnected.emit(player.peer_id)

## Account creation requests.
func _server_account_signup(player: Player, username: String, password: String) -> void:
	# Fetch the db.
	var db: Dictionary[String, UserEntry] = _load_users_db()
	
	# The account already exist.
	if db.get(username):
		NotificationService.make_show_request(player.peer_id, "Identifiant déjà pris")
		return
		
	# Adds the user.
	_add_user_to_db(username, password)
	NotificationService.make_show_request(player.peer_id, "Compte créé avec succès")

## Client receives the API command confirmation.
func _client_account_login(username: String) -> void:
	Players.is_logged_in = not username.is_empty()
	Players.local_name = username

	# Emit the proper.
	if Players.is_logged_in:
		NotificationService.show_message("Connecté au compte %s" % username)
		user_connected.emit(NetworkService.client_connection.client_id, username)
	else:
		NotificationService.show_message("Déconnecté du compte %s" % username)
		user_disconnected.emit(NetworkService.client_connection.client_id)

# CALLBACKS

func _on_sent_credentials_response(_id: int, username: String, password: String) -> void:
	# Saves credentials within file.
	var cfg: ConfigFile = ConfigFile.new()
	var path: String = get_exec_dir().path_join(CREDENTIALS_NAME)
	
	cfg.set_value(SECTION_CREDENTIALS, FIELD_CREDENTIAL_USER, username)
	cfg.set_value(SECTION_CREDENTIALS, FIELD_CREDENTIAL_PASSWORD, password)
	
	cfg.save(path)

func _on_user_disconnected(_id: int) -> void:
	# Clears credentials automatically.
	var cfg: ConfigFile = ConfigFile.new()
	var path: String = get_exec_dir().path_join(CREDENTIALS_NAME)

	# Cannot open.
	if cfg.load(path) != Error.OK:
		return
	
	# Erases values.
	cfg.erase_section_key(SECTION_CREDENTIALS, FIELD_CREDENTIAL_USER)
	cfg.erase_section_key(SECTION_CREDENTIALS, FIELD_CREDENTIAL_PASSWORD)
	
	cfg.save(path)

func _on_connected_to_server() -> void:
	# Sends credentials automatically.
	var cfg: ConfigFile = ConfigFile.new()
	var path: String = get_exec_dir().path_join(CREDENTIALS_NAME)

	# Cannot open.
	if cfg.load(path) != Error.OK:
		return
	
	# Reads values.
	var user: String = cfg.get_value(SECTION_CREDENTIALS, FIELD_CREDENTIAL_USER, "")
	var password: String = cfg.get_value(SECTION_CREDENTIALS, FIELD_CREDENTIAL_PASSWORD, "")
	
	# Invalid.
	if user.is_empty() or password.is_empty():
		return
	
	# Sending login request.
	make_login_attempt(user, password)
