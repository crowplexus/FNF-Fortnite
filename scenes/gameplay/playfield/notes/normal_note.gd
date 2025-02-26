extends Note

@onready var player: AnimationPlayer = $"animation_player"
@onready var splash: AnimatedSprite2D = $"splash"
@onready var arrow: AnimatedSprite2D = $"arrow"

func show_all() -> void:
	if not arrow.visible: arrow.show()
	var is_hold: bool = clip_rect and hold_size > 0.0
	if clip_rect: clip_rect.visible = is_hold
	super()

func reload(le_data: NoteData) -> void:
	super(le_data)
	hold_size = le_data.length
	player.play(str(le_data.column))
	if not arrow.visible: arrow.show()
	if clip_rect and hold_size > 0.0 and hold_body: # damn
		var color: = Note.COLORS[le_data.column]
		hold_body.texture = arrow.sprite_frames.get_frame_texture("%s hold piece" % color, 0)
		if hold_tail: hold_tail.texture = arrow.sprite_frames.get_frame_texture("%s hold tail" % color, 0)
		display_hold(hold_size)
		if hold_tail:
			hold_tail.position.y = hold_body.position.y + hold_body.size.y

func update_hold(delta: float) -> void:
	super(delta)
	if arrow.visible: arrow.hide()
	if hold_tail: hold_tail.position.y = hold_body.position.y + hold_body.size.y + 26

func display_splash() -> Node2D:
	if not note_field: return null
	# TODO: change *all* of this
	var receptor: = note_field.get_child(data.column)
	var dip: AnimatedSprite2D = null
	for child: Node in receptor.get_children():
		if child.name.begins_with("splash_"):
			if child.visible: continue
			dip = child
			break
	if not dip:
		dip = splash.duplicate()
		dip.name = "splash_%s" % receptor.get_child_count()
		if dip.top_level: dip.global_position = receptor.global_position
		dip.animation_finished.connect(dip.hide)
		receptor.add_child(dip)
	dip.frame = 0
	dip.show()
	dip.play("note impact %s %s" %  [ randi_range(1, 2), Note.COLORS[data.column] ])
	return dip
