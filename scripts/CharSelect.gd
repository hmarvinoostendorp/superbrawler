extends Control
## Character select. Each player cursors through the roster and confirms.
## In single player, P1 picks both fighters in turn (theirs, then the AI's).

const ROSTER := ["red", "blue", "green"]

# Per-player selection index into ROSTER and confirmation state.
var sel := [0, 1]
var confirmed := [false, false]
var single_player := false

# UI references, one entry per panel.
var _name_labels := []
var _stat_labels := []
var _status_labels := []
var _swatches := []     # Polygon2D
var _panels := []       # background ColorRect
var _last_sel := [-1, -1]

var _title: Label
var _hint: Label


func _ready() -> void:
	single_player = GameSettings.single_player
	# Sensible defaults (and never start both on the same pick by accident).
	sel = [0, 1]

	_title = _make_label("CHOOSE YOUR FIGHTER", 48, HORIZONTAL_ALIGNMENT_CENTER)
	_title.position = Vector2(0, 50)
	_title.size = Vector2(1280, 60)
	add_child(_title)

	_build_panel(0, 220.0, "Player 1")
	_build_panel(1, 700.0, ("CPU" if single_player else "Player 2"))

	_hint = _make_label("", 22, HORIZONTAL_ALIGNMENT_CENTER)
	_hint.position = Vector2(0, 640)
	_hint.size = Vector2(1280, 30)
	add_child(_hint)

	_refresh_all()


func _build_panel(i: int, x: float, who: String) -> void:
	var panel := ColorRect.new()
	panel.position = Vector2(x, 150)
	panel.size = Vector2(360, 440)
	panel.color = Color(0, 0, 0, 0.25)
	add_child(panel)
	_panels.append(panel)

	var who_label := _make_label(who, 26, HORIZONTAL_ALIGNMENT_CENTER)
	who_label.position = Vector2(x, 165)
	who_label.size = Vector2(360, 32)
	add_child(who_label)

	# Shape swatch, centered in the upper area of the panel.
	var swatch := Polygon2D.new()
	swatch.position = Vector2(x + 180, 320)
	add_child(swatch)
	_swatches.append(swatch)

	var name_label := _make_label("", 30, HORIZONTAL_ALIGNMENT_CENTER)
	name_label.position = Vector2(x, 400)
	name_label.size = Vector2(360, 36)
	add_child(name_label)
	_name_labels.append(name_label)

	var stat_label := _make_label("", 18, HORIZONTAL_ALIGNMENT_CENTER)
	stat_label.position = Vector2(x, 440)
	stat_label.size = Vector2(360, 110)
	add_child(stat_label)
	_stat_labels.append(stat_label)

	var status_label := _make_label("", 24, HORIZONTAL_ALIGNMENT_CENTER)
	status_label.position = Vector2(x, 552)
	status_label.size = Vector2(360, 30)
	add_child(status_label)
	_status_labels.append(status_label)


func _make_label(text: String, font_size: int, align: int) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.horizontal_alignment = align
	return l


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		_on_cancel()
		return

	if single_player:
		# P1 drives panel 0, then panel 1, using the P1 controls.
		if not confirmed[0]:
			_handle_panel(0, "p1")
		elif not confirmed[1]:
			_handle_panel(1, "p1")
	else:
		_handle_panel(0, "p1")
		_handle_panel(1, "p2")

	_refresh_all()

	if confirmed[0] and confirmed[1]:
		_start_match()


func _handle_panel(i: int, prefix: String) -> void:
	if confirmed[i]:
		return
	var n := ROSTER.size()
	if Input.is_action_just_pressed(prefix + "_left"):
		sel[i] = (sel[i] - 1 + n) % n
	if Input.is_action_just_pressed(prefix + "_right"):
		sel[i] = (sel[i] + 1) % n
	if Input.is_action_just_pressed(prefix + "_attack") \
			or Input.is_action_just_pressed(prefix + "_jump"):
		confirmed[i] = true


func _on_cancel() -> void:
	# Step back one confirmation, or leave to the menu if nothing is locked in.
	if confirmed[1]:
		confirmed[1] = false
	elif confirmed[0]:
		confirmed[0] = false
	else:
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")


func _refresh_all() -> void:
	for i in 2:
		_refresh_panel(i)
	if single_player:
		_hint.text = "P1: A/D choose, F/W confirm  •  Pick your fighter, then the CPU's  •  Esc back"
	else:
		_hint.text = "P1: A/D + F confirm    P2: ←/→ + (/ or Enter) confirm    Esc back"


func _refresh_panel(i: int) -> void:
	var char_id: String = ROSTER[sel[i]]
	var data: Dictionary = GameSettings.CHARACTERS[char_id]

	_name_labels[i].text = data["name"]
	_name_labels[i].add_theme_color_override("font_color", data["color"])

	var dmg: int = data["attack_damage"]
	var text := "Speed: %d\nAttack: %d frames\nReach: %d\nDamage: %d" % [
		int(data["move_speed"]), int(data["attack_frames"]),
		int(data["attack_reach"]), dmg]
	var dr: float = data.get("damage_reduction", 0.0)
	if dr > 0.0:
		text += "\nArmor: %d%% less damage" % int(round(dr * 100.0))
	_stat_labels[i].text = text

	if confirmed[i]:
		_status_labels[i].text = "READY"
		_status_labels[i].add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
		_panels[i].color = Color(0.15, 0.35, 0.15, 0.5)
	else:
		var active := _is_panel_active(i)
		_status_labels[i].text = "◄ choose ►" if active else "..."
		_status_labels[i].add_theme_color_override("font_color", Color.WHITE)
		_panels[i].color = Color(0.2, 0.2, 0.3, 0.5) if active else Color(0, 0, 0, 0.25)

	# Rebuild the swatch only when the pick changed.
	if _last_sel[i] != sel[i]:
		_last_sel[i] = sel[i]
		_swatches[i].polygon = _display_points(char_id)
		_swatches[i].color = data["color"]


func _is_panel_active(i: int) -> bool:
	if not single_player:
		return true
	# In single player only the panel P1 is currently picking is "active".
	return (i == 0 and not confirmed[0]) or (i == 1 and confirmed[0] and not confirmed[1])


func _display_points(char_id: String) -> PackedVector2Array:
	var data: Dictionary = GameSettings.CHARACTERS[char_id]
	var size: Vector2 = data["size"]
	var scale: float = 130.0 / maxf(size.x, size.y)
	var half := size * scale * 0.5
	var shape: String = data.get("shape", "rect")
	if shape == "triangle":
		return PackedVector2Array([
			Vector2(0, -half.y), Vector2(half.x, half.y), Vector2(-half.x, half.y)])
	if shape == "hexagon":
		return PackedVector2Array([
			Vector2(half.x, 0), Vector2(half.x * 0.5, half.y),
			Vector2(-half.x * 0.5, half.y), Vector2(-half.x, 0),
			Vector2(-half.x * 0.5, -half.y), Vector2(half.x * 0.5, -half.y)])
	return PackedVector2Array([
		Vector2(-half.x, -half.y), Vector2(half.x, -half.y),
		Vector2(half.x, half.y), Vector2(-half.x, half.y)])


func _start_match() -> void:
	GameSettings.p1_character = ROSTER[sel[0]]
	GameSettings.p2_character = ROSTER[sel[1]]
	get_tree().change_scene_to_file("res://scenes/Game.tscn")
