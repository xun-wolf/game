"""两个场景调整：
1) Game.tscn：把 SeasonBanner 挪到选卡弹窗之前（层级低于弹窗，不再盖住结算面板）
2) MainMenu.tscn：加一张背景图节点
"""

import pathlib

# ---------------- Game.tscn：移动 SeasonBanner ----------------
gt = pathlib.Path(r"D:\aigame\GameIame\Game.tscn")
text = gt.read_text(encoding="utf-8")
lines = text.split("\n")

start = None
for i, l in enumerate(lines):
    if l.strip() == '[node name="SeasonBanner" type="Panel" parent="CanvasLayer"]':
        start = i
        break
assert start is not None, "SeasonBanner not found"

end = None
for j in range(start + 1, len(lines)):
    if lines[j].startswith("[node ") and 'parent="CanvasLayer/SeasonBanner"' not in lines[j]:
        end = j
        break
assert end is not None

block = lines[start:end]
# 去掉块尾多余空行
while block and block[-1].strip() == "":
    block.pop()

del lines[start:end]

insert_at = None
for i, l in enumerate(lines):
    if l.startswith('[node name="NewCardSelecction"'):
        insert_at = i
        break
assert insert_at is not None, "modal node not found"

lines[insert_at:insert_at] = block + [""]
gt.write_text("\n".join(lines), encoding="utf-8")
print("SeasonBanner moved before card-selection modal")

# ---------------- MainMenu.tscn：背景 ----------------
mm = pathlib.Path(r"D:\aigame\GameIame\MainMenu.tscn")
t = mm.read_text(encoding="utf-8")

t = t.replace("[gd_scene load_steps=10 format=2]", "[gd_scene load_steps=11 format=2]", 1)
anchor = '[ext_resource path="res://ui/DifficultySelector.gd" type="Script" id=8]\n'
assert t.count(anchor) == 1
t = t.replace(anchor, anchor + '[ext_resource path="res://ui/menu_bg.png" type="Texture" id=9]\n', 1)

root = '[node name="MainMenu" type="Control"]\nanchor_right = 1.0\nanchor_bottom = 1.0\n'
assert t.count(root) == 1
t = t.replace(root, root + '''
[node name="BG" type="TextureRect" parent="."]
anchor_right = 1.0
anchor_bottom = 1.0
mouse_filter = 2
texture = ExtResource( 9 )
expand = true
stretch_mode = 6
''', 1)

mm.write_text(t, encoding="utf-8")
print("menu background added")
