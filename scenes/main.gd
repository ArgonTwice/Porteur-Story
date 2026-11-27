## Écran M0 : affiche l'horloge ; boutons pause et vitesse. Sert à valider l'APK.
extends Control

var _label := Label.new()
var _pause := Button.new()
var _speed := Button.new()


func _ready() -> void:
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(PRESET_CENTER)
	box.grow_horizontal = GROW_DIRECTION_BOTH
	box.grow_vertical = GROW_DIRECTION_BOTH
	add_child(box)
	var title := Label.new()
	title.text = tr("app.title")
	for n in [title, _label, _pause, _speed]:
		n.add_theme_font_size_override("font_size", 40)
		box.add_child(n)
	_pause.pressed.connect(func() -> void: Clock.sim.paused = not Clock.sim.paused)
	_speed.pressed.connect(Clock.sim.cycle_speed)


func _process(_delta: float) -> void:
	var c := Clock.sim
	_label.text = "%s · %s" % [tr("clock.day") % c.day(), tr("clock.evening" if c.is_evening() else "clock.morning")]
	_pause.text = tr("clock.paused") if c.paused else "||"
	_speed.text = tr("clock.speed") % c.speed
