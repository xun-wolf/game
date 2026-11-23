"""一品补偿方案扫描 v2：把"加能力 + 加压力"的组合也测进去。

思路：如果只加补偿（能量/起始金），一品会变简单但失去"绝境"味道；
可以考虑"给工具 + 加门槛"，比如 4 能量 + 旱情拉长/税更高。
"""

import pathlib
import random
import sys

sys.path.insert(0, r"D:\aigame\_tools")
import balance_sim as b

TIER5 = b.TIERS[4]


def patch_drought(first, last):
    def water_cost(turn, tier):
        if b.season_of(turn) != "summer":
            return 1
        if not tier["drought"]:
            return 1
        return 2 if (first <= turn <= last) else 1

    b.water_cost = water_cost
    b.Game.start_turn.__globals__["water_cost"] = water_cost
    b.Game.end_turn.__globals__["water_cost"] = water_cost


def run(n=400, start_gold=0, energy=None, tax=None, drought=None, seed=21):
    patch_drought(*(drought or (10, 12)))
    rng = random.Random(seed)
    tier = dict(TIER5)
    if tax is not None:
        tier["tax"] = tax
    old = b.BASE_ENERGY
    if energy is not None:
        b.BASE_ENERGY = energy
    passes = 0
    golds = []
    for _ in range(n):
        g = b.Game(tier, rng, 1.0)
        g.gold = start_gold
        gold = g.run()
        golds.append(gold)
        if gold >= tier["tax"]:
            passes += 1
    b.BASE_ENERGY = old
    golds.sort()
    return passes / n * 100, golds[n // 2], golds[int(n * 0.9)]


if __name__ == "__main__":
    variants = [
        ("现状", dict()),
        ("起始金 +4", dict(start_gold=4)),
        ("起始金 +6", dict(start_gold=6)),
        ("能量 +1", dict(energy=4)),
        ("能量 +1 且旱情 9-12", dict(energy=4, drought=(9, 12))),
        ("能量 +1 且税 34", dict(energy=4, tax=34)),
        ("能量 +1 且旱情 9-12 且税 32", dict(energy=4, drought=(9, 12), tax=32)),
        ("起始金 +6 且能量 +1 且税 36", dict(start_gold=6, energy=4, tax=36)),
    ]
    lines = []
    for name, kw in variants:
        p, med, p90 = run(**kw)
        lines.append("%-26s 通关率 %5.1f%%  中位 %3.0f  p90 %3.0f" % (name, p, med, p90))
    text = "\n".join(lines)
    print(text.encode("ascii", "replace").decode("ascii"))
    pathlib.Path(r"D:\aigame\_tools\tier5_sweep2.txt").write_text(text, encoding="utf-8")
