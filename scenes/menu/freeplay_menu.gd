extends Node2D

## Song to play if the audio file for the hovered one couldn't be found.
@export var default_song: AudioStream = preload("res://assets/music/freeplayRandom.ogg")
## List of songs to display on-screen.
@export var songs: SongList = preload("res://assets/default/song_list.tres")

@onready var song_container: BoxContainer = $"song_container/box"
@onready var random_template: Label = $"song_container/box/random"
@onready var bg: Sprite2D = $"background"

var cursor_tween: Tween
var selected: int = 0
var exiting: bool = false

func _ready() -> void:
	Global.play_bgm(default_song)
	Conductor.bpm = default_song.bpm
	#Global.request_audio_fade(Global.bgm, 1.0, 0.3)
	for song: SongItem in songs.list:
		#var i: int = song.list.find(song)
		var item: Label = random_template.duplicate()
		item.text = song.name
		item.name = song.folder
		song_container.add_child(item)
	for song: Label in song_container.get_children():
		song.modulate.a = 0.6
	change_selection()

func _process(_delta: float) -> void:
	if Global.bgm and Global.bgm.playing:
		Conductor.update(Global.bgm.get_playback_position() + AudioServer.get_time_since_last_mix())

func _unhandled_input(_event: InputEvent) -> void:
	if exiting: return
	var axis: int = floori(Input.get_axis("ui_up", "ui_down"))
	if axis != 0: change_selection(axis)
	if Input.is_action_just_pressed("ui_accept"):
		Global.request_audio_fade(Global.bgm, 0.0, 0.5)
		var song_to_pick: = songs.list[selected - 1]
		if selected == 0: song_to_pick = songs.pick_random()
		Gameplay.chart = FNFChart.parse(song_to_pick.folder, "hard")
		await get_tree().create_timer(0.5).timeout
		get_tree().change_scene_to_file("res://scenes/gameplay/gameplay.tscn")

## Changes the index of the selection cursor
func change_selection(next: int = 0) -> void:
	var item: Label = song_container.get_child(selected)
	selected = wrapi(selected + next, 0, song_container.get_child_count())
	if next != 0: Global.play_sfx(Global.resources.get_resource("scroll"))
	if item: item.modulate.a = 0.6
	item = song_container.get_child(selected)
	item.modulate.a = 1.0
