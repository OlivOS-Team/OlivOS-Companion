#!/usr/bin/env python3
"""从 resource/favoricon.ico 生成各平台应用图标。

用法（仓库根目录）：
    python tools/generate_icons.py

依赖 Pillow：pip install pillow
"""

from __future__ import annotations

import json
from pathlib import Path

from PIL import Image, ImageOps

ROOT = Path(__file__).resolve().parent.parent
SOURCE = ROOT / "resource" / "favoricon.ico"

ANDROID_ICONS = {
    "mipmap-mdpi": 48,
    "mipmap-hdpi": 72,
    "mipmap-xhdpi": 96,
    "mipmap-xxhdpi": 144,
    "mipmap-xxxhdpi": 192,
}

WINDOWS_ICON = ROOT / "windows" / "runner" / "resources" / "app_icon.ico"
BRANDING_ICON = ROOT / "assets" / "branding" / "olivos.png"
WINDOWS_SIZES = [(16, 16), (24, 24), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)]


def load_source() -> Image.Image:
    with Image.open(SOURCE) as image:
        sizes = sorted(image.info.get("sizes", [image.size]), key=lambda item: item[0] * item[1])
        image.size = sizes[-1]
        image.load()
        source = image.convert("RGBA")

    if source.width != source.height:
        side = min(source.width, source.height)
        source = ImageOps.fit(source, (side, side), method=Image.Resampling.LANCZOS)

    # iOS 不允许图标带 alpha；如果源图有透明像素，先压到源图角落的底色上。
    alpha_min, _ = source.getchannel("A").getextrema()
    if alpha_min < 255:
        background = Image.new("RGBA", source.size, source.getpixel((0, 0)))
        background.alpha_composite(source)
        source = background
    return source


def resized(source: Image.Image, size: int, *, opaque: bool = False) -> Image.Image:
    image = source.convert("RGB" if opaque else "RGBA")
    return image.resize((size, size), Image.Resampling.LANCZOS)


def generate_android(source: Image.Image) -> None:
    base = ROOT / "android" / "app" / "src" / "main" / "res"
    for folder, size in ANDROID_ICONS.items():
        target = base / folder / "ic_launcher.png"
        target.parent.mkdir(parents=True, exist_ok=True)
        resized(source, size).save(target, optimize=True)
        print(f"android  {target.relative_to(ROOT)}  {size}x{size}")


def generate_from_contents(source: Image.Image, contents: Path, opaque: bool) -> None:
    data = json.loads(contents.read_text(encoding="utf-8"))
    written: dict[str, int] = {}
    for entry in data.get("images", []):
        filename = entry.get("filename")
        size_text = entry.get("size")
        scale_text = entry.get("scale")
        if not filename or not size_text or not scale_text:
            continue
        base_size = float(size_text.split("x", 1)[0])
        scale = int(scale_text.removesuffix("x"))
        pixels = round(base_size * scale)
        previous = written.get(filename)
        if previous is not None and previous != pixels:
            raise ValueError(f"{filename} 需要两种尺寸：{previous} 与 {pixels}")
        written[filename] = pixels

    for filename, pixels in written.items():
        target = contents.parent / filename
        resized(source, pixels, opaque=opaque).save(target, optimize=True)
        print(f"asset    {target.relative_to(ROOT)}  {pixels}x{pixels}")


def generate_windows(source: Image.Image) -> None:
    WINDOWS_ICON.parent.mkdir(parents=True, exist_ok=True)
    source.save(WINDOWS_ICON, format="ICO", sizes=WINDOWS_SIZES)
    with Image.open(WINDOWS_ICON) as image:
        actual = sorted(image.info.get("sizes", []))
    print(f"windows  {WINDOWS_ICON.relative_to(ROOT)}  {actual}")


def main() -> None:
    if not SOURCE.exists():
        raise SystemExit(f"找不到源图标：{SOURCE}")

    source = load_source()
    print(f"source   {SOURCE.relative_to(ROOT)}  {source.width}x{source.height}  {source.mode}")

    BRANDING_ICON.parent.mkdir(parents=True, exist_ok=True)
    resized(source, 256).save(BRANDING_ICON, optimize=True)
    print(f"branding {BRANDING_ICON.relative_to(ROOT)}  256x256")

    generate_android(source)
    generate_from_contents(
        source,
        ROOT / "ios" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset" / "Contents.json",
        opaque=True,
    )
    generate_from_contents(
        source,
        ROOT / "macos" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset" / "Contents.json",
        opaque=False,
    )
    generate_windows(source)


if __name__ == "__main__":
    main()
