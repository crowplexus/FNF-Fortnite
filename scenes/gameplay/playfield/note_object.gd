## Node to create new note types from a basic object.[br]
## You can decide how it looks, how it loads, etc.[br][br]
## Scene Tree must look like this:[br][br]
## arrow (Any Node2D type)[br]
## clip_rect (Any Control Type)[br]
##		hold_body (TextureRect)[br]
##		hold_tail (Any Type)[br]
class_name Note
extends Node2D

enum DeletionEventID {
	DIE = 0,
	HIT = 1,
}

## Default Directions.
const COLORS: PackedStringArray = ["purple","blue","green","red"]

## Default Note Distance (in pixels)
const DISTANCE: float = 450.0

static func get_scroll_as_vector(scroll: int) -> Vector2:
	match scroll:
		1: return Vector2(-1, 1) # Down
		_: return -Vector2.ONE # Up (default)

## If note splashes should be forced to appear regardless of the judgement.
@export var forced_splash: bool = false
## This is for the notefield that the note is targetting.
var note_field: NoteField
## Data used mainly for hold sizes and whatnot.
var data: NoteData
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
# Input stuff
var was_hit: bool = false
var was_missed: bool = false
var late_hitbox: float = 1.0
var early_hitbox: float = 1.0
# FOR HOLDS
var dropped: bool = false
var hold_timer: float = 0.0
var _stupid_visual_bug: bool = false
# VISUALS
var scroll_mult: Vector2 = -Vector2.ONE
var moving: bool = true

func hide_all() -> void: queue_free()
func show_all() -> void: show()

func _ready() -> void:
	scroll_mult = Note.get_scroll_as_vector(Global.settings.scroll)
	if data:
		hold_size = data.length
	if has_node("clip_rect"):
		clip_rect = get_node("clip_rect")
		if has_node("clip_rect/hold_body"): hold_body = get_node("clip_rect/hold_body")
		if has_node("clip_rect/hold_tail"): hold_tail = get_node("clip_rect/hold_tail")
		clip_rect.scale *= -scroll_mult

func update_hold(delta:  float) -> void:
	#moving = false
	if _stupid_visual_bug:
		hold_size += (data.time - Conductor.time) / absf(clip_rect.scale.y)
		_stupid_visual_bug = false
	hold_size -= delta / absf(clip_rect.scale.y)
	#display_hold(hold_size)
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
func display_hold(size: float = 0.0, speed: float = data.speed if data else 1.0) -> void:
	# general implementation, should work for everything???
	if not data or not hold_body or not clip_rect:
		return
	var calc: float = size * (Note.DISTANCE * 2.0) * speed
	hold_body.size = Vector2(hold_body.texture.get_width(), calc / absf(hold_body.scale.y))

## Use this function for implementing splash visuals.[br]
## Return null if you don't want note splashes on your note type.
func display_splash() -> Node2D:
	return null

## Checks if the note is in range to be hit
func is_hittable(hit_window: float = 0.18) -> bool:
	return data.time > Conductor.playhead - (hit_window * late_hitbox) \
		and data.time < Conductor.playhead + (hit_window * early_hitbox)
