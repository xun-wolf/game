"""ShopItem 支持"同一件强化买两次"：农田升级第二档（up2）借此获得出售入口。

第一次：up1（8 金），第二次：up2（16 金）。
"""

import pathlib

p = pathlib.Path(r"D:\aigame\GameIame\shop\ShopItem.gd")
t = p.read_text(encoding="utf-8")

new_script = '''extends TextureRect

export var description = ""
export var cost = 5

# 允许买第二次时，第二次的价格（0 表示只能买一次）
export var rebuy_cost = 0

var buys = 0
var bought = false

export var is_energy = true

export var up_num = 1

func max_buys():
	return 2 if rebuy_cost > 0 else 1

func current_cost():
	if buys > 0 and rebuy_cost > 0:
		return rebuy_cost
	return cost

func _ready():
	update_button()
	$Button.connect("pressed", self, "_on_buy")

func update_button():
	$Button.text = "购买（" + String(current_cost()) + " 金币）"

func _on_buy():
	if buys >= max_buys():
		return

	if GS.gold >= current_cost():
		GS.gold -= current_cost()
		buys += 1
		bought = (buys >= max_buys())

		if is_energy:
			GS.energy_max += 1
			GS.energy += 1
		else:
			if up_num == 1:
				# 农田第一档买完后再买一次就是第二片田
				if buys == 1:
					GS.tilemap.up1()
				else:
					GS.tilemap.up2()
			elif up_num == 2:
				GS.tilemap.up2()
			elif up_num == 3:
				GS.card_draw_count += 1
			elif up_num == 4:
				GS.auto_water = true

		update_button()

func _process(delta):
	if bought:
		$Button.hide()
	else:
		$Button.show()
		$Button.disabled = (GS.gold < current_cost())
'''

p.write_text(new_script, encoding="utf-8")
print("ShopItem rewritten with rebuy support")
