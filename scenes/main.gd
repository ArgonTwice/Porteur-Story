## Écran M0 : affiche l'horloge ; boutons pause et vitesse. Sert à valider l'APK.
## Tailles en dp réels (densité écran), recalculées au pliage/dépliage.
extends Control

const BUTTON_DP := 56.0 ## [P] hauteur des boutons (>= 48 dp, cible tactile Android)
const FONT_DP := 22.0 ## [P] taille du texte
const WIDTH_DP := 300.0 ## [P] largeur du bloc

var _box := VBoxContainer.new()
var _title := Label.new()
var _label := Label.new()
var _pause := Button.new()
var _speed := Button.new()


func _ready() -> void:
	_box.set_anchors_preset(PRESET_CENTER)
	_box.grow_horizontal = GROW_DIRECTION_BOTH
	_box.grow_vertical = GROW_DIRECTION_BOTH
	add_child(_box)
	_title.text = tr("app.title")
	for n in [_title, _label, _pause, _speed]:
		_box.add_child(n)
	for l in [_title, _label]:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_pause.pressed.connect(func() -> void: Clock.sim.paused = not Clock.sim.paused)
	_speed.pressed.connect(Clock.sim.cycle_speed)
	resized.connect(_apply_scale) # suit le viewport (plié/déplié, rotation)
	_apply_scale.call_deferred()


## Convertit des dp Android en unités du viewport (après stretch canvas_items).
func _dp(v: float) -> float:
	var px := v * DisplayServer.screen_get_dpi() / 160.0
	return px / get_viewport().get_final_transform().get_scale().x


func _apply_scale() -> void:
	var font := int(_dp(FONT_DP))
	for n in [_title, _label, _pause, _speed]:
		n.add_theme_font_size_override("font_size", font)
	_title.add_theme_font_size_override("font_size", int(font * 1.4))
	for b in [_pause, _speed]:
		b.custom_minimum_size.y = _dp(BUTTON_DP)
	_box.add_theme_constant_override("separation", int(_dp(8)))
	_box.custom_minimum_size.x = minf(_dp(WIDTH_DP), size.x * 0.9)
	_box.reset_size()
	_box.position = (size - _box.size) / 2


func _process(_delta: float) -> void:
	var c := Clock.sim
	_label.text = "%s · %s" % [tr("clock.day") % c.day(), tr("clock.evening" if c.is_evening() else "clock.morning")]
	_pause.text = tr("clock.paused") if c.paused else "||"
	_speed.text = tr("clock.speed") % c.speed
