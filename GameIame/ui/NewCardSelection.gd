extends Control

var current_card = null

onready var win_menu = $WinMenu

var tips = [
"提示：别小看基础植物！它们生命值很高，可以吸收伤害，而且只需几个回合就能长成。"
,"提示：免疫能在任何情况下保护植物免受伤害！包括植物缺水的时候。"
,"提示：敌人会攻击离自己最近的植物，请据此制定策略！"
,"提示：不同等级的种子会产出不同的卡牌。稀有卡牌虽然强大，但有时也需要低阶卡牌的帮助。"
]

var tip_num = 0

func _ready():
	$ConfirmButton.disabled = true
	get_parent().hide()
	
	win_menu.hide()
	
	GS.card_selector_ui = self


#func find_card_under_mouse():
#	var space = get_world_2d().direct_space_state
#	var mouse = get_parent().get_local_mouse_position()
#
#	var collisions = space.intersect_point(mouse, 32, [], 0x7FFFFFFF, false, true)
#
#	var card = null
#
#	for collision in collisions:
#		var obj = collision["collider"]
#		if obj.is_in_group("SelectableCard"):
#			card = obj
#
#			# Always prefer the current card to any other card, to prevent
#			# oscillating behavior.
#			if card == current_card:
#				return card
#
#	return card

func popup():
	get_parent().show()
	# 弹窗盖上来时收掉季节/虫王横幅，避免从半透明面板后面透出文字
	if SeasonManager != null:
		SeasonManager.hide_banner()
	$AnimationPlayer.play("Popup")
	
	
func release_current_card():
	if current_card == null:
		return
		
	current_card.is_hovered = false
	current_card = null
	
func setup_card(node: SelectableCard, card):
	var b = GS.get_card_base(card)
	node.add_child(b)
	b.position.x = 400 / 4.0
	b.position.y = 560 / 4.0
	node.card_child = b
	node.associated_card = card

	
var current_plant_level = 1
var is_settlement = false

func get_gold_for_level(level: int) -> int:
	if level == 1:
		return 3
	elif level == 2:
		return 6
	elif level == 3:
		return 12
	return 3

func _show_selection_ui(on: bool):
	# 结算/胜利面板要盖住整个选卡界面，否则"选择…或…金币。"和金按钮会从底下透出来
	$Explanation.visible = on
	$Bonus.visible = on
	$GoldButton.visible = on
	$ConfirmButton.visible = on
	$Cards.visible = on

func setup_cards(cards: Array, plant_level = 1):
	is_settlement = false
	current_plant_level = plant_level
	deselect_all()
	var gold_val = get_gold_for_level(plant_level)

	_show_selection_ui(true)
	win_menu.visible = false
	$Explanation.text = "【选优留种】选一张卡牌加入牌组，\n或\n【挑粮入市】运粮变现换取 " + str(gold_val) + " 金币。"
	$GoldButton.text = "挑粮入市 (换 " + str(gold_val) + " 金币)"
	$Bonus.text = "（或）"
	
	setup_card($Cards/Card, cards[0])
	setup_card($Cards/Card2, cards[1])
	setup_card($Cards/Card3, cards[2])
	
	$TipPanel/Tip.text = tips[tip_num]
	tip_num = (tip_num + 1) % tips.size()
	$TipPanel.show()
	
	SFX.plant_jingle.play_usual()
	
func setup_win():
	is_settlement = true
	_show_selection_ui(false)
	win_menu.visible = true
	$TipPanel.hide()
	# 金稻是终极胜利，同样算通过本阶，记进榜上
	DifficultyManager.mark_tier_cleared(DifficultyManager.current_tier)
	$WinMenu/Label.text = "「神农显圣 · 丰稔传世」"
	$WinMenu/Label2.text = "历经千辛万苦，你竟然亲手培育出了失传百年的【百年月华·金稻】！\n\n金穗垂地，光华照耀四野，四方农家无不顶礼赞叹。\n你不仅无需再为区区赋税忧愁，更被奉为当世神农！\n\n恭喜你达成了终极传奇胜利！:)"
	$WinMenu/Label3.text = "本阶已记入榜上 · 感谢游玩！"
	$WinMenu/ConfirmButton2.text = "返回主菜单"
	SFX.win_jingle.play_usual()

func setup_tax_settlement(passed: bool, gold: int, tax: int):
	is_settlement = true
	_show_selection_ui(false)
	win_menu.visible = true
	$TipPanel.hide()
	
	var tier_name = DifficultyManager.get_tier_title()
	var tier_praise = DifficultyManager.get_win_praise()
	var tier_rank = DifficultyManager.get_tier_rank()
	
	if passed:
		DifficultyManager.mark_tier_cleared(DifficultyManager.current_tier)
		$WinMenu/Label.text = tier_name + " · 完税嘉奖"
		$WinMenu/Label2.text = "寒来暑往，二十四候周天已毕。\n\n" + tier_praise + "\n\n你如数缴纳了 " + str(tax) + " 两田赋税银（剩余存银: " + str(gold - tax) + " 两）。\n知县特赐‘" + tier_rank + "耕模’金匾，名扬四方！\n\n恭喜你突破本阶，圆满通关！"
		$WinMenu/Label3.text = "耕读传家，岁岁平安！"
		$WinMenu/ConfirmButton2.text = "再来一局"
		SFX.win_jingle.play_usual()
	else:
		$WinMenu/Label.text = tier_name + " · 欠赋收田"
		$WinMenu/Label2.text = "二十四候时令已尽，大寒腊月已至。\n\n在" + tier_name + "的严苛考验下，官差敲响农舍大门索取岁赋 " + str(tax) + " 两，而你手头仅余 " + str(gold) + " 两存银，无力完赋。\n官府查封了农田抵债，你只能背起行囊，叹息离去……\n\n古训：‘人误地一时，地误人一年。’"
		$WinMenu/Label3.text = "来年春暖，重整旗鼓！"
		$WinMenu/ConfirmButton2.text = "重整旗鼓"
		SFX.no_water.play_usual()

func contains_mouse(control: Control):
	var r = Rect2(Vector2.ZERO, control.rect_size)
	return r.has_point(control.get_local_mouse_position())
	
func _process(delta):
	GS.new_cards_mouse = contains_mouse(self)

#func _physics_process(delta):
#	var under_mouse = find_card_under_mouse()
#
#	if under_mouse != current_card:
#		release_current_card()
#		current_card = under_mouse
#
#		if is_instance_valid(current_card):
#			current_card.is_hovered = true

func deselect_others(selected_card):
	$GoldButton.pressed = false
	for card in $Cards.get_children():
		if card != selected_card:
			card.is_selected = false
			
	$ConfirmButton.disabled = false
	
func deselect_all():
	$GoldButton.pressed = false
	for card in $Cards.get_children():
		card.is_selected = false
		
	# Nothing is selected -> confirm button is greyed out.
	$ConfirmButton.disabled = true

func _on_GoldButton_pressed():
	for card in $Cards.get_children():
		card.is_selected = false
		
	# If the gold button is also not pressed, we can't confirm.
	$ConfirmButton.disabled = not $GoldButton.pressed

func _on_ConfirmButton_pressed():
	if is_settlement:
		is_settlement = false
		win_menu.hide()
		get_parent().hide()
		GS.waiting_for_card_selection = false
		SceneTransitions.change_scene_to(GS.MainMenu)
		return

	for card in $Cards.get_children():
		if card.is_selected:
			card.is_selected = false
			# Add new cards to discard pile
			GS.discard_pile.push_back(card.associated_card)
			if card.associated_card == GS.card_win_plant:
				CardCreation.has_win_card = true
				
			CardCreation.picked_cat(card.associated_card.cat)
			
	var took_gold = $GoldButton.pressed
	remove_card_children()
			
	if took_gold:
		$GoldButton.pressed = false
		var gold_val = get_gold_for_level(current_plant_level)
		GS.gold += gold_val
	
	GS.stats_on_harvest_choice(took_gold)
	
	# 同候还有其它成熟作物时切换到下一株，否则收起面板
	if not GS.resolve_selection():
		$AnimationPlayer.play("Popdown")
	
func remove_card_children():
	$Cards/Card.destroy_card_child()
	$Cards/Card2.destroy_card_child()
	$Cards/Card3.destroy_card_child()
	
	get_parent().hide()
	
	
	
