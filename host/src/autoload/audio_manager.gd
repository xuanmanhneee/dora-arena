extends Node

const UI_BGM_PATH := "res://assets/audio/bgm/ui-bgm.mp3"
const GAME_BGM_PATH := "res://assets/audio/bgm/game-bgm.mp3"

const UI_HOVER_SFX := "res://assets/audio/sfx/ui/hover.wav"
const UI_CLICK_SFX := "res://assets/audio/sfx/ui/click.wav"

const SHOOT_SFX := "res://assets/audio/sfx/shoot.wav"
const PICKUP_ITEM_SFX := "res://assets/audio/sfx/pickup_item.mp3"
const REFLECT_BULLET_SFX := "res://assets/audio/sfx/reflect_bullet.mp3"
const RESPAWN_SFX := "res://assets/audio/sfx/respawn.mp3"
const END_GAME_SFX := "res://assets/audio/sfx/end_game.mp3"

const MIN_VOLUME_DB := -80.0
const BGM_FADE_DURATION := 0.8

@onready var ui_bgm_player := AudioStreamPlayer.new()
@onready var game_bgm_player := AudioStreamPlayer.new()

var bgm_volume := 0.5
var sfx_volume := 0.8
var bgm_tween: Tween


func _ready() -> void:
	add_child(ui_bgm_player)
	add_child(game_bgm_player)

	EventBus.subscribe("game_over", _on_game_over)
	EventBus.subscribe("game_restarted", _on_game_restarted)
	EventBus.subscribe("player_respawned", _on_player_respawned)
	EventBus.subscribe("player_shoot", _on_player_shoot)
	EventBus.subscribe("player_pickup_item", _on_item_picked)

	load_settings()
	apply_volume()

	play_ui_bgm()


func _on_game_over(_winner) -> void:
	fade_out_bgm()
	play_end_game()


func _on_game_restarted() -> void:
	play_game_bgm()


func _on_player_respawned(_player) -> void:
	play_respawn()


func _on_player_shoot(_player = null) -> void:
	play_shoot()


func _on_item_picked(_player = null, _item = null) -> void:
	play_pickup_item()


# =========================
# BGM
# =========================

func play_ui_bgm() -> void:
	_crossfade_bgm(ui_bgm_player, game_bgm_player, UI_BGM_PATH)


func play_game_bgm() -> void:
	_crossfade_bgm(game_bgm_player, ui_bgm_player, GAME_BGM_PATH)


func stop_bgm() -> void:
	_stop_all_bgm()


func fade_out_bgm() -> void:
	if bgm_tween:
		bgm_tween.kill()

	bgm_tween = create_tween()

	if ui_bgm_player.playing:
		bgm_tween.parallel().tween_property(ui_bgm_player, "volume_db", MIN_VOLUME_DB, BGM_FADE_DURATION)

	if game_bgm_player.playing:
		bgm_tween.parallel().tween_property(game_bgm_player, "volume_db", MIN_VOLUME_DB, BGM_FADE_DURATION)

	await bgm_tween.finished
	_stop_all_bgm()


func _crossfade_bgm(next_player: AudioStreamPlayer, old_player: AudioStreamPlayer, path: String) -> void:
	var stream := load(path)

	if stream == null:
		push_error("Failed to load BGM: " + path)
		return

	if bgm_tween:
		bgm_tween.kill()

	var target_db := _get_bgm_volume_db()

	next_player.stream = stream
	next_player.volume_db = MIN_VOLUME_DB
	next_player.play()

	bgm_tween = create_tween()
	bgm_tween.tween_property(next_player, "volume_db", target_db, BGM_FADE_DURATION)

	if old_player.playing:
		bgm_tween.parallel().tween_property(old_player, "volume_db", MIN_VOLUME_DB, BGM_FADE_DURATION)

	await bgm_tween.finished

	if old_player.playing:
		old_player.stop()

	old_player.volume_db = target_db
	next_player.volume_db = target_db


func _stop_all_bgm() -> void:
	if bgm_tween:
		bgm_tween.kill()

	ui_bgm_player.stop()
	game_bgm_player.stop()

	apply_volume()


func _get_bgm_volume_db() -> float:
	return linear_to_db(max(bgm_volume, 0.0001))


# =========================
# SFX
# =========================

func play_sfx(path: String) -> void:
	var stream := load(path)

	if stream == null:
		push_warning("Missing SFX: " + path)
		return

	var sfx_player := AudioStreamPlayer.new()
	add_child(sfx_player)

	sfx_player.stream = stream
	sfx_player.volume_db = linear_to_db(max(sfx_volume, 0.0001))
	sfx_player.finished.connect(sfx_player.queue_free)
	sfx_player.play()


# =========================
# UI SFX
# =========================

func play_ui_hover() -> void:
	play_sfx(UI_HOVER_SFX)


func play_ui_click() -> void:
	play_sfx(UI_CLICK_SFX)


# =========================
# GAME SFX
# =========================

func play_shoot() -> void:
	play_sfx(SHOOT_SFX)


func play_pickup_item() -> void:
	play_sfx(PICKUP_ITEM_SFX)


func play_reflect_bullet() -> void:
	play_sfx(REFLECT_BULLET_SFX)


func play_respawn() -> void:
	play_sfx(RESPAWN_SFX)


func play_end_game() -> void:
	play_sfx(END_GAME_SFX)


# =========================
# VOLUME
# =========================

func set_bgm_volume(value: float) -> void:
	bgm_volume = clamp(value, 0.0, 1.0)
	apply_volume()
	save_settings()


func set_sfx_volume(value: float) -> void:
	sfx_volume = clamp(value, 0.0, 1.0)
	save_settings()


func apply_volume() -> void:
	var db := _get_bgm_volume_db()

	if not ui_bgm_player.playing:
		ui_bgm_player.volume_db = db

	if not game_bgm_player.playing:
		game_bgm_player.volume_db = db

	if ui_bgm_player.playing:
		ui_bgm_player.volume_db = db

	if game_bgm_player.playing:
		game_bgm_player.volume_db = db


# =========================
# SETTINGS
# =========================

func load_settings() -> void:
	bgm_volume = SettingsManager.get_setting("audio", "bgm_volume", 0.5)
	sfx_volume = SettingsManager.get_setting("audio", "sfx_volume", 0.8)


func save_settings() -> void:
	SettingsManager.set_setting("audio", "bgm_volume", bgm_volume)
	SettingsManager.set_setting("audio", "sfx_volume", sfx_volume)
