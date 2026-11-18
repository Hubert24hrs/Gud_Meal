"""Makes every logo file and app icon of GudMeals from the one brand logo, assets/brand/gudmeals-logo.webp.

    python scripts/make-brand-assets.py          (needs Pillow: pip install pillow)

The logo is the square master: a chef's hat on a cloche with a fork and spoon (the emblem), the name "GudMeals",
the line "Good Food. Great Mood.", a rider on a scooter and three small badges. Each place uses the part that
reads at its size:
  - the whole logo: app sign-in screens, the app's launch screen, the install page, link previews;
  - the name (wordmark) with the emblem: website headers;
  - the emblem: the customer app's icon, favicons;
  - the rider on the scooter: the rider app's icon.
Everything is cut from the logo itself; nothing is redrawn. The cut-outs keep the logo's own white where it is
part of the drawing (the hat, the inside of letters) and lose the white around them, so they sit on any light
background.
"""

from __future__ import annotations

import json
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
BRAND = ROOT / "assets" / "brand"
LOGO = BRAND / "gudmeals-logo.webp"

#: Colours read from the logo (see docs/adr/0022-gudmeals-brand.md).
WHITE = (255, 255, 255, 255)
CHOCOLATE = (58, 13, 5, 255)  # "Gud", the rider, the cloche
#: The website apps that get favicons and the logo files.
WEBSITES = ("web", "partner", "admin")


def load() -> Image.Image:
    im = Image.open(LOGO).convert("RGBA")
    assert im.size == (1254, 1254), f"expected the 1254 px square logo, got {im.size}"
    return im


def clear_background(im: Image.Image) -> Image.Image:
    """The white around the drawing becomes transparent (white inside it, like the hat, stays)."""
    out = im.copy()
    w, h = out.size
    for seed in ((0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1)):
        if out.getpixel(seed)[3]:
            ImageDraw.floodfill(out, seed, (255, 255, 255, 0), thresh=40)
    # Soften the light fringe the anti-aliasing leaves: near-white pixels next to the cleared area fade out.
    px = out.load()
    for y in range(1, h - 1):
        for x in range(1, w - 1):
            r, g, b, a = px[x, y]
            if a and r > 235 and g > 235 and b > 235:
                if not (px[x - 1, y][3] and px[x + 1, y][3] and px[x, y - 1][3] and px[x, y + 1][3]):
                    px[x, y] = (r, g, b, 0)
    return out


def is_green(c) -> bool:
    r, g, b = c[:3]
    return g > r + 20 and g > b + 20


def is_red(c) -> bool:
    r, g, b = c[:3]
    return r > 140 and g < 110 and b < 110 and r > g + 60


def is_orange(c) -> bool:
    r, g, b = c[:3]
    return r > 200 and 90 < g < 215 and b < 120


def emblem(im: Image.Image) -> Image.Image:
    """The chef's hat on the cloche, with the orange arc and the leaf; the letters below are left out."""
    out = clear_background(im.crop((150, 0, 1230, 540)))
    px = out.load()
    w, h = out.size
    for y in range(h):
        oy = y  # rows of the crop are rows of the logo
        for x in range(w):
            ox = x + 150
            c = px[x, y]
            if not c[3] or oy <= 470:
                continue
            if ox >= 1000:
                keep = is_green(c) or (is_orange(c) and oy <= 500)  # the leaf, the arc's end
            elif ox < 250:
                keep = is_orange(c) and oy <= 500  # the arc's end; the "G" starts below it
            elif 440 <= ox < 800:
                keep = oy < 500  # the cloche's rim; "dM" start at 504
            else:
                keep = oy < 519 and not (ox < 300 and oy >= 517)  # the rim's tips; "u", "a" start at 547
            if not keep:
                px[x, y] = (0, 0, 0, 0)
    return out.crop(out.getbbox())


def wordmark(im: Image.Image) -> Image.Image:
    """The name "GudMeals" with its red underline (no tagline, no emblem above it)."""
    top, bottom = 486, 768
    out = clear_background(im.crop((0, top, 1254, bottom)))
    px = out.load()
    w, h = out.size
    # Where the letters start in each column band: the cloche's rim and the leaf sit just above them.
    starts = [(0, 250, 486), (250, 300, 540), (300, 480, 545), (480, 800, 490), (800, 1000, 540), (1000, 1254, 486)]
    for y in range(h):
        oy = y + top
        for x in range(w):
            c = px[x, y]
            if not c[3]:
                continue
            first = next(s for a, b, s in starts if a <= x < b)
            drop = oy < first or is_green(c) or is_orange(c)
            if x >= 1000 and oy < 560 and not is_red(c):
                drop = True  # what is left of the leaf above "ls": only the red letters stay
            if oy >= 730 and not is_red(c):
                drop = True  # the tagline (dark) starts at 731; the red underline continues to 766
            if drop:
                px[x, y] = (0, 0, 0, 0)
    return out.crop(out.getbbox())


def rider(im: Image.Image) -> Image.Image:
    """The rider on the scooter with the red food box and the speed lines."""
    top = 793
    out = clear_background(im.crop((20, top, 510, 1062)))
    px = out.load()
    w, h = out.size
    for y in range(h):
        for x in range(w):
            c = px[x, y]
            low = y + top > 1040
            # The swoosh under the wheels (orange, red, and its light edge); only the dark wheels go that low.
            if c[3] and (is_orange(c) or (low and (is_red(c) or sum(c[:3]) > 300))):
                px[x, y] = (0, 0, 0, 0)
    return out.crop(out.getbbox())


def on_dark(art: Image.Image) -> Image.Image:
    """The same art for dark backgrounds: its dark brown ("Gud", outlines) turns cream; the red stays."""
    out = art.copy()
    px = out.load()
    for y in range(out.height):
        for x in range(out.width):
            r, g, b, a = px[x, y]
            if a and r + g + b < 260 and not is_red((r, g, b)):
                px[x, y] = (251, 240, 234, a)
    return out


def fit(art: Image.Image, size: int, box: float, ground=None, shape: str = "square") -> Image.Image:
    """`art` scaled to fit `box` (a share of `size`) and centred on a `size` square of `ground` (None: clear)."""
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    if ground is not None:
        draw = ImageDraw.Draw(canvas)
        if shape == "rounded":
            draw.rounded_rectangle((0, 0, size - 1, size - 1), radius=round(size * 16 / 72), fill=ground)
        elif shape == "circle":
            draw.ellipse((0, 0, size - 1, size - 1), fill=ground)
        else:
            draw.rectangle((0, 0, size, size), fill=ground)
    limit = size * box
    scale = min(limit / art.width, limit / art.height)
    piece = art.resize((max(1, round(art.width * scale)), max(1, round(art.height * scale))), Image.LANCZOS)
    canvas.alpha_composite(piece, ((size - piece.width) // 2, (size - piece.height) // 2))
    return canvas


def on_disc(art: Image.Image, size: int, ground, disc, disc_share: float, art_share: float, shape="square"):
    """The rider app's icon: the art on a light disc on a dark ground."""
    canvas = fit(Image.new("RGBA", (1, 1), (0, 0, 0, 0)), size, 1, ground, shape)
    d = round(size * disc_share)
    disc_img = Image.new("RGBA", (d, d), (0, 0, 0, 0))
    ImageDraw.Draw(disc_img).ellipse((0, 0, d - 1, d - 1), fill=disc)
    canvas.alpha_composite(disc_img, ((size - d) // 2, (size - d) // 2))
    canvas.alpha_composite(fit(art, size, art_share), (0, 0))
    return canvas


def save(img: Image.Image, path: Path, *, opaque: bool = False) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    if opaque:  # store icons need no transparency
        flat = Image.new("RGB", img.size, (255, 255, 255))
        flat.paste(img, mask=img.split()[3])
        flat.save(path, optimize=True)
    else:
        img.save(path, optimize=True)


def write_text(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with open(path, "w", encoding="utf-8", newline="\n") as handle:
        handle.write(text)


def main() -> None:
    im = load()
    full = clear_background(im)
    mark, name, scooter = emblem(im), wordmark(im), rider(im)

    # Master cut-outs, kept next to the logo.
    save(full, BRAND / "gudmeals-logo.png")
    save(mark, BRAND / "gudmeals-emblem.png")
    save(name, BRAND / "gudmeals-wordmark.png")
    save(on_dark(name), BRAND / "gudmeals-wordmark-light.png")
    save(scooter, BRAND / "gudmeals-rider.png")
    print(f"emblem {mark.size}, wordmark {name.size}, rider {scooter.size}")

    # Websites: the files their pages show, and favicons (Next.js picks up app/icon.png and app/apple-icon.png).
    lockup_h = 112  # 2x of the header's 56 px
    for app in WEBSITES:
        public = ROOT / "apps" / app / "public" / "brand"
        save(mark.resize((round(mark.width * lockup_h / mark.height), lockup_h), Image.LANCZOS), public / "gudmeals-emblem.png")
        save(name.resize((round(name.width * 96 / name.height), 96), Image.LANCZOS), public / "gudmeals-wordmark.png")
        save(on_dark(name).resize((round(name.width * 96 / name.height), 96), Image.LANCZOS), public / "gudmeals-wordmark-light.png")
        save(fit(mark, 192, 0.92), ROOT / "apps" / app / "src" / "app" / "icon.png")
        save(fit(mark, 180, 0.78, WHITE), ROOT / "apps" / app / "src" / "app" / "apple-icon.png", opaque=True)

    # Link previews of the customer website (WhatsApp, X, Facebook): the whole logo on white, 1200x630.
    preview = Image.new("RGBA", (1200, 630), WHITE)
    shown = full.resize((580, 580), Image.LANCZOS)
    preview.alpha_composite(shown, ((1200 - 580) // 2, 25))
    save(preview, ROOT / "apps" / "web" / "src" / "app" / "opengraph-image.png", opaque=True)

    # Phone apps: in-app logo files (customer and rider), launcher icons, launch screens, browser builds.
    densities = {"mdpi": 1.0, "hdpi": 1.5, "xhdpi": 2.0, "xxhdpi": 3.0, "xxxhdpi": 4.0}
    for app in ("customer", "rider"):
        base = ROOT / "mobile" / app
        save(full.resize((720, 720), Image.LANCZOS), base / "assets" / "brand" / "gudmeals-logo.png")
        save(name.resize((round(name.width * 144 / name.height), 144), Image.LANCZOS), base / "assets" / "brand" / "gudmeals-wordmark.png")
        art = mark if app == "customer" else scooter
        ground = WHITE if app == "customer" else CHOCOLATE
        res = base / "android" / "app" / "src" / "main" / "res"
        for density, k in densities.items():
            # Adaptive icon layer: 108dp, launchers show the middle 72dp (a 66dp circle is always visible).
            fg = round(108 * k)
            if app == "customer":
                save(fit(art, fg, 0.56), res / f"mipmap-{density}" / "ic_launcher_foreground.png")
            else:
                save(on_disc(art, fg, (0, 0, 0, 0), WHITE, 0.60, 0.46), res / f"mipmap-{density}" / "ic_launcher_foreground.png")
            legacy = round(48 * k)
            if app == "customer":
                save(fit(art, legacy, 0.80, ground, "rounded"), res / f"mipmap-{density}" / "ic_launcher.png")
            else:
                save(on_disc(art, legacy, ground, WHITE, 0.84, 0.64, "rounded"), res / f"mipmap-{density}" / "ic_launcher.png")
        hex_ground = "#{:02X}{:02X}{:02X}".format(*ground[:3])
        write_text(res / "values" / "ic_launcher_background.xml",
                   '<?xml version="1.0" encoding="utf-8"?>\n'
                   "<!-- Made by scripts/make-brand-assets.py: the launcher icon's background, a colour of the logo. -->\n"
                   f'<resources>\n    <color name="ic_launcher_background">{hex_ground}</color>\n</resources>\n')
        write_text(res / "mipmap-anydpi-v26" / "ic_launcher.xml",
                   '<?xml version="1.0" encoding="utf-8"?>\n'
                   "<!-- Made by scripts/make-brand-assets.py from assets/brand/gudmeals-logo.webp. -->\n"
                   '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
                   '    <background android:drawable="@color/ic_launcher_background" />\n'
                   '    <foreground android:drawable="@mipmap/ic_launcher_foreground" />\n'
                   "</adaptive-icon>\n")
        # Launch screen (before Flutter draws): the whole logo on white.
        save(full.resize((480, 480), Image.LANCZOS), res / "drawable-nodpi" / "launch_logo.png")
        launch = ('<?xml version="1.0" encoding="utf-8"?>\n'
                  "<!-- Made by scripts/make-brand-assets.py: the GudMeals logo on white while the app starts. -->\n"
                  '<layer-list xmlns:android="http://schemas.android.com/apk/res/android">\n'
                  '    <item android:drawable="@android:color/white" />\n'
                  "    <item>\n"
                  '        <bitmap android:gravity="center" android:src="@drawable/launch_logo" />\n'
                  "    </item>\n"
                  "</layer-list>\n")
        for folder in ("drawable", "drawable-v21"):
            write_text(res / folder / "launch_background.xml", launch)
        # Browser builds (flutter build web).
        web = base / "web"
        if web.exists():
            save(fit(mark if app == "customer" else scooter, 32, 0.96), web / "favicon.png")
            for n in (192, 512):
                if app == "customer":
                    save(fit(art, n, 0.78, ground), web / "icons" / f"Icon-{n}.png")
                    save(fit(art, n, 0.62, ground), web / "icons" / f"Icon-maskable-{n}.png")
                else:
                    save(on_disc(art, n, ground, WHITE, 0.84, 0.62), web / "icons" / f"Icon-{n}.png")
                    save(on_disc(art, n, ground, WHITE, 0.70, 0.50), web / "icons" / f"Icon-maskable-{n}.png")
        # iOS: every size the asset catalogue lists (no transparency allowed).
        appicon = base / "ios" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset"
        contents = appicon / "Contents.json"
        if contents.exists():
            for entry in json.loads(contents.read_text(encoding="utf-8"))["images"]:
                if "filename" not in entry:
                    continue
                points = float(entry["size"].split("x")[0])
                px = round(points * float(entry["scale"].rstrip("x")))
                icon = fit(art, px, 0.74, ground) if app == "customer" else on_disc(art, px, ground, WHITE, 0.80, 0.60)
                save(icon, appicon / entry["filename"], opaque=True)
        print(f"made the {app} app's icons and launch screen")


if __name__ == "__main__":
    main()
