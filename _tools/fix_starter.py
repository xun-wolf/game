"""修复 balance_sim.py 里被 PowerShell 控制台编码搞坏的 STARTER 牌组行。"""

import pathlib

p = pathlib.Path(r"D:\aigame\_tools\balance_sim.py")
lines = p.read_text(encoding="utf-8").split("\n")

for i, l in enumerate(lines):
    if l.startswith("STARTER = ["):
        lines[i] = 'STARTER = ["初耕·小白菜", "晨露清沥", "细密防虫网", "挥锄除虫",'
        lines[i + 1] = '           "田禾·红番茄", "水瓢浅浇", "精选·紫葡萄", "挥锄除虫", "水桶重灌"]'
        break

p.write_text("\n".join(lines), encoding="utf-8")
print("starter fixed")
