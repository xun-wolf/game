"""把 UI 里的 emoji 换成 SimHei 能渲染的文字（🪙→两、🎯→两、删掉纯装饰的 🌸🍁💥）。

逐条替换并断言命中次数，避免误伤；以 UTF-8 + 原样换行读写。
"""

import pathlib
import sys

ROOT = pathlib.Path(r"D:\aigame\GameIame")

EDITS = {
    "DifficultyManager.gd": [
        ('"岁赋 18 🪙 | 害虫温和，风调雨顺"', '"岁赋 18 两 | 害虫温和，风调雨顺"'),
        ('"岁赋 24 🪙 | 官吏苛征，一候一两银"', '"岁赋 24 两 | 官吏苛征，一候一两银"'),
        ('"岁赋 24 🪙 | 凶虫横行，开局直面硬壳巨虫"', '"岁赋 24 两 | 凶虫横行，开局直面硬壳巨虫"'),
        ('"岁赋 24 🪙 | 凶虫袭扰 + 大旱：盛夏每阶段 3 点水"', '"岁赋 24 两 | 凶虫袭扰 + 大旱：盛夏每阶段 3 点水"'),
        ('"岁赋 30 🪙 | 苛政 + 大旱：盛夏每阶段 3 点水，唯有金稻破局"', '"岁赋 30 两 | 苛政 + 大旱：盛夏每阶段 3 点水，唯有金稻破局"'),
    ],
    "Game.tscn": [
        ('text = "存银: 0 🪙  |  岁赋: 18 🎯\\n🌸 春耕 · 立春 (距入夏 6 候)"',
         'text = "存银: 0 两  |  岁赋: 18 两\\n春耕 · 立春 (距入夏 6 候)"'),
        ('text = "🌸【立春 · 农事初兴】春回大地，草木萌发。好雨知时节，当春乃发生！"',
         'text = "【立春 · 农事初兴】春回大地，草木萌发。好雨知时节，当春乃发生！"'),
    ],
    "MainMenu.tscn": [
        ('text = "岁赋 18 🪙 | 害虫温和，风调雨顺"', 'text = "岁赋 18 两 | 害虫温和，风调雨顺"'),
        ('text = "【⚔️ 待攻坚 · 耕耘挑战】"', 'text = "【待攻坚 · 耕耘挑战】"'),
    ],
    "GoldLabel.gd": [
        ('" 🪙  |  岁赋: "', '" 两  |  岁赋: "'),
        ('+ " 🎯"', '+ " 两"'),
    ],
    "SeasonManager.gd": [
        ('const SEASON_TITLES = ["🌸 春耕", "☀️ 夏耘", "🍁 秋收", "❄️ 冬藏"]',
         'const SEASON_TITLES = ["春耕", "夏耘", "秋收", "冬藏"]'),
        ('Season.SPRING: "🌸【立春 · 农事初兴】', 'Season.SPRING: "【立春 · 农事初兴】'),
        ('Season.SUMMER: "☀️【立夏 · 万物繁盛】', 'Season.SUMMER: "【立夏 · 万物繁盛】'),
        ('Season.AUTUMN: "🍁【立秋 · 金风送爽】', 'Season.AUTUMN: "【立秋 · 金风送爽】'),
        ('Season.WINTER: "❄️【立冬 · 岁暮天寒】', 'Season.WINTER: "【立冬 · 岁暮天寒】'),
        ('return "🌸 春耕"', 'return "春耕"'),
    ],
    "ui/DifficultySelector.gd": [
        ('"【🏆 已通关 · 榜上有名】"', '"【已通关 · 榜上有名】"'),
        ('"【⚔️ 待攻坚 · 耕耘挑战】"', '"【待攻坚 · 耕耘挑战】"'),
    ],
    "ui/NewCardSelection.tscn": [
        ('text = "💰 挑粮入市 (换 3 金币)"', 'text = "挑粮入市 (换 3 金币)"'),
    ],
}

ok = True
for name, pairs in EDITS.items():
    p = ROOT / name
    with open(p, "r", encoding="utf-8", newline="") as f:
        text = f.read()
    for old, new in pairs:
        n = text.count(old)
        if n != 1:
            print(f"!! {name}: 命中 {n} 次 -> {old[:60]}")
            ok = False
            continue
        text = text.replace(old, new, 1)
    with open(p, "w", encoding="utf-8", newline="") as f:
        f.write(text)
    print("done", name)

if not ok:
    sys.exit(1)
print("all replacements applied")
