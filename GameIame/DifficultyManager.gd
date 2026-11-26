extends Node

enum Tier {
	TIER_1 = 1,
	TIER_2 = 2,
	TIER_3 = 3,
	TIER_4 = 4,
	TIER_5 = 5
}

const TIER_DATA = {
	Tier.TIER_1: {
		"id": 1,
		"rank": "九品",
		"name": "丰年祥和",
		"short": "九品·丰年",
		"full_title": "【九品 · 丰年祥和】",
		"tax": 18,
		"max_turns": 24,
		"start_bug_wave": 0,
		"summer_drought": false,
		"desc": "岁赋 18 两 | 害虫温和，风调雨顺",
		"win_praise": "岁丰年稔，草木茂盛，深谙田园农道！"
	},
	Tier.TIER_2: {
		"id": 2,
		"rank": "七品",
		"name": "苛捐杂税",
		"short": "七品·苛赋",
		"full_title": "【七品 · 苛捐杂税】",
		"tax": 24,
		"max_turns": 24,
		"start_bug_wave": 0,
		"summer_drought": false,
		"desc": "岁赋 24 两 | 官吏苛征，一候一两银",
		"win_praise": "苛赋沉重，仍能精打细算、如数完税，功昭乡梓！"
	},
	Tier.TIER_3: {
		"id": 3,
		"rank": "五品",
		"name": "凶虫肆虐",
		"short": "五品·凶虫",
		"full_title": "【五品 · 凶虫肆虐】",
		"tax": 24,
		"max_turns": 24,
		"start_bug_wave": 12,
		"summer_drought": false,
		"desc": "岁赋 24 两 | 凶虫横行，开局即有双虫袭扰",
		"win_praise": "力斩群害，守土护稼，堪称田垄中流砥柱！"
	},
	Tier.TIER_4: {
		"id": 4,
		"rank": "三品",
		"name": "百年大旱",
		"short": "三品·大旱",
		"full_title": "【三品 · 百年大旱】",
		"tax": 24,
		"max_turns": 24,
		"start_bug_wave": 12,
		"summer_drought": true,
		"start_gold": 6,
		"desc": "岁赋 24 两 | 凶虫袭扰 + 大旱：大暑前后（第 10-12 候）每阶段 2 点水；乡邻接济，开局多 6 两",
		"win_praise": "抗旱排难，善构水利，挽救田庄于绝境！"
	},
	Tier.TIER_5: {
		"id": 5,
		"rank": "一品",
		"name": "神农绝境",
		"short": "一品·神农",
		"full_title": "【一品 · 神农绝境】",
		"tax": 30,
		"max_turns": 24,
		"start_bug_wave": 12,
		"summer_drought": true,
		"start_gold": 6,
		"desc": "岁赋 30 两 | 苛政 + 大旱：大暑前后每阶段 2 点水；乡邻接济，开局多 6 两",
		"win_praise": "绝境登神，光耀华夏，创万世不拔之基业！"
	}
}

var current_tier = Tier.TIER_1
var cleared_tiers = []

const SAVE_PATH = "user://difficulty_progress.json"

func _ready():
	load_progress()
	apply_to_game_state()

func cycle_tier(delta: int):
	var next_t = current_tier + delta
	if next_t < Tier.TIER_1:
		next_t = Tier.TIER_5
	elif next_t > Tier.TIER_5:
		next_t = Tier.TIER_1
	current_tier = next_t
	apply_to_game_state()

func set_tier(t: int):
	if t in TIER_DATA:
		current_tier = t
		apply_to_game_state()

func apply_to_game_state():
	Flags.hard_mode = (current_tier > Tier.TIER_1)
	GS.tax_amount = get_tax_amount()
	GS.max_turns = get_max_turns()

func get_tier_title(t: int = -1) -> String:
	var key = current_tier if t == -1 else t
	return TIER_DATA[key]["full_title"]

func get_tier_short(t: int = -1) -> String:
	var key = current_tier if t == -1 else t
	return TIER_DATA[key]["short"]

func get_tier_rank(t: int = -1) -> String:
	var key = current_tier if t == -1 else t
	return TIER_DATA[key]["rank"]

func get_tier_desc(t: int = -1) -> String:
	var key = current_tier if t == -1 else t
	return TIER_DATA[key]["desc"]

# 开局补偿：三品·百年大旱 / 一品·神农绝境 有乡邻接济的起始存银
# 这笔钱主要用来在开局购买能量强化，撑过虫害与大旱
func get_start_gold(t: int = -1) -> int:
	var key = current_tier if t == -1 else t
	return int(TIER_DATA[key].get("start_gold", 0))

func get_win_praise(t: int = -1) -> String:
	var key = current_tier if t == -1 else t
	return TIER_DATA[key]["win_praise"]

func get_tax_amount(t: int = -1) -> int:
	var key = current_tier if t == -1 else t
	return TIER_DATA[key]["tax"]

func get_max_turns(t: int = -1) -> int:
	var key = current_tier if t == -1 else t
	return TIER_DATA[key]["max_turns"]

func get_start_bug_wave(t: int = -1) -> int:
	var key = current_tier if t == -1 else t
	return TIER_DATA[key]["start_bug_wave"]

func is_summer_drought(t: int = -1) -> bool:
	var key = current_tier if t == -1 else t
	return TIER_DATA[key]["summer_drought"]

func is_tier_cleared(t: int) -> bool:
	return t in cleared_tiers

func mark_tier_cleared(t: int):
	if not (t in cleared_tiers):
		cleared_tiers.append(t)
		save_progress()

func save_progress():
	var file = File.new()
	if file.open(SAVE_PATH, File.WRITE) == OK:
		var data = {
			"cleared_tiers": cleared_tiers
		}
		file.store_string(to_json(data))
		file.close()

func load_progress():
	var path = SAVE_PATH
	# 工程改名后用户目录也变了，这里顺带把旧目录（Cardwork Cycle）的进度接过来
	if not File.new().file_exists(path):
		var legacy = OS.get_user_data_dir().get_base_dir() + "/Cardwork Cycle/difficulty_progress.json"
		var probe = File.new()
		if probe.file_exists(legacy):
			path = legacy

	var file = File.new()
	if file.file_exists(path) and file.open(path, File.READ) == OK:
		var txt = file.get_as_text()
		file.close()
		var res = parse_json(txt)
		if typeof(res) == TYPE_DICTIONARY and res.has("cleared_tiers"):
			cleared_tiers = res["cleared_tiers"]
		if path != SAVE_PATH:
			save_progress()
