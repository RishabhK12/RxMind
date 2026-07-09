#!/usr/bin/env python3
"""Generate PNG brand assets from the canonical rxmind mark design."""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
BRAND_BLUE = (59, 130, 246, 255)
WHITE = (255, 255, 255, 255)


def draw_mark(size: int, padding_ratio: float = 0.12) -> Image.Image:
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    pad = int(size * padding_ratio)

    # Rounded square bubble (clean app-icon silhouette)
    body = [pad, pad, size - pad, size - pad]
    radius = int(size * 0.22)
    draw.rounded_rectangle(body, radius=radius, fill=BRAND_BLUE)

    # Speech tail (bottom-left)
    tail = [
        (pad + int(size * 0.08), size - pad - int(size * 0.06)),
        (pad + int(size * 0.22), size - pad + int(size * 0.04)),
        (pad + int(size * 0.34), size - pad - int(size * 0.02)),
    ]
    draw.polygon(tail, fill=BRAND_BLUE)

    # Medical cross
    cx = size / 2
    cy = size / 2 - size * 0.02
    bar = size * 0.09
    arm = size * 0.26
    draw.rounded_rectangle(
        [cx - arm / 2, cy - bar / 2, cx + arm / 2, cy + bar / 2],
        radius=int(bar * 0.35),
        fill=WHITE,
    )
    draw.rounded_rectangle(
        [cx - bar / 2, cy - arm / 2, cx + bar / 2, cy + arm / 2],
        radius=int(bar * 0.35),
        fill=WHITE,
    )
    return img


def write_png(path: Path, size: int) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    draw_mark(size).save(path, format="PNG", optimize=True)
    print(f"wrote {path} ({size}x{size})")


def main() -> None:
    targets = {
        ROOT / "assets/icons/app_icon.png": 1024,
        ROOT / "website/public/icon.png": 512,
        ROOT / "website/public/apple-touch-icon.png": 180,
        ROOT / "website/public/favicon-32.png": 32,
        ROOT / "website/public/favicon-16.png": 16,
        ROOT / "website/public/icons/app-icon.png": 512,
        ROOT / "website/app/icon.png": 512,
        ROOT / "website/app/apple-icon.png": 180,
    }
    for path, size in targets.items():
        write_png(path, size)

    ico_path = ROOT / "website/public/favicon.ico"
    ico_path.parent.mkdir(parents=True, exist_ok=True)
    draw_mark(32).save(ico_path, format="ICO", sizes=[(16, 16), (32, 32)])
    (ROOT / "website/app/favicon.ico").write_bytes(ico_path.read_bytes())
    print(f"wrote {ico_path}")

    # Flutter web
    web_targets = {
        ROOT / "web/favicon.png": 32,
        ROOT / "web/icons/Icon-192.png": 192,
        ROOT / "web/icons/Icon-512.png": 512,
        ROOT / "web/icons/Icon-maskable-192.png": 192,
        ROOT / "web/icons/Icon-maskable-512.png": 512,
    }
    for path, size in web_targets.items():
        write_png(path, size)

    # Android launcher mipmaps (mdpi baseline 48)
    android_sizes = {
        "mipmap-mdpi": 48,
        "mipmap-hdpi": 72,
        "mipmap-xhdpi": 96,
        "mipmap-xxhdpi": 144,
        "mipmap-xxxhdpi": 192,
    }
    for folder, size in android_sizes.items():
        write_png(
            ROOT / f"android/app/src/main/res/{folder}/ic_launcher.png",
            size,
        )


if __name__ == "__main__":
    main()
