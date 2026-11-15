class_name SciencePointOfInterest
extends Area2D

const GROUP := "science_points_of_interest"

@export var map_icon: MapIcon

var topic_id := ""
var wavelength_ids: Array[String] = []
var _visited := false


func _ready() -> void:
	add_to_group(GROUP)
	$Marker.modulate = _topic_color(topic_id)
	body_entered.connect(_on_body_entered)


func configure(science_topic_id: String, selected_wavelengths: Array[String]) -> void:
	topic_id = science_topic_id
	wavelength_ids = selected_wavelengths.duplicate()
	map_icon = map_icon.duplicate() as MapIcon
	map_icon.color = _topic_color(topic_id)


func get_display_name() -> String:
	var topic := _find_component(RocketDesign.SCIENCE_TOPICS, topic_id)
	return "Punto de interés: %s" % topic.get("nombre", "Ciencia espacial")


func get_information() -> String:
	var sections: Array[String] = []
	var topic := _find_component(RocketDesign.SCIENCE_TOPICS, topic_id)
	if not topic.is_empty():
		sections.append(topic.get("informacion", topic["descripcion"]))

	for wavelength_id in wavelength_ids:
		var wavelength := _find_component(RocketDesign.WAVELENGTHS, wavelength_id)
		if wavelength.is_empty():
			continue
		sections.append("Longitud de onda — %s\n%s" % [wavelength["nombre"], wavelength["informacion"]])

		for instrument_id in RocketDesign.get_selected_instrument_ids(wavelength_id):
			var instrument := _find_component(RocketDesign.INSTRUMENTS, instrument_id)
			var optics_id: String = RocketDesign.get_selected_optics(wavelength_id, instrument_id)
			var optics := _find_component(RocketDesign.OPTICS, optics_id)
			sections.append(
				"Instrumento — %s\n%s\nÓptica — %s. %s"
				% [
					instrument.get("nombre", instrument_id),
					instrument.get("descripcion", ""),
					optics.get("nombre", "Sin óptica"),
					optics.get("informacion", ""),
				]
			)

	return "\n\n".join(sections)


func _on_body_entered(body: Node2D) -> void:
	if not body is PlayerShip or _visited:
		return
	_visited = true
	Events.science_point_reached.emit(self)
	queue_free()


func _find_component(components: Array[Dictionary], component_id: String) -> Dictionary:
	for component in components:
		if component["id"] == component_id:
			return component
	return {}


func _topic_color(science_topic_id: String) -> Color:
	match science_topic_id:
		"agujeros_negros":
			return Color("ffb347")
		"universo_temprano":
			return Color("b59cff")
		"exoplanetas":
			return Color("7de4b5")
		"galaxias":
			return Color("ff8eae")
		_:
			return Color("70d9ff")
