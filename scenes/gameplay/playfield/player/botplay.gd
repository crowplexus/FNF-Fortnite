extends Player
func _process(delta: float) -> void:
	if not game or not game.note_group or game.note_group.note_list.is_empty():
		return
	for note: Note in game.note_group.get_children():
		if not note.visible:
			continue
		var data: NoteData = NoteData.EMPTY if not note.data else note.data
		if data.time <= Conductor.playhead and data.side == note_field.get_index():
			note.was_hit = true
			var was_hold: bool = note.hold_size > 0.0
			if note.hold_size > 0.0:
				note.update_hold(delta)
				note_field.play_animation(note.data.column, NoteField.RepState.CONFIRM)
			else:
				note.hide_all()
			if note.hold_size <= 0.0:
				if was_hold: note_field.play_animation(note.data.column, NoteField.RepState.STATIC)
				game.note_group.on_note_deleted.emit(Note.DeletionEventID.HIT, note)
func _unhandled_key_input(_e: InputEvent) -> void:
	return # disable input lol...
