"""Halloween version of the normal game thumbnail (1920x1080): same scene, spooky night look.

Run:  python3 build/make_halloween_thumb.py <fonts dir> <emoji dir> [output]
"""
import os
import sys

from PIL import Image, ImageDraw, ImageFilter

FONTS, EMOJI = sys.argv[1], sys.argv[2]
OUT = sys.argv[3] if len(sys.argv) > 3 else "docs/art/thumbnail_halloween_1920x1080.png"
sys.argv = [sys.argv[0], FONTS, "docs/art"]
sys.path.insert(0, os.path.dirname(__file__))
import make_art as art  # noqa: E402
import make_winter_art as w  # noqa: E402

w.EMOJI = EMOJI
W, H = 1920, 1080
OUTLINE = (24, 10, 40)

img = Image.open("docs/art/thumbnail_1920x1080.png").convert("RGBA")
# spooky dusk: multiply tint, purple at the top, warm orange near the ground
from PIL import ImageChops, ImageEnhance  # noqa: E402

base = img.convert("RGB")
base = ImageEnhance.Color(base).enhance(1.25)
tint = art.vgradient(W, H, (120, 95, 215), (255, 150, 95))
img = ImageChops.multiply(base, tint).convert("RGBA")
img = ImageEnhance.Brightness(img).enhance(1.12)

# moon glow
glow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
ImageDraw.Draw(glow).ellipse([1500, -140, 1900, 260], fill=(255, 215, 130, 150))
img.alpha_composite(glow.filter(ImageFilter.GaussianBlur(60)))
w.put(img, "1f319", 190, (1700, 120), rot=-10)

# bats, ghosts and candy flying about
for code, size, pos, rot in (
    ("1f987", 120, (980, 90), 10), ("1f987", 90, (1230, 200), -15), ("1f987", 100, (430, 60), 18),
    ("1f47b", 150, (1420, 470), 8), ("1f47b", 110, (90, 520), -10), ("1f36c", 90, (1180, 650), 20),
    ("1f36c", 80, (700, 80), -25),
):
    w.put(img, code, size, pos, rot=rot)

# pumpkins smashed along the slope
for size, pos, rot in ((200, (1230, 940), -10), (150, (1700, 880), 14), (130, (1010, 760), 8), (170, (1810, 1010), -16), (120, (160, 880), 12)):
    w.put(img, "1f383", size, pos, rot=rot)

# titles
art.title_text(img, "SPOOKY SNOW!", art.TITLE_FONT, 118, (1470, 300), rot=5, top=(255, 215, 90), bottom=(255, 100, 20), outline=OUTLINE)
art.tag(img, "HALLOWEEN UPDATE", (1470, 410), 56, (140, 60, 220), rot=5)

img.convert("RGB").save(OUT)
print("saved", OUT)
