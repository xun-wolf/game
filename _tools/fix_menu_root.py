"""修上一个脚本的锅：BG 节点把 MainMenu 根节点的 theme/script 抢走了。"""

import pathlib

p = pathlib.Path(r"D:\aigame\GameIame\MainMenu.tscn")
t = p.read_text(encoding="utf-8")

bad = '''[node name="MainMenu" type="Control"]
anchor_right = 1.0
anchor_bottom = 1.0

[node name="BG" type="TextureRect" parent="."]
anchor_right = 1.0
anchor_bottom = 1.0
mouse_filter = 2
texture = ExtResource( 9 )
expand = true
stretch_mode = 6
theme = ExtResource( 3 )
script = ExtResource( 2 )
'''

good = '''[node name="MainMenu" type="Control"]
anchor_right = 1.0
anchor_bottom = 1.0
theme = ExtResource( 3 )
script = ExtResource( 2 )

[node name="BG" type="TextureRect" parent="."]
anchor_right = 1.0
anchor_bottom = 1.0
mouse_filter = 2
texture = ExtResource( 9 )
expand = true
stretch_mode = 6
'''

assert t.count(bad) == 1, t.count(bad)
p.write_text(t.replace(bad, good, 1), encoding="utf-8")
print("root theme/script restored")
