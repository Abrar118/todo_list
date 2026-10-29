"""Nudge's mascot: one geometry, two outputs.

    python tool/mascot/mascot.py

writes

* assets/mascot/idle.json, assets/mascot/cheer.json — Lottie animations
  (512x512, 60 fps) the app plays through the `lottie` package, recoloured
  at runtime to the active palette (layers `Body`, `Lip`, `Feet`, `Sprout`);
* assets/icon/icon.png, icon_background.png, icon_foreground.png,
  icon_monochrome.png — the app
  icon, rendered from the same shapes (needs Pillow), for
  `dart run flutter_launcher_icons`;
* ios/Runner/Assets.xcassets/AppIcon-<palette>.appiconset — the iOS
  alternate icon for each other palette.

The mascot is an original character drawn here: a round, chunky sprout
with a solid lip under its body like the app's buttons, big eyes and a
two-leaf sprout on top. Edit the shapes below and re-run; never hand-edit
the JSON.
"""

import json
import math
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

# Default (green palette) colours; the app recolours Body/Lip/Feet/Sprout.
BODY = (0x58, 0xCC, 0x02)
SHADE = (0x46, 0xA3, 0x02)
INK = (0x1B, 0x1B, 0x2F)
WHITE = (0xFF, 0xFF, 0xFF)
CHEEK = (0xFF, 0x9A, 0xB4)
TONGUE = (0xFF, 0x8F, 0xA3)

# --- geometry (512 x 512 canvas) -------------------------------------------

# A path is (vertices, in-tangents, out-tangents, closed); tangents are
# relative to their vertex, as in Lottie.
BODY_PATH = (
    [[256, 165], [406, 300], [256, 435], [106, 300]],
    [[-95, 0], [0, -80], [105, 0], [0, 85]],
    [[95, 0], [0, 85], [-105, 0], [0, -80]],
    True,
)
LIP_OFFSET = 16
STEM = ([[256, 180], [250, 118]], [[0, 0], [6, 22]], [[-4, -22], [0, 0]], False)
LEAF_LEFT = (
    [[250, 122], [172, 92]],
    [[-38, 12], [30, -26]],
    [[-24, -46], [22, 28]],
    True,
)
LEAF_RIGHT = (
    [[252, 116], [344, 72]],
    [[42, 12], [-38, -22]],
    [[26, -50], [-16, 34]],
    True,
)
SMILE = ([[236, 324], [276, 324]], [[0, 0], [-8, 20]], [[8, 20], [0, 0]], False)
HAPPY_EYE_L = ([[184, 280], [228, 280]], [[0, 0], [-6, -32]], [[6, -32], [0, 0]], False)
HAPPY_EYE_R = ([[284, 280], [328, 280]], [[0, 0], [-6, -32]], [[6, -32], [0, 0]], False)
OPEN_MOUTH = (
    [[224, 314], [288, 314]],
    [[0, 46], [0, 0]],
    [[0, 0], [0, 46]],
    True,
)


def shifted(path, dy):
    v, i, o, c = path
    return ([[x, y + dy] for x, y in v], i, o, c)


# --- Lottie ----------------------------------------------------------------


def st(v):
    return {"a": 0, "k": v}


def anim(frames):
    """Keyframes [(t, value), ...] with a soft ease in and out."""
    ks = []
    for n, (t, v) in enumerate(frames):
        s = v if isinstance(v, list) else [v]
        k = {"t": t, "s": s}
        if n < len(frames) - 1:
            d = len(s)
            k["o"] = {"x": [0.45] * d, "y": [0] * d}
            k["i"] = {"x": [0.55] * d, "y": [1] * d}
        ks.append(k)
    return {"a": 1, "k": ks}


def rgb(c):
    return [round(x / 255, 4) for x in c] + [1]


def el(cx, cy, w, h):
    return {"ty": "el", "nm": "Ellipse", "d": 1, "p": st([cx, cy]), "s": st([w, h])}


def sh(path):
    v, i, o, c = path
    return {"ty": "sh", "nm": "Path", "d": 1, "ks": st({"v": v, "i": i, "o": o, "c": c})}


def fl(c, opacity=100):
    return {"ty": "fl", "nm": "Fill", "c": st(rgb(c)), "o": st(opacity), "r": 1}


def stroke(c, w):
    return {
        "ty": "st", "nm": "Stroke", "c": st(rgb(c)), "o": st(100), "w": st(w),
        "lc": 2, "lj": 2, "ml": 4,
    }


def gr(name, items, rot=0, anchor=(0, 0)):
    return {
        "ty": "gr", "nm": name,
        "it": items + [{
            "ty": "tr", "p": st(list(anchor)), "a": st(list(anchor)),
            "s": st([100, 100]), "r": st(rot), "o": st(100),
            "sk": st(0), "sa": st(0),
        }],
    }


def tf(anchor=(256, 256), p=None, s=None, r=None, o=None):
    a = [anchor[0], anchor[1], 0]
    return {
        "o": o or st(100),
        "r": r or st(0),
        "p": p or st(a),
        "a": st(a),
        "s": s or st([100, 100, 100]),
    }


def layer(ind, name, shapes, op, parent=None, ks=None):
    out = {
        "ddd": 0, "ind": ind, "ty": 4, "nm": name, "sr": 1, "ks": ks or tf(),
        "ao": 0, "shapes": shapes, "ip": 0, "op": op, "st": 0, "bm": 0,
    }
    if parent:
        out["parent"] = parent
    return out


def build(mood):
    idle = mood == "idle"
    op = 180 if idle else 90
    rig_anchor = (256, 440)
    if idle:
        rig = tf(
            rig_anchor,
            p=anim([(0, [256, 440, 0]), (45, [256, 436, 0]), (90, [256, 440, 0]),
                    (135, [256, 436, 0]), (180, [256, 440, 0])]),
            s=anim([(0, [100, 100, 100]), (45, [98, 103, 100]), (90, [100, 100, 100]),
                    (135, [98, 103, 100]), (180, [100, 100, 100])]),
        )
        sprout_r = anim([(0, -5), (90, 6), (180, -5)])
        shadow_s = anim([(0, [100, 100, 100]), (45, [95, 95, 100]), (90, [100, 100, 100]),
                         (135, [95, 95, 100]), (180, [100, 100, 100])])
    else:
        rig = tf(
            rig_anchor,
            p=anim([(0, [256, 440, 0]), (10, [256, 446, 0]), (28, [256, 372, 0]),
                    (46, [256, 440, 0]), (56, [256, 440, 0]), (90, [256, 440, 0])]),
            s=anim([(0, [100, 100, 100]), (10, [108, 92, 100]), (28, [95, 106, 100]),
                    (46, [110, 90, 100]), (56, [100, 100, 100]), (90, [100, 100, 100])]),
        )
        sprout_r = anim([(0, 0), (14, -16), (30, 16), (46, -10), (60, 4), (75, 0), (90, 0)])
        shadow_s = anim([(0, [100, 100, 100]), (10, [104, 104, 100]), (28, [70, 70, 100]),
                         (46, [106, 106, 100]), (56, [100, 100, 100]), (90, [100, 100, 100])])

    if idle:
        # Lottie paints a layer's first group on top, so front to back.
        eyes = [
            gr("Shine", [el(224, 262, 14, 14), el(324, 262, 14, 14), fl(WHITE)]),
            gr("Pupils", [el(214, 276, 40, 48), el(314, 276, 40, 48), fl(INK)]),
            gr("Sclera", [el(206, 268, 68, 78), el(306, 268, 68, 78), fl(WHITE)]),
        ]
        eyes_ks = tf(
            (256, 268),
            s=anim([(0, [100, 100, 100]), (112, [100, 100, 100]), (117, [100, 8, 100]),
                    (122, [100, 100, 100]), (180, [100, 100, 100])]),
        )
        mouth = [gr("Smile", [sh(SMILE), stroke(INK, 8)])]
    else:
        eyes = [gr("Happy", [sh(HAPPY_EYE_L), sh(HAPPY_EYE_R), stroke(INK, 10)])]
        eyes_ks = tf()
        mouth = [
            gr("Tongue", [el(256, 346, 30, 16), fl(TONGUE)]),
            gr("Open", [sh(OPEN_MOUTH), fl(INK)]),
        ]

    layers = [
        {"ddd": 0, "ind": 1, "ty": 3, "nm": "Rig", "sr": 1, "ks": rig, "ao": 0,
         "ip": 0, "op": op, "st": 0, "bm": 0},
        layer(2, "Eyes", eyes, op, parent=1, ks=eyes_ks),
        layer(3, "Face", mouth + [
            gr("Cheeks", [el(170, 318, 48, 28), el(342, 318, 48, 28), fl(CHEEK, 85)]),
        ], op, parent=1),
        layer(4, "Highlight", [
            gr("Belly", [el(256, 360, 150, 96), fl(WHITE, 12)]),
            gr("Sheen", [el(186, 222, 56, 30), fl(WHITE, 38)], rot=-28, anchor=(186, 222)),
        ], op, parent=1),
        layer(5, "Body", [gr("Body", [sh(BODY_PATH), fl(BODY)])], op, parent=1),
        layer(6, "Lip", [gr("Lip", [sh(shifted(BODY_PATH, LIP_OFFSET)), fl(SHADE)])], op, parent=1),
        layer(7, "Sprout", [
            gr("Stem", [sh(STEM), stroke(SHADE, 12)]),
            gr("Leaves", [sh(LEAF_LEFT), sh(LEAF_RIGHT), fl(SHADE)]),
        ], op, parent=1, ks=tf((254, 178), r=sprout_r)),
        layer(8, "Feet", [gr("Feet", [el(196, 440, 80, 46), el(316, 440, 80, 46), fl(SHADE)])],
              op, parent=1),
        layer(9, "Shadow", [gr("Shadow", [el(256, 464, 240, 30), fl((0, 0, 0), 16)])], op,
              ks=tf((256, 464), s=shadow_s)),
    ]
    return {
        "v": "5.7.4", "fr": 60, "ip": 0, "op": op, "w": 512, "h": 512,
        "nm": f"Nudge mascot ({mood})", "ddd": 0, "assets": [], "layers": layers,
    }


# --- icon (Pillow) ---------------------------------------------------------


def bezier_points(path, steps=40):
    v, i, o, c = path
    pts = []
    n = len(v)
    segs = n if c else n - 1
    for k in range(segs):
        a, b = v[k], v[(k + 1) % n]
        p1 = (a[0] + o[k][0], a[1] + o[k][1])
        p2 = (b[0] + i[(k + 1) % n][0], b[1] + i[(k + 1) % n][1])
        for s in range(steps):
            t = s / steps
            mt = 1 - t
            x = mt**3 * a[0] + 3 * mt**2 * t * p1[0] + 3 * mt * t**2 * p2[0] + t**3 * b[0]
            y = mt**3 * a[1] + 3 * mt**2 * t * p1[1] + 3 * mt * t**2 * p2[1] + t**3 * b[1]
            pts.append((x, y))
    if not c:
        pts.append(tuple(v[-1]))
    return pts


def render_hill(size, bg, colour=None):
    """The icon ground: forest, with a grass hill rolling across the bottom
    third, like the meadow band at the top of every tab."""
    from PIL import Image, ImageDraw

    ss = 4
    big = size * ss
    img = Image.new("RGBA", (big, big), bg + (255,))
    d = ImageDraw.Draw(img)
    hill = ([[0, 0.70], [1, 0.64]], [[0, 0], [-0.3, -0.06]], [[0.35, -0.12], [0, 0]], False)
    v, i, o, _ = hill
    pts = bezier_points(([[x * big, y * big] for x, y in v],
                         [[x * big, y * big] for x, y in i],
                         [[x * big, y * big] for x, y in o], False), steps=120)
    d.polygon(pts + [(big, big), (0, big)], fill=(colour or HILL) + (255,))
    return img.resize((size, size), Image.LANCZOS)


def render_icon(size, bg, scale, dy, silhouette=False, body=BODY, shade=SHADE):
    """The idle mascot's first frame on [bg] (None: transparent, or an
    image to draw over), in [body] with a [shade] lip, feet and sprout."""
    from PIL import Image, ImageDraw

    ss = 4
    big = size * ss
    if isinstance(bg, Image.Image):
        start = bg.convert("RGBA").resize((big, big), Image.LANCZOS)
    else:
        start = Image.new("RGBA", (big, big), bg + (255,) if bg else (0, 0, 0, 0))
    canvas = [start]
    k = big / 512 * scale
    off = (big - 512 * k) / 2

    def P(x, y):
        return (off + x * k, off + (y + dy) * k)

    def col(c, a=255):
        return (255, 255, 255, a) if silhouette else c + (a,)

    def paint(draw_fn):
        # ImageDraw overwrites pixels, so every shape gets its own layer
        # and is blended on: translucent shapes must mix with what is below.
        layer = Image.new("RGBA", (big, big), (0, 0, 0, 0))
        draw_fn(ImageDraw.Draw(layer))
        canvas[0] = Image.alpha_composite(canvas[0], layer)

    def ellipse(cx, cy, w, h, c, a=255):
        x0, y0 = P(cx - w / 2, cy - h / 2)
        x1, y1 = P(cx + w / 2, cy + h / 2)
        paint(lambda d: d.ellipse([x0, y0, x1, y1], fill=col(c, a)))

    def poly(path, c, a=255):
        pts = [P(x, y) for x, y in bezier_points(path)]
        paint(lambda d: d.polygon(pts, fill=col(c, a)))

    def line(path, c, w):
        pts = [P(x, y) for x, y in bezier_points(path)]
        r = w * k / 2

        def draw(d):
            d.line(pts, fill=col(c), width=int(w * k), joint="curve")
            for x, y in (pts[0], pts[-1]):
                d.ellipse([x - r, y - r, x + r, y + r], fill=col(c))

        paint(draw)

    if not silhouette:
        ellipse(256, 464, 240, 30, (0, 0, 0), 40)
    ellipse(196, 440, 80, 46, shade)
    ellipse(316, 440, 80, 46, shade)
    line(STEM, shade, 12)
    poly(LEAF_LEFT, shade)
    poly(LEAF_RIGHT, shade)
    poly(shifted(BODY_PATH, LIP_OFFSET), shade)
    poly(BODY_PATH, body)
    if not silhouette:
        ellipse(256, 360, 150, 96, WHITE, 31)
        ellipse(170, 318, 48, 28, CHEEK, 217)
        ellipse(342, 318, 48, 28, CHEEK, 217)
        ellipse(206, 268, 68, 78, WHITE)
        ellipse(306, 268, 68, 78, WHITE)
        ellipse(214, 276, 40, 48, INK)
        ellipse(314, 276, 40, 48, INK)
        ellipse(224, 262, 14, 14, WHITE)
        ellipse(324, 262, 14, 14, WHITE)
        line(SMILE, INK, 8)
    else:
        # Eyes punched out, so the monochrome icon still has a face.
        d = ImageDraw.Draw(canvas[0])
        for cx in (206, 306):
            x0, y0 = P(cx - 34, 268 - 39)
            x1, y1 = P(cx + 34, 268 + 39)
            d.ellipse([x0, y0, x1, y1], fill=(0, 0, 0, 0))
    return canvas[0].resize((size, size), Image.LANCZOS)


ICON_BG = (0x1D, 0x4D, 0x2B)  # the green palette's hero forest
HILL = (0x2A, 0x6E, 0x3A)

# iOS alternate icons, one per non-default palette, switched in when the
# user picks that palette (lib/services/app_icon_service.dart). Ground is
# the palette's hero, the mascot its fill (`AppColors._specs` in
# lib/core/app_colors.dart: the light spec, or the dark one for the black
# palettes, whose light fill would vanish on their hero). Lip and hill are
# derived as the app derives accentEdge and the default icon's hill.
ALT_ICONS = {
    "lagoon": (0x134E4A, 0x14B8A6),
    "grape": (0x3B0764, 0x9333EA),
    "indigo": (0x1E1B4B, 0x4F46E5),
    "berry": (0x500724, 0xF472B6),
    "sunset": (0x7C2D12, 0xFF9600),
    "space": (0x3A3A3C, 0xF2F2F7),
    "midnight": (0x1E3A5F, 0xBFDBFE),
}


def unhex(v):
    return ((v >> 16) & 0xFF, (v >> 8) & 0xFF, v & 0xFF)


def lighten(c, by):
    import colorsys

    h, l, s = colorsys.rgb_to_hls(*(x / 255 for x in c))
    r, g, b = colorsys.hls_to_rgb(h, min(max(l + by, 0), 1), s)
    return (round(r * 255), round(g * 255), round(b * 255))


def write_alt_icons():
    xcassets = os.path.join(ROOT, "ios", "Runner", "Assets.xcassets")
    for name, (hero, fill) in ALT_ICONS.items():
        hero, fill = unhex(hero), unhex(fill)
        ground = render_hill(1024, hero, colour=lighten(hero, 0.1))
        icon = render_icon(1024, ground, 0.8, -10, body=fill, shade=lighten(fill, -0.1))
        folder = os.path.join(xcassets, f"AppIcon-{name}.appiconset")
        os.makedirs(folder, exist_ok=True)
        icon.convert("RGB").save(os.path.join(folder, "icon.png"))
        with open(os.path.join(folder, "Contents.json"), "w", encoding="utf-8") as f:
            json.dump({
                "images": [{"filename": "icon.png", "idiom": "universal",
                            "platform": "ios", "size": "1024x1024"}],
                "info": {"author": "xcode", "version": 1},
            }, f, indent=2)
            f.write("\n")


def main():
    out = os.path.join(ROOT, "assets", "mascot")
    os.makedirs(out, exist_ok=True)
    for mood in ("idle", "cheer"):
        with open(os.path.join(out, f"{mood}.json"), "w", encoding="utf-8") as f:
            json.dump(build(mood), f, separators=(",", ":"))
    if "--no-icon" in sys.argv:
        return
    icon = os.path.join(ROOT, "assets", "icon")
    # Full-bleed icon (iOS, legacy Android): forest ground, mascot large.
    ground = render_hill(1024, ICON_BG)
    render_icon(1024, ground, 0.8, -10).save(os.path.join(icon, "icon.png"))
    # Adaptive: the hill is the background layer, the mascot the foreground,
    # kept inside the 66% safe zone.
    ground.save(os.path.join(icon, "icon_background.png"))
    render_icon(1024, None, 0.6, -10).save(os.path.join(icon, "icon_foreground.png"))
    render_icon(1024, None, 0.6, -10, silhouette=True).save(
        os.path.join(icon, "icon_monochrome.png"))
    write_alt_icons()


if __name__ == "__main__":
    main()
