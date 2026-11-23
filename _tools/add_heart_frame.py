"""给 Bug.tscn 的 HeartMarker 加一个金色外框子节点（虫王专用）。"""

import pathlib

p = pathlib.Path(r"D:\aigame\GameIame\bugs\Bug.tscn")
text = p.read_text(encoding="utf-8")

old = '''[node name="HeartMarker" type="Sprite" parent="."]
position = Vector2( 140, 64 )
scale = Vector2( 1e-05, 1e-05 )
texture = ExtResource( 4 )

[node name="HealthNum" type="Label" parent="HeartMarker"]'''

new = '''[node name="HeartMarker" type="Sprite" parent="."]
position = Vector2( 140, 64 )
scale = Vector2( 1e-05, 1e-05 )
texture = ExtResource( 4 )

[node name="Frame" type="Sprite" parent="HeartMarker"]
visible = false
z_index = -1
scale = Vector2( 1.2, 1.2 )
modulate = Color( 0.85, 0.62, 0.18, 1 )
texture = ExtResource( 4 )

[node name="HealthNum" type="Label" parent="HeartMarker"]'''

assert text.count(old) == 1, text.count(old)
p.write_text(text.replace(old, new, 1), encoding="utf-8")
print("heart frame added")
