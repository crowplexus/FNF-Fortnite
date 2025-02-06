class_name Gameplay
extends Node2D

enum PlayMode {
	STORY = (1 << 1),
	FREEPLAY = (2 << 1),
	CHARTING = (3 << 1),
}

var player_strums: NoteField
# I need this to be static because of story mode,
# since it reuses the same tally from the previous song.
static var tally: Tally
static var chart: BaseChart

@onready var hitsound: AudioStreamPlayer = $"scream"
@onready var music: AudioStreamPlayer = $%"music_player"
@onready var note_group: Node = $"hud_layer/note_group"
@onready var hud_layer: CanvasLayer = $"hud_layer"
@onready var hud: TemplateHUD = $"hud_layer/hud"

var assets: ChartAssets
var game_mode: PlayMode = PlayMode.FREEPLAY
var judgements: JudgementList = preload("res://assets/default/judgements.tres")
var note_fields: Array[NoteField] = []

var max_hit_window: float = Tally.TIMINGS.back()
var starting: bool = true

func _ready() -> void:
	if not tally: tally = Tally.new()
	print_debug("max hit window is ", max_hit_window)
	init_note_spawner()
	if chart.assets:
		assets = chart.assets
		load_streams()
		reload_hud()
	
	# setup note fields.
	var from_where: Control
	if hud.has_node("note_fields"): from_where = hud.get_node("note_fields")
	elif hud_layer.has_node("note_fields"): from_where = hud.get_node("note_fields")
	for node: Node in from_where.get_children():
		if node is NoteField: note_fields.append(node)
	
	player_strums = note_fields[1]
	Conductor.reset(chart.get_bpm(), false)
	Conductor.on_beat_hit.connect(on_beat_hit)
	
	var skip_countdown: bool = false
	if hud:
		hud.init_vars()
		skip_countdown = hud.skip_countdown
		hud.update_score_text()
		if not skip_countdown:
			Conductor.set_time((Conductor.crotchet * -5.0))
			hud.start_countdown()
	if skip_countdown:
		Conductor.set_time((Conductor.crotchet * -3.0))
	
	Global.update_discord("Playing a Song", "in Freeplay")

func _exit_tree() -> void:
	Conductor.on_beat_hit.disconnect(on_beat_hit)

func _process(delta: float) -> void:
	if get_tree().paused: return
	if starting:
		Conductor.update(Conductor.time + delta)
		if Conductor.time >= 0.0:
			if music: music.play(0.0)
			starting = false
	elif music and music.playing:
		Conductor.update(music.get_playback_position() + AudioServer.get_time_since_last_mix())
	# prevent that fuckass bug where the notes inside the group will still move
	if note_group.spawning_complete():
		note_group.active = false
	# hud bumping #
	if hud_layer.scale != Vector2.ONE:
		hud_layer.scale = hud.get_bump_lerp_vector(hud_layer.scale, Vector2.ONE, delta)
		hud_layer.offset.x = (hud_layer.scale.x - 1.0) * -(get_viewport_rect().size.x * 0.5)
		hud_layer.offset.y = (hud_layer.scale.y - 1.0) * -(get_viewport_rect().size.y * 0.5)

func _unhandled_key_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		tally = null
		get_tree().change_scene_to_file("res://scenes/menu/freeplay_menu.tscn")
		return
	var action: String = player_strums.get_action_name(event)
	if not player_strums.has_control or action.dedent().is_empty():
		return
	var idx: int = player_strums.controls.find(action)
	fucker_temp.pause_sing = Input.is_action_pressed(action)
	if Input.is_action_just_released(action):
		player_strums.play_animation(idx, NoteField.RepState.STATIC)
		return
	if Input.is_action_just_pressed(action):
		var inputs: Array = note_group.get_children().filter(func(n) -> bool:
			return n.data and n.data.column == idx and n.is_hittable(max_hit_window * 0.001) \
				and n.data.side == note_fields.find(player_strums))
		if inputs.is_empty():
			player_strums.play_animation(idx, NoteField.RepState.PRESSED)
		else:
			inputs.sort_custom(func(n1: Note, n2: Note) -> bool:
				return n1.data.time < n2.data.time)
			var hit_note: Note = inputs[0]
			if not hit_note:
				player_strums.play_animation(idx, NoteField.RepState.PRESSED)
			else:
				if hit_note and not hit_note.was_hit:
					player_strums.play_animation(idx, NoteField.RepState.CONFIRM)
					on_note_hit(hit_note)


func reload_hud() -> void:
	if chart.assets.hud:
		hud.set_process(false) # just in case
		hud.queue_free()
		hud = chart.assets.hud.instantiate()
		hud_layer.add_child(hud)
		hud_layer.move_child(hud, 0)


func load_streams() -> void:
	if chart.assets.instrumental:
		music.stream.set_sync_stream(0, chart.assets.instrumental)
		if chart.assets.vocals:
			for i: int in chart.assets.vocals.size():
				music.stream.set_sync_stream(i + 1, chart.assets.vocals[i])


func init_note_spawner() -> void:
	note_group.max_hit_window = max_hit_window
	note_group.connect("on_note_spawned", func(data: NoteData, note: Node2D) -> void:
		var receptor: = note_fields[data.side].get_child(data.column)
		note.global_position = receptor.global_position
		note.scale = note_fields[data.side].scale
		note.note_field = note_fields[data.side]
	)
	note_group.connect("on_note_deleted", func(type: int, note: Note) -> void:
		if type == 0 and note.note_field == player_strums:
			on_note_miss(note)
		if type == 1:
			note.note_field.play_animation(note.data.column, NoteField.RepState.CONFIRM)
			note.note_field.set_reset_timer(note.data.column, 0.3 * Conductor.crotchet)
	)
	note_group.note_list = chart.notes.duplicate(true)


@onready var fucker_temp: Actor2D = $"bf"

func on_note_hit(note: Note) -> void:
	if note.was_hit: return
	note.was_hit = true
	var abs_diff: float = absf(note.data.time - Conductor.playhead)
	var judgement: Judgement = judgements.list[Tally.judge_time(abs_diff * 1000.0)]
	if note.forced_splash or judgement.splash_type != Judgement.SplashType.DISABLED:
		note.display_splash()
	note.hide()
	fucker_temp.sing(note.data.column, true)
	# Scoring Stuff
	tally.increase_score(abs_diff * 1000.0)
	if judgement.combo_break:
		tally.combo = 0
		tally.breaks += 1
	tally.increase_combo(1)
	tally.update_accuracy(abs_diff * 1000.0)
	# Update HUD
	hud.display_judgement(judgement.texture)
	hud.display_combo(tally.combo)
	hud.update_score_text()


func on_note_miss(note: Note) -> void:
	if note.was_missed: return
	tally.break_combo()
	tally.increase_misses(1)
	hud.update_score_text()


func on_beat_hit(beat: float) -> void:
	if floori(beat) % 4 == 0:
		hud_layer.scale += Vector2(hud.get_bump_scale(), hud.get_bump_scale())
