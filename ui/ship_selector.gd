# Panel (PanelContainer) del menú principal para elegir la nave: vista previa, nombre y un botón
# "Cambiar nave" que recorre todas las naves de `ShipCatalog`.
#
# Está construido por código (igual que `rocket_builder.gd`), así que no depende
# de nodos hijos y se puede instanciar en cualquier escena.
class_name ShipSelector
extends PanelContainer

signal ship_changed

const PREVIEW_SIZE := Vector2(140, 140)
const PANEL_COLOR := Color("252b40")
const PREVIEW_BG_COLOR := Color("171b2b")
const MENU_THEME := preload("res://ui/theme_main_menu.tres")

var _preview: TextureRect
var _name_label: Label
var _counter_label: Label
var _change_button: Button
var _pop_tween: Tween


func _ready() -> void:
	theme = MENU_THEME
	ShipCatalog.refresh()
	_build_interface()
	_refresh(false)
	ShipCatalog.selection_changed.connect(_on_selection_changed)


func _exit_tree() -> void:
	if ShipCatalog.selection_changed.is_connected(_on_selection_changed):
		ShipCatalog.selection_changed.disconnect(_on_selection_changed)


func _build_interface() -> void:
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = PANEL_COLOR
	panel_style.set_corner_radius_all(8)
	panel_style.set_content_margin_all(14)
	add_theme_stylebox_override("panel", panel_style)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	add_child(column)

	var heading := Label.new()
	heading.text = "NAVE"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 16)
	column.add_child(heading)

	var preview_panel := PanelContainer.new()
	var preview_style := StyleBoxFlat.new()
	preview_style.bg_color = PREVIEW_BG_COLOR
	preview_style.set_corner_radius_all(6)
	preview_style.set_content_margin_all(10)
	preview_panel.add_theme_stylebox_override("panel", preview_style)
	column.add_child(preview_panel)

	_preview = TextureRect.new()
	_preview.custom_minimum_size = PREVIEW_SIZE
	_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_preview.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_preview.pivot_offset = PREVIEW_SIZE / 2.0
	preview_panel.add_child(_preview)

	_name_label = Label.new()
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_name_label.add_theme_font_size_override("font_size", 16)
	column.add_child(_name_label)

	_counter_label = Label.new()
	_counter_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_counter_label.add_theme_font_size_override("font_size", 12)
	_counter_label.modulate = Color(1, 1, 1, 0.6)
	column.add_child(_counter_label)

	_change_button = Button.new()
	_change_button.text = "Cambiar nave"
	_change_button.add_theme_font_size_override("font_size", 16)
	# Sin foco de teclado: así Espacio/Enter no "pulsan" el botón y el menú sigue
	# arrancando con cualquier tecla, como antes.
	_change_button.focus_mode = Control.FOCUS_NONE
	_change_button.pressed.connect(_on_change_pressed)
	column.add_child(_change_button)


func _refresh(animate: bool) -> void:
	var index := ShipCatalog.selected_index
	var count := ShipCatalog.get_ship_count()
	_preview.texture = ShipCatalog.get_ship_texture(index)
	_name_label.text = ShipCatalog.get_ship_name(index)
	_counter_label.text = "%d / %d" % [index + 1, count]
	_change_button.disabled = count <= 1
	_change_button.tooltip_text = (
		"" if count > 1 else "Agrega imágenes en res://ships/player_ships/ para tener más naves."
	)
	if animate:
		_play_pop()


func _play_pop() -> void:
	if _pop_tween != null and _pop_tween.is_valid():
		_pop_tween.kill()
	_preview.scale = Vector2.ONE * 0.8
	_pop_tween = create_tween()
	_pop_tween.tween_property(_preview, "scale", Vector2.ONE, 0.18).set_trans(
		Tween.TRANS_BACK
	).set_ease(Tween.EASE_OUT)


func _on_change_pressed() -> void:
	ShipCatalog.select_next()


func _on_selection_changed() -> void:
	_refresh(true)
	ship_changed.emit()
