"""收尾：删掉不再使用的金色外框节点，并让档位颜色区分更明显。"""

import pathlib

# 1) Bug.tscn 去掉 Frame 节点与只给它用的 ext_resource
tscn = pathlib.Path(r"D:\aigame\GameIame\bugs\Bug.tscn")
t = tscn.read_text(encoding="utf-8")

frame_block = '''
[node name="Frame" type="Sprite" parent="HeartMarker"]
visible = false
z_index = -1
scale = Vector2( 1, 1 )
texture = ExtResource( 6 )
'''
assert t.count(frame_block) == 1
t = t.replace(frame_block, "", 1)

ext = '[ext_resource path="res://plants/heart_frame_gold.png" type="Texture" id=6]\n'
assert t.count(ext) == 1
t = t.replace(ext, "", 1)
t = t.replace("[gd_scene load_steps=14 format=2]", "[gd_scene load_steps=13 format=2]", 1)
tscn.write_text(t, encoding="utf-8")
print("frame node removed")

# 2) 血量标记颜色拉大区分度
gd = pathlib.Path(r"D:\aigame\GameIame\bugs\Bug.gd")
g = gd.read_text(encoding="utf-8")
g = g.replace("2: Color(1.0, 0.80, 0.80, 1.0),", "2: Color(1.0, 0.68, 0.45, 1.0),")
g = g.replace("3: Color(1.0, 0.52, 0.46, 1.0),", "3: Color(1.0, 0.40, 0.34, 1.0),")
gd.write_text(g, encoding="utf-8")
print("marker colors tuned")
