"""把右上角 HUD 面板加宽，避免"存银: 20 两 | 岁赋: 18 两 [九品 · 丰年]"被窗口右边缘切掉。"""

import pathlib

p = pathlib.Path(r"D:\aigame\GameIame\Game.tscn")
text = p.read_text(encoding="utf-8")

pairs = [
    ('''[node name="Panel" type="Panel" parent="CanvasLayer"]
anchor_left = 1.0
anchor_right = 1.0
margin_left = -380.0''',
     '''[node name="Panel" type="Panel" parent="CanvasLayer"]
anchor_left = 1.0
anchor_right = 1.0
margin_left = -470.0'''),
    ('''margin_left = -180.0
margin_top = -66.0
margin_right = 180.0
margin_bottom = -8.0''',
     '''margin_left = -225.0
margin_top = -66.0
margin_right = 225.0
margin_bottom = -8.0'''),
]

for old, new in pairs:
    n = text.count(old)
    assert n == 1, f"matched {n} times: {old[:40]!r}"
    text = text.replace(old, new, 1)

p.write_text(text, encoding="utf-8")
print("HUD widened")
