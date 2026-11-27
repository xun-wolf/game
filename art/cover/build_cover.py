"""生成《田间风云》商店封面：分层源文件（ORA）+ 多尺寸导出。

用法：python build_cover.py
输入：raw/keyart_landscape.jpg、raw/keyart_portrait.jpg、GameIame/ui/splash_cn.png
输出：exports/*.png、layers/*.png、cover_source.ora
"""
import os
import zipfile
from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.abspath(__file__))
RAW = os.path.join(ROOT, "raw")
EXPORTS = os.path.join(ROOT, "exports")
LAYERS = os.path.join(ROOT, "layers")
SPLASH = os.path.join(ROOT, "..", "..", "GameIame", "ui", "splash_cn.png")
FONT = os.path.join(ROOT, "..", "..", "GameIame", "fonts", "SimHei.ttf")

GOLD = (232, 200, 122, 255)
PAPER = (242, 232, 208, 255)


def ensure_dirs():
    for d in (EXPORTS, LAYERS):
        os.makedirs(d, exist_ok=True)


def load_art(path, trim_bottom=0.07):
    img = Image.open(path).convert("RGB")
    w, h = img.size
    return img.crop((0, 0, w, int(h * (1 - trim_bottom))))


def cover_crop(img, size, focus=(0.5, 0.5)):
    tw, th = size
    ar = tw / th
    w, h = img.size
    if w / h > ar:
        nw = int(h * ar)
        x = int((w - nw) * focus[0])
        img = img.crop((x, 0, x + nw, h))
    else:
        nh = int(w / ar)
        y = int((h - nh) * focus[1])
        img = img.crop((0, y, w, y + nh))
    return img.resize(size, Image.LANCZOS)


def gradient_layer(size, stops):
    """stops: [(y_ratio, (r,g,b,a)), ...] 生成纵向渐变透明层。"""
    w, h = size
    layer = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    stops = sorted(stops, key=lambda s: s[0])
    for y in range(h):
        t = y / max(1, h - 1)
        prev, nxt = stops[0], stops[-1]
        for i in range(len(stops) - 1):
            if stops[i][0] <= t <= stops[i + 1][0]:
                prev, nxt = stops[i], stops[i + 1]
                break
        span = nxt[0] - prev[0]
        k = 0 if span == 0 else (t - prev[0]) / span
        c = tuple(int(prev[1][j] + (nxt[1][j] - prev[1][j]) * k) for j in range(4))
        draw.line([(0, y), (w, y)], fill=c)
    return layer


def extract_title():
    """从启动画提取标题字组，压掉深色底，保留金属字与朱印。"""
    splash = Image.open(SPLASH).convert("RGB")
    crop = splash.crop((590, 385, 1386, 656))
    w, h = crop.size
    src = crop.load()
    alpha = Image.new("L", crop.size, 0)
    dst = alpha.load()
    for y in range(h):
        for x in range(w):
            r, g, b = src[x, y]
            luma = 0.299 * r + 0.587 * g + 0.114 * b
            a = int(max(0, min(255, (luma - 32) * 255 / 120)))
            if r > 110 and r > g * 1.5 and r > b * 1.5:
                a = 255
            dst[x, y] = a
    title = crop.convert("RGBA")
    title.putalpha(alpha)
    bbox = title.getbbox()
    return title.crop(bbox)


def draw_text_layer(size, text, font_size, color, center_x=None, top=None,
                    letter_spacing=0):
    layer = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    font = ImageFont.truetype(FONT, font_size)
    shadow = (0, 0, 0, 170)

    def put(x, y, ch, fill):
        draw.text((x, y), ch, font=font, fill=fill)

    if letter_spacing:
        widths = [draw.textlength(ch, font=font) for ch in text]
        total = sum(widths) + letter_spacing * (len(text) - 1)
        x = (size[0] - total) / 2 if center_x is None else center_x - total / 2
        for ch, cw in zip(text, widths):
            put(x + 2, top + 2, ch, shadow)
        x = (size[0] - total) / 2 if center_x is None else center_x - total / 2
        for ch, cw in zip(text, widths):
            put(x, top, ch, color)
            x += cw + letter_spacing
    else:
        tw = draw.textlength(text, font=font)
        x = (size[0] - tw) / 2 if center_x is None else center_x - tw / 2
        put(x + 2, top + 2, text, shadow)
        put(x, top, text, color)
    return layer


def paste_center(canvas, layer, cy):
    x = int((canvas.size[0] - layer.size[0]) / 2)
    canvas.alpha_composite(layer, (x, int(cy - layer.size[1] / 2)))


def make_frame(size, inset=26, alpha=110):
    layer = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    draw.rectangle([inset, inset, size[0] - inset - 1, size[1] - inset - 1],
                   outline=(212, 178, 106, alpha), width=2)
    return layer


def compose_landscape(art, size, title_width, title_cy, subtitle_size,
                      tagline_size, frame=True):
    w, h = size
    bg = cover_crop(art, size, (0.5, 0.46)).convert("RGBA")
    atmos = gradient_layer(size, [
        (0.0, (6, 8, 6, 235)),
        (0.30, (6, 8, 6, 120)),
        (0.50, (0, 0, 0, 0)),
        (0.78, (0, 0, 0, 0)),
        (1.0, (6, 7, 5, 215)),
    ])
    base = Image.alpha_composite(bg, atmos)

    title = extract_title()
    ratio = title_width / title.size[0]
    title = title.resize((title_width, int(title.size[1] * ratio)), Image.LANCZOS)
    paste_center(base, title, title_cy)

    if subtitle_size > 0:
        sub_top = int(title_cy + title.size[1] / 2 + max(10, h * 0.014))
        sub = draw_text_layer(size, "二十四候 · 五档官品 · 卡牌种田",
                              subtitle_size, GOLD, top=sub_top,
                              letter_spacing=3)
        base.alpha_composite(sub)

    if tagline_size > 0:
        tag = draw_text_layer(size, "一亩田，二十四候，一场风云", tagline_size,
                              (238, 226, 198, 230), center_x=w * 0.20,
                              top=int(h * 0.925))
        base.alpha_composite(tag)
        eng = draw_text_layer(size, "FIELD CHRONICLES",
                              max(13, int(tagline_size * 0.62)),
                              (212, 190, 148, 190), center_x=w * 0.83,
                              top=int(h * 0.935), letter_spacing=4)
        base.alpha_composite(eng)

    if frame:
        base.alpha_composite(make_frame(size, inset=max(14, int(w * 0.013))))
    return base


def compose_portrait(art, size):
    w, h = size
    bg = cover_crop(art, size, (0.5, 0.42)).convert("RGBA")
    atmos = gradient_layer(size, [
        (0.0, (6, 8, 6, 240)),
        (0.30, (6, 8, 6, 140)),
        (0.46, (0, 0, 0, 0)),
        (0.80, (0, 0, 0, 0)),
        (1.0, (6, 7, 5, 210)),
    ])
    base = Image.alpha_composite(bg, atmos)

    title = extract_title()
    tw = int(w * 0.84)
    title = title.resize((tw, int(title.size[1] * tw / title.size[0])), Image.LANCZOS)
    title_cy = int(h * 0.15)
    paste_center(base, title, title_cy)

    sub = draw_text_layer(size, "二十四候 · 卡牌种田", int(w * 0.045), GOLD,
                          top=int(title_cy + title.size[1] / 2 + h * 0.024),
                          letter_spacing=2)
    base.alpha_composite(sub)
    base.alpha_composite(make_frame(size, inset=int(w * 0.035)))
    return base


def main():
    ensure_dirs()
    land = load_art(os.path.join(RAW, "keyart_landscape.jpg"))
    port = load_art(os.path.join(RAW, "keyart_portrait.jpg"))

    hero = compose_landscape(land, (1920, 1080), 880, 1080 * 0.175, 40, 26)
    hero.save(os.path.join(EXPORTS, "cover_1920x1080.png"))
    hero.resize((1280, 720), Image.LANCZOS).save(
        os.path.join(EXPORTS, "cover_1280x720.png"))

    social = compose_landscape(land, (1200, 630), 560, 630 * 0.175, 28, 20)
    social.save(os.path.join(EXPORTS, "social_1200x630.png"))

    capsule = compose_landscape(land, (616, 353), 340, 353 * 0.21, 18, 0, frame=True)
    capsule.save(os.path.join(EXPORTS, "capsule_616x353.png"))

    small = compose_landscape(land, (460, 215), 260, 215 * 0.25, 0, 0, frame=False)
    small.save(os.path.join(EXPORTS, "capsule_460x215.png"))

    mini = compose_landscape(land, (231, 87), 130, 87 * 0.30, 0, 0, frame=False)
    mini.save(os.path.join(EXPORTS, "capsule_231x87.png"))

    wide = compose_landscape(land, (1920, 620), 700, 620 * 0.22, 34, 20)
    wide.save(os.path.join(EXPORTS, "hero_1920x620.png"))

    portrait = compose_portrait(port, (600, 900))
    portrait.save(os.path.join(EXPORTS, "cover_600x900.png"))

    icon = cover_crop(load_art(os.path.join(RAW, "keyart_portrait.jpg"), 0.04),
                      (512, 512), (0.5, 0.55)).convert("RGBA")
    icon.save(os.path.join(EXPORTS, "icon_512x512.png"))

    # 分层源文件：把主视觉拆成可编辑图层，导出 OpenRaster（.ora）
    size = (1920, 1080)
    bg = cover_crop(land, size, (0.5, 0.46)).convert("RGBA")
    atmos = gradient_layer(size, [
        (0.0, (6, 8, 6, 225)), (0.34, (6, 8, 6, 90)),
        (0.52, (0, 0, 0, 0)), (0.78, (0, 0, 0, 0)), (1.0, (6, 7, 5, 215)),
    ])
    title = extract_title()
    tw = 1000
    title = title.resize((tw, int(title.size[1] * tw / title.size[0])), Image.LANCZOS)
    title_layer = Image.new("RGBA", size, (0, 0, 0, 0))
    title_layer.alpha_composite(title, (int((size[0] - tw) / 2),
                                        int(size[1] * 0.175 - title.size[1] / 2)))

    sub = draw_text_layer(size, "二十四候 · 五档官品 · 卡牌种田", 44, GOLD,
                          top=int(size[1] * 0.175 + title.size[1] / 2 + size[1] * 0.014),
                          letter_spacing=3)
    frame = make_frame(size)

    layers = [("背景", bg), ("氛围光", atmos), ("标题", title_layer),
              ("副标题", sub), ("描金边框", frame)]
    for name, img in layers:
        img.save(os.path.join(LAYERS, f"{name}.png"))

    stack = ['<?xml version="1.0" encoding="UTF-8"?>',
             '<image version="0.0.1" w="1920" h="1080">', '  <stack>']
    for name, _ in layers:
        stack.append(f'    <layer name="{name}" src="data/{name}.png" x="0" y="0" visibility="visible" opacity="1.0"/>')
    stack += ['  </stack>', '</image>']
    stack_xml = "\n".join(stack)

    ora_path = os.path.join(ROOT, "cover_source.ora")
    with zipfile.ZipFile(ora_path, "w", zipfile.ZIP_DEFLATED) as z:
        z.writestr("mimetype", "image/openraster", compress_type=zipfile.ZIP_STORED)
        z.writestr("stack.xml", stack_xml)
        for name, _ in layers:
            z.write(os.path.join(LAYERS, f"{name}.png"), f"data/{name}.png")
        z.write(os.path.join(EXPORTS, "cover_1920x1080.png"), "mergedimage.png")
        thumb = hero.copy()
        thumb.thumbnail((256, 256), Image.LANCZOS)
        thumb_path = os.path.join(LAYERS, "thumbnail.png")
        thumb.convert("RGB").save(thumb_path)
        z.write(thumb_path, "Thumbnails/thumbnail.png")

    print("done:", ora_path)


if __name__ == "__main__":
    main()
