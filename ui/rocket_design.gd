extends Node

# The NASA game specifies the instrument/mission choices, but not resource
# costs. These estimates are for this game's balance and are not NASA data.
const INSTRUMENTS: Array[Dictionary] = [
	{
		"id": "camara",
		"nombre": "Cámara",
		"descripcion": "Toma imágenes y puede optimizarse para luz óptica, infrarroja, ultravioleta o rayos X.",
		"wavelengths": ["optico", "infrarrojo", "ultravioleta", "rayos_x"],
		"costo": 25,
		"masa": 20,
		"energia": 20,
		"datos": 40,
		"ciencia": 35,
	},
	{
		"id": "espectrometro",
		"nombre": "Espectrómetro",
		"descripcion": "Descompone la luz para estudiar composición, temperatura y movimiento.",
		"wavelengths": ["optico", "infrarrojo", "ultravioleta", "rayos_x", "rayos_gamma"],
		"costo": 35,
		"masa": 25,
		"energia": 35,
		"datos": 30,
		"ciencia": 45,
	},
	{
		"id": "radiometro",
		"nombre": "Radiómetro",
		"descripcion": "Mide la potencia de radiación; en este diseño observa el fondo cósmico de microondas.",
		"wavelengths": ["microondas"],
		"costo": 40,
		"masa": 35,
		"energia": 45,
		"datos": 35,
		"ciencia": 50,
	},
	{
		"id": "contador_proporcional",
		"nombre": "Contador proporcional",
		"descripcion": "Detecta rayos X midiendo el pulso eléctrico producido en un gas; no necesita óptica.",
		"wavelengths": ["rayos_x"],
		"costo": 15,
		"masa": 10,
		"energia": 10,
		"datos": 15,
		"ciencia": 25,
	},
	{
		"id": "centelleador",
		"nombre": "Centelleador",
		"descripcion": "Detecta rayos gamma convirtiendo su energía en destellos de luz medibles.",
		"wavelengths": ["rayos_gamma"],
		"costo": 30,
		"masa": 20,
		"energia": 25,
		"datos": 20,
		"ciencia": 40,
	},
]

const WAVELENGTHS: Array[Dictionary] = [
	{"id": "infrarrojo", "nombre": "Infrarrojo", "informacion": "El infrarrojo atraviesa mejor las nubes de polvo que la luz visible y ayuda a observar estrellas y galaxias jóvenes y distantes."},
	{"id": "optico", "nombre": "Óptico", "informacion": "La luz óptica permite captar estrellas y gas; con espectros se puede estudiar la composición y el movimiento de los objetos."},
	{"id": "ultravioleta", "nombre": "Ultravioleta", "informacion": "Las estrellas jóvenes, calientes y masivas emiten mucha luz ultravioleta, que ilumina el gas y el polvo que las rodea."},
	{"id": "microondas", "nombre": "Microondas", "informacion": "El fondo cósmico de microondas es una señal remanente del Big Bang y aporta pistas sobre el universo temprano."},
	{"id": "rayos_x", "nombre": "Rayos X", "informacion": "Los rayos X pueden revelar material calentado a temperaturas extremas, por ejemplo al caer hacia un agujero negro."},
	{"id": "rayos_gamma", "nombre": "Rayos gamma", "informacion": "Los rayos gamma se asocian a procesos de altísima energía, como chorros de materia y estallidos cósmicos; no se enfocan con espejos convencionales."},
]

const SCIENCE_TOPICS: Array[Dictionary] = [
	{
		"id": "agujeros_negros",
		"nombre": "Agujeros negros",
		"descripcion": "Estudia agujeros negros y cómo interactúan con estrellas y galaxias.",
		"informacion": "Aunque la luz no escapa de un agujero negro, el material que cae hacia él puede calentarse y emitir rayos X y gamma. En luz óptica, el movimiento de estrellas cercanas permite inferir la masa del objeto.",
		"wavelengths": ["rayos_x", "rayos_gamma", "optico", "ultravioleta"],
	},
	{
		"id": "universo_temprano",
		"nombre": "Universo temprano",
		"descripcion": "Investiga las primeras galaxias y la radiación remanente del Big Bang.",
		"informacion": "Como la luz de las galaxias más lejanas tarda mucho en llegar, las observamos como eran en el pasado. La expansión del universo desplaza esa luz hacia el infrarrojo; las microondas permiten estudiar la radiación de fondo que quedó tras el Big Bang.",
		"wavelengths": ["optico", "microondas", "infrarrojo"],
	},
	{
		"id": "exoplanetas",
		"nombre": "Exoplanetas",
		"descripcion": "Busca planetas y estudia cómo se forman los sistemas planetarios.",
		"informacion": "Una cámara óptica puede descubrir planetas al medir la pequeña disminución periódica de brillo cuando pasan frente a su estrella. El infrarrojo ayuda a observar planetas jóvenes y estudiar sus atmósferas en regiones con polvo.",
		"wavelengths": ["optico", "infrarrojo"],
	},
	{
		"id": "galaxias",
		"nombre": "Galaxias",
		"descripcion": "Investiga la estructura, evolución y composición de las galaxias.",
		"informacion": "La luz óptica revela la estructura y el movimiento del gas; el infrarrojo puede atravesar polvo y mostrar regiones ocultas. Los rayos X señalan material muy caliente cerca de agujeros negros, y la radiación ultravioleta destaca estrellas jóvenes y calientes.",
		"wavelengths": ["optico", "infrarrojo", "rayos_x", "rayos_gamma", "ultravioleta"],
	},
	{
		"id": "formacion_estelar",
		"nombre": "Formación estelar",
		"descripcion": "Observa el nacimiento de estrellas dentro de nubes de gas y polvo.",
		"informacion": "Las estrellas nacen en nubes densas de gas y polvo. El polvo absorbe parte de la luz visible, mientras que el infrarrojo permite observar el interior de esas nubes; las estrellas jóvenes y calientes también iluminan el gas con luz ultravioleta.",
		"wavelengths": ["optico", "infrarrojo", "ultravioleta"],
	},
]

const OPTICS: Array[Dictionary] = [
	{"id": "sin_optica", "nombre": "Sin óptica", "informacion": "Los rayos gamma no se enfocan con espejos; algunos detectores de rayos X tampoco necesitan óptica."},
	{"id": "primario_unico", "nombre": "Espejo primario único", "informacion": "Un espejo principal tradicional recoge la luz y la dirige al instrumento."},
	{"id": "segmentado", "nombre": "Espejo segmentado", "informacion": "Varios segmentos trabajan juntos como un espejo grande; se usa para construir telescopios de mayor tamaño."},
	{"id": "anidado", "nombre": "Espejo anidado", "informacion": "Capas de espejos anidados pueden desviar rayos X que llegan con un ángulo muy rasante."},
]

const DEFAULT_BUDGET := 200
const DEFAULT_MAX_MASS := 200
const DEFAULT_LEVEL := 1
const MAX_MASS_SPEED_PENALTY := 0.30
# Fixed base capacities for the ship; these are no longer configurable modules.
const BASE_ENERGY_GENERATED := 90
const BASE_DATA_CAPACITY := 80
const BASE_DATA_TRANSMISSION := 70
const LEVEL_LIMITS := {
	1: {"topics": 1, "wavelengths": 1, "instruments": 99},
	2: {"topics": 2, "wavelengths": 2, "instruments": 99},
	3: {"topics": 4, "wavelengths": 3, "instruments": 3},
}

var budget_limit := DEFAULT_BUDGET
var max_mass := DEFAULT_MAX_MASS
var level := DEFAULT_LEVEL
var selected_topics: Array[String] = []
var selected_wavelengths: Array[String] = []
# Wavelength ID -> instrument ID -> selected optics ID.
var _instrument_selections: Dictionary = {}


func _ready() -> void:
	reset_design()


func reset_design() -> void:
	budget_limit = DEFAULT_BUDGET
	max_mass = DEFAULT_MAX_MASS
	level = DEFAULT_LEVEL
	selected_topics = ["formacion_estelar"]
	selected_wavelengths = ["infrarrojo"]
	_instrument_selections = {"infrarrojo": {"camara": "primario_unico"}}


func get_level_limit(kind: String) -> int:
	return LEVEL_LIMITS[level][kind]


func set_level(new_level: int) -> void:
	level = clampi(new_level, 1, 3)
	while selected_topics.size() > get_level_limit("topics"):
		selected_topics.pop_back()
	while selected_wavelengths.size() > get_level_limit("wavelengths"):
		_remove_wavelength(selected_wavelengths.back())
	_prune_incompatible_wavelengths()
	_prune_excess_instruments()


func is_topic_selected(topic_id: String) -> bool:
	return selected_topics.has(topic_id)


func can_select_topic(topic_id: String) -> bool:
	return _find_by_id(SCIENCE_TOPICS, topic_id) != {} and (
		is_topic_selected(topic_id) or selected_topics.size() < get_level_limit("topics")
	)


func set_topic_selected(topic_id: String, selected: bool) -> void:
	if _find_by_id(SCIENCE_TOPICS, topic_id).is_empty():
		return
	if selected and not is_topic_selected(topic_id) and selected_topics.size() < get_level_limit("topics"):
		selected_topics.append(topic_id)
	elif not selected:
		selected_topics.erase(topic_id)
	_prune_incompatible_wavelengths()


func is_wavelength_selected(wavelength_id: String) -> bool:
	return selected_wavelengths.has(wavelength_id)


func is_wavelength_relevant(wavelength_id: String) -> bool:
	for topic_id in selected_topics:
		var topic: Dictionary = _find_by_id(SCIENCE_TOPICS, topic_id)
		if topic.get("wavelengths", []).has(wavelength_id):
			return true
	return false


func get_selected_wavelengths_for_topic(topic_id: String) -> Array[String]:
	var selected_for_topic: Array[String] = []
	var topic: Dictionary = _find_by_id(SCIENCE_TOPICS, topic_id)
	for wavelength_id in selected_wavelengths:
		if topic.get("wavelengths", []).has(wavelength_id):
			selected_for_topic.append(wavelength_id)
	return selected_for_topic


func can_select_wavelength(wavelength_id: String) -> bool:
	return _find_by_id(WAVELENGTHS, wavelength_id) != {} and is_wavelength_relevant(wavelength_id) and (
		is_wavelength_selected(wavelength_id)
		or selected_wavelengths.size() < get_level_limit("wavelengths")
	)


func set_wavelength_selected(wavelength_id: String, selected: bool) -> void:
	if _find_by_id(WAVELENGTHS, wavelength_id).is_empty():
		return
	if selected and can_select_wavelength(wavelength_id):
		if not is_wavelength_selected(wavelength_id):
			selected_wavelengths.append(wavelength_id)
			_instrument_selections[wavelength_id] = {}
	elif not selected:
		_remove_wavelength(wavelength_id)


func get_compatible_instruments(wavelength_id: String) -> Array[Dictionary]:
	var compatible: Array[Dictionary] = []
	for instrument in INSTRUMENTS:
		if instrument["wavelengths"].has(wavelength_id):
			compatible.append(instrument)
	return compatible


func get_available_optics(wavelength_id: String, instrument_id: String) -> Array[Dictionary]:
	var optics_ids: Array[String] = []
	if wavelength_id == "rayos_gamma":
		optics_ids = ["sin_optica"]
	elif wavelength_id == "rayos_x":
		if instrument_id == "contador_proporcional":
			optics_ids = ["sin_optica"]
		elif instrument_id == "espectrometro":
			optics_ids = ["sin_optica", "anidado", "segmentado"]
		else:
			optics_ids = ["anidado", "segmentado"]
	elif wavelength_id == "microondas":
		optics_ids = ["primario_unico"]
	else:
		optics_ids = ["primario_unico", "segmentado"]

	var available: Array[Dictionary] = []
	for optics in OPTICS:
		if optics_ids.has(optics["id"]):
			available.append(optics)
	return available


func is_instrument_selected(wavelength_id: String, instrument_id: String) -> bool:
	return _instrument_selections.get(wavelength_id, {}).has(instrument_id)


func can_select_instrument(wavelength_id: String, instrument_id: String) -> bool:
	if not is_wavelength_selected(wavelength_id):
		return false
	if _find_by_id(INSTRUMENTS, instrument_id).is_empty():
		return false
	if not _find_instrument_for_wavelength(wavelength_id, instrument_id):
		return false
	if is_instrument_selected(wavelength_id, instrument_id):
		return true
	if _selected_instrument_count() >= get_level_limit("instruments"):
		return false
	return level != 3 or _instrument_selections[wavelength_id].is_empty()


func set_instrument_selected(wavelength_id: String, instrument_id: String, selected: bool) -> void:
	if selected:
		if not can_select_instrument(wavelength_id, instrument_id):
			return
		if not _instrument_selections.has(wavelength_id):
			_instrument_selections[wavelength_id] = {}
		var optics := get_available_optics(wavelength_id, instrument_id)
		if optics.is_empty():
			return
		_instrument_selections[wavelength_id][instrument_id] = optics[0]["id"]
	else:
		if _instrument_selections.has(wavelength_id):
			_instrument_selections[wavelength_id].erase(instrument_id)


func get_selected_optics(wavelength_id: String, instrument_id: String) -> String:
	return _instrument_selections.get(wavelength_id, {}).get(instrument_id, "")


func get_selected_instrument_ids(wavelength_id: String) -> Array[String]:
	var instrument_ids: Array[String] = []
	for instrument_id in _instrument_selections.get(wavelength_id, {}).keys():
		instrument_ids.append(instrument_id)
	return instrument_ids


func set_selected_optics(wavelength_id: String, instrument_id: String, optics_id: String) -> void:
	if not is_instrument_selected(wavelength_id, instrument_id):
		return
	for optics in get_available_optics(wavelength_id, instrument_id):
		if optics["id"] == optics_id:
			_instrument_selections[wavelength_id][instrument_id] = optics_id
			return


func calculate_totals() -> Dictionary:
	var totals := {
		"cost": 0,
		"mass": 0,
		"energy_used": 0,
		"energy_generated": BASE_ENERGY_GENERATED,
		"data_generated": 0,
		"data_capacity": BASE_DATA_CAPACITY,
		"data_transmission": BASE_DATA_TRANSMISSION,
		"science": 0,
		"instrument_count": 0,
	}

	for wavelength_id in selected_wavelengths:
		for instrument_id in _instrument_selections.get(wavelength_id, {}):
			var instrument: Dictionary = _find_by_id(INSTRUMENTS, instrument_id)
			_add_common_totals(totals, instrument)
			totals["energy_used"] += instrument["energia"]
			totals["data_generated"] += instrument["datos"]
			totals["science"] += instrument["ciencia"]
			totals["instrument_count"] += 1

	return totals


func get_movement_speed_multiplier() -> float:
	var mass: float = calculate_totals()["mass"]
	var load_ratio := 1.0 if max_mass <= 0 and mass > 0.0 else 0.0
	if max_mass > 0:
		load_ratio = clampf(mass / float(max_mass), 0.0, 1.0)
	return 1.0 - load_ratio * MAX_MASS_SPEED_PENALTY


func get_validation_errors(totals: Dictionary = {}) -> Array[String]:
	if totals.is_empty():
		totals = calculate_totals()
	var errors: Array[String] = []
	if selected_topics.is_empty():
		errors.append("Selecciona al menos un tema científico.")
	for topic_id in selected_topics:
		if get_selected_wavelengths_for_topic(topic_id).is_empty():
			errors.append("El tema %s necesita una longitud de onda compatible." % _topic_name(topic_id))
	if selected_wavelengths.is_empty():
		errors.append("Selecciona al menos una longitud de onda.")
	for wavelength_id in selected_wavelengths:
		if _instrument_selections.get(wavelength_id, {}).is_empty():
			errors.append("Selecciona un instrumento para %s." % _wavelength_name(wavelength_id))
	if totals["cost"] > budget_limit:
		errors.append("El coste supera el presupuesto máximo.")
	if totals["mass"] > max_mass:
		errors.append("La masa supera la capacidad máxima del cohete.")
	if totals["energy_used"] > totals["energy_generated"]:
		errors.append("El consumo de energía supera la energía generada.")
	if totals["data_generated"] > totals["data_capacity"]:
		errors.append("Los datos superan la capacidad de la aviónica.")
	if totals["data_generated"] > totals["data_transmission"]:
		errors.append("Los datos superan la capacidad de transmisión.")
	return errors


func _prune_incompatible_wavelengths() -> void:
	for wavelength_id in selected_wavelengths.duplicate():
		if not is_wavelength_relevant(wavelength_id):
			_remove_wavelength(wavelength_id)


func _prune_excess_instruments() -> void:
	var remaining := get_level_limit("instruments")
	for wavelength_id in selected_wavelengths:
		var selections: Dictionary = _instrument_selections.get(wavelength_id, {})
		var already_kept_one := false
		for instrument_id in selections.keys():
			if remaining <= 0 or (level == 3 and already_kept_one):
				selections.erase(instrument_id)
			else:
				remaining -= 1
				already_kept_one = true


func _remove_wavelength(wavelength_id: String) -> void:
	selected_wavelengths.erase(wavelength_id)
	_instrument_selections.erase(wavelength_id)


func _selected_instrument_count() -> int:
	var count := 0
	for selections in _instrument_selections.values():
		count += selections.size()
	return count


func _find_instrument_for_wavelength(wavelength_id: String, instrument_id: String) -> bool:
	for instrument in get_compatible_instruments(wavelength_id):
		if instrument["id"] == instrument_id:
			return true
	return false


func _wavelength_name(wavelength_id: String) -> String:
	var wavelength: Dictionary = _find_by_id(WAVELENGTHS, wavelength_id)
	return wavelength.get("nombre", wavelength_id)


func _topic_name(topic_id: String) -> String:
	var topic: Dictionary = _find_by_id(SCIENCE_TOPICS, topic_id)
	return topic.get("nombre", topic_id)


func _add_common_totals(totals: Dictionary, component: Dictionary) -> void:
	totals["cost"] += component["costo"]
	totals["mass"] += component["masa"]


func _find_by_id(items: Array[Dictionary], item_id: String) -> Dictionary:
	for item in items:
		if item["id"] == item_id:
			return item
	return {}
