extends Node2D

# 端到端入口链路测试：主菜单 -> 点「开始游戏」-> Intro -> 点按钮 -> Game
# 与 autotest 分开跑：change_scene 会释放 current_scene，所以本节点先把自己摘出来。

const LOG_PATH = "D:/aigame/_shots/flowtest.txt"
const SHOT_DIR = "D:/aigame/_shots"

var logfile = null

func say(msg):
	print(msg)
	if logfile != null:
		logfile.store_line(str(msg))
		logfile.flush()

func _ready():
	logfile = File.new()
	logfile.open(LOG_PATH, File.WRITE)

	var watchdog = Timer.new()
	watchdog.wait_time = 60.0
	watchdog.one_shot = true
	watchdog.connect("timeout", self, "_on_watchdog")
	add_child(watchdog)
	watchdog.start()

	say("=== FLOWTEST START ===")
	# 把自己从 current_scene 上摘下来，否则场景切换会连测试脚本一起 free 掉
	get_tree().current_scene = null
	yield(get_tree(), "idle_frame")

	var menu = load("res://MainMenu.tscn").instance()
	get_tree().get_root().add_child(menu)
	get_tree().current_scene = menu
	for i in range(10):
		yield(get_tree(), "idle_frame")
	# 按真实操作：先选到一品，再点开始游戏
	DifficultyManager.set_tier(5)
	Flags.skip_tutorial = true
	yield(get_tree(), "idle_frame")
	say("[F] menu loaded: " + menu.name + " | tier=" + DifficultyManager.get_tier_title() + " start_gold=" + str(DifficultyManager.get_start_gold()))

	menu._on_PlayButton_pressed()
	for i in range(90):
		yield(get_tree(), "idle_frame")
	var cur = get_tree().current_scene
	say("[F] after Play -> scene: " + (cur.name if cur != null else "null") + " (Intro 场景根节点名就是 Control)")

	if cur == null:
		say("!!! 没能进入 Intro")
		finish()
		return

	say("[F] intro: btn=" + str(cur.get_node_or_null("Button")) + " has_method=" + str(cur.has_method("_on_Button_pressed")))
	cur._on_Button_pressed()
	var st = get_node("/root/SceneTransitions")
	say("[F] after click: next=" + str(st.next) + " playing=" + str(st.get_node("AnimationPlayer").is_playing()))
	for i in range(120):
		yield(get_tree(), "idle_frame")
	cur = get_tree().current_scene
	say("[F] after Intro -> scene: " + (cur.name if cur != null else "null"))
	if cur != null and cur.name == "Control":
		say("[F] still on intro, forcing faded()")
		st.faded()
		for i in range(40):
			yield(get_tree(), "idle_frame")
		cur = get_tree().current_scene
		say("[F] after forced faded -> scene: " + (cur.name if cur != null else "null"))
	say("[F] game state: turn=" + str(GS.current_turn) + " tax=" + str(GS.tax_amount) + " max_turns=" + str(GS.max_turns) + " tilemap=" + str(GS.tilemap != null))
	yield(get_tree().create_timer(6.0), "timeout")
	say("[F] 进场检查: tier=" + DifficultyManager.get_tier_title() + " gold=" + str(GS.gold) +
		" banner=" + str(SeasonManager.banner_ui != null and SeasonManager.banner_ui.visible))
	yield(shot("62_start_bonus_real"), "completed")

	yield(shot("60_game_entry"), "completed")

	# 金稻胜利 -> 点确认 -> 应回到主菜单
	var winplant = load("res://plants/winplant/WinPlant.tscn").instance()
	winplant.card_level = 4
	winplant.position = Vector2(0, 0)
	GS.tilemap.add_child(winplant)
	for i in range(6):
		yield(get_tree(), "idle_frame")
	winplant.popup_menu()
	for i in range(20):
		yield(get_tree(), "idle_frame")
	say("[F] win panel visible=" + str(GS.card_selector_ui.win_menu.visible))
	yield(shot("61_win_panel"), "completed")
	GS.card_selector_ui._on_ConfirmButton_pressed()
	for i in range(120):
		yield(get_tree(), "idle_frame")
	cur = get_tree().current_scene
	say("[F] after win confirm -> scene: " + (cur.name if cur != null else "null"))

	say("=== FLOWTEST DONE ===")
	finish()

func shot(name):
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	var img = get_viewport().get_texture().get_data()
	img.flip_y()
	var err = img.save_png(SHOT_DIR + "/" + name + ".png")
	say("[F] shot " + name + " err=" + str(err))

func finish():
	if logfile != null:
		logfile.close()
	get_tree().quit()

func _on_watchdog():
	say("!!! WATCHDOG TIMEOUT !!!")
	finish()
