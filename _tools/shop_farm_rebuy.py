"""农田商品改成可以买两次：8 金扩一片，16 金再扩一片（对应 tilemap.up1 / up2）。"""

import pathlib

p = pathlib.Path(r"D:\aigame\GameIame\shop\Shop.tscn")
t = p.read_text(encoding="utf-8")

old = '''description = "购买更多农田来种植植物。"
cost = 8
is_energy = false'''

new = '''description = "购买更多农田来种植植物。可以买两次：第二次再扩一片。"
cost = 8
rebuy_cost = 16
is_energy = false'''

assert t.count(old) == 1, t.count(old)
p.write_text(t.replace(old, new, 1), encoding="utf-8")
print("farm item now rebuyable")
