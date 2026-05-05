#!/usr/bin/env python3
"""Render the Dopamine Detox app icon. Restrained: black background, single muted-amber arc."""
from PIL import Image, ImageDraw
from pathlib import Path
import math

SIZE = 1024
BG = (10, 10, 10)
ACCENT = (212, 166, 115)
TRACK = (35, 35, 35)

img = Image.new("RGB", (SIZE, SIZE), BG)
d = ImageDraw.Draw(img)

inset = 180
stroke = 60
box = (inset, inset, SIZE - inset, SIZE - inset)

d.arc(box, start=0, end=360, fill=TRACK, width=stroke)
d.arc(box, start=-90, end=180, fill=ACCENT, width=stroke)

out_dir = Path(__file__).resolve().parent.parent / "DopamineDetox/Assets.xcassets/AppIcon.appiconset"
out = out_dir / "icon-1024.png"
img.save(out, "PNG")
print(f"wrote {out}")
