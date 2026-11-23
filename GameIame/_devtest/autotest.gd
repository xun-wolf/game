extends Node2D

# Temporary integration test harness (not part of the game).
# Run: Godot_v3.5.3 --path D:\aigame\GameIame res://_devtest/autotest.tscn

const SHOT_DIR = "D:/aigame/_shots"
const LOG_PATH = "D:/aigame/_shots/autotest.txt"

var logfile = null

func say(msg):
	print(msg)
	if logfile != null:
		logfile.store_line(str(msg))
		logfile.flush()

func _ready():
	randomize()
	var d = Directory.new()
	if not d.dir_exists(SHOT_DIR):
		d.make_dir(SHOT_DIR)
	logfile = File.new()
	logfile.open(LOG_PATH, File.WRITE)

	var watchdog = Timer.new()
	watchdog.wait_time = 90.0
	watchdog.one_shot = true
	watchdog.connect("timeout", self, "_on_watchdog")
	add_child(watchdog)
	watchdog.start()

	say("=== AUTOTEST START ===")
	yield(get_tree(), "idle_frame")

	check_autoloads()
	check_water_rule()
	yield(shot_menu(), "completed")
	yield(check_start_bonus_banner(), "completed")

	var game = load("res://Game.tscn").instance()
	add_child(game)
	for i in range(20):
		yield(get_tree(), "idle_frame")

	check_season_binding()
	yield(shot_shop(), "completed")
	yield(check_plant_water(), "completed")
	yield(run_seasons(), "completed")
	yield(shot_bugs(), "completed")
	yield(run_settlement(), "completed")
	yield(run_turn_loop(), "completed")
	yield(check_win_ui(), "completed")
	yield(check_starter_deck(), "completed")

	say("=== AUTOTEST DONE ===")
	logfile.close()
	get_tree().quit()

func _on_watchdog():
	say("!!! WATCHDOG TIMEOUT !!!")
	if logfile != null:
		logfile.close()
	get_tree().quit()

func check_autoloads():
	say("[T] autoloads: SM=" + str(SeasonManager) + " DM=" + str(DifficultyManager) + " GS=" + str(GS) + " Flags=" + str(Flags))
	say("[T] initial: tier=" + str(DifficultyManager.current_tier) + " tax=" + str(GS.tax_amount) + " max_turns=" + str(GS.max_turns) + " hard=" + str(Flags.hard_mode))
	for t in range(1, 6):
		DifficultyManager.set_tier(t)
		say("[T] tier " + str(t) + " | tax=" + str(GS.tax_amount) + " | turns=" + str(GS.max_turns) + " | bug_wave=" + str(DifficultyManager.get_start_bug_wave()) + " | severe_drought=" + str(DifficultyManager.is_summer_drought()) + " | hard=" + str(Flags.hard_mode))
	DifficultyManager.set_tier(1)
	DifficultyManager.set_tier(5)
	GS.reset_all_state()
	say("[T] 一品开局存银 = " + str(GS.gold) + "（期望 6）")
	DifficultyManager.set_tier(1)
	GS.reset_all_state()
	for turn in [1, 6, 7, 12, 13, 18, 19, 24, 25]:
		say("[T] turn " + str(turn) + " -> season " + str(SeasonManager.get_season_for_turn(turn)) + " (season_title) " + SeasonManager.get_season_title(SeasonManager.get_season_for_turn(turn)) + " term=" + SeasonManager.get_turn_term(turn))

func check_water_rule():
	var saved_turn = GS.current_turn
	for t in [1, 3, 4, 5]:
		DifficultyManager.set_tier(t)
		SeasonManager.apply_season(0, false)
		GS.current_turn = 8
		var spring_cost = SeasonManager.water_cost_per_stage()
		SeasonManager.apply_season(1, false)
		GS.current_turn = 8
		var summer_mid = SeasonManager.water_cost_per_stage()
		GS.current_turn = 11
		var summer_peak = SeasonManager.water_cost_per_stage()
		say("[T] tier " + str(t) + " 每阶段耗水: 其他季=" + str(spring_cost) +
			" 夏初(第8候)=" + str(summer_mid) + " 大暑(第11候)=" + str(summer_peak))
	DifficultyManager.set_tier(1)
	SeasonManager.apply_season(0, false)
	GS.current_turn = saved_turn

func check_start_bonus_banner():
	DifficultyManager.set_tier(5)
	GS.reset_all_state()
	var g = load("res://Game.tscn").instance()
	add_child(g)
	for i in range(30):
		yield(get_tree(), "idle_frame")
	var vis = false
	if SeasonManager.banner_ui != null:
		vis = SeasonManager.banner_ui.visible
	say("[T] 一品进场: gold=" + str(GS.gold) + " banner_visible=" + str(vis))
	yield(shot("45_start_bonus"), "completed")
	g.queue_free()
	for i in range(3):
		yield(get_tree(), "idle_frame")
	# 清掉指向已释放场景的引用，后面的主场景才会重新绑定
	SeasonManager.tilemap = null
	SeasonManager.decor_node = null
	SeasonManager.world_modulate = null
	SeasonManager.banner_ui = null
	SeasonManager.season_fx = null
	GS.tilemap = null
	GS.camera = null
	DifficultyManager.set_tier(1)
	GS.reset_all_state()

func check_season_binding():
	say("[T] tilemap bound=" + str(SeasonManager.tilemap != null) + " decor=" + str(SeasonManager.decor_node != null) + " modulate=" + str(SeasonManager.world_modulate != null) + " banner=" + str(SeasonManager.banner_ui != null))
	var decor_children = -1
	if SeasonManager.decor_node != null:
		decor_children = SeasonManager.decor_node.get_child_count()
	say("[T] season_tilesets=" + str(SeasonManager.season_tilesets.size()) + " decor_children=" + str(decor_children))
	say("[T] season_fx=" + str(SeasonManager.season_fx) + " emitters=" + str(SeasonManager.season_fx.emitters.size() if SeasonManager.season_fx else -1))
	if SeasonManager.tilemap != null and SeasonManager.tilemap.tile_set != null:
		var tex = SeasonManager.tilemap.tile_set.tile_get_texture(2)
		say("[T] current tileset tex(2)=" + (tex.resource_path if tex != null else "null"))
	var nulls = 0
	for s in range(4):
		for tid in SeasonManager.TILE_FILES:
			if SeasonManager.farm_textures[s][tid] == null:
				nulls += 1
				say("[T] NULL farm tex season " + str(s) + " tile " + str(tid) + " -> " + SeasonManager.TILE_FILES[tid])
		for fn in SeasonManager.DECOR_FILENAMES:
			if SeasonManager.decor_textures[s][fn] == null:
				nulls += 1
	say("[T] null textures=" + str(nulls))

func shot(name):
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	var img = get_viewport().get_texture().get_data()
	img.flip_y()
	var path = SHOT_DIR + "/" + name + ".png"
	var err = img.save_png(path)
	say("[T] shot " + path + " err=" + str(err))

func shot_bugs():
	SeasonManager.apply_season(0, false)
	# 把血量标记贴图导出，方便核对金色底托的尺寸关系
	var hm = load("res://plants/heart_marker.svg")
	if hm != null:
		hm.get_data().save_png("D:/aigame/_shots/heart_marker_dump.png")
	var scene = load("res://bugs/Bug.tscn")
	var made = []
	var max_shake = 0.0
	var hp = [2, 3, 5, 9]
	for i in range(1, 5):
		var b = scene.instance()
		b.tier = i
		b.health = hp[i - 1]
		b.position = Vector2(-330 + (i - 1) * 220, 40)
		GS.tilemap.add_child(b)
		b.spawn_now()
		made.append(b)
	for i in range(90):
		yield(get_tree(), "idle_frame")
		var off = GS.camera.offset.length() if is_instance_valid(GS.camera) else 0.0
		if off > max_shake:
			max_shake = off
	say("[T] king shake max offset=" + str(max_shake) + " sfx heavy=" + str(SFX.heavy_hit) + " king=" + str(SFX.king_spawn))
	var tiers = []
	for b in made:
		tiers.append(b.tier)
	say("[T] bugs spawned: " + str(made.size()) + " tiers " + str(tiers))
	yield(shot("50_bug_tiers"), "completed")
	for b in made:
		b.queue_free()
	yield(get_tree(), "idle_frame")

func check_win_ui():
	var scene = load("res://plants/winplant/WinPlant.tscn")
	var plant = scene.instance()
	plant.position = Vector2(0, 0)
	GS.tilemap.add_child(plant)
	plant.card_level = 4
	for i in range(5):
		yield(get_tree(), "idle_frame")
	plant.popup_menu()
	for i in range(70):
		yield(get_tree(), "idle_frame")
	var ui = GS.card_selector_ui
	say("[T] 金稻胜利面板 visible=" + str(ui.win_menu.visible) + " 标题=" + ui.get_node("WinMenu/Label").text)
	say("[T] 通关记录=" + str(DifficultyManager.cleared_tiers))
	yield(shot("70_win"), "completed")
	ui.win_menu.hide()
	ui.get_parent().hide()
	ui.is_settlement = false
	GS.waiting_for_card_selection = false
	plant.queue_free()
	for i in range(3):
		yield(get_tree(), "idle_frame")

func check_starter_deck():
	for c in GS.hand.get_children():
		GS.hand.remove_child(c)
		c.queue_free()
	GS.draw_pile = []
	GS.discard_pile = []
	var tut = get_node_or_null("Game/CanvasLayer/Tutorial")
	if tut == null or not tut.has_method("tutorial_cards"):
		say("[T] tutorial node not found")
		return
	tut.tutorial_cards()
	var hand_n = GS.hand.get_child_count()
	var total = hand_n + GS.draw_pile.size() + GS.discard_pile.size()
	say("[T] 初始牌组: 手牌 " + str(hand_n) + " + 抽牌堆 " + str(GS.draw_pile.size()) + " + 弃牌堆 " + str(GS.discard_pile.size()) + " = " + str(total))
	yield(get_tree(), "idle_frame")

func shot_menu():
	var menu = load("res://MainMenu.tscn").instance()
	# 必须挂到 viewport 根节点下，Control 的锚点才会按屏幕尺寸解析
	get_tree().get_root().add_child(menu)
	for i in range(25):
		yield(get_tree(), "idle_frame")
	say("[T] menu tier: " + DifficultyManager.get_tier_title())
	yield(shot("40_menu"), "completed")
	menu.queue_free()
	yield(get_tree(), "idle_frame")

func shot_shop():
	var shop = get_node_or_null("Game/CanvasLayer/Shop")
	if shop == null:
		say("[T] shop not found")
		return
	GS.gold = 20
	shop.visible = true
	for i in range(20):
		yield(get_tree(), "idle_frame")
	var prices = []
	for item in shop.get_node("Items").get_children():
		prices.append(str(item.cost))
	say("[T] shop costs: " + str(prices) + " total=" + str(prices.size()))

	# 农田商品二次购买：8 金扩一片，16 金再扩一片
	var farm = null
	for item in shop.get_node("Items").get_children():
		if not item.is_energy and item.up_num == 1:
			farm = item
	if farm != null:
		GS.gold = 40
		farm._on_buy()
		say("[T] farm 1st buy -> gold=" + str(GS.gold) + " next_cost=" + str(farm.current_cost()) + " bought=" + str(farm.bought))
		farm._on_buy()
		say("[T] farm 2nd buy -> gold=" + str(GS.gold) + " bought=" + str(farm.bought) + " button_visible=" + str(farm.get_node("Button").visible))
	yield(shot("30_shop"), "completed")
	shop.visible = false

func check_plant_water():
	var plant = load("res://plants/Plant.tscn").instance()
	plant.position = Vector2(300, 300)
	add_child(plant)
	yield(get_tree(), "idle_frame")

	SeasonManager.apply_season(1, false) # 夏
	plant.set_water(5)
	plant.water_plant()
	say("[T] 平年夏天浇一次: 5 -> " + str(plant.water) + "（期望 4）")

	SeasonManager.apply_season(0, false) # 春
	plant.set_water(5)
	plant.water_plant()
	say("[T] 春天浇一次: 5 -> " + str(plant.water) + "（期望 4）")

	plant.queue_free()
	yield(get_tree(), "idle_frame")

func run_seasons():
	for s in range(4):
		SeasonManager.apply_season(s, true)
		for i in range(50):
			yield(get_tree(), "idle_frame")
		var bvis = "n/a"
		if SeasonManager.banner_ui != null:
			bvis = str(SeasonManager.banner_ui.visible)
		var fx_on = []
		if SeasonManager.season_fx != null:
			for k in SeasonManager.season_fx.emitters:
				if SeasonManager.season_fx.emitters[k].emitting:
					fx_on.append(k)
		say("[T] season " + str(s) + " applied. banner_visible=" + bvis + " emitting=" + str(fx_on) + " modulate=" + str(SeasonManager.world_modulate.color if SeasonManager.world_modulate != null else "n/a"))
		yield(shot("0" + str(s) + "_" + SeasonManager.SEASON_DIR_NAMES[s]), "completed")

func run_settlement():
	GS.gold = 40
	GS.popup_tax_settlement(true, 40, 18)
	for i in range(45):
		yield(get_tree(), "idle_frame")
	var vis = "no-ui"
	if GS.card_selector_ui != null:
		vis = str(GS.card_selector_ui.win_menu.visible)
	say("[T] settlement(pass) visible=" + vis + " cleared=" + str(DifficultyManager.cleared_tiers))
	yield(shot("10_tax_pass"), "completed")

	GS.popup_tax_settlement(false, 5, 18)
	for i in range(45):
		yield(get_tree(), "idle_frame")
	var vis2 = "no-ui"
	if GS.card_selector_ui != null:
		vis2 = str(GS.card_selector_ui.win_menu.visible)
	say("[T] settlement(fail) visible=" + vis2)
	yield(shot("11_tax_fail"), "completed")

	DifficultyManager.cleared_tiers = []

func run_turn_loop():
	say("[T] --- turn loop ---")
	SeasonManager.reset_season()
	GS.tutorial = false
	GS.current_turn = 1
	GS.max_turns = 24
	GS.tax_amount = 18
	GS.game_settled = false
	GS.gold = 20
	var last_season = -1
	for i in range(24):
		GS.deal_new_hand()
		yield(get_tree(), "idle_frame")
		say("[T]   iter " + str(i) + " turn=" + str(GS.current_turn) + " season=" + str(SeasonManager.current_season))
		if SeasonManager.current_season != last_season:
			last_season = SeasonManager.current_season
			say("[T] turn " + str(GS.current_turn) + " season=" + SeasonManager.SEASON_DIR_NAMES[last_season] + " settled=" + str(GS.game_settled) + " state=" + str(GS.turn_state))
			yield(shot("20_turn_" + str(GS.current_turn) + "_" + SeasonManager.SEASON_DIR_NAMES[last_season]), "completed")
	say("[T] after 24 turns: turn=" + str(GS.current_turn) + " settled=" + str(GS.game_settled) + " gold=" + str(GS.gold))
	GS.deal_new_hand()
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	var win = "no-ui"
	if GS.card_selector_ui != null:
		win = str(GS.card_selector_ui.win_menu.visible)
	say("[T] final: turn=" + str(GS.current_turn) + " settled=" + str(GS.game_settled) + " win_menu=" + win)
	yield(shot("21_final_settlement"), "completed")
