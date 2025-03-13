extends Player

func _ready() -> void:
	note_field = get_parent()
	if get_tree().current_scene and get_tree().current_scene is Node2D:
		game = get_tree().current_scene
	hit_note.connect(on_note_hit)

func _process(delta: float) -> void:
	if not game or not game.note_group:
		return
	for note: Note in game.note_group.get_children():
		if note.time <= Conductor.playhead and note.side == note_field.get_index():
			hit_note.emit(note)
			note.was_hit = true
			var was_hold: bool = note.hold_size > 0.0
			if note.hold_size > 0.0:
				note.update_hold(delta)
				if fmod(note.hold_size, 0.05) == 0:
					note_field.play_animation(note.column, NoteField.RepState.CONFIRM)
					hit_hold_note.emit(note)
				note.allowed_to_hide = true
			if note.hold_size <= 0.0:
				if was_hold: note_field.play_animation(note.column, NoteField.RepState.STATIC)
				game.note_group.on_note_deleted.emit(note)
				note.hide_all()

func _unhandled_key_input(_e: InputEvent) -> void:
	return # disable input lol...

func on_note_hit(note: Note) -> void:
	note_field.play_animation(note.column, NoteField.RepState.CONFIRM)
	note_field.set_reset_timer(note.column, 0.3 * Conductor.crotchet)
