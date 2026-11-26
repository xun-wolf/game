extends Control

# 开场动画：四幕卷轴分镜
# 1 荒芜  2 石下卷轴  3 四季成牌  4 接牌入田
# 交互：点击/空格推进，长按或 ESC 跳过；回访玩家走 2.4 秒极简版。

const BEAT_TIMES = [3.2, 3.6, 4.2, 3.2]
const SUBTITLES = [
	"地荒了三年，草比人高。",
	"石头下压着上一任农夫的卷轴。",
	"四季，被他写成了一副牌。",
	"今年，换你来打。"
]
const SEEN_PATH = "user://intro_seen.json"
const LONG_PRESS_MS = 600
const QUICK_TIME = 2.4

var _beat = -1
var _beat_elapsed = 0.0
var _finished = false
var _quick = false
var _pressing = false
var _press_ms = 0

var _snow = null
var _dust = null
var _cards = []

func _ready():
	_build_fx()
	_cards = [$Stage/Card1, $Stage/Card2, $Stage/Card3, $Stage/Card4]
	$Title.rect_pivot_offset = $Title.rect_size * 0.5
	_fit_to_viewport()
	if not get_viewport().is_connected("size_changed", self, "_fit_to_viewport"):
		get_viewport().connect("size_changed", self, "_fit_to_viewport")
	_show_skip_hint()
	# 开场是否极简只看菜单开关与是否已看；「跳过新手教程」只影响进入游戏后的教程
	if Flags.quick_intro_on_revisit and _has_seen():
		_start_quick()
	else:
		_start_beat(0)

# 按 1080x800 设计稿等比缩放并居中，避免窗口尺寸不同导致构图被裁切
func _fit_to_viewport():
	var vp = get_viewport_rect().size
	var k = min(vp.x / 1080.0, vp.y / 800.0)
	rect_scale = Vector2(k, k)
	rect_position = (vp - Vector2(1080, 800) * k) * 0.5

func _process(delta):
	if _finished:
		return
	if _pressing and OS.get_ticks_msec() - _press_ms >= LONG_PRESS_MS:
		_finish()
		return
	_beat_elapsed += delta
	var dur = QUICK_TIME if _quick else BEAT_TIMES[max(0, _beat)]
	if _beat_elapsed >= dur:
		_advance()

func _unhandled_input(event):
	if _finished:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.scancode == KEY_ESCAPE:
			_finish()
		elif event.scancode == KEY_SPACE or event.scancode == KEY_ENTER:
			_advance()
	elif event is InputEventMouseButton and event.button_index == BUTTON_LEFT:
		if event.pressed:
			_pressing = true
			_press_ms = OS.get_ticks_msec()
		else:
			var held = OS.get_ticks_msec() - _press_ms
			_pressing = false
			if held < LONG_PRESS_MS:
				_advance()

func _advance():
	if _finished:
		return
	if _quick or _beat >= BEAT_TIMES.size() - 1:
		_finish()
		return
	$Tween.stop_all()
	_start_beat(_beat + 1)

func _finish():
	if _finished:
		return
	_finished = true
	_pressing = false
	$Tween.stop_all()
	_mark_seen()
	SceneTransitions.change_scene_to(GS.Game)

# ---------------- 四幕 ----------------

func _start_beat(index):
	_beat = index
	_beat_elapsed = 0.0
	_update_dots(index)
	match index:
		0:
			_beat_ruin()
		1:
			_beat_scroll()
		2:
			_beat_cards()
		3:
			_beat_hand()

func _beat_ruin():
	$Stage.visible = true
	$Stage.scale = Vector2.ONE
	$Stage.position = Vector2.ZERO
	$Stage/Scroll.visible = false
	$Stage/Deck.visible = false
	$Title.visible = false
	for c in _cards:
		c.visible = false
	_set_subtitle(0)
	_snow.emitting = true
	_tween_prop($Stage, "position", Vector2.ZERO, Vector2(26, 0),
		BEAT_TIMES[0], 0.0, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
	$Tween.start()

func _beat_scroll():
	var focus = Vector2(760, 620)
	var zoom = 1.18
	_tween_prop($Stage, "scale", $Stage.scale, Vector2(zoom, zoom), 1.2)
	_tween_prop($Stage, "position", $Stage.position, focus * (1.0 - zoom), 1.2)

	$Stage/Scroll.visible = true
	$Stage/Scroll.modulate = Color(0.85, 0.77, 0.63, 0)
	$Stage/Scroll.position = Vector2(700, 545)
	$Stage/Scroll.scale = Vector2(0.18, 0.18)
	_tween_prop($Stage/Scroll, "modulate:a", 0.0, 1.0, 0.7)
	_tween_prop($Stage/Scroll, "position", Vector2(700, 545), Vector2(700, 500), 0.9)

	$Stage/Deck.visible = true
	$Stage/Deck.modulate = Color(1, 1, 1, 0)
	$Stage/Deck.position = Vector2(820, 560)
	$Stage/Deck.scale = Vector2(0.10, 0.10)
	_tween_prop($Stage/Deck, "modulate:a", 0.0, 1.0, 0.7, 0.15)
	_tween_prop($Stage/Deck, "position", Vector2(820, 560), Vector2(820, 520), 0.9, 0.15)

	_dust.position = Vector2(760, 592)
	_dust.restart()
	_dust.emitting = true

	_set_subtitle(1)
	$Tween.start()

func _beat_cards():
	_tween_prop($Stage, "scale", $Stage.scale, Vector2.ONE, 0.8)
	_tween_prop($Stage, "position", $Stage.position, Vector2.ZERO, 0.8)

	$Stage/Scroll.visible = true
	$Stage/Scroll.modulate = Color(0.85, 0.77, 0.63, 1)
	$Stage/Scroll.position = Vector2(540, 430)
	$Stage/Scroll.scale = Vector2(0.32, 0.02)
	_tween_prop($Stage/Scroll, "scale", Vector2(0.32, 0.02), Vector2(0.32, 0.32), 0.7)
	$Stage/Deck.visible = false

	var xs = [330, 470, 610, 750]
	var rots = [-6, -2, 2, 6]
	for i in range(4):
		var c = _cards[i]
		c.visible = true
		c.position = Vector2(xs[i], 455)
		c.scale = Vector2(0.16, 0.16)
		c.rotation = 0
		c.modulate = Color(1, 1, 1, 0)
		_tween_prop(c, "modulate:a", 0.0, 1.0, 0.6, 0.12 * i)
		_tween_prop(c, "position", Vector2(xs[i], 455), Vector2(xs[i], 425), 0.8, 0.12 * i)
		_tween_prop(c, "rotation", 0.0, deg2rad(rots[i]), 0.8, 0.12 * i)

	_set_subtitle(2)
	$Tween.start()

func _beat_hand():
	_snow.emitting = false
	_tween_prop(_snow, "modulate:a", 1.0, 0.0, 1.0)
	_set_subtitle(3)
	for i in range(4):
		var c = _cards[i]
		_tween_prop(c, "position", c.position, Vector2(540, 640), 0.7, 0.06 * i)
		_tween_prop(c, "scale", c.scale, Vector2(0.05, 0.05), 0.7, 0.06 * i)
		_tween_prop(c, "modulate:a", 1.0, 0.0, 0.5, 0.15 + 0.06 * i)
	_tween_prop($Stage/Scroll, "modulate:a", 1.0, 0.0, 0.5)

	$Title.visible = true
	$Title.modulate = Color(1, 1, 1, 0)
	$Title.rect_scale = Vector2(0.92, 0.92)
	_tween_prop($Title, "modulate:a", 0.0, 1.0, 0.9, 0.25)
	_tween_prop($Title, "rect_scale", Vector2(0.92, 0.92), Vector2.ONE, 0.9, 0.25)
	$Tween.start()

func _start_quick():
	_quick = true
	_beat = -1
	_beat_elapsed = 0.0
	for d in [$Dot1, $Dot2, $Dot3, $Dot4]:
		d.visible = false
	$Stage.visible = false
	$Stage/Scroll.visible = false
	$Stage/Deck.visible = false
	_snow.emitting = false
	$Title.visible = true
	$Title.modulate = Color(1, 1, 1, 0)
	$Title.rect_scale = Vector2(0.94, 0.94)
	_tween_prop($Title, "modulate:a", 0.0, 1.0, 0.8)
	_tween_prop($Title, "rect_scale", Vector2(0.94, 0.94), Vector2.ONE, 0.8)
	_set_subtitle(3)
	$Tween.start()

# ---------------- 辅助 ----------------

func _tween_prop(obj, prop, from_value, to_value, dur, delay = 0.0, trans_type = Tween.TRANS_CUBIC, ease_type = Tween.EASE_OUT):
	$Tween.interpolate_property(obj, prop, from_value, to_value, dur, trans_type, ease_type, delay)

func _update_dots(active):
	var dots = [$Dot1, $Dot2, $Dot3, $Dot4]
	for i in range(dots.size()):
		if i == active:
			dots[i].color = Color(0.95, 0.85, 0.6, 1)
		else:
			dots[i].color = Color(0.4, 0.38, 0.34, 0.7)
		dots[i].visible = true

func _set_subtitle(index):
	$Subtitle.text = SUBTITLES[index]
	$SubtitleBg.visible = true
	$Subtitle.visible = true
	$SubtitleBg.modulate = Color(1, 1, 1, 0)
	$Subtitle.modulate = Color(1, 1, 1, 0)
	_tween_prop($SubtitleBg, "modulate:a", 0.0, 0.85, 0.5)
	_tween_prop($Subtitle, "modulate:a", 0.0, 1.0, 0.5)

func _show_skip_hint():
	$SkipHint.modulate = Color(1, 1, 1, 1)
	_tween_prop($SkipHint, "modulate:a", 1.0, 0.0, 0.8, 5.0)

func _build_fx():
	_snow = CPUParticles2D.new()
	_snow.name = "Snow"
	_snow.texture = load("res://seasons/fx/snow.png")
	_snow.amount = 60
	_snow.lifetime = 9.0
	_snow.preprocess = 6.0
	_snow.local_coords = false
	_snow.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_snow.emission_rect_extents = Vector2(620, 8)
	_snow.position = Vector2(540, -10)
	_snow.direction = Vector2(0, 1)
	_snow.spread = 18.0
	_snow.gravity = Vector2(10, 26)
	_snow.initial_velocity = 24.0
	_snow.initial_velocity_random = 0.6
	_snow.scale_amount = 1.1
	_snow.scale_amount_random = 0.6
	_snow.color = Color(0.94, 0.97, 1.0, 0.9)
	_snow.emitting = false
	$FX.add_child(_snow)

	_dust = CPUParticles2D.new()
	_dust.name = "Dust"
	_dust.texture = load("res://seasons/fx/dust.png")
	_dust.amount = 26
	_dust.lifetime = 1.3
	_dust.one_shot = true
	_dust.local_coords = false
	_dust.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	_dust.emission_sphere_radius = 26.0
	_dust.direction = Vector2(0, -1)
	_dust.spread = 55.0
	_dust.gravity = Vector2(0, -14)
	_dust.initial_velocity = 46.0
	_dust.initial_velocity_random = 0.7
	_dust.scale_amount = 2.0
	_dust.scale_amount_random = 0.8
	_dust.color = Color(0.72, 0.62, 0.5, 0.8)
	_dust.emitting = false
	$FX.add_child(_dust)

func _has_seen():
	var f = File.new()
	if not f.file_exists(SEEN_PATH):
		return false
	if f.open(SEEN_PATH, File.READ) != OK:
		return false
	var data = parse_json(f.get_as_text())
	f.close()
	return typeof(data) == TYPE_DICTIONARY and bool(data.get("seen", false))

func _mark_seen():
	var f = File.new()
	if f.open(SEEN_PATH, File.WRITE) == OK:
		f.store_string(to_json({"seen": true}))
		f.close()
