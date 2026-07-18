#!/usr/bin/env python3
"""
stage3_convert_climb.py — Stage-0 addendum: convert the CLIMB-START tableau cels.

The climb-window investigation (Jay-confirmed 48fb14d) + the $03-census (this
dispatch, canonical consume point $1A78, dims-validated) pinned the climb cels:

  PLAYER climb poses (content/player/, draw-A, no mirror):
    $A3C5 $A3E9 $A40B $A425 $A45A $A4A4 $A4D2 $A4F2 $A548 $A572 $A5CC $A5DC
    -> start_col = the cel's TRACED Apple render column (byte_col*7 + sub), parity_flip=False.
       COLUMN-PARITY FIX (2026-07-18): was start_col=0 + pick_parity('orange') + a hand-maintained
       FLIP_OVERRIDE list. That guessed the chroma parity from a max-orange heuristic and hand-patched
       the misses — which silently inverted $A4A4 (it passed its hue gate while blue<->orange swapped).
       Deriving the origin from the real render position (the SAME model the cliff cels below already
       use) makes parity correct per-cel by construction: it reproduces every former FLIP_OVERRIDE
       ($A3C5/$A3E9/$A4F2/$A572) automatically and fixes the missed $A4A4. No heuristic, no override list.

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
                                   count_chroma)

REPO = os.path.abspath(os.path.join(HERE, '..', '..'))

# PLAYER poses: (addr, traced Apple byte_col, sub-byte shift) from the clean blit-entry trace
# (gen_climb_anim FRAMES / build/logs/blitsub.tr). start_col = byte_col*7 + sub. sub=0 for all.
POSES = [(0xA3C5, 0x0A, 0), (0xA3E9, 0x09, 0), (0xA40B, 0x0B, 0), (0xA425, 0x0A, 0),
         (0xA45A, 0x0C, 0), (0xA4A4, 0x0A, 0), (0xA4D2, 0x0B, 0), (0xA4F2, 0x0A, 0),
         (0xA548, 0x0B, 0), (0xA572, 0x0A, 0), (0xA5CC, 0x0C, 0), (0xA5DC, 0x0B, 0)]
# Cliff/scenery cels — (addr, byte_col, subbyte_shift). start_col = col*7 + shift.
# The B1B6 cliff-draw table (idx0-4) authorities the core cliff {AA7D, AB4A, AB7C,
# AB8E, AB94}; AA7D (col$06 base) added after Jay's "missing cliff sprites" note.
# AA23/AA31 (row-100 mountain band, tiled cols 0B/17/23, sh=2) pulled into the climb
# scenery per Jay (2026-07-12) — drawn during the climb, not in the backdrop module.
CLIFF = [(0xAB8E, 0x0A, 0), (0xAB94, 0x0A, 0), (0xAB7C, 0x0A, 0), (0xAB4A, 0x00, 0),
         (0xAA7D, 0x06, 0), (0xAA23, 0x0B, 2), (0xAA31, 0x0B, 2)]

def emit(catdir, label, h, cw, packed, addr, start_col, dry):
    if dry:
        return
    os.makedirs(catdir, exist_ok=True)
    write_s_file(os.path.join(catdir, 'converted.s'), label, h, cw, packed,
                 'dump05_imprison.bin', f"addr_{addr:04X}", start_col=start_col)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--dry-run', action='store_true')
    ap.add_argument('--outroot', default=os.path.join(REPO, 'content'),
                    help='output content root (point at a scratch dir to diff before adopting)')
    ap.add_argument('--manifest', default=os.path.join(REPO, 'build',
                    'stage3-climb-manifest.csv'))
    args = ap.parse_args()
    dump = load_dump()
    rows = []

    # --- PLAYER poses: NATIVE color at the traced render column (start_col = byte_col*7 + sub) ---
    for a, col, sh in POSES:
        h, w, bitmap = extract_cel(dump, a)
        sc = col * 7 + sh
        packed, cw = convert_sprite_to_coco3(bitmap, h, w, start_col=sc,
                                             parity_flip=False, mirror=False)
        packed, cw = trim_cols(packed, cw, h)
        o, b, wh, bk = count_chroma(bitmap, h, w, sc, False)
        label = f"scene6_climb_{a:04X}"
        emit(os.path.join(args.outroot, 'player', label), label, h, cw,
             packed, a, sc, args.dry_run)
        rows.append((f"{a:04X}", f"{h}x{w}", 'player', f'native(col{col:02X})',
                     False, False, sc, o, b, wh, bk,
                     'orange' if o > b else ('blue' if b > o else 'tie/none'),
                     'derived-parity', f"content/player/{label}"))

    # --- CLIFF scenery: native color at the traced render column ---
    for a, col, sh in CLIFF:
        h, w, bitmap = extract_cel(dump, a)
        sc = col * 7 + sh
        packed, cw = convert_sprite_to_coco3(bitmap, h, w, start_col=sc,
                                             parity_flip=False, mirror=False)
        packed, cw = trim_cols(packed, cw, h)
        o, b, wh, bk = count_chroma(bitmap, h, w, sc, False)
        label = f"scene6_cliff_{a:04X}"
        emit(os.path.join(args.outroot, 'scenery', label), label, h, cw,
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
