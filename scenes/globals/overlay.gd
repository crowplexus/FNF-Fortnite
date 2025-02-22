extends CanvasLayer

@onready var fps_label: Label = $"%fps_label"
@onready var update_timer: Timer = $"%update_timer"


func _ready() -> void:
	update_timer.timeout.connect(func() -> void:
		update_overlay()
		update_timer.start(1.0)
	)
	update_timer.start(1.0)
	update_overlay()

func _unhandled_key_input(event: InputEvent) -> void:
	if event.pressed:
		match event.keycode:
			61, 4194437: update_master_volume(5)
			45, 4194435: update_master_volume(-5)

func update_overlay() -> void:
	fps_label.text = "%s FPS\n%s RAM" % [
		Engine.get_frames_per_second(),
		String.humanize_size(OS.get_static_memory_usage()),
	]

func update_master_volume(bhm: int = 0) -> void:
	Global.settings.master_volume += bhm
