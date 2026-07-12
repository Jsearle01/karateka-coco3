#!/usr/bin/env python3
"""
build_scene6_preview.py — one by-type preview sheet for Jay's Stage-0 hue gate.

Reads the Stage-0 manifest, decodes each converted.s (CoCo3 4-color packed), and
montages the cels into per-type sheets (player / guard), each cel labeled with
ptr, dominant color, flip, mirror. Palette matches sprite_visualize.py:
  0 black, 1 orange(255,140,0), 2 blue(0,0,255), 3 white.
PNGs are diagnostic artifacts for Jay's visual review (do not self-certify hue).
"""
import os, sys, csv, re

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, '..', '..'))
from PIL import Image, ImageDraw

PAL = {0: (0, 0, 0), 1: (255, 140, 0), 2: (0, 0, 255), 3: (255, 255, 255)}
SCALE = 3
PAD = 4
COLS = 12


def decode_s(path):
    """Parse a converted.s -> (width_px, height, rows[list of palette-index lists])."""
    h = w = None
    rows = []
    for line in open(path, encoding='utf-8', errors='replace'):
        m = re.search(r'fcb\s+(\d+),(\d+)\s*;\s*height', line)
        if m:
            h, w = int(m.group(1)), int(m.group(2))
            continue
        m = re.search(r'fcb\s+([$0-9A-Fa-f,]+)\s*;\s*row', line)
        if m and w:
            vals = [int(x.strip().lstrip('$'), 16) for x in m.group(1).split(',') if x.strip()]
            px = []
            for byte in vals:
                for p in range(4):
                    px.append((byte >> (6 - p * 2)) & 3)
            rows.append(px[:w * 4])
    return (w * 4 if w else 0), h, rows


def render_cel(path):
    wpx, h, rows = decode_s(path)
    if not rows or not wpx:
        return None
    img = Image.new('RGB', (wpx, h), (40, 40, 40))
    for y, row in enumerate(rows):
        for x, v in enumerate(row[:wpx]):
            img.putpixel((x, y), PAL.get(v, (255, 0, 0)))
    return img.resize((wpx * SCALE, h * SCALE), Image.NEAREST)


def build_sheet(rows, title, out):
    cels = []
    for r in rows:
        p = os.path.join(REPO, r['dir'], 'converted.s')
        if os.path.isfile(p):
            im = render_cel(p)
            if im:
                lbl = f"{r['ptr']} {r['dominant'][:3]}{'m' if r['mirror']=='True' else ''}"
                cels.append((im, lbl, r['note']))
    if not cels:
        return None
    cw = max(im.width for im, _, _ in cels) + PAD * 2
    ch = max(im.height for im, _, _ in cels) + PAD * 2 + 12
    ncol = COLS
    nrow = (len(cels) + ncol - 1) // ncol
    W, H = ncol * cw, nrow * ch + 24
    sheet = Image.new('RGB', (W, H), (24, 24, 24))
    d = ImageDraw.Draw(sheet)
    d.text((6, 6), f"{title}  ({len(cels)} cels)", fill=(230, 230, 230))
    for i, (im, lbl, note) in enumerate(cels):
        cx, cy = (i % ncol) * cw, 24 + (i // ncol) * ch
        sheet.paste(im, (cx + PAD, cy + PAD))
        col = (255, 120, 120) if note.startswith('F') else (200, 200, 200)
        d.text((cx + PAD, cy + im.height + PAD), lbl, fill=col)
    sheet.save(out)
    return out, len(cels)


def scan_content(category):
    """Every content/<category>/<asset>/converted.s -> a preview row, labeled
    with its start_col (0 = BLIND, flagged). Covers ALL asset types for the
    hue gate, not just the combatants from the convert manifest."""
    root = os.path.join(REPO, 'content', category)
    rows = []
    if not os.path.isdir(root):
        return rows
    for name in sorted(os.listdir(root)):
        cs = os.path.join(root, name, 'converted.s')
        if not os.path.isfile(cs):
            continue
        sc = 0
        for line in open(cs, encoding='utf-8', errors='replace'):
            m = re.search(r'start_col=(\d+)', line)
            if m:
                sc = int(m.group(1)); break
        blind = (sc == 0)
        rows.append(dict(ptr=name[:18], dominant='blind' if blind else f'c{sc}',
                         mirror='False', note='F:blind(start_col=0)' if blind else 'ok',
                         dir=os.path.relpath(os.path.join(root, name), REPO)))
    return rows


def main():
    manifest = os.path.join(REPO, 'build', 'scene6-stage0-manifest.csv')
    outdir = os.path.join(REPO, 'build', 'scene6-stage0-preview')
    os.makedirs(outdir, exist_ok=True)
    rows = list(csv.DictReader(open(manifest)))
    # Combatants: from the Stage-0 convert manifest (player=orange / guard=blue).
    for kind, title in [('player', 'SCENE-6 PLAYER combatants (target: ORANGE)'),
                        ('guard', 'SCENE-6 GUARD combatants (target: BLUE, mirrored)')]:
        krows = [r for r in rows if r['kind'] == kind]
        res = build_sheet(krows, title, os.path.join(outdir, f'scene6_{kind}_sheet.png'))
        if res:
            print(f"  {res[0]}  ({res[1]} cels)")
    # Scene-6 background/midground (Fuji stack $A948.. / floor $AA11 / scroll
    # $A684-bank): sourced from stage0_convert_scene6_bg (NOT content/scenery|floor,
    # which are SCENE-5). Rendered under content/background/ when converted.
    for category, title in [('background', 'SCENE-6 BACKGROUND / MIDGROUND (Fuji/floor/scroll)')]:
        srows = scan_content(category)
        res = build_sheet(srows, title, os.path.join(outdir, f'scene6_{category}_sheet.png'))
        if res:
            nblind = sum(1 for r in srows if r['note'].startswith('F'))
            print(f"  {res[0]}  ({res[1]} cels, {nblind} blind)")


if __name__ == '__main__':
    main()
