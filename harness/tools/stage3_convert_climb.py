#!/usr/bin/env python3
"""
stage3_convert_climb.py — Stage-0 addendum: convert the CLIMB-START tableau cels.

The climb-window investigation (Jay-confirmed 48fb14d) + the $03-census (this
dispatch, canonical consume point $1A78, dims-validated) pinned the climb cels:

  PLAYER climb poses (content/player/, ORANGE-dominant, draw-A, Jay's pose rule):
    $A3C5 $A3E9 $A40B $A425 $A45A $A4A4 $A4D2 $A4F2 $A548 $A572 $A5CC $A5DC
    -> pick_parity(target='orange'), start_col=0, no mirror (same as the fight cast).

  CLIFF scenery (content/scenery/, NATIVE color — the parity of the traced render
  column, NOT orange/blue-forced; Jay's hue gate confirms vs scene6_climb_*):
    $AB8E (tiled climbing surface) $AB94 $AB7C  col $0A -> start_col 70
    $AB4A                                       col $00 -> start_col 0
    (sub-byte shift $10 = 0 for every climb cel, so start_col = byte_col*7.)

Ground/floor ($AA11/$AA7D/$AA23/$AA31) + Fuji ($A948/$A976/$A9B8/$A9E2) are ALREADY
in content/background/ (bg converter) — not re-converted here. $AA03/$AB03/$AA02/
$A400/$A500/$A502/$A602 were $04-census page-crossing ARTIFACTS (absent from the
canonical census) — NOT real cels, not converted.

Source: dump05_imprison.bin (64K, offset==addr) — validated: dump[addr] h/w matches
the live-memory census for all cels. Does NOT touch the ROM. New dirs stay untracked
until Jay's hue gate.
"""
import os, sys, argparse

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from sprite_convert import convert_sprite_to_coco3, write_s_file
from stage0_convert_scene6 import (load_dump, extract_cel, trim_cols,
                                   pick_parity, count_chroma)

REPO = os.path.abspath(os.path.join(HERE, '..', '..'))

# (addr, byte_col)  — sub-byte shift is 0 for all (traced $10=00)
POSES = [0xA3C5, 0xA3E9, 0xA40B, 0xA425, 0xA45A, 0xA4A4,
         0xA4D2, 0xA4F2, 0xA548, 0xA572, 0xA5CC, 0xA5DC]
# Cliff/scenery cels — (addr, byte_col, subbyte_shift). start_col = col*7 + shift.
# The B1B6 cliff-draw table (idx0-4) authorities the core cliff {AA7D, AB4A, AB7C,
# AB8E, AB94}; AA7D (col$06 base) added after Jay's "missing cliff sprites" note.
# AA23/AA31 (row-100 mountain band, tiled cols 0B/17/23, sh=2) pulled into the climb
# scenery per Jay (2026-07-12) — drawn during the climb, not in the backdrop module.
CLIFF = [(0xAB8E, 0x0A, 0), (0xAB94, 0x0A, 0), (0xAB7C, 0x0A, 0), (0xAB4A, 0x00, 0),
         (0xAA7D, 0x06, 0), (0xAA23, 0x0B, 2), (0xAA31, 0x0B, 2)]

# Jay hue-gate correction (2026-07-12): these poses came out with orange<->blue
# TRANSPOSED — the pick_parity(orange) heuristic chose the wrong parity for them
# (white-dominant figures; the orange/blue lead is within sparse edge chroma, so the
# max-orange pick landed on the swapped parity). Invert the chosen parity_flip.
FLIP_OVERRIDE = {0xA3C5, 0xA4F2, 0xA572}


def emit(catdir, label, h, cw, packed, addr, start_col, dry):
    if dry:
        return
    os.makedirs(catdir, exist_ok=True)
    write_s_file(os.path.join(catdir, 'converted.s'), label, h, cw, packed,
                 'dump05_imprison.bin', f"addr_{addr:04X}", start_col=start_col)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--dry-run', action='store_true')
    ap.add_argument('--manifest', default=os.path.join(REPO, 'build',
                    'stage3-climb-manifest.csv'))
    args = ap.parse_args()
    dump = load_dump()
    rows = []

    # --- PLAYER poses: orange-dominant, draw-A (start_col=0 + pick_parity) ---
    for a in POSES:
        h, w, bitmap = extract_cel(dump, a)
        flip, o, b, wh, bk, note = pick_parity(bitmap, h, w, 'orange')
        if a in FLIP_OVERRIDE:
            flip = not flip
            o, b = b, o                       # dominance swaps with the parity
            note = 'jay-flip(hue-gate swap-fix)'
        packed, cw = convert_sprite_to_coco3(bitmap, h, w, start_col=0,
                                             parity_flip=flip, mirror=False)
        packed, cw = trim_cols(packed, cw, h)
        label = f"scene6_climb_{a:04X}"
        emit(os.path.join(REPO, 'content', 'player', label), label, h, cw,
             packed, a, 0, args.dry_run)
        rows.append((f"{a:04X}", f"{h}x{w}", 'player', 'orange', flip, False, 0,
                     o, b, wh, bk, 'orange' if o > b else ('blue' if b > o else 'tie'),
                     note, f"content/player/{label}"))

    # --- CLIFF scenery: native color at the traced render column ---
    for a, col, sh in CLIFF:
        h, w, bitmap = extract_cel(dump, a)
        sc = col * 7 + sh
        packed, cw = convert_sprite_to_coco3(bitmap, h, w, start_col=sc,
                                             parity_flip=False, mirror=False)
        packed, cw = trim_cols(packed, cw, h)
        o, b, wh, bk = count_chroma(bitmap, h, w, sc, False)
        label = f"scene6_cliff_{a:04X}"
        emit(os.path.join(REPO, 'content', 'scenery', label), label, h, cw,
             packed, a, sc, args.dry_run)
        rows.append((f"{a:04X}", f"{h}x{w}", 'scenery', f'native(col{col:02X})',
                     False, False, sc, o, b, wh, bk,
                     'orange' if o > b else ('blue' if b > o else 'tie/none'),
                     'native-parity', f"content/scenery/{label}"))

    os.makedirs(os.path.dirname(args.manifest), exist_ok=True)
    cols = ['ptr', 'hxw', 'kind', 'target', 'flip', 'mirror', 'start_col', 'orange',
            'blue', 'white', 'black', 'dominant', 'note', 'dir']
    with open(args.manifest, 'w') as f:
        f.write(','.join(cols) + '\n')
        for r in rows:
            f.write(','.join(str(x) for x in r) + '\n')
    print(f"poses: {len(POSES)}  cliff: {len(CLIFF)}  -> content/player + content/scenery")
    print("flags: F1(no-chroma)=%d  F3(half-half)=%d" % (
        sum(1 for r in rows if 'F1' in r[12]),
        sum(1 for r in rows if 'F3' in r[12])))
    print("manifest:", args.manifest)


if __name__ == '__main__':
    main()
