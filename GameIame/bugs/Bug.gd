extends Node2D

enum ActionType {
	ATTACK_CLOSEST
}

# 等级越高：体型越大、甲壳越硬，立绘也不同
const TIER_TEXTURES = {
	1: preload("res://bugs/bug_t1.png"),
	2: preload("res://bugs/bug_t2.png"),
	3: preload("res://bugs/bug_t3.png"),
	4: preload("res://bugs/bug_t4.png"),
}

const HEART_NORMAL = preload("res://plants/heart_marker.svg")
const HEART_GOLD = preload("res://plants/heart_frame_gold.png")

# 血量标记按档位换色：普通白 -> 浅红 -> 深红 -> 虫王(整颗暗金)
const TIER_MARKER_COLORS = {
	1: Color(1.0, 1.0, 1.0, 1.0),
	2: Color(1.0, 0.68, 0.45, 1.0),
	3: Color(1.0, 0.40, 0.34, 1.0),
	4: Color(1.0, 1.0, 1.0, 1.0),
}

export var tier = 1

export var health = 3

func _ready():
	apply_tier()

func apply_tier():
	if $Sprite == null:
		return
	var t = int(clamp(tier, 1, 4))
	$Sprite.texture = TIER_TEXTURES.get(t, TIER_TEXTURES[1])
	# 虫王整颗心换成暗金底，其它档位只调色
	$HeartMarker.texture = HEART_GOLD if t == 4 else HEART_NORMAL
	$HeartMarker.modulate = TIER_MARKER_COLORS.get(t, Color(1, 1, 1, 1))
	if t == 4:
		announce_king()

func announce_king():
	# 虫王出场给一条横幅提示（复用季节横幅那套 toast）+ 低频轰鸣 + 地面震动
	if not is_inside_tree():
		return
	if SeasonManager != null:
		SeasonManager.show_king_banner("【虫王来袭】田垄轰鸣，黑甲虫王破土而出！")
	shake_camera(0.55, 7.0)
	if SFX != null:
		SFX.king_spawn.play_usual()

func set_tier_health(t, h):
	tier = t
	health = h
	apply_tier()

export var actions: Array = [ActionType.ATTACK_CLOSEST]

var next_action = 0

var current_plant_target = null

var spawned = false

func spawn_now():
	spawned = true
	$AnimationPlayer.play("Spawn")

#func _ready():
#	spawned = true
#	$AnimationPlayer.play("Spawn")

func _physics_process(delta):
	$HeartMarker/HealthNum.text = String(health)
	
	# If our animation is done, also check the target's animation.
	if not $AnimationPlayer.is_playing():
		if is_instance_valid(current_plant_target):
			if not current_plant_target.get_node("AnimationPlayer").is_playing():
				current_plant_target = null
				
func dec_health():
	var amount = attack_queue.pop_front()
	if amount == null:
		amount = 1
	health -= amount
	if health <= 0:
		remove_from_group("Enemy")
		remove_from_group("Object")
		$AnimationPlayer.queue("OutOfHealth")
		
var attack_queue = []
		
func take_damage(amount):
	if health <= 0:
		return
	attack_queue.push_back(amount)
	$AnimationPlayer.play("Slash")

func pull_action():
	var result = actions[next_action]
	
	next_action += 1
	if next_action >= actions.size():
		next_action = 0
		
	return result

func compute_action():
	var op = actions[next_action]
	
	# Here we can implement some branching logic... basically a very
	# simple bytecode... if we want more complex enemy behaviors.
	
	return op

func take_turn():
	$AnimationPlayer.queue("Delay")
	
	if not spawned:
		spawned = true
		$AnimationPlayer.queue("Spawn")
		return
	
	var act = compute_action()
	
	if act == ActionType.ATTACK_CLOSEST:
		attack(find_closest())
		
func turn_over():
	if is_instance_valid(current_plant_target):
		if current_plant_target.get_node("AnimationPlayer").is_playing():
			return false
	return not $AnimationPlayer.is_playing()
	
func attack(plant):
	if not is_instance_valid(plant):
		return
	
	$AnimationPlayer.play("Attack")
	current_plant_target = plant
	
func play_target_anim():
	current_plant_target.slash_health(1)
	# 大虫子撞击时震屏 + 重击音效（等级越高越明显）
	if tier >= 3:
		if tier >= 4:
			shake_camera(0.30, 6.0)
			SFX.heavy_hit.play_sfx()
		else:
			shake_camera(0.18, 3.0)
			SFX.heavy_hit.play_sfx()

func shake_camera(duration: float, magnitude: float):
	if is_instance_valid(GS.camera) and GS.camera.has_method("shake"):
		GS.camera.shake(duration, magnitude)
	
func find_closest():
	var closest = null
	var dist = 0
	for plant in get_tree().get_nodes_in_group("Plant"):
		if plant.consumed: # Consumed plants will queue_free() immediately
			continue
		
		if closest == null:
			closest = plant
			dist = (plant.position - position).length()
		else:
			var test = (plant.position - position).length()
			if test < dist:
				closest = plant
				dist = test
	return closest
	
func finalize_turn():
	pass
