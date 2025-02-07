extends Node2D
@onready var grid: ColorRect = $"grid_layer/color_rect"
@onready var time_text: Label = $"grid_layer/time_text"


func _process(delta: float) -> void:
	move_grid(delta)
	update_text()

func move_grid(_delta: float) -> void:
	var current_offset: float = grid.material.get_shader_parameter("offset")
	grid.material.set_shader_parameter("offset", current_offset + 0.002)

func update_text() -> void:
	time_text.text = "%s / %s\n%s BPM" % [
		Global.format_to_time(Conductor.time),
		Global.format_to_time(1000),
		Conductor.bpm
	]
