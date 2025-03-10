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
## Counts how many of (tier judgement) you've hit.
var tiers_scored: Array[int] = [0, 0, 0, 0, 0]

## Increases the score by the amount provided (in ms).
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
	#if combo > 0:
		# TODO: add this.
		#breaks += 1
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

## Updates the counter for the tiers you have.
func update_tier_score(tier: int) -> void:
	if tier > tiers_scored.size():
		tiers_scored.append(0)
	tiers_scored[tier] += 1

## Calculates the ratio of all tiers (except the highest) up to all the other judgements.[br]
## Returns 0.0 if Global.settings.use_epics is disabled.
func calculate_epic_attack() -> float:
	if not Global.settings.use_epics:
		# there's no reason for this to be calculate cus there's only 4 (or less) judgements
		return 0.0
	# Sick, Good, Bad, Shit.
	return self.tiers_scored[1] + self.tiers_scored[2] + self.tiers_scored[3] + self.tiers_scored[4]

## Calculates the ratio of Tier 1s (Sicks) up to all the other judgements.[br]
## Returns 0.0 if Global.settings.use_epics is disabled.
func calculate_sick_attack() -> float:
	if not Global.settings.use_epics:
		# there's no reason for this to be calculate cus there's only 4 (or less) judgements
		return 0.0
	# Good, Bad, Shit.
	return self.tiers_scored[2] + self.tiers_scored[3] + self.tiers_scored[4]

## Grabs the max hit window in seconds.
static func get_max_hit_window_secs() -> float:
	return TIMINGS.back() * 0.001

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

## Returns a string with an grade, depends on what judgements have been hit in the tier list given.[br]
## Hitting only tier 1s results in "Perf"[br]
## Hitting at least 1 tier 2 results in "Great"[br]
## Hitting at least 1 tier 3 results in "Pass" 
func get_tier_grade() -> String:
	var fc_tier: String = ""
	#if notes_hit_count == 0:
	#	fc_tier = "Noplay"
	#	return fc_tier
	var scores: = self.tiers_scored
	if scores.size() >= 3: # 3 tiers or more
		if scores[3] == 0 and (misses + breaks) == 0:
			if scores[0] > 0: fc_tier = "PFC" #"Perf" # Epic
			if scores[1] > 0: fc_tier = "GFC" #"Great" # Sick
			if scores[2] > 0: fc_tier = "FC" #"Piss" if randf_range(0, 100) < 0.5 else "Pass" # Good, 1/500 chance of saying Piss instead
	return fc_tier
