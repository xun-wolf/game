extends Label

var lines = [
"你好，\n\n希望这卷落满灰尘的卷轴能顺利送到你手中。我是曾经照料这片土地的前任农夫，我由衷希望你能比我更好地利用它。"
,"不过，我猜你对耕作这门技艺还相当生疏。我打算把经营这座农场所需的基础知识教给你。"
,"我们开始吧。\n\n首先，要浏览农场，请在地面上的任意位置按住鼠标左键并拖动鼠标。"
,"接下来，在农场里做任何事都必须打出卡牌。卡牌能完成许多不同的工作……种植植物、为植物浇水，以及击退害虫。每张卡牌都需要消耗能量才能打出，能量显示在左下角的能量球中，也标注在每张卡牌的右上角。"
,"你的卡牌排列在屏幕底部。使用鼠标滚轮可以左右移动它们，以便查看当前看不到的卡牌。"
,"你应该把一张【初耕·小白菜】种在翻好的土地上。左键点击手牌中的种子卡牌，然后把它拖到上方的垄田中即可打出。\n\n这张卡牌会用绿色旋转圆圈标出可以耕种的位置。"
,"播种之后，你会注意到一个重要细节：每株作物都有生命值。务必悉心呵护，让它长到成熟！"
,"现在，你需要给作物补充水分。使用【晨露清沥】卡牌为你的作物浇水。"
,"注意，每株作物都有水分指示。每当农作回合结束，地力水分都会消耗 1 点。若作物缺水受旱，便会折损生命！\n\n遇上「百年大旱」这类年份，旱期每长一阶段要多耗 1 点水：三品在第 10-12 候，一品更长（第 10-14 候），浇水要算准。"
,"作物的最后一项属性是免疫值，你可以用【细密防虫网】卡牌以及其他手段施加防护。"
,"每 1 点免疫能抵御 1 点伤害。不过，作物的免疫值会在回合开始时消退 1 点。\n\n作物的各项属性上限均为 10 点。"
,"现在，打出可用卡牌后，点击右下角“结束回合”推移时令。你会看到水分滋润作物的生机……若田间有料想之外的害虫，它们也会在此刻偷袭作物！"
,"新的一候时令到来，你已摸入新的农事卡牌。"
,"农家农具的另一妙用是驱除侵害庄稼的田虫。使用你的【挥锄除虫】卡牌，狠狠给那只害虫一击！"
,"如今你已领悟农耕基础。但还有最重要的一条：勤苦耕耘究竟所图为何？"
,"每逢作物受得甘霖滋养，便会向成熟蜕变。待到瓜熟蒂落自动收获，你可选择【选优留种】将珍妙卡牌收入囊中。越是精心培育的良种，结出的卡牌便越是精妙。"
,"生机旺盛、少遭虫害的作物，收获时往往能开出更罕见的高阶卡牌。"
,"收获时你亦可选择【挑粮入市】换取存银。存银既可用于集市采购升级，也是年终缴纳官税的保障——若在第24候大寒结束时缴不足当年岁赋，农庄便会破产！"
,"最后，相传农家至宝【百年月华·金稻】只要能种成收获，便可一举奠定传世家业，直接赢得胜利！"
,"去吧，春华秋实，大展身手吧！"]

var current_line = 0
var turns_with_reqs = [5, 7, 9, 11, 13]

func contains_mouse(control: Control):
	var r = Rect2(Vector2.ZERO, control.rect_size)
	return r.has_point(control.get_local_mouse_position())

func end_tutorial():
	GS.tutorial = false
	GS.tutorial_mouse = false
	GS.card_draw_count = 5 # Back to normal card count
	GS.current_turn = 1 # Start from turn 1 after tutorial
	SeasonManager.update_season_for_turn(1)
	queue_free()

func _ready():
	TutorialSteps.tutorial = self
	
	update_tutorial()
	GS.turn_state = GS.TurnState.WAITING_FOR_TUTORIAL
	GS.card_draw_count = 2 # Only draw the Whack! card plus some filler

	if Flags.skip_tutorial:
		call_deferred("tutorial_skip")

	# DEBUGGING
	# call_deferred("tutorial_debug")

func tutorial_skip():
	tutorial_cards()
	GS.draw_card_to_hand()
	GS.draw_card_to_hand()
	end_tutorial()
	GS.turn_state = GS.TurnState.PLAYING_CARDS

func debug_all_cards():
	GS.add_card_to_hand(GS.card_basic_plant)	
	GS.add_card_to_hand(GS.card_medium_plant)	
	GS.add_card_to_hand(GS.card_high_plant)	
	GS.add_card_to_hand(GS.card_free_1x1_water)
	GS.add_card_to_hand(GS.card_buy_1x1_water)
	GS.add_card_to_hand(GS.card_small_attack)
	GS.add_card_to_hand(GS.card_small_defend)
	GS.add_card_to_hand(GS.card_drain1_dmg3)
	GS.add_card_to_hand(GS.card_water2_1x1)
	GS.add_card_to_hand(GS.card_water1_2x2)
	GS.add_card_to_hand(GS.card_water1_3x3)
	GS.add_card_to_hand(GS.card_water2_2x2)
	GS.add_card_to_hand(GS.card_drain3_rng5)
	GS.add_card_to_hand(GS.card_water5)
	GS.add_card_to_hand(GS.card_drain7_dmgall5)
	GS.add_card_to_hand(GS.card_drain3_dmgall1)
	GS.add_card_to_hand(GS.card_3def_1)
	GS.add_card_to_hand(GS.card_heal1_dmg1)
	GS.add_card_to_hand(GS.card_def2_dmg1)
	GS.add_card_to_hand(GS.card_heal2_dmg2)
	GS.add_card_to_hand(GS.card_def3_dmg3)
	GS.add_card_to_hand(GS.card_def2_all)
	GS.add_card_to_hand(GS.card_heal_attack_all)
	GS.add_card_to_hand(GS.card_dmg2)
	GS.add_card_to_hand(GS.card_add1_expensive)
	GS.add_card_to_hand(GS.card_sacrif1_1enem)
	GS.add_card_to_hand(GS.card_add2)
	GS.add_card_to_hand(GS.card_sacrif2_2enem)
	GS.add_card_to_hand(GS.card_free_atk)
	GS.add_card_to_hand(GS.card_add1_cheap)
	GS.add_card_to_hand(GS.card_sacrifice)
	GS.add_card_to_hand(GS.card_win_plant)
	GS.add_card_to_hand(GS.card_energy)
	GS.add_card_to_hand(GS.card_cards)

func tutorial_debug():
	tutorial_cards()
	end_tutorial()
	GS.turn_state = GS.TurnState.PLAYING_CARDS
	
	#debug_all_cards()
#
#	GS.add_card_to_hand(GS.card_small_attack)
	GS.add_card_to_hand(GS.card_water5)
	GS.add_card_to_hand(GS.card_water5)
	GS.add_card_to_hand(GS.card_3def_1)
	GS.add_card_to_hand(GS.card_3def_1)
	GS.add_card_to_hand(GS.card_3def_1)
	GS.add_card_to_hand(GS.card_3def_1)
	GS.add_card_to_hand(GS.card_3def_1)
	GS.add_card_to_hand(GS.card_win_plant)
	#GS.add_card_to_hand(GS.card_basic_plant)
#	GS.add_card_to_hand(GS.card_basic_plant)
#	GS.add_card_to_hand(GS.card_basic_plant)
#	GS.add_card_to_hand(GS.card_add1_expensive)
##	GS.add_card_to_hand(GS.card_def2_all)
#	GS.add_card_to_hand(GS.card_heal_attack_all)
#	GS.add_card_to_hand(GS.card_sacrif2_2enem)
#	GS.add_card_to_hand(GS.card_energy)
#	GS.add_card_to_hand(GS.card_cards)
##	GS.add_card_to_hand(GS.card_free_atk)
#	GS.add_card_to_hand(GS.card_sacrifice)
	GS.gold += 200
	GS.energy += 200
	
	for enem in get_tree().get_nodes_in_group("Enemy"):
		enem.spawn_now()


func tutorial_cards():
	GS.add_card_to_hand(GS.card_basic_plant)
	#GS.add_card_to_hand(GS.card_basic_plant)
	GS.add_card_to_hand(GS.card_free_1x1_water)
	GS.add_card_to_hand(GS.card_small_defend)
	
	GS.draw_pile.push_back(GS.card_small_attack)
	#GS.draw_pile.push_back(GS.card_medium_plant)
	
	GS.draw_pile.push_back(GS.card_medium_plant)
	# 早期水牌密度太低（8 张里只有 2 张水牌，约 1.25 水/回合，刚够养 1 株），
	# 补一张「水桶重灌」（1 费 +2 水），让开局能稳定养住 1~2 株作物。
	GS.draw_pile.push_back(GS.card_water2_1x1)
	
	GS.discard_pile.push_back(GS.card_buy_1x1_water)
	# 第二张「水桶重灌」：水牌从 3/8 提到 4/9，抽 5 张时水量更稳
	GS.discard_pile.push_back(GS.card_water2_1x1)
	#GS.discard_pile.push_back(GS.card_buy_1x1_water)
	
	GS.discard_pile.push_back(GS.card_small_attack)
	#GS.discard_pile.push_back(GS.card_small_attack)
	#GS.discard_pile.push_back(GS.card_small_defend)

func update_tutorial():
	if current_line >= lines.size():
		end_tutorial()
		return
	
	text = lines[current_line]
	
	TutorialSteps.need_end_turn_button = (current_line == 11)
	
	$NextButton.visible = not (current_line in turns_with_reqs)
	
	if current_line == 4:
		tutorial_cards()
		GS.turn_state = GS.TurnState.PLAYING_CARDS
		
	if current_line == 13:
		var plants = get_tree().get_nodes_in_group("Plant")
		var lcoord = Vector2.ZERO
		
		if not plants.empty():
			var plant = plants[0]
			lcoord = plant.position + Vector2(128 * 2, 0)
		
		GS.spawn_bug_lcoord(lcoord).spawn_now()
	
func step_tutorial():
	current_line += 1
	update_tutorial()
	
func _process(delta):
	if not GS.tutorial:
		GS.tutorial_mouse = false
		return
		
	GS.tutorial_mouse = contains_mouse(self) or contains_mouse($NextButton)
	
	if TutorialSteps.marked_step >= current_line:
		$NextButton.visible = true

func _on_NextButton_pressed():
	step_tutorial()
