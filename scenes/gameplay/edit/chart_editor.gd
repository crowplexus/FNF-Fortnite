extends Node2D

@onready var grid: ColorRect = $"grid_layer/color_rect"

func _process(delta: float) -> void:
	(grid.material as ShaderMaterial).set_shader_parameter("offset", 
		(grid.material as ShaderMaterial).get_shader_parameter("offset") + 0.002)
