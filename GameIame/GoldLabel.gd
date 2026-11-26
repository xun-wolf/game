extends Label

func _process(delta):
	var s_title = SeasonManager.get_season_title(SeasonManager.current_season)
	var term = SeasonManager.get_turn_term(GS.current_turn)
	var season_idx = SeasonManager.get_season_for_turn(GS.current_turn)
	
	var next_season_turn = (season_idx + 1) * 6 + 1
	var turns_left = next_season_turn - GS.current_turn
	var countdown_str = ""
	if season_idx < SeasonManager.Season.WINTER:
		var next_name = SeasonManager.SEASON_NAMES[season_idx + 1]
		countdown_str = " (距入" + next_name + " " + String(turns_left) + " 候)"
	else:
		var tax_left = GS.max_turns - GS.current_turn
		if tax_left > 0:
			countdown_str = " (距完税 " + String(tax_left) + " 候)"
		else:
			countdown_str = " (岁末终候！)"
	
	var tier_tag = " [" + DifficultyManager.get_tier_short() + "]"
	var drought_alert = ""
	var water_cost = SeasonManager.water_cost_per_stage()
	if water_cost > 1:
		drought_alert = " ·大旱" + String(water_cost) + "水"
	
	text = "存银: " + String(GS.gold) + " 两  |  岁赋: " + String(GS.tax_amount) + " 两" + tier_tag + "\n" + s_title + " · " + term + drought_alert + countdown_str
