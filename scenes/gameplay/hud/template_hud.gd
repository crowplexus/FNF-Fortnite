class_name TemplateHUD
extends Control

## Called whenever the countdown ticks.
@warning_ignore("unused_signal")
signal on_countdown_tick(tick: int)
## Called whenever the countdown ends.
@warning_ignore("unused_signal")
signal on_countdown_end()

## Use this if you want to skip the default hud countdown.
@export var skip_countdown: bool = false

## Use this to initialize the HUD's default values (if needed).
func init_vars() -> void:
	pass

## Displays the countdown and does something after it ends.
func start_countdown() -> void:
	pass

## Updates the score text to display new stats.
func update_score_text() -> void:
	pass

@warning_ignore("unused_parameter")
## Displays a judgement sprite on-screen.
func display_judgement(image: Texture2D) -> void:
	pass

@warning_ignore("unused_parameter")
## Displays combo count on-screen.
func display_combo(combo: int = -1) -> void:
	pass
