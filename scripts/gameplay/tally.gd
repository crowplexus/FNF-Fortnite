class_name Tally
extends Resource

## Defines the scoring system used for calculations, and how high scores will be displayed.
enum ScoringSystem {
	## Accuracy gets calculated based on the Judgement.
	Judge = (1 << 1),
	## Accuracy gets calculated based on Note Hit Time.
	HitTime = (2 << 1),
}

## Accuracy Points you get from missing notes.
const MISS_POINTS: float = -5.0
## The weight of which accuracy points get multiplied by.
const POINTS_WEIGHT: float = 20.0
## Maximum score a note can receive.
const MAX_SCORE: int = 500
## Temporary, will be replaced with settings.
const TIMINGS: Array[float] = [ 18.9, 37.8, 75.6, 113.4, 180.0 ]
## Tier for a miss.
static var MISS_TIER: int:
	get: return TIMINGS.size() + 1

## Score accumulated from hitting notes.
@export var score: int = 0
## Misses accumulated from missing notes.
@export var misses: int = 0
## Combo accumulated from hitting notes consecutively, resets to 0 if you miss.
@export var combo: int = 0
## Combo Breaks, obtained whenever the combo counter resets to 0.
@export var breaks: int = 0
## Accuracy accumulated from millisecond calculations made when hitting notes.
@export var accuracy: float = 0.0
## Used when displaying highscores.
var score_system: ScoringSystem = ScoringSystem.Judge
## Used for accuracy calculations.
var notes_hit_count: int = 0
## Used for accuracy calculations.
var accuracy_points: float = 0.0

## Increases the score by the amount provided.
func increase_score(amount: float) -> void:
	score += floori(MAX_SCORE - absf(amount))

## Increases the misses counter by the amount provided (default: 1).
func increase_misses(amount: int = 1) -> void:
	misses += amount

## Increases the combo counter by the amount provided.
func increase_combo(amount: int) -> void:
	combo += amount
	# never decrease this idk
	notes_hit_count += 1

## Increases the combo breaks counter (if possible).
func break_combo() -> void:
	if combo > 0:
		breaks += 1
	combo = 0

## Updates the accuracy currently displayed.
func update_accuracy(time: float) -> void:
	match score_system:
		ScoringSystem.HitTime:
			accuracy_points += calc_max_points(judge_time(time), time)
			accuracy = accuracy_points / (notes_hit_count + misses)
		_:
			accuracy_points += calc_judgement_points(judge_time(time))
			accuracy = accuracy_points / notes_hit_count

## Calculate the accuracy points for a single hit (in milliseconds).
static func calc_max_points(tier: int, time: float) -> float:
	if tier == MISS_TIER: return MISS_POINTS
	var max_points: float = 100.0 - (tier * POINTS_WEIGHT)
	if tier == 1 and not Global.settings.use_epics: tier -= 1
	var points: float = (TIMINGS[tier] / time) * max_points
	return min(points, max_points)

## Accuracy Scores based on judgement obtained (instead of note hit time).
static func calc_judgement_points(tier: int) -> float:
	#if tier == MISS_TIER: return MISS_POINTS
	var points: float = 100.0 - (tier * POINTS_WEIGHT)
	if tier == 1 and not Global.settings.use_epics: tier -= 1
	return points

## Returns a judgement tier based on the time provided.[br]
## Tier 0 (Epic) will never get returned if disabled in settings.
static func judge_time(ms: float) -> int:
	for i: int in TIMINGS.size():
		var can_return: bool = ms <= TIMINGS[i]
		if not Global.settings.use_epics and i == 0:
			can_return = false
		if can_return: return i
	return TIMINGS.find(TIMINGS.back())
