# Presents a confirmation screen whether the player really intends on leaving
# the game back to the main menu or not.
extends MarginContainer

@onready var yes_button := $VBoxContainer/HBoxContainer/YesButton
@onready var no_button := $VBoxContainer/HBoxContainer/NoButton
@onready var title_label: Label = $VBoxContainer/Label
@onready var yes_label: Label = $VBoxContainer/HBoxContainer/YesButton/Label
@onready var no_label: Label = $VBoxContainer/HBoxContainer/NoButton/Label
@onready var language_button: Button = $VBoxContainer/LanguageButton
@onready var menu_sounds: MenuSoundPlayer = $MenuSoundPlayer


func _ready() -> void:
	visible = false
	set_process_input(false)
	Localization.locale_changed.connect(_on_locale_changed)
	language_button.pressed.connect(Localization.toggle_locale)
	_on_locale_changed(Localization.locale)
	for button in [yes_button, no_button]:
		button.connect("focus_entered", _on_Button_focus_entered)


func _on_locale_changed(_locale: String) -> void:
	title_label.text = tr("¿Seguro que quieres salir?")
	yes_label.text = tr("Sí")
	no_label.text = tr("No")
	language_button.text = Localization.current_language_code()
	language_button.tooltip_text = tr("Cambiar idioma")


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


func open() -> void:
	get_tree().paused = true
	menu_sounds.play_open()
	show()
	no_button.grab_focus()
	set_process_input(true)


func close() -> void:
	menu_sounds.play_close()
	get_tree().paused = false
	set_process_input(false)
	hide()


func request_quit() -> void:
	Events.quit_requested.emit()
	close()


func _on_YesButton_pressed() -> void:
	request_quit()


func _on_NoButton_pressed() -> void:
	close()


func _on_Button_focus_entered() -> void:
	menu_sounds.play_hide()
