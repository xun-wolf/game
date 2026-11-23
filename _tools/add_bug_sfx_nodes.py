"""给 SFX 场景加两个新音效播放器（重击 / 虫王出场）。"""

import pathlib

p = pathlib.Path(r"D:\aigame\GameIame\SFX.tscn")
t = p.read_text(encoding="utf-8")

t = t.replace("[gd_scene load_steps=20 format=2]", "[gd_scene load_steps=22 format=2]", 1)

anchor = '[ext_resource path="res://sfx/nowater2.wav" type="AudioStream" id=18]\n'
assert t.count(anchor) == 1
t = t.replace(anchor, anchor
              + '[ext_resource path="res://sfx/heavy_hit.wav" type="AudioStream" id=20]\n'
              + '[ext_resource path="res://sfx/king_spawn.wav" type="AudioStream" id=21]\n', 1)

t = t.rstrip("\n") + '''

[node name="HeavyHit" type="AudioStreamPlayer" parent="."]
stream = ExtResource( 20 )
volume_db = -6.0
bus = "SFX"
script = ExtResource( 2 )

[node name="KingSpawn" type="AudioStreamPlayer" parent="."]
stream = ExtResource( 21 )
volume_db = -4.0
bus = "SFX"
script = ExtResource( 2 )
'''

p.write_text(t, encoding="utf-8")
print("sfx players added")
