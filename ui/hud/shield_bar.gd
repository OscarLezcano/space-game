# Energy meter for the player's ship.
extends TextureProgressBar

@export var gradient: Gradient
@export var danger_threshold := 0.3

@onready var anim_player := $AnimationPlayer


func initialize(player: PlayerShip) -> void:
	player.energy_changed.connect(_on_energy_changed)
	_on_energy_changed(player.energy, player.max_energy)


func _on_energy_changed(current_energy: float, max_energy: float) -> void:
	max_value = maxf(max_energy, 1.0)
	value = current_energy
	var energy_ratio := current_energy / max_energy if max_energy > 0.0 else 0.0
	tint_progress = gradient.sample(energy_ratio)
	if energy_ratio <= danger_threshold:
		if anim_player.current_animation != "danger":
			anim_player.play("danger")
	elif anim_player.current_animation == "danger":
		anim_player.stop()
		tint_progress = gradient.sample(energy_ratio)
