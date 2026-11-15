# Initializes the map, world effects, HUD, and player camera.
extends Node

@onready var map: MapView = $MapView
@onready var camera := $GameWorld/Camera
@onready var hud := $UI/HUD


func _ready() -> void:
	Events.station_spawned.connect(_on_Spawner_station_spawned)
	Events.asteroid_spawned.connect(_on_Spawner_asteroid_spawned)

	camera.setup_camera_map(map)

	ObjectRegistry.register_distortion_parent($DistortMaskView/SubViewport)
	camera.setup_distortion_camera()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_fullscreen"):
		get_window().mode = Window.MODE_EXCLUSIVE_FULLSCREEN if (not ((get_window().mode == Window.MODE_EXCLUSIVE_FULLSCREEN) or (get_window().mode == Window.MODE_FULLSCREEN))) else Window.MODE_WINDOWED
		get_viewport().set_input_as_handled()


func _on_Spawner_station_spawned(station: DockingPoint, player: PlayerShip) -> void:
	hud.initialize(player)
	player.grab_camera(camera)
	Events.node_spawned.emit(station)
	Events.node_spawned.emit(player)


func _on_Spawner_asteroid_spawned(asteroid: DockingPoint) -> void:
	Events.node_spawned.emit(asteroid)
