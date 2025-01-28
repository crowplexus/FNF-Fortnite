extends Control

const ACCELERATION: String = "acceleration"
const VELOCITY: String = "velocity"

@export var judge_scale: Vector2 = Vector2(0.65, 0.65)
@export var combo_scale: Vector2 = Vector2(0.45, 0.45)

var display_digits: Array[Node2D] = []
var display_tweens: Array[Tween] = []
var judgement_tween: Tween


func _ready() -> void:
	if not has_node("judgement"):
		add_child(Sprite2D.new()) # Judgement
		get_child(0).name = "judgement"
	if not has_node("combo_digit0"):
		for i: Node2D in display_digits:
			i.name = "combo_digit%s" % display_digits.find(i)
			add_child(i)
	
	for node: Node in get_children():
		if node.name.begins_with("combo_digit"):
			display_digits.append(node)
			display_tweens.append(null)


func display_judgement(texture: Texture2D) -> void:
	var judgement: Sprite2D = get_child(0)
	judgement.self_modulate.a = 1.0
	judgement.scale = judge_scale * 1.05
	judgement.texture = texture
	judgement.position.y = -50
	judgement.visible = true
	if judgement_tween: judgement_tween.stop()
	judgement_tween = create_tween().set_parallel(true)
	judgement_tween.tween_property(judgement, "scale", judge_scale, 0.1)
	judgement_tween.tween_property(judgement, "self_modulate:a", 0.0, 0.4).set_delay(Conductor.crotchet * 0.05)
	judgement_tween.finished.connect(judgement.hide)


func display_combo(amnt: int = 0) -> void:
	var combo: Array = str(amnt).pad_zeros(2).split("")
	var offset: float = combo.size() - 3
	for i: int in combo.size():
		if (i + 1) > display_digits.size():
			display_tweens.insert(i, null)
			display_digits.insert(i, Sprite2D.new())
			display_digits[i].name = "combo_digit%s" % i
			add_child(display_digits[i])
		var num_score: Sprite2D = display_digits[i]
		num_score.texture = load("res://assets/game/hud/combo/funkin/num%s.png" % combo[i])
		num_score.position = Vector2(
			(size.x * 0.5) - (90 * combo_scale.x) * (offset - i),
			(size.y * 0.25) + 25
		)
		num_score.scale = combo_scale * 1.1
		num_score.self_modulate.a = 1.0
		num_score.visible = true
		if display_tweens[i]: display_tweens[i].stop()
		display_tweens[i] = create_tween().set_parallel(true)
		display_tweens[i].tween_property(num_score, "scale", combo_scale, 0.2)
		display_tweens[i].tween_property(num_score, "self_modulate:a", 0.0, 0.45).set_delay(Conductor.crotchet * 0.1)
		display_tweens[i].finished.connect(num_score.hide)


func compute_velocity(vel: float, accel: float, delta: float) -> float:
	var dt: float = 0.0 if accel <= 0.0 else delta
	return vel + accel * dt


func is_moving(node: Node) -> bool:
	return node.get_meta(VELOCITY, Vector2.ZERO) != Vector2.ZERO or \
		node.get_meta(ACCELERATION, Vector2.ZERO) != Vector2.ZERO
