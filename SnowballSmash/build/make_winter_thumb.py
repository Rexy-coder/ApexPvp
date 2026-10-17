"""Winter update thumbnail (1920x1080) in the style of the normal game thumbnail.
Includes Pet Paradise pets and the crazy events.

Run:  python3 build/make_winter_thumb.py <fonts dir> <emoji dir> <pet pngs dir> [output]
"""
import os
import sys

from PIL import Image, ImageChops, ImageDraw, ImageEnhance, ImageFilter

FONTS, EMOJI, PETS = sys.argv[1], sys.argv[2], sys.argv[3]
OUT = sys.argv[4] if len(sys.argv) > 4 else "docs/art/thumbnail_winter_1920x1080.png"
sys.argv = [sys.argv[0], FONTS, "docs/art"]
sys.path.insert(0, os.path.dirname(__file__))
import make_art as art  # noqa: E402
import make_winter_art as w  # noqa: E402

w.EMOJI = EMOJI
W, H = 1920, 1080
OUTLINE = (14, 24, 64)

img = Image.open("docs/art/thumbnail_1920x1080.png").convert("RGB")
img = ImageEnhance.Color(img).enhance(1.2)
tint = art.vgradient(W, H, (110, 150, 255), (215, 235, 255))  # cold evening blue
img = ImageChops.multiply(img, tint).convert("RGBA")
img = ImageEnhance.Brightness(img).enhance(1.1)
art.flakes(img, 160, 21, (0, 0, W, H), 3, 9)


def pet(name, height, center, rot=0):
    im = Image.open(f"{PETS}/{name}.png").convert("RGBA")
    im = im.crop(im.getbbox())
    im = im.resize((max(1, int(im.width * height / im.height)), height), Image.LANCZOS)
    if rot:
        im = im.rotate(rot, resample=Image.BICUBIC, expand=True)
    pad = 36
    out = Image.new("RGBA", (im.width + pad * 2, im.height + pad * 2 + 12), (0, 0, 0, 0))
    sh = Image.new("RGBA", im.size, OUTLINE + (0,))
    sh.putalpha(im.getchannel("A").point(lambda a: a * 150 // 255))
    shadow = Image.new("RGBA", out.size, (0, 0, 0, 0))
    shadow.alpha_composite(sh, (pad, pad + 12))
    out.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(9)))
    out.alpha_composite(im, (pad, pad))
    art.paste_center(img, out, center)


# snow-covered fun in the sky and on the slope
for code, size, pos, rot in (
    ("2744-fe0f", 100, (980, 90), 15), ("2744-fe0f", 70, (1240, 210), -10), ("2744-fe0f", 80, (430, 60), 20),
    ("1f98c", 130, (95, 520), -8), ("2604-fe0f", 110, (1720, 90), 0), ("1f384", 190, (1830, 640), 4),
    ("1f381", 120, (1185, 650), 12), ("1f381", 190, (1190, 940), -10), ("1f384", 150, (120, 900), -5),
):
    w.put(img, code, size, pos, rot=rot)

# Pet Paradise: the new 3D pets (golden / rainbow) running along the slope
pet("Penguin_1", 190, (1010, 900), rot=-6)
pet("Unicorn_1", 240, (1530, 930), rot=4)
pet("SnowKing_1", 215, (1760, 880), rot=-4)

art.title_text(img, "WINTER UPDATE!", art.TITLE_FONT, 112, (1460, 285), rot=5, top=(255, 255, 255), bottom=(255, 100, 110), outline=OUTLINE)
art.tag(img, "+ PET PARADISE", (1470, 395), 54, (235, 60, 150), rot=5)
art.tag(img, "6 CRAZY EVENTS", (1500, 480), 48, (60, 150, 255), rot=5)

img.convert("RGB").save(OUT)
print("saved", OUT)
