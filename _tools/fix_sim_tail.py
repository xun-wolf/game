"""把 balance_sim.py 的 simulate/入口段替换成多操作水平版本。"""

import pathlib

p = pathlib.Path(r"D:\aigame\_tools\balance_sim.py")
text = p.read_text(encoding="utf-8")
head = text[: text.index("def simulate(")]

tail = '''def simulate(n_games=200, seed=1, skills=(0.6, 0.8, 1.0)):
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
    text = "\\n".join(lines)
    print(text.encode("ascii", "replace").decode("ascii"))
    pathlib.Path(r"D:\\aigame\\_tools\\sim_report.txt").write_text(text, encoding="utf-8")
'''

p.write_text(head + tail, encoding="utf-8")
print("tail replaced")
