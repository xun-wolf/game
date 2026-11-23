"""从 git HEAD 版本重建 Game.tscn 的 WIP 改动（GBK 误读导致的中文损坏修复）。

只做文本替换，全部以 UTF-8 读写；每个替换都断言命中次数。
"""

import subprocess
import sys

GAME = r"D:\aigame\GameIame\Game.tscn"
REPO = r"D:\aigame\GameIame"

raw = subprocess.run(["git", "-C", REPO, "cat-file", "-p", "HEAD:Game.tscn"],
                     capture_output=True, check=True).stdout
text = raw.decode("utf-8")

edits = []


def edit(old, new):
    edits.append((old, new))


edit('[gd_scene load_steps=55 format=2]', '[gd_scene load_steps=57 format=2]')

edit('[ext_resource path="res://farm/farmland_4.png" type="Texture" id=54]\n',
     '[ext_resource path="res://farm/farmland_4.png" type="Texture" id=54]\n'
     '[ext_resource path="res://ui/SeasonBanner.gd" type="Script" id=55]\n'
     '[ext_resource path="res://seasons/SeasonFX.tscn" type="PackedScene" id=56]\n')

edit('[node name="Game" type="Node2D"]\n',
     '[node name="Game" type="Node2D"]\n\n[node name="WorldModulate" type="CanvasModulate" parent="."]\n')

edit('[node name="CanvasLayer" type="CanvasLayer" parent="."]\n',
     '[node name="CanvasLayer" type="CanvasLayer" parent="."]\n\n'
     '[node name="SeasonFX" parent="CanvasLayer" instance=ExtResource( 56 )]\n')

# --- Panel 尺寸 ---
edit('''[node name="Panel" type="Panel" parent="CanvasLayer"]
anchor_left = 1.0
anchor_right = 1.0
margin_left = -260.0
margin_top = 9.0
margin_right = -9.0
margin_bottom = 104.0''',
     '''[node name="Panel" type="Panel" parent="CanvasLayer"]
anchor_left = 1.0
anchor_right = 1.0
margin_left = -380.0
margin_top = 9.0
margin_right = -9.0
margin_bottom = 124.0''')

# --- 商店按钮 ---
edit('''[node name="ShopButton" type="Button" parent="CanvasLayer/Panel"]
anchor_left = 0.5
anchor_right = 0.5
margin_left = -33.0
margin_top = 8.0
margin_right = 33.0
margin_bottom = 50.0
theme = ExtResource( 8 )
text = "商店"''',
     '''[node name="ShopButton" type="Button" parent="CanvasLayer/Panel"]
anchor_left = 0.5
anchor_right = 0.5
margin_left = -50.0
margin_top = 8.0
margin_right = 50.0
margin_bottom = 50.0
theme = ExtResource( 8 )
text = "市集采购"''')

# --- 金币/存银 HUD ---
edit('''[node name="GoldLabel" type="Label" parent="CanvasLayer/Panel"]
anchor_left = 0.5
anchor_top = 1.0
anchor_right = 0.5
anchor_bottom = 1.0
margin_left = -122.5
margin_top = -39.0
margin_right = 122.5
margin_bottom = -13.0
text = "（金币：0）"
align = 1
script = ExtResource( 18 )
''',
     '''[node name="GoldLabel" type="Label" parent="CanvasLayer/Panel"]
anchor_left = 0.5
anchor_top = 1.0
anchor_right = 0.5
anchor_bottom = 1.0
margin_left = -180.0
margin_top = -66.0
margin_right = 180.0
margin_bottom = -8.0
text = "存银: 0 🪙  |  岁赋: 18 🎯\\n🌸 春耕 · 立春 (距入夏 6 候)"
align = 1
script = ExtResource( 18 )

[node name="SeasonBanner" type="Panel" parent="CanvasLayer"]
visible = false
anchor_left = 0.5
anchor_right = 0.5
margin_left = -380.0
margin_top = 20.0
margin_right = 380.0
margin_bottom = 86.0
mouse_filter = 1
theme = ExtResource( 8 )
script = ExtResource( 55 )

[node name="Label" type="Label" parent="CanvasLayer/SeasonBanner"]
anchor_right = 1.0
anchor_bottom = 1.0
text = "🌸【立春 · 农事初兴】春回大地，草木萌发。好雨知时节，当春乃发生！"
align = 1
valign = 1
autowrap = true
''')

for i, (old, new) in enumerate(edits):
    n = text.count(old)
    if n != 1:
        print(f"edit {i}: matched {n} times, aborting")
        print(old[:120])
        sys.exit(1)
    text = text.replace(old, new, 1)

# 保留原始换行风格（HEAD 是 LF）
with open(GAME, "wb") as f:
    f.write(text.encode("utf-8"))

print("rebuilt Game.tscn ok, bytes:", len(text.encode("utf-8")))
