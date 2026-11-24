#!/usr/bin/env python3
"""Render the original crescent mark using Pillow."""
from pathlib import Path
from PIL import Image, ImageDraw

root = Path(__file__).resolve().parent.parent
master = Image.new("RGB", (1024, 1024), "#201a32")
draw = ImageDraw.Draw(master)
draw.ellipse((230, 230, 794, 794), outline="#786696", width=9)
draw.ellipse((318, 318, 706, 706), fill="#f1c782")
draw.ellipse((412, 270, 728, 594), fill="#201a32")
draw.polygon([(667, 343), (682, 389), (728, 404), (682, 420),
              (667, 466), (652, 420), (606, 404), (652, 389)], fill="#eae3f4")


def save(path, size):
    master.resize((size, size), Image.Resampling.LANCZOS).save(path)


for path in (root / "web/icons").glob("*.png"):
    save(path, int(path.stem.rsplit("-", 1)[-1]))
save(root / "web/favicon.png", 48)
master.save(root / "windows/runner/resources/app_icon.ico",
            sizes=[(size, size) for size in (16, 32, 48, 64, 128, 256)])
for density, size in zip(("mdpi", "hdpi", "xhdpi", "xxhdpi", "xxxhdpi"), (48, 72, 96, 144, 192)):
    save(root / f"android/app/src/main/res/mipmap-{density}/ic_launcher.png", size)
for folder in (root / "ios/Runner/Assets.xcassets/AppIcon.appiconset",
               root / "macos/Runner/Assets.xcassets/AppIcon.appiconset"):
    for path in folder.glob("*.png"):
        with Image.open(path) as image:
            size = image.width
        save(path, size)
