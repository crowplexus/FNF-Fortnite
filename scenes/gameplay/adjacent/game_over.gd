extends Node2D

const CONTINUE_SECRET: AudioStream = preload("res://assets/music/gameover/secret/continue.mp3")
const GAME_OVER_SECRET: AudioStream = preload("res://assets/music/gameover/secret/game_over.mp3")

const SECRET_MESSAGES: Array[String] = [
	"Pick up your balls\nand try again.",
	"Make your girl proud\nand try again.",
	"Years of rapping yet here you are losing to some brat\ntry again."
]

@export var skeleton: Actor2D

@onready var music: AudioStreamPlayer = $"music"
@onready var secret_texts: CanvasLayer = $"secret_texts"
@onready var da_text: Control = $"secret_texts/yes"
@onready var nyet_text: Control = $"secret_texts/no"
@onready var secret_message: Control = $"secret_texts/message"
@onready var stupid_buttons: Array[Control] = [da_text, nyet_text]

@onready var bg: ColorRect = $"bg"
@onready var gore: Sprite2D = $"secret_texts/gore_of_my_comfort_character"

var selected: int = -1
var can_change: bool = false
var texts_displayed: bool = false
var camera_moved: bool = true
var text_tweens: Array[Tween] = []
var oops: bool = false
var camera: Camera2D

func _start_game_over() -> void:
	camera = get_viewport().get_camera_2d()
	if camera:
		camera_moved = false
		camera.process_mode = Node.PROCESS_MODE_ALWAYS # just in case lol
		camera.position_smoothing_enabled = true # guarantee that it's enabled
		camera.position_smoothing_speed = 1.0 # slow it down if possible...
	
	oops = randf_range(0, 100) < .5 # .5% chance
	setup_secret()
	bg.modulate.a = 0.0
	bg.visible = true
	create_tween().set_ease(Tween.EASE_IN).tween_property(bg, "modulate:a", 0.7, 1.0).set_delay(0.5)
	Global.play_sfx(skeleton.death_sound)
	if skeleton and skeleton.anim:
		skeleton.anim.animation_finished.connect(_progress_animations)
		skeleton.play_animation("deathStart", true)

func setup_secret() -> void:
	if oops: text_tweens.resize(stupid_buttons.size() + 1)
	for text: Control in stupid_buttons: text.modulate.a = 0.0
	secret_message.modulate.a = 0.0
	# translate it all.
	da_text.text = tr("choice_da", &"russian-bootleg-easteregg")
	nyet_text.text = tr("choice_nyet", &"russian-bootleg-easteregg")
	var msg_id: int = SECRET_MESSAGES.find(SECRET_MESSAGES.pick_random()) + 1
	var message: String = tr("secret_msg_%s" % msg_id, &"russian-bootleg-eastergg")
	if message.is_empty() or message == "secret_msg_%s" % msg_id:
		message = tr("secret_msg_fallback", &"russian-bootleg-eastergg")
	print_debug(message)
	secret_message.text = message

func _process(delta: float) -> void:
	if skeleton:
		if oops and not texts_displayed and skeleton.anim.current_animation == "deathStart" and skeleton.anim.current_animation_position >= 2.0:
			for i: int in stupid_buttons.size() + 1:
				var obj: Label = secret_message if i >= stupid_buttons.size() else stupid_buttons[i]
				text_tweens[i] = create_tween().set_ease(Tween.EASE_IN)
				text_tweens[i].tween_property(obj, "modulate:a", 1.0, 0.5)
				if obj == secret_message:
					text_tweens[i].finished.connect(update_selection)
			texts_displayed = true
		if camera and not camera_moved and skeleton.anim.current_animation == "deathStart" and skeleton.anim.current_animation_position >= 0.5:
			camera.global_position = skeleton.global_position
			camera_moved = true

func _unhandled_input(_event: InputEvent) -> void:
	if not can_change: return
	var axis: int = Input.get_axis("ui_left", "ui_right")
	if axis != 0 and oops:
		selected = wrapi(selected + axis, 0, stupid_buttons.size())
		update_selection()
	if Input.is_action_just_pressed("ui_accept"):
		match selected:
			0: _selected_da()
			1: _selected_nyet()
	# you can only really press cancel for this if you didn't get the secret.
	if not oops and Input.is_action_just_released("ui_cancel"):
		_selected_nyet()

func update_selection() -> void:
	for i: int in stupid_buttons.size():
		stupid_buttons[i].modulate.a = 1.0 if i == selected else 0.6

func _progress_animations(animation: StringName) -> void:
	match animation:
		&"deathStart":
			music.stream = CONTINUE_SECRET if oops else skeleton.death_music
			skeleton.play_animation("deathLoop")
			music.stream.loop = true
			music.play(0.0)
			selected = 0
			can_change = true
			if oops: update_selection()
		&"deathConfirm":
			if oops:
				for i: int in stupid_buttons.size() + 1:
					var obj: Label = secret_message if i >= stupid_buttons.size() else stupid_buttons[i]
					text_tweens[i] = create_tween().set_ease(Tween.EASE_IN)
					text_tweens[i].tween_property(obj, "modulate:a", 0.0, 0.3) \
					.set_delay(0.1)

func _selected_nyet() -> void:
	can_change = false
	music.stop()
	if not oops:
		get_tree().paused = false
		Global.change_scene("res://scenes/menu/freeplay_menu.tscn")
		return
	bg.modulate.a = 1.0
	if not bg.visible: bg.show()
	skeleton.hide()
	secret_message.hide()
	nyet_text.hide()
	da_text.hide()
	music.stream = GAME_OVER_SECRET
	await get_tree().create_timer(0.5).timeout
	secret_message.position.y = da_text.position.y
	secret_message.text = tr("game_over", &"russian-bootleg-easteregg") #"игра окоичена!"
	gore.show()
	secret_message.show()
	music.play(0.0)
	await get_tree().create_timer(4.0).timeout
	gore.hide()
	secret_message.hide()
	await get_tree().create_timer(0.5).timeout
	Global.change_scene("res://scenes/menu/freeplay_menu.tscn", true)

func _selected_da() -> void:
	music.stop()
	can_change = false
	Global.play_sfx(skeleton.death_confirm_sound)
	bg.modulate.a = 0.0
	# MANUALLY DOING THIS WOO
	skeleton.z_index = 1
	bg.z_index = 2
	var tween: Tween = create_tween().set_ease(Tween.EASE_IN).set_parallel(is_instance_valid(camera))
	tween.tween_property(bg, "modulate:a", 1.0, 1.0)
	if camera: tween.tween_property(camera, "zoom", Vector2(1.05, 1.05), 0.6)
	skeleton.play_animation("deathConfirm")
	bg.visible = true
	await get_tree().create_timer(3.0).timeout
	get_tree().paused = false
	Global.change_scene(load("res://scenes/gameplay/gameplay.tscn"))
