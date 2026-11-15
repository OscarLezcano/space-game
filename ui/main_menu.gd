# Changes scenes after fading the screen on `any key` or on the A/B/cross
# buttons on a gamepad.
extends Control

const FADE_IN_TIME := 0.5
const FADE_OUT_TIME := 2.5

@onready var screen_fader: TextureRect = $FadeLayer/ScreenFader
@onready var main_screen := $Background/MainScreen

@onready var menu_sounds: MenuSoundPlayer = $MenuSoundPlayer

var _language_button: Button

func _ready() -> void:
	screen_fader.fade_in()
	_add_language_button()
	Localization.locale_changed.connect(_update_language_button)


func _add_language_button() -> void:
	_language_button = Button.new()
	_language_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_language_button.offset_left = -150.0
	_language_button.offset_top = 24.0
	_language_button.offset_right = -24.0
	_language_button.offset_bottom = 60.0
	_language_button.focus_mode = Control.FOCUS_NONE
	_language_button.tooltip_text = tr("Cambiar idioma")
	_language_button.pressed.connect(_on_language_button_pressed)
	add_child(_language_button)
	_update_language_button()


func _update_language_button(_locale: String = "") -> void:
	if is_instance_valid(_language_button):
		_language_button.text = Localization.current_language_code()
		_language_button.tooltip_text = tr("Cambiar idioma")


func _on_language_button_pressed() -> void:
	Localization.toggle_locale()


func _unhandled_input(event: InputEvent) -> void:
	if screen_fader.is_playing:
		return
	if event is InputEventKey or event.is_action_pressed("thrust_forwards"):
		main_screen.animator.play_backwards("intro")
		menu_sounds.play_confirm()
		screen_fader.fade_out()
		await screen_fader.animation_finished
		get_tree().change_scene_to_file("res://ui/rocket_builder.tscn")
