"""Snowball Smash - draws the 512x512 icons for every game pass and developer product.

Run:  python3 build/make_shop_icons.py <fonts dir> <emoji dir> <output dir>
Emoji art: Microsoft Fluent Emoji 3D (MIT licence), from the @lobehub/fluent-emoji-3d npm package.
"""
import math
import os
import random
import sys

from PIL import Image, ImageDraw, ImageFilter, ImageFont

sys.argv += [None] * 4
FONTS = sys.argv[1] or "fonts"
EMOJI = sys.argv[2] or "emoji"
OUT = sys.argv[3] or "docs/shop-icons"
sys.argv = [sys.argv[0], FONTS, OUT]  # make_art reads argv on import
sys.path.insert(0, os.path.dirname(__file__))
import make_art as art  # noqa: E402

S = 1024  # drawn at 2x, saved at 512
OUTLINE = (20, 28, 64)
TITLE = f"{FONTS}/Luckiest.ttf"


def emoji(code, size, rot=0):
    im = Image.open(f"{EMOJI}/{code}.webp").convert("RGBA").resize((size, size), Image.LANCZOS)
    return im.rotate(rot, resample=Image.BICUBIC, expand=True) if rot else im


def with_shadow(sprite, offset=(0, 18), blur=14, alpha=110):
    pad = blur * 3
    out = Image.new("RGBA", (sprite.width + pad * 2, sprite.height + pad * 2 + offset[1]), (0, 0, 0, 0))
    sh = Image.new("RGBA", sprite.size, OUTLINE + (0,))
    sh.putalpha(sprite.getchannel("A").point(lambda a: a * alpha // 255))
    out.alpha_composite(sh, (pad + offset[0], pad + offset[1]))
    out = out.filter(ImageFilter.GaussianBlur(blur))
    out.alpha_composite(sprite, (pad, pad))
    return out


def place(img, sprite, center, shadow=True):
    if shadow:
        sprite = with_shadow(sprite)
    art.paste_center(img, sprite, center)


def card(bg_top, bg_bottom, stud):
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    m = 26
    radius = 150
    mask = Image.new("L", (S, S), 0)
    ImageDraw.Draw(mask).rounded_rectangle([m, m, S - m, S - m], radius=radius, fill=255)
    body = art.vgradient(S, S, bg_top, bg_bottom).convert("RGBA")
    # soft radial light behind the artwork
    glow = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    ImageDraw.Draw(glow).ellipse([S * 0.18, S * 0.12, S * 0.82, S * 0.76], fill=(255, 255, 255, 90))
    body.alpha_composite(glow.filter(ImageFilter.GaussianBlur(90)))
    # lego studs
    studs = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    sd = ImageDraw.Draw(studs)
    step = 92
    for y in range(-20, S, step):
        for x in range(-20, S, step):
            sd.ellipse([x + 14, y + 14, x + step - 14, y + step - 14], outline=stud + (120,), width=6, fill=stud + (45,))
    body.alpha_composite(studs)
    # frosty inner edge
    frost = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    ImageDraw.Draw(frost).rounded_rectangle([m + 6, m + 6, S - m - 6, S - m - 6], radius=radius - 6, outline=(235, 248, 255, 170), width=26)
    body.alpha_composite(frost.filter(ImageFilter.GaussianBlur(10)))
    img.paste(body, (0, 0), mask)
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([m, m, S - m, S - m], radius=radius, outline=OUTLINE, width=22)
    return img


def snow_cap(img, seed):
    """Snow piled on the top edge with icicle drips, outlined like the rest of the art."""
    rnd = random.Random(seed)
    top = 30
    pts = [(60, top + 30)]
    x = 60
    while x < S - 60:
        x += rnd.randint(50, 90)
        pts.append((min(x, S - 60), top + rnd.randint(60, 100)))
    pts += [(S - 60, top + 30), (S - 160, top - 5), (160, top - 5)]
    drips = []
    for px, py in pts[1:-3]:
        if rnd.random() < 0.5:
            drips.append((px, py, rnd.randint(30, 85)))

    def shape(d, fill, grow):
        d.polygon(pts, fill=fill)
        for px, py, length in drips:
            d.rounded_rectangle([px - 15 - grow, py - 20, px + 15 + grow, py + length + grow], radius=15 + grow, fill=fill)

    layer = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    shape(ImageDraw.Draw(layer), OUTLINE, 0)
    layer = layer.filter(ImageFilter.MaxFilter(13))
    snow = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    shape(ImageDraw.Draw(snow), (250, 253, 255), 0)
    # shading on the underside
    shade = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    ImageDraw.Draw(shade).rectangle([0, top + 40, S, top + 200], fill=(170, 205, 245, 140))
    shade.putalpha(Image.composite(shade.getchannel("A"), Image.new("L", (S, S), 0), snow.getchannel("A")))
    snow.alpha_composite(shade.filter(ImageFilter.GaussianBlur(8)))
    # keep the cap inside the card's rounded corners
    clip = Image.new("L", (S, S), 0)
    ImageDraw.Draw(clip).rounded_rectangle([0, 0, S, S], radius=170, fill=255)
    for lay in (layer, snow):
        lay.putalpha(Image.composite(lay.getchannel("A"), Image.new("L", (S, S), 0), clip))
    img.alpha_composite(layer)
    img.alpha_composite(snow)


def flakes(img, seed, count=26):
    rnd = random.Random(seed)
    d = ImageDraw.Draw(img)
    for _ in range(count):
        x, y = rnd.uniform(80, S - 80), rnd.uniform(170, S - 260)
        r = rnd.uniform(4, 10)
        d.ellipse([x - r, y - r, x + r, y + r], fill=(255, 255, 255, rnd.randint(170, 240)))


def fit_title(img, text, center, max_w, size, top, bottom):
    while size > 40:
        f = ImageFont.truetype(TITLE, size)
        b = f.getbbox(text, stroke_width=size // 8)
        if b[2] - b[0] <= max_w:
            break
        size -= 6
    art.title_text(img, text, TITLE, size, center, top=top, bottom=bottom, outline=OUTLINE, stroke=max(10, size // 7))


def badge(img, text, color=(235, 50, 60)):
    f = ImageFont.truetype(TITLE, 74)
    b = f.getbbox(text)
    w, h = b[2] - b[0] + 70, 112
    x1, y0 = S - 50, 60
    x0 = x1 - w
    layer = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    d.rounded_rectangle([x0 - 10, y0 - 8, x1 + 10, y0 + h + 14], radius=40, fill=OUTLINE)
    d.rounded_rectangle([x0, y0, x1, y0 + h], radius=34, fill=color)
    d.rounded_rectangle([x0 + 12, y0 + 8, x1 - 12, y0 + h * 0.45], radius=24, fill=art.lerp(color, (255, 255, 255), 0.3))
    layer = layer.rotate(-8, center=((x0 + x1) / 2, y0 + h / 2), resample=Image.BICUBIC)
    img.alpha_composite(layer)
    art.title_text(img, text, TITLE, 74, ((x0 + x1) / 2, y0 + h / 2 + 6), rot=8, top=(255, 255, 255),
                   bottom=(255, 255, 255), outline=OUTLINE, stroke=9, shadow=False)


def rainbow_ball(size):
    ball = art.shaded_ball(size, (255, 255, 255), (255, 255, 255), (150, 150, 170))
    import numpy as np
    arr = np.array(ball).astype(np.float32)
    h, w = arr.shape[:2]
    yy, xx = np.mgrid[0:h, 0:w]
    hue = ((xx + yy) / (w + h) * 1.4) % 1.0
    import colorsys
    lut = np.array([colorsys.hsv_to_rgb(i / 255, 0.65, 1) for i in range(256)]) * 255
    tint = lut[(hue * 255).astype(int)]
    arr[..., :3] = arr[..., :3] * tint / 255
    return Image.fromarray(arr.clip(0, 255).astype(np.uint8), "RGBA")


def outlined_sprite(sprite, width=14):
    a = sprite.getchannel("A").point(lambda v: 255 if v > 40 else 0).filter(ImageFilter.MaxFilter(width * 2 + 1))
    out = Image.new("RGBA", sprite.size, OUTLINE + (0,))
    out.putalpha(a)
    out.alpha_composite(sprite)
    return out


def snowball_sprite(r, rainbow=False):
    size = int(r * 2.4)
    layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    if rainbow:
        c = size / 2
        d = ImageDraw.Draw(layer)
        d.ellipse([c - r - 14, c - r - 14, c + r + 14, c + r + 14], fill=OUTLINE)
        art.paste_center(layer, rainbow_ball(int(r * 2)), (c, c))
    else:
        art.snowball(layer, (size / 2, size / 2), r, face=True, angry=True)
    return layer


ITEMS = [
    # key, background top, bottom, stud colour, title, title colours, badge
    ("VIP", (255, 222, 90), (235, 150, 20), (255, 245, 190), "VIP", ((255, 255, 210), (255, 205, 40)), "+25%"),
    ("DoubleCoins", (130, 235, 120), (40, 160, 70), (210, 255, 200), "2x COINS", ((255, 255, 255), (200, 255, 170)), "FOREVER"),
    ("PerfectPush", (120, 200, 255), (40, 110, 230), (210, 235, 255), "PERFECT PUSH", ((255, 255, 255), (190, 230, 255)), "MAX"),
    ("MegaStart", (170, 230, 255), (60, 150, 230), (230, 248, 255), "MEGA START", ((255, 255, 255), (190, 230, 255)), "+2 SIZE"),
    ("LuckyCharm", (140, 240, 150), (30, 150, 90), (215, 255, 215), "LUCKY", ((255, 255, 255), (190, 255, 190)), "+10%"),
    ("RainbowBall", (255, 160, 220), (150, 90, 240), (255, 225, 245), "RAINBOW", ((255, 255, 255), (255, 210, 245)), "+50%"),
    ("Turbo5", (255, 160, 90), (225, 60, 50), (255, 220, 190), "TURBO", ((255, 250, 170), (255, 190, 40)), "x5"),
    ("Turbo20", (255, 120, 90), (170, 30, 60), (255, 200, 190), "TURBO", ((255, 250, 170), (255, 170, 40)), "x20"),
    ("CoinsSmall", (255, 235, 120), (240, 170, 30), (255, 248, 200), "+2,500", ((255, 255, 210), (255, 210, 50)), None),
    ("CoinsMedium", (255, 225, 110), (230, 150, 25), (255, 245, 195), "+15,000", ((255, 255, 210), (255, 210, 50)), None),
    ("CoinsLarge", (255, 210, 100), (220, 125, 25), (255, 240, 190), "+60,000", ((255, 255, 210), (255, 210, 50)), None),
    ("CoinsHuge", (255, 195, 90), (205, 100, 30), (255, 235, 185), "+250,000", ((255, 255, 210), (255, 210, 50)), "BEST VALUE"),
    ("Boost15", (200, 160, 255), (110, 70, 220), (235, 220, 255), "2x COINS", ((255, 255, 255), (230, 210, 255)), "15 MIN"),
    ("Boost60", (185, 140, 255), (90, 50, 200), (230, 215, 255), "2x COINS", ((255, 255, 255), (230, 210, 255)), "1 HOUR"),
    ("ServerStorm", (130, 230, 255), (30, 130, 220), (215, 245, 255), "SERVER x2", ((255, 255, 255), (190, 240, 255)), "10 MIN"),
]


def artwork(img, key):
    C = (S / 2, S * 0.43)
    if key == "VIP":
        place(img, emoji("2728", 170), (250, 260))
        place(img, emoji("1f451", 470), C)
    elif key == "DoubleCoins":
        place(img, emoji("1fa99", 330, 18), (C[0] + 95, C[1] + 20))
        place(img, emoji("1fa99", 360, -12), (C[0] - 80, C[1] - 10))
        place(img, emoji("2728", 150), (790, 250))
    elif key == "PerfectPush":
        place(img, emoji("1f3af", 430), (C[0] - 20, C[1]))
        place(img, emoji("26a1", 240, -15), (C[0] + 190, C[1] + 70))
    elif key == "MegaStart":
        place(img, outlined_sprite(snowball_sprite(200)), C)
        place(img, emoji("2744-fe0f", 150, 15), (780, 270))
        place(img, emoji("2744-fe0f", 110, -10), (230, 590))
    elif key == "LuckyCharm":
        place(img, emoji("1f340", 440, -8), C)
        place(img, emoji("2728", 170), (780, 260))
    elif key == "RainbowBall":
        place(img, emoji("1f308", 380), (C[0], C[1] - 70), shadow=False)
        place(img, outlined_sprite(snowball_sprite(165, rainbow=True)), (C[0], C[1] + 60))
        place(img, emoji("2728", 140), (790, 330))
    elif key in ("Turbo5", "Turbo20"):
        if key == "Turbo20":
            place(img, emoji("1f525", 300, 10), (C[0] - 150, C[1] + 90))
        place(img, emoji("1f680", 440), C)
    elif key == "CoinsSmall":
        place(img, emoji("1fa99", 380, -10), C)
        place(img, emoji("2728", 160), (790, 260))
    elif key == "CoinsMedium":
        place(img, emoji("1fa99", 210, 20), (C[0] + 170, C[1] + 110))
        place(img, emoji("1f4b0", 420), (C[0] - 30, C[1]))
    elif key == "CoinsLarge":
        place(img, emoji("1f9f0", 400), (C[0], C[1] + 20))
        for (x, y, s, r) in ((C[0] - 160, C[1] - 110, 190, -15), (C[0] + 140, C[1] - 130, 210, 12), (C[0] + 10, C[1] - 170, 170, 0)):
            place(img, emoji("1fa99", s, r), (x, y))
    elif key == "CoinsHuge":
        place(img, emoji("1f3e6", 400), (C[0] - 40, C[1]))
        place(img, emoji("1f4b0", 230, -8), (C[0] + 170, C[1] + 90))
        place(img, emoji("1fa99", 170, 15), (C[0] - 200, C[1] + 120))
    elif key == "Boost15":
        place(img, emoji("23f1-fe0f", 400), (C[0] - 40, C[1]))
        place(img, emoji("1fa99", 220, 12), (C[0] + 170, C[1] + 100))
    elif key == "Boost60":
        place(img, emoji("231b", 400), (C[0] - 40, C[1]))
        place(img, emoji("1fa99", 220, 12), (C[0] + 170, C[1] + 100))
    elif key == "ServerStorm":
        place(img, emoji("1f32a-fe0f", 430), (C[0] - 20, C[1]))
        place(img, emoji("1fa99", 180, -20), (C[0] + 200, C[1] - 90))
        place(img, emoji("1fa99", 150, 20), (C[0] - 210, C[1] + 110))
        place(img, emoji("2744-fe0f", 110), (C[0] + 210, C[1] + 130))


def make(item, index):
    key, top, bottom, stud, title, tcol, badge_text = item
    img = card(top, bottom, stud)
    flakes(img, index * 7 + 1)
    artwork(img, key)
    snow_cap(img, index * 13 + 5)
    fit_title(img, title, (S / 2, S * 0.82), S - 170, 190, tcol[0], tcol[1])
    if badge_text:
        badge(img, badge_text)
    return img.resize((512, 512), Image.LANCZOS)


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    for i, item in enumerate(ITEMS):
        make(item, i).save(f"{OUT}/{item[0]}.png")
    # contact sheet
    sheet = Image.new("RGB", (5 * 260 + 20, 3 * 260 + 20), (40, 44, 60))
    for i, item in enumerate(ITEMS):
        im = Image.open(f"{OUT}/{item[0]}.png").resize((250, 250), Image.LANCZOS)
        sheet.paste(im, (15 + (i % 5) * 260, 15 + (i // 5) * 260), im)
    sheet.save(f"{OUT}/_all.png")
    print("saved", len(ITEMS), "icons to", OUT)
