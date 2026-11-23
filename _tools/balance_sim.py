"""《田间风云》经济模型 —— 自动对局测量器（200 局/档位）。

不是引擎内对局：它复刻游戏的真实数值与规则，用来快速回答
"这档税能不能交上""商店是不是太便宜"这类问题。

取自工程里的真实数据：
- 生长阶段与收获金：plants/Plant.gd + NewCardSelection.get_gold_for_level
  一级 3 帧（2 次生长）-> 3 金；二级 5 帧（4 次）-> 6 金；三级 8 帧（7 次）-> 15 金
- 耗水：SeasonManager.water_cost_per_stage（1 / 2 / 3）
- 牌组：Tutorial.tutorial_cards 的初始 8 张
- 能量 3/回合、手牌 5
- 岁赋：DifficultyManager.TIER_DATA
- 商店：shop/Shop.tscn 的 7/10/13/8/4/9

未建模（会把结果往上抬）：虫子的移动/寻路、防御牌、自动浇水、
商店的能量强化以外的间接收益、目标选择失误。

用法: python balance_sim.py [局数]
"""

import pathlib
import random
import statistics
import sys
from collections import Counter

# ---------------------------------------------------------------- 卡牌数据

# (名称, 费用, 类型, 数值)
#  type: plant1/2/3, water（数值=给单株加的水）, attack（数值=伤害）
CARDS = [
    ("初耕·小白菜", 1, "plant1", 0),
    ("田禾·红番茄", 2, "plant2", 0),
    ("精选·紫葡萄", 3, "plant3", 0),
    ("晨露清沥", 0, "water", 1),
    ("水瓢浅浇", 1, "water", 1),
    ("水桶重灌", 1, "water", 2),
    ("竹制喷壶", 3, "water", 2),
    ("引渠入垄", 3, "water", 3),
    ("龙骨水车", 4, "water", 4),
    ("天降甘霖", 3, "water", 5),
    ("挥锄除虫", 1, "attack", 1),
    ("重铁拍扁", 1, "attack", 2),
    ("巧劲弹指", 0, "attack", 1),
    ("细密防虫网", 1, "defend", 1),
    ("稻草扎人", 1, "defend", 3),
]

STARTER = ["初耕·小白菜", "晨露清沥", "细密防虫网", "挥锄除虫",
           "田禾·红番茄", "水瓢浅浇", "精选·紫葡萄", "挥锄除虫", "水桶重灌"]

# 生长阶段与收获金
PLANT = {
    "plant1": {"steps": 2, "gold": 3, "name": "小白菜"},
    "plant2": {"steps": 4, "gold": 6, "name": "番茄"},
    "plant3": {"steps": 7, "gold": 15, "name": "葡萄"},
}

TIERS = [
    {"rank": "九品", "tax": 18, "bug_start": 0, "drought": False},
    {"rank": "七品", "tax": 24, "bug_start": 0, "drought": False},
    {"rank": "五品", "tax": 24, "bug_start": 12, "drought": False},
    {"rank": "三品", "tax": 24, "bug_start": 12, "drought": True},
    {"rank": "一品", "tax": 30, "bug_start": 12, "drought": True},
]

SHOP = [("能量+1", 7), ("能量+1", 10), ("能量+1", 13), ("农田+1", 8), ("抽牌+1", 9)]
AUTO_WATER = ("自动浇水", 4)

MAX_TURNS = 24
BASE_ENERGY = 3
BASE_HAND = 5
BASE_PLOTS = 4


def season_of(turn):
    if turn <= 6:
        return "spring"
    if turn <= 12:
        return "summer"
    if turn <= 18:
        return "autumn"
    return "winter"


def water_cost(turn, tier):
    if season_of(turn) != "summer":
        return 1
    return 2 if (tier["drought"] and turn >= 10) else 1


class Game:
    def __init__(self, tier, rng, skill=1.0):
        self.tier = tier
        self.rng = rng
        self.skill = skill
        self.gold = 0
        self.energy_max = BASE_ENERGY
        self.hand_size = BASE_HAND
        self.plots_cap = BASE_PLOTS
        self.deck = list(STARTER)
        self.discard = []
        self.hand = []
        self.plants = []          # dict(kind, water, steps_left, health)
        self.bugs = []            # dict(health)
        self.turn = 1
        self.harvests = 0
        self.deaths = 0
        self.upgrades = []
        self.bug_wave_turns = []

    # ---- 牌堆 ----
    def draw(self, n):
        for _ in range(n):
            if not self.deck:
                if not self.discard:
                    return
                self.deck = self.discard
                self.discard = []
                self.rng.shuffle(self.deck)
            self.hand.append(self.deck.pop())

    def card_def(self, name):
        for c in CARDS:
            if c[0] == name:
                return c
        return None

    def play(self, name):
        c = self.card_def(name)
        if c is None:
            return False
        _, cost, kind, val = c
        if cost > self.energy:
            return False
        self.energy -= cost
        self.hand.remove(name)
        self.discard.append(name)
        if kind == "water":
            target = min(self.plants, key=lambda p: p["water"]) if self.plants else None
            if target:
                target["water"] = min(10, target["water"] + val)
        elif kind.startswith("plant"):
            if len(self.plants) < self.plots_cap:
                self.plants.append({"kind": kind, "water": 0, "defense": 0,
                                    "steps_left": PLANT[kind]["steps"], "health": 3})
        elif kind == "defend":
            if self.plants:
                target = min(self.plants, key=lambda p: p["defense"])
                target["defense"] += val
        elif kind == "attack":
            if self.bugs:
                bug = min(self.bugs, key=lambda b: b["health"])
                bug["health"] -= val
                if bug["health"] <= 0:
                    self.bugs.remove(bug)
        return True

    # ---- 回合 ----
    def start_turn(self):
        # skill 模拟操作水平：站位/选牌失误会浪费一部分行动力
        self.energy = self.energy_max * self.skill
        # 上一手剩下的牌进弃牌堆（对应 GS.clear_hand + discard）
        self.discard.extend(self.hand)
        self.hand = []
        self.draw(self.hand_size)

        cost = water_cost(self.turn, self.tier)
        # 0) 先保住已经在田里的作物：优先浇离收获最近的
        guard = 0
        while guard < 30:
            guard += 1
            thirsty = [p for p in self.plants if p["water"] < cost]
            if not thirsty:
                break
            thirsty.sort(key=lambda p: p["steps_left"])
            waters = [c for c in self.hand if self.card_def(c)[2] == "water"]
            waters.sort(key=lambda c: (self.card_def(c)[1] / max(1, self.card_def(c)[3]), self.card_def(c)[1]))
            played = False
            for w in waters:
                if self.card_def(w)[1] <= self.energy and self.play(w):
                    played = True
                    break
            if not played:
                break

        # 1) 有余力再扩田（慢慢来，别一次种满）
        cap = min(self.plots_cap, 1 + self.turn // 6)
        guard = 0
        while len(self.plants) < cap and guard < 10:
            guard += 1
            seeds = [c for c in self.hand if self.card_def(c)[2] in ("plant1", "plant2", "plant3")]
            # 早期只种快周转的低级作物；第 8 回合后才舍得占田种葡萄
            if self.turn < 8:
                seeds = [c for c in seeds if self.card_def(c)[2] != "plant3"]
            seeds.sort(key=lambda c: int(self.card_def(c)[2][-1]))
            planted = False
            for s in seeds:
                if self.card_def(s)[1] <= self.energy and self.play(s):
                    planted = True
                    break
            if not planted:
                break

        # 1.5) 有虫先给最接近收获的作物上防护
        if self.bugs and self.plants:
            guard = 0
            while guard < 5:
                guard += 1
                defs = [c for c in self.hand if self.card_def(c)[2] == 'defend']
                if not defs:
                    break
                if min(p_['defense'] for p_ in self.plants) >= 3:
                    break
                defs.sort(key=lambda c: -self.card_def(c)[3])
                done = False
                for d_ in defs:
                    if self.card_def(d_)[1] <= self.energy and self.play(d_):
                        done = True
                        break
                if not done:
                    break

        # 2) 有虫就打
        guard = 0
        while self.bugs and guard < 10:
            guard += 1
            atks = [c for c in self.hand if self.card_def(c)[2] == "attack"]
            atks.sort(key=lambda c: (self.card_def(c)[1], -self.card_def(c)[3]))
            hit = False
            for a in atks:
                if self.card_def(a)[1] <= self.energy and self.play(a):
                    hit = True
                    break
            if not hit:
                break

        # 3) 剩下的能量囤水
        guard = 0
        while self.plants and guard < 10:
            guard += 1
            waters = [c for c in self.hand if self.card_def(c)[2] == "water"]
            waters.sort(key=lambda c: (self.card_def(c)[1], -self.card_def(c)[3]))
            done = False
            for w in waters:
                if self.card_def(w)[1] <= self.energy and self.play(w):
                    done = True
                    break
            if not done:
                break

    def end_turn(self):
        cost = water_cost(self.turn, self.tier)
        for p_ in self.plants:
            if p_["defense"] > 0:
                p_["defense"] -= 1
        for p in list(self.plants):
            if p["water"] >= cost:
                p["water"] -= cost
                p["steps_left"] -= 1
                if p["steps_left"] <= 0:
                    info = PLANT[p["kind"]]
                    # 收获策略：税没攒够就变现，够了一半概率换成牌
                    if self.gold < self.tier["tax"] or self.rng.random() < 0.35:
                        self.gold += info["gold"]
                    else:
                        new_card = self.rng.choice(
                            [c[0] for c in CARDS if c[2] in ("water", "plant2", "attack")])
                        self.discard.append(new_card)
                    self.harvests += 1
                    self.plants.remove(p)
            else:
                # 缺水：掉血
                p["health"] -= 1
                if p["health"] <= 0:
                    self.deaths += 1
                    self.plants.remove(p)
        # 虫子啃最近的一株
        for b in list(self.bugs):
            if not self.plants:
                break
            victim = self.plants[0]
            if victim["defense"] > 0:
                victim["defense"] -= 1
            else:
                victim["health"] -= 1
                if victim["health"] <= 0:
                    self.deaths += 1
                    self.plants.remove(victim)

    def maybe_buy(self):
        reserve = self.tier["tax"] - self.gold
        # 只在"买完还能交税"时考虑
        if self.gold - self.tier["tax"] <= 0:
            return
        for name, price in SHOP:
            if name in self.upgrades:
                continue
            if self.gold - price >= self.tier["tax"] * 0.5 and self.gold >= price + 4:
                self.gold -= price
                self.upgrades.append(name)
                if name.startswith("能量"):
                    self.energy_max += 1
                elif name.startswith("农田"):
                    self.plots_cap += 1
                elif name.startswith("抽牌"):
                    self.hand_size += 1
                return

    def maybe_spawn(self):
        # 近似 GS.spawn_configs：第 4 回合起每 3 回合一波，血量随波数上涨，场上最多 5 只
        if self.turn < 4 or (self.turn - 4) % 3 != 0:
            return
        if len(self.bugs) >= 5:
            return
        wave = (self.turn - 4) // 3
        count = min(2, 1 + wave // 4)
        health = [2, 2, 3, 3, 5, 5, 9][min(wave, 6)]
        for _ in range(count):
            self.bugs.append({"health": health})
        self.bug_wave_turns.append(self.turn)

    def run(self):
        for t in range(1, MAX_TURNS + 1):
            self.turn = t
            self.maybe_spawn()
            self.start_turn()
            self.end_turn()
            self.maybe_buy()
        return self.gold


def simulate(n_games=200, seed=1, skills=(0.6, 0.8, 1.0)):
    rng = random.Random(seed)
    out = {}
    for skill in skills:
        rows = []
        for tier in TIERS:
            golds, passes, harvests, deaths, ups = [], 0, [], [], []
            for _ in range(n_games):
                g = Game(tier, rng, skill)
                gold = g.run()
                golds.append(gold)
                harvests.append(g.harvests)
                deaths.append(g.deaths)
                ups.append(len(g.upgrades))
                if gold >= tier["tax"]:
                    passes += 1
            rows.append({
                "rank": tier["rank"], "tax": tier["tax"],
                "pass": passes / n_games * 100,
                "median": statistics.median(golds),
                "p10": sorted(golds)[int(n_games * 0.1)],
                "p90": sorted(golds)[int(n_games * 0.9)],
                "harvests": statistics.mean(harvests),
                "deaths": statistics.mean(deaths),
                "upgrades": statistics.mean(ups),
            })
        out[skill] = rows
    return out


if __name__ == "__main__":
    n = int(sys.argv[1]) if len(sys.argv) > 1 else 200
    data = simulate(n)
    lines = []
    for skill, rows in data.items():
        lines.append("")
        lines.append("=== 操作水平 %.1f（行动力折算）===" % skill)
        lines.append("%-6s%4s%8s%8s%6s%6s%7s%7s" % (
            "档位", "税", "通关率", "中位金", "p10", "p90", "收获", "死亡"))
        for r in rows:
            lines.append("%-6s%4d%7.1f%%%8.0f%6.0f%6.0f%7.1f%7.1f" % (
                r["rank"], r["tax"], r["pass"], r["median"],
                r["p10"], r["p90"], r["harvests"], r["deaths"]))
    text = "\n".join(lines)
    print(text.encode("ascii", "replace").decode("ascii"))
    pathlib.Path(r"D:\aigame\_tools\sim_report.txt").write_text(text, encoding="utf-8")
