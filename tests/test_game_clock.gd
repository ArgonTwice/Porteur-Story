extends "res://tests/test_base.gd"

const GameClock := preload("res://src/sim/game_clock.gd")
const H := GameClock.HALF_DAY_SECONDS


func test_tick() -> void:
	var c := GameClock.new()
	var seen: Array[int] = []
	c.ticked.connect(func(h: int) -> void: seen.append(h))
	check(c.day() == 1 and not c.is_evening(), "départ : jour 1 matin")
	check(c.advance(H - 0.01) == 0, "pas de tick avant 1 demi-journée")
	check(c.advance(0.02) == 1 and c.is_evening(), "1 tick -> soir")
	check(c.advance(H) == 1 and c.day() == 2 and not c.is_evening(), "jour 2 matin")
	check(seen == [1, 2], "signal ticked par demi-journée : %s" % [seen])


func test_several_ticks_in_one_frame() -> void:
	var c := GameClock.new()
	check(c.advance(H * 3.5) == 3 and c.half_day == 3, "3 ticks d'un coup, reste conservé")
	check(c.advance(H * 0.5) == 1, "le reste compte")


func test_pause() -> void:
	var c := GameClock.new()
	c.paused = true
	check(c.advance(H * 10) == 0 and c.half_day == 0, "pause : rien n'avance")
	c.paused = false
	check(c.advance(H) == 1, "reprise")
	check(c.advance(-5.0) == 0, "delta négatif ignoré")


func test_speed() -> void:
	var c := GameClock.new()
	c.speed = 4
	check(c.advance(H) == 4, "x4 : 4 demi-journées")
	c.cycle_speed()
	check(c.speed == 1, "x4 -> x1")
	c.cycle_speed()
	check(c.speed == 2, "x1 -> x2")


func test_dict_roundtrip() -> void:
	var c := GameClock.new()
	c.speed = 2
	c.advance(H * 2.75) # 5 demi-journées, reste 0.5 H
	c.paused = true
	# Passage par JSON : les int reviennent en float.
	var d: Dictionary = JSON.parse_string(JSON.stringify(c.to_dict()))
	var c2 := GameClock.new()
	c2.from_dict(d)
	check(c2.half_day == 5 and typeof(c2.half_day) == TYPE_INT, "half_day restauré en int")
	check(c2.speed == 2 and c2.paused, "vitesse et pause restaurées")
	c2.paused = false
	check(c2.advance(H * 0.25) == 1, "reste de la demi-journée restauré")
	c2.from_dict({"speed": 3})
	check(c2.speed == 1 and c2.half_day == 0, "valeurs invalides ou absentes -> défaut")
