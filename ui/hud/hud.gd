extends Control

@onready var energy_bar := $EnergyBar
@onready var cargo_gauge := $CargoGauge


func _ready() -> void:
	Localization.locale_changed.connect(_on_locale_changed)
	_on_locale_changed(Localization.locale)


func initialize(player: PlayerShip) -> void:
	energy_bar.initialize(player)
	cargo_gauge.initialize(player)


func _on_locale_changed(_locale: String) -> void:
	$EnergyLabel.text = tr("ENERGÍA")
