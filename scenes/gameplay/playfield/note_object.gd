## Node to create new note types from a basic object.[br]
## You can decide how it looks, how it loads, etc.[br][br]
## Scene Tree must look like this:[br][br]
## arrow (Any Node2D type)[br]
## clip_rect (Any Control Type)[br]
##		hold_body (TextureRect)[br]
##		hold_tail (Any Type)[br]
class_name Note
extends Node2D

## Default Directions.
const COLORS: PackedStringArray = ["purple","blue","green","red"]

## Default Note Distance (in pixels)
const DISTANCE: float = 450.0
## Default Hold Distance (in pixels)
const DISTANCE_HOLD: float = 2000.0

static func get_scroll_as_vector(scroll: int) -> Vector2:
	match scroll:
		1: return Vector2(-1, 1) # Down
		_: return -Vector2.ONE # Up (default)

## If note splashes should be forced to appear regardless of the judgement.
@export var forced_splash: bool = false
## This is for the notefield that the note is targetting.
var note_field: NoteField
## Data used mainly for hold sizes and whatnot.
var data: NoteData:
	set(new_data):
		time = new_data.time
		column = new_data.column
		length = new_data.length
		kind = new_data.kind
		side = new_data.side
## (Current) Hold Size, not to be confused with [code]data.length[/code]
var hold_size: float = 0.0
## Hold note body, gets attached if [code]$"clip_rect/hold_body"[/code]
## exists in the scene tree.
var hold_body: TextureRect
## Hold note tail, gets attached if [code]$"clip_rect/hold_tail"[/code]
## exists in the scene tree.
var hold_tail: Node2D
## Control Node for hiding offscreen hold notes.
var clip_rect: Control

## Note Spawn Time (in seconds).
var time: float = -1.0
## Note Column/Direction.
var column: int = -1
## Note Player ID/Side.[br]0 = Enemy, 1 = Player, etc...
var side: int = -1
## Note Type/Kind, if unspecified or non-existant,
## The default note type will be used instead.
var kind: StringName
## Note Length, spawns a tail in the note if specified.
var length: float = -1.0

# Input stuff
var was_hit: bool = false
var was_missed: bool = false
#var late_hitbox: float = 1.0
#var early_hitbox: float = 1.0
var hit_time: float = 0.0
# FOR HOLDS
var dropped: bool = false
var hold_timer: float = 0.0
var _stupid_visual_bug: bool = false
var allowed_to_hide: bool = true
# VISUALS
var scroll_mult: Vector2 = -Vector2.ONE
var moving: bool = true

func hide_all() -> void: queue_free()
func show_all() -> void: show()

func _ready() -> void:
	hold_size = length
	scroll_mult = Note.get_scroll_as_vector(Global.settings.scroll)
	if has_node("clip_rect"):
		clip_rect = get_node("clip_rect")
		if has_node("clip_rect/hold_body"): hold_body = get_node("clip_rect/hold_body")
		if has_node("clip_rect/hold_tail"): hold_tail = get_node("clip_rect/hold_tail")
		clip_rect.scale *= -scroll_mult


func scroll_ahead() -> void:
	if not note_field or column == -1:
		return
	var strum_speed: float = note_field.speed * note_field.get_receptor(column).speed
	position.y = Note.DISTANCE * (Conductor.playhead - time) * strum_speed / absf(scale.y)
	position.y *= scroll_mult.y
	position.y += note_field.global_position.y

func update_hold(delta: float) -> void:
	moving = false
	if _stupid_visual_bug:
		hold_size += hit_time / absf(clip_rect.scale.y)
		_stupid_visual_bug = false
	hold_size -= delta / absf(clip_rect.scale.y)
	display_hold(hold_size)
	if hold_size <= 0.0:
		hide_all()

## Use this function to initialise the note itself and related properties[br]
## Called whenever a note is spawned, remember to also call super(data)
func reload(_data: NoteData) -> void:
	_stupid_visual_bug = false
	was_missed = false
	was_hit = false
	moving = true

## Use this function for implementing hold note visuals.[br]
## Leave empty if you want your note type to not have holds.
func display_hold(size: float = 0.0, speed: float = 0.0 if data else 1.0) -> void:
	if column != -1 and not hold_body or not clip_rect:
		return
	if speed == 0.0:
		speed = note_field.speed * note_field.get_receptor(column).speed if note_field else 1.0
	# general implementation, should work for everything???
	hold_body.size.y = (Note.DISTANCE_HOLD * speed) * size
	hold_body.size.x = hold_body.texture.get_width()

## Use this function for implementing splash visuals.[br]
## Return null if you don't want note splashes on your note type.
func display_splash() -> Node2D:
	return null

## Checks if the note is in range to be hitp
func is_hittable(hit_window: float = 0.18) -> bool:
	#const diff: float = data.time - Conductor.playhead
	#return absf(diff) <= (hit_window * (early_hitbox if diff < 0 else late_hitbox))
	return absf(Conductor.playhead - time) <= hit_window and not was_hit and not was_missed
