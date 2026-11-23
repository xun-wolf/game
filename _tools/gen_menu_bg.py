"""主菜单背景：暗色渐变 + 暗角 + 底部田垄剪影，别抢标题。

输出: GameIame/ui/menu_bg.png (1920x1080)
"""

import math
import pathlib
import random

from PIL import Image, ImageDraw, ImageFilter

W, H = 1920, 1080
OUT = pathlib.Path(r"D:\aigame\GameIame\ui\menu_bg.png")

img = Image.new("RGB", (W, H), (18, 24, 19))
d = ImageDraw.Draw(img)

# 1) 垂直渐变：上略亮，下更深
top = (34, 44, 34)
bottom = (12, 16, 13)
for y in range(H):
    k = y / (H - 1)
    k = k ** 0.85
    c = tuple(int(top[i] + (bottom[i] - top[i]) * k) for i in range(3))
    d.line([(0, y), (W, y)], fill=c)

# 2) 远处的田垄剪影（三层，越远越暗）
def hill(color, base_y, amp, phase, freq):
    pts = [(0, H)]
    for x in range(0, W + 1, 8):
        y = base_y + math.sin(x / freq + phase) * amp + math.sin(x / (freq * 0.37) + phase * 2) * amp * 0.4
        pts.append((x, y))
    pts.append((W, H))
    d.polygon(pts, fill=color)

hill((16, 22, 17), H * 0.74, 26, 0.6, 320)
hill((20, 27, 21), H * 0.82, 18, 2.1, 260)
hill((24, 32, 25), H * 0.90, 12, 4.0, 200)

# 3) 田垄细纹
for i in range(14):
    y = H * 0.86 + i * 14
    d.line([(0, y), (W, y)], fill=(38, 48, 38), width=1)

# 4) 轻噪点，避免色带
rng = random.Random(3)
px = img.load()
for _ in range(160000):
    x = rng.randrange(W)
    y = rng.randrange(H)
    r, g, b = px[x, y]
    n = rng.randint(-7, 7)
    px[x, y] = (max(0, min(255, r + n)), max(0, min(255, g + n)), max(0, min(255, b + n)))

# 5) 暗角
vignette = Image.new("L", (W, H), 0)
vd = ImageDraw.Draw(vignette)
vd.ellipse([-W * 0.35, -H * 0.45, W * 1.35, H * 1.45], fill=255)
vignette = vignette.filter(ImageFilter.GaussianBlur(220))
black = Image.new("RGB", (W, H), (0, 0, 0))
img = Image.composite(img, black, vignette)

img.save(OUT)
print("saved", OUT)
