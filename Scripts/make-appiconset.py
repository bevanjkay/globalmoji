#!/usr/bin/env python3
"""Builds App/Assets.xcassets/AppIcon.appiconset from Design/app-icon-source.png.

The source artwork is an opaque render of the icon on a white background. This script
cuts the squircle out onto a transparent canvas, places it on Apple's 1024-pt icon grid
(icon body = 824 pt), and exports every macOS size. Requires Pillow and numpy.
"""
import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

root = Path(__file__).resolve().parent.parent
source = Path(sys.argv[1]) if len(sys.argv) > 1 else root / "Design/app-icon-source.png"
out = root / "App/Assets.xcassets/AppIcon.appiconset"
out.mkdir(parents=True, exist_ok=True)

image = Image.open(source).convert("RGBA")
pixels = np.array(image)

# The squircle body is the dark navy region; the soft drop shadow around it is excluded.
dark = (pixels[:, :, :3].astype(int).sum(axis=2) < 240)
rows = np.where(dark.any(axis=1))[0]
cols = np.where(dark.any(axis=0))[0]
top, bottom, left, right = rows.min(), rows.max(), cols.min(), cols.max()
side = max(right - left, bottom - top) + 1
print(f"squircle body: x={left}..{right} y={top}..{bottom} side={side}")

# Anti-aliased squircle mask at 4x, matching Apple's ~22.37% corner radius.
scale = 4
mask = Image.new("L", (side * scale, side * scale), 0)
ImageDraw.Draw(mask).rounded_rectangle(
    [0, 0, side * scale - 1, side * scale - 1], radius=int(side * scale * 0.2237), fill=255
)
mask = mask.resize((side, side), Image.LANCZOS)

body = image.crop((left, top, left + side, top + side))
body.putalpha(mask)

# Apple's macOS icon grid: 1024 canvas, 824 body, centred.
canvas = Image.new("RGBA", (1024, 1024), (0, 0, 0, 0))
body_size = 824
canvas.paste(body.resize((body_size, body_size), Image.LANCZOS), ((1024 - body_size) // 2, (1024 - body_size) // 2))

images = []
for size in (16, 32, 128, 256, 512):
    for factor in (1, 2):
        px = size * factor
        name = f"icon_{size}x{size}@{factor}x.png"
        canvas.resize((px, px), Image.LANCZOS).save(out / name, optimize=True)
        images.append({"filename": name, "idiom": "mac", "scale": f"{factor}x", "size": f"{size}x{size}"})

(out / "Contents.json").write_text(json.dumps({"images": images, "info": {"author": "xcode", "version": 1}}, indent=2, sort_keys=True) + "\n")
print(f"Wrote {len(images)} icons to {out}")
