## Horloge de jeu en demi-journées (matin / soir). Sim pure : avancée par advance(delta).
extends RefCounted

signal ticked(half_day: int)

const HALF_DAY_SECONDS := 30.0 ## [P] durée réelle d'une demi-journée à vitesse x1
const SPEEDS: Array[int] = [1, 2, 4]

var half_day := 0 ## demi-journées écoulées depuis le début de la partie
var paused := false
var speed := 1:
	set(v):
		assert(v in SPEEDS, "vitesse invalide")
		speed = v
var _acc := 0.0 ## secondes accumulées vers la prochaine demi-journée


## Avance de delta secondes réelles ; émet ticked pour chaque demi-journée franchie.
func advance(delta: float) -> int:
	if paused or delta <= 0.0:
		return 0
	_acc += delta * speed
	var n := int(_acc / HALF_DAY_SECONDS)
	_acc -= n * HALF_DAY_SECONDS
	for i in n:
		half_day += 1
		ticked.emit(half_day)
	return n


## Passe à la vitesse suivante (x1 -> x2 -> x4 -> x1).
func cycle_speed() -> void:
	speed = SPEEDS[(SPEEDS.find(speed) + 1) % SPEEDS.size()]


func day() -> int: ## jour courant, à partir de 1
	return half_day / 2 + 1


func is_evening() -> bool:
	return half_day % 2 == 1


func to_dict() -> Dictionary:
	return {"half_day": half_day, "speed": speed, "paused": paused, "acc": _acc}


func from_dict(d: Dictionary) -> void:
	half_day = int(d.get("half_day", 0))
	var s := int(d.get("speed", 1))
	speed = s if s in SPEEDS else 1
	paused = bool(d.get("paused", false))
	_acc = clampf(float(d.get("acc", 0.0)), 0.0, HALF_DAY_SECONDS)
