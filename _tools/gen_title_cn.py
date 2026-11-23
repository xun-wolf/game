"""生成《田间风云》中文标题图（替换原来的 Cardwork Cycle 英文手写 logo）。

输出 ui/title_cn.png，1024x460，透明底：
- 楷体「田间风云」，白色 + 柔和投影
- 右侧一枚朱红印章「丰」
- 下方 FIELD CHRONICLES 小字副标题
"""

import pathlib

from PIL import Image, ImageDraw, ImageFilter, ImageFont

OUT = pathlib.Path(r"D:\aigame\GameIame\ui\title_cn.png")
FONT_KAI = r"C:\Windows\Fonts\simkai.ttf"
FONT_LATIN = r"C:\Windows\Fonts\calibri.ttf"

W, H = 1024, 460
TITLE = "田间风云"
SUB = "FIELD CHRONICLES"

img = Image.new("RGBA", (W, H), (0, 0, 0, 0))

# ---- 主标题 ----
title_font = ImageFont.truetype(FONT_KAI, 190)
tracking = 24

def text_width(font, s, track):
    w = 0
    for ch in s:
        w += font.getlength(ch) + track
    return w - track if s else 0

tw = text_width(title_font, TITLE, tracking)
x = (W - tw) / 2 - 40          # 留出右侧印章的空间
y = 40

# 投影
shadow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
sd = ImageDraw.Draw(shadow)
cx = x
for ch in TITLE:
    sd.text((cx, y + 10), ch, font=title_font, fill=(0, 0, 0, 170))
    cx += title_font.getlength(ch) + tracking
shadow = shadow.filter(ImageFilter.GaussianBlur(10))
img = Image.alpha_composite(img, shadow)

draw = ImageDraw.Draw(img)
cx = x
for ch in TITLE:
    # 主体：上白下浅灰的渐变感，用两层叠出来
    draw.text((cx, y), ch, font=title_font, fill=(255, 255, 255, 255))
    draw.text((cx, y + 3), ch, font=title_font, fill=(226, 232, 238, 90))
    cx += title_font.getlength(ch) + tracking

# ---- 朱红印章 ----
seal_size = 104
sx = int(x + tw + 18)
sy = int(y + 26)
seal = Image.new("RGBA", (seal_size, seal_size), (0, 0, 0, 0))
sd = ImageDraw.Draw(seal)
sd.rounded_rectangle([0, 0, seal_size - 1, seal_size - 1], radius=10,
                     fill=(176, 58, 46, 235), outline=(140, 40, 30, 255), width=3)
seal_char = ImageFont.truetype(FONT_KAI, 62)
bbox = seal_char.getbbox("丰")
cw, chh = bbox[2] - bbox[0], bbox[3] - bbox[1]
sd.text(((seal_size - cw) / 2 - bbox[0], (seal_size - chh) / 2 - bbox[1] - 6), "丰",
        font=seal_char, fill=(255, 246, 238, 245))
img.alpha_composite(seal, dest=(sx, sy))

# ---- 副标题 ----
draw = ImageDraw.Draw(img)
sub_font = ImageFont.truetype(FONT_LATIN, 34)
sub_track = 11
sw = text_width(sub_font, SUB, sub_track)
sx = (W - sw) / 2
sy2 = 300
for ch in SUB:
    draw.text((sx, sy2), ch, font=sub_font, fill=(168, 176, 184, 235))
    sx += sub_font.getlength(ch) + sub_track

# 副标题下的细线
line_y = sy2 + 56
draw.line([(W / 2 - 190, line_y), (W / 2 + 190, line_y)], fill=(120, 128, 136, 120), width=2)

img = img.resize((560, 252), Image.LANCZOS)
img.save(OUT)
print("saved", OUT, img.size)
