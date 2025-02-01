## Node to create new note types from a basic object.[br]
## You can decide how it looks, how it loads, etc.[br][br]
## Scene Tree must look like this:[br][br]
## arrow (Any Node2D type)[br]
## clip_rect (Any Control Type)[br]
##		hold_body (TextureRect)[br]
##		hold_tail (Any Type)[br]
class_name NoteObject
extends Node2D

## Default Directions.
const COLORS: PackedStringArray = ["purple","blue","green","red"]

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

func _ready() -> void:
	if data:
		hold_size = data.length
	if has_node("clip_rect"):
		clip_rect = get_node("clip_rect")
		if has_node("clip_rect/hold_body"): hold_body = get_node("clip_rect/hold_body")
		if has_node("clip_rect/hold_tail"): hold_tail = get_node("clip_rect/hold_tail")

## Use this function to initialise the note itself and related properties[br]
## Called whenever a note is spawned.
func reload(_data: NoteData) -> void:
	pass

## Use this function for implementing hold note visuals.[br]
## Leave empty if you want your note type to not have holds.
func display_hold(size: float = 0.0, speed: float = 1.0) -> void:
	if not data or not clip_rect or size <= 0.0:
		return
	if hold_body and hold_body.texture: # general implementation, should work for everything???
		hold_body.size = Vector2(hold_body.texture.get_width(),
			size * (450.0 * speed) / absf(hold_body.scale.y)
			#- (0.0 if not hold_tail else hold_tail.texture.get_height())
		)

## Use this function for implementing splash visuals.[br]
## Return null if you don't want note splashes on your note type.
func display_splash() -> Node2D:
	return null

## Checks if the note is in range to be hit
func is_hittable(hit_window: float = 180.0) -> bool:
	return data and data.time > Conductor.playhead - hit_window and data.time < Conductor.playhead + hit_window
