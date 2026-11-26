extends Node2D

export var health = 3
var water = 0
var defense = 0

var health_disp = 3
var water_disp = 0
var defense_disp = 0

export var plant_scale = 1.0

export var card_level = 1

export var anim_frames: SpriteFrames

# If the plant is "consumed", that means the card / gold popup has been
# shown, and the plant should be queue_freed()
var consumed = false

var spawn_sfx_timer = 0.15

var pips = []
var pip_row: Control
var hover_area: Control
var mature_tween: Tween
var last_tip = ""

func nowater_sfx():
	SFX.no_water.play_sfx()

func _ready():
	if GS.auto_water:
		water = 1
	
	if anim_frames != null:
		$Plant.frames = anim_frames
	$Plant.scale = Vector2(plant_scale, plant_scale)
	
	heart_update()
	defense_update()
	water_update()
	
	_build_growth_ui()
	refresh_growth()

func _get_frames():
	if anim_frames != null:
		return anim_frames
	return $Plant.frames

# 阶段点：横排在植株右上角，亮起的点数表示当前生长到第几阶段。
func _build_growth_ui():
	var frames = _get_frames()
	if frames == null:
		return
	var total = frames.get_frame_count("default")
	if total <= 0:
		return
	var step = 8
	var width = total * step - 1
	pip_row = Control.new()
	pip_row.name = "GrowthPips"
	pip_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pip_row.rect_position = Vector2(112 - width, 18)
	add_child(pip_row)
	for i in range(total):
		var bg = ColorRect.new()
		bg.rect_position = Vector2(i * step, 0)
		bg.rect_size = Vector2(7, 7)
		bg.color = Color(0.08, 0.06, 0.05, 0.75)
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pip_row.add_child(bg)
		var fill = ColorRect.new()
		fill.rect_position = Vector2(i * step + 1, 1)
		fill.rect_size = Vector2(5, 5)
		fill.color = Color(0.93, 0.78, 0.34, 1.0)
		fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pip_row.add_child(fill)
		pips.append(fill)
	
	hover_area = Control.new()
	hover_area.name = "GrowthHover"
	hover_area.rect_position = Vector2(16, 16)
	hover_area.rect_size = Vector2(96, 96)
	hover_area.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(hover_area)

func refresh_growth():
	var frames = _get_frames()
	if frames == null or pips.size() == 0:
		return
	var total = frames.get_frame_count("default")
	var idx = $Plant.frame
	for i in range(pips.size()):
		var lit = i <= idx
		pips[i].color = Color(0.93, 0.78, 0.34, 1.0) if lit else Color(0.35, 0.3, 0.24, 0.9)
	if idx >= total - 1:
		_start_mature_glow()
	_refresh_tooltip()

func _refresh_tooltip():
	var frames = _get_frames()
	if frames == null or hover_area == null:
		return
	var total = frames.get_frame_count("default")
	var remain = total - 1 - $Plant.frame
	var tip = "已成熟，可收获"
	if remain > 0:
		var step = 2 if card_level == 4 else 1
		var waterings = int(ceil(float(remain) / step))
		var water = 0
		for i in range(waterings):
			water += _water_cost_at_turn(GS.current_turn + i)
		var mature_turn = GS.current_turn + waterings - 1
		# 成熟后要下一候才收获，因此收获候 = 成熟候 + 1
		if mature_turn + 1 > GS.max_turns:
			tip = "还需 %d 次浇水 · 共需 %d 水\n年内无法收获（成熟也赶不上收获）" % [waterings, water]
		else:
			var when = "第 %d 候" % mature_turn
			var term = SeasonManager.get_turn_term(mature_turn)
			if term != "时节":
				when = "%s（第 %d 候）" % [term, mature_turn]
			tip = "还需 %d 次浇水 · 共需 %d 水\n预计%s成熟，次候收获（每候足水）" % [waterings, water, when]
	if tip != last_tip:
		last_tip = tip
		hover_area.hint_tooltip = tip

# 按候推算单阶段耗水：旱情窗口内翻倍（三品 10-12 候、一品 10-14 候）。
func _water_cost_at_turn(turn):
	var cost = SeasonManager.WATER_COST_BASE
	if DifficultyManager.is_drought_turn(turn):
		cost += 1
	return cost

func _start_mature_glow():
	if mature_tween != null:
		return
	var base_scale = Vector2(plant_scale, plant_scale)
	mature_tween = Tween.new()
	add_child(mature_tween)
	mature_tween.interpolate_property($Plant, "modulate", Color(1, 1, 1), Color(1.0, 0.78, 0.42), 0.8, Tween.TRANS_SINE, Tween.EASE_IN_OUT, 0.0)
	mature_tween.interpolate_property($Plant, "modulate", Color(1.0, 0.78, 0.42), Color(1, 1, 1), 0.8, Tween.TRANS_SINE, Tween.EASE_IN_OUT, 0.8)
	mature_tween.interpolate_property($Plant, "scale", base_scale, base_scale * 1.05, 0.8, Tween.TRANS_SINE, Tween.EASE_IN_OUT, 0.0)
	mature_tween.interpolate_property($Plant, "scale", base_scale * 1.05, base_scale, 0.8, Tween.TRANS_SINE, Tween.EASE_IN_OUT, 0.8)
	mature_tween.set_repeat(true)
	mature_tween.start()


func centered_lpf_noise(in_pos):
	var r = rand_range(0, 32)
	var th = rand_range(0, 6.28)
	var pos = Vector2(64, 64) + polar2cartesian(r, th)
	
	return in_pos + (pos - in_pos) * 0.005
	
func sine_y_offset(node, offset):
	var theta = GS.global_sine_timer * 64 + offset
	var y = sin(theta * (PI / 32.0))
	
	node.position.y = y
	
func slash_health(amount):
	$AnimationPlayer.play("Slash")
	SFX.whack.play_sfx()
	
# Can be called from animations to explicitly update the visibility at some point.
func update_markers_visibility():
	$H/HeartMarker.visible = (health > -1) # I guess
	$W/WaterMarker.visible = (water > 0)
	$D/DefenseMarker.visible = (defense > 0)

func update_display():
	#$H/HeartMarker/HealthNum.text = String(health)
	#$W/WaterMarker/WaterNum.text = String(water)
	#$D/DefenseMarker/DefenseNum.text = String(defense)
	
	_refresh_tooltip()
	
	# Don't update visibility while the animation is going...?
	if not $AnimationPlayer.is_playing():
		update_markers_visibility()
	
	# Randomly move markers and plant sprite for a little bit more life.
	# One option for this: JitterFX.gd, inspired by the main menu of my game
	# HaleyHeartbeat
	#$HeartMarker.position = centered_lpf_noise($HeartMarker.position)
	#$WaterMarker.position = centered_lpf_noise($WaterMarker.position)
	#$DefenseMarker.position = centered_lpf_noise($DefenseMarker.position)
	
	#$Plant.position = centered_lpf_noise($Plant.position)
	
	# Another option: sine wave, may look nicer than noise for this purpose.
	sine_y_offset($H, 28)
	sine_y_offset($W, 64)
	sine_y_offset($D, 100)
	

func _process(delta):
	update_display()
	
	if spawn_sfx_timer > 0:
		spawn_sfx_timer -= delta
		if spawn_sfx_timer <= 0:
			SFX.rand_seeds()
	
func take_turn():
	var anim = $AnimationPlayer
	
	anim.queue("Delay")
	
	var needed_water = SeasonManager.water_cost_per_stage()
	if water >= needed_water:
		if $Plant.frame == $Plant.frames.get_frame_count("default") - 1:
			anim.queue("PlantIsDone")
			consumed = true
		else:
			anim.queue("WaterPlant")
	else:
		anim.queue("NoWater")
		
func water_sfx():
	SFX.rand_water()
	
func dec_health():	
	var amount = 1
	
	# TODO: Animate shield rather than heart...
	if defense > 0:
		defense -= amount
		$ShieldFX.play("Pop")
		if defense < 0:
			amount = -defense
			defense = 0
		else:
			return
	
	health -= amount
	$HeartFX.play("Pop")
	if health <= 0:
		$AnimationPlayer.queue("OutOfHealth")
		
func set_health(amount):
	if health <= 0:
		return
	
	if amount > 10:
		amount = 10
	health = amount
	
	$HeartFX.play("Pop")
	
	if health <= 0:
		$AnimationPlayer.queue("OutOfHealth")
		
func set_defense(amount):
	if amount > 10:
		amount = 10
	if amount < 0:
		amount = 0
	defense = amount
	
	$ShieldFX.play("Pop")
	
func set_water(amount):
	if amount > 10:
		amount = 10
	if amount < 0:
		amount = 0
	water = amount
	
	$WaterFX.play("Pop")

func heart_update():
	health_disp = health
	$H/HeartMarker/HealthNum.text = String(health_disp)
	
func defense_update():
	defense_disp = defense
	$D/DefenseMarker/DefenseNum.text = String(defense)
	
func water_update():
	water_disp = water
	$W/WaterMarker/WaterNum.text = String(water)

	#
	#

func water_plant():
	set_water(water - SeasonManager.water_cost_per_stage())
	
func popup_menu():
	if card_level == 1:
		GS.popup_card_selection(CardCreation.pick_plant1_cards(health), 1)
	elif card_level == 2:
		GS.popup_card_selection(CardCreation.pick_plant2_cards(health), 2)
	elif card_level == 3:
		GS.popup_card_selection(CardCreation.pick_plant3_cards(health), 3)
	elif card_level == 4:
		GS.popup_card_winner()
	
func upgrade_plant():
	# 金稻·神种每次浇水推进两个生长阶段
	var total = _get_frames().get_frame_count("default")
	var step = 2 if card_level == 4 else 1
	$Plant.frame = min($Plant.frame + step, total - 1)
	refresh_growth()
	
func turn_over():
	# If we are being polled about our turn, then the card selection
	# dialog must be related to this plant.
	if GS.waiting_for_card_selection:
		return false
	return not $AnimationPlayer.is_playing()
	
func finalize_turn():
	if consumed:
		queue_free()
