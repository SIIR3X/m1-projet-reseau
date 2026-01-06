extends Control

var enemy_board: BoardController
var own_board: BoardController

var am_player1: bool

var is_bot_game: bool

@onready var chat_button: Button = %ChatButton
@onready var chat: ChatController = %Chat

static var SHIP_COLORS := {
    1: Color.html("#FFF000"),
    2: Color.html("#00E5FF"),
    3: Color.html("#FF0062"),
    4: Color.html("#00FF38"),
    5: Color.html("#FF8C00")
}

const COLOR_ATTACK_TURN: Color = Color(0.792, 0.074, 0.247)
const COLOR_DEFENSE_TURN: Color = Color(0.173, 0.243, 0.314)
const COLOR_DEFAULT: Color = Color(0.176, 0.176, 0.176)


func get_ship_color(ship_id: int) -> Color:
    return SHIP_COLORS.get(ship_id, Color.YELLOW)


func _ready() -> void:
    chat.visible = false
    chat_button.visible = true
    
    chat_button.pressed.connect(func():
        chat.visible = not chat.visible
    )


func setup_nodes() -> void:
    own_board = $Boards/LeftSide/OwnBoardContainer/OwnBoard
    enemy_board = $Boards/RightSide/EnemyBoardContainer/EnemyBoard

    # Impossible to click my own board
    # Only protection (may improved)
    own_board.disable_interactions()

    var own_label_panel := $Boards/LeftSide/OwnLabelContainer
    var enemy_label_panel := $Boards/RightSide/EnemyLabelContainer

    set_panel_background(own_label_panel, COLOR_DEFAULT)
    set_panel_background(enemy_label_panel, COLOR_DEFAULT)


func initialize_names(name_p1: String, name_p2: String, _am_player1: bool) -> void:
    is_bot_game = (name_p2 == "BOT")

    am_player1 = _am_player1

    var my_name: String
    var enemy_name: String

    if _am_player1:
        my_name = name_p1
        enemy_name = name_p2
    else:
        my_name = name_p2
        enemy_name = name_p1

    $TopBar/PlayerA/Name.text = my_name
    $TopBar/PlayerB/Name.text = enemy_name


func initialize_timers(p1_time: float, p2_time: float) -> void:
    if is_bot_game:
        $TopBar/PlayerA/Timer.visible = false
        $TopBar/PlayerB/Timer.visible = false
        return

    $TopBar/PlayerA/Timer.text = _format_time(p1_time)
    $TopBar/PlayerB/Timer.text = _format_time(p2_time)

    if am_player1:
        _set_active_player(1)
    else:
        _set_active_player(2)


func load_own_board(data: Array) -> void:
    for y in range(data.size()):
        for x in range(data[y].size()):
            var ship_id: int = int(data[y][x])

            if ship_id == 0:
                own_board.set_cell_color(x, y, Color(0.2, 0.4, 1.0)) # Water
            else:
                own_board.set_cell_color(x, y, get_ship_color(ship_id))


func load_enemy_board(shot_history: Array) -> void:
    var my_name : String = $TopBar/PlayerA/Name.text

    for shot in shot_history:
        var shooter_name : String = shot["shooter_name"]
        var x := int(shot["x"])
        var y := int(shot["y"])
        var result := int(shot["result"])
        var sunk: Array = shot["sunk_cells"]
        var ship_id := int(shot["ship_id"])

        if shooter_name == my_name:
            enemy_board.set_cell_result(x, y, result)

            if result == Shot.ShotResult.SUNK:
                var color := get_ship_color(ship_id)
                for cell in sunk:
                    enemy_board.set_cell_color(cell[0], cell[1], color)
        else:
            apply_shot_own_board(x, y, result)


func apply_shot_enemy_board(x: int, y: int, result: int, sunk_cells: Array = [], ship_id: int = -1) -> void:
    enemy_board.set_cell_result(x, y, result)

    if result == Shot.ShotResult.SUNK:
        _color_enemy_sunk_ship(sunk_cells, ship_id)



func apply_shot_own_board(x: int, y: int, _result: int) -> void:
    own_board.set_cell_result(x, y, Shot.ShotResult.HIT)


func _color_enemy_sunk_ship(sunk_cells: Array, ship_id: int) -> void:
    var color: Color = get_ship_color(ship_id)

    for cell in sunk_cells:
        var x := int(cell[0])
        var y := int(cell[1])
        enemy_board.set_cell_color(x, y, color)


func update_timers(p1_time: float, p2_time: float, _am_current_player: bool) -> void:
    var my_time: float
    var enemy_time: float

    if am_player1:
        my_time = p1_time
        enemy_time = p2_time
    else:
        my_time = p2_time
        enemy_time = p1_time

    if _am_current_player:
        _set_active_player(1)
    else:
        _set_active_player(2)

    $TopBar/PlayerA/Timer.text = _format_time(my_time)
    $TopBar/PlayerB/Timer.text = _format_time(enemy_time)


func _format_time(t: float) -> String:
    var s: int = int(t)
    return "%d:%02d" % [s / 60, s % 60]


func _set_active_player(player: int) -> void:
    var green := Color(0.6, 1.0, 0.6)
    var normal := Color(1,1,1)

    $TopBar/PlayerA.modulate = normal
    $TopBar/PlayerB.modulate = normal

    if player == 1:
        $TopBar/PlayerA.modulate = green
    else:
        $TopBar/PlayerB.modulate = green


func set_panel_background(panel: PanelContainer, color: Color) -> void:
    var style := StyleBoxFlat.new()
    style.bg_color = color
    panel.add_theme_stylebox_override("panel", style)


func update_label_backgrounds(is_my_turn: bool) -> void:
    var own_label_panel := $Boards/LeftSide/OwnLabelContainer
    var enemy_label_panel := $Boards/RightSide/EnemyLabelContainer

    if is_my_turn:
        set_panel_background(enemy_label_panel, COLOR_ATTACK_TURN)
        set_panel_background(own_label_panel, COLOR_DEFAULT)
    else:
        set_panel_background(own_label_panel, COLOR_DEFENSE_TURN)
        set_panel_background(enemy_label_panel, COLOR_DEFAULT)


func show_player_disconnected() -> void:
    $DisconnectedOverlay.visible = true
