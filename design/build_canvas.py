#!/usr/bin/env python3
"""
Generates the Mananu design canvas: one .dc.html artboard per screen, plus
canvas.json, into design/canvas/.

Every value here is lifted from app/lib/theme/tokens.dart — colours, the type
ramp, spacing, radii, control heights — so the canvas and the Flutter app are
the same design system expressed twice. If a token changes, change it there
first, then here, then re-run:

    python3 design/build_canvas.py

The artboards are static mockups. Copy is literal so it can be retyped in place.
"""
import json
import os
import pathlib

OUT = pathlib.Path(__file__).parent / "canvas"

# ---------------------------------------------------------------- tokens

LIGHT = dict(
    name="light",
    scaffold="#FAF9F5",      # paper
    surface="#FFFFFF",
    raised="#FAF9F5",        # surfaceContainerHighest
    on="#0D1012",            # ink
    on_rgb="13,16,18",
    line="#E4E2DC",
    mist="#858D93",
    primary="#C8912F",       # brass
    on_primary="#FFFFFF",
    indicator="#F6EDD8",     # brassSoft
    measured_bg="#E3F1EC",
    estimated_bg="#F5EFE6",
)
DARK = dict(
    name="dark",
    scaffold="#0A0C0D",
    surface="#16191B",
    raised="#1F2325",
    on="#F2F1ED",
    on_rgb="242,241,237",
    line="#2C3134",
    mist="#8A9298",
    primary="#E0A93F",       # brassBright
    on_primary="#0A0C0D",
    indicator="#1F2325",
    measured_bg="rgba(30,122,95,0.18)",
    estimated_bg="rgba(154,123,79,0.18)",
)

BRASS = "#C8912F"
BRASS_SOFT = "#F6EDD8"
MEASURED = "#1E7A5F"
ESTIMATED = "#9A7B4F"
WARNING = "#B4531E"
DANGER = "#B03A2E"
PROTEIN, CARBS, FAT = "#2F6F8F", "#C8912F", "#8A5A9B"
INK = "#0D1012"

FONT = "Inter, system-ui, -apple-system, 'Helvetica Neue', Helvetica, Arial, sans-serif"
TNUM = "font-variant-numeric:tabular-nums;font-feature-settings:'tnum';"

# Type ramp — MananuType, verbatim.
T_READOUT = f"font-size:76px;font-weight:300;letter-spacing:-2.5px;line-height:1;{TNUM}"
T_DISPLAY = f"font-size:40px;font-weight:600;letter-spacing:-1px;line-height:1.05;{TNUM}"
T_TITLE = "font-size:22px;font-weight:600;letter-spacing:-0.3px;line-height:1.2;"
T_HEADING = "font-size:17px;font-weight:600;letter-spacing:-0.1px;line-height:1.3;"
T_BODY = "font-size:15px;line-height:1.45;"
T_BODY_STRONG = "font-size:15px;line-height:1.45;font-weight:600;"
T_CAPTION = "font-size:13px;line-height:1.35;"
T_LABEL = "font-size:11px;font-weight:700;letter-spacing:0.9px;line-height:1.2;"
T_NUMBER = f"font-size:15px;font-weight:600;{TNUM}"


def alpha(p, a):
    return f"rgba({p['on_rgb']},{a})"


# ---------------------------------------------------------------- icons
# Stroke icons on a 24-grid, one style throughout. Never emoji.

def icon(name, size=24, color="currentColor", stroke=1.8):
    paths = {
        "today": '<rect x="3" y="4" width="18" height="17" rx="2.5"/><path d="M3 9.5h18M8 2.5v4M16 2.5v4"/>',
        "scale": '<rect x="4" y="3" width="16" height="18" rx="3"/><path d="M8.5 9.5a3.5 3.5 0 0 1 7 0M12 9.5l1.6-1.6M8 15.5h8"/>',
        "settings": '<circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-4 0v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83-2.83l.06-.06A1.65 1.65 0 0 0 4.68 15a1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1 0-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 2.83-2.83l.06.06A1.65 1.65 0 0 0 9 4.68a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 2.83l-.06.06A1.65 1.65 0 0 0 19.4 9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1z"/>',
        "plus": '<path d="M12 5v14M5 12h14"/>',
        "search": '<circle cx="11" cy="11" r="7"/><path d="M21 21l-4.35-4.35"/>',
        "camera": '<path d="M23 19a2 2 0 0 1-2 2H3a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h4l2-3h6l2 3h4a2 2 0 0 1 2 2z"/><circle cx="12" cy="13" r="4"/>',
        "drop": '<path d="M12 2.7l5.66 5.66a8 8 0 1 1-11.31 0z"/>',
        "info": '<circle cx="12" cy="12" r="9.5"/><path d="M12 16v-4.5M12 8.2v.1"/>',
        "chevron": '<path d="M9 18l6-6-6-6"/>',
        "tare": '<ellipse cx="12" cy="12" rx="5.5" ry="8.5"/>',
        "weighed": '<path d="M4 8h16M6 8V6.5M18 8V6.5"/><rect x="3" y="10" width="18" height="10" rx="2.5"/><path d="M9 15h6"/>',
        "estimated": '<circle cx="12" cy="12" r="8" stroke-dasharray="2.2 3"/>',
        "cloud-off": '<path d="M22.61 16.95A5 5 0 0 0 18 10h-1.26a8 8 0 0 0-7.05-6M5 5a8 8 0 0 0 4 15h9a5 5 0 0 0 1.7-.3M1 1l22 22"/>',
        "trend-down": '<path d="M23 18l-9.5-9.5-5 5L1 6M17 18h6v-6"/>',
        "check": '<path d="M20 6L9 17l-5-5"/>',
        "shield": '<path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/><path d="M9 12l2 2 4-4"/>',
        "sparkle": '<path d="M12 3l1.9 6.1L20 11l-6.1 1.9L12 19l-1.9-6.1L4 11l6.1-1.9z"/>',
        "download": '<path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4M7 10l5 5 5-5M12 15V3"/>',
        "trash": '<path d="M3 6h18M8 6V4a1 1 0 0 1 1-1h6a1 1 0 0 1 1 1v2M19 6l-1 14a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2L5 6M10 11v6M14 11v6"/>',
        "close": '<path d="M18 6L6 18M6 6l12 12"/>',
        "refresh": '<path d="M21 12a9 9 0 1 1-2.64-6.36"/><path d="M21 3v6h-6"/>',
        "back": '<path d="M19 12H5M12 19l-7-7 7-7"/>',
        "recipe": '<path d="M6 3v18M6 3c3 0 4 2 4 5s-1 5-4 5M18 3v18M18 3c-2 0-3 4-3 7s1 3 3 3"/>',
        "restaurant": '<path d="M7 2v20M7 2c2 0 3 2 3 5s-1 5-3 5-3-2-3-5 1-5 3-5zM17 2v20M17 2c-1.5 0-3 3-3 7 0 2 1 3 3 3"/>',
    }[name]
    return (
        f'<svg width="{size}" height="{size}" viewBox="0 0 24 24" fill="none" '
        f'stroke="{color}" stroke-width="{stroke}" stroke-linecap="round" '
        f'stroke-linejoin="round" aria-hidden="true">{paths}</svg>'
    )


# ---------------------------------------------------------------- primitives

def doc(inner, p, width=390, height=None):
    size = f"height:{height}px;" if height else "min-height:844px;"
    return f"""<!doctype html>
<html>
<head>
  <meta charset="utf-8">
  <script src="./support.js"></script>
</head>
<body>
<x-dc>
<helmet>
  <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&amp;display=swap">
  <style>
    body {{ margin: 0; background: {p['scaffold']}; color: {p['on']}; font-family: {FONT}; -webkit-font-smoothing: antialiased; }}
    a {{ color: {BRASS}; }} a:hover {{ color: {WARNING}; }}
    svg {{ display: block; flex: none; }}
  </style>
</helmet>
<div style="width:{width}px;{size}background:{p['scaffold']};color:{p['on']};display:flex;flex-direction:column;overflow:hidden;position:relative;">
{inner}
</div>
</x-dc>
</body>
</html>
"""


def status_space():
    # Real status bar renders here on a phone. Left empty on purpose.
    return '<div style="height:54px;flex:none;"></div>'


def app_bar(p, title, actions="", leading=""):
    return f"""<div style="height:56px;flex:none;display:flex;align-items:center;gap:8px;padding:0 8px 0 16px;">
  {leading}
  <div style="flex:1;{T_TITLE}color:{p['on']};">{title}</div>
  <div style="display:flex;align-items:center;gap:0;">{actions}</div>
</div>"""


def icon_button(p, name, size=24):
    return f'<div style="width:48px;height:48px;display:flex;align-items:center;justify-content:center;border-radius:24px;">{icon(name, size, p["on"])}</div>'


def section(p, title, child):
    return f"""<div style="display:flex;flex-direction:column;">
  <div style="padding:0 4px 8px 4px;{T_LABEL}text-transform:uppercase;color:{alpha(p, 0.55)};">{title}</div>
  {child}
</div>"""


def card(p, inner, padding="0"):
    return f'<div style="background:{p["surface"]};border:1px solid {p["line"]};border-radius:14px;overflow:hidden;padding:{padding};">{inner}</div>'


def badge(p, weighed=True, label=None, dense=False):
    fg = MEASURED if weighed else ESTIMATED
    bg = p["measured_bg"] if weighed else p["estimated_bg"]
    pad = "2px 6px" if dense else "4px 8px"
    isz = 11 if dense else 13
    fs = 10 if dense else 11
    text = label or ("Weighed" if weighed else "Estimated")
    return (
        f'<div style="display:inline-flex;align-items:center;gap:4px;padding:{pad};border-radius:8px;'
        f'background:{bg};color:{fg};font-size:{fs}px;font-weight:700;letter-spacing:0.9px;line-height:1.2;white-space:nowrap;">'
        f'{icon("weighed" if weighed else "estimated", isz, fg, 2)}<span>{text}</span></div>'
    )


def progress(p, pct, height=8, color=BRASS):
    return (
        f'<div style="height:{height}px;border-radius:999px;background:{p["raised"]};overflow:hidden;">'
        f'<div style="width:{pct}%;height:100%;background:{color};border-radius:999px;"></div></div>'
    )


def filled_button(p, label, icon_name=None, height=54, width="auto"):
    ic = icon(icon_name, 20, p["on_primary"], 2.2) if icon_name else ""
    return (
        f'<div style="height:{height}px;width:{width};display:flex;align-items:center;justify-content:center;gap:8px;'
        f'border-radius:14px;background:{p["primary"]};color:{p["on_primary"]};{T_BODY_STRONG}padding:0 20px;">'
        f'{ic}<span>{label}</span></div>'
    )


def outlined_button(p, label, height=54):
    return (
        f'<div style="height:{height}px;display:flex;align-items:center;justify-content:center;border-radius:14px;'
        f'border:1px solid {p["line"]};color:{p["on"]};{T_BODY_STRONG}padding:0 20px;">{label}</div>'
    )


def nav_bar(p, selected):
    items = [("today", "Today"), ("scale", "Body"), ("settings", "Settings")]
    cells = []
    for key, label in items:
        on = key == selected
        pill_bg = p["indicator"] if on else "transparent"
        cells.append(
            f'<div style="flex:1;display:flex;flex-direction:column;align-items:center;gap:4px;">'
            f'<div style="width:64px;height:32px;border-radius:16px;background:{pill_bg};display:flex;align-items:center;justify-content:center;">'
            f'{icon(key, 24, p["on"], 2.2 if on else 1.8)}</div>'
            f'<div style="{T_CAPTION}font-weight:600;color:{p["on"] if on else alpha(p, 0.7)};">{label}</div></div>'
        )
    return (
        f'<div style="flex:none;height:88px;padding:12px 8px 20px 8px;box-sizing:border-box;background:{p["surface"]};'
        f'border-top:1px solid {p["line"]};display:flex;align-items:flex-start;">{"".join(cells)}</div>'
    )


def fab(p, label="Weigh food"):
    return (
        f'<div style="position:absolute;right:16px;bottom:104px;height:56px;padding:0 20px 0 16px;border-radius:16px;'
        f'background:{p["primary"]};color:{p["on_primary"]};display:flex;align-items:center;gap:8px;font-size:14px;font-weight:600;'
        f'box-shadow:0 6px 16px rgba(13,16,18,0.18);">{icon("plus", 22, p["on_primary"], 2.2)}<span>{label}</span></div>'
    )


def scroll(inner, bottom=168):
    # An inner block, not a flex child, so a tall page never shrinks its cards.
    return (
        f'<div style="flex:1;overflow:hidden;">'
        f'<div style="display:flex;flex-direction:column;gap:24px;padding:8px 16px {bottom}px 16px;">{inner}</div></div>'
    )


def mark(p, height=18):
    # MananuMark: three strokes, the middle one brass. Proportions from
    # theme/instruments.dart (stroke 0.225 h, gap 0.1625 h, width 1.05 h).
    stroke = height * 0.225
    gap = height * 0.1625
    width = height * 1.05
    def bar(c):
        return f'<div style="width:{width:.1f}px;height:{stroke:.1f}px;border-radius:{stroke / 2:.1f}px;background:{c};"></div>'
    return (
        f'<div style="display:flex;flex-direction:column;gap:{gap:.1f}px;" aria-label="Mananu">'
        f'{bar(p["on"])}{bar(BRASS)}{bar(p["on"])}</div>'
    )


def header(p, title, label=None, actions=""):
    # MananuHeader: small label over a 30 px title, the mark (or actions) right.
    lab = (
        f'<div style="{T_LABEL}text-transform:uppercase;color:{alpha(p, 0.5)};">{label}</div><div style="height:2px;"></div>'
        if label else ""
    )
    right = actions or f'<div style="padding-right:8px;">{mark(p)}</div>'
    return f"""<div style="flex:none;display:flex;align-items:center;padding:12px 8px 8px 16px;">
  <div style="flex:1;display:flex;flex-direction:column;">{lab}<div style="{T_DISPLAY}font-size:30px;color:{p['on']};">{title}</div></div>
  <div style="display:flex;align-items:center;">{right}</div>
</div>"""


def arc_gauge(p, progress, inner, size=132, stroke=10):
    # ArcGauge: a 270° arc from 135°, quiet track, brass fill.
    import math
    c = size / 2
    r = c - stroke / 2
    def pt(deg):
        a = math.radians(deg)
        return f"{c + r * math.cos(a):.2f},{c + r * math.sin(a):.2f}"
    def arc(sweep, colour):
        if sweep <= 0:
            return ""
        large = 1 if sweep > 180 else 0
        return (
            f'<path d="M{pt(135)} A{r:.2f},{r:.2f} 0 {large} 1 {pt(135 + sweep)}" fill="none" '
            f'stroke="{colour}" stroke-width="{stroke}" stroke-linecap="round"/>'
        )
    svg = (
        f'<svg width="{size}" height="{size}" viewBox="0 0 {size} {size}" style="position:absolute;inset:0;">'
        f'{arc(270, p["raised"])}{arc(270 * min(progress, 1.0), WARNING if progress > 1 else p["primary"])}</svg>'
    )
    return (
        f'<div style="position:relative;width:{size}px;height:{size}px;flex:none;display:flex;align-items:center;justify-content:center;">'
        f'{svg}<div style="position:relative;display:flex;flex-direction:column;align-items:center;">{inner}</div></div>'
    )


def sparkline(p, values, width=96, height=32):
    # Sparkline: a hint of direction, no axes, dot on the last point.
    lo, hi = min(values), max(values)
    if hi - lo < 0.5:
        mid = (hi + lo) / 2
        lo, hi = mid - 0.25, mid + 0.25
    pad = 4
    pts = []
    for i, v in enumerate(values):
        x = pad + (width - 2 * pad) * i / (len(values) - 1)
        y = pad + (height - 2 * pad) * (hi - v) / (hi - lo)
        pts.append(f"{x:.1f},{y:.1f}")
    lx, ly = pts[-1].split(",")
    return (
        f'<svg width="{width}" height="{height}" viewBox="0 0 {width} {height}">'
        f'<polyline points="{" ".join(pts)}" fill="none" stroke="{BRASS}" stroke-width="2" stroke-linejoin="round" stroke-linecap="round"/>'
        f'<circle cx="{lx}" cy="{ly}" r="4" fill="{p["surface"]}"/><circle cx="{lx}" cy="{ly}" r="3" fill="{BRASS}"/></svg>'
    )


# The persona's last thirty mornings, oldest first. The Body chart and the
# Today sparkline both draw from this list.
WEIGHTS = [80.1, 80.2, 79.7, 80.2, 79.5, 80.4, 79.6, 79.3, 79.9, 79.2, 79.5, 79.0,
           79.6, 78.9, 79.4, 78.7, 79.2, 78.9, 78.6, 79.2, 78.7, 78.5, 78.9, 78.3,
           78.8, 78.3, 78.7, 78.2, 78.5, 78.7]

# ---------------------------------------------------------------- screens

def onboarding(p, height=None):
    segs = "".join(
        f'<div style="flex:1;height:3px;margin:0 2px;border-radius:999px;background:{BRASS if i == 0 else p["line"]};"></div>'
        for i in range(4)
    )
    inner = f"""{status_space()}
<div style="display:flex;padding:16px;">{segs}</div>
<div style="flex:1;display:flex;flex-direction:column;justify-content:center;padding:0 24px;gap:0;">
  <div style="{T_DISPLAY}color:{p['on']};white-space:pre-line;">Weigh it.
Don't guess it.</div>
  <div style="height:16px;"></div>
  <div style="{T_BODY}color:{alpha(p, 0.7)};text-wrap:pretty;">Photo calorie apps guess how much is on your plate, and portion size is where they go wrong. Mananu uses the camera only to work out what the food is. The amount comes off the scale.</div>
  <div style="height:32px;"></div>
  {card(p, f'''<div style="{T_HEADING}color:{p['on']};">What it costs</div>
    <div style="height:8px;"></div>
    <div style="{T_CAPTION}color:{alpha(p, 0.7)};white-space:pre-line;text-wrap:pretty;">Weighing, barcode scanning, manual logging and your body trends are free, forever, with no account limits.

Photo recognition is free for 30 scans a month. Beyond that, Plus is £4.99 a month or £39.99 a year. You can cancel in two taps and nothing renews without telling you first.</div>''', padding="16px")}
</div>
<div style="padding:24px;flex:none;">{filled_button(p, "Continue")}</div>
"""
    return doc(inner, p, height=height)


def today(p, height=None):
    eaten, goal = 1105, 3038
    inside = (
        f'<div style="{T_DISPLAY}font-size:34px;color:{p["on"]};">1,105</div>'
        f'<div style="{T_CAPTION}color:{alpha(p, 0.55)};">kcal</div>'
    )

    def macro(label, grams, target, colour):
        pct = round(grams / target * 100)
        return f"""<div style="flex:1;display:flex;flex-direction:column;">
  <div style="display:flex;align-items:baseline;"><div style="{T_NUMBER}font-size:17px;color:{p['on']};">{grams}</div><div style="{T_CAPTION}color:{alpha(p, 0.5)};">&nbsp;g</div></div>
  <div style="height:4px;"></div>
  <div style="padding-right:12px;">{progress(p, pct, 5, colour)}</div>
  <div style="height:4px;"></div>
  <div style="{T_CAPTION}font-size:11px;color:{alpha(p, 0.5)};">{label} · of {target} g</div>
</div>"""

    energy = card(p, f"""<div style="display:flex;align-items:center;gap:16px;">
  {arc_gauge(p, eaten / goal, inside)}
  <div style="flex:1;display:flex;flex-direction:column;align-items:flex-start;">
    <div style="{T_DISPLAY}font-size:28px;color:{p['on']};">1,933</div>
    <div style="{T_CAPTION}color:{alpha(p, 0.55)};">left of 3,038</div>
    <div style="height:12px;"></div>
    {badge(p, True, "92% weighed")}
    <div style="height:4px;"></div>
    <div style="{T_CAPTION}color:{alpha(p, 0.55)};text-wrap:pretty;">About as accurate as logging gets.</div>
  </div>
</div>
<div style="height:16px;border-bottom:1px solid {p['line']};"></div>
<div style="height:12px;"></div>
<div style="display:flex;">{macro("Protein", 71, 126, PROTEIN)}{macro("Carbs", 127, 420, CARBS)}{macro("Fat", 33, 95, FAT)}</div>
<div style="height:12px;"></div>
<div style="{T_CAPTION}font-size:11px;color:{alpha(p, 0.4)};">From your fat-free mass (Cunningham 1980)</div>
""", padding="24px 24px 16px 24px")

    def meal(time, slot, names, kcal, weighed, label, unsynced=False, last=False):
        sync = (
            f'<div title="Saved on this phone, not yet synced" style="display:flex;align-items:center;margin-left:6px;">{icon("cloud-off", 14, p["mist"], 2)}</div>'
            if unsynced else ""
        )
        border = "" if last else f"border-bottom:1px solid {p['line']};"
        return f"""<div style="display:flex;align-items:center;gap:12px;padding:12px 16px;{border}">
  <div style="width:44px;flex:none;{T_CAPTION}{TNUM}color:{alpha(p, 0.5)};">{time}</div>
  <div style="flex:1;min-width:0;display:flex;flex-direction:column;gap:2px;">
    <div style="display:flex;align-items:center;"><div style="{T_BODY_STRONG}color:{p['on']};">{slot}</div>{sync}</div>
    <div style="{T_CAPTION}color:{alpha(p, 0.6)};text-wrap:pretty;">{names}</div>
  </div>
  <div style="display:flex;flex-direction:column;align-items:flex-end;gap:4px;flex:none;">
    <div style="{T_NUMBER}color:{p['on']};">{kcal} kcal</div>
    {badge(p, weighed, label, dense=True)}
  </div>
</div>"""

    meals = section(p, "Meals", card(p,
        meal("07:40", "Breakfast", "Porridge oats, Greek yogurt", 427, True, "Weighed")
        + meal("12:55", "Lunch", "Chicken breast, grilled, basmati rice, olive oil", 584, True, "Weighed")
        + meal("16:10", "Snack", "Apple, medium", 94, False, "Estimated", unsynced=True, last=True),
    ))

    body = section(p, "Body", card(p, f"""<div style="display:flex;align-items:center;gap:8px;padding:16px;">
  <div style="flex:1;display:flex;flex-direction:column;gap:2px;">
    <div style="{T_TITLE}{TNUM}color:{p['on']};">78.7 kg</div>
    <div style="{T_CAPTION}color:{alpha(p, 0.6)};">Body fat trending at 22.9%</div>
  </div>
  {sparkline(p, WEIGHTS[-14:])}
  {icon("chevron", 24, alpha(p, 0.4))}
</div>"""))

    inner = f"""{status_space()}
{header(p, "Today", "Sunday 6 September")}
{scroll(energy + meals + body)}
{nav_bar(p, "today")}
{fab(p)}
"""
    return doc(inner, p, height=height)


def photo_strip(p, names):
    # _FromPhotoStrip: what the photo recognised, as chips, one tap from the
    # capture flow. The grams still come from the scale.
    chips = "".join(
        f'<div style="height:32px;padding:0 12px;border-radius:8px;border:1px solid {p["line"]};display:flex;align-items:center;'
        f'{T_CAPTION}font-weight:600;color:{p["on"]};white-space:nowrap;">{n}</div>'
        for n in names
    )
    return f"""<div style="flex:none;background:{p['surface']};padding:8px 8px 8px 16px;display:flex;align-items:center;gap:12px;overflow:hidden;">
  <div style="{T_LABEL}color:{alpha(p, 0.45)};white-space:nowrap;">FROM YOUR PHOTO</div>
  <div style="flex:1;display:flex;gap:8px;overflow:hidden;-webkit-mask-image:linear-gradient(90deg,#000 80%,transparent);mask-image:linear-gradient(90deg,#000 80%,transparent);">{chips}</div>
  <div style="width:32px;height:32px;display:flex;align-items:center;justify-content:center;flex:none;">{icon("close", 18, p["on"], 2)}</div>
</div>
<div style="height:1px;background:{p['line']};flex:none;"></div>"""


def weigh_food_inner(p, capturing=True, from_photo=True, grams="235.0", stable=True):
    # _ScaleReadout: the number is the hero. It goes quiet (45 %) while the
    # reading moves and settles to ink, with the brass bar, once it locks.
    bar_w = 72 if stable else 28
    bar_c = BRASS if stable else alpha(p, 0.2)
    delta = (
        f'<div style="height:12px;"></div>'
        f'<div style="padding:8px 12px;border-radius:8px;background:{BRASS_SOFT};{T_CAPTION}font-weight:600;color:{BRASS};">+160.0 g since last ingredient</div>'
        if capturing else ""
    )
    readout = f"""<div style="flex:none;background:{p['surface']};padding:16px 24px 24px 24px;display:flex;flex-direction:column;align-items:center;">
  <div style="display:flex;align-items:center;gap:8px;">
    <div style="width:7px;height:7px;border-radius:999px;background:{MEASURED};"></div>
    <div style="{T_LABEL}color:{alpha(p, 0.55)};">SCALE CONNECTED</div>
  </div>
  <div style="height:16px;"></div>
  <div style="{T_READOUT}color:{p['on'] if stable else alpha(p, 0.45)};">{grams}</div>
  <div style="height:8px;"></div>
  <div style="width:{bar_w}px;height:3px;border-radius:2px;background:{bar_c};"></div>
  <div style="height:8px;"></div>
  <div style="{T_LABEL}color:{alpha(p, 0.5)};">{"GRAMS · SETTLED" if stable else "GRAMS"}</div>
  {delta}
</div>
<div style="height:1px;background:{p['line']};flex:none;"></div>"""

    strip = photo_strip(p, ["Basmati rice", "Chicken tikka", "Coriander"]) if from_photo else ""

    def component(name, grams, kcal, last=False):
        border = "" if last else f"border-bottom:1px solid {p['line']};margin-left:16px;"
        return f"""<div style="display:flex;align-items:center;gap:12px;padding:8px 16px 8px 0;{border}">
  <div style="flex:1;min-width:0;display:flex;flex-direction:column;gap:4px;">
    <div style="{T_BODY_STRONG}color:{p['on']};">{name}</div>
    <div style="display:flex;align-items:center;gap:8px;">{badge(p, True, dense=True)}<div style="{T_CAPTION}color:{alpha(p, 0.6)};">{grams} g</div></div>
  </div>
  <div style="{T_NUMBER}color:{p['on']};">{kcal} kcal</div>
</div>"""

    lst = f'<div style="flex:1;overflow:hidden;padding:8px 0 8px 16px;display:flex;flex-direction:column;">{component("Rice, white, basmati, boiled", 75, 98, last=True)}</div>'

    if capturing:
        action = f"""<div style="flex:none;background:{p['surface']};border-top:1px solid {p['line']};padding:16px;display:flex;flex-direction:column;">
  <div style="{T_BODY_STRONG}color:{p['on']};">Adding: Chicken tikka</div>
  <div style="height:4px;"></div>
  <div style="{T_CAPTION}color:{alpha(p, 0.6)};">Reading has settled. Tap to capture 160.0 g.</div>
  <div style="height:12px;"></div>
  {filled_button(p, "Capture 160.0 g", "check")}
</div>"""
    else:
        def act(name, label, hi=False):
            c = BRASS if hi else p["on"]
            return f'<div style="flex:1;display:flex;flex-direction:column;align-items:center;gap:4px;padding:12px 0;">{icon(name, 22, c)}<div style="{T_CAPTION}font-weight:600;color:{c};">{label}</div></div>'
        action = f"""<div style="flex:none;background:{p['surface']};border-top:1px solid {p['line']};padding:12px 16px;display:flex;">
  {act("search", "Search")}{act("camera", "Photo")}{act("drop", "Cooking oil", True)}
</div>"""

    summary = f"""<div style="flex:none;background:{p['raised']};border-top:1px solid {p['line']};padding:16px 16px 28px 16px;display:flex;align-items:center;gap:12px;">
  <div style="flex:1;display:flex;flex-direction:column;gap:2px;">
    <div style="display:flex;align-items:baseline;gap:4px;">
      <div style="{T_DISPLAY}font-size:30px;color:{p['on']};">98</div>
      <div style="{T_CAPTION}color:{p['on']};">kcal</div>
      <div style="width:4px;"></div>
      <div style="{T_CAPTION}color:{alpha(p, 0.5)};">±5%</div>
    </div>
    <div style="{T_CAPTION}color:{alpha(p, 0.6)};">Weighed · 100% of these calories were weighed</div>
  </div>
  {filled_button(p, "Log meal", height=50, width="112px")}
</div>"""

    return f"""{status_space()}
{app_bar(p, "Weigh food", actions=icon_button(p, "tare"))}
{readout}
{strip}
{lst}
{action}
{summary}
"""


def weigh_food(p, capturing=True, height=None):
    return doc(weigh_food_inner(p, capturing), p, height=height)


def cooking_oil(p, height=None):
    # The Weigh food screen, idle, under a scrim, with the sheet on top. The
    # sheet is absolutely positioned inside the phone root.

    def slider(label, value, pct, suffix="g", decimals=1):
        shown = f"{value:.{decimals}f}{suffix}" if suffix else f"{value:.0f}"
        return f"""<div style="display:flex;flex-direction:column;gap:6px;">
  <div style="display:flex;justify-content:space-between;align-items:center;">
    <div style="{T_CAPTION}color:{p['on']};">{label}</div>
    <div style="{T_NUMBER}color:{p['on']};">{shown}</div>
  </div>
  <div style="position:relative;height:20px;display:flex;align-items:center;">
    <div style="position:absolute;left:0;right:0;height:4px;border-radius:999px;background:{BRASS_SOFT};"></div>
    <div style="position:absolute;left:0;width:{pct}%;height:4px;border-radius:999px;background:{BRASS};"></div>
    <div style="position:absolute;left:calc({pct}% - 10px);width:20px;height:20px;border-radius:999px;background:{BRASS};box-shadow:0 1px 4px rgba(13,16,18,0.2);"></div>
  </div>
</div>"""

    sheet = f"""<div style="position:absolute;inset:0;background:rgba(13,16,18,0.32);"></div>
<div style="position:absolute;left:0;right:0;bottom:0;background:{p['surface']};border-radius:28px 28px 0 0;padding:8px 24px 40px 24px;display:flex;flex-direction:column;">
  <div style="align-self:center;width:32px;height:4px;border-radius:999px;background:{p['mist']};opacity:0.6;"></div>
  <div style="height:16px;"></div>
  <div style="{T_TITLE}color:{p['on']};">Cooking oil</div>
  <div style="height:8px;"></div>
  <div style="{T_BODY}color:{alpha(p, 0.65)};text-wrap:pretty;">Put the pan on the scale and tare it, add the oil, and read it. Afterwards, weigh whatever is left in the pan. The difference went into your food — and it is the one thing a photo can never see.</div>
  <div style="height:24px;"></div>
  <div style="display:flex;flex-direction:column;gap:16px;">
    {slider("Oil added", 15.0, 25)}
    {slider("Left in the pan", 3.0, 5)}
    {slider("Portions from this pan", 2, 14, suffix="", decimals=0)}
  </div>
  <div style="height:16px;"></div>
  <div style="padding:16px;border-radius:14px;background:{BRASS_SOFT};{T_BODY_STRONG}color:{INK};text-wrap:pretty;">6.0 g of oil per portion — 53 kcal that most apps miss entirely.</div>
  <div style="height:16px;"></div>
  {filled_button(p, "Add to meal")}
</div>"""

    return doc(weigh_food_inner(p, capturing=False, from_photo=False) + sheet, p, height=height)


def photo_scan(p, height=None):
    # PhotoIdentifySheet, results stage: the model said what is on the plate,
    # each candidate is matched to the catalogue, and the user taps the one
    # they are weighing now. No grams anywhere on this sheet: the scale has
    # those.
    thumb = """<svg width="56" height="56" viewBox="0 0 56 56" style="border-radius:8px;flex:none;">
<rect width="56" height="56" fill="#E9E4D8"/>
<circle cx="28" cy="29" r="22" fill="#FFFFFF"/><circle cx="28" cy="29" r="17" fill="none" stroke="#E4E2DC"/>
<path d="M14 30c3-8 12-10 18-7 4 2 6 6 4 10-3 5-11 6-16 3-4-2-6-3-6-6z" fill="#EFD9A8"/>
<path d="M26 20c4-3 10-2 13 2 2 3 1 7-2 9-4 2-9 0-11-3-2-3-2-6 0-8z" fill="#C8642F"/>
<path d="M22 24l3-4M35 33l3 2" stroke="#2E7D4F" stroke-width="2" stroke-linecap="round"/>
</svg>"""

    def candidate(name, conf, match, alts=(), last=False):
        sub = (
            f'<div style="{T_CAPTION}color:{alpha(p, 0.6)};text-wrap:pretty;">{match}</div>'
            if match else
            f'<div style="{T_CAPTION}color:{alpha(p, 0.6)};">Not in the food database — search for it instead.</div>'
        )
        chips = "".join(
            f'<div style="height:32px;padding:0 12px;border-radius:8px;border:1px solid {p["line"]};display:flex;align-items:center;{T_CAPTION}color:{p["on"]};white-space:nowrap;">{a}</div>'
            for a in alts
        )
        alt = f'<div style="display:flex;flex-wrap:wrap;gap:8px;padding:0 16px 12px 16px;">{chips}</div>' if alts else ""
        chevron = icon("chevron", 22, alpha(p, 0.5)) if match else ""
        return card(p, f"""<div style="display:flex;align-items:center;gap:12px;padding:12px 16px;">
  <div style="flex:1;min-width:0;display:flex;flex-direction:column;gap:4px;">
    <div style="display:flex;align-items:center;"><div style="flex:1;{T_BODY_STRONG}color:{p['on']};">{name}</div><div style="{T_LABEL}color:{alpha(p, 0.5)};">{conf}</div></div>
    {sub}
  </div>
  {chevron}
</div>{alt}""") + ("" if last else '<div style="height:8px;"></div>')

    fat = card(p, f"""<div style="display:flex;align-items:center;gap:16px;padding:12px 16px;">
    {icon("drop", 24, BRASS)}
    <div style="flex:1;display:flex;flex-direction:column;gap:4px;">
      <div style="{T_BODY_STRONG}color:{p['on']};">Cooked in fat?</div>
      <div style="{T_CAPTION}color:{alpha(p, 0.6)};text-wrap:pretty;">Looks like ghee in the marinade. Weigh the pan before and after to log what the food absorbed — the photo cannot see it.</div>
    </div>
  </div>""")

    sheet = f"""<div style="position:absolute;inset:0;background:rgba(13,16,18,0.32);"></div>
<div style="position:absolute;left:0;right:0;bottom:0;top:170px;background:{p['surface']};border-radius:28px 28px 0 0;padding:8px 24px 24px 24px;display:flex;flex-direction:column;overflow:hidden;">
  <div style="align-self:center;width:32px;height:4px;border-radius:999px;background:{p['mist']};opacity:0.6;flex:none;"></div>
  <div style="height:16px;"></div>
  <div style="display:flex;align-items:center;gap:12px;">
    {thumb}
    <div style="flex:1;{T_TITLE}color:{p['on']};">Tap what you are weighing now</div>
    <div style="width:40px;height:40px;display:flex;align-items:center;justify-content:center;">{icon("refresh", 22, p['on'])}</div>
  </div>
  <div style="height:16px;"></div>
  {candidate("Basmati rice", "LIKELY", "Rice, white, basmati, boiled · 130 kcal / 100 g · CoFID", alts=["Rice, white, boiled", "Rice, brown, boiled"])}
  {candidate("Chicken tikka", "LIKELY", "Chicken tikka, takeaway · 173 kcal / 100 g · CoFID", alts=["Chicken, breast, grilled"])}
  {candidate("Coriander", "POSSIBLY", None, last=True)}
  <div style="height:8px;"></div>
  {fat}
  <div style="height:12px;"></div>
  <div style="{T_CAPTION}color:{alpha(p, 0.5)};text-wrap:pretty;">The photo only says what the food is. The amount is whatever the scale reads when you capture it.</div>
</div>"""
    return doc(weigh_food_inner(p, capturing=False, from_photo=False, grams="0.0", stable=False) + sheet, p, height=height)


def body_chart(p):
    # 30 days of morning weights (dots) with the 7-day rolling median (line).
    # Drawn deliberately: the dots are faint so the noise is visible and the
    # trend is what the eye lands on.
    raw = WEIGHTS
    med = []
    for i in range(len(raw)):
        w = sorted(raw[max(0, i - 6): i + 1])
        m = w[len(w) // 2] if len(w) % 2 else (w[len(w) // 2 - 1] + w[len(w) // 2]) / 2
        med.append(m)
    W, H, L, R, T, B = 342, 150, 6, 44, 10, 26
    lo, hi = 78.0, 80.5  # snapped to the 0.5 kg gridline step, as in the app

    def x(i): return L + i * (W - L - R) / (len(raw) - 1)
    def y(v): return T + (hi - v) * (H - T - B) / (hi - lo)
    dots = "".join(f'<circle cx="{x(i):.1f}" cy="{y(v):.1f}" r="2.6" fill="{p["mist"]}" opacity="0.45"/>' for i, v in enumerate(raw))
    line = " ".join(f"{x(i):.1f},{y(v):.1f}" for i, v in enumerate(med))
    grid = "".join(
        f'<line x1="{L}" x2="{W - R}" y1="{y(v):.1f}" y2="{y(v):.1f}" stroke="{p["line"]}" stroke-width="1"/>'
        f'<text x="{W - R + 6}" y="{y(v) + 4:.1f}" font-size="11" fill="{alpha(p, 0.45)}" font-family="{FONT}" style="{TNUM}">{v:.1f}</text>'
        for v in (80.5, 80.0, 79.5, 79.0, 78.5, 78.0)
    )
    svg = f"""<svg width="{W}" height="{H}" viewBox="0 0 {W} {H}" aria-label="Weight, last 30 days">
{grid}
{dots}
<polyline points="{line}" fill="none" stroke="{BRASS}" stroke-width="2.5" stroke-linejoin="round" stroke-linecap="round"/>
<circle cx="{x(29):.1f}" cy="{y(med[-1]):.1f}" r="4" fill="{BRASS}" stroke="{p['surface']}" stroke-width="2"/>
<text x="{L}" y="{H - 8}" font-size="11" fill="{alpha(p, 0.45)}" font-family="{FONT}">8 Aug</text>
<text x="{W - R}" y="{H - 8}" font-size="11" fill="{alpha(p, 0.45)}" font-family="{FONT}" text-anchor="end">6 Sep</text>
</svg>"""
    return card(p, f"""<div style="{T_LABEL}text-transform:uppercase;color:{alpha(p, 0.5)};">Weight · 30 days</div>
<div style="height:12px;"></div>
{svg}
<div style="height:8px;"></div>
<div style="{T_CAPTION}color:{alpha(p, 0.6)};">The line is the 7-day median. The dots are each reading — that spread is normal.</div>""", padding="24px 24px 20px 24px")


def metric_grid(p, metrics):
    # _MetricGrid: two columns, 12 px gutters, tiles 1.55:1. Each tile is a
    # number with its uncertainty; tapping one opens the caveat and citation.
    tile_w = (390 - 32 - 12) / 2
    tile_h = tile_w / 1.55
    tiles = []
    for label, value, sub, not_measured in metrics:
        face = p["estimated_bg"] if not_measured else p["surface"]
        nm = f'<div style="height:4px;"></div>{badge(p, False, "Not measured", dense=True)}' if not_measured else ""
        tiles.append(f"""<div style="width:{tile_w:.1f}px;height:{tile_h:.1f}px;box-sizing:border-box;padding:12px;border-radius:14px;border:1px solid {p['line']};background:{face};display:flex;flex-direction:column;justify-content:space-between;">
  <div style="display:flex;flex-direction:column;align-items:flex-start;"><div style="{T_CAPTION}font-weight:600;color:{alpha(p, 0.65)};white-space:nowrap;">{label}</div>{nm}</div>
  <div style="display:flex;flex-direction:column;"><div style="{T_DISPLAY}font-size:24px;color:{p['on']};white-space:nowrap;">{value}</div><div style="{T_CAPTION}font-size:11px;color:{alpha(p, 0.45)};white-space:nowrap;">{sub}</div></div>
</div>""")
    return f'<div style="display:flex;flex-wrap:wrap;gap:12px;">{"".join(tiles)}</div>'


def body(p, height=None):
    headline = card(p, f"""<div style="{T_LABEL}text-transform:uppercase;color:{alpha(p, 0.5)};">Body fat · 7-day median</div>
<div style="height:12px;"></div>
<div style="display:flex;align-items:baseline;gap:4px;">
  <div style="{T_DISPLAY}color:{p['on']};">22.9</div>
  <div style="{T_TITLE}color:{alpha(p, 0.6)};">%</div>
  <div style="flex:1;"></div>
  <div style="align-self:center;padding:8px 12px;border-radius:8px;background:{p['raised']};{T_CAPTION}color:{alpha(p, 0.7)};">± 5.0 pts</div>
</div>
<div style="height:12px;"></div>
<div style="{T_CAPTION}color:{alpha(p, 0.6)};text-wrap:pretty;">Today's reading was 22.5 %. Single readings move with hydration; the median is the one to watch.</div>
<div style="height:16px;border-bottom:1px solid {p['line']};"></div>
<div style="height:16px;"></div>
<div style="display:flex;align-items:center;gap:8px;">
  {icon("trend-down", 18, BRASS, 2)}
  <div style="{T_BODY}color:{p['on']};">0.37 kg per week down over three weeks</div>
</div>""", padding="24px")

    reading = section(p, "This reading", metric_grid(p, [
        ("Weight", "78.7 kg", "±0.1 kg", False),
        ("BMI", "24.8", "&nbsp;", False),
        ("Fat-free mass", "61.0 kg", "±3.9 kg", False),
        ("Body fat", "22.5 %", "±5.0 %", False),
        ("Fat mass", "17.7 kg", "±3.9 kg", False),
        ("Body water", "44.0 L", "±3.8 L", False),
        ("Skeletal muscle", "31.9 kg", "±2.7 kg", False),
        ("Bone mass", "3.5 kg", "&nbsp;", True),
        ("Resting energy", "1,842 kcal/day", "±184 kcal/day", False),
    ]))

    method = card(p, f"""<div style="{T_HEADING}color:{p['on']};">How these numbers are worked out</div>
<div style="height:8px;"></div>
<div style="{T_BODY}color:{alpha(p, 0.72)};white-space:pre-line;text-wrap:pretty;">Your scale passes a small current through your body and measures the resistance. Water conducts; fat does not. Everything except your weight is calculated from that one measurement using published equations — Sun (2003) for fat-free mass and body water, Janssen (2000) for skeletal muscle, Cunningham (1980) for resting energy.

Bioimpedance is good at showing change over weeks and poor at absolute figures for one person on one day. Mananu shows you the trend for that reason.</div>""", padding="16px")

    inner = f"""{status_space()}
{header(p, "Body", "Last reading Sun 6 Sep, 07:12", actions=icon_button(p, "info"))}
{scroll(headline + body_chart(p) + reading + method)}
{nav_bar(p, "scale")}
{fab(p)}
"""
    return doc(inner, p, height=height)


def settings(p, height=None):
    def device(title, subtitle, connected, last=False):
        border = "" if last else f"border-bottom:1px solid {p['line']};"
        dot = MEASURED if connected else p["mist"]
        return f"""<div style="display:flex;align-items:flex-start;gap:16px;padding:12px 16px;{border}">
  <div style="width:9px;height:9px;border-radius:999px;background:{dot};margin-top:7px;flex:none;"></div>
  <div style="flex:1;display:flex;flex-direction:column;gap:2px;">
    <div style="{T_BODY_STRONG}color:{p['on']};">{title}</div>
    <div style="{T_CAPTION}color:{alpha(p, 0.6)};">{subtitle}</div>
  </div>
  <div style="{T_CAPTION}color:{alpha(p, 0.6)};white-space:nowrap;margin-top:2px;">{"Connected" if connected else "Not connected"}</div>
</div>"""

    def nav(name, title, subtitle, danger=False, last=False):
        border = "" if last else f"border-bottom:1px solid {p['line']};"
        c = DANGER if danger else p["on"]
        return f"""<div style="display:flex;align-items:center;gap:16px;padding:12px 16px;{border}">
  {icon(name, 21, c)}
  <div style="flex:1;display:flex;flex-direction:column;gap:2px;">
    <div style="{T_BODY_STRONG}color:{c};">{title}</div>
    <div style="{T_CAPTION}color:{alpha(p, 0.6)};">{subtitle}</div>
  </div>
  {icon("chevron", 20, alpha(p, 0.5))}
</div>"""

    scales = section(p, "Your scales", card(p,
        device("Body scale", "Bare feet, hard floor, same time each morning", True)
        + device("Kitchen scale", "Tare between ingredients, or let Mananu take the difference", False, last=True),
    ))
    data = section(p, "Your data", card(p,
        nav("shield", "Body composition consent", "Withdraw at any time. Weight and food logging keep working without it.")
        + nav("sparkle", "Photo recognition", "Meal photos are sent to our AI provider only when you take one. Turn this off and search still works.")
        + nav("download", "Export everything", "Every measurement and meal, as CSV")
        + nav("trash", "Delete my account", "Erased, not hidden. This cannot be undone.", danger=True, last=True),
    ))
    about = section(p, "About", card(p, f"""<div style="{T_CAPTION}color:{WARNING};text-wrap:pretty;">Mananu is not a medical device. It does not diagnose, treat, cure or prevent any disease. Do not use the body scale if you have a pacemaker or another implanted electronic device.</div>
<div style="height:12px;"></div>
<div style="{T_CAPTION}color:{alpha(p, 0.5)};text-wrap:pretty;">Nutrition data: McCance and Widdowson's The Composition of Foods Integrated Dataset, used under the Open Government Licence v3.0; USDA FoodData Central, public domain; barcode data from Open Food Facts under the Open Database Licence.</div>""", padding="16px"))

    inner = f"""{status_space()}
{header(p, "Settings", "mananu")}
{scroll(scales + data + about)}
{nav_bar(p, "settings")}
{fab(p)}
"""
    return doc(inner, p, height=height)


def recipes(p, height=None):
    def recipe(name, per100, yield_g, portions, last=False):
        border = "" if last else f"border-bottom:1px solid {p['line']};"
        return f"""<div style="display:flex;align-items:center;gap:12px;padding:12px 16px;{border}">
  <div style="flex:1;min-width:0;display:flex;flex-direction:column;gap:4px;">
    <div style="{T_BODY_STRONG}color:{p['on']};">{name}</div>
    <div style="display:flex;align-items:center;gap:8px;">{badge(p, True, dense=True)}<div style="{T_CAPTION}color:{alpha(p, 0.6)};white-space:nowrap;">{per100} kcal / 100 g</div></div>
    <div style="{T_CAPTION}color:{alpha(p, 0.45)};">Finished dish {yield_g} g</div>
  </div>
  <div style="height:40px;padding:0 14px;display:flex;align-items:center;border-radius:14px;border:1px solid {p['line']};{T_CAPTION}font-weight:600;color:{p['on']};white-space:nowrap;flex:none;">Log a portion</div>
</div>"""

    explain = card(p, f"""<div style="display:flex;gap:12px;align-items:flex-start;">
  {icon("weighed", 20, BRASS, 2)}
  <div style="{T_CAPTION}color:{alpha(p, 0.7)};text-wrap:pretty;">Weigh the ingredients once, then weigh the finished dish. From then on a plated portion is one number off the scale, correct forever.</div>
</div>""", padding="16px")

    lst = section(p, "Your recipes", card(p,
        recipe("Chicken and rice", 226, 400, 2)
        + recipe("Overnight oats", 142, 250, 1)
        + recipe("Dal", 118, 1160, 4, last=True),
    ))

    inner = f"""{status_space()}
{app_bar(p, "Recipes", leading=icon_button(p, "back"))}
{scroll(explain + lst, bottom=24)}
<div style="padding:0 24px 40px 24px;flex:none;">{filled_button(p, "New recipe", "plus")}</div>
"""
    return doc(inner, p, height=height)


def components(p, height=None):
    sw = lambda hexv, name: (
        f'<div style="display:flex;flex-direction:column;gap:6px;align-items:flex-start;">'
        f'<div style="width:56px;height:40px;border-radius:8px;background:{hexv};border:1px solid {p["line"]};"></div>'
        f'<div style="{T_CAPTION}font-size:11px;color:{alpha(p, 0.7)};">{name}</div>'
        f'<div style="{T_CAPTION}font-size:11px;color:{alpha(p, 0.45)};{TNUM}">{hexv}</div></div>'
    )
    colours = f"""<div style="display:flex;gap:12px;row-gap:16px;flex-wrap:wrap;">
  {sw(INK, "Ink")}{sw("#FAF9F5", "Paper")}{sw(BRASS, "Brass")}{sw(BRASS_SOFT, "Brass soft")}
  {sw(MEASURED, "Measured")}{sw(ESTIMATED, "Estimated")}{sw(WARNING, "Warning")}{sw(DANGER, "Danger")}
  {sw(PROTEIN, "Protein")}{sw(CARBS, "Carbs")}{sw(FAT, "Fat")}
</div>"""
    ramp = f"""<div style="display:flex;flex-direction:column;gap:10px;">
  <div style="{T_READOUT}color:{p['on']};">118.0</div>
  <div style="{T_DISPLAY}color:{p['on']};">Display 40 / 600</div>
  <div style="{T_TITLE}color:{p['on']};">Title 22 / 600</div>
  <div style="{T_HEADING}color:{p['on']};">Heading 17 / 600</div>
  <div style="{T_BODY}color:{p['on']};">Body 15 / 400 — line height 1.45</div>
  <div style="{T_CAPTION}color:{alpha(p, 0.6)};">Caption 13 / 400</div>
  <div style="{T_LABEL}text-transform:uppercase;color:{alpha(p, 0.55)};">Label 11 / 700 / +0.9</div>
</div>"""
    badges = f"""<div style="display:flex;gap:12px;align-items:center;flex-wrap:wrap;">
  {badge(p, True)}{badge(p, False)}{badge(p, True, "91% weighed")}{badge(p, True, dense=True)}{badge(p, False, "Not measured", dense=True)}
</div>"""
    buttons = f"""<div style="display:flex;flex-direction:column;gap:12px;width:280px;">
  {filled_button(p, "Continue")}{filled_button(p, "Capture 160.0 g", "check")}{outlined_button(p, "Cancel")}
</div>"""
    inner = f"""<div style="padding:32px;display:grid;grid-template-columns:repeat(2, minmax(0, 1fr));gap:32px;">
  <div style="display:flex;flex-direction:column;gap:32px;">
    {section(p, "Colour", colours)}
    {section(p, "Provenance", badges)}
    {section(p, "Buttons", buttons)}
  </div>
  <div style="display:flex;flex-direction:column;gap:32px;">
    {section(p, "Type — Inter, tabular figures wherever a number can change", ramp)}
    {section(p, "Card", card(p, f'<div style="{T_HEADING}color:{p["on"]};">Card</div><div style="height:8px;"></div><div style="{T_CAPTION}color:{alpha(p, 0.6)};">Surface, 1 px line, radius 14, no shadow.</div>', padding="16px"))}
  </div>
</div>"""
    return doc(inner, p, width=900, height=height or 760)


# ---------------------------------------------------------------- canvas

# Frame heights. Screens that scroll on a phone are shown full length; the
# values were measured from a headless render and are re-checked whenever the
# content changes (run with MEASURE=1 to emit natural heights instead).
HEIGHTS = {
    "Main": 1100, "Onboarding": 844, "WeighFood": 844, "PhotoScan": 844,
    "CookingOil": 844, "Body": 2060, "Settings": 1280, "TodayDark": 1100,
    "Recipes": 844, "Components": 760,
}
MEASURE = os.environ.get("MEASURE") == "1"


def h(stem):
    return None if MEASURE else HEIGHTS[stem]


ARTBOARDS = [
    ("Main", lambda: today(LIGHT, h("Main")), "Today", 390),
    ("Onboarding", lambda: onboarding(LIGHT, h("Onboarding")), "Onboarding", 390),
    ("WeighFood", lambda: weigh_food(LIGHT, height=h("WeighFood")), "Weigh food", 390),
    ("PhotoScan", lambda: photo_scan(LIGHT, h("PhotoScan")), "Photo scan · results", 390),
    ("CookingOil", lambda: cooking_oil(LIGHT, h("CookingOil")), "Cooking oil", 390),
    ("Body", lambda: body(LIGHT, h("Body")), "Body", 390),
    ("Settings", lambda: settings(LIGHT, h("Settings")), "Settings", 390),
    ("TodayDark", lambda: today(DARK, h("TodayDark")), "Today · dark", 390),
    ("Recipes", lambda: recipes(LIGHT, h("Recipes")), "Recipes · planned (phase 6)", 390),
    ("Components", lambda: components(LIGHT, h("Components")), "Components", 900),
]


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    layout = []
    x = 0
    row1 = ["Main", "Onboarding", "WeighFood", "PhotoScan", "CookingOil", "Body", "Settings"]
    row2 = ["TodayDark", "Recipes", "Components"]
    positions = {}
    for name in row1:
        positions[name] = (x, 0)
        x += 390 + 80
    x = 0
    for name in row2:
        positions[name] = (x, HEIGHTS["Body"] + 120)
        x += (900 if name == "Components" else 390) + 80
    for stem, build, title, w in ARTBOARDS:
        (OUT / f"{stem}.dc.html").write_text(build())
        px, py = positions[stem]
        layout.append({"file": f"{stem}.dc.html", "title": title, "x": px, "y": py, "w": w, "h": HEIGHTS[stem]})
    canvas = {
        "artboards": layout,
        "annotations": [
            {"id": "note-brief", "x": 0, "y": -150, "w": 440,
             "text": "Mananu — app screens. Every value comes from app/lib/theme/tokens.dart: Inter, 14 px cards, 54 px buttons, brass on paper. Green is reserved for weighed values and tan for estimated ones; nothing else uses those two colours.\nToday, Body and Settings show the whole scrolled page; the phone shows the top 844 px."},
            {"id": "note-photo", "x": 1410, "y": -110, "w": 390,
             "text": "Photo scan: the model only says WHAT is on the plate. Every candidate is matched to the food database; the grams come from the scale when the user captures. No quantity is ever asked of the photo."},
            {"id": "note-body", "x": 2350, "y": -110, "w": 390,
             "text": "Body: the trend leads, the reading follows. Median line over faint raw dots so the noise is visible and honest; every tile opens its caveat and citation."},
            {"id": "note-recipes", "x": 470, "y": 1900, "w": 390,
             "text": "Recipes is a proposal for the Phase 6 screen. The model already exists in core/nutrition/portion.dart."},
        ],
        "launch": {"view": "canvas"},
    }
    (OUT / "canvas.json").write_text(json.dumps(canvas, indent=2))
    print(f"wrote {len(ARTBOARDS)} artboards to {OUT}")


if __name__ == "__main__":
    main()
