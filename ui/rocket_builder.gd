extends Control

const GAME_SCENE := "res://main/game.tscn"
const MAIN_MENU_SCENE := "res://ui/main_menu.tscn"
const NASA_GAME_URL := "https://science.nasa.gov/mission/webb/game-build-it-yourself/"

var _topic_checks: Dictionary = {}
var _wavelength_checks: Dictionary = {}
var _assignment_container: VBoxContainer
var _level_input: OptionButton
var _budget_input: SpinBox
var _mass_input: SpinBox
var _totals_labels: Dictionary = {}
var _mission_counts: Label
var _status_label: Label
var _launch_button: Button
var _language_button: Button


func _ready() -> void:
	theme = load("res://ui/theme_game_ui.tres")
	_build_interface()
	_refresh_mission_controls()
	_update_summary()


func _build_interface() -> void:
	var background := ColorRect.new()
	background.color = Color("171b2b")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 32)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 32)
	margin.add_theme_constant_override("margin_bottom", 20)
	add_child(margin)

	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 8)
	margin.add_child(page)

	var heading_row := HBoxContainer.new()
	page.add_child(heading_row)

	var title := Label.new()
	title.text = tr("Construye tu misión espacial")
	title.add_theme_font_size_override("font_size", 28)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading_row.add_child(title)

	_language_button = Button.new()
	_language_button.text = Localization.current_language_code()
	_language_button.tooltip_text = tr("Cambiar idioma")
	_language_button.pressed.connect(_on_language_button_pressed)
	heading_row.add_child(_language_button)

	var subtitle := Label.new()
	subtitle.text = tr("Elige ciencia, longitudes de onda, instrumentos y ópticas. La nave incluye capacidades base fijas de energía y datos, sin subsistemas seleccionables. Las métricas de instrumentos son estimaciones de balance, no cifras oficiales de NASA; las ópticas se validan por compatibilidad, pero no tienen costo o masa asignados.")
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	page.add_child(subtitle)

	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 16)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(body)

	var components_panel := _make_panel()
	components_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	components_panel.size_flags_stretch_ratio = 1.65
	body.add_child(components_panel)

	var component_content := VBoxContainer.new()
	component_content.add_theme_constant_override("separation", 8)
	components_panel.add_child(component_content)

	var component_heading := Label.new()
	component_heading.text = tr("DISEÑO CIENTÍFICO")
	component_heading.add_theme_font_size_override("font_size", 18)
	component_content.add_child(component_heading)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	component_content.add_child(scroll)

	var component_list := VBoxContainer.new()
	component_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	component_list.add_theme_constant_override("separation", 6)
	scroll.add_child(component_list)

	_add_section_heading(component_list, "Temas científicos")
	for topic in RocketDesign.SCIENCE_TOPICS:
		_add_topic_check(component_list, topic)

	_add_section_heading(component_list, "Longitudes de onda (según el tema elegido)")
	for wavelength in RocketDesign.WAVELENGTHS:
		_add_wavelength_check(component_list, wavelength)

	_add_section_heading(component_list, "Instrumentos y ópticas por longitud de onda")
	_assignment_container = VBoxContainer.new()
	_assignment_container.add_theme_constant_override("separation", 6)
	component_list.add_child(_assignment_container)

	var summary_panel := _make_panel()
	summary_panel.custom_minimum_size.x = 350
	summary_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(summary_panel)

	var summary_scroll := ScrollContainer.new()
	summary_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	summary_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	summary_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	summary_scroll.follow_focus = true
	summary_panel.add_child(summary_scroll)

	var summary := VBoxContainer.new()
	summary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	summary.add_theme_constant_override("separation", 8)
	summary_scroll.add_child(summary)

	var summary_heading := Label.new()
	summary_heading.text = tr("Resumen del cohete")
	summary_heading.add_theme_font_size_override("font_size", 20)
	summary.add_child(summary_heading)

	var level_row := HBoxContainer.new()
	summary.add_child(level_row)
	var level_label := Label.new()
	level_label.text = tr("Nivel NASA")
	level_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	level_row.add_child(level_label)
	_level_input = OptionButton.new()
	for level in [1, 2, 3]:
		_level_input.add_item(tr("Nivel %d") % level)
		_level_input.set_item_metadata(level - 1, level)
	_level_input.select(RocketDesign.level - 1)
	_level_input.item_selected.connect(_on_level_selected)
	level_row.add_child(_level_input)

	_add_limit_input(summary, "Presupuesto máximo", RocketDesign.budget_limit, true)
	_add_limit_input(summary, "Masa máxima", RocketDesign.max_mass, false)

	var balance_heading := Label.new()
	balance_heading.text = tr("BALANCE")
	balance_heading.add_theme_font_size_override("font_size", 16)
	summary.add_child(balance_heading)

	for metric_key in ["cost", "mass", "energy", "data", "science", "speed"]:
		var metric := Label.new()
		metric.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_totals_labels[metric_key] = metric
		summary.add_child(metric)

	_mission_counts = Label.new()
	_mission_counts.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary.add_child(_mission_counts)
	var flight_hint := Label.new()
	flight_hint.text = tr("En vuelo, abre el mapa con M y dirígete a los marcadores de ciencia.")
	flight_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary.add_child(flight_hint)

	_status_label = Label.new()
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary.add_child(_status_label)

	var reference := LinkButton.new()
	reference.text = tr("Fuente: NASA Webb — Build It Yourself")
	reference.uri = NASA_GAME_URL
	summary.add_child(reference)

	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 8)
	summary.add_child(buttons)

	var reset_button := Button.new()
	reset_button.text = tr("Restablecer")
	reset_button.pressed.connect(_reset_design)
	buttons.add_child(reset_button)

	var back_button := Button.new()
	back_button.text = tr("Menú")
	back_button.pressed.connect(_go_to_main_menu)
	buttons.add_child(back_button)

	_launch_button = Button.new()
	_launch_button.text = tr("Lanzar misión")
	_launch_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_launch_button.pressed.connect(_launch_mission)
	buttons.add_child(_launch_button)


func _make_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("252b40")
	style.set_corner_radius_all(8)
	style.set_content_margin_all(14)
	panel.add_theme_stylebox_override("panel", style)
	return panel


func _add_section_heading(parent: VBoxContainer, text: String) -> void:
	var heading := Label.new()
	heading.text = tr(text)
	heading.add_theme_font_size_override("font_size", 16)
	parent.add_child(heading)


func _add_topic_check(parent: VBoxContainer, topic: Dictionary) -> void:
	var checkbox := CheckBox.new()
	checkbox.text = tr(topic["nombre"])
	checkbox.tooltip_text = tr(topic["descripcion"])
	checkbox.set_meta("topic_id", topic["id"])
	checkbox.toggled.connect(_on_topic_toggled.bind(topic["id"]))
	_topic_checks[topic["id"]] = checkbox
	parent.add_child(checkbox)


func _add_wavelength_check(parent: VBoxContainer, wavelength: Dictionary) -> void:
	var checkbox := CheckBox.new()
	checkbox.text = tr(wavelength["nombre"])
	checkbox.set_meta("wavelength_id", wavelength["id"])
	checkbox.toggled.connect(_on_wavelength_toggled.bind(wavelength["id"]))
	_wavelength_checks[wavelength["id"]] = checkbox
	parent.add_child(checkbox)


func _refresh_mission_controls() -> void:
	for topic_id in _topic_checks:
		var checkbox: CheckBox = _topic_checks[topic_id]
		checkbox.set_pressed_no_signal(RocketDesign.is_topic_selected(topic_id))
		checkbox.disabled = not RocketDesign.can_select_topic(topic_id)

	for wavelength_id in _wavelength_checks:
		var checkbox: CheckBox = _wavelength_checks[wavelength_id]
		checkbox.set_pressed_no_signal(RocketDesign.is_wavelength_selected(wavelength_id))
		checkbox.disabled = not RocketDesign.can_select_wavelength(wavelength_id)

	_rebuild_assignments()


func _rebuild_assignments() -> void:
	for child in _assignment_container.get_children():
		_assignment_container.remove_child(child)
		child.queue_free()

	if RocketDesign.selected_wavelengths.is_empty():
		var hint := Label.new()
		hint.text = tr("Elige primero un tema compatible y una longitud de onda.")
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_assignment_container.add_child(hint)
		return

	for wavelength_id in RocketDesign.selected_wavelengths:
		var wavelength := _find_component(RocketDesign.WAVELENGTHS, wavelength_id)
		var wavelength_panel := _make_panel()
		_assignment_container.add_child(wavelength_panel)
		var options := VBoxContainer.new()
		options.add_theme_constant_override("separation", 4)
		wavelength_panel.add_child(options)

		var title := Label.new()
		title.text = tr(wavelength["nombre"])
		title.add_theme_font_size_override("font_size", 15)
		options.add_child(title)

		for instrument in RocketDesign.get_compatible_instruments(wavelength_id):
			_add_instrument_option(options, wavelength_id, instrument)


func _add_instrument_option(parent: VBoxContainer, wavelength_id: String, instrument: Dictionary) -> void:
	var instrument_id: String = instrument["id"]
	var card := PanelContainer.new()
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color("1d2437")
	card_style.set_corner_radius_all(6)
	card_style.set_content_margin_all(10)
	card.add_theme_stylebox_override("panel", card_style)
	parent.add_child(card)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 5)
	card.add_child(content)

	var checkbox := CheckBox.new()
	checkbox.text = tr(instrument["nombre"])
	checkbox.tooltip_text = tr(instrument["descripcion"])
	checkbox.button_pressed = RocketDesign.is_instrument_selected(wavelength_id, instrument_id)
	checkbox.disabled = not RocketDesign.can_select_instrument(wavelength_id, instrument_id)
	checkbox.toggled.connect(_on_instrument_toggled.bind(wavelength_id, instrument_id))
	content.add_child(checkbox)

	var description := Label.new()
	description.text = tr(instrument["descripcion"])
	description.add_theme_font_size_override("font_size", 12)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(description)

	var metrics_heading := Label.new()
	metrics_heading.text = tr("MÉTRICAS ESTIMADAS DE JUEGO")
	metrics_heading.add_theme_font_size_override("font_size", 11)
	content.add_child(metrics_heading)

	var metrics := GridContainer.new()
	metrics.columns = 3
	metrics.add_theme_constant_override("h_separation", 12)
	metrics.add_theme_constant_override("v_separation", 3)
	content.add_child(metrics)
	for metric in [
		{"label": "Costo", "key": "costo"},
		{"label": "Masa", "key": "masa"},
		{"label": "Energía", "key": "energia"},
		{"label": "Datos", "key": "datos"},
		{"label": "Ciencia", "key": "ciencia"},
	]:
		var metric_label := Label.new()
		metric_label.text = "%s: %d" % [tr(metric["label"]), instrument[metric["key"]]]
		metric_label.add_theme_font_size_override("font_size", 12)
		metrics.add_child(metric_label)

	if checkbox.button_pressed:
		var optics_row := HBoxContainer.new()
		optics_row.add_theme_constant_override("separation", 8)
		content.add_child(optics_row)
		var optics_label := Label.new()
		optics_label.text = tr("Óptica")
		optics_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		optics_row.add_child(optics_label)

		var optics_input := OptionButton.new()
		for optics in RocketDesign.get_available_optics(wavelength_id, instrument_id):
			optics_input.add_item(tr(optics["nombre"]))
			optics_input.set_item_metadata(optics_input.item_count - 1, optics["id"])
			if optics["id"] == RocketDesign.get_selected_optics(wavelength_id, instrument_id):
				optics_input.select(optics_input.item_count - 1)
		optics_input.item_selected.connect(_on_optics_selected.bind(wavelength_id, instrument_id, optics_input))
		optics_row.add_child(optics_input)


func _add_limit_input(parent: VBoxContainer, label_text: String, value: int, is_budget: bool) -> void:
	var row := HBoxContainer.new()
	parent.add_child(row)

	var label := Label.new()
	label.text = tr(label_text)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)

	var input := SpinBox.new()
	input.min_value = 0
	input.max_value = 10000
	input.step = 1
	input.value = value
	input.custom_minimum_size.x = 100
	if is_budget:
		_budget_input = input
		input.value_changed.connect(_on_budget_changed)
	else:
		_mass_input = input
		input.value_changed.connect(_on_mass_changed)
	row.add_child(input)


func _update_summary() -> void:
	var totals: Dictionary = RocketDesign.calculate_totals()
	_totals_labels["cost"].text = tr("Costo: %d / %d") % [totals["cost"], RocketDesign.budget_limit]
	_totals_labels["mass"].text = tr("Masa: %d / %d") % [totals["mass"], RocketDesign.max_mass]
	_totals_labels["energy"].text = tr("Energía: %d / %d") % [totals["energy_used"], totals["energy_generated"]]
	_totals_labels["data"].text = tr("Datos: %d / %d · Transmisión: %d / %d") % [totals["data_generated"], totals["data_capacity"], totals["data_generated"], totals["data_transmission"]]
	_totals_labels["science"].text = tr("Ciencia total: %d") % totals["science"]
	_totals_labels["speed"].text = tr("Velocidad máxima: %d%% de la base") % roundi(
		RocketDesign.get_movement_speed_multiplier() * 100.0
	)
	_mission_counts.text = tr("Nivel %d · Temas %d/%d · Ondas %d/%d · Instrumentos %d/%s") % [
		RocketDesign.level,
		RocketDesign.selected_topics.size(),
		RocketDesign.get_level_limit("topics"),
		RocketDesign.selected_wavelengths.size(),
		RocketDesign.get_level_limit("wavelengths"),
		totals["instrument_count"],
		"3" if RocketDesign.level == 3 else tr("sin límite"),
	]

	var errors: Array[String] = RocketDesign.get_validation_errors(totals)
	_launch_button.disabled = not errors.is_empty()
	if errors.is_empty():
		_status_label.text = tr("Diseño válido. ¡Listo para lanzar!")
		_status_label.modulate = Color("8de0a8")
	else:
		_status_label.text = tr("Revisa el diseño:") + "\n• " + "\n• ".join(errors)
		_status_label.modulate = Color("ff9a9a")


func _on_level_selected(index: int) -> void:
	RocketDesign.set_level(int(_level_input.get_item_metadata(index)))
	_refresh_mission_controls()
	_update_summary()


func _on_topic_toggled(selected: bool, topic_id: String) -> void:
	RocketDesign.set_topic_selected(topic_id, selected)
	_refresh_mission_controls()
	_update_summary()


func _on_wavelength_toggled(selected: bool, wavelength_id: String) -> void:
	RocketDesign.set_wavelength_selected(wavelength_id, selected)
	_refresh_mission_controls()
	_update_summary()


func _on_instrument_toggled(selected: bool, wavelength_id: String, instrument_id: String) -> void:
	RocketDesign.set_instrument_selected(wavelength_id, instrument_id, selected)
	_refresh_mission_controls()
	_update_summary()


func _on_optics_selected(index: int, wavelength_id: String, instrument_id: String, input: OptionButton) -> void:
	var optics_id: String = input.get_item_metadata(index)
	RocketDesign.set_selected_optics(wavelength_id, instrument_id, optics_id)
	_update_summary()


func _on_budget_changed(value: float) -> void:
	RocketDesign.budget_limit = int(value)
	_update_summary()


func _on_mass_changed(value: float) -> void:
	RocketDesign.max_mass = int(value)
	_update_summary()


func _reset_design() -> void:
	RocketDesign.reset_design()
	_budget_input.value = RocketDesign.budget_limit
	_mass_input.value = RocketDesign.max_mass
	_level_input.select(RocketDesign.level - 1)
	_refresh_mission_controls()
	_update_summary()


func _go_to_main_menu() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)


func _launch_mission() -> void:
	if RocketDesign.get_validation_errors().is_empty():
		get_tree().change_scene_to_file(GAME_SCENE)


func _on_language_button_pressed() -> void:
	Localization.toggle_locale()
	get_tree().call_deferred("reload_current_scene")


func _find_component(components: Array[Dictionary], component_id: String) -> Dictionary:
	for component in components:
		if component["id"] == component_id:
			return component
	return {}
