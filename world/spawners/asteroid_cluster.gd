# Cluster of Asteroid nodes in the world.
# Spawns asteroids and keeps track of the available resources in the cluster.
class_name AsteroidCluster
extends Node2D

signal cluster_depleted

const AsteroidScene := preload("res://world/docking_point/asteroid.tscn")

# Ore left in the cluster.
var iron_amount := 0.0: set = set_iron_amount
# If `true`, the cluster is occupied, e.g. by a pirate squad.
var is_occupied := false


func _init() -> void:
	set_as_top_level(true)


# Spawns a new random count of asteroids and adds them as children.
func spawn_asteroids(
	rng: RandomNumberGenerator,
	count_min := 1,
	count_max := 5,
	spawn_radius := 150.0,
	asteroid_radius := 75.0,
	spawn_inner_radius := 0.0
) -> void:
	var count = rng.randi_range(count_min, count_max)
	var min_distance_squared := pow(asteroid_radius, 2)
	var inner_radius_squared := pow(clampf(spawn_inner_radius, 0.0, spawn_radius), 2)
	var outer_radius_squared := pow(spawn_radius, 2)

	for _i in range(count):
		var spawn_position := Vector2.ZERO
		for _attempt in range(24):
			var angle := rng.randf_range(0.0, TAU)
			var radius := sqrt(rng.randf_range(inner_radius_squared, outer_radius_squared))
			spawn_position = Vector2(radius * cos(angle), radius * sin(angle))
			var overlaps_existing := false
			for asteroid in get_children():
				if spawn_position.distance_squared_to(asteroid.position) < min_distance_squared:
					overlaps_existing = true
					break
			if not overlaps_existing:
				break

		var asteroid = _create_asteroid(rng, spawn_position)
		add_child(asteroid)
		asteroid.mined.connect(_on_Asteroid_mined)
		asteroid.depleted.connect(_on_Asteroid_depleted)
		iron_amount += asteroid.iron_amount
		Events.asteroid_spawned.emit(asteroid)


func set_iron_amount(value: float) -> void:
	iron_amount = max(value, 0.0)
	if is_equal_approx(iron_amount, 0.0):
		cluster_depleted.emit()
		queue_free()


# Creates, initializes, and returns a new Asteroid.
func _create_asteroid(rng: RandomNumberGenerator, location: Vector2) -> Asteroid:
	var asteroid: Asteroid = AsteroidScene.instantiate()
	asteroid.setup(rng)
	asteroid.global_position = location
	asteroid.rotation = rng.randf_range(0, PI * 2)
	return asteroid


func _on_Asteroid_mined(amount: float) -> void:
	self.iron_amount -= amount


func _on_Asteroid_depleted() -> void:
	if get_child_count() == 1:
		cluster_depleted.emit()
