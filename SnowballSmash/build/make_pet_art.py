"""Update 5 "Pet Paradise" art: game icon (512x512) and update picture (1920x1080).

Run:  python3 build/make_pet_art.py <fonts dir> <emoji dir> <pet pngs dir> [output dir]
The pet pngs are renders of the 3D pet models (see HANDOVER.md), named <PetId>_<variant>.png.
"""
import os
import sys

from PIL import Image, ImageDraw, ImageFilter

FONTS, EMOJI, PETS = sys.argv[1], sys.argv[2], sys.argv[3]
OUTDIR = sys.argv[4] if len(sys.argv) > 4 else "docs/art"
sys.argv = [sys.argv[0], FONTS, EMOJI, "docs/art"]
sys.path.insert(0, os.path.dirname(__file__))
import make_winter_art as w  # noqa: E402
import make_art as art  # noqa: E402

OUTLINE = w.OUTLINE


def pet(img, name, height, center, rot=0, glow=None):
    im = Image.open(f"{PETS}/{name}.png").convert("RGBA")
    im = im.crop(im.getbbox())
    scale = height / im.height
    im = im.resize((max(1, int(im.width * scale)), height), Image.LANCZOS)
    if rot:
        im = im.rotate(rot, resample=Image.BICUBIC, expand=True)
    pad = 40
    out = Image.new("RGBA", (im.width + pad * 2, im.height + pad * 2 + 14), (0, 0, 0, 0))
    if glow:
        g = Image.new("RGBA", im.size, glow + (0,))
        g.putalpha(im.getchannel("A").point(lambda a: a * 200 // 255))
        out.alpha_composite(g, (pad, pad))
        out = out.filter(ImageFilter.GaussianBlur(24))
    sh = Image.new("RGBA", im.size, OUTLINE + (0,))
    sh.putalpha(im.getchannel("A").point(lambda a: a * 140 // 255))
    shadow = Image.new("RGBA", out.size, (0, 0, 0, 0))
    shadow.alpha_composite(sh, (pad, pad + 14))
    out.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(10)))
    out.alpha_composite(im, (pad, pad))
    art.paste_center(img, out, center)


def icon():
    S = 1024
    img = art.vgradient(S, S, (120, 70, 230), (255, 150, 210)).convert("RGBA")
    art.rays(img, (512, 470), 20, (255, 240, 200), 40, spin=0.1)
    art.flakes(img, 70, 9, (0, 0, S, S), 3, 9)
    w.put(img, "2728", 120, (150, 170), rot=-10)
    w.put(img, "2728", 90, (880, 260), rot=12)
    pet(img, "Unicorn_2", 560, (330, 480), rot=-4, glow=(255, 255, 255))
    pet(img, "FrostDragon_2", 470, (700, 520), rot=5, glow=(255, 255, 255))
    pet(img, "Penguin_1", 330, (520, 660), glow=(255, 235, 150))
    art.title_text(img, "PET", art.TITLE_FONT, 190, (512, 790), rot=-3, top=(255, 255, 255), bottom=(255, 190, 240), outline=OUTLINE)
    art.title_text(img, "PARADISE!", art.TITLE_FONT, 210, (520, 930), rot=-3, top=(255, 245, 140), bottom=(255, 150, 30), outline=OUTLINE)
    art.tag(img, "UPDATE 5", (250, 75), 70, (235, 60, 150), rot=-8)
    return art.finish(img, (512, 512))


def update_picture():
    W, H = 1920, 1080
    img = Image.open("docs/art/thumbnail_1920x1080.png").convert("RGBA").filter(ImageFilter.GaussianBlur(9))
    tint = art.vgradient(W, H, (110, 60, 210), (255, 150, 210)).convert("RGBA")
    tint.putalpha(150)
    img.alpha_composite(tint)
    img.alpha_composite(Image.new("RGBA", (W, H), (40, 10, 60, 60)))
    art.flakes(img, 120, 11, (0, 0, W, H), 3, 8)
    art.tag(img, "UPDATE 5", (960, 58), 50, (235, 60, 150), rot=-3)
    art.title_text(img, "PET PARADISE", art.TITLE_FONT, 150, (960, 200), rot=-2, top=(255, 255, 255), bottom=(255, 190, 240), outline=OUTLINE)
    pet(img, "Unicorn_1", 250, (230, 190), rot=-6, glow=(255, 240, 160))
    pet(img, "FrostDragon_2", 240, (1690, 190), rot=6, glow=(255, 255, 255))

    CARDS = [
        ("pet:Penguin_1", "GOLDEN PETS", (255, 205, 60)),
        ("pet:Santa_2", "RAINBOW PETS", (255, 120, 220)),
        ("2728", "FUSION MACHINE", (120, 220, 255)),
        ("1f389", "PET PARTY EVENT", (255, 130, 190)),
        ("pet:SnowLeopard_2", "SHINY HATCHES", (170, 140, 255)),
        ("1f95a", "FUSE ALL BUTTON", (120, 230, 110)),
    ]
    cw, ch, gap = 500, 290, 40
    x0 = (W - (cw * 3 + gap * 2)) // 2
    y0 = 340
    for i, (icon_, text, color) in enumerate(CARDS):
        col, row = i % 3, i // 3
        x, y = x0 + col * (cw + gap), y0 + row * (ch + gap)
        layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        d = ImageDraw.Draw(layer)
        d.rounded_rectangle([x + 4, y + 12, x + cw + 4, y + ch + 12], 36, fill=OUTLINE + (170,))
        d.rounded_rectangle([x, y, x + cw, y + ch], 36, fill=OUTLINE)
        d.rounded_rectangle([x + 9, y + 9, x + cw - 9, y + ch - 9], 30, fill=(70, 40, 130))
        d.rounded_rectangle([x + 9, y + 9, x + cw - 9, y + 60], 30, fill=(96, 60, 165))
        d.rounded_rectangle([x + 9, y + 9, x + cw - 9, y + ch - 9], 30, outline=color, width=7)
        img.alpha_composite(layer)
        if icon_.startswith("pet:"):
            pet(img, icon_[4:], 150, (x + cw // 2, y + 112))
        else:
            w.put(img, icon_, 160, (x + cw // 2, y + 112))
        w.label(img, text, 60, (x + cw // 2, y + ch - 56), (255, 255, 255), color, cw - 60)
    w.put(img, "1f381", 200, (110, 985), rot=-8)
    w.put(img, "2728", 150, (1820, 990), rot=10)
    return img.convert("RGB")


if __name__ == "__main__":
    os.makedirs(OUTDIR, exist_ok=True)
    icon().save(f"{OUTDIR}/icon_pet_paradise_512.png")
    update_picture().save(f"{OUTDIR}/update_pet_paradise.png")
    print("saved to", OUTDIR)
