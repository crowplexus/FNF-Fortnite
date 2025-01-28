## Chart Format for Friday Night Funkin' (0.2.7.1),
## also includes support for any of its children formats (i.e: Psych Engine)
class_name FNFChart
extends BaseChart

## Parses a chart from a JSON file using the original FNF chart format or similar
static func parse(song_name: StringName, difficulty: StringName = Global.DEFAULT_DIFFICULTY) -> BaseChart:
	var path: String = "res://assets/game/songs/%s/charts/%s.json" % [ song_name, difficulty ]
	var song: String = song_name
	if not ResourceLoader.exists(path):
		path = BaseChart.fix_path(path) + ".json"
		song = BaseChart.fix_path(song)
		# and then if the lowercase path isn't found, just live with that.
		if not ResourceLoader.exists(path):
			# last resort, use default difficulty
			path = path.replace(path.get_file().get_basename(), Global.DEFAULT_DIFFICULTY.to_lower())
		if not ResourceLoader.exists(path):
			print_debug("Failed to parse chart \"%s\" [Difficulty: %s]" % [ song, difficulty ])
			return BaseChart.new()
	var chart: FNFChart = FNFChart.parse_from_string(load(path).data)
	chart.assets = BaseChart.get_assets_resource("res://assets/game/songs/%s/assets.tres" % song)
	chart.parsed_values["folder"] = song_name
	chart.parsed_values["file"] = difficulty
	return chart

## Parses a json string as a chart.
static func parse_from_string(json: Dictionary) -> FNFChart:
	var chart: FNFChart = FNFChart.new()
	var legacy_mode: bool = json.song is Dictionary
	var chart_dict: Dictionary = json.song if legacy_mode else json
	
	if "speed" in chart_dict: chart.velocity_changes[0].values.speed = chart_dict.speed
	if "bpm" in chart_dict: chart.bpm_changes[0].values.bpm = chart_dict.bpm

	var fake_bpm: float = chart.get_bpm()
	var fake_crotchet: float = (60.0 / fake_bpm)
	var current_speed: float = chart.get_speed()
	var fake_timer: float = 0.0
	var max_columns: int = 4
	
	for measure: Dictionary in chart_dict["notes"]:
		if not "sectionNotes" in measure: measure["sectionNotes"] = []
		if not "mustHitSection" in measure: measure["mustHitSection"] = false
		if not "changeBPM" in measure: measure["changeBPM"] = false
		if not "bpm" in measure: measure["bpm"] = fake_bpm
		var must_hit_section: bool = measure["mustHitSection"]
		
		for song_note: Array in measure["sectionNotes"]:
			var column: int = int(song_note[1])
			if (column % max_columns) <= -1:
				# psych events, do something here later
				continue
			var swag_note: NoteData = NoteData.from_array(song_note)
			if legacy_mode:
				swag_note.side = int(must_hit_section)
				if column % (max_columns * 2) >= max_columns:
					swag_note.side = int(not must_hit_section)
			swag_note.speed = current_speed
			chart.notes.append(swag_note)
		
		if measure["changeBPM"] == true and fake_bpm != measure.bpm:
			fake_bpm = measure.bpm
			fake_crotchet = (60.0 / measure.bpm)
			chart.bpm_changes.append(TimedEvent.bpm_change(fake_timer, measure.bpm))
		
		fake_timer += fake_crotchet / 4.0
	
	var ghosts: int = 0
	var ii: int = 0
	for i: int in chart.notes.size():
		if i == 0: continue
		var cur: NoteData = chart.notes[i]
		var prev: NoteData = chart.notes[i - 1]
		if cur.time == prev.time and cur.column == prev.column:
			chart.notes.remove_at(i)
			ghosts += 1
		ii += 1
	print_debug("deleted ", ghosts, " ghost notes from ", ii, " total notes")
	
	chart.notes.sort_custom(func(one: NoteData, two: NoteData): return one.time < two.time)
	chart.bpm_changes.sort_custom(func(one: TimedEvent, two: TimedEvent): return one.time < two.time)
	chart.velocity_changes.sort_custom(func(one: TimedEvent, two: TimedEvent): return one.time < two.time)
	
	return chart

## For Psych Engine Event Support.
func load_psych_event() -> void:
	pass

## For Kade Engine BPM Change Events.
func load_kade_bpm_changes() -> void:
	pass

## For Andromeda Engine Velocity Change Events.
func load_andromeda_velocity_changes() -> void:
	# ADAPTED FROM QUAVER!!!
	# https://github.com/Quaver/Quaver
	pass
