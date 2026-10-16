"""Winter update art: game icon (512x512) and update picture (1920x1080).

Run:  python3 build/make_winter_art.py <fonts dir> <emoji dir> [output dir]
Emoji art: Microsoft Fluent Emoji 3D (MIT licence), from the @lobehub/fluent-emoji-3d npm package.
"""
import os
import sys

from PIL import Image, ImageDraw, ImageFilter, ImageFont

FONTS = sys.argv[1] if len(sys.argv) > 1 else "fonts"
EMOJI = sys.argv[2] if len(sys.argv) > 2 else "emoji"
OUTDIR = sys.argv[3] if len(sys.argv) > 3 else "docs/art"
sys.argv = [sys.argv[0], FONTS, "docs/art"]
sys.path.insert(0, os.path.dirname(__file__))
import make_art as art  # noqa: E402

OUTLINE = (14, 24, 64)


def put(img, code, size, center, rot=0, blur=8, offset=10):
    sprite = Image.open(f"{EMOJI}/{code}.webp").convert("RGBA").resize((size, size), Image.LANCZOS)
    if rot:
        sprite = sprite.rotate(rot, resample=Image.BICUBIC, expand=True)
    pad = blur * 3
    out = Image.new("RGBA", (sprite.width + pad * 2, sprite.height + pad * 2 + offset), (0, 0, 0, 0))
    sh = Image.new("RGBA", sprite.size, OUTLINE + (0,))
    sh.putalpha(sprite.getchannel("A").point(lambda a: a * 150 // 255))
    out.alpha_composite(sh, (pad, pad + offset))
    out = out.filter(ImageFilter.GaussianBlur(blur))
    out.alpha_composite(sprite, (pad, pad))
    art.paste_center(img, out, center)


def label(img, text, size, center, top, bottom, max_w):
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


# ------------------------------------------------------------------ icon
def icon():
    S = 1024
    img = art.vgradient(S, S, (20, 36, 110), (70, 150, 235)).convert("RGBA")
    art.rays(img, (560, 470), 18, (200, 230, 255), 34, spin=0.1)
    art.checker_slope(img, [(0, 760), (300, 700), (700, 640), (S, 600), (S, S), (0, S)], [(246, 250, 255), (205, 225, 250)], 120)
    art.flakes(img, 90, 7, (0, 0, S, 640), 3, 8)
    art.starburst(img, (760, 520), 300, 170, 14, (255, 70, 80), width=10, rot=0.2)
    art.starburst(img, (760, 520), 190, 110, 12, (255, 235, 170), rot=0.5)
    put(img, "1f381", 190, (840, 410), rot=-18)
    put(img, "1f381", 120, (950, 610), rot=22)
    put(img, "1f384", 200, (900, 220), rot=6)
    art.plank(img, (930, 730), 170, 34, (176, 112, 64), -30)
    art.snow_puff(img, (690, 600), 150, 18, 4)
    put(img, "1f98c", 130, (110, 330), rot=-8)
    put(img, "2744-fe0f", 110, (500, 130), rot=15)
    put(img, "2744-fe0f", 70, (330, 230), rot=-10)
    art.speed_lines(img, (380, 560), (-0.86, 0.5), 22, 2, 520, 230, 14)
    art.snowball(img, (430, 545), 285, face=True, angry=True)
    # Santa hat on the snowball
    put(img, "1f385", 190, (330, 290), rot=-20)
    art.title_text(img, "SNOWBALL", art.TITLE_FONT, 150, (512, 820), rot=4, top=(255, 255, 255), bottom=(170, 225, 255), outline=OUTLINE)
    art.title_text(img, "SMASH!", art.TITLE_FONT, 190, (530, 940), rot=4, top=(255, 120, 120), bottom=(235, 40, 60), outline=OUTLINE)
    art.tag(img, "UPDATE 3", (250, 70), 70, (40, 170, 90), rot=-8)
    return art.finish(img, (512, 512))


# ------------------------------------------------------------------ update picture
def update_picture():
    W, H = 1920, 1080
    img = Image.open("docs/art/thumbnail_1920x1080.png").convert("RGBA").filter(ImageFilter.GaussianBlur(9))
    night = art.vgradient(W, H, (18, 30, 100), (70, 140, 230)).convert("RGBA")
    night.putalpha(150)
    img.alpha_composite(night)
    img.alpha_composite(Image.new("RGBA", (W, H), (6, 10, 40, 80)))
    art.flakes(img, 120, 5, (0, 0, W, H), 3, 8)

    art.tag(img, "UPDATE 3", (960, 58), 50, (40, 170, 90), rot=-3)
    art.title_text(img, "WINTER WONDERLAND", art.TITLE_FONT, 124, (960, 205), rot=-2, top=(255, 255, 255), bottom=(255, 90, 100), outline=OUTLINE)
    put(img, "1f384", 170, (130, 190), rot=-6)
    put(img, "1f385", 160, (1790, 175), rot=8)
    put(img, "1f98c", 130, (125, 440), rot=-8)

    CARDS = [
        ("1f384", "WINTER EVENT", (255, 100, 110)),
        ("2604-fe0f", "METEOR SHOWER", (255, 150, 60)),
        ("1f30c", "GALAXY EVENT", (170, 120, 255)),
        ("1f427", "3D PETS", (120, 210, 255)),
        ("1f95a", "BLIZZARD EGG", (130, 130, 255)),
        ("1f4c8", "17 NEW UPGRADES", (120, 230, 110)),
    ]
    cw, ch, gap = 500, 290, 40
    x0 = (W - (cw * 3 + gap * 2)) // 2
    y0 = 340
    for i, (code, text, color) in enumerate(CARDS):
        col, row = i % 3, i // 3
        x, y = x0 + col * (cw + gap), y0 + row * (ch + gap)
        layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        d = ImageDraw.Draw(layer)
        d.rounded_rectangle([x + 4, y + 12, x + cw + 4, y + ch + 12], 36, fill=OUTLINE + (170,))
        d.rounded_rectangle([x, y, x + cw, y + ch], 36, fill=OUTLINE)
        d.rounded_rectangle([x + 9, y + 9, x + cw - 9, y + ch - 9], 30, fill=(30, 52, 120))
        d.rounded_rectangle([x + 9, y + 9, x + cw - 9, y + 60], 30, fill=(44, 72, 150))
        d.rounded_rectangle([x + 9, y + 9, x + cw - 9, y + ch - 9], 30, outline=color, width=7)
        img.alpha_composite(layer)
        if code == "1f95a":
            put(img, code, 150, (x + cw // 2 - 55, y + 112), rot=-10)
            put(img, "1f9ca", 130, (x + cw // 2 + 70, y + 118), rot=8)
        else:
            put(img, code, 170, (x + cw // 2, y + 112))
        label(img, text, 62, (x + cw // 2, y + ch - 56), (255, 255, 255), color, cw - 60)

    put(img, "1f381", 220, (110, 975), rot=-8)
    put(img, "1f381", 160, (1830, 990), rot=10)
    put(img, "1f36a", 110, (1820, 420), rot=12)
    return img.convert("RGB")


if __name__ == "__main__":
    os.makedirs(OUTDIR, exist_ok=True)
    icon().save(f"{OUTDIR}/icon_winter_512.png")
    update_picture().save(f"{OUTDIR}/update_winter_wonderland.png")
    print("saved to", OUTDIR)
