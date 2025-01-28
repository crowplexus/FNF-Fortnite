class_name Tally
extends Resource

## Defines the scoring system used for calculations, and how high scores will be displayed.
enum ScoringSystem {
	## Accuracy gets calculated internally, never displayed.[br]
	## Uses BBE2Complex for Accuracy.
	Default = 0,
	## Accuracy gets calculated based on the Judgement.
	Judge = 1,
	## Accuracy gets calculated based in milliseconds.
	BBE2Complex = 2,
}

## Maximum score a note can receive.
const MAX_SCORE: int = 500
## Temporary, will be replaced with settings.
const TIMINGS: Array[float] = [ 22.5, 45.0, 90.0, 135.0, 180.0 ]
## Tier for a miss.
static var MISS_TIER: int:
	get: return TIMINGS.size() + 1

## Score accumulated from hitting notes.
@export var score: int = 0
## Misses accumulated from missing notes.
@export var misses: int = 0
## Combo accumulated from hitting notes consecutively, resets to 0 if you miss.
@export var combo: int = 0
## Accuracy accumulated from millisecond calculations made when hitting notes.
@export var accuracy: float = 0.0
## Used when displaying highscores.
var score_system: ScoringSystem = ScoringSystem.Judge
## Used for accuracy calculations.
var notes_hit_count: int = 0
## Used for accuracy calculations.
var accuracy_score_accumulated: float = 0.0

func _to_string() -> String:
	return "Score: %s # Misses: %s # Rank: {rank} - %s%%" % [ score, misses, snappedf(accuracy, 0.001) ]

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
	if (notes_hit_count + amount) > notes_hit_count:
		notes_hit_count += amount

## Updates the accuracy currently displayed.
func update_accuracy(time: float) -> void:
	var tier: int = judge_time(time)
	match score_system:
		ScoringSystem.Judge:
			accuracy_score_accumulated += get_accuracy_score(tier)
			accuracy = accuracy_score_accumulated / (notes_hit_count + misses)
		_: # Default, BBE2Complex, although with some minor changes.
			var perfect_tier: bool = tier == 0
			if tier == 1 and not Global.settings.tier1_judges:
				perfect_tier = true
			if perfect_tier:
				accuracy_score_accumulated += 1.0 # Epic or Sick
			if tier != MISS_TIER: # don't increase on Miss Tier cus this is done below
				accuracy_score_accumulated += TIMINGS[tier] / time # Anything else.
			accuracy = (accuracy_score_accumulated * 100.0) / (notes_hit_count + misses)

## Returns a judgement tier based on the time provided.[br]
## 0: Epic, 1: Sick, 2: Good, 3: Bad, 4: Shit 5: Miss[br]
## Epic will never get returned if disabled in settings.
static func judge_time(ms: float) -> int:
	for i: int in TIMINGS.size():
		var window: float = TIMINGS[i]
		var can_return: bool = ms <= window
		if not Global.settings.tier1_judges and i == 0:
			can_return = false
		if can_return: return i
	return MISS_TIER

## Accuracy Scores based on judgement.
static func get_accuracy_score(tier: int) -> float:
	match tier: # Stolen from Psych Engine lol!
		0,1: return 100.0 # Epic, Sick.
		2: return 67.0 # Good.
		3: return 34.0 # Bad.
		_: return 0.0 # Anything else.
