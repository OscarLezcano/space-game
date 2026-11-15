extends Control

@onready var energy_bar := $EnergyBar
@onready var cargo_gauge := $CargoGauge


func initialize(player: PlayerShip) -> void:
	energy_bar.initialize(player)
	cargo_gauge.initialize(player)
