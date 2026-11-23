"""扫描"大旱窗口"对三品/一品通关率的影响。

思路：大旱档不必整个夏天都 2 点水，可以只覆盖最热的几个候（第 9-12 候之类）。
模型绝对值偏悲观，只用来看相对形状：哪个窗口能把三品放在五品和一品之间。
"""

import pathlib
import sys

sys.path.insert(0, r"D:\aigame\_tools")

import balance_sim as b

def patch():
    # 把 water_cost 换成"带窗口"的版本
    def water_cost(turn, tier):
        if b.season_of(turn) != "summer":
            return 1
        if not tier["drought"]:
            return 1
        if b.DROUGHT_FIRST <= turn <= b.DROUGHT_LAST:
            return 2
        return 1

    b.water_cost = water_cost
    # Game 内部调用的是模块级 water_cost，需要让方法内引用到新函数
    b.Game.start_turn.__globals__["water_cost"] = water_cost
    b.Game.end_turn.__globals__["water_cost"] = water_cost


def run(first, last, n=200):
    b.DROUGHT_FIRST = first
    b.DROUGHT_LAST = last
    patch()
    rows = b.simulate(n, seed=9, skills=(1.0,))[1.0]
    out = {}
    for r in rows:
        out[r["rank"]] = (r["pass"], r["median"])
    return out


if __name__ == "__main__":
    lines = []
    for first, last, label in [(7, 12, "整个夏天 6 候"), (9, 12, "第 9-12 候（4 候）"),
                               (10, 12, "第 10-12 候（3 候）"), (11, 12, "第 11-12 候（2 候）")]:
        res = run(first, last)
        lines.append("%-18s 五品 %4.1f%% 中位%3.0f | 三品 %4.1f%% 中位%3.0f | 一品 %4.1f%% 中位%3.0f" % (
            label,
            res["五品"][0], res["五品"][1],
            res["三品"][0], res["三品"][1],
            res["一品"][0], res["一品"][1]))
    text = "\n".join(lines)
    print(text.encode("ascii", "replace").decode("ascii"))
    pathlib.Path(r"D:\aigame\_tools\drought_sweep.txt").write_text(text, encoding="utf-8")
