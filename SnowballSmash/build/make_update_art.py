"""Update announcement picture ("SPOOKY SNOW UPDATE") built on the game thumbnail.

Run:  python3 build/make_update_art.py <fonts dir> <emoji dir> [output]
Emoji art: Microsoft Fluent Emoji 3D (MIT licence), from the @lobehub/fluent-emoji-3d npm package.
"""
import os
import sys

from PIL import Image, ImageDraw, ImageFilter, ImageFont

FONTS = sys.argv[1] if len(sys.argv) > 1 else "fonts"
EMOJI = sys.argv[2] if len(sys.argv) > 2 else "emoji"
OUT = sys.argv[3] if len(sys.argv) > 3 else "docs/art/update_spooky_snow.png"
sys.argv = [sys.argv[0], FONTS, "docs/art"]
sys.path.insert(0, os.path.dirname(__file__))
import make_art as art  # noqa: E402

W, H = 1920, 1080
OUTLINE = (20, 12, 40)


def emoji(code, size, rot=0):
    im = Image.open(f"{EMOJI}/{code}.webp").convert("RGBA").resize((size, size), Image.LANCZOS)
    return im.rotate(rot, resample=Image.BICUBIC, expand=True) if rot else im


def shadowed(sprite, blur=10, offset=12, alpha=140):
    pad = blur * 3
    out = Image.new("RGBA", (sprite.width + pad * 2, sprite.height + pad * 2 + offset), (0, 0, 0, 0))
    sh = Image.new("RGBA", sprite.size, OUTLINE + (0,))
    sh.putalpha(sprite.getchannel("A").point(lambda a: a * alpha // 255))
    out.alpha_composite(sh, (pad, pad + offset))
    out = out.filter(ImageFilter.GaussianBlur(blur))
    out.alpha_composite(sprite, (pad, pad))
    return out


def label(img, text, size, center, top, bottom, max_w):
    """Centred outlined label with a vertical gradient, shrunk to fit max_w."""
    while True:
        font = ImageFont.truetype(art.TITLE_FONT, size)
        stroke = max(5, size // 7)
        l, t, r, b = font.getbbox(text, stroke_width=stroke)
        if r - l <= max_w or size <= 20:
            break
        size -= 2
    pad = stroke * 2
    lw, lh = r - l + pad * 2, b - t + pad * 2 + stroke
    layer = Image.new("RGBA", (lw, lh), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    o = (pad - l, pad - t)
    d.text((o[0], o[1] + stroke * 0.8), text, font=font, fill=OUTLINE, stroke_width=stroke, stroke_fill=OUTLINE)
    d.text(o, text, font=font, fill=OUTLINE, stroke_width=stroke, stroke_fill=OUTLINE)
    mask = Image.new("L", (lw, lh), 0)
    ImageDraw.Draw(mask).text(o, text, font=font, fill=255)
    layer.paste(art.vgradient(lw, lh, top, bottom).convert("RGBA"), (0, 0), mask)
    art.paste_center(img, layer, center)


def put(img, code, size, center, rot=0):
    art.paste_center(img, shadowed(emoji(code, size, rot)), center)


# ------------------------------------------------------------------ background: the thumbnail at night
img = Image.open("docs/art/thumbnail_1920x1080.png").convert("RGBA").filter(ImageFilter.GaussianBlur(9))
night = art.vgradient(W, H, (40, 14, 90), (255, 110, 20)).convert("RGBA")
night.putalpha(150)
img.alpha_composite(night)
img.alpha_composite(Image.new("RGBA", (W, H), (10, 4, 30, 90)))

# moon glow top right
glow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
ImageDraw.Draw(glow).ellipse([1560, -60, 1960, 340], fill=(255, 210, 120, 120))
img.alpha_composite(glow.filter(ImageFilter.GaussianBlur(60)))
put(img, "1f319", 230, (1770, 140), rot=-10)

# ------------------------------------------------------------------ title
art.title_text(img, "SPOOKY SNOW!", art.TITLE_FONT, 160, (960, 205), rot=-2,
               top=(255, 200, 80), bottom=(255, 100, 20), outline=OUTLINE)
art.tag(img, "UPDATE 2", (960, 58), 50, (235, 60, 60), rot=-3)

# decorations around the title
put(img, "1f987", 130, (300, 110), rot=15)
put(img, "1f987", 100, (470, 230), rot=-12)
put(img, "1f47b", 170, (140, 200), rot=8)
put(img, "1f578-fe0f", 150, (1540, 120))

# ------------------------------------------------------------------ feature cards
CARDS = [
    ("1f95a", "PETS & EGGS", (120, 200, 255)),
    ("1f36c", "HALLOWEEN CANDY", (255, 150, 40)),
    ("1f4c8", "23 NEW UPGRADES", (120, 230, 110)),
    ("1f381", "DAILY REWARDS", (255, 110, 170)),
    ("1f39f-fe0f", "CODES", (190, 130, 255)),
    ("1f3c6", "LEADERBOARDS", (255, 210, 60)),
]
cw, ch, gap = 500, 290, 40
x0 = (W - (cw * 3 + gap * 2)) // 2
y0 = 340
for i, (code, text, color) in enumerate(CARDS):
    col, row = i % 3, i // 3
    x, y = x0 + col * (cw + gap), y0 + row * (ch + gap)
    layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    d.rounded_rectangle([x + 4, y + 12, x + cw + 4, y + ch + 12], 36, fill=OUTLINE + (170,))  # drop shadow
    d.rounded_rectangle([x, y, x + cw, y + ch], 36, fill=OUTLINE)
    d.rounded_rectangle([x + 9, y + 9, x + cw - 9, y + ch - 9], 30, fill=(62, 34, 104))
    d.rounded_rectangle([x + 9, y + 9, x + cw - 9, y + 60], 30, fill=(84, 50, 136))
    d.rounded_rectangle([x + 9, y + 9, x + cw - 9, y + ch - 9], 30, outline=color, width=7)
    img.alpha_composite(layer)
    if code == "1f95a":  # egg with a pet peeking next to it
        put(img, code, 150, (x + cw // 2 - 55, y + 112), rot=-10)
        put(img, "1f427", 140, (x + cw // 2 + 70, y + 118), rot=8)
    else:
        put(img, code, 170, (x + cw // 2, y + 112))
    label(img, text, 62, (x + cw // 2, y + ch - 56), (255, 255, 255), color, cw - 60)

# corner pumpkins and a ghost on the bottom
put(img, "1f383", 230, (110, 980), rot=-8)
put(img, "1f383", 170, (1830, 990), rot=10)
put(img, "1f480", 110, (1820, 420), rot=12)

img.convert("RGB").save(OUT)
print("saved", OUT)
