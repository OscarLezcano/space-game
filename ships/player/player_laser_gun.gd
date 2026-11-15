# LaserGun that fires based on user's input

extends LaserGun

@export var fire_action := "fire2"


func _physics_process(delta: float) -> void:
	if not is_firing:
		return
	var player := owner as PlayerShip
	if not player or not player.consume_energy(PlayerShip.ENERGY_PER_LASER_SECOND * delta):
		is_firing = false
		return
	super._physics_process(delta)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo():
		return
	if event.is_action(fire_action):
		self.is_firing = event.is_pressed()
