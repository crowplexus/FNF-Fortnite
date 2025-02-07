extends Node

## Default App Client ID, for Discord RPC
const DISCORD_RPC_ID: int = 1328904269151338507
## Default Large Image that shows up on Discord.
const DISCORD_RPC_DEFAULT_LI: String = "default-fortnite"
## Default assets for charts, used in case "assets.tres" is missing in the chart folder.
const DEFAULT_CHART_ASSETS: ChartAssets = preload("res://assets/default/chart_assets.tres")
## Default Text that shows up when you hover over the large image on Discord.
const DISCORD_RPC_DEFAULT_LI_TEXT: String = ""
## Default Chart Difficulty.
const DEFAULT_DIFFICULTY: String = "normal"

@onready var bgm: AudioStreamPlayer = $"%background_music"
@onready var sfx: Node = $"%sound_effects"
@onready var resources: ResourcePreloader = $"%resource_preloader"
var music_fade_tween: Tween

var settings: Settings = Settings.new()

func _ready() -> void:
	reset_discord()

func _unhandled_key_input(event: InputEvent) -> void:
	if event.keycode == KEY_F11 and event.pressed:
		var is_full: bool = get_window().mode == Window.Mode.MODE_FULLSCREEN
		get_window().mode = Window.MODE_WINDOWED if is_full else Window.MODE_FULLSCREEN

## [see]lerpf[/see]
func lerpv2(v1: Vector2, v2: Vector2, weight: float = 1.0) -> Vector2:
	return Vector2(
		lerpf(v1.x, v2.x, weight),
		lerpf(v1.y, v2.y, weight)
	)
##
func request_audio_fade(player: AudioStreamPlayer, to: float = 0.0, speed: float = 1.0) -> AudioStreamPlayer:
	if to < 0.0: return
	if music_fade_tween: music_fade_tween.stop()
	var new_vol: float = linear_to_db(to)
	var cur_vol: float = db_to_linear(player.volume_db)
	music_fade_tween = create_tween().set_ease(Tween.EASE_IN if new_vol > cur_vol else Tween.EASE_OUT)
	music_fade_tween.tween_property(player, "volume_db", new_vol, speed)
	return player

## Plays background music (remember to stop it if you're switching to a scene that has custom music nodes).
func play_bgm(stream: AudioStream, volume: float = 1.0, loop: bool = true) -> AudioStreamPlayer:
	bgm.stop()
	bgm.stream = stream
	bgm.volume_db = linear_to_db(volume)
	#bgm.pitch_scale = pitch
	bgm.stream.loop = loop
	bgm.play(0.0)
	return bgm

## Plays a sound effect.
func play_sfx(stream: AudioStream, volume: float = 0.7, pitch: float = 1.0) -> void:
	var asp: AudioStreamPlayer = AudioStreamPlayer.new()
	asp.bus = "Sound Effects"
	asp.stream = stream
	asp.pitch_scale = pitch
	asp.volume_db = linear_to_db(volume)
	asp.finished.connect(asp.queue_free)
	sfx.add_child(asp)
	asp.play(0.0)

### Returns "PAUSED" if the tree is paused.
func get_paused_string() -> String:
	return "PAUSED" if get_tree().paused else ""

## Returns a game mode string based on the integer given.[br]
## [code]1 = "STORY MODE"[/code][br]
## [code]2 = "FREEPLAY"[/code][br]
## [code]3 = "CHARTING"[/code]
func get_mode_string(game_mode: int) -> String:
	match game_mode:
		0: return "STORY MODE"
		1: return "FREEPLAY"
		2: return "CHARTING"
		_: return ""

## Formats a float to a digital clock string[br]
## Like: 1:25
func format_to_time(value: float) -> String:
	var minutes: float = Global.float_to_minute(value)
	var seconds: float = Global.float_to_seconds(value)
	var formatter: String = "%2d:%02d" % [minutes, seconds]
	var hours: int = Global.float_to_hours(value)
	if hours != 0: # append hours if needed
		formatter = ("%2d:%02d:02d" % [hours, minutes, seconds])
	return formatter

## Gets the current weekday as a name
func get_weekday_string() -> String:
	var weekday: Time.Weekday = Time.get_date_dict_from_system().weekday
	match weekday:
		0: return "Sunday"
		1: return "Monday"
		2: return "Tuesday"
		3: return "Wednesday"
		4: return "Thursday"
		5: return "Friday"
		_: return "Unknown"

func float_to_hours(value: float) -> int: return int(value / 3600.0)
func float_to_minute(value: float) -> int: return int(value / 60) % 60
func float_to_seconds(value: float) -> float: return fmod(value, 60)

## Resets the state of the Discord RPC plugin back to the defaults.
func reset_discord() -> void:
	DiscordRPC.app_id = DISCORD_RPC_ID
	update_discord_images()

## Updates the details and state of Discord RPC.
func update_discord(state: String, details: String) -> void:
	DiscordRPC.state = state
	DiscordRPC.details = details
	DiscordRPC.refresh()

## Updates the images used in Discord RPC.
func update_discord_images(large: String = DISCORD_RPC_DEFAULT_LI, small: String = "", large_txt: String = DISCORD_RPC_DEFAULT_LI_TEXT, small_txt: String = "") -> void:
	DiscordRPC.large_image = large
	DiscordRPC.large_image_text = large_txt
	if small and small.length() != 0:
		DiscordRPC.small_image = small
		DiscordRPC.small_image_text = small_txt
	DiscordRPC.refresh()
