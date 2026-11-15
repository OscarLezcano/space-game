# Represents an extended dockable that holds a random amount of mineable
# resources.
class_name Asteroid
extends DockingPoint

const RADIO_ATRACCION := 650.0

signal mined(amount)
signal depleted

@export var min_iron_amount := 5.0
@export var max_iron_amount := 100.0
@export var min_scale := 0.2
@export_range(0.0, 1000.0, 10.0) var atraccion := 300.0

@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var fx_anim_player: AnimationPlayer = $FXAnimationPlayer
@onready var sprite: Sprite2D = $Sprite2D

var iron_amount := 0.0
var _is_depleted := false


func _ready() -> void:
	super()
	add_to_group("asteroids")
	Events.damaged.connect(_on_damaged)
	anim_player.speed_scale = randf_range(0.5, 2.0)


func setup(rng: RandomNumberGenerator) -> void:
	iron_amount = rng.randf_range(min_iron_amount, max_iron_amount)
	scale *= max(iron_amount / max_iron_amount, min_scale)


func mine_amount(value: float) -> float:
	return _remove_iron(value)


func take_damage(value: float) -> void:
	# Weapon damage destroys the affected ore; it is not transferred to player cargo.
	_remove_iron(value)


func get_gravity_attraction(target_position: Vector2) -> Vector2:
	if _is_depleted or atraccion <= 0.0:
		return Vector2.ZERO
	var direction := global_position - target_position
	var distance := direction.length()
	if distance <= 0.0 or distance >= RADIO_ATRACCION:
		return Vector2.ZERO
	var falloff := 1.0 - distance / RADIO_ATRACCION
	return direction / distance * atraccion * falloff


func _remove_iron(value: float) -> float:
	if _is_depleted or value <= 0.0:
		return 0.0

	var mined_amount: float = min(iron_amount, value)
	if mined_amount <= 0.0:
		return 0.0
	iron_amount -= mined_amount
	mined.emit(mined_amount)

	if is_equal_approx(iron_amount, 0.0):
		_is_depleted = true
		undock()
		depleted.emit()
		shrink()
	elif not fx_anim_player.is_playing():
		fx_anim_player.play("pulse")

	return mined_amount


func _on_damaged(target: Node, amount: float, _shooter: Node) -> void:
	if target == collision_shape.get_parent():
		take_damage(amount)


# Animates the asteroid shrinking down and frees it.
func shrink() -> void:
	var fx_tween = create_tween()
	if fx_anim_player.is_playing():
		fx_anim_player.stop(false)
	fx_tween.tween_property(
		sprite, "scale", Vector2.ZERO, 0.25
	).from_current().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	fx_tween.tween_property(
		dock_aura, "scale", Vector2.ZERO, 0.5
	).from_current().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	fx_tween.play()
	await fx_tween.finished
	queue_free()


func _on_DockingArea_body_entered(body: Node) -> void:
	super._on_DockingArea_body_entered(body)
	anim_player.stop(false)


func _on_DockingArea_body_exited(body: Node) -> void:
	super._on_DockingArea_body_exited(body)
	anim_player.play()
