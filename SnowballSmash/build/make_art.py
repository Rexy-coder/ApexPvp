"""Snowball Smash - draws the game icon (512x512) and thumbnail (1920x1080).

Run:  python3 build/make_art.py <fonts dir> <output dir>
Needs Pillow + numpy and the free Google fonts Luckiest Guy and Fredoka.
"""
import math
import random
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

FONTS = sys.argv[1] if len(sys.argv) > 1 else "fonts"
OUT = sys.argv[2] if len(sys.argv) > 2 else "art"
TITLE_FONT = f"{FONTS}/Luckiest.ttf"
ROUND_FONT = f"{FONTS}/Fredoka.ttf"

OUTLINE = (22, 30, 70)


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(len(a)))


def vgradient(w, h, top, bottom):
    t = np.linspace(0, 1, h)[:, None, None]
    arr = np.array(top)[None, None, :] * (1 - t) + np.array(bottom)[None, None, :] * t
    arr = np.repeat(arr, w, axis=1)
    return Image.fromarray(arr.astype(np.uint8), "RGB")


def rays(img, center, count, color, alpha, spin=0):
    w, h = img.size
    layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    r = max(w, h) * 1.5
    for i in range(count):
        a0 = spin + i * 2 * math.pi / count
        a1 = a0 + math.pi / count
        d.polygon([center, (center[0] + r * math.cos(a0), center[1] + r * math.sin(a0)),
                   (center[0] + r * math.cos(a1), center[1] + r * math.sin(a1))], fill=color + (alpha,))
    img.alpha_composite(layer)


def shaded_ball(size, base, light, dark, rim=None):
    """Sphere with soft shading, as RGBA."""
    yy, xx = np.mgrid[0:size, 0:size].astype(np.float32)
    c = (size - 1) / 2
    nx, ny = (xx - c) / c, (yy - c) / c
    r2 = nx * nx + ny * ny
    inside = r2 <= 1
    nz = np.sqrt(np.clip(1 - r2, 0, 1))
    lx, ly, lz = -0.45, -0.6, 0.66
    lam = np.clip(nx * lx + ny * ly + nz * lz, 0, 1)
    base, light, dark = (np.array(v, np.float32) for v in (base, light, dark))
    col = dark[None, None] + (base - dark)[None, None] * np.clip(lam * 1.6, 0, 1)[..., None]
    spec = np.clip((lam - 0.82) * 6, 0, 1)[..., None]
    col = col * (1 - spec) + light[None, None] * spec
    if rim is not None:
        edge = np.clip((np.sqrt(r2) - 0.86) * 7, 0, 1)[..., None] * (ny > 0.1)[..., None]
        col = col * (1 - edge * 0.5) + np.array(rim, np.float32)[None, None] * edge * 0.5
    alpha = np.clip((1 - np.sqrt(r2)) * c * 1.5, 0, 1) * 255
    out = np.dstack([np.clip(col, 0, 255), alpha]).astype(np.uint8)
    out[~inside, 3] = 0
    return Image.fromarray(out, "RGBA")


def paste_center(img, sprite, center):
    img.alpha_composite(sprite, (int(center[0] - sprite.width / 2), int(center[1] - sprite.height / 2)))


def outlined_circle(img, center, radius, fill, width, outline=OUTLINE):
    d = ImageDraw.Draw(img)
    x, y = center
    d.ellipse([x - radius - width, y - radius - width, x + radius + width, y + radius + width], fill=outline)
    if isinstance(fill, Image.Image):
        paste_center(img, fill, center)
    else:
        d.ellipse([x - radius, y - radius, x + radius, y + radius], fill=fill)


def starburst(img, center, r_out, r_in, points, fill, outline=OUTLINE, width=0, rot=0):
    d = ImageDraw.Draw(img)
    pts = []
    for i in range(points * 2):
        r = r_out if i % 2 == 0 else r_in
        a = rot + i * math.pi / points
        pts.append((center[0] + r * math.cos(a), center[1] + r * math.sin(a)))
    if width:
        d.polygon(pts, fill=outline)
        pts2 = []
        for i in range(points * 2):
            r = (r_out if i % 2 == 0 else r_in) - width * 1.6
            a = rot + i * math.pi / points
            pts2.append((center[0] + r * math.cos(a), center[1] + r * math.sin(a)))
        d.polygon(pts2, fill=fill)
    else:
        d.polygon(pts, fill=fill)


def coin(img, center, r, tilt=1.0, rot=0):
    """Gold coin with a star, seen at an angle (tilt squashes it)."""
    s = int(r * 2.6)
    layer = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    c = s / 2
    w = r * tilt
    o = max(3, r * 0.14)
    d.ellipse([c - w - o, c - r - o, c + w + o, c + r + o], fill=OUTLINE)
    d.ellipse([c - w, c - r, c + w, c + r], fill=(240, 160, 20))
    d.ellipse([c - w * 0.86, c - r * 0.86, c + w * 0.86, c + r * 0.86], fill=(255, 205, 45))
    d.ellipse([c - w * 0.66, c - r * 0.66, c + w * 0.66, c + r * 0.66], fill=(236, 156, 22))
    pts = []
    for i in range(10):
        rr = r * (0.5 if i % 2 == 0 else 0.22)
        a = -math.pi / 2 + i * math.pi / 5
        pts.append((c + rr * math.cos(a) * tilt, c + rr * math.sin(a)))
    d.polygon(pts, fill=(255, 240, 150))
    d.ellipse([c - w * 0.55, c - r * 0.8, c - w * 0.2, c - r * 0.45], fill=(255, 250, 210))
    layer = layer.rotate(rot, resample=Image.BICUBIC)
    paste_center(img, layer, center)


def snowball(img, center, r, face=True, angry=False):
    paste_center(img, Image.new("RGBA", (1, 1)), center)
    d = ImageDraw.Draw(img)
    o = r * 0.07
    d.ellipse([center[0] - r - o, center[1] - r - o, center[0] + r + o, center[1] + r + o], fill=OUTLINE)
    ball = shaded_ball(int(r * 2), (240, 247, 255), (255, 255, 255), (150, 185, 230), rim=(190, 225, 255))
    paste_center(img, ball, center)
    # snow clumps
    rnd = random.Random(3)
    for _ in range(9):
        a = rnd.uniform(0, 2 * math.pi)
        dist = rnd.uniform(0.25, 0.8) * r
        cr = rnd.uniform(0.09, 0.16) * r
        cx, cy = center[0] + math.cos(a) * dist, center[1] + math.sin(a) * dist
        clump = shaded_ball(int(cr * 2), (232, 242, 255), (255, 255, 255), (170, 200, 240))
        paste_center(img, clump, (cx, cy))
    if face:
        ex, ey = center[0] + r * 0.18, center[1] - r * 0.12
        for dx in (-0.32, 0.18):
            x = ex + dx * r
            d.ellipse([x - r * 0.13, ey - r * 0.17, x + r * 0.13, ey + r * 0.17], fill=OUTLINE)
            d.ellipse([x - r * 0.04, ey - r * 0.11, x + r * 0.05, ey - r * 0.01], fill=(255, 255, 255))
        if angry:
            d.line([ex - 0.48 * r, ey - 0.33 * r, ex - 0.16 * r, ey - 0.2 * r], fill=OUTLINE, width=int(r * 0.08))
            d.line([ex + 0.02 * r, ey - 0.2 * r, ex + 0.34 * r, ey - 0.33 * r], fill=OUTLINE, width=int(r * 0.08))
        # big grin
        mx, my = ex - r * 0.05, center[1] + r * 0.25
        d.chord([mx - r * 0.38, my - r * 0.28, mx + r * 0.38, my + r * 0.28], 0, 180, fill=OUTLINE)
        d.chord([mx - r * 0.3, my - r * 0.2, mx + r * 0.3, my + r * 0.2], 0, 180, fill=(220, 60, 80))
        d.rectangle([mx - r * 0.27, my, mx + r * 0.27, my + r * 0.07], fill=(255, 255, 255))
        # cheeks
        for dx in (-0.55, 0.42):
            d.ellipse([ex + dx * r - r * 0.09, my - r * 0.12, ex + dx * r + r * 0.09, my - r * 0.03], fill=(255, 170, 190))


def block(img, center, size, color, rot, outline=OUTLINE, width=6):
    s = int(size * 1.8)
    layer = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    c = s / 2
    h = size / 2
    d.rectangle([c - h - width, c - h - width, c + h + width, c + h + width], fill=outline)
    d.rectangle([c - h, c - h, c + h, c + h], fill=color)
    d.rectangle([c - h, c - h, c + h, c - h * 0.55], fill=lerp(color, (255, 255, 255), 0.3))
    d.ellipse([c - h * 0.3, c - h * 0.3, c + h * 0.3, c + h * 0.3], fill=lerp(color, (255, 255, 255), 0.18))
    layer = layer.rotate(rot, resample=Image.BICUBIC)
    paste_center(img, layer, center)


def plank(img, center, length, thick, color, rot, width=6):
    s = int(length * 1.5)
    layer = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    c = s / 2
    d.rounded_rectangle([c - length / 2 - width, c - thick / 2 - width, c + length / 2 + width, c + thick / 2 + width], radius=thick / 3, fill=OUTLINE)
    d.rounded_rectangle([c - length / 2, c - thick / 2, c + length / 2, c + thick / 2], radius=thick / 4, fill=color)
    d.line([c - length / 2 + 8, c, c + length / 2 - 8, c], fill=lerp(color, (0, 0, 0), 0.25), width=max(2, int(thick / 8)))
    layer = layer.rotate(rot, resample=Image.BICUBIC)
    paste_center(img, layer, center)


def snow_puff(img, center, r, count, seed):
    rnd = random.Random(seed)
    for _ in range(count):
        a = rnd.uniform(0, 2 * math.pi)
        dist = rnd.uniform(0, 1) * r
        pr = rnd.uniform(0.12, 0.3) * r
        p = (center[0] + math.cos(a) * dist, center[1] + math.sin(a) * dist * 0.7)
        paste_center(img, shaded_ball(int(pr * 2), (245, 250, 255), (255, 255, 255), (190, 215, 245)), p)


def flakes(img, count, seed, box, rmin, rmax):
    rnd = random.Random(seed)
    d = ImageDraw.Draw(img)
    for _ in range(count):
        x, y = rnd.uniform(box[0], box[2]), rnd.uniform(box[1], box[3])
        r = rnd.uniform(rmin, rmax)
        d.ellipse([x - r, y - r, x + r, y + r], fill=(255, 255, 255, rnd.randint(150, 255)))


def speed_lines(img, origin, direction, count, seed, length, spread, width):
    rnd = random.Random(seed)
    layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    dx, dy = direction
    px, py = -dy, dx
    for _ in range(count):
        off = rnd.uniform(-spread, spread)
        start = rnd.uniform(0, length * 0.4)
        L = rnd.uniform(length * 0.4, length)
        x0 = origin[0] + px * off + dx * start
        y0 = origin[1] + py * off + dy * start
        d.line([x0, y0, x0 + dx * L, y0 + dy * L], fill=(255, 255, 255, rnd.randint(120, 220)), width=int(rnd.uniform(width * 0.5, width)))
    img.alpha_composite(layer)


def title_text(img, text, font_path, size, center, rot=0, top=(255, 245, 140), bottom=(255, 170, 20),
               outline=OUTLINE, stroke=None, shadow=True):
    font = ImageFont.truetype(font_path, size)
    stroke = stroke if stroke is not None else max(4, size // 9)
    bbox = font.getbbox(text, stroke_width=stroke)
    w, h = bbox[2] - bbox[0] + stroke * 4, bbox[3] - bbox[1] + stroke * 4
    pad = stroke * 2
    ox, oy = -bbox[0] + pad, -bbox[1] + pad
    layer = Image.new("RGBA", (w + pad * 2, h + pad * 2), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    if shadow:
        d.text((ox + stroke * 0.5, oy + stroke * 1.1), text, font=font, fill=outline, stroke_width=stroke, stroke_fill=outline)
    d.text((ox, oy), text, font=font, fill=outline, stroke_width=stroke, stroke_fill=outline)
    mask = Image.new("L", layer.size, 0)
    ImageDraw.Draw(mask).text((ox, oy), text, font=font, fill=255)
    grad = vgradient(layer.width, layer.height, top, bottom).convert("RGBA")
    # text-height based gradient
    t0, t1 = oy + bbox[1], oy + bbox[3]
    grad = vgradient(layer.width, max(1, int(t1 - t0)), top, bottom)
    full = Image.new("RGB", layer.size, bottom)
    full.paste(Image.new("RGB", (layer.width, int(t0)), top), (0, 0))
    full.paste(grad, (0, int(t0)))
    layer.paste(full, (0, 0), mask)
    # glossy highlight on the top part of the letters
    hl = Image.new("L", layer.size, 0)
    hd = ImageDraw.Draw(hl)
    hd.rectangle([0, 0, layer.width, t0 + (t1 - t0) * 0.42], fill=70)
    hl = Image.fromarray((np.array(hl, np.uint16) * np.array(mask, np.uint16) // 255).astype(np.uint8))
    layer.paste(Image.new("RGB", layer.size, (255, 255, 255)), (0, 0), hl)
    layer = layer.rotate(rot, resample=Image.BICUBIC, expand=True)
    paste_center(img, layer, center)


def tag(img, text, center, size, fill, rot=0):
    font = ImageFont.truetype(TITLE_FONT, size)
    bbox = font.getbbox(text)
    tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
    pw, ph = tw + size * 0.9, th + size * 0.7
    o = size * 0.12
    layer = Image.new("RGBA", (int(pw + o * 4), int(ph + o * 4)), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    d.rounded_rectangle([o, o * 1.6, pw + o * 3, ph + o * 3.4], radius=size * 0.35, fill=OUTLINE)
    d.rounded_rectangle([o * 2, o * 2, pw + o * 2, ph + o * 2], radius=size * 0.3, fill=fill)
    d.rounded_rectangle([o * 3, o * 2.5, pw + o, ph * 0.5], radius=size * 0.25, fill=lerp(fill, (255, 255, 255), 0.3))
    img.alpha_composite(layer.rotate(rot, resample=Image.BICUBIC, expand=True),
                        (int(center[0] - layer.width / 2), int(center[1] - layer.height / 2)))
    title_text(img, text, TITLE_FONT, size, (center[0], center[1] + size * 0.08), rot=rot,
               top=(255, 255, 255), bottom=(255, 255, 255), stroke=max(3, size // 10), shadow=False)


def snowman(img, base, s, rot=0):
    layer = Image.new("RGBA", (int(s * 3), int(s * 4.2)), (0, 0, 0, 0))
    c = (layer.width / 2, layer.height - s * 0.7)
    for r, y in ((0.62, 0), (0.46, -0.95), (0.34, -1.68)):
        outlined_circle(layer, (c[0], c[1] + y * s), r * s,
                        shaded_ball(int(r * s * 2), (240, 247, 255), (255, 255, 255), (160, 190, 230)), int(s * 0.05))
    d = ImageDraw.Draw(layer)
    hy = c[1] - 1.68 * s
    d.polygon([(c[0] + s * 0.05, hy), (c[0] + s * 0.5, hy + s * 0.08), (c[0] + s * 0.05, hy + s * 0.13)], fill=(255, 140, 30), outline=OUTLINE)
    for dx in (-0.12, 0.12):
        d.ellipse([c[0] + dx * s - s * 0.05, hy - s * 0.15, c[0] + dx * s + s * 0.05, hy - s * 0.05], fill=OUTLINE)
    d.rectangle([c[0] - s * 0.42, hy - s * 0.38, c[0] + s * 0.42, hy - s * 0.3], fill=OUTLINE)
    d.rectangle([c[0] - s * 0.26, hy - s * 0.85, c[0] + s * 0.26, hy - s * 0.36], fill=OUTLINE)
    d.rectangle([c[0] - s * 0.2, hy - s * 0.45, c[0] + s * 0.2, hy - s * 0.38], fill=(220, 50, 60))
    d.rounded_rectangle([c[0] - s * 0.48, c[1] - 1.32 * s, c[0] + s * 0.48, c[1] - 1.16 * s], radius=s * 0.06, fill=(230, 52, 60), outline=OUTLINE, width=int(s * 0.03))
    layer = layer.rotate(rot, resample=Image.BICUBIC, expand=True)
    img.alpha_composite(layer, (int(base[0] - layer.width / 2), int(base[1] - layer.height + s * 0.4)))


def pine(img, base, s):
    d = ImageDraw.Draw(img)
    d.rectangle([base[0] - s * 0.12, base[1] - s * 0.6, base[0] + s * 0.12, base[1]], fill=(120, 76, 44), outline=OUTLINE, width=max(2, int(s * 0.04)))
    for i, (w, y) in enumerate(((1.0, 0.45), (0.8, 1.05), (0.58, 1.6), (0.36, 2.1))):
        pts = [(base[0] - w * s, base[1] - y * s), (base[0] + w * s, base[1] - y * s), (base[0], base[1] - (y + 0.85) * s)]
        d.polygon(pts, fill=(46, 150, 84) if i % 2 == 0 else (34, 128, 74), outline=OUTLINE, width=max(2, int(s * 0.04)))
        d.polygon([(base[0] - w * s * 0.55, base[1] - (y + 0.38) * s), (base[0] + w * s * 0.55, base[1] - (y + 0.38) * s),
                   (base[0], base[1] - (y + 0.85) * s)], fill=(245, 250, 255))


def mountains(img, horizon, seed, color, snow, count, height):
    rnd = random.Random(seed)
    d = ImageDraw.Draw(img)
    w = img.width
    for _ in range(count):
        x = rnd.uniform(-0.1, 1.1) * w
        hw = rnd.uniform(0.12, 0.25) * w
        hh = rnd.uniform(0.6, 1.0) * height
        d.polygon([(x - hw, horizon), (x + hw, horizon), (x, horizon - hh)], fill=color)
        d.polygon([(x - hw * 0.3, horizon - hh * 0.7), (x + hw * 0.3, horizon - hh * 0.7), (x, horizon - hh)], fill=snow)


def checker_slope(img, poly_top_y, colors, tile, seed=0):
    """Snowy ground below a curve, with a big checker pattern like the game."""
    w, h = img.size
    yy, xx = np.mgrid[0:h, 0:w]
    u = (xx * 0.85 + yy * 1.1) // tile
    v = (xx * -0.6 + yy * 1.3) // tile
    chk = ((u + v) % 2).astype(bool)
    a = np.array(colors[0], np.uint8)
    b = np.array(colors[1], np.uint8)
    arr = np.where(chk[..., None], a, b)
    ground = Image.fromarray(arr.astype(np.uint8), "RGB").convert("RGBA")
    mask = Image.new("L", img.size, 0)
    ImageDraw.Draw(mask).polygon(poly_top_y, fill=255)
    img.paste(ground, (0, 0), mask)
    ImageDraw.Draw(img).line(poly_top_y[:-2], fill=(255, 255, 255), width=int(tile * 0.12))


def finish(img, size):
    return img.resize(size, Image.LANCZOS).convert("RGB")


# ----------------------------------------------------------------------
# ICON 512x512 (drawn at 2x)
# ----------------------------------------------------------------------
def make_icon():
    S = 1024
    img = vgradient(S, S, (90, 200, 255), (30, 110, 230)).convert("RGBA")
    rays(img, (560, 470), 18, (255, 255, 255), 38, spin=0.1)
    # ground
    checker_slope(img, [(0, 760), (300, 700), (700, 640), (S, 600), (S, S), (0, S)], [(244, 249, 255), (214, 232, 252)], 120)
    flakes(img, 60, 7, (0, 0, S, 640), 3, 7)
    # impact burst behind the hit
    starburst(img, (760, 520), 300, 170, 14, (255, 214, 60), width=10, rot=0.2)
    starburst(img, (760, 520), 190, 110, 12, (255, 250, 200), rot=0.5)
    # snowman flying apart
    for c, r in (((830, 380), 70), ((900, 560), 58), ((760, 300), 46)):
        outlined_circle(img, c, r, shaded_ball(int(r * 2), (240, 247, 255), (255, 255, 255), (160, 190, 230)), 7)
    d = ImageDraw.Draw(img)
    d.rectangle([700, 180, 790, 260], fill=OUTLINE)
    d.rectangle([675, 255, 815, 275], fill=OUTLINE)
    d.polygon([(905, 330), (990, 318), (912, 352)], fill=(255, 140, 30), outline=OUTLINE)
    plank(img, (930, 700), 170, 34, (176, 112, 64), -30)
    plank(img, (650, 210), 130, 28, (150, 92, 52), 40)
    block(img, (960, 450), 70, (120, 200, 255), 20)
    block(img, (870, 250), 54, (230, 60, 70), -15)
    snow_puff(img, (690, 600), 150, 18, 4)
    # speed lines + the hero snowball
    speed_lines(img, (380, 560), (-0.86, 0.5), 22, 2, 520, 230, 14)
    snowball(img, (430, 545), 285, face=True, angry=True)
    # coins
    coin(img, (170, 250), 62, 0.85, 15)
    coin(img, (300, 140), 46, 0.45, -10)
    coin(img, (930, 830), 56, 0.7, 20)
    coin(img, (110, 470), 40, 0.3, 0)
    # title
    title_text(img, "SNOWBALL", TITLE_FONT, 150, (512, 820), rot=4, top=(255, 255, 255), bottom=(170, 225, 255))
    title_text(img, "SMASH!", TITLE_FONT, 190, (530, 940), rot=4)
    return finish(img, (512, 512))


# ----------------------------------------------------------------------
# THUMBNAIL 1920x1080 (drawn at 1.5x)
# ----------------------------------------------------------------------
def make_thumbnail():
    W, H = 2880, 1620
    img = vgradient(W, H, (110, 210, 255), (40, 130, 235)).convert("RGBA")
    rays(img, (1850, 820), 24, (255, 255, 255), 30, spin=0.05)
    # clouds
    rnd = random.Random(11)
    for _ in range(9):
        cx, cy = rnd.uniform(0, W), rnd.uniform(60, 420)
        for _ in range(5):
            r = rnd.uniform(60, 120)
            ox = rnd.uniform(-120, 120)
            ImageDraw.Draw(img).ellipse([cx + ox - r, cy - r * 0.7, cx + ox + r, cy + r * 0.7], fill=(255, 255, 255, 235))
    mountains(img, 900, 5, (150, 175, 220), (245, 250, 255), 9, 520)
    mountains(img, 960, 9, (120, 150, 205), (240, 248, 255), 7, 380)
    # slope
    checker_slope(img, [(0, 1030), (900, 930), (1900, 860), (W, 820), (W, H), (0, H)], [(244, 249, 255), (212, 230, 252)], 170)
    # candy-cane rail along the slope edge
    d = ImageDraw.Draw(img)
    for i in range(30):
        x0 = i * 110
        y0 = 1030 - (x0 / W) * 210 + 40
        d.line([x0, y0, x0 + 110, y0 - 110 / W * 210], fill=(230, 52, 60) if i % 2 else (255, 255, 255), width=34)
    # trees in the distance
    for x, y, s in ((300, 1000, 90), (520, 975, 75), (2600, 840, 100), (2420, 860, 80), (160, 1040, 110)):
        pine(img, (x, y), s)
    flakes(img, 140, 3, (0, 0, W, 900), 4, 10)

    # cabin getting smashed on the right
    starburst(img, (2050, 900), 520, 300, 16, (255, 214, 60), width=14, rot=0.15)
    starburst(img, (2050, 900), 330, 200, 14, (255, 250, 200), rot=0.4)
    for i, (x, y, r) in enumerate(((2350, 620, -35), (2480, 860, 25), (2250, 420, 60), (2560, 560, -10), (2150, 1180, 70), (2420, 1080, -50))):
        plank(img, (x, y), 260, 52, (176, 112, 64) if i % 2 else (140, 88, 52), r, width=8)
    block(img, (2650, 380), 120, (200, 50, 55), 25, width=8)
    block(img, (2300, 280), 90, (200, 50, 55), -20, width=8)
    block(img, (2700, 760), 100, (255, 220, 120), 10, width=8)
    snowman(img, (2620, 1260), 170, rot=-28)
    snow_puff(img, (1900, 1080), 300, 26, 8)

    # the hero snowball
    speed_lines(img, (1100, 980), (-0.92, 0.38), 40, 4, 1300, 430, 22)
    snowball(img, (1250, 900), 470, face=True, angry=True)
    snow_puff(img, (1150, 1380), 260, 20, 12)

    # coins bursting out
    for x, y, r, t, rot in ((1900, 420, 70, 0.8, 10), (2150, 250, 55, 0.4, -20), (2700, 1050, 80, 0.9, 15),
                            (1700, 620, 50, 0.3, 0), (2420, 1400, 60, 0.6, -10), (900, 300, 60, 0.7, 20), (650, 520, 44, 0.35, 0)):
        coin(img, (x, y), r, t, rot)

    # UI-style callouts like the game
    tag(img, "x5", (1870, 600), 110, (255, 92, 196), rot=-8)
    title_text(img, "CRITICAL!", TITLE_FONT, 130, (2400, 200), rot=-6, top=(255, 240, 90), bottom=(255, 110, 30))
    title_text(img, "+12,500", TITLE_FONT, 110, (2150, 760), rot=5, top=(255, 255, 160), bottom=(255, 200, 40))

    # title
    title_text(img, "SNOWBALL", TITLE_FONT, 235, (790, 265), rot=-5, top=(255, 255, 255), bottom=(160, 220, 255))
    title_text(img, "SMASH!", TITLE_FONT, 300, (820, 490), rot=-5)
    return finish(img, (1920, 1080))


if __name__ == "__main__":
    import os

    os.makedirs(OUT, exist_ok=True)
    make_icon().save(f"{OUT}/icon_512.png")
    make_thumbnail().save(f"{OUT}/thumbnail_1920x1080.png")
    print("saved to", OUT)
