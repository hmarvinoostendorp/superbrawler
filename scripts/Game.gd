extends Node2D
## Builds the arena, spawns the two fighters, draws the HUD and runs the
## stock-based match loop. Everything is created in code from primitives.

const ARENA_WIDTH := 1280.0
const ARENA_HEIGHT := 720.0
const FLOOR_Y := 600.0
const WALL_THICKNESS := 40.0

var players: Array[Player] = []
var match_over := false

# HUD nodes, built in _ready.
var _hud: CanvasLayer
var _health_bars := {}     # player_index -> ColorRect (fill)
var _health_labels := {}
var _stock_labels := {}
var _name_labels := {}
var _result_label: Label
var _hint_label: Label


func _ready() -> void:
	_build_arena()
	_spawn_players()
	_build_hud()


func _build_arena() -> void:
	# Background.
	var bg := ColorRect.new()
	bg.color = Color(0.13, 0.14, 0.18)
	bg.size = Vector2(ARENA_WIDTH, ARENA_HEIGHT)
	bg.z_index = -10
	add_child(bg)

	# Floor (visual + collision).
	_add_static_box(
		Vector2(ARENA_WIDTH * 0.5, FLOOR_Y + 40),
		Vector2(ARENA_WIDTH, 80),
		Color(0.30, 0.32, 0.38))
	# Left and right walls keep fighters in the arena.
	_add_static_box(
		Vector2(WALL_THICKNESS * 0.5, ARENA_HEIGHT * 0.5),
		Vector2(WALL_THICKNESS, ARENA_HEIGHT),
		Color(0.22, 0.23, 0.28))
	_add_static_box(
		Vector2(ARENA_WIDTH - WALL_THICKNESS * 0.5, ARENA_HEIGHT * 0.5),
		Vector2(WALL_THICKNESS, ARENA_HEIGHT),
		Color(0.22, 0.23, 0.28))


func _add_static_box(center: Vector2, size: Vector2, col: Color) -> void:
	var body := StaticBody2D.new()
	body.position = center
	body.collision_layer = 1
	body.collision_mask = 0
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	body.add_child(shape)
	var vis := ColorRect.new()
	vis.color = col
	vis.size = size
	vis.position = -size * 0.5
	body.add_child(vis)
	add_child(body)


func _spawn_players() -> void:
	var p1 := Player.new()
	p1.setup(1, GameSettings.p1_character, false, _spawn_point(400.0, GameSettings.p1_character))
	var p2 := Player.new()
	p2.setup(2, GameSettings.p2_character, GameSettings.single_player, _spawn_point(880.0, GameSettings.p2_character))

	p1.opponent = p2
	p2.opponent = p1
	players = [p1, p2]

	for p in players:
		add_child(p)
		p.health_changed.connect(_on_health_changed)
		p.stocks_changed.connect(_on_stocks_changed)
		p.defeated.connect(_on_player_defeated)


func _spawn_point(x: float, char_id: String) -> Vector2:
	# Rest the fighter's base on the floor regardless of its height.
	var h: float = GameSettings.CHARACTERS[char_id]["size"].y
	return Vector2(x, FLOOR_Y - h * 0.5)


# --- HUD -------------------------------------------------------------------

func _build_hud() -> void:
	_hud = CanvasLayer.new()
	add_child(_hud)
	_build_player_hud(players[0], 40, false)
	_build_player_hud(players[1], ARENA_WIDTH - 40 - 360, true)

	_result_label = Label.new()
	_result_label.position = Vector2(0, 250)
	_result_label.size = Vector2(ARENA_WIDTH, 80)
	_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_label.add_theme_font_size_override("font_size", 64)
	_result_label.visible = false
	_hud.add_child(_result_label)

	_hint_label = Label.new()
	_hint_label.position = Vector2(0, 340)
	_hint_label.size = Vector2(ARENA_WIDTH, 40)
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_label.text = "Esc: Menu"
	_hint_label.visible = false
	_hud.add_child(_hint_label)


func _build_player_hud(p: Player, x: float, right_aligned: bool) -> void:
	var name_label := Label.new()
	name_label.position = Vector2(x, 24)
	name_label.size = Vector2(360, 28)
	name_label.text = GameSettings.CHARACTERS[p.character_id]["name"]
	name_label.add_theme_font_size_override("font_size", 22)
	if right_aligned:
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hud.add_child(name_label)
	_name_labels[p.player_index] = name_label

	# Health bar background.
	var bar_bg := ColorRect.new()
	bar_bg.position = Vector2(x, 56)
	bar_bg.size = Vector2(360, 26)
	bar_bg.color = Color(0, 0, 0, 0.5)
	_hud.add_child(bar_bg)

	var bar_fill := ColorRect.new()
	bar_fill.position = Vector2(x, 56)
	bar_fill.size = Vector2(360, 26)
	bar_fill.color = p.color
	_hud.add_child(bar_fill)
	_health_bars[p.player_index] = bar_fill

	var hp_label := Label.new()
	hp_label.position = Vector2(x, 56)
	hp_label.size = Vector2(360, 26)
	hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hp_label.add_theme_font_size_override("font_size", 18)
	_hud.add_child(hp_label)
	_health_labels[p.player_index] = hp_label

	var stock_label := Label.new()
	stock_label.position = Vector2(x, 86)
	stock_label.size = Vector2(360, 24)
	stock_label.add_theme_font_size_override("font_size", 20)
	if right_aligned:
		stock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hud.add_child(stock_label)
	_stock_labels[p.player_index] = stock_label

	_update_health_hud(p)
	_update_stock_hud(p)


func _update_health_hud(p: Player) -> void:
	var frac := clampf(float(p.health) / float(p.max_health), 0.0, 1.0)
	_health_bars[p.player_index].size.x = 360.0 * frac
	_health_labels[p.player_index].text = "%d / %d" % [maxi(p.health, 0), p.max_health]


func _update_stock_hud(p: Player) -> void:
	_stock_labels[p.player_index].text = "Lives: " + "♥".repeat(p.stocks)


func _on_health_changed(p: Player) -> void:
	_update_health_hud(p)


func _on_stocks_changed(p: Player) -> void:
	_update_stock_hud(p)
	_update_health_hud(p)


func _on_player_defeated(loser: Player) -> void:
	if match_over:
		return
	match_over = true
	var winner: Player = players[0] if players[1] == loser else players[1]
	_update_stock_hud(loser)
	_result_label.text = GameSettings.CHARACTERS[winner.character_id]["name"] + " wins!"
	_result_label.visible = true
	_hint_label.text = "Enter: Rematch    Esc: Menu"
	_hint_label.visible = true


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
	elif match_over and event.is_action_pressed("ui_accept"):
		get_tree().reload_current_scene()
