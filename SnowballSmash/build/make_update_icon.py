"""Game icon (512x512) for the Spooky Snow update: the normal icon at night, smashing pumpkins.

Run:  python3 build/make_update_icon.py <fonts dir> <emoji dir> [output]
Emoji art: Microsoft Fluent Emoji 3D (MIT licence), from the @lobehub/fluent-emoji-3d npm package.
"""
import os
import sys

from PIL import Image, ImageFilter

FONTS = sys.argv[1] if len(sys.argv) > 1 else "fonts"
EMOJI = sys.argv[2] if len(sys.argv) > 2 else "emoji"
OUT = sys.argv[3] if len(sys.argv) > 3 else "docs/art/icon_spooky_512.png"
sys.argv = [sys.argv[0], FONTS, "docs/art"]
sys.path.insert(0, os.path.dirname(__file__))
import make_art as art  # noqa: E402

S = 1024
OUTLINE = (20, 12, 40)


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


img = art.vgradient(S, S, (46, 20, 100), (255, 120, 30)).convert("RGBA")
art.rays(img, (560, 470), 18, (255, 220, 160), 30, spin=0.1)
put(img, "1f319", 210, (880, 120), rot=-12)
# ground: snowy slope in the orange evening light
art.checker_slope(img, [(0, 760), (300, 700), (700, 640), (S, 600), (S, S), (0, S)], [(255, 228, 205), (238, 196, 170)], 120)
art.flakes(img, 50, 7, (0, 0, S, 640), 3, 7)

# impact burst with pumpkins flying apart
art.starburst(img, (760, 520), 300, 170, 14, (255, 150, 30), width=10, rot=0.2)
art.starburst(img, (760, 520), 190, 110, 12, (255, 230, 150), rot=0.5)
put(img, "1f383", 190, (830, 400), rot=-20)
put(img, "1f383", 120, (940, 600), rot=25)
art.plank(img, (930, 720), 170, 34, (176, 112, 64), -30)
art.block(img, (660, 230), 60, (150, 90, 230), 20)
art.snow_puff(img, (690, 600), 150, 18, 4)

# bats, ghost and candy
put(img, "1f987", 110, (560, 90), rot=12)
put(img, "1f987", 85, (420, 230), rot=-10)
put(img, "1f47b", 150, (105, 330), rot=10)
put(img, "1f36c", 100, (950, 830), rot=-20)

# the hero snowball
art.speed_lines(img, (380, 560), (-0.86, 0.5), 22, 2, 520, 230, 14)
art.snowball(img, (430, 545), 285, face=True, angry=True)

# title
art.title_text(img, "SNOWBALL", art.TITLE_FONT, 150, (512, 820), rot=4, top=(255, 255, 255), bottom=(255, 200, 150),
               outline=OUTLINE)
art.title_text(img, "SMASH!", art.TITLE_FONT, 190, (530, 940), rot=4, top=(255, 210, 80), bottom=(255, 100, 20),
               outline=OUTLINE)
art.tag(img, "UPDATE 2", (250, 80), 72, (235, 60, 60), rot=-8)

art.finish(img, (512, 512)).save(OUT)
print("saved", OUT)
