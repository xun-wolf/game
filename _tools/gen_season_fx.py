"""生成《田间风云》季节特效贴图 + 夏日干裂地面。

用法:
  python gen_season_fx.py <project_root>

产物:
  seasons/fx/leaf_gold.png   24x24  秋叶（金黄）
  seasons/fx/leaf_red.png    24x24  秋叶（赤褐）
  seasons/fx/snow.png        10x10  雪花
  seasons/fx/petal.png       14x14  春花瓣
  seasons/fx/dust.png        8x8    夏日浮尘
  seasons/summer/farm/dirt_pixel*.png / farmland_*.png  叠加干裂纹
"""

import hashlib
import math
import os
import random
import sys

from PIL import Image, ImageDraw

ROOT = sys.argv[1] if len(sys.argv) > 1 else r"D:\aigame\GameIame"
FX_DIR = os.path.join(ROOT, "seasons", "fx")
SUMMER_DIR = os.path.join(ROOT, "seasons", "summer", "farm")


def ensure_dir(p):
    if not os.path.isdir(p):
        os.makedirs(p)


def polygon_ellipse(cx, cy, rx, ry, angle_deg, steps=36):
    a = math.radians(angle_deg)
    ca, sa = math.cos(a), math.sin(a)
    pts = []
    for i in range(steps):
        t = 2.0 * math.pi * i / steps
        x = rx * math.cos(t)
        y = ry * math.sin(t)
        pts.append((cx + x * ca - y * sa, cy + x * sa + y * ca))
    return pts


def draw_leaf(size, fill, outline, vein):
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    cx = cy = size / 2.0
    rx, ry = size * 0.30, size * 0.46
    # 叶身：旋转 38 度的椭圆
    body = polygon_ellipse(cx, cy, rx, ry, 38)
    d.polygon(body, fill=fill)
    # 叶柄
    stem_dx = -math.sin(math.radians(38)) * ry * 0.95
    stem_dy = math.cos(math.radians(38)) * ry * 0.95
    d.line([(cx, cy), (cx + stem_dx, cy + stem_dy)], fill=outline, width=1)
    # 主叶脉
    d.line([(cx - stem_dx * 0.7, cy - stem_dy * 0.7), (cx + stem_dx * 0.55, cy + stem_dy * 0.55)],
           fill=vein, width=1)
    # 4 条侧脉
    for k in (-0.45, -0.15, 0.15, 0.45):
        px = cx + stem_dx * k
        py = cy + stem_dy * k
        d.line([(px, py), (px + math.sin(math.radians(38)) * rx * 0.85,
                           py - math.cos(math.radians(38)) * rx * 0.85)], fill=vein, width=1)
        d.line([(px, py), (px - math.sin(math.radians(38)) * rx * 0.85,
                           py + math.cos(math.radians(38)) * rx * 0.85)], fill=vein, width=1)
    # 描边（只描外轮廓，颜色比叶身深）
    d.line(body + [body[0]], fill=outline, width=1)
    return img


def draw_snow(size):
    """冷色描边 + 白芯的小雪团：落在雪地上也能看清。"""
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    c = size / 2.0
    d.ellipse([c - 5, c - 5, c + 5, c + 5], fill=(158, 180, 214, 170))
    d.ellipse([c - 3.5, c - 3.5, c + 3.5, c + 3.5], fill=(206, 222, 244, 235))
    d.ellipse([c - 2, c - 2, c + 2, c + 2], fill=(255, 255, 255, 255))
    return img


def draw_petal(size):
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    cx = cy = size / 2.0
    d.polygon(polygon_ellipse(cx, cy, size * 0.22, size * 0.42, 20),
              fill=(247, 183, 205, 235))
    d.polygon(polygon_ellipse(cx + 1, cy - 1, size * 0.10, size * 0.22, 20),
              fill=(255, 214, 226, 235))
    return img


def draw_dust(size):
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.ellipse([1, 1, size - 2, size - 2], fill=(214, 176, 120, 120))
    d.ellipse([2, 2, size - 3, size - 3], fill=(226, 194, 142, 160))
    return img


# ---------------------------------------------------------------- 干裂地面

def crack_paths(rng, size, n_main):
    """返回若干条裂纹折线（像素坐标），带分叉。"""
    lines = []

    def grow(x, y, ang, steps, width, depth):
        pts = [(x, y)]
        for _ in range(steps):
            ang += rng.uniform(-0.45, 0.45)
            x += math.cos(ang) * rng.uniform(1.6, 3.2)
            y += math.sin(ang) * rng.uniform(1.6, 3.2)
            if not (0 <= x < size and 0 <= y < size):
                break
            pts.append((x, y))
            if depth > 0 and rng.random() < 0.10:
                lines.append((pts[:], max(1, width - 1)))
                grow(x, y, ang + rng.choice([-1, 1]) * rng.uniform(0.6, 1.2),
                     max(3, steps // 2), max(1, width - 1), depth - 1)
        lines.append((pts, width))

    for _ in range(n_main):
        # 主裂纹从边缘或角落出发，穿过整块地
        side = rng.random()
        if side < 0.5:
            x, y = rng.uniform(0, size), 0
            ang = math.radians(rng.uniform(55, 125))
        else:
            x, y = 0, rng.uniform(0, size)
            ang = math.radians(rng.uniform(-35, 35))
        grow(x, y, ang, rng.randint(30, 55), 2, 2)
    return lines


def bake_cracks(path, seed):
    """环形 Voronoi：裂缝是相邻泥块之间的缝隙，可无缝拼接。"""
    import numpy as np

    rng = random.Random(seed)
    img = Image.open(path).convert("RGBA")
    w, h = img.size
    size = w

    # 1. 日晒褪色：略微降饱和、提亮
    px = img.load()
    for yy in range(h):
        for xx in range(w):
            r, g, b, a = px[xx, yy]
            lum = 0.299 * r + 0.587 * g + 0.114 * b
            r = int(r * 0.90 + lum * 0.11)
            g = int(g * 0.90 + lum * 0.11)
            b = int(b * 0.90 + lum * 0.11)
            px[xx, yy] = (min(255, r + 6), min(255, g + 4), min(255, b + 2), a)

    # 2. 环形 Voronoi 裂缝
    n_cells = rng.randint(6, 8)
    seeds = [(rng.uniform(0, size), rng.uniform(0, size)) for _ in range(n_cells)]
    ys, xs = np.mgrid[0:size, 0:size].astype(np.float32)
    dists = []
    for (sx, sy) in seeds:
        dx = np.abs(xs - sx)
        dy = np.abs(ys - sy)
        dx = np.minimum(dx, size - dx)   # 环形距离 -> 可无缝铺贴
        dy = np.minimum(dy, size - dy)
        dists.append(np.sqrt(dx * dx + dy * dy))
    d = np.stack(dists, axis=0)
    d.sort(axis=0)
    gap = d[1] - d[0]
    seam = gap < 1.7

    arr = np.asarray(img).astype(np.float32)
    rgb = arr[:, :, :3]
    # 缝隙内部更暗，边缘略亮一点，模拟干裂受光
    dark = seam & (gap < 0.8)
    edge = seam & ~dark
    rgb[dark] = rgb[dark] * 0.52 + 6
    rgb[edge] = rgb[edge] * 0.76 + 8
    arr[:, :, :3] = np.clip(rgb, 0, 255)
    return Image.fromarray(arr.astype(np.uint8), "RGBA")


def main():
    ensure_dir(FX_DIR)

    draw_leaf(24, (214, 158, 56, 255), (108, 66, 24, 255), (150, 100, 38, 255)).save(
        os.path.join(FX_DIR, "leaf_gold.png"))
    draw_leaf(24, (188, 92, 48, 255), (96, 44, 26, 255), (136, 62, 34, 255)).save(
        os.path.join(FX_DIR, "leaf_red.png"))
    draw_snow(10).save(os.path.join(FX_DIR, "snow.png"))
    draw_petal(14).save(os.path.join(FX_DIR, "petal.png"))
    draw_dust(8).save(os.path.join(FX_DIR, "dust.png"))

    targets = ["dirt_pixel.png", "dirt_pixel_2.png", "dirt_pixel_3.png", "dirt_pixel_4.png",
               "farmland_1.png", "farmland_2.png", "farmland_3.png", "farmland_4.png"]
    for name in targets:
        p = os.path.join(SUMMER_DIR, name)
        if not os.path.exists(p):
            print("skip missing", p)
            continue
        seed = int(hashlib.md5(name.encode("utf-8")).hexdigest()[:8], 16)
        bake_cracks(p, seed).save(p)
        print("cracked", name)

    print("done ->", FX_DIR)


if __name__ == "__main__":
    main()
