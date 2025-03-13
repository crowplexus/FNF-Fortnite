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
@onready var player: Actor2D = $"bf"

var assets: ChartAssets
var game_mode: PlayMode = PlayMode.FREEPLAY
var judgements: JudgementList = preload("res://assets/default/judgements.tres")
var note_fields: Array[NoteField] = []
var timed_events: Array[TimedEvent] = []
var event_position: int = 0
var should_process_events: bool = true

var max_hit_window: float = Tally.get_max_hit_window_secs()
var is_ending: bool = false
var starting: bool = true

# temporarily here until I figure something out!
var health: int = 50 # 50%

func _ready() -> void:
	if not tally: tally = Tally.new()
	print_debug("max hit window is ", max_hit_window, " (", max_hit_window * 1000.0, "ms)")
	if chart and chart.assets:
		assets = chart.assets
		load_streams()
		reload_hud()
	init_note_spawner()
	
	# setup note fields.
	var from_where: Control
	if hud.has_node("note_fields"): from_where = hud.get_node("note_fields")
	elif hud_layer.has_node("note_fields"): from_where = hud.get_node("note_fields")
	for node: Node in from_where.get_children():
		if node is NoteField: note_fields.append(node)
	
	player_strums = note_fields[1]
	if chart:
		for note_field: NoteField in note_fields:
			note_field.speed = chart.get_speed()
		print_debug("scroll speed changed to ", chart.get_speed(), " at ", Conductor.time)
		Conductor.reset(chart.get_bpm(), false)
	Conductor.on_beat_hit.connect(on_beat_hit)
	
	var skip_countdown: bool = false
	var crotchet_offset: float = -3.0
	if hud:
		hud.init_vars()
		skip_countdown = hud.skip_countdown
		if not skip_countdown:
			crotchet_offset = -5.0
			hud.start_countdown()
		hud.update_score_text()
	Conductor.set_time(Conductor.crotchet * crotchet_offset)
	Global.update_discord("Solo (1 of 1)", "In-game")

func _exit_tree() -> void:
	Conductor.length = -1.0
	Conductor.on_beat_hit.disconnect(on_beat_hit)

func _process(delta: float) -> void:
	if get_tree().paused: return
	if starting:
		if Conductor.time >= 0.0:
			Global.update_discord_timestamps(0.0, Conductor.length)
			if music: music.play(0.0)
			starting = false
	if music and music.playing:
		Conductor.update(music.get_playback_position() + AudioServer.get_time_since_last_mix())
	else: # if all else fails update the conductor anyway
		Conductor.update(Conductor.time + delta)
	if not starting:
		if not is_ending and Conductor.time >= Conductor.length:
			is_ending = true
			await get_tree().create_timer(0.5).timeout
			exit_game()
		if should_process_events:
			process_timed_events()
	# hud bumping #
	if hud_layer.is_inside_tree() and hud_layer.scale != Vector2.ONE:
		hud_layer.scale = hud.get_bump_lerp_vector(hud_layer.scale, Vector2.ONE, delta)
		hud_layer.offset.x = (hud_layer.scale.x - 1.0) * -(get_viewport_rect().size.x * 0.5)
		hud_layer.offset.y = (hud_layer.scale.y - 1.0) * -(get_viewport_rect().size.y * 0.5)

func _unhandled_key_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		exit_game()
		return
	var action: String = player_strums.player.get_action_name(event)
	if not action.dedent().is_empty():
		player.pause_sing = player_strums.player.keys_held.has(true)

func process_timed_events() -> void:
	if timed_events.is_empty() or event_position >= timed_events.size():
		should_process_events = false
		return
	var current_event: TimedEvent = timed_events[event_position]
	if not current_event.was_fired:
		#var idx: int = timed_events.find(current_event) # if i need it...
		if Conductor.time < current_event.time:
			return
		if current_event.efire:
			current_event.efire.call()
		else: # hardcoded events yayy !!!! ! ! ! !
			match current_event.name:
				&"Scroll Speed Change":
					for note_field: NoteField in note_fields:
						note_field.speed_change_tween = create_tween()
						note_field.speed_change_tween.tween_property(note_field, "speed", current_event.values.speed, 1.0)
					print_debug("scroll speed changed to ", current_event.values.speed, " at ", Conductor.time)
			current_event.was_fired = true
	event_position += 1


func reload_hud() -> void:
	if chart.assets and chart.assets.hud:
		hud.set_process(false) # just in case
		hud.queue_free()
		hud = chart.assets.hud.instantiate()
		hud_layer.add_child(hud)
		hud_layer.move_child(hud, 0)


func load_streams() -> void:
	if chart.assets and chart.assets.instrumental:
		music.stream.set_sync_stream(0, chart.assets.instrumental)
		Conductor.length = chart.assets.instrumental.get_length()
		if chart.assets.vocals:
			for i: int in chart.assets.vocals.size():
				music.stream.set_sync_stream(i + 1, chart.assets.vocals[i])


func init_note_spawner() -> void:
	note_group.on_note_spawned.connect(func(data: NoteData, note: Node2D) -> void:
		var receptor: = note_fields[data.side].get_child(data.column)
		note.global_position = receptor.global_position
		note.scale = note_fields[data.side].scale
		note.note_field = note_fields[data.side]
	)
	if chart and not chart.notes.is_empty():
		note_group.note_list = chart.notes.duplicate(true)
		if Conductor.length < 0.0: Conductor.length = chart.notes.back().time


func on_note_hit(note: Note) -> void:
	if note.was_hit or note.column == -1:
		return
	note.was_hit = true
	health = clampi(health + 5, 0, 100)
	var abs_diff: float = absf(note.time - Conductor.playhead)
	var judged_tier: int = Tally.judge_time(abs_diff * 1000.0)
	var judgement: Judgement = judgements.list[judged_tier]
	if note.forced_splash or judgement.splash_type != Judgement.SplashType.DISABLED:
		note.display_splash()
	player.sing(note.column, note.arrow.visible)
	# Scoring Stuff
	tally.increase_score(abs_diff * 1000.0)
	if judgement.combo_break:
		tally.break_combo()
	tally.increase_combo(1)
	tally.update_accuracy(abs_diff * 1000.0)
	tally.update_tier_score(judged_tier)
	# Update HUD
	hud.display_judgement(judgement.texture)
	hud.display_combo(tally.combo)
	hud.update_score_text()
	hud.update_health(health)
	attempt_to_die()

func attempt_to_die() -> void:
	if health <= 0: # игра окоичена!
		# TODO: the base game thing where it doesn't directly reset the scene
		# but instead tweens the notes back up, restarts all counters and plays the song from the beginning
		hud_layer.hide()
		music.stop()
		player.die()


func on_note_miss(note: Note, idx: int = -1) -> void:
	if note and note.was_missed or idx == -1: return
	tally.break_combo() # break combo (if possible)
	tally.increase_misses(1) # increase by one
	player.sing(idx, true, "miss")
	health = clampi(health - 5, 0, 100)
	hud.update_score_text()
	hud.update_health(health)
	attempt_to_die()


func on_beat_hit(beat: float) -> void:
	if fmod(beat, 4.0) == 0:
		hud_layer.scale += Vector2(hud.get_bump_scale(), hud.get_bump_scale())


func exit_game() -> void:
	tally = null
	Global.change_scene("res://scenes/menu/freeplay_menu.tscn")
