extends Node

signal locale_changed(locale: String)

const SETTINGS_PATH := "user://settings.cfg"
const DEFAULT_LOCALE := "en"
const SUPPORTED_LOCALES := ["es", "en"]

var locale := DEFAULT_LOCALE


func _ready() -> void:
	var settings := ConfigFile.new()
	if settings.load(SETTINGS_PATH) == OK:
		var saved_locale := str(settings.get_value("localization", "locale", DEFAULT_LOCALE))
		if SUPPORTED_LOCALES.has(saved_locale):
			locale = saved_locale
	TranslationServer.set_locale(locale)


func toggle_locale() -> void:
	set_locale("en" if locale == "es" else "es")


func set_locale(new_locale: String) -> void:
	if not SUPPORTED_LOCALES.has(new_locale) or new_locale == locale:
		return

	locale = new_locale
	TranslationServer.set_locale(locale)
	var settings := ConfigFile.new()
	var load_error := settings.load(SETTINGS_PATH)
	if load_error != OK and load_error != ERR_FILE_NOT_FOUND:
		push_warning("No se pudieron cargar las preferencias del idioma.")
	settings.set_value("localization", "locale", locale)
	var save_error := settings.save(SETTINGS_PATH)
	if save_error != OK:
		push_warning("No se pudo guardar el idioma seleccionado.")
	locale_changed.emit(locale)


func current_language_code() -> String:
	return "ES" if locale == "es" else "EN"
