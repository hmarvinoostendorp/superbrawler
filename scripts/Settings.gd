extends Control
## Settings screen. Currently exposes the stock (lives) count.

var _stocks_value_label: Label

func _ready() -> void:
	var title := Label.new()
	title.text = "SETTINGS"
	title.add_theme_font_size_override("font_size", 56)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(0, 100)
	title.size = Vector2(1280, 70)
	add_child(title)

	# Stocks row: label + [-] value [+]
	var row := HBoxContainer.new()
	row.position = Vector2(440, 300)
	row.add_theme_constant_override("separation", 16)
	add_child(row)

	var label := Label.new()
	label.text = "Lives (Stocks):"
	label.add_theme_font_size_override("font_size", 28)
	label.custom_minimum_size = Vector2(220, 52)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(label)

	var minus := _make_button("-", Vector2(52, 52))
	minus.pressed.connect(_on_decrease)
	row.add_child(minus)

	_stocks_value_label = Label.new()
	_stocks_value_label.add_theme_font_size_override("font_size", 32)
	_stocks_value_label.custom_minimum_size = Vector2(60, 52)
	_stocks_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stocks_value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(_stocks_value_label)

	var plus := _make_button("+", Vector2(52, 52))
	plus.pressed.connect(_on_increase)
	row.add_child(plus)

	var back := _make_button("Back", Vector2(200, 52))
	back.position = Vector2(540, 440)
	back.pressed.connect(_on_back)
	add_child(back)

	_refresh()


func _make_button(text: String, size: Vector2) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = size
	b.add_theme_font_size_override("font_size", 26)
	return b


func _refresh() -> void:
	_stocks_value_label.text = str(GameSettings.stocks)


func _on_decrease() -> void:
	GameSettings.stocks = maxi(1, GameSettings.stocks - 1)
	_refresh()


func _on_increase() -> void:
	GameSettings.stocks = mini(9, GameSettings.stocks + 1)
	_refresh()


func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back()
