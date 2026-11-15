# Spawns the station, asteroids, and mission science points on game entry.
# Keeps track of resources available in the world and which asteroid clusters holds it,
# and spawns more when running low.
class_name GameWorld
extends Node2D

const SCIENCE_POINT_SCENE := preload("res://world/points_of_interest/science_point_of_interest.tscn")

# Radius of the world in pixels.
@export var radius := 8000.0

# Minimum amount of iron that must be added when the world spawns new asteroids.
# Used in `_spawn_asteroids`.
@export var iron_amount_balance_level := 100.0
# If the amouns of iron in the world goes below this threshold, spawns new asteroids.
@export var refresh_threshold_range := 25.0

var _spawned_positions := []
var _world_objects := []
var _iron_clusters := {}

@onready var rng := RandomNumberGenerator.new()

@onready var station_spawner: StationSpawner = $StationSpawner
@onready var asteroid_spawner: AsteroidSpawner = $AsteroidSpawner


func _ready() -> void:
	await owner.ready
	setup()


func setup() -> void:
	rng.randomize()

	asteroid_spawner.cluster_depleted.connect(_on_AsteroidSpawner_cluster_depleted)

	station_spawner.spawn_station(rng)
	asteroid_spawner.spawn_asteroid_clusters(rng, iron_amount_balance_level, radius)
	_spawn_science_points()


func _spawn_science_points() -> void:
	var topic_count := RocketDesign.selected_topics.size()
	if topic_count == 0:
		return

	var spawn_distance := minf(radius * 0.55, 1600.0)
	var angle_offset := rng.randf_range(0.0, TAU)
	for index in topic_count:
		var topic_id: String = RocketDesign.selected_topics[index]
		var point: SciencePointOfInterest = SCIENCE_POINT_SCENE.instantiate()
		point.configure(topic_id, RocketDesign.get_selected_wavelengths_for_topic(topic_id))
		var angle := angle_offset + TAU * index / topic_count
		point.global_position = global_position + Vector2.RIGHT.rotated(angle) * spawn_distance
		add_child(point)
		Events.node_spawned.emit(point)
		asteroid_spawner.spawn_science_point_field(rng, point.global_position, RocketDesign.level)


func _on_AsteroidSpawner_cluster_depleted(iron_left: float) -> void:
	if iron_left < refresh_threshold_range:
		asteroid_spawner.spawn_asteroid_clusters(rng, iron_amount_balance_level, radius)
