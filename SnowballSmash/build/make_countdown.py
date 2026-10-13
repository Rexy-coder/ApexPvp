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

# flat 2D clock
d = ImageDraw.Draw(img)
cx, cy, r = W / 2, 430, 260
d.ellipse([cx - r - 22, cy - r - 22, cx + r + 22, cy + r + 22], fill=OUTLINE)  # outline
d.ellipse([cx - r - 8, cy - r - 8, cx + r + 8, cy + r + 8], fill=(255, 205, 40))  # yellow rim
d.ellipse([cx - r + 18, cy - r + 18, cx + r - 18, cy + r - 18], fill=OUTLINE)
d.ellipse([cx - r + 28, cy - r + 28, cx + r - 28, cy + r - 28], fill=(255, 255, 255))  # face
# tick marks
for i in range(60):
    a = i / 60 * 2 * math.pi
    big = i % 5 == 0
    r1 = r - 50
    r2 = r - (100 if big else 68)
    w = 16 if big else 6
    d.line([cx + math.sin(a) * r1, cy - math.cos(a) * r1, cx + math.sin(a) * r2, cy - math.cos(a) * r2],
           fill=OUTLINE, width=w)
# hands (10:10)
def hand(angle_deg, length, width, color):
    a = math.radians(angle_deg)
    d.line([cx, cy, cx + math.sin(a) * length, cy - math.cos(a) * length], fill=color, width=width)
    d.ellipse([cx + math.sin(a) * length - width / 2, cy - math.cos(a) * length - width / 2,
               cx + math.sin(a) * length + width / 2, cy - math.cos(a) * length + width / 2], fill=color)

hand(305, 130, 30, OUTLINE)  # hour hand
hand(60, 185, 22, OUTLINE)  # minute hand
d.ellipse([cx - 30, cy - 30, cx + 30, cy + 30], fill=OUTLINE)
d.ellipse([cx - 16, cy - 16, cx + 16, cy + 16], fill=(235, 55, 60))

# straight text under the clock
art.title_text(img, TEXT, art.TITLE_FONT, 220, (W / 2, 880), rot=0, top=(255, 255, 255), bottom=(255, 210, 60),
               outline=OUTLINE, stroke=22)

img.convert("RGB").save(OUT)
print("saved", OUT)
