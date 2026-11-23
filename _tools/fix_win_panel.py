"""修胜利/选卡弹窗被教程卷轴盖住 + 胜利面板文字排版。

1) Game.tscn：CanvasLayer/Tutorial 整块挪到 NewCardSelecction 之前（层级更低）
2) NewCardSelection.tscn：胜利标题加宽、正文加高
"""

import pathlib

# ---------- 1) Game.tscn：教程挪到弹窗之前 ----------
gt = pathlib.Path(r"D:\aigame\GameIame\Game.tscn")
text = gt.read_text(encoding="utf-8")
lines = text.split("\n")

start = None
for i, l in enumerate(lines):
    if l.startswith('[node name="Tutorial" type="Label" parent="CanvasLayer"]'):
        start = i
        break
assert start is not None, "tutorial node not found"

end = None
for j in range(start + 1, len(lines)):
    if lines[j].startswith("[node ") and 'parent="CanvasLayer/Tutorial' not in lines[j]:
        end = j
        break
assert end is not None

block = lines[start:end]
while block and block[-1].strip() == "":
    block.pop()
del lines[start:end]

target = None
for i, l in enumerate(lines):
    if l.startswith('[node name="NewCardSelecction"'):
        target = i
        break
assert target is not None, "modal node not found"

lines[target:target] = block + [""]
gt.write_text("\n".join(lines), encoding="utf-8")
print("tutorial moved below the modal")

# ---------- 2) 胜利面板排版 ----------
nt = pathlib.Path(r"D:\aigame\GameIame\ui\NewCardSelection.tscn")
t = nt.read_text(encoding="utf-8")

pairs = [
    ('''margin_left = -83.0
margin_top = 14.0
margin_right = 83.0
margin_bottom = 40.0
text = "恭喜！"''',
     '''margin_left = -180.0
margin_top = 14.0
margin_right = 180.0
margin_bottom = 46.0
text = "恭喜！"'''),
    ('''margin_left = -294.0
margin_top = 65.0
margin_right = 294.0
margin_bottom = 207.0''',
     '''margin_left = -330.0
margin_top = 60.0
margin_right = 330.0
margin_bottom = 330.0'''),
]

for old, new in pairs:
    assert t.count(old) == 1, f"matched {t.count(old)}: {old[:40]!r}"
    t = t.replace(old, new, 1)

nt.write_text(t, encoding="utf-8")
print("win panel layout adjusted")
