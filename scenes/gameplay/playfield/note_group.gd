extends Node

enum NoteDeletionType {
	DIE = 0,
	HIT = 1,
}

const TEMPLATE_NOTE: PackedScene = preload("res://scenes/gameplay/playfield/notes/normal_note.tscn")

signal on_note_spawned(data: NoteData, note: Note)
signal on_note_deleted(type: NoteDeletionType, note: Note)

@export var active: bool = true
var colours: Array[StringName] = [ &"purple", &"blue", &"green", &"red", ]
var note_list: Array[NoteData] = []
var max_hit_window: float = 180.0
var list_position: int = 0

func _ready() -> void:
	list_position = 0
	for i: int in 20: # precache this many notes
		var preload_note: = TEMPLATE_NOTE.instantiate()
		preload_note.name = "preload%s" % str(i)
		preload_note.top_level = true
		preload_note.hide()
		add_child(preload_note)


func _process(_delta: float) -> void:
	if not active or spawning_complete():
		return
	
	try_spawning()
	move_present_nodes()


func spawning_complete() -> bool:
	return note_list.size() == 0 or list_position >= note_list.size()


func move_present_nodes() -> void:
	for i: int in get_child_count():
		var node: Note = get_child(i)
		if not node.visible:
			continue
		# TODO: move to note class?
		var data: NoteData = NoteData.EMPTY if not node.data else node.data
		var rel_time: float = Conductor.playhead - data.time
		
		node.position.y = Note.DISTANCE * rel_time * data.speed / absf(node.scale.y)
		node.position.y *= node.scroll_mult.y
		node.position.y += node.note_field.global_position.y
		
		if data.time <= Conductor.playhead and (not node.note_field or node.note_field.cpu):
			on_note_deleted.emit(NoteDeletionType.HIT, node)
			if data.side == 1: node.display_splash()
			node.hide()
		
		if rel_time > 0.75:
			on_note_deleted.emit(NoteDeletionType.DIE, node)
			node.hide()


func try_spawning() -> void:
	while list_position < note_list.size():
		var note_data: NoteData = note_list[list_position]
		if absf(note_data.time - Conductor.time) > 0.8: break

		var new_note: Note = get_note()
		new_note.data = note_data
		new_note.was_missed = false
		new_note.was_hit = false
		new_note.reload(note_data)
		on_note_spawned.emit(note_data, new_note)
		new_note.show()
		list_position += 1#= clampi(list_position + 1, 0, note_list.size())
		#print_debug("spawned at ", Conductor.time)
		#print(list_position)


func get_note() -> Node:
	for node: Node in get_children():
		if not node.visible:
			return node
	var duped: = TEMPLATE_NOTE.instantiate()
	duped.name = "note%s" % list_position
	duped.hide()
	add_child(duped)
	return duped
