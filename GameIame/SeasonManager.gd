extends Node

enum Season {
	SPRING = 0,
	SUMMER = 1,
	AUTUMN = 2,
	WINTER = 3
}

const SEASON_NAMES = ["春", "夏", "秋", "冬"]
const SEASON_DIR_NAMES = ["spring", "summer", "autumn", "winter"]
const SEASON_TITLES = ["春耕", "夏耘", "秋收", "冬藏"]

const SOLAR_TERMS = {
	1: "立春",
	2: "雨水",
	3: "惊蛰",
	4: "春分",
	5: "清明",
	6: "谷雨",
	7: "立夏",
	8: "小满",
	9: "芒种",
	10: "夏至",
	11: "小暑",
	12: "大暑",
	13: "立秋",
	14: "处暑",
	15: "白露",
	16: "秋分",
	17: "寒露",
	18: "霜降",
	19: "立冬",
	20: "小雪",
	21: "大雪",
	22: "冬至",
	23: "小寒",
	24: "大寒"
}

const SEASON_CHANGE_BANNERS = {
	Season.SPRING: "【立春 · 农事初兴】春回大地，草木萌发。好雨知时节，当春乃发生！",
	Season.SUMMER: "【立夏 · 万物繁盛】时序入夏，草木成荫。日光热烈，需勤加浇灌！",
	Season.AUTUMN: "【立秋 · 金风送爽】金风拂面，硕果累累。正是挑粮变现之良机！",
	Season.WINTER: "【立冬 · 岁暮天寒】严冬已至，寒霜覆田。岁末官税结算在即，备足存银！"
}

const SEASON_MODULATE = {
	Season.SPRING: Color(1.0, 1.0, 1.0, 1.0),
	Season.SUMMER: Color(1.03, 1.02, 0.94, 1.0),
	Season.AUTUMN: Color(1.05, 0.96, 0.88, 1.0),
	Season.WINTER: Color(0.92, 0.96, 1.05, 1.0)
}

const TILE_FILES = {
	1: "dirt_pixel.png",
	2: "grass_pixel.png",
	3: "plant_spot.png",
	4: "dirt_pixel_2.png",
	5: "dirt_pixel_3.png",
	6: "dirt_pixel_4.png",
	7: "farmland_1.png",
	8: "farmland_2.png",
	9: "farmland_3.png",
	10: "farmland_4.png",
}

const DECOR_FILENAMES = [
	"clod.png", "crystal.png", "fern.png", "fern_small.png",
	"flower_pink.png", "flower_pink_cluster.png", "flower_yellow.png",
	"grass_tall.png", "mushroom.png", "pebble.png", "stone.png",
	"stump.png", "tree_big.png", "tree_pine.png", "tree_small.png",
	"tuft_a.png", "tuft_b.png", "tuft_c.png", "tuft_d.png",
	"tuft_e.png", "tuft_f.png", "twig.png"
]

var current_season = Season.SPRING
var last_announced_season = -1

# --- 旱季耗水规则 ---
# 基础：每推进一个生长阶段消耗 1 点水。
# 只有三品·百年大旱 / 一品·神农绝境 会遇旱，且只在大暑前后（第 10-12 候）缺水，
# 每阶段 2 点水；其余档位、其余时候都是 1 点。
# （实玩反馈：整个夏天翻倍会把三品卡死在"永远浇不动"上。）
const WATER_COST_BASE = 1
const DROUGHT_FIRST_TURN = 10
const DROUGHT_LAST_TURN = 12

func is_drought_active() -> bool:
	return current_season == Season.SUMMER

func is_drought_turn() -> bool:
	return (GS.current_turn >= DROUGHT_FIRST_TURN and GS.current_turn <= DROUGHT_LAST_TURN)

func drought_bonus() -> int:
	if not is_drought_active():
		return 0
	if not DifficultyManager.is_summer_drought():
		return 0
	return 1 if is_drought_turn() else 0

func water_cost_per_stage() -> int:
	return WATER_COST_BASE + drought_bonus()

var tilemap: TileMap = null
var decor_node: Node2D = null
var world_modulate: CanvasModulate = null
var banner_ui: Control = null
var season_fx: Node = null

# Cached textures: season -> id -> Texture
var farm_textures = {}
# Cached textures: season -> filename -> Texture
var decor_textures = {}

# Prebuilt TileSets for each season
var season_tilesets = {}

func _ready():
	preload_all_textures()

func preload_all_textures():
	for s_idx in range(4):
		var s_name = SEASON_DIR_NAMES[s_idx]
		farm_textures[s_idx] = {}
		decor_textures[s_idx] = {}
		
		var farm_prefix = "res://farm/" if s_idx == 0 else "res://seasons/" + s_name + "/farm/"
		var decor_prefix = "res://decor/" if s_idx == 0 else "res://seasons/" + s_name + "/decor/"
		
		for tid in TILE_FILES:
			var fn = TILE_FILES[tid]
			farm_textures[s_idx][tid] = load(farm_prefix + fn)
			
		for fn in DECOR_FILENAMES:
			decor_textures[s_idx][fn] = load(decor_prefix + fn)

func bind_game_elements(tm: TileMap, decor: Node2D, modulate: CanvasModulate = null, banner: Control = null):
	tilemap = tm
	decor_node = decor
	world_modulate = modulate
	banner_ui = banner
	if is_instance_valid(tm):
		season_fx = tm.get_node_or_null("../CanvasLayer/SeasonFX")
	
	# Tag all decor sprites with their base filename
	if is_instance_valid(decor_node):
		for child in decor_node.get_children():
			if child is Sprite and child.texture != null:
				var fn = child.texture.resource_path.get_file()
				child.set_meta("decor_filename", fn)
	
	# Build season TileSets based on base TileSet
	if is_instance_valid(tilemap) and tilemap.tile_set != null:
		build_season_tilesets(tilemap.tile_set)
		
	# Apply current season
	apply_season(current_season, false)

func build_season_tilesets(base_ts: TileSet):
	season_tilesets.clear()
	for s_idx in range(4):
		var ts = base_ts.duplicate()
		for tid in TILE_FILES:
			if tid in farm_textures[s_idx]:
				ts.tile_set_texture(tid, farm_textures[s_idx][tid])
		season_tilesets[s_idx] = ts

func get_season_for_turn(turn: int) -> int:
	if turn <= 6:
		return Season.SPRING
	elif turn <= 12:
		return Season.SUMMER
	elif turn <= 18:
		return Season.AUTUMN
	else:
		return Season.WINTER

func get_season_title(season: int) -> String:
	if season >= 0 and season < SEASON_TITLES.size():
		return SEASON_TITLES[season]
	return "春耕"

func get_turn_term(turn: int) -> String:
	if turn in SOLAR_TERMS:
		return SOLAR_TERMS[turn]
	return "时节"

func update_season_for_turn(turn: int):
	var target_season = get_season_for_turn(turn)
	var is_new_season = (target_season != current_season) or (target_season != last_announced_season)
	
	current_season = target_season
	apply_season(current_season, is_new_season)
	if is_new_season:
		last_announced_season = current_season

func reset_season():
	current_season = Season.SPRING
	last_announced_season = -1
	apply_season(Season.SPRING, false)

func apply_season(season: int, trigger_banner: bool = false):
	current_season = season
	
	# 1. Swap TileSet
	if is_instance_valid(tilemap):
		if season in season_tilesets:
			tilemap.tile_set = season_tilesets[season]
		elif tilemap.tile_set != null:
			# Fallback: direct texture replacement
			for tid in TILE_FILES:
				if tid in farm_textures[season]:
					tilemap.tile_set.tile_set_texture(tid, farm_textures[season][tid])
			tilemap.update()
			
	# 2. Swap Decor Sprites
	if is_instance_valid(decor_node):
		for child in decor_node.get_children():
			if child.has_meta("decor_filename"):
				var fn = child.get_meta("decor_filename")
				if fn in decor_textures[season]:
					child.texture = decor_textures[season][fn]
					
	# 3. Atmospheric lighting
	if is_instance_valid(world_modulate):
		world_modulate.color = SEASON_MODULATE[season]

	# 4. Weather particles (春花瓣 / 夏浮尘 / 秋落叶 / 冬飘雪)
	if is_instance_valid(season_fx) and season_fx.has_method("set_season"):
		season_fx.set_season(season)

	# 5. Trigger Banner Announcement
	if trigger_banner:
		show_banner(SEASON_CHANGE_BANNERS[season])

func show_banner(text: String):
	if is_instance_valid(banner_ui) and banner_ui.has_method("display_banner"):
		banner_ui.display_banner(text)

# 弹窗打开时把横幅收掉，避免半透明面板后面透出文字
func hide_banner():
	if is_instance_valid(banner_ui) and banner_ui.has_method("hide_now"):
		banner_ui.hide_now()

# 虫王横幅去重：同一时间只播一次，避免一波多只时刷屏
var king_banner_until = 0.0

func show_king_banner(text: String):
	var now = OS.get_ticks_msec() / 1000.0
	if now < king_banner_until:
		return
	king_banner_until = now + 8.0
	show_banner(text)

# 调试用：按 1-4 直接切季节。正式试玩/演示时保持 false，否则会把四季节奏打乱。
const DEBUG_SEASON_KEYS = false

func _unhandled_input(event):
	if not DEBUG_SEASON_KEYS:
		return
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		if event.scancode == KEY_1:
			apply_season(Season.SPRING, true)
		elif event.scancode == KEY_2:
			apply_season(Season.SUMMER, true)
		elif event.scancode == KEY_3:
			apply_season(Season.AUTUMN, true)
		elif event.scancode == KEY_4:
			apply_season(Season.WINTER, true)
