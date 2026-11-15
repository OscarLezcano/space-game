# A gun that fires a projectile when user input is provided.
extends Gun

@export var fire_action := "fire"

var collision_mask: int = 0

var _input_disabled := false


func _get_configuration_warnings() -> PackedStringArray:
	return PackedStringArray(["Missing Projectile scene, the gun will not be able to fire"]) if not projectile else PackedStringArray([])


func _physics_process(_delta: float) -> void:
	if _input_disabled or not Input.is_action_pressed(fire_action) or not can_fire():
		return
	var player := owner as PlayerShip
	if player and player.consume_energy(PlayerShip.ENERGY_PER_PLASMA_SHOT):
		fire(global_position, global_rotation, collision_mask)
