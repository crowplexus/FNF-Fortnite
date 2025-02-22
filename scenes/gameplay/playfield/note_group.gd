extends Node

const TEMPLATE_NOTE: PackedScene = preload("res://scenes/gameplay/playfield/notes/normal_note.tscn")

signal on_note_spawned(data: NoteData, note: Note)
signal on_note_deleted(type: Note.DeletionEventID, note: Note)

@export var active: bool = true
var colours: Array[StringName] = [ &"purple", &"blue", &"green", &"red", ]
var note_list: Array[NoteData] = []
var max_hit_window: float = 180.0
var list_position: int = 0

func _ready() -> void:
	list_position = 0
	#for i: int in 64: # precache this many notes
	#	var preload_note: = TEMPLATE_NOTE.instantiate()
	#	preload_note.name = "preload%s" % str(i)
	#	preload_note.top_level = true
	#	preload_note.hide_all()
	#	add_child(preload_note)


func _process(_delta: float) -> void:
	if not active:
		return
	
	try_spawning()
	move_present_nodes()


func spawning_complete() -> bool:
	return note_list.size() == 0 or list_position >= note_list.size()


func move_present_nodes() -> void:
	for i: int in get_child_count():
		var node: Note = get_child(i)
		if not node.visible :
			continue
		# TODO: move to note class?
		var data: NoteData = NoteData.EMPTY if not node.data else node.data		
		if node.moving:
			node.position.y = Note.DISTANCE * (Conductor.playhead - data.time) * data.speed / absf(node.scale.y)
			node.position.y *= node.scroll_mult.y
			node.position.y += node.note_field.global_position.y
		# must be done no matter what to prevent orphan notes
		if (Conductor.playhead - data.time) > 0.75:
			if not node.was_hit: node.was_missed = true
			on_note_deleted.emit(Note.DeletionEventID.DIE, node)
			node.hide_all()


func try_spawning() -> void:
	while list_position < note_list.size():
		var note_data: NoteData = note_list[list_position]
		if absf(note_data.time - Conductor.time) > 0.8: break

		var new_note: Note = get_note()
		new_note.data = note_data
		new_note.reload(note_data)
		on_note_spawned.emit(note_data, new_note)
		new_note.show_all()
		list_position += 1#= clampi(list_position + 1, 0, note_list.size())
		#print_debug("spawned at ", Conductor.time)
		#print(list_position)


func get_note() -> Node:
	#for node: Node in get_children():
	#	if not node.visible:
	#		return node
	var duped: = TEMPLATE_NOTE.instantiate()
	duped.name = "note%s" % list_position
	#duped.hide_all()
	add_child(duped)
	return duped
