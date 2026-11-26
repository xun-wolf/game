extends Area2D

const STATE_IN_HAND = 0
const STATE_HOVER = 1
const STATE_PICKUP = 2
const STATE_DISCARD = 3

# 帧率无关的平滑：half_life 秒内完成一半位移
const POS_HALF_LIFE = 0.05
const ROT_HALF_LIFE = 0.07
const SCALE_HALF_LIFE = 0.06
const SPAWN_DURATION = 0.30

var state = STATE_IN_HAND

var associated_card

# The rotation of the card while it is not hovered. Updated by the CardManager
var in_hand_rotation = 0

var in_hand_position = Vector2.ZERO
var in_hand_hover_position = Vector2.ZERO

# 发牌入场：由 GS.add_card_to_hand 写入错峰延迟
var spawn_delay = 0.0
var spawn_time = 0.0

func is_picked_up():
	return state == STATE_PICKUP

func _ready():
	# 从手牌下方飞入，配合 CardManager 的扇形目标位置
	position = Vector2(0, 320)
	scale = Vector2(0.25, 0.25)
	modulate.a = 0.0

func release():
	# TODO: Figure out how this will work with picked up cards
	if state == STATE_HOVER:
		state = STATE_IN_HAND
		
func hover():
	if state == STATE_IN_HAND:
		state = STATE_HOVER

func _k(delta, half_life):
	return 1.0 - pow(0.5, delta / half_life)

func update_transform(delta):
	# 弃牌：快速缩小并飞向弃牌堆
	if state == STATE_DISCARD:
		position += (GS.get_discard_pos() - position) * _k(delta, 0.025)
		rotation += (TAU * 0.25 - rotation) * _k(delta, 0.03)
		var ds = scale.x + (0.0 - scale.x) * _k(delta, 0.025)
		scale = Vector2(ds, ds)
		z_index = 0
		return

	if spawn_delay > 0.0:
		spawn_delay -= delta
		return

	if spawn_time < SPAWN_DURATION:
		spawn_time = min(spawn_time + delta, SPAWN_DURATION)

	var target_scale = 1.0
	var target_rot = in_hand_rotation
	var target_pos = in_hand_position
	z_index = 0
	if state == STATE_HOVER or state == STATE_PICKUP:
		target_scale = 1.25
		target_rot = 0
		target_pos = in_hand_hover_position
		z_index = 100
	if state == STATE_PICKUP:
		# Position should be locked
		target_pos = position
		target_scale = 0.72

	position += (target_pos - position) * _k(delta, POS_HALF_LIFE)
	rotation += (target_rot - rotation) * _k(delta, ROT_HALF_LIFE)
	var s = scale.x + (target_scale - scale.x) * _k(delta, SCALE_HALF_LIFE)
	scale = Vector2(s, s)

func play_self():
	if associated_card.action == GS.Action.PLANT:
		GS.cursor.new_plant(associated_card)
	if associated_card.action == GS.Action.WATER:
		GS.cursor.water(associated_card)
	if associated_card.action == GS.Action.ATTACK:
		GS.cursor.attack(associated_card)
	if associated_card.action == GS.Action.DEFEND:
		GS.cursor.defend(associated_card)
	if associated_card.action == GS.Action.DRAIN_WATER_DMG_RNG:
		GS.cursor.drain_water_dmg_rng(associated_card)
	if associated_card.action == GS.Action.DRAIN_WATER_DMG_ALL:
		GS.cursor.drain_water_dmg_all(associated_card)
	if associated_card.action == GS.Action.HEAL_DMG_NEAR:
		GS.cursor.heal_dmg_near(associated_card)
	if associated_card.action == GS.Action.DEF_DMG_NEAR:
		GS.cursor.def_dmg_near(associated_card)
	if associated_card.action == GS.Action.ADD_DAMAGE:
		GS.cursor.add_damage(associated_card)
	if associated_card.action == GS.Action.DEF_ALL:
		GS.cursor.def_all(associated_card)
	if associated_card.action == GS.Action.HEAL_ALL_DMG:
		GS.cursor.heal_all_dmg(associated_card)
	if associated_card.action == GS.Action.SACRIF:
		GS.cursor.sacrif(associated_card)
	if associated_card.action == GS.Action.DRAW_3:
		GS.draw_card_to_hand()
		GS.draw_card_to_hand()
		GS.draw_card_to_hand()
	if associated_card.action == GS.Action.PLUS_ENERGY:
		GS.energy += 1
		
	GS.energy -= associated_card.cost
	discard()
	
	SFX.card_play.play_sfx()
	
func discard():
	var new_parent = get_node("../../CardDummy")
	get_parent().remove_child(self)
	new_parent.add_child(self)
	
	state = STATE_DISCARD
	GS.discard_pile.push_back(associated_card)
	
func try_play_self():
	GS.release_current_card(self)
	
#	if associated_card.action == GS.Action.PLANT \
#		or associated_card.action == GS.Action.WATER \
#		or associated_card.action == GS.Action.ATTACK \
#		or associated_card.action == GS.Action.DEFEND:
	if GS.cursor.may_play_card():
		play_self()
		return
	
	# If we can't play the card, simply return to hover state.
	state = STATE_HOVER

func spawn_alpha():
	if spawn_time < SPAWN_DURATION:
		return clamp(spawn_time / SPAWN_DURATION, 0.0, 1.0)
	return 1.0

func update_modulate():
	var playable = (associated_card.cost <= GS.energy)
	var mod = Color.white
	if not playable:
		mod = Color(0.4, 0.4, 0.4, 1.0)
	mod.a = spawn_alpha()
	modulate = mod
	
func _physics_process(delta):
	if state == STATE_DISCARD:
		# Disable input
		collision_layer = 0
		collision_mask = 0
		input_pickable = false 
		
		if scale.x < 0.07:
			queue_free()
	
	if state == STATE_PICKUP:
		global_position = get_global_mouse_position()
		position.y += 98 + 30
		
		if Input.is_action_just_released("mouse"):
			try_play_self()
	
	if state == STATE_HOVER:
		if GS.energy >= associated_card.cost:
			if Input.is_action_just_pressed("mouse"):
				state = STATE_PICKUP
				GS.set_current_card(self)
			
	update_transform(delta)
	update_modulate()
