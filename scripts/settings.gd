class_name Settings
extends Resource

const IGNORED_PROPERTIES: PackedStringArray = ["resource_local_to_scene", "resource_scene_unique_id", "resource_name", "resource_path", "script"]

## Defines the Master Volume of the game.
var master_volume: int = 20:
	set(new_mv):
		master_volume = clampi(new_mv, 0, 100)
		AudioServer.set_bus_volume_db(0, linear_to_db(master_volume * 0.01))
## Shortcut setting for muting the whole game.
var master_mute: bool = false:
	set(new_mute):
		AudioServer.set_bus_mute(0, new_mute)
		master_mute = new_mute
## Alternates between in-game scroll directions.
@export_enum("Up:0","Down:1")
var scroll: int = 0
## Prevents inputs from punishing you if you press keys when there's no notes to hit.
@export var ghost_tapping: bool = true
## Defines the maximum timing window for a note to be hittable.
@export var max_hit_window: float = 0.18 # 180ms
## Locks framerate to your monitor's refresh rate[br]
## May help reducing screen tearing.
@export var vsync: bool = false:
	set(new_vsync):
		var value: = DisplayServer.VSYNC_ADAPTIVE if new_vsync else DisplayServer.VSYNC_DISABLED
		DisplayServer.window_set_vsync_mode(value)
		vsync = new_vsync
## Enables a 5th judgement not originally present in the game.
@export var use_epics: bool = true
## Defines the intensity of the Camera Bump.
@export var bump_intensity: int = 100:
	set(new_bi):
		bump_intensity = clampi(new_bi, 0, 100)
## Defines the intensity of the HUD Bump.
@export var hud_bump_intensity: int = 100:
	set(new_bi):
		hud_bump_intensity = clampi(new_bi, 0, 100)
## Changes the UI elements and dialogue language.
@export var language: String = "en"


func _init(use_defaults: bool = false) -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(master_volume * 0.01))
	if not use_defaults: # not a "defaults-only" instance
		reload_custom_settings()


func reload_custom_settings() -> void:
	if not ResourceLoader.exists("user://settings.tres"):
		return
	var custom_settings: Settings = load("user://settings.tres")
	for key: String in get_settings().keys():
		if get(key) != custom_settings.get(key):
			set(key, custom_settings.get(key))
	custom_settings.unreference()
	custom_settings.free()


func get_settings() -> Dictionary:
	var props: Dictionary[String, Variant] = {}
	for prop in get_property_list():
		if not IGNORED_PROPERTIES.has(prop.name) and get(prop.name) != null:
			props[prop.name] = get(prop.name)
	return props


func save_settings() -> void:
	ResourceSaver.save(self, "user://settings.tres")
