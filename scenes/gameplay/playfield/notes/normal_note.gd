extends Note

@onready var player: AnimationPlayer = $"animation_player"
@onready var splash: AnimatedSprite2D = $"splash"
@onready var arrow: AnimatedSprite2D = $"arrow"

func show_all() -> void:
	if not arrow.visible: arrow.show()
	var is_hold: bool = clip_rect and hold_size > 0.0
	if clip_rect: clip_rect.visible = is_hold
	super()

func reload(p_data: NoteData) -> void:
	super(p_data)
	hold_size = length
	player.play(str(column))
	if not arrow.visible: arrow.show()
	if arrow.sprite_frames and clip_rect and hold_size > 0.0 and hold_body: # damn
		var color: = Note.COLORS[column % Note.COLORS.size()]
		hold_body.texture = arrow.sprite_frames.get_frame_texture("%s hold piece" % color, 0)
		if hold_tail: hold_tail.texture = arrow.sprite_frames.get_frame_texture("%s hold tail" % color, 0)
		display_hold(hold_size)
		if hold_tail:
			hold_tail.position.y = hold_body.position.y + hold_body.size.y

func update_hold(delta: float) -> void:
	if arrow.visible: arrow.hide()
	super(delta)
	if hold_tail: hold_tail.position.y = hold_body.position.y + hold_body.size.y + 30

func can_splash() -> bool:
	# NOTE: if i add covers, maybe "length <= 0.0" should be removed from here.
	return judgement and judgement.splash_type != Judgement.SplashType.DISABLED and length <= 0.0

func hold_finished() -> void:
	# testing, idk if i will add hold covers and whatever.
	if judgement and judgement.splash_type != Judgement.SplashType.DISABLED:
		display_splash()

func display_splash() -> Node2D:
	if not note_field or column == -1:
		return null
	# TODO: change *all* of this
	var dip: AnimatedSprite2D = null
	var receptor: = note_field.get_child(column)
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
	dip.play("note impact %s %s" %  [ randi_range(1, 2), Note.COLORS[column] ], 1.0)
	return dip
