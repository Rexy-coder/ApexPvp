"""Countdown picture: the game thumbnail with a flat 2D clock and "5 DAYS" on top.

Run:  python3 build/make_countdown.py <fonts dir> [text] [output]
"""
import math
import os
import sys

from PIL import Image, ImageDraw

FONTS = sys.argv[1] if len(sys.argv) > 1 else "fonts"
TEXT = sys.argv[2] if len(sys.argv) > 2 else "5 DAYS"
OUT = sys.argv[3] if len(sys.argv) > 3 else "docs/art/admin_abuse_5_days.png"
sys.argv = [sys.argv[0], FONTS, "docs/art"]
sys.path.insert(0, os.path.dirname(__file__))
import make_art as art  # noqa: E402

OUTLINE = (22, 30, 70)
W, H = 1920, 1080

img = Image.open("docs/art/thumbnail_1920x1080.png").convert("RGBA")
# darken a little so the clock stands out, but keep the picture visible
img.alpha_composite(Image.new("RGBA", (W, H), (10, 15, 40, 95)))

# flat 2D clock: black face, two hands at 90 degrees (12 and 3 o'clock),
# the quarter between the hands is white
BLACK = (0, 0, 0)
WHITE = (255, 255, 255)
d = ImageDraw.Draw(img)
cx, cy, r = W / 2, 430, 270
d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=BLACK)
rim = 20  # black ring that stays around the edge
# white quarter between the hands, reaching out to the black rim
# (PIL angles: 0 = 3 o'clock, -90 = 12 o'clock)
d.pieslice([cx - r + rim, cy - r + rim, cx + r - rim, cy + r - rim], -90, 0, fill=WHITE)


# straight black-and-white text under the clock
art.title_text(img, TEXT, art.TITLE_FONT, 220, (W / 2, 880), rot=0, top=WHITE, bottom=WHITE,
               outline=BLACK, stroke=22, shadow=False)

img.convert("RGB").save(OUT)
print("saved", OUT)
