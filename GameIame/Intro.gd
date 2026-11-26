extends Control

# 开场：农书墨痕 → 灯下成牌
# 1 墨线勾出荒田  2 石下农书  3 四季成牌  4 墨洗接牌
# 交互：点击/空格推进，长按 0.6 秒或 ESC 跳过；回访极简版由主菜单开关控制。

const BEAT_TIMES = [3.5, 4.0, 4.5, 3.2]
const SUBTITLES = [
	"地荒了三年，草比人高。",
	"石头下压着一本旧农书。",
	"二十四候，被他写成了二十四张牌。",
	"今年，换你来打。"
]
const SEEN_PATH = "user://intro_seen.json"
const LONG_PRESS_MS = 600
const QUICK_TIME = 2.4
const PAPER_BASE = Color(0.905, 0.855, 0.75)
const INK_DARK = Color(0.27, 0.19, 0.12, 1)
const INK_LIGHT = Color(0.93, 0.90, 0.82, 1)
const DOT_ON = Color(0.2, 0.14, 0.1, 0.9)
const DOT_OFF = Color(0.45, 0.36, 0.28, 0.45)

var _beat = -1
var _beat_elapsed = 0.0
var _finished = false
var _quick = false
var _pressing = false
var _press_ms = 0

var _cards = []

var _furrow_lines = []
var _furrow_paths = []
var _furrow_t = 0.0

var _dust_ambient = null
var _dust_burst = null

func _ready():
	_make_paper()
	_make_sun()
	_build_fx()
	_build_furrows()
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

	if _beat == 0 and not _quick:
		_grow_furrows(delta)

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
			_beat_book()
		2:
			_beat_cards()
		3:
			_beat_hand()

func _beat_ruin():
	$Stage.visible = true
	$Stage.scale = Vector2.ONE
	$Stage.position = Vector2.ZERO
	$Stage/Scroll.visible = false
	$Title.visible = false
	$DarkWash.color = Color(0.04, 0.03, 0.02, 0)
	$SubtitleBg.visible = true
	$SubtitleBg.modulate = Color(1, 1, 1, 1)
	_set_subtitle_color(true)
	$SkipHint.add_color_override("font_color", Color(0.35, 0.27, 0.2, 0.9))
	for d in [$Dot1, $Dot2, $Dot3, $Dot4]:
		d.modulate = Color(1, 1, 1, 1)
	for c in _cards:
		c.visible = false

	_furrow_t = 0.0
	for line in _furrow_lines:
		line.points = PoolVector2Array()
		line.visible = true

	$Stage.modulate = Color(1, 1, 1, 1)
	$Stage/Stone.modulate = Color(0.4, 0.34, 0.28, 1)
	_dust_ambient.emitting = true
	_set_subtitle(0)
	$Tween.start()

func _beat_book():
	var focus = Vector2(760, 600)
	var zoom = 1.2
	_tween_prop($Stage, "scale", $Stage.scale, Vector2(zoom, zoom), 1.2)
	_tween_prop($Stage, "position", $Stage.position, focus * (1.0 - zoom), 1.2)

	$Stage/Scroll.visible = true
	$Stage/Scroll.modulate = Color(1, 1, 1, 0)
	$Stage/Scroll.position = Vector2(760, 620)
	$Stage/Scroll.scale = Vector2(0.2, 0.2)
	_tween_prop($Stage/Scroll, "modulate:a", 0.0, 1.0, 0.7)
	_tween_prop($Stage/Scroll, "position", Vector2(760, 620), Vector2(680, 512), 0.9)
	_tween_prop($Stage/Scroll, "scale", Vector2(0.2, 0.2), Vector2(0.24, 0.24), 0.9)

	_dust_burst.position = focus
	_dust_burst.restart()
	_dust_burst.emitting = true

	_set_subtitle(1)
	$Tween.start()

func _beat_cards():
	_tween_prop($Stage, "scale", $Stage.scale, Vector2.ONE, 0.8)
	_tween_prop($Stage, "position", $Stage.position, Vector2.ZERO, 0.8)
	_flash_page()

	$Stage/Scroll.visible = true
	$Stage/Scroll.modulate = Color(1, 1, 1, 1)
	$Stage/Scroll.position = Vector2(540, 420)
	$Stage/Scroll.scale = Vector2(0.32, 0.02)
	_tween_prop($Stage/Scroll, "scale", Vector2(0.32, 0.02), Vector2(0.32, 0.32), 0.7)

	var xs = [330, 470, 610, 750]
	var rots = [-6, -2, 2, 6]
	for i in range(4):
		var c = _cards[i]
		c.visible = true
		c.position = Vector2(540, 600)
		c.scale = Vector2(0.16, 0.16)
		c.rotation = 0
		c.modulate = Color(1, 1, 1, 0)
		_tween_prop(c, "modulate:a", 0.0, 1.0, 0.6, 0.12 * i)
		_tween_prop(c, "position", Vector2(540, 600), Vector2(xs[i], 420), 0.8, 0.12 * i)
		_tween_prop(c, "rotation", 0.0, deg2rad(rots[i]), 0.8, 0.12 * i)

	_set_subtitle(2)
	$Tween.start()

func _beat_hand():
	for i in range(4):
		var c = _cards[i]
		_tween_prop(c, "position", c.position, Vector2(540, 620), 0.7, 0.06 * i)
		_tween_prop(c, "scale", c.scale, Vector2(0.05, 0.05), 0.7, 0.06 * i)
		_tween_prop(c, "modulate:a", 1.0, 0.0, 0.5, 0.15 + 0.06 * i)
	_tween_prop($Stage/Scroll, "modulate:a", 1.0, 0.0, 0.5)

	# 墨洗：纸面转暗，场景淡出，白字标题浮现
	_tween_prop($Stage, "modulate:a", 1.0, 0.25, 0.8, 0.1)
	_tween_prop($DarkWash, "color:a", 0.0, 0.82, 0.8, 0.1)
	_tween_prop($SubtitleBg, "modulate:a", 1.0, 0.0, 0.5)
	_set_subtitle_color(false)
	for d in [$Dot1, $Dot2, $Dot3, $Dot4]:
		_tween_prop(d, "modulate:a", 1.0, 0.0, 0.4)
	$SkipHint.add_color_override("font_color", Color(0.8, 0.76, 0.68, 0.85))

	$Title.visible = true
	$Title.modulate = Color(1, 1, 1, 0)
	$Title.rect_scale = Vector2(0.92, 0.92)
	_tween_prop($Title, "modulate:a", 0.0, 1.0, 0.9, 0.5)
	_tween_prop($Title, "rect_scale", Vector2(0.92, 0.92), Vector2.ONE, 0.9, 0.5)

	_set_subtitle(3)
	$Tween.start()

func _start_quick():
	_quick = true
	_beat = -1
	_beat_elapsed = 0.0
	$Stage.visible = false
	$DarkWash.color = Color(0.04, 0.03, 0.02, 0.82)
	$SubtitleBg.visible = false
	$Title.visible = true
	$Title.modulate = Color(1, 1, 1, 0)
	$Title.rect_scale = Vector2(0.94, 0.94)
	_set_subtitle_color(false)
	for d in [$Dot1, $Dot2, $Dot3, $Dot4]:
		d.visible = false
	_tween_prop($Title, "modulate:a", 0.0, 1.0, 0.8)
	_tween_prop($Title, "rect_scale", Vector2(0.94, 0.94), Vector2.ONE, 0.8)
	_set_subtitle(3)
	$SubtitleBg.visible = false
	$Tween.start()

# ---------------- 画面构建 ----------------

func _make_paper():
	var img = Image.new()
	img.create(128, 128, false, Image.FORMAT_RGB8)
	img.lock()
	for y in range(128):
		for x in range(128):
			var n = randf() * 0.04 - 0.02
			img.set_pixel(x, y, Color(PAPER_BASE.r + n, PAPER_BASE.g + n, PAPER_BASE.b + n))
	img.unlock()
	var tex = ImageTexture.new()
	tex.create_from_image(img, Texture.FLAG_REPEAT)
	$Paper.texture = tex

func _make_sun():
	var img = Image.new()
	img.create(96, 96, false, Image.FORMAT_RGBA8)
	img.lock()
	for y in range(96):
		for x in range(96):
			if Vector2(x - 48, y - 48).length() <= 44.0:
				img.set_pixel(x, y, Color(1, 1, 1, 0.14))
	img.unlock()
	var tex = ImageTexture.new()
	tex.create_from_image(img)
	$Stage/Sun.texture = tex

func _build_furrows():
	var anchors_list = [
		[Vector2(60, 468), Vector2(280, 420), Vector2(540, 402), Vector2(800, 420), Vector2(1020, 468)],
		[Vector2(40, 540), Vector2(300, 486), Vector2(540, 466), Vector2(780, 486), Vector2(1040, 540)],
		[Vector2(120, 740), Vector2(320, 690), Vector2(540, 672), Vector2(760, 690), Vector2(960, 740)],
		[Vector2(160, 780), Vector2(360, 730), Vector2(540, 716), Vector2(720, 730), Vector2(920, 780)],
		[Vector2(210, 818), Vector2(400, 776), Vector2(540, 764), Vector2(700, 776), Vector2(880, 818)]
	]
	_furrow_lines = [$Stage/Furrow4, $Stage/Furrow5, $Stage/Furrow1, $Stage/Furrow2, $Stage/Furrow3]
	for anchors in anchors_list:
		_furrow_paths.append(_subdivide(anchors, 28))

func _subdivide(anchors, per_segment):
	var out = []
	for i in range(anchors.size() - 1):
		for s in range(per_segment):
			out.append(anchors[i].linear_interpolate(anchors[i + 1], float(s) / per_segment))
	out.append(anchors[anchors.size() - 1])
	return out

func _grow_furrows(delta):
	_furrow_t += delta
	for i in range(_furrow_lines.size()):
		var local = clamp((_furrow_t - i * 0.2) / 1.8, 0.0, 1.0)
		var n = int(local * _furrow_paths[i].size())
		if n <= 0:
			continue
		var pv = PoolVector2Array()
		for k in range(n):
			pv.append(_furrow_paths[i][k])
		_furrow_lines[i].points = pv

func _build_fx():
	_dust_ambient = CPUParticles2D.new()
	_dust_ambient.name = "DustAmbient"
	_dust_ambient.texture = load("res://seasons/fx/dust.png")
	_dust_ambient.amount = 22
	_dust_ambient.lifetime = 14.0
	_dust_ambient.preprocess = 10.0
	_dust_ambient.local_coords = false
	_dust_ambient.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_dust_ambient.emission_rect_extents = Vector2(620, 300)
	_dust_ambient.position = Vector2(540, 400)
	_dust_ambient.direction = Vector2(1, 0)
	_dust_ambient.spread = 12.0
	_dust_ambient.gravity = Vector2(1.5, -0.6)
	_dust_ambient.initial_velocity = 9.0
	_dust_ambient.initial_velocity_random = 0.8
	_dust_ambient.scale_amount = 1.6
	_dust_ambient.scale_amount_random = 0.8
	_dust_ambient.color = Color(0.45, 0.36, 0.28, 0.28)
	_dust_ambient.emitting = false
	$FX.add_child(_dust_ambient)

	_dust_burst = CPUParticles2D.new()
	_dust_burst.name = "DustBurst"
	_dust_burst.texture = load("res://seasons/fx/dust.png")
	_dust_burst.amount = 18
	_dust_burst.lifetime = 1.4
	_dust_burst.one_shot = true
	_dust_burst.local_coords = false
	_dust_burst.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	_dust_burst.emission_sphere_radius = 30.0
	_dust_burst.direction = Vector2(0, -1)
	_dust_burst.spread = 60.0
	_dust_burst.gravity = Vector2(0, -8)
	_dust_burst.initial_velocity = 42.0
	_dust_burst.initial_velocity_random = 0.8
	_dust_burst.scale_amount = 1.6
	_dust_burst.scale_amount_random = 0.8
	_dust_burst.color = Color(0.55, 0.44, 0.33, 0.55)
	_dust_burst.emitting = false
	$FX.add_child(_dust_burst)

func _flash_page():
	$PageFlash.color = Color(1, 0.98, 0.92, 0)
	_tween_prop($PageFlash, "color:a", 0.0, 0.5, 0.12)
	_tween_prop($PageFlash, "color:a", 0.5, 0.0, 0.32, 0.12)

# ---------------- 辅助 ----------------

func _tween_prop(obj, prop, from_value, to_value, dur, delay = 0.0, trans_type = Tween.TRANS_CUBIC, ease_type = Tween.EASE_OUT):
	$Tween.interpolate_property(obj, prop, from_value, to_value, dur, trans_type, ease_type, delay)

func _set_subtitle_color(dark):
	if dark:
		$Subtitle.add_color_override("font_color", INK_DARK)
	else:
		$Subtitle.add_color_override("font_color", INK_LIGHT)

func _update_dots(active):
	var dots = [$Dot1, $Dot2, $Dot3, $Dot4]
	for i in range(dots.size()):
		if i == active:
			dots[i].color = DOT_ON
		else:
			dots[i].color = DOT_OFF
		dots[i].visible = true

func _set_subtitle(index):
	$Subtitle.text = SUBTITLES[index]
	$SubtitleBg.visible = true
	$Subtitle.visible = true
	$Subtitle.modulate = Color(1, 1, 1, 0)
	_tween_prop($Subtitle, "modulate:a", 0.0, 1.0, 0.5)

func _show_skip_hint():
	$SkipHint.modulate = Color(1, 1, 1, 1)
	_tween_prop($SkipHint, "modulate:a", 1.0, 0.0, 0.8, 5.0)

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
