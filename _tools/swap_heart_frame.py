"""Bug.tscn 的金色心形底托改用专用贴图（heart_frame_gold.png），不描边不染洋红。"""

import pathlib

p = pathlib.Path(r"D:\aigame\GameIame\bugs\Bug.tscn")
text = p.read_text(encoding="utf-8")

old = '''[node name="Frame" type="Sprite" parent="HeartMarker"]
visible = false
z_index = -1
scale = Vector2( 1.2, 1.2 )
modulate = Color( 0.85, 0.62, 0.18, 1 )
texture = ExtResource( 4 )'''

new = '''[node name="Frame" type="Sprite" parent="HeartMarker"]
visible = false
z_index = -1
scale = Vector2( 1.18, 1.18 )
texture = ExtResource( 6 )'''

assert text.count(old) == 1
text = text.replace(old, new, 1)

# 注册新的 ext_resource（放在 heart_marker 之后）
anchor = '[ext_resource path="res://plants/heart_marker.svg" type="Texture" id=4]'
assert text.count(anchor) == 1
text = text.replace(anchor, anchor + '\n[ext_resource path="res://plants/heart_frame_gold.png" type="Texture" id=6]', 1)

# load_steps 加一
text = text.replace("[gd_scene load_steps=13 format=2]", "[gd_scene load_steps=14 format=2]", 1)

p.write_text(text, encoding="utf-8")
print("frame texture swapped")
