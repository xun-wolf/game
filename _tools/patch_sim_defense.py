"""给 balance_sim 补上防御牌、防御衰减和更合理的购买逻辑。"""

import pathlib
import re

p = pathlib.Path(r"D:\aigame\_tools\balance_sim.py")
t = p.read_text(encoding="utf-8")

# 1) 顶部补 pathlib
t = t.replace("import random\nimport statistics\nimport sys",
              "import pathlib\nimport random\nimport statistics\nimport sys")

# 2) 卡牌：加防御牌
t = t.replace('    ("巧劲弹指", 0, "attack", 1),\n]',
              '    ("巧劲弹指", 0, "attack", 1),\n    ("细密防虫网", 1, "defend", 1),\n    ("稻草扎人", 1, "defend", 3),\n]')

# 3) 初始牌组放回防护网
t = t.replace('STARTER = ["初耕·小白菜", "晨露清沥", "细密防虫网", "挥锄除虫",\n           "田禾·红番茄", "水瓢浅浇", "精选·紫葡萄", "挥锄除虫"]',
              'STARTER = ["初耕·小白菜", "晨露清沥", "细密防虫网", "挥锄除虫",\n           "田禾·红番茄", "水瓢浅浇", "精选·紫葡萄", "挥锄除虫"]')

# 4) 植株增加 defense 字段
t = t.replace('self.plants.append({"kind": kind, "water": 0,\n                                    "steps_left": PLANT[kind]["steps"], "health": 3})',
              'self.plants.append({"kind": kind, "water": 0, "defense": 0,\n                                    "steps_left": PLANT[kind]["steps"], "health": 3})')

# 5) play() 支持 defend
t = t.replace('''        elif kind == "attack":''',
              '''        elif kind == "defend":
            if self.plants:
                target = min(self.plants, key=lambda p: p["defense"])
                target["defense"] += val
        elif kind == "attack":''')

# 6) 虫咬：先扣防御
t = t.replace('''        for b in list(self.bugs):
            if self.plants:
                victim = self.plants[0]
                victim["health"] -= 1
                if victim["health"] <= 0:
                    self.deaths += 1
                    self.plants.remove(victim)''',
              '''        for b in list(self.bugs):
            if not self.plants:
                break
            victim = self.plants[0]
            if victim["defense"] > 0:
                victim["defense"] -= 1
            else:
                victim["health"] -= 1
                if victim["health"] <= 0:
                    self.deaths += 1
                    self.plants.remove(victim)''')

# 7) 防御每回合衰减 1（对应 deal_new_hand 里的 set_defense(defense-1)）
t = t.replace('''    def end_turn(self):
        cost = water_cost(self.turn, self.tier)''',
              '''    def end_turn(self):
        cost = water_cost(self.turn, self.tier)
        for p_ in self.plants:
            if p_["defense"] > 0:
                p_["defense"] -= 1''')

# 8) 购买逻辑放宽：留足一半税钱就买
t = t.replace('''            if self.gold - price >= max(0, reserve) and self.gold >= price + 6:''',
              '''            if self.gold - price >= self.tier["tax"] * 0.5 and self.gold >= price + 4:''')

p.write_text(t, encoding="utf-8")
print("patched defense + shop logic")
