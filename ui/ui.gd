# Handles in-game menus and the science-point information panel.
extends CanvasLayer

@onready var screen_fader: TextureRect = $ScreenFader
@onready var map: TextureRect = $MapDisplay
@onready var upgrade_menu := $UpgradeUI
@onready var quit_menu := $QuitMenu
@onready var science_info_panel := $ScienceInfoPanel

var _player: PlayerShip


func _ready() -> void:
	Events.player_died.connect(reset.bind(true))
	Events.quit_requested.connect(quit)
	Events.upgrade_unlocked.connect(upgrade_menu.open)
	Events.station_spawned.connect(_on_station_spawned)
	Events.science_point_reached.connect(_on_science_point_reached)
	science_info_panel.closed.connect(_on_science_info_panel_closed)
	screen_fader.fade_in()
	await get_tree().process_frame
	if is_inside_tree() and get_tree().get_nodes_in_group(SciencePointOfInterest.GROUP).is_empty():
		_return_to_mission_builder()


func _process(delta: float) -> void:
	if not _player or get_tree().paused or not map.visible:
		return
	if not _player.consume_energy(PlayerShip.ENERGY_PER_MAP_SECOND * delta):
		if not map.is_animating():
			map.toggle()


func _unhandled_input(event: InputEvent) -> void:
	if get_tree().paused:
		return

	if event.is_action_pressed("ui_cancel"):
		quit_menu.open()
	if event.is_action_pressed("toggle_map") and not map.is_animating():
		if not map.visible and _player and _player.energy <= 0.0:
			return
		map.toggle()


func _on_station_spawned(_station: DockingPoint, player: PlayerShip) -> void:
	_player = player


func _on_science_point_reached(point: SciencePointOfInterest) -> void:
	var remaining_points := get_tree().get_nodes_in_group(SciencePointOfInterest.GROUP).size()
	science_info_panel.open_for(point, remaining_points <= 1)


func _on_science_info_panel_closed() -> void:
	if get_tree().get_nodes_in_group(SciencePointOfInterest.GROUP).is_empty():
		_return_to_mission_builder()


func _return_to_mission_builder() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://ui/rocket_builder.tscn")


func quit() -> void:
	get_tree().quit()


func reset(with_delay: bool) -> void:
	screen_fader.fade_out(with_delay)
	await screen_fader.animation_finished
	get_tree().change_scene_to_file("res://ui/main_menu.tscn")
