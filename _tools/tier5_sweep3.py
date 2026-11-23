"""一品补偿方案 v3：只测"玩家看得见"的补偿，不动系统（不加能量）。

候选：
  A 起始金 +6（乡邻接济）
  B 开局多一张「天降甘霖」（神农降雨）
  C 两者都给
"""

import pathlib
import random
import sys

sys.path.insert(0, r"D:\aigame\_tools")
import balance_sim as b

TIER5 = b.TIERS[4]


def run(n=400, start_gold=0, extra_card=None, seed=21):
    rng = random.Random(seed)
    tier = dict(TIER5)
    passes = 0
    golds = []
    for _ in range(n):
        g = b.Game(tier, rng, 1.0)
        g.gold = start_gold
        if extra_card:
            g.deck.append(extra_card)
        gold = g.run()
        golds.append(gold)
        if gold >= tier["tax"]:
            passes += 1
    golds.sort()
    return passes / n * 100, golds[n // 2], golds[int(n * 0.9)]


if __name__ == "__main__":
    variants = [
        ("现状", dict()),
        ("A 起始金 +6", dict(start_gold=6)),
        ("B 多一张天降甘霖", dict(extra_card="天降甘霖")),
        ("C 金 +6 且多一张甘霖", dict(start_gold=6, extra_card="天降甘霖")),
    ]
    lines = []
    for name, kw in variants:
        p, med, p90 = run(**kw)
        lines.append("%-22s 通关率 %5.1f%%  中位 %3.0f  p90 %3.0f" % (name, p, med, p90))
    text = "\n".join(lines)
    print(text.encode("ascii", "replace").decode("ascii"))
    pathlib.Path(r"D:\aigame\_tools\tier5_sweep3.txt").write_text(text, encoding="utf-8")
