#!/usr/bin/env python3
"""
render.py — aspect-correct, nearest-neighbor render of an assembled frame to a PIL image
(Milestone 3). Headlessly testable: returns a PIL.Image; the Tkinter app wraps it.

Each sprite pixel -> a NON-SQUARE integer cell (CELL_W*z x CELL_H*z), nearest-neighbor.
Palette = the RGB gate set (crawl driver palette_sets set 1: black/orange $26/blue $19/white $3F):
  0 -> TRANS (flat mid-gray, distinct from opaque black — the shadow-task view)
  1 -> orange (255,85,0)   2 -> blue (0,170,255)   3 -> white (255,255,255)
(Opaque-black `f` is the deferred paint-model decision — see the f-refactor plan.)
"""
from pixel_map import CELL_W, CELL_H
try:
    from PIL import Image, ImageDraw
except ImportError:
    Image = None

TRANS_GRAY = (128, 128, 128)
RGB = {0: TRANS_GRAY, 1: (255, 85, 0), 2: (0, 170, 255), 3: (255, 255, 255)}
BG = (40, 40, 40)                 # canvas outside any cel
BOUNDARY = (255, 0, 255)          # cel-boundary overlay

OPAQUE_BLACK = (0, 0, 0)          # index-0 marked opaque (shadow) — solid, distinct from trans gray
CHANGED = (255, 255, 0)           # changed-pixel (New vs Old) highlight

def render_frame(frame, zoom=3, boundaries=True, opacity_by_cel=None, changed_by_cel=None):
    """Render each placed cel, later on top. index 1/2/3 = colours; index 0 = TRANS gray,
    unless opacity_by_cel[cel_id][y][x] is True (opaque shadow) -> solid black.
    changed_by_cel[cel_id] = set of (x,y) local pixels to highlight (New vs Old)."""
    if Image is None:
        raise RuntimeError("Pillow required: pip install pillow")
    cw, ch = CELL_W * zoom, CELL_H * zoom
    img = Image.new("RGB", (frame.W * cw, frame.H * ch), BG)
    px = img.load()
    for p in frame.placed:                        # back to front
        opac = (opacity_by_cel or {}).get(p.cel_id)
        chg = (changed_by_cel or {}).get(p.cel_id, set())
        for cy in range(p.h_px):
            for cx in range(p.w_px):
                val = p.cel.pixels[cy][cx]
                if val == 0 and opac is not None and opac[cy][cx]:
                    color = OPAQUE_BLACK
                elif (cx, cy) in chg:
                    color = CHANGED
                else:
                    color = RGB[val]
                ox = (p.x - frame.x0 + cx) * cw
                oy = (p.y - frame.y0 + cy) * ch
                for yy in range(ch):
                    for xx in range(cw):
                        px[ox + xx, oy + yy] = color
    if boundaries:
        d = ImageDraw.Draw(img)
        for p in frame.placed:
            x0 = (p.x - frame.x0) * cw; y0 = (p.y - frame.y0) * ch
            d.rectangle([x0, y0, x0 + p.w_px * cw - 1, y0 + p.h_px * ch - 1], outline=BOUNDARY)
    return img
