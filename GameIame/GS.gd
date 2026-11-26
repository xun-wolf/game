extends Node

enum Action {
	PLANT,
	WATER,
	ATTACK,
	DEFEND,
	DRAIN_WATER_DMG_RNG,
	DRAIN_WATER_DMG_ALL,
	HEAL_DMG_NEAR,
	DEF_DMG_NEAR,
	
	ADD_DAMAGE,
	
	DEF_ALL,
	HEAL_ALL_DMG,
	
	SACRIF,
	
	DRAW_3,
	PLUS_ENERGY
}

enum Water {
	W1x1,
	W2x2,
	W3x3
}

enum TurnState {
	UNDEFINED,
	WAITING_FOR_TUTORIAL,
	PLAYING_CARDS,
	UPDATING
}

const CAT_WATER = 1
const CAT_DEF = 2
const CAT_ATK = 3
const CAT_SEED = 4

var CardTexWater = preload("res://cards/card_water.svg")
var CardTexDef = preload("res://cards/card_tank.svg")
var CardTexAtk = preload("res://cards/card_attak.svg")
var CardTexSeed = preload("res://cards/card_seeds.svg")

var turn_state = TurnState.UNDEFINED
var waiting_for_card_selection = false

var card_selector_ui = null
var gold = 0
var current_turn = 1
var max_turns = 24
var tax_amount = 18
var game_settled = false
var current_harvest_plant_level = 1
var energy = 3
var energy_max = 3

var shop_open = false
var upper_panel_mouse = false
var tutorial_mouse = false
var new_cards_mouse = false
var end_turn_mouse = false

func popup_card_selection(card_set: Array, plant_level = 1):
	current_harvest_plant_level = plant_level
	waiting_for_card_selection = true
	card_selector_ui.setup_cards(card_set, plant_level)
	card_selector_ui.popup()
	
func popup_card_winner():
	waiting_for_card_selection = true
	card_selector_ui.setup_win()
	card_selector_ui.popup()

func popup_tax_settlement(passed: bool, current_gold: int, target_tax: int):
	waiting_for_card_selection = true
	card_selector_ui.setup_tax_settlement(passed, current_gold, target_tax)
	card_selector_ui.popup()

class Card:
	var title: String
	var desc: String
	var cost: int
	var action
	
	var water_shape
	
	# Amount of damage, water, or defense
	var quantity
	
	# Amount of drain for health or water
	var drain
	
	var mult
	
	# Category / build, these things influence card generation
	var cat
	
	var icon
	
	func _init(title_: String, desc_: String, cost_: int, action_):
		title = title_
		desc = desc_
		cost = cost_
		action = action_
		
		quantity = 1
		drain = 1
		
		cat = 0
		icon = null
		
	func shape(water_shape_):
		water_shape = water_shape_
		return self
		
	func with_quantity(amount_):
		quantity = amount_
		return self
		
	func with_drain(amount_):
		drain = amount_
		return self
		
	func with_mult(m):
		mult = m
		return self
		
	func with_cat(c):
		cat = c
		return self
		
	func with_icon(ic):
		icon = ic
		return self

# The "global state" node. This is where global variables are usually stored,
# as well as things like scene preloads.

var card_basic_plant : Card = Card.new(
	"初耕·小白菜",
	"在沃土上播撒青菜良种，经受雨露滋养，长成后可收获基础农获",
	1,
	Action.PLANT).with_cat(CAT_SEED).with_icon(preload("res://cards/icons/basic_seeds.svg"))
	
var card_medium_plant : Card = Card.new(
	"田禾·红番茄",
	"选育健壮农禾，精心照料成熟，可收获更具价值的农事卡牌",
	2,
	Action.PLANT).with_cat(CAT_SEED).with_icon(preload("res://cards/icons/middling_seeds.svg"))
	
var card_high_plant : Card = Card.new(
	"精选·紫葡萄",
	"搭架引蔓的稀罕果种，需漫长水土滋育，收获极珍贵的精妙卡牌",
	3,
	Action.PLANT).with_cat(CAT_SEED).with_icon(preload("res://cards/icons/quality_seeds.svg"))
	
var card_free_1x1_water : Card = Card.new(
	"晨露清沥",
	"引清晨凝露，为 1x1 地垄润入 1 点水分",
	0,
	Action.WATER
).shape(Water.W1x1).with_cat(CAT_WATER).with_icon(preload("res://cards/icons/water_drop.svg"))

var card_buy_1x1_water : Card = Card.new(
	"水瓢浅浇",
	"信手舀水细浇，为 1x1 地垄补充 1 点水分",
	1,
	Action.WATER
).shape(Water.W1x1).with_cat(CAT_WATER).with_icon(preload("res://cards/icons/water_drip.svg"))

var card_small_attack : Card = Card.new(
	"挥锄除虫",
	"挥动铁锄狠准拍击，对单个害虫造成 $DQ 点伤害",
	1,
	Action.ATTACK
).with_quantity(1).with_cat(CAT_ATK).with_icon(preload("res://cards/icons/whack.svg"))

var card_small_defend : Card = Card.new(
	"细密防虫网",
	"为单株作物罩上防虫网抵御害虫，施加 1 点免疫",
	1,
	Action.DEFEND
).with_quantity(1).with_cat(CAT_DEF).with_icon(preload("res://cards/icons/netting_shield.svg"))

# Low water cards

var card_drain1_dmg3 : Card = Card.new(
	"引浆御虫",
	"自单株作物汲取 1 点水分化作水箭，对随机害虫造成 $DQ 点伤害",
	0,
	Action.DRAIN_WATER_DMG_RNG
).with_quantity(3).with_drain(1).with_cat(CAT_WATER).with_icon(preload("res://cards/icons/water_dagger.svg"))

var card_water2_1x1 : Card = Card.new(
	"水桶重灌",
	"提桶注水深透，为 1x1 地块饱浸 2 点水分",
	1,
	Action.WATER
).shape(Water.W1x1).with_quantity(2).with_cat(CAT_WATER).with_icon(preload("res://cards/icons/pour_one.svg"))

var card_water1_2x2 : Card = Card.new(
	"竹制喷壶",
	"持细孔喷壶均匀散水，为 2x2 垄田各施加 1 点水分",
	3,
	Action.WATER
).shape(Water.W2x2).with_cat(CAT_WATER).with_icon(preload("res://cards/icons/water_can.svg"))

# Medium water cards

var card_water1_3x3 : Card = Card.new(
	"引渠入垄",
	"引溪流灌溉四方，为 3x3 广袤田畴各滋润 1 点水分",
	3,
	Action.WATER
).shape(Water.W3x3).with_cat(CAT_WATER).with_icon(preload("res://cards/icons/water_barrel.svg"))

var card_water2_2x2 : Card = Card.new(
	"龙骨水车",
	"借水车翻转之功，为 2x2 区域各注入 2 点充沛水分",
	4,
	Action.WATER
).shape(Water.W2x2).with_quantity(2).with_cat(CAT_WATER).with_icon(preload("res://cards/icons/hose.svg"))

var card_drain3_rng5 : Card = Card.new(
	"激流冲淋",
	"自作物抽取 1 点水分化作激流，对随机害虫造成 $DQ 点高额冲击",
	1,
	Action.DRAIN_WATER_DMG_RNG
).with_drain(1).with_quantity(4).with_cat(CAT_WATER).with_icon(preload("res://cards/icons/water_blast.svg"))

# High water cards

var card_water5 : Card = Card.new(
	"天降甘霖",
	"逢久旱得甘霖，为单株作物倾注 5 点充足水分",
	3,
	Action.WATER
).shape(Water.W1x1).with_quantity(5).with_cat(CAT_WATER).with_icon(preload("res://cards/icons/rainfall.svg"))

var card_drain7_dmgall5 : Card = Card.new(
	"山洪涤秽",
	"引田间 4 点澎湃水力涤荡全场，对所有害虫造成 $DQ 点毁灭巨创",
	4,
	Action.DRAIN_WATER_DMG_ALL
).with_quantity(5).with_drain(4).with_cat(CAT_WATER).with_icon(preload("res://cards/icons/tsunami.svg"))

var card_drain3_dmgall1 : Card = Card.new(
	"漫堤排涝",
	"排泄田间 2 点积存积涝，狂澜冲刷，对所有害虫造成 $DQ 点伤害",
	2,
	Action.DRAIN_WATER_DMG_ALL
).with_quantity(2).with_drain(2).with_cat(CAT_WATER).with_icon(preload("res://cards/icons/overflow.svg"))

# Low tank cards

var card_3def_1 : Card = Card.new(
	"稻草扎人",
	"立稻草人守卫垄畔，威慑田鼠飞雀，为作物施加 3 点免疫",
	1,
	Action.DEFEND
).with_quantity(3).with_cat(CAT_DEF).with_icon(preload("res://cards/icons/tough_shield.svg"))

var card_heal1_dmg1 : Card = Card.new(
	"草木灰肥",
	"撒灰除虫固本，使单株作物回复 1 点生命，同时呛击最近害虫 $DQ 点伤害",
	1,
	Action.HEAL_DMG_NEAR
).with_quantity(1).with_drain(1).with_cat(CAT_DEF).with_icon(preload("res://cards/icons/vampire_fang.svg"))

var card_def2_dmg1 : Card = Card.new(
	"荆棘编篱",
	"在垄旁编织带刺荆棘，为作物提供 2 点免疫，并反刺最近害虫 $DQ 点伤害",
	1,
	Action.DEF_DMG_NEAR
).with_quantity(1).with_drain(2).with_cat(CAT_DEF).with_icon(preload("res://cards/icons/spiked_shield.svg"))

# Medium tank cards

var card_heal2_dmg2 : Card = Card.new(
	"沃土深培",
	"深翻客土培根，为单株作物回复 3 点生命，震退最近害虫造成 $DQ 点伤害",
	3,
	Action.HEAL_DMG_NEAR
).with_quantity(2).with_drain(3).with_cat(CAT_DEF).with_icon(preload("res://cards/icons/vampire_slash.svg"))

var card_def3_dmg3 : Card = Card.new(
	"恶犬看垄",
	"猛犬蹲守垄头，为作物提供 3 点强力守护，并扑咬最近害虫造成 $DQ 点伤害",
	3,
	Action.DEF_DMG_NEAR
).with_quantity(3).with_drain(3).with_cat(CAT_DEF).with_icon(preload("res://cards/icons/thorns.svg"))

# Rare tank cards

var card_def2_all : Card = Card.new(
	"温室地膜",
	"全田覆盖保温护根薄膜，为所有作物施加 2 点坚固免疫",
	4,
	Action.DEF_ALL
).with_quantity(2).with_cat(CAT_DEF).with_icon(preload("res://cards/icons/magic_shield.svg"))

var card_heal_attack_all : Card = Card.new(
	"万物回春",
	"春晖普照生机盎然，令全场作物回复 2 点生命，同时震慑全场害虫造成 $DQ 点伤害",
	4,
	Action.HEAL_ALL_DMG
).with_drain(2).with_quantity(1).with_cat(CAT_DEF).with_icon(preload("res://cards/icons/vampire_blast.svg"))

# Low attack-focus cards

var card_dmg2 : Card = Card.new(
	"重铁拍扁",
	"抡起重镐猛力砸落，对单个害虫造成 $DQ 点强力伤害",
	1,
	Action.ATTACK
).with_quantity(2).with_cat(CAT_ATK).with_icon(preload("res://cards/icons/kapow.svg"))

var card_add1_expensive: Card = Card.new(
	"草药熏烟",
	"点燃驱虫艾草熏蒸田头，令你下一次除虫攻击伤害增加 1 点",
	1,
	Action.ADD_DAMAGE
).with_quantity(1).with_cat(CAT_ATK).with_icon(preload("res://cards/icons/power_fungi.svg"))

var card_sacrif1_1enem : Card = Card.new(
	"掐枝保穗",
	"忍痛掐去病叶消耗 1 点作物生命，聚力重创残血害虫造成 $DQ 点伤害",
	1,
	Action.SACRIF
).with_quantity(4).with_drain(1).with_mult(1).with_cat(CAT_ATK).with_icon(preload("res://cards/icons/blood_dagger.svg"))

# Medium attack cards

var card_add2 : Card = Card.new(
	"老农巧劲",
	"积年农事练就的发力巧劲，令你下一次除虫攻击伤害增加 2 点",
	2,
	Action.ADD_DAMAGE
).with_quantity(2).with_cat(CAT_ATK).with_icon(preload("res://cards/icons/technique.svg"))

var card_sacrif2_2enem : Card = Card.new(
	"断臂截疫",
	"斩断染疫茎蔓消耗 2 点作物生命，回击最虚弱的 2 只害虫各造成 $DQ 点伤害",
	4,
	Action.SACRIF
).with_quantity(4).with_drain(2).with_mult(2).with_cat(CAT_ATK).with_icon(preload("res://cards/icons/blood_blade.svg"))

var card_free_atk : Card = Card.new(
	"巧劲弹指",
	"眼疾手快，信手弹出泥丸，对单个害虫造成 $DQ 点伤害",
	0,
	Action.ATTACK
).with_quantity(1).with_cat(CAT_ATK).with_icon(preload("res://cards/icons/zing.svg"))

# Rare attack cards

var card_add1_cheap : Card = Card.new(
	"一鼓作气",
	"心随意动顺势而为，零消耗使你下一次除虫攻击伤害增加 1 点",
	0,
	Action.ADD_DAMAGE
).with_quantity(1).with_cat(CAT_ATK).with_icon(preload("res://cards/icons/power_crystal.svg"))

var card_sacrifice : Card = Card.new(
	"焚禾焦土",
	"引火断腕牺牲整株作物，烈焰横扫全田，对所有害虫造成 $DQ 点狂烈伤害",
	5,
	Action.SACRIF
).with_quantity(4).with_drain(0).with_mult(-1).with_cat(CAT_ATK).with_icon(preload("res://cards/icons/sacrifice.svg"))

# GENERAL RARE CARDS

var card_win_plant : Card = Card.new(
	"百年月华·金稻",
	"世代耕夫求之不得的天赐神种。若能呵护长成，便获丰稔传世之功",
	3,
	Action.PLANT
).with_cat(CAT_SEED).with_icon(preload("res://cards/icons/mystical_seeds.svg"))

var card_energy : Card = Card.new(
	"粗茶提神",
	"饮一碗陈年大碗浓茶提振气力，恢复 1 点行动体力",
	0,
	Action.PLUS_ENERGY
).with_icon(preload("res://cards/icons/free_energy.svg"))

# GENERAL MED CARDS

var card_cards : Card = Card.new(
	"翻看黄历",
	"查阅时令农谚筹谋先机，立即抽取 3 张农事手牌",
	1,
	Action.DRAW_3
).with_icon(preload("res://cards/icons/cool_drawing.svg"))

var Game = preload("res://Game.tscn")
var MainMenu = preload("res://MainMenu.tscn")
var Intro = preload("res://Intro.tscn")
var HandCard = preload("res://cards/HandCard.tscn")
var CardBase = preload("res://cards/CardBase.tscn")

var Plant1 = preload("res://plants/plant1/Plant1.tscn")
var Plant2 = preload("res://plants/plant2/Plant2.tscn")
var Plant3 = preload("res://plants/plant3/Plant3.tscn")
var PlantWin = preload("res://plants/winplant/WinPlant.tscn")

var Bug = preload("res://bugs/Bug.tscn")

var hand = null

var current_picked_up_card = null
var cursor: Cursor = null

var tilemap = null

func set_current_card(card: Node):
	if current_picked_up_card != null:
		current_picked_up_card.release()
		current_picked_up_card = null
	current_picked_up_card = card
	
func release_current_card(card: Node):
	if current_picked_up_card == card:
		current_picked_up_card = null

func get_card_base(card: Card):
	var b = CardBase.instance()
	b.get_node("Title").text = card.title
	b.get_node("Desc").text = card.desc
	b.get_node("Cost").text = String(card.cost)
	b.associated_card = card
	return b
	
func spawn_bug_intcoord(x: int, y: int):
	var b = Bug.instance()
	b.tier = 2
	b.health = 3

	tilemap.add_child(b)
	b.position = Vector2(x, y) * 128
	
func spawn_bug_lcoord(pos):
	var b = Bug.instance()
	b.tier = 2
	b.health = 3
	tilemap.add_child(b)
	
	b.position = pos
	
	return b
	
func get_object_at_map_lcoord(coord: Vector2):
	for obj in get_tree().get_nodes_in_group("Object"):
		var p = obj.position
		if (p - coord).length_squared() < 16:
			return obj
	return null
	
func get_plant_at_map_lcoord(coord: Vector2):
	for obj in get_tree().get_nodes_in_group("Plant"):
		var p = obj.position
		if (p - coord).length_squared() < 16:
			return obj
	return null
	
func get_enemy_at_map_lcoord(coord: Vector2):
	for obj in get_tree().get_nodes_in_group("Enemy"):
		var p = obj.position
		if (p - coord).length_squared() < 16:
			return obj
	return null
	
func get_random_enemy():
	var nodes = get_tree().get_nodes_in_group("Enemy")
	
	if nodes.empty():
		return null
	
	return nodes[randi() % nodes.size()]
	
func get_nearest_enemy(position):
	var node = null
	var dist = 0
	
	for enemy in get_tree().get_nodes_in_group("Enemy"):
		var to_enem = (enemy.position - position).length()
		if node == null:
			node = enemy
			dist = to_enem
		elif to_enem < dist:
			node = enemy
			dist = to_enem
			
	return node
	
	
func get_lowest_health_enemy(exclude = null):
	var node = null
	var dist = 0
	
	for enemy in get_tree().get_nodes_in_group("Enemy"):
		if enemy == exclude:
			continue
		
		if node == null:
			node = enemy
			dist = enemy.health
		elif enemy.health < dist:
			node = enemy
			dist = enemy.health
			
	return node


func add_card_to_hand(card: Card):
	var h = HandCard.instance()
	var b = get_card_base(card)
	
	b.dynamic_display = true
	
	h.associated_card = card
	
	h.add_child(b)
	
	# 发牌错峰：每张比前一张晚 0.05 秒飞入
	h.spawn_delay = float(hand.get_child_count()) * 0.05
	
	hand.add_child(h)

func _ready():
	# 用编辑器版引擎打包时窗口标题会带 "(DEBUG)"，这里统一覆盖成正式标题
	OS.set_window_title("田间风云 · Field Chronicles")
	# 窗口大小交给项目设置（1080x800）+ 项目里的 stretch 设置；
	# 位置显式固定在左上角：高分屏下引擎默认居中的算法会把窗口推出屏幕底部。
	OS.window_position = Vector2(30, 30)
	
	reset_all_state()

	
var current_turns = null
var current_obj = null
	
func turn_processor():
	for plant in get_tree().get_nodes_in_group("Plant"):
		current_obj = plant
		plant.take_turn()
		yield()
		
	for enemy in get_tree().get_nodes_in_group("Enemy"):
		current_obj = enemy
		enemy.take_turn()
		yield()
		
	current_obj = null
	return null
	
enum SpawnOpt {
	Bug2,
	Bug3,
	Bug5,
	Bug9
}
# 虫潮的节奏与波次池由 DifficultyManager 按品级配置，这里只负责抽取与落位。
# 连续多波没有出过 5 血以上的虫时，下一波强制补一只，避免长时间“没虫”。
var waves_since_strong = 0

func is_bug_wave_turn():
	if tutorial or game_settled:
		return false
	if current_turn < DifficultyManager.get_bug_first_turn():
		return false
	if current_turn >= max_turns:
		return false
	return current_turn % DifficultyManager.get_bug_interval() == 0

func is_bug_king_wave(turn):
	return turn in DifficultyManager.get_bug_king_turns()

# 池条目为 [虫血, 权重]，虫血 2/3/5/9 对应四档立绘。
func roll_bug_hp(pool):
	var total = 0
	for entry in pool:
		total += entry[1]
	var r = randi() % total
	for entry in pool:
		r -= entry[1]
		if r < 0:
			return entry[0]
	return pool[0][0]

func bug_opt_for_hp(hp):
	if hp == 2:
		return SpawnOpt.Bug2
	if hp == 3:
		return SpawnOpt.Bug3
	if hp == 5:
		return SpawnOpt.Bug5
	return SpawnOpt.Bug9

# 在随机作物的附近找一格空地放虫，返回是否成功。
func spawn_bug_at_plant(item, plants):
	for attempt in range(0, 100):
		var p = plants[randi() % plants.size()]
		var x = (randi() % 5) - 2
		var y = (randi() % 5) - 2
		var pos = p.position + Vector2(x, y) * 128
		if get_object_at_map_lcoord(pos) != null:
			continue

		var bug = Bug.instance()
		bug.position = pos

		# 立绘跟血量走：2/3/5/9 分别对应四档外观
		if item == SpawnOpt.Bug2:
			bug.tier = 1
			bug.health = 2
		if item == SpawnOpt.Bug3:
			bug.tier = 2
			bug.health = 3
		if item == SpawnOpt.Bug5:
			bug.tier = 3
			bug.health = 5
		if item == SpawnOpt.Bug9:
			bug.tier = 4
			bug.health = 9

		tilemap.add_child(bug)
		return true
	return false
	
func spawn_enemies():
	# Enemies are spawned near plants
	var plants = get_tree().get_nodes_in_group("Plant")
	
	# Can't spawn if there are no plants, also wil cause div by zero
	if plants.size() == 0:
		return
	
	var count_enemys = get_tree().get_nodes_in_group("Enemy").size()
	var size = DifficultyManager.get_bug_wave_size(current_turn)
	var plan = [] # 虫血列表
	
	if is_bug_king_wave(current_turn):
		# 虫王携小虫压阵
		plan.append(9)
		for i in range(max(size - 1, 1)):
			plan.append(3)
	else:
		var pool = DifficultyManager.get_bug_wave_pool(current_turn)
		var max_kings = DifficultyManager.get_bug_max_kings()
		var kings = 0
		for i in range(size):
			var hp = roll_bug_hp(pool)
			# 单波随机虫王不超过配置上限，超出降为 5 血
			if hp == 9:
				if kings >= max_kings:
					hp = 5
				else:
					kings += 1
			plan.append(hp)
		# 保底：连续 3 波没出过 5 血以上的虫，本波强制一只
		if waves_since_strong >= 3:
			plan[0] = 5
	
	var strong_spawned = false
	for hp in plan:
		# Don't spawn more than 5 enemies at once
		if count_enemys >= 5:
			break
		if not spawn_bug_at_plant(bug_opt_for_hp(hp), plants):
			continue
		count_enemys += 1
		if hp >= 5:
			strong_spawned = true
	
	waves_since_strong = 0 if strong_spawned else waves_since_strong + 1
	
func end_turn():
	# Must be in PLAYING_CARDS or WAITING_FOR_TUTORIAL state
	if turn_state != TurnState.PLAYING_CARDS:
		return
	
	SFX.end_turn.play_sfx()
	
	hand.clear_hand()
	current_picked_up_card = null
	
	# 每 3 候固定来一波虫，波次强度随候推进
	if is_bug_wave_turn():
		spawn_enemies()
	
	turn_state = TurnState.UPDATING
	current_turns = turn_processor()
	if current_turns == null:
		deal_new_hand()

# Used for plant markers!
var global_sine_timer = 0

func _process(delta):
	if Input.is_action_just_pressed("fullscreen"):
		OS.window_fullscreen = !OS.window_fullscreen
	
	global_sine_timer += 0.4 * delta
	if global_sine_timer >= 1:
		global_sine_timer -= 1
		
var draw_pile = []
var discard_pile = []

var camera = null
	
func shuffle_cards():
	discard_pile.shuffle()
	draw_pile = discard_pile
	discard_pile = []
	
func draw_card():
	if not draw_pile.empty():
		return draw_pile.pop_front()
		
	if discard_pile.empty():
		return null
		
	shuffle_cards()
	return draw_pile.pop_front()
	
func draw_card_to_hand():
	var c = draw_card()
	if c == null:
		return
	add_card_to_hand(c)
	
var card_draw_count = 5
		
func deal_new_hand():
	TutorialSteps.mark_have_ended_turn()
	
	for plant in get_tree().get_nodes_in_group("Plant"):
		plant.set_defense(plant.defense - 1)
	
	if not tutorial and not game_settled:
		current_turn += 1
		SeasonManager.update_season_for_turn(current_turn)
		if current_turn > max_turns:
			game_settled = true
			turn_state = TurnState.UNDEFINED
			popup_tax_settlement(gold >= tax_amount, gold, tax_amount)
			return
	
	for i in range(0, card_draw_count):
		var c = draw_card()
		if c == null:
			break
		add_card_to_hand(c)
	
	turn_state = TurnState.PLAYING_CARDS
	
	energy = energy_max
	
	SFX.card_deal.play_sfx()
		
func _physics_process(delta):
	if current_turns != null:
		if not is_instance_valid(current_obj):
			current_turns = current_turns.resume()
			
			if current_turns == null:
				deal_new_hand()
		elif current_obj.turn_over():
			current_obj.finalize_turn()
			current_turns = current_turns.resume()
			
			if current_turns == null:
				deal_new_hand()
				

func get_discard_pos():
	var s = get_viewport().size
	var cam_zoom = camera.zoom
	return camera.global_position + s * 0.5 * cam_zoom + Vector2(0, 200) * cam_zoom
	
# Should this get reset?
var tutorial = true

var auto_water = false
	
func reset_all_state():
	tutorial = true # SHould this get reset?
	TutorialSteps.tutorial = null
	TutorialSteps.reset_all_state()
	
	CardCreation.reset_all_state()
	
	turn_state = TurnState.UNDEFINED
	waiting_for_card_selection = false

	card_selector_ui = null
	# 一品·神农绝境 有乡邻接济的起始存银
	gold = DifficultyManager.get_start_gold()
	current_turn = 1
	max_turns = DifficultyManager.get_max_turns()
	tax_amount = DifficultyManager.get_tax_amount()
	game_settled = false
	current_harvest_plant_level = 1
	SeasonManager.reset_season()
	
	energy_max = 3
	energy = energy_max
	
	hand = null

	current_picked_up_card = null
	cursor = null
	
	current_turns = null
	current_obj = null
	
	global_sine_timer = 0
	
	draw_pile = []
	discard_pile = []

	camera = null
	
	tilemap = null
	
	card_draw_count = 5 # Will be set by tutorial
	
	shop_open = false
	upper_panel_mouse = false
	tutorial_mouse = false
	new_cards_mouse = false
	end_turn_mouse = false
	
	auto_water = false
	
	waves_since_strong = 0

