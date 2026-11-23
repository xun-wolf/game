extends Node2D

# 季节环境特效：春花瓣 / 夏浮尘 / 秋落叶 / 冬落雪。
# 挂在 Game 的 CanvasLayer 下（屏幕空间），由 SeasonManager.apply_season 驱动。

enum Season {
	SPRING = 0,
	SUMMER = 1,
	AUTUMN = 2,
	WINTER = 3
}

const TEX_PETAL = preload("res://seasons/fx/petal.png")
const TEX_LEAF_GOLD = preload("res://seasons/fx/leaf_gold.png")
const TEX_LEAF_RED = preload("res://seasons/fx/leaf_red.png")
const TEX_DUST = preload("res://seasons/fx/dust.png")
const TEX_SNOW = preload("res://seasons/fx/snow.png")

var emitters = {}
var current_season = -1

func _ready():
	_build_emitters()
	var vp = get_viewport()
	if vp != null and not vp.is_connected("size_changed", self, "_layout"):
		vp.connect("size_changed", self, "_layout")
	_layout()
	set_season(Season.SPRING)

func _new_emitter(key, tex, amount, lifetime, full_area):
	var p = CPUParticles2D.new()
	p.name = key
	p.texture = tex
	p.amount = amount
	p.lifetime = lifetime
	p.one_shot = false
	p.preprocess = lifetime * 0.8
	p.randomness = 0.55
	p.local_coords = false
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emitting = false
	p.visible = false
	p.direction = Vector2(0, 1)
	p.spread = 22.0
	p.gravity = Vector2(0, 30)
	p.set_meta("full_area", full_area)
	p.set_meta("base_amount", amount)
	add_child(p)
	emitters[key] = p
	return p

func _build_emitters():
	# ---- 春：飘落花瓣 ----
	var petal = _new_emitter("Petals", TEX_PETAL, 30, 11.0, false)
	petal.initial_velocity = 26.0
	petal.initial_velocity_random = 0.55
	petal.spread = 34.0
	petal.gravity = Vector2(12.0, 12.0)
	petal.angular_velocity = 40.0
	petal.angular_velocity_random = 1.0
	petal.scale_amount = 0.55
	petal.scale_amount_random = 0.6
	petal.hue_variation_random = 0.02

	# ---- 夏：干燥浮尘 ----
	var dust = _new_emitter("Dust", TEX_DUST, 40, 5.0, true)
	dust.direction = Vector2(0, -1)
	dust.spread = 70.0
	dust.gravity = Vector2(6.0, -3.0)
	dust.initial_velocity = 10.0
	dust.initial_velocity_random = 0.8
	dust.scale_amount = 0.5
	dust.scale_amount_random = 0.7
	dust.color = Color(1.0, 0.93, 0.8, 0.55)

	# ---- 秋：落叶（远近两层，远的慢且淡）----
	var leaf_far = _new_emitter("LeavesFar", TEX_LEAF_GOLD, 26, 13.0, false)
	leaf_far.initial_velocity = 18.0
	leaf_far.initial_velocity_random = 0.7
	leaf_far.spread = 40.0
	leaf_far.gravity = Vector2(18.0, 8.0)
	leaf_far.angular_velocity = 60.0
	leaf_far.angular_velocity_random = 1.0
	leaf_far.scale_amount = 0.42
	leaf_far.scale_amount_random = 0.5
	leaf_far.color = Color(0.92, 0.88, 0.8, 0.75)
	leaf_far.hue_variation_random = 0.06

	var leaf_near = _new_emitter("LeavesNear", TEX_LEAF_RED, 14, 9.5, false)
	leaf_near.initial_velocity = 46.0
	leaf_near.initial_velocity_random = 0.6
	leaf_near.spread = 26.0
	leaf_near.gravity = Vector2(30.0, 24.0)
	leaf_near.angular_velocity = 120.0
	leaf_near.angular_velocity_random = 1.0
	leaf_near.scale_amount = 1.05
	leaf_near.scale_amount_random = 0.55
	leaf_near.hue_variation_random = 0.05

	# ---- 冬：飘雪（远近两层）----
	var snow_far = _new_emitter("SnowFar", TEX_SNOW, 110, 15.0, false)
	snow_far.initial_velocity = 16.0
	snow_far.initial_velocity_random = 0.7
	snow_far.spread = 30.0
	snow_far.gravity = Vector2(10.0, 12.0)
	snow_far.angular_velocity = 20.0
	snow_far.angular_velocity_random = 1.0
	snow_far.scale_amount = 0.55
	snow_far.scale_amount_random = 0.6
	snow_far.color = Color(0.96, 0.98, 1.0, 0.9)

	var snow_near = _new_emitter("SnowNear", TEX_SNOW, 40, 10.0, false)
	snow_near.initial_velocity = 34.0
	snow_near.initial_velocity_random = 0.7
	snow_near.spread = 22.0
	snow_near.gravity = Vector2(14.0, 26.0)
	snow_near.angular_velocity = 30.0
	snow_near.angular_velocity_random = 1.0
	snow_near.scale_amount = 1.0
	snow_near.scale_amount_random = 0.6
	snow_near.color = Color(1.0, 1.0, 1.0, 1.0)

func _layout():
	var vp = get_viewport()
	if vp == null:
		return
	var s = vp.size
	for key in emitters:
		var p = emitters[key]
		if p.get_meta("full_area"):
			p.position = s * 0.5
			p.emission_rect_extents = s * 0.55
		else:
			p.position = Vector2(s.x * 0.5, -24.0)
			p.emission_rect_extents = Vector2(s.x * 0.62, 6.0)

func set_season(season):
	current_season = season
	var active = {
		"Petals": season == Season.SPRING,
		"Dust": season == Season.SUMMER,
		"LeavesFar": season == Season.AUTUMN,
		"LeavesNear": season == Season.AUTUMN,
		"SnowFar": season == Season.WINTER,
		"SnowNear": season == Season.WINTER,
	}
	for key in emitters:
		var p = emitters[key]
		if active.get(key, false):
			if not p.emitting:
				p.visible = true
				p.emitting = true
				p.restart()
		else:
			# 直接隐藏：emitting=false 只会冻结粒子，旧季节的叶子会挂在半空
			p.emitting = false
			p.visible = false

func is_emitting(key):
	if emitters.has(key):
		return emitters[key].emitting
	return false
