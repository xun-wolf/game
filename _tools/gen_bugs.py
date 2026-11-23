"""生成 4 个等级的害虫立绘（96x96，透明底，平滑描边）。

配色沿用原版 bug1.svg 的语汇：黑描边 + 暗红甲壳 + 灰爪 + 红眼。
等级越高：体型越大、甲壳越深、甲片/尖刺/角越多。

输出: GameIame/bugs/bug_t1.png .. bug_t4.png
"""

import math
import pathlib

from PIL import Image, ImageDraw, ImageFilter

OUT = pathlib.Path(r"D:\aigame\GameIame\bugs")
S = 96          # 最终尺寸
K = 5           # 超采样倍数
C = S * K


def canvas():
    return Image.new("RGBA", (C, C), (0, 0, 0, 0))


def draw_bug(tier, size_ratio, body_color, accent, spots=0, plates=0, spikes=0,
             horn=False, glow_eye=False):
    img = canvas()
    d = ImageDraw.Draw(img)
    cx, cy = C / 2, C / 2
    R = C / 2 * size_ratio

    body_rx, body_ry = R * 0.62, R * 0.78
    head_r = R * 0.30
    head_y = cy - body_ry * 0.85

    outline = (18, 12, 12, 255)
    leg = (170, 174, 178, 255)
    leg_dark = (60, 64, 68, 255)

    # --- 腿：每侧 3 条，带关节 ---
    for side in (-1, 1):
        for i in range(3):
            base_y = cy - body_ry * 0.25 + i * body_ry * 0.45
            knee_x = cx + side * (body_rx * 1.05 + R * 0.05)
            knee_y = base_y - R * 0.10
            foot_x = cx + side * (body_rx * 1.45 + R * 0.10)
            foot_y = base_y + R * 0.28
            d.line([(cx + side * body_rx * 0.7, base_y), (knee_x, knee_y)],
                   fill=leg_dark, width=int(R * 0.10))
            d.line([(knee_x, knee_y), (foot_x, foot_y)], fill=leg_dark, width=int(R * 0.09))
            d.line([(cx + side * body_rx * 0.7, base_y), (knee_x, knee_y)],
                   fill=leg, width=max(1, int(R * 0.06)))
            d.line([(knee_x, knee_y), (foot_x, foot_y)], fill=leg, width=max(1, int(R * 0.05)))

    # --- 尖刺（高等级）---
    if spikes:
        for i in range(spikes):
            t = (i + 1) / (spikes + 1)
            y = cy - body_ry * 0.55 + t * body_ry * 1.1
            for side in (-1, 1):
                bx = cx + side * body_rx * 0.92
                tip = (cx + side * (body_rx * 1.55), y - R * 0.12)
                d.polygon([(bx, y - R * 0.08), (bx, y + R * 0.08), tip],
                          fill=outline)

    # --- 甲壳主体 ---
    d.ellipse([cx - body_rx, cy - body_ry, cx + body_rx, cy + body_ry],
              fill=body_color, outline=outline, width=max(1, int(R * 0.07)))

    # 甲壳缝
    d.line([(cx, cy - body_ry * 0.55), (cx, cy + body_ry * 0.82)],
           fill=outline, width=max(1, int(R * 0.05)))

    # --- 斑纹 / 甲片 ---
    for i in range(spots):
        sx = cx + (body_rx * 0.45 if i % 2 == 0 else -body_rx * 0.45)
        sy = cy - body_ry * 0.25 + (i // 2) * body_ry * 0.45
        rr = R * 0.12
        d.ellipse([sx - rr, sy - rr, sx + rr, sy + rr], fill=accent, outline=outline,
                  width=max(1, int(R * 0.03)))

    for i in range(plates):
        t = (i + 1) / (plates + 1)
        y = cy - body_ry * 0.5 + t * body_ry
        d.arc([cx - body_rx * 0.92, y - body_ry * 0.28,
               cx + body_rx * 0.92, y + body_ry * 0.28],
              start=200, end=340, fill=outline, width=max(1, int(R * 0.055)))

    # --- 头 ---
    d.ellipse([cx - head_r, head_y - head_r, cx + head_r, head_y + head_r],
              fill=body_color, outline=outline, width=max(1, int(R * 0.07)))

    # 触角
    for side in (-1, 1):
        d.line([(cx + side * head_r * 0.5, head_y - head_r * 0.7),
                (cx + side * head_r * 1.6, head_y - head_r * 1.9)],
               fill=outline, width=max(1, int(R * 0.045)))

    # 角（虫王）
    if horn:
        d.polygon([(cx - head_r * 0.42, head_y - head_r * 0.55),
                   (cx + head_r * 0.42, head_y - head_r * 0.55),
                   (cx, head_y - head_r * 2.4)], fill=outline)

    # 眼睛
    eye_r = head_r * 0.30
    for side in (-1, 1):
        ex = cx + side * head_r * 0.42
        ey = head_y + head_r * 0.10
        if glow_eye:
            glow = Image.new("RGBA", (C, C), (0, 0, 0, 0))
            gd = ImageDraw.Draw(glow)
            gr = eye_r * 2.6
            gd.ellipse([ex - gr, ey - gr, ex + gr, ey + gr], fill=(255, 40, 30, 90))
            glow = glow.filter(ImageFilter.GaussianBlur(C * 0.012))
            img.alpha_composite(glow)
            d = ImageDraw.Draw(img)
        d.ellipse([ex - eye_r, ey - eye_r, ex + eye_r, ey + eye_r],
                  fill=(255, 60, 50, 255) if glow_eye else accent,
                  outline=outline, width=max(1, int(R * 0.035)))
        # 高光
        hr = eye_r * 0.35
        d.ellipse([ex - hr * 1.6, ey - hr * 1.9, ex + hr * 0.2, ey - hr * 0.1],
                  fill=(255, 240, 235, 230))

    return img.resize((S, S), Image.LANCZOS)


def main():
    specs = [
        # tier, 体型占比, 甲壳色, 眼/斑纹色, 斑点数, 甲片数, 尖刺数, 角, 发光眼
        (1, 0.62, (122, 74, 47, 255), (255, 214, 120, 255), 0, 0, 0, False, False),
        (2, 0.74, (143, 47, 34, 255), (255, 190, 90, 255), 4, 0, 0, False, False),
        (3, 0.86, (90, 20, 16, 255), (255, 120, 60, 255), 0, 3, 4, False, False),
        (4, 1.00, (42, 10, 20, 255), (255, 60, 50, 255), 0, 4, 6, True, True),
    ]
    for tier, ratio, body, accent, spots, plates, spikes, horn, glow in specs:
        img = draw_bug(tier, ratio, body, accent, spots, plates, spikes, horn, glow)
        path = OUT / f"bug_t{tier}.png"
        img.save(path)
        print("saved", path)


if __name__ == "__main__":
    main()
