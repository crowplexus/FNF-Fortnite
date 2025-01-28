extends TemplateHUD

@onready var score_text: Label = $"health_bar/score_text"
@onready var combo_group: Control = $"combo_group"

@onready var countdown: Control = $"countdown"
@onready var countdown_sprite: Sprite2D = $"countdown/sprite"
@onready var countdown_sound: AudioStreamPlayer = $"countdown/sound"
@onready var countdown_timer: Timer = $"countdown/timer"
var countdown_tween: Tween

var countdown_sprites: Array[Texture2D] = []
var countdown_sounds: Array[AudioStream] = []
var _countdown_iteration: int = 0

var game: Node2D

func _ready() -> void:
	game = get_tree().current_scene
	countdown.hide()

func init_vars() -> void:
	countdown_sprites = (game.assets as ChartAssets).countdown_textures
	countdown_sounds = (game.assets as ChartAssets).countdown_sounds
	if not countdown_sprite:
		countdown_sprite = Sprite2D.new()
		countdown_sprite.name = "sprite"
		countdown.add_child(countdown_sprite)
	if not countdown_sound:
		countdown_sound = AudioStreamPlayer.new()
		countdown_sound.name = "sound"
		countdown.add_child(countdown_sound)
	if not countdown_timer:
		countdown_timer = Timer.new()
		countdown_timer.name = "timer"
		countdown_timer.one_shot = true
		countdown.add_child(countdown_timer)

func start_countdown() -> void:
	countdown.show()
	countdown_timer.timeout.connect(countdown_progress)
	countdown_timer.start(Conductor.crotchet)
	on_countdown_tick.emit(_countdown_iteration)

func countdown_progress() -> void:
	if _countdown_iteration >= 4:
		on_countdown_end.emit()
		countdown_timer.stop()
		countdown.hide()
		return
	
	if countdown_sprite and _countdown_iteration < countdown_sprites.size():
		const SCALE: Vector2 = Vector2(0.7, 0.7)
		countdown_sprite.texture = countdown_sprites[_countdown_iteration]
		countdown_sprite.position = Vector2(get_viewport_rect().size.x, get_viewport_rect().size.y) * 0.5
		countdown_sprite.self_modulate.a = 1.0
		countdown_sprite.scale = SCALE * 1.05
		countdown_sprite.show()
		
		if countdown_tween.tween: countdown_tween.tween.stop()
		countdown_tween.tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE).set_parallel(true)
		countdown_tween.tween.tween_property(countdown_sprite, "scale", SCALE, Conductor.crotchet * 0.9)
		countdown_tween.tween.tween_property(countdown_sprite, "self_modulate:a", 0.0, Conductor.crotchet * 0.8)
		countdown_tween.tween.finished.connect(countdown_sprite.hide)
	
	if countdown_sound.stream and _countdown_iteration < countdown_sounds.size():
		countdown_sound.stream = countdown_sounds[_countdown_iteration]
		countdown_sound.play()
	countdown_timer.start(Conductor.crotchet)
	_countdown_iteration += 1

func update_score_text() -> void:
	score_text.text = str(game.tally).replace("{rank}", get_rank(game.tally.accuracy))

func display_judgement(image: Texture2D) -> void:
	combo_group.display_judgement(image)

func display_combo(combo: int = -1) -> void:
	if combo < 5:
		# TODO: miss combo
		return
	combo_group.display_combo(combo)

func get_rank(accuracy: float) -> String:
	match accuracy:
		_ when accuracy >= 100: return "SS"
		_ when accuracy >= 95: return "SS-"
		_ when accuracy >= 90: return "S"
		_ when accuracy >= 85: return "S-"
		_ when accuracy >= 80: return "A"
		_ when accuracy >= 75: return "A-"
		_ when accuracy >= 70: return "B"
		_ when accuracy >= 65: return "B-"
		_ when accuracy >= 60: return "C"
		_ when accuracy >= 55: return "C-"
		_ when accuracy >= 50: return "D"
		_ when accuracy >= 45: return "D-"
		_ when accuracy >= 35: return "F+"
		_ when accuracy <= 20: return "F"
		_ when accuracy <= -1: return "NASTY"
	return "N/A"
