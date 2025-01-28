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

var settings: Settings = Settings.new()

func _ready() -> void:
	reset_discord()

func _unhandled_key_input(event: InputEvent) -> void:
	if event.pressed and event.keycode == KEY_P:
		get_tree().paused = not get_tree().paused

func play_bgm(stream: AudioStream, volume: float = 1.0, loop: bool = true) -> void:
	bgm.stop()
	bgm.volume_db = linear_to_db(volume)
	#bgm.pitch_scale = pitch
	bgm.stream = stream
	bgm.stream.loop = loop
	bgm.play(0.0)

## Plays a sound effect.
func play_sfx(stream: AudioStream, volume: float = 0.7, pitch: float = 1.0) -> void:
	var asp: AudioStreamPlayer = AudioStreamPlayer.new()
	asp.bus = "Sound Effects"
	asp.stream = stream
	asp.pitch_scale = pitch
	asp.volume_db = linear_to_db(volume)
	asp.finished.connect(asp.free)
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
