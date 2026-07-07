#!/usr/bin/env python3
"""Generate the Ice 2 app icon: two glass wireframe cubes side by side.

Emits a 1024x1024 master SVG (build/appicon-master.svg) matching the existing
icon's blue tile (inset 100, corner radius ~192, vertical gradient), then the
caller rasterizes it and downscales into AppIcon.appiconset.
"""
import math
import os

K = math.cos(math.radians(30))  # 0.8660254, iso half-width factor


def cube(cx, cy, r, stroke, silhouette=False, fill="#ffffff"):
    """Return SVG for one iso wireframe cube centered at (cx, cy) with radius r.

    silhouette=True returns just the filled hexagon outline (used to occlude the
    cube behind an overlapping one).
    """
    T = (cx, cy - r)
    UR = (cx + K * r, cy - r / 2)
    BR = (cx + K * r, cy + r / 2)
    B = (cx, cy + r)
    BL = (cx - K * r, cy + r / 2)
    UL = (cx - K * r, cy - r / 2)
    C = (cx, cy)

    def p(pt):
        return f"{pt[0]:.2f},{pt[1]:.2f}"

    hexagon = f"M{p(T)} L{p(UR)} L{p(BR)} L{p(B)} L{p(BL)} L{p(UL)} Z"

    if silhouette:
        # slightly grown so the overlapping cube's stroke sits cleanly on the tile
        g = stroke * 0.9
        return f'<path d="{hexagon}" fill="{fill}" stroke="{fill}" stroke-width="{g:.1f}" stroke-linejoin="round"/>'

    top_face = f"M{p(T)} L{p(UR)} L{p(C)} L{p(UL)} Z"
    left_face = f"M{p(UL)} L{p(C)} L{p(B)} L{p(BL)} Z"
    right_face = f"M{p(UR)} L{p(BR)} L{p(B)} L{p(C)} Z"
    inner = f"M{p(UL)} L{p(C)} L{p(UR)} M{p(C)} L{p(B)}"

    # subtle glass glints echoing the original: a chevron on the top face and a
    # short vertical glint hugging the near edge on each lower face.
    def lerp(a, b, t):
        return (a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t)

    def shift(pt, ref_from, ref_to, t):
        # nudge pt by t of the vector (ref_from -> ref_to)
        return (pt[0] + (ref_to[0] - ref_from[0]) * t, pt[1] + (ref_to[1] - ref_from[1]) * t)

    # top-face chevron highlight (points downward, parallel to the front edges)
    h1a = lerp(C, UL, 0.5)
    h1t = lerp(T, C, 0.42)
    h1b = lerp(C, UR, 0.5)
    top_hi = f"M{p(h1a)} Q{p(h1t)} {p(h1b)}"
    # left face: short glint just inside the C->B edge, bowing toward BL
    lstart = shift(lerp(C, B, 0.14), C, BL, 0.10)
    lend = shift(lerp(C, B, 0.60), C, BL, 0.14)
    lctrl = shift(lerp(C, B, 0.37), C, BL, 0.26)
    left_hi = f"M{p(lstart)} Q{p(lctrl)} {p(lend)}"
    # right face: mirror, bowing toward BR
    rstart = shift(lerp(C, B, 0.14), C, BR, 0.10)
    rend = shift(lerp(C, B, 0.60), C, BR, 0.14)
    rctrl = shift(lerp(C, B, 0.37), C, BR, 0.26)
    right_hi = f"M{p(rstart)} Q{p(rctrl)} {p(rend)}"

    hw = stroke * 0.42  # highlight stroke width
    return (
        f'<path d="{top_face}" fill="{fill}" fill-opacity="0.24"/>'
        f'<path d="{left_face}" fill="{fill}" fill-opacity="0.13"/>'
        f'<path d="{right_face}" fill="{fill}" fill-opacity="0.05"/>'
        f'<path d="{top_hi}" fill="none" stroke="{fill}" stroke-opacity="0.45" '
        f'stroke-width="{hw:.1f}" stroke-linecap="round"/>'
        f'<path d="{left_hi}" fill="none" stroke="{fill}" stroke-opacity="0.32" '
        f'stroke-width="{hw:.1f}" stroke-linecap="round"/>'
        f'<path d="{right_hi}" fill="none" stroke="{fill}" stroke-opacity="0.22" '
        f'stroke-width="{hw:.1f}" stroke-linecap="round"/>'
        f'<path d="{hexagon}" fill="none" stroke="{fill}" stroke-width="{stroke}" stroke-linejoin="round"/>'
        f'<path d="{inner}" fill="none" stroke="{fill}" stroke-width="{stroke}" '
        f'stroke-linecap="round" stroke-linejoin="round"/>'
    )


def build_svg():
    R = 178          # cube radius
    STROKE = 30      # white line weight
    # left cube: back/up-left; right cube: forward, nudged down-right
    lcx, lcy = 405, 500
    rcx, rcy = 638, 545

    back = cube(lcx, lcy, R, STROKE)
    mask = cube(rcx, rcy, R, STROKE, silhouette=True, fill="#233a86")
    front = cube(rcx, rcy, R, STROKE)

    return f'''<svg width="1024" height="1024" viewBox="0 0 1024 1024" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="tile" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#2d4b9c"/>
      <stop offset="1" stop-color="#1e3d99"/>
    </linearGradient>
    <filter id="shadow" x="-10%" y="-10%" width="120%" height="125%">
      <feDropShadow dx="0" dy="10" stdDeviation="14" flood-color="#000000" flood-opacity="0.28"/>
    </filter>
  </defs>
  <g filter="url(#shadow)">
    <rect x="100" y="100" width="824" height="824" rx="192" ry="192" fill="url(#tile)"/>
  </g>
  <g>
    {back}
    {mask}
    {front}
  </g>
</svg>
'''


def main():
    os.makedirs("build", exist_ok=True)
    svg = build_svg()
    with open("build/appicon-master.svg", "w") as f:
        f.write(svg)
    print("wrote build/appicon-master.svg")


if __name__ == "__main__":
    main()
