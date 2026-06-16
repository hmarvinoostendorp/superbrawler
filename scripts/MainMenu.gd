extends Control
## Main menu. Buttons built in code so the scene file stays trivial.

func _ready() -> void:
	var title := Label.new()
	title.text = "SUPER BRAWLERS"
	title.add_theme_font_size_override("font_size", 72)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(0, 120)
	title.size = Vector2(1280, 90)
	add_child(title)

	var vbox := VBoxContainer.new()
	vbox.position = Vector2(490, 300)
	vbox.size = Vector2(300, 0)
	vbox.add_theme_constant_override("separation", 16)
	add_child(vbox)

	_add_button(vbox, "2 Player Versus", _on_two_player)
	_add_button(vbox, "Single Player", _on_single_player)
	_add_button(vbox, "Settings", _on_settings)
	_add_button(vbox, "Exit", _on_exit)

	var controls := Label.new()
	controls.text = "P1: WASD move/jump, F attack    P2: Arrows move/jump, / or Enter attack"
	controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls.position = Vector2(0, 640)
	controls.size = Vector2(1280, 30)
	add_child(controls)


func _add_button(parent: Node, text: String, handler: Callable) -> void:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(300, 52)
	b.add_theme_font_size_override("font_size", 26)
	b.pressed.connect(handler)
	parent.add_child(b)


func _on_two_player() -> void:
	GameSettings.single_player = false
	get_tree().change_scene_to_file("res://scenes/CharSelect.tscn")


func _on_single_player() -> void:
	GameSettings.single_player = true
	get_tree().change_scene_to_file("res://scenes/CharSelect.tscn")


func _on_settings() -> void:
	get_tree().change_scene_to_file("res://scenes/Settings.tscn")


func _on_exit() -> void:
	get_tree().quit()
