class_name Actor2D
extends Node2D

## Beat delay for the character to bop its head.
@export var dance_interval: float = 2.0
## Dance Animations for the character to play every dance interval.
@export var dance_moves: PackedStringArray = ["idle"]
## Sing Animations for the character to play when hitting the corresponding notes.
@export var sing_moves: PackedStringArray = ["singLEFT", "singDOWN", "singUP", "singRIGHT"]
## How long it takes for a character to stop singing after doing so.
@export var sing_duration: float = 2.0
## Icon shown on the health bar.
@export var icon: HealthIcon
## Mark the character as a player (flips certain animations when its used as an opponent).
@export var is_player: bool = false

@onready var anim: AnimationPlayer = $"animation_player"
var idle_cooldown: float = 0.0
var pause_sing: bool = false
var _last_anim: String = ""
var _last_dance: int = 0

func _ready() -> void:
	Conductor.on_beat_hit.connect(_try_dance)

func _exit_tree() -> void:
	Conductor.on_beat_hit.disconnect(_try_dance)

func _process(delta: float) -> void:
	if idle_cooldown > 0.0 and not pause_sing:
		idle_cooldown -= delta / (Conductor.crotchet * sing_duration)
		if idle_cooldown <= 0.0:
			dance()

func _try_dance(beat: float) -> void:
	if fmod(beat, dance_interval) == 0 and idle_cooldown <= 0.0:
		dance()

func play_animation(animation: String, forced: bool = false, reversed: bool = false, speed: float = 1.0) -> void:
	if _last_anim != animation or forced: anim.seek(0.0)
	anim.play(animation, -1, speed, reversed)
	_last_anim = animation

func dance(forced: bool = false, reversed: bool = false, speed: float = 1.0) -> void:
	play_animation(dance_moves[_last_dance], forced, reversed, speed)
	_last_dance = wrapi(_last_dance + 1, 0, dance_moves.size())

func sing(direction: int, forced: bool = false, suffix: String = "", reversed: bool = false, speed: float = 1.0) -> void:
	play_animation(sing_moves[direction % sing_moves.size()] + suffix, forced, reversed, speed)
	idle_cooldown = 1.0
