"""生成暗金心形底托，尺寸/位置对齐 heart_marker.svg 的实际图形。

heart_marker.svg 是 128x128 画布，心形只占左下角 (1,83)-(53,127)。
所以这里也在 128x128 画布上把心画在同一位置，并放大约 18% 作为外框。
"""

import math
import pathlib

from PIL import Image, ImageDraw

SIZE = 128
K = 6
C = SIZE * K

# 原图心形的包围盒
BBOX = (1, 83, 53, 127)
CX = (BBOX[0] + BBOX[2]) / 2
CY = (BBOX[1] + BBOX[3]) / 2
HALF_W = (BBOX[2] - BBOX[0]) / 2 * 1.18
HALF_H = (BBOX[3] - BBOX[1]) / 2 * 1.18


def heart_points(cx, cy, w, h, n=260):
    pts = []
    for i in range(n):
        t = 2 * math.pi * i / n
        x = 16 * math.sin(t) ** 3
        y = 13 * math.cos(t) - 5 * math.cos(2 * t) - 2 * math.cos(3 * t) - math.cos(4 * t)
        pts.append((cx + x / 16 * w, cy - y / 16 * h))
    return pts


img = Image.new("RGBA", (C, C), (0, 0, 0, 0))
d = ImageDraw.Draw(img)
cx, cy = CX * K, CY * K
w, h = HALF_W * K, HALF_H * K

d.polygon(heart_points(cx, cy, w * 1.02, h * 1.02), fill=(92, 58, 12, 255))
d.polygon(heart_points(cx, cy, w, h), fill=(206, 152, 46, 255))
d.polygon(heart_points(cx, cy - h * 0.04, w * 0.88, h * 0.86), fill=(236, 190, 84, 255))

img = img.resize((SIZE, SIZE), Image.LANCZOS)
out = pathlib.Path(r"D:\aigame\GameIame\plants\heart_frame_gold.png")
img.save(out)
print("saved", out, "bbox", img.getbbox())
