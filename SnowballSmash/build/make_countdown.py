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
FACE = BLACK  # clock face and rim
MARK = WHITE  # quarter and hands
d = ImageDraw.Draw(img)
cx, cy, r = W / 2, 430, 270
d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=FACE)
# bezel: white ring inside the black edge
ring = 14
d.ellipse([cx - r + 18, cy - r + 18, cx + r - 18, cy + r - 18], fill=MARK)
d.ellipse([cx - r + 18 + ring, cy - r + 18 + ring, cx + r - 18 - ring, cy + r - 18 - ring], fill=FACE)


def stroke(points, width, color):
    d.line(points, fill=color, width=int(width))
    for x, y in points:  # rounded ends
        d.ellipse([x - width / 2, y - width / 2, x + width / 2, y + width / 2], fill=color)


# hour marks (bigger at 12, 3, 6 and 9)
for h in range(12):
    a = h / 12 * 2 * math.pi
    big = h % 3 == 0
    r1 = r - 62
    r2 = r - (122 if big else 98)
    stroke([(cx + math.sin(a) * r1, cy - math.cos(a) * r1), (cx + math.sin(a) * r2, cy - math.cos(a) * r2)],
           22 if big else 14, MARK)

# the white quarter between the hands (inside the hour marks)
hw = 46  # hand thickness
q = r - 140  # radius of the quarter / hand length
d.pieslice([cx - q, cy - q, cx + q, cy + q], -90, 0, fill=MARK)
for tip in [(cx, cy - q + hw / 2), (cx + q - hw / 2, cy)]:
    stroke([(cx, cy), tip], hw, MARK)  # hands with rounded ends, joined to the quarter

# centre pin
d.ellipse([cx - 22, cy - 22, cx + 22, cy + 22], fill=FACE)
d.ellipse([cx - 9, cy - 9, cx + 9, cy + 9], fill=MARK)


# straight black-and-white text under the clock
art.title_text(img, TEXT, art.TITLE_FONT, 220, (W / 2, 880), rot=0, top=WHITE, bottom=WHITE,
               outline=BLACK, stroke=22, shadow=False)

img.convert("RGB").save(OUT)
print("saved", OUT)
