#!/usr/bin/env python3
"""
stage2_convert_arrow.py — convert the health-arrow cel $0B12 (Stage-2 prereq).

Reuses the Stage-0 pipeline: source $0B12 from dump05_imprison.bin, convert both
parities, pick per Jay's color target (player=orange draw-A no-mirror; guard=blue
draw-B --mirror), trim, write into the NEW content/hud/ category. Also reports the
left-right palindrome check (is --mirror a no-op?).
"""
import os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from sprite_convert import convert_sprite_to_coco3, write_s_file
from stage0_convert_scene6 import load_dump, extract_cel, pick_parity, trim_cols

REPO = os.path.abspath(os.path.join(HERE, '..', '..'))
ADDR = 0x0B12


def decode(packed):
    px = []
    for byte in packed:
        for p in range(4):
            px.append((byte >> (6 - p * 2)) & 3)
    return px


def emit(bitmap, h, w, flip, mirror, label, catdir):
    packed, cw = convert_sprite_to_coco3(bitmap, h, w, start_col=0,
                                         parity_flip=flip, mirror=mirror)
    packed, cw = trim_cols(packed, cw, h)
    d = os.path.join(catdir, label)
    os.makedirs(d, exist_ok=True)
    write_s_file(os.path.join(d, 'converted.s'), label, h, cw, packed,
                 'dump05_imprison.bin', f'addr_{ADDR:04X}', start_col=0)
    o = sum(1 for v in decode(packed) if v == 1)
    b = sum(1 for v in decode(packed) if v == 2)
    return os.path.relpath(d, REPO), o, b, packed, cw


def main():
    dump = load_dump()
    h, w, bitmap = extract_cel(dump, ADDR)
    print(f"$0B12: {h}x{w}  bytes={' '.join('%02X'%x for x in bitmap)}")

    # pick parity per target hue (Jay's rule)
    pf, po, pb, *_ , pnote = pick_parity(bitmap, h, w, 'orange')
    gf, go, gb, *_ , gnote = pick_parity(bitmap, h, w, 'blue')
    print(f"player(orange) parity_flip={pf} -> orange={po} blue={pb} [{pnote}]")
    print(f"guard (blue)   parity_flip={gf} -> orange={go} blue={gb} [{gnote}]")

    catdir = os.path.join(REPO, 'content', 'hud')
    pdir, poo, pbb, ppk, pcw = emit(bitmap, h, w, pf, False, 'arrow_0B12', catdir)
    gdir, goo, gbb, gpk, gcw = emit(bitmap, h, w, gf, True, 'arrow_0B12_mir', catdir)
    print(f"player -> {pdir}  (orange={poo} blue={pbb})")
    print(f"guard  -> {gdir}  (orange={goo} blue={gbb}, --mirror)")

    # PALINDROME check: does --mirror change the packed bytes at the SAME parity?
    un, cwu = convert_sprite_to_coco3(bitmap, h, w, start_col=0, parity_flip=pf, mirror=False)
    mi, cwm = convert_sprite_to_coco3(bitmap, h, w, start_col=0, parity_flip=pf, mirror=True)
    un, _ = trim_cols(un, cwu, h); mi, _ = trim_cols(mi, cwm, h)
    palindrome = (bytes(un) == bytes(mi))
    print(f"PALINDROME (left-right): --mirror {'IS a NO-OP (cel h-symmetric)' if palindrome else 'CHANGES the cel (not h-symmetric)'}")
    # show one row decoded both ways for the report
    print("  player row0 pixels:", ''.join(map(str, decode(ppk)[:pcw*4])))
    print("  guard  row0 pixels:", ''.join(map(str, decode(gpk)[:gcw*4])))


if __name__ == '__main__':
    main()
