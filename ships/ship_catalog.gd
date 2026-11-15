# Lista las naves que el jugador puede elegir y recuerda cuál eligió.
#
# La nave original (`topdown-player.svg`) siempre existe como opción 0, así que
# aunque la carpeta esté vacía el juego funciona igual.
extends Node

signal selection_changed

# Carpeta donde se dejan las imágenes de las naves extra.
const SHIPS_DIR := "res://ships/player_ships"
# Nave original del juego; se usa también si algo falla al cargar otra.
const DEFAULT_SHIP_PATH := "res://ships/player/topdown-player.svg"
const DEFAULT_SHIP_NAME := "Original"
const IMAGE_EXTENSIONS := ["png", "jpg", "jpeg", "webp", "svg", "bmp", "tga"]
# Dónde se guarda la elección entre sesiones (carpeta de datos del usuario).
const SETTINGS_PATH := "user://ship_selection.cfg"


const REFERENCE_TEXTURE_SIZE := 80.0
const REFERENCE_SPRITE_SCALE := 1z

# Cada elemento: {"path": String, "name": String}
var ships: Array[Dictionary] = []
var selected_index := 0


func _ready() -> void:
	refresh()


# Vuelve a leer la carpeta. Mantiene la nave elegida si todavía existe.
func refresh() -> void:
	var previous_path := get_selected_path() if not ships.is_empty() else _load_saved_path()
	ships = [{"path": DEFAULT_SHIP_PATH, "name": DEFAULT_SHIP_NAME}]
	for path in _scan_ship_files():
		ships.append({"path": path, "name": _make_display_name(path)})

	selected_index = 0
	for index in ships.size():
		if ships[index]["path"] == previous_path:
			selected_index = index
			break


func get_ship_count() -> int:
	return ships.size()


func get_ship_name(index: int) -> String:
	if ships.is_empty():
		return DEFAULT_SHIP_NAME
	return ships[posmod(index, ships.size())]["name"]


func get_selected_path() -> String:
	if ships.is_empty():
		return DEFAULT_SHIP_PATH
	return ships[selected_index]["path"]


func get_selected_texture() -> Texture2D:
	return _load_texture(get_selected_path())


# Textura de la nave en la posición `index`. Nunca devuelve null mientras exista
# la nave original.
func get_ship_texture(index: int) -> Texture2D:
	if ships.is_empty():
		return _load_texture(DEFAULT_SHIP_PATH)
	return _load_texture(ships[posmod(index, ships.size())]["path"])


func select(index: int) -> void:
	if ships.is_empty():
		return
	var new_index := posmod(index, ships.size())
	if new_index == selected_index:
		return
	selected_index = new_index
	_save_selection()
	selection_changed.emit()


func select_next() -> void:
	select(selected_index + 1)


# Escala que hay que darle a un Sprite2D (o a las partículas de la estela) para
# que `texture` ocupe el mismo tamaño en pantalla que la nave original.
func get_display_scale(texture: Texture2D) -> float:
	if texture == null:
		return REFERENCE_SPRITE_SCALE
	var biggest_side := maxf(texture.get_width(), texture.get_height())
	if biggest_side <= 0.0:
		return REFERENCE_SPRITE_SCALE
	return REFERENCE_SPRITE_SCALE * REFERENCE_TEXTURE_SIZE / biggest_side


func _scan_ship_files() -> Array[String]:
	var found: Array[String] = []
	var checked := {}
	var dir := DirAccess.open(SHIPS_DIR)
	if dir == null:
		return found

	for file_name in dir.get_files():
		# En el juego exportado Godot solo lista "nave.png.import" (o ".remap"),
		# no el archivo original; hay que quitar ese sufijo para recuperar la ruta.
		var clean_name := file_name
		if clean_name.ends_with(".import"):
			clean_name = clean_name.trim_suffix(".import")
		elif clean_name.ends_with(".remap"):
			clean_name = clean_name.trim_suffix(".remap")

		if not IMAGE_EXTENSIONS.has(clean_name.get_extension().to_lower()):
			continue
		var path := SHIPS_DIR.path_join(clean_name)
		# En el editor aparecen "nave.png" y "nave.png.import": revisar cada una una sola vez.
		if checked.has(path):
			continue
		checked[path] = true
		# Ignora imágenes que Godot no pudo importar como textura, o que están
		# corruptas: una imagen mala no debe romper el selector ni el juego.
		if not ResourceLoader.exists(path, "Texture2D"):
			continue
		if ResourceLoader.load(path) as Texture2D == null:
			push_warning("Se ignora la nave '%s': no es una imagen válida." % path)
			continue
		found.append(path)

	# Orden natural y sin distinguir mayúsculas: nave2 antes que nave10.
	found.sort_custom(func(a: String, b: String) -> bool: return a.naturalnocasecmp_to(b) < 0)
	return found


func _load_texture(path: String) -> Texture2D:
	var texture := ResourceLoader.load(path) as Texture2D
	if texture == null and path != DEFAULT_SHIP_PATH:
		push_warning("No se pudo cargar la nave '%s'. Se usa la original." % path)
		texture = ResourceLoader.load(DEFAULT_SHIP_PATH) as Texture2D
	return texture


func _make_display_name(path: String) -> String:
	return path.get_file().get_basename().replace("-", " ").replace("_", " ").capitalize()


func _load_saved_path() -> String:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return DEFAULT_SHIP_PATH
	return str(config.get_value("ship", "path", DEFAULT_SHIP_PATH))


func _save_selection() -> void:
	var config := ConfigFile.new()
	config.set_value("ship", "path", get_selected_path())
	config.save(SETTINGS_PATH)
