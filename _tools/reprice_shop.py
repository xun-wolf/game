"""商店重新定价：让"买强化"重新变成需要攒钱的取舍。

背景：收获金币从 1 提到 3/6/15（x3~x15），但商店沿用原版 2/3/5/2/2/4 的价格，
一次一级收获就能买下最便宜的能量强化，两次三级收获能清空整个商店。
"""

import pathlib

p = pathlib.Path(r"D:\aigame\GameIame\shop\Shop.tscn")
text = p.read_text(encoding="utf-8")

pairs = [
    ('"这枚神秘水晶能为你增加 1 点能量上限。"\ncost = 2',
     '"这枚神秘水晶能为你增加 1 点能量上限。"\ncost = 7'),
    ('"这根魔法法杖能为你增加 1 点能量上限。"\ncost = 3',
     '"这根魔法法杖能为你增加 1 点能量上限。"\ncost = 10'),
    ('"这枚附魔戒指能为你增加 1 点能量上限。"\n',
     '"这枚附魔戒指能为你增加 1 点能量上限。"\ncost = 13\n'),
    ('"购买更多农田来种植植物。"\ncost = 2',
     '"购买更多农田来种植植物。"\ncost = 8'),
    ('"有了这把浇水壶，你每种下一株新植物，它都会自带 1 点水分。"\ncost = 2',
     '"有了这把浇水壶，你每种下一株新植物，它都会自带 1 点水分。"\ncost = 4'),
    ('"这副棱彩卡组能让你每回合额外抽 1 张牌。"\ncost = 4',
     '"这副棱彩卡组能让你每回合额外抽 1 张牌。"\ncost = 9'),
]

for old, new in pairs:
    n = text.count(old)
    assert n == 1, f"matched {n}: {old[:30]!r}"
    text = text.replace(old, new, 1)

# 场景里的按钮文案写死了"10 金币"，实际由 ShopItem._ready 覆盖；这里改成不写数字，避免误导
before = text.count('text = "购买（10 金币）"')
text = text.replace('text = "购买（10 金币）"', 'text = "购买"')
print("button texts updated:", before)

p.write_text(text, encoding="utf-8")
print("shop repriced")
