"""一品补偿方案扫描（只跑模型，不改游戏代码）。

目标：把模型里一品的通关率从 1.5% 拉到 5~15%（按"真实≈模型x2"的校准，对应真实 10~30%）。
"""

import pathlib
import random

import sys

sys.path.insert(0, r"D:\aigame\_tools")
import balance_sim as b

TIER5 = b.TIERS[4]


def run(n=400, start_gold=0, energy=None, plots=None, tax=None):
    rng = random.Random(21)
    tier = dict(TIER5)
    if tax is not None:
        tier["tax"] = tax
    old_energy = b.BASE_ENERGY
    if energy is not None:
        b.BASE_ENERGY = energy
    passes = 0
    golds = []
    for _ in range(n):
        g = b.Game(tier, rng, 1.0)
        if plots is not None:
            g.plots_cap = plots
        g.gold = start_gold
        gold = g.run()
        golds.append(gold)
        if gold >= tier["tax"]:
            passes += 1
    b.BASE_ENERGY = old_energy
    golds.sort()
    return passes / n * 100, golds[n // 2], golds[int(n * 0.9)]


if __name__ == "__main__":
    variants = [
        ("现状（税30，无补偿）", dict()),
        ("起始金 +6 两", dict(start_gold=6)),
        ("起始金 +10 两", dict(start_gold=10)),
        ("基础能量 +1（3→4）", dict(energy=4)),
        ("起始田 +1（4→5）", dict(plots=5)),
        ("起始金 +6 且能量 +1", dict(start_gold=6, energy=4)),
        ("起始田 +1 且能量 +1", dict(plots=5, energy=4)),
        ("税 30→26（对照）", dict(tax=26)),
        ("税 30→28（对照）", dict(tax=28)),
    ]
    lines = []
    for name, kw in variants:
        p, med, p90 = run(**kw)
        lines.append("%-22s 通关率 %5.1f%%   中位金 %3.0f   p90 %3.0f" % (name, p, med, p90))
    text = "\n".join(lines)
    print(text.encode("ascii", "replace").decode("ascii"))
    pathlib.Path(r"D:\aigame\_tools\tier5_sweep.txt").write_text(text, encoding="utf-8")
