extends Control

const NASA_GAME_URL := "https://science.nasa.gov/mission/webb/game-build-it-yourself/"

signal closed

var _title: Label
var _information: Label
var _guidance: Label
var _continue_button: Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_interface()
	hide()


func open_for(point: SciencePointOfInterest, is_final_point: bool = false) -> void:
	_title.text = point.get_display_name()
	_information.text = point.get_information()
	_guidance.text = (
		"Misión completada. Cierra esta ficha para volver al configurador."
		if is_final_point
		else "Punto completado. Acércate a la estación y permanece dentro de su radio para recargar energía."
	)
	_continue_button.text = "Volver al configurador" if is_final_point else "Continuar vuelo"
	show()
	get_tree().paused = true
	_continue_button.grab_focus()


func _build_interface() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	var dimmer := ColorRect.new()
	dimmer.color = Color(0.025, 0.04, 0.09, 0.78)
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dimmer)

	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.offset_left = -360
	panel.offset_top = -220
	panel.offset_right = 360
	panel.offset_bottom = 220
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("202b42")
	panel_style.set_corner_radius_all(10)
	panel_style.set_content_margin_all(24)
	panel.add_theme_stylebox_override("panel", panel_style)
	add_child(panel)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 14)
	panel.add_child(content)

	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 24)
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(_title)

	var separator := HSeparator.new()
	content.add_child(separator)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(scroll)

	_information = Label.new()
	_information.custom_minimum_size.x = 640
	_information.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_information.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	scroll.add_child(_information)

	_guidance = Label.new()
	_guidance.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(_guidance)

	var source := LinkButton.new()
	source.text = "Fuente: NASA Webb — Build It Yourself"
	source.uri = NASA_GAME_URL
	content.add_child(source)

	_continue_button = Button.new()
	_continue_button.text = "Continuar vuelo"
	_continue_button.pressed.connect(close)
	content.add_child(_continue_button)


func close() -> void:
	hide()
	get_tree().paused = false
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
