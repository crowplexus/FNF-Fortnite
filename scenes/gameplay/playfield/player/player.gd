class_name Player
extends Node

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
	keys_held.resize(controls.size())
	keys_held.fill(false)

func _process(delta: float) -> void:
	if not game or not game.note_group or game.note_group.note_list.is_empty():
		return
	for note: Note in game.note_group.get_children():
		if not note.visible or note.hold_size <= 0.0 or note.hold_timer <= 0.0 or \
			note.data.side != note_field.get_index() or note.was_missed or note.dropped:
			continue
		note.update_hold(delta)
		if keys_held[note.data.column]:
			note_field.play_animation(note.data.column, NoteField.RepState.CONFIRM)
		else:
			note.hold_timer -= 0.05 * absf(note.hold_size)
		if note.hold_timer <= 0.0:
			note_field.play_animation(note.data.column, NoteField.RepState.STATIC, true)
			game.on_note_miss(note)
			note.dropped = true
			note.moving = true
			#note.hide_all()


func get_action_id(event: InputEvent) -> int:
	var id: int = -1
	for garlic_bread: int in controls.size():
		if event.is_action(controls[garlic_bread]):
			id = garlic_bread
			#print("a ", id)
			break
	return id


func get_action_name(event: InputEvent) -> String:
	var id: String = ""
	for garlic_bread: String in controls:
		if event.is_action(garlic_bread):
			id = garlic_bread
			break
	return id


func _unhandled_key_input(event: InputEvent) -> void:
	if not game is Gameplay or not note_field or force_disable_input:
		return
	var action: String = get_action_name(event)
	if action.dedent().is_empty():
		return
	var idx: int = controls.find(action)
	keys_held[idx % keys_held.size()] = Input.is_action_pressed(action)
	if Input.is_action_just_released(action):
		note_field.play_animation(idx, NoteField.RepState.STATIC)
		return
	if Input.is_action_just_pressed(action):
		var inputs: Array = game.note_group.get_children().filter(func(n) -> bool:
			return n.data and n.data.column == idx and n.is_hittable(game.max_hit_window * 0.001) \
				and n.data.side == note_field.get_index() and not n.was_hit and not n.was_missed)
		if inputs.is_empty():
			note_field.play_animation(idx, NoteField.RepState.PRESSED)
		else:
			inputs.sort_custom(func(n1: Note, n2: Note) -> bool:
				return n1.data.time < n2.data.time)
			var hit_note: Note = inputs[0]
			if not hit_note:
				note_field.play_animation(idx, NoteField.RepState.PRESSED)
			else:
				if hit_note:
					note_field.play_animation(idx, NoteField.RepState.CONFIRM)
					game.on_note_hit(hit_note)
					if hit_note.hold_size > 0.0:
						hit_note.hold_timer = 1.0
						hit_note._stupid_visual_bug = (hit_note.data.time - Conductor.time) < 0.0
					else:
						hit_note.hide_all()
