## Gameplay Object that usually contains 4 sprites,
## visually representing a player's playfield.
class_name NoteField
extends Node2D

enum RepState {
	STATIC = 0,
	PRESSED = 1,
	CONFIRM = 2,
}
## If the note field controls itself.
@export var cpu: bool = true
## If the note field can be controlled by pressing keys.
@export var has_control: bool = false
## Actions to use for controlling.
@export var controls: PackedStringArray = [ "note_left", "note_down", "note_up", "note_right" ]


func _ready() -> void:
	pass

@warning_ignore("unused_parameter")
func _process(delta: float) -> void:
	pass


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


func play_animation(idx: int = 0, state: = NoteField.RepState.STATIC, force: bool = true) -> void:
	var receptor: = get_child(idx % get_child_count())
	if receptor.has_method("play_animation"):
		receptor.play_animation(state, force)


func set_reset_timer(idx: int = 0, timer: float = 0.5 * Conductor.crotchet) -> void:
	var receptor: = get_child(idx % get_child_count())
	receptor.reset_timer = timer


func set_reset_animation(idx: int = 0, new_state: = NoteField.RepState.STATIC) -> void:
	var receptor: = get_child(idx % get_child_count())
	receptor.reset_state = new_state
