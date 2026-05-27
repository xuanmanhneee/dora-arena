extends Node

const FALLBACK_LOCALE := "vi"
const UI_ASSET_PATH := "res://assets/ui"

func _ready() -> void:
	var locale = SettingsManager.get_setting(
		"localization",
		"locale",
		FALLBACK_LOCALE
	)

	TranslationServer.set_locale(locale)

func set_locale(locale: String) -> void:
	TranslationServer.set_locale(locale)

	SettingsManager.set_setting(
		"localization",
		"locale",
		locale
	)

	EventBus.emit("locale_changed")

func text(key: String) -> String:
	return TranslationServer.translate(key)

func texture(base_name: String) -> Texture2D:
	var locale := TranslationServer.get_locale()

	var localized_path := "%s/%s_%s.png" % [
		UI_ASSET_PATH,
		base_name,
		locale
	]

	if ResourceLoader.exists(localized_path):
		return load(localized_path)

	var fallback_path := "%s/%s_%s.png" % [
		UI_ASSET_PATH,
		base_name,
		FALLBACK_LOCALE
	]

	if ResourceLoader.exists(fallback_path):
		return load(fallback_path)

	push_warning("Missing localized texture: %s" % base_name)
	return null

func bbcode_text(base_name: String) -> String:
	var locale := TranslationServer.get_locale()

	var path := "res://data/localization/%s_%s.txt" % [
		base_name,
		locale
	]

	if FileAccess.file_exists(path):
		return FileAccess.get_file_as_string(path)

	var fallback_path := "res://data/localization/%s_%s.txt" % [
		base_name,
		FALLBACK_LOCALE
	]

	if FileAccess.file_exists(fallback_path):
		return FileAccess.get_file_as_string(fallback_path)

	push_warning("Missing localized text file: %s" % base_name)
	return ""

func localized_text_file(base_name: String) -> String:
	var locale := TranslationServer.get_locale()

	var path := "res://data/localization/%s_%s.txt" % [
		base_name,
		locale
	]

	if FileAccess.file_exists(path):
		return FileAccess.get_file_as_string(path)

	var fallback_path := "res://data/localization/%s_%s.txt" % [
		base_name,
		FALLBACK_LOCALE
	]

	if FileAccess.file_exists(fallback_path):
		return FileAccess.get_file_as_string(fallback_path)

	push_warning("Missing localized text file: %s" % base_name)
	return ""
