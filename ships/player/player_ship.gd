# Main class to represent the player's physics body. Controls the player's
# current health and how to operate when an upgrade choice has been made.
class_name PlayerShip
extends CharacterBody2D

signal died
signal energy_changed(current_energy: float, max_energy: float)

const ENERGY_PER_PLASMA_SHOT := 3.0
const ENERGY_PER_LASER_SECOND := 18.0
const ENERGY_PER_MAP_SECOND := 1.0
const ENERGY_RECHARGE_PER_SECOND := 15.0

@export var stats: Resource = preload("res://ships/player/player_stats.tres")
@export var projectile_mask := 0 # (int, LAYERS_2D_PHYSICS)
@export var ExplosionEffect: PackedScene
# Represents the ship on the minimap. Use a MapIcon resource.
@export var map_icon: Resource

var dockables := []
var max_energy := 0.0
var energy := 0.0

@onready var shape := $CollisionShape3D
@onready var agent: GSAISteeringAgent = $StateMachine/Move.agent
@onready var camera_transform := $CameraTransform
@onready var timer := $MapTimer
@onready var cargo := $Cargo
@onready var move_state := $StateMachine/Move
@onready var gun := $Gun
@onready var laser_gun := $LaserGun
@onready var vfx := $VFX
@onready var sprite: Sprite2D = $Sprite2D
@onready var move_trail: CPUParticles2D = $VFX/MoveTrail


func _ready() -> void:
	stats.initialize()
	max_energy = RocketDesign.calculate_totals()["energy_generated"]
	energy = max_energy
	energy_changed.emit(energy, max_energy)
	Events.damaged.connect(_on_damaged)
	Events.upgrade_chosen.connect(_on_upgrade_chosen)
	stats.health_depleted.connect(die)
	gun.collision_mask = projectile_mask
	laser_gun.collision_mask = projectile_mask
	_apply_selected_ship()


# Cambia el dibujo de la nave por el elegido en el menú (ver `ShipCatalog`).
# Solo toca la apariencia: el hitbox, los stats y los estados no cambian.
func _apply_selected_ship() -> void:
	var texture := ShipCatalog.get_selected_texture()
	if texture == null:
		return
	var display_scale := ShipCatalog.get_display_scale(texture)
	sprite.texture = texture
	sprite.scale = Vector2.ONE * display_scale
	# La estela de movimiento usa la misma imagen que la nave.
	move_trail.texture = texture
	move_trail.scale_amount_min = display_scale
	move_trail.scale_amount_max = display_scale


func _process(delta: float) -> void:
	if energy >= max_energy:
		return
	for dockable_ref in dockables:
		var dockable: Variant = dockable_ref.get_ref()
		if dockable is Station:
			energy = minf(max_energy, energy + ENERGY_RECHARGE_PER_SECOND * delta)
			energy_changed.emit(energy, max_energy)
			return


func consume_energy(amount: float) -> bool:
	if amount <= 0.0:
		return true
	if energy <= 0.0:
		return false

	var can_pay := energy >= amount
	energy = maxf(energy - amount, 0.0)
	energy_changed.emit(energy, max_energy)
	return can_pay


func _toggle_map(map_up: bool, tween_time: float) -> void:
	if not map_up:
		timer.start(tween_time)
		await timer.timeout
	camera_transform.update_position = not map_up


func die() -> void:
	var effect := ExplosionEffect.instantiate()
	effect.global_position = global_position
	ObjectRegistry.register_effect(effect)

	died.emit()
	Events.player_died.emit()

	queue_free()


func grab_camera(camera: Camera2D) -> void:
	camera_transform.remote_path = camera.get_path()


func _on_damaged(target: Node, amount: int, _origin: Node) -> void:
	if not target == self:
		return

	stats.health -= amount


func _on_upgrade_chosen(choice: int) -> void:
	match choice:
		Events.UpgradeChoices.HEALTH:
			stats.add_modifier("max_health", 25.0)
		Events.UpgradeChoices.SPEED:
			stats.add_modifier("linear_speed_max", 125.0)
		Events.UpgradeChoices.CARGO:
			cargo.stats.add_modifier("max_cargo", 50.0)
		Events.UpgradeChoices.MINING:
			cargo.stats.add_modifier("mining_rate", 10.0)
			cargo.stats.add_modifier("unload_rate", 5.0)
		Events.UpgradeChoices.WEAPON:
			gun.stats.add_modifier("damage", 3.0)
			# That's a limitation of the stats system, modifiers only add or remove values, and they
			# don't have limits
			if gun.stats.get_stat("cooldown") > 0.2:
				gun.stats.add_modifier("cooldown", -0.05)
