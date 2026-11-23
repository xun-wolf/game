"""主菜单换成中文标题图：替换 ext_resource 路径，并按新图比例调整 TextureRect。"""

import pathlib

p = pathlib.Path(r"D:\aigame\GameIame\MainMenu.tscn")
text = p.read_text(encoding="utf-8")

pairs = [
    ('[ext_resource path="res://ui/title.svg" type="Texture" id=5]',
     '[ext_resource path="res://ui/title_cn.png" type="Texture" id=5]'),
    ('''[node name="TextureRect" type="TextureRect" parent="."]
anchor_left = 0.5
anchor_right = 0.5
margin_left = -255.0
margin_top = 33.0
margin_right = 262.0
margin_bottom = 272.0''',
     '''[node name="TextureRect" type="TextureRect" parent="."]
anchor_left = 0.5
anchor_right = 0.5
margin_left = -290.0
margin_top = 26.0
margin_right = 290.0
margin_bottom = 286.0'''),
    ('expand = true', 'expand = true'),
]

for old, new in pairs:
    if old == new:
        continue
    n = text.count(old)
    assert n == 1, f"matched {n}: {old[:40]!r}"
    text = text.replace(old, new, 1)

p.write_text(text, encoding="utf-8")
print("main menu title swapped")
