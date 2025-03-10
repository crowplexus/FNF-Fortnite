class_name Player
extends Node

signal hit_note(note: Note)
signal miss_note(note: Note, dir: int)

## Actions to use for controlling.
@export var controls: PackedStringArray = [ "note_left", "note_down", "note_up", "note_right" ]
## How many of the receptors are being held at a time
var keys_held: Array[bool] = []

var game: Node2D = null
var note_field: NoteField = null
var force_disable_input: bool = false

func _ready() -> void:
	note_field = get_parent()
	if get_tree().current_scene and get_tree().current_scene is Node2D:
		game = get_tree().current_scene
		if game is Gameplay:
			hit_note.connect(game.on_note_hit)
			miss_note.connect(game.on_note_miss)
	keys_held.resize(controls.size())
	keys_held.fill(false)

func _process(delta: float) -> void:
	if not game or not game.note_group or game.note_group.note_list.is_empty():
		return
	for note: Note in game.note_group.get_children():
		if not note.visible or note.hold_size <= 0.0 or note.hold_timer <= 0.0 or note.side != note_field.get_index() or not note.was_hit:
			continue
		note.update_hold(delta)
		if keys_held[note.column]:
			note_field.play_animation(note.column, NoteField.RepState.CONFIRM)
		else:
			note.hold_timer -= 0.05 * absf(note.hold_size)
		if note.hold_timer <= 0.0:
			note_field.play_animation(note.column, NoteField.RepState.STATIC, true)
			miss_note.emit(note, note.column)
			note.dropped = true
			note.moving = true
			#note.hide_all()

func _unhandled_key_input(event: InputEvent) -> void:
	var idx: int = get_action_id(event)
	if not game is Gameplay or not note_field or force_disable_input or idx == -1:
		return
	var action: String = controls[idx]
	keys_held[idx % keys_held.size()] = Input.is_action_pressed(action)
	if Input.is_action_just_released(action):
		note_field.play_animation(idx, NoteField.RepState.STATIC)
		return
	if Input.is_action_just_pressed(action):
		# two methods for inputs I'm just testing this shit
		##var hit_note: Note
		##for n: Note in game.note_group.get_children():
		##	if n.column == idx and n.side == note_field.get_index() and n.is_hittable(game.max_hit_window):
		##			hit_note = n
		##			break
		var notes: Array = game.note_group.get_children().filter(func(n: Note) -> bool:
			return idx == n.column and note_field.get_index() == n.side)
		# TODO: fix the one bug where you hit both notes in a jack
		if not notes.is_empty():
			notes.sort_custom(func(a: Note, b: Note) -> bool: return a.time < b.time)
			var note: Note = notes.front()
			if note.is_hittable(game.max_hit_window):
				hit_note.emit(note)
				if note.was_hit:
					note.hit_time = note.time - Conductor.playhead
					if note.hold_size <= 0.0:
						note.hide_all()
					else:
						note.hold_timer = 1.0
						note._stupid_visual_bug = note.hit_time < 0.0
						note.allowed_to_hide = false
					note_field.play_animation(idx, NoteField.RepState.CONFIRM)
		else:
			note_field.play_animation(idx, NoteField.RepState.PRESSED)
			if not Global.settings.ghost_tapping:
				miss_note.emit(null, idx)


func get_action_id(event: InputEvent) -> int:
	var id: int = -1
	if event.is_echo(): return id
	for garlic_bread: int in controls.size():
		if event.is_action(controls[garlic_bread]):
			id = garlic_bread
			break
	return id

func get_action_name(event: InputEvent) -> String:
	var id: String
	if event.is_echo(): return id
	for garlic_bread: String in controls:
		if event.is_action(garlic_bread):
			id = garlic_bread
			break
	return id
