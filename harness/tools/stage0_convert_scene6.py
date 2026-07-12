#!/usr/bin/env python3
"""
stage0_convert_scene6.py — Stage-0 mass-convert of the scene-6 cast.

Drives sprite_convert.convert_sprite_to_coco3 over the scene-6 combatant cast,
sourcing each cel's Apple bytes directly from the 64K memory dump
(dump05_imprison.bin, offset == address), applying Jay's three Stage-0 rulings:

  R1  output into the EXISTING content/<category>/ convention (no new tree).
  R2  re-convert existing blind (start_col=0) assets in place (diff-gated).
  R3  PARITY = Jay's authored color target, per sprite:
        player -> ORANGE-dominant interior, guard -> BLUE-dominant interior.
      Implemented by converting BOTH parities and picking the one whose chroma
      count matches the target (flip = swap orange<->blue). Draw-entry from the
      facing trace (ae2502e) is the classifier:
        pure draw-A  -> player  (orange, no mirror)
        pure draw-B  -> guard   (blue,  --mirror  [STATIC draw-B])
        CROSS (both) -> SHARED  -> two variants: player(orange,no-mirror)
                                                 + guard(blue,--mirror)

Reads the facing per-cel log for the cel list (ptr/HxW/entries). Writes a
converted.s per output and a manifest CSV. Preview PNGs via sprite_visualize.py
are rendered by the caller. Does NOT touch the ROM. New-asset dirs stay
untracked until Jay's hue gate; existing-asset re-converts are the tracked diff.
"""
import os, re, sys, argparse

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from sprite_convert import convert_sprite_to_coco3, write_s_file

REPO = os.path.abspath(os.path.join(HERE, '..', '..'))
DUMP = os.path.join(REPO, '..', 'karateka_dissasembly_claude', 'dumps', 'dump05_imprison.bin')
FACELOG = os.path.join(REPO, '..', 'karateka_dissasembly_claude',
                       'build', 'logs', 'guard_facing.log')


def load_dump():
    with open(DUMP, 'rb') as f:
        d = f.read()
    assert len(d) == 65536, f"expected 64K dump, got {len(d)}"
    return d


def extract_cel(dump, addr):
    """Apple sprite record at `addr` in the 64K dump: [h, w, bitmap...]."""
    h = dump[addr]
    w = dump[addr + 1]
    bitmap = list(dump[addr + 2: addr + 2 + h * w])
    return h, w, bitmap


def parse_facelog():
    """Return [{ptr,h,w,has_a,has_b,xmin,xmax,draws}] for cels drawn >= MIN."""
    cels = []
    pat = re.compile(
        r'cel@\$([0-9A-F]+) ptr=\$[0-9A-F]+ (\d+)x(\d+) draws=(\d+) '
        r'par=\w+\([^)]*\) blend=\[[^]]*\] entry=\[([^]]*)\] X=(\d+)-(\d+)')
    with open(FACELOG) as f:
        for line in f:
            m = pat.search(line)
            if not m:
                continue
            ptr, h, w, draws, ent, xmin, xmax = m.groups()
            cels.append(dict(ptr=int(ptr, 16), h=int(h), w=int(w),
                             draws=int(draws),
                             has_a=('A:' in ent or 'Ay:' in ent),
                             has_b=('B:' in ent or 'By:' in ent),
                             xmin=int(xmin), xmax=int(xmax)))
    return cels


def classify(cel):
    """Combatant classification by bank + draw-entry. Returns a 'kind' or None
    (None = not a combatant/arrow this pass; scenery/floor/bg deferred)."""
    a = cel['ptr']
    if 0x8000 <= a <= 0x95FF:       # combatant heads/bodies/legs/arms
        if cel['has_a'] and cel['has_b']:
            return 'shared'
        return 'player' if cel['has_a'] else 'guard'
    if 0x9B00 <= a <= 0x9EFF:       # player run/walk-in cels
        return 'player'
    return None                     # floor/scenery/HUD -> deferred (see report)


def trim_cols(coco3_bitmap, coco3_width, height):
    """Trim leading/trailing all-zero byte columns — same as sprite_convert.py
    main() so outputs match the existing content/ convention (registration is
    then handled by per-frame X-offset align tables, princess pattern)."""
    if coco3_width <= 0:
        return coco3_bitmap, coco3_width
    has = [any(coco3_bitmap[r * coco3_width + c] != 0 for r in range(height))
           for c in range(coco3_width)]
    L = next((i for i in range(coco3_width) if has[i]), 0)
    R = next((i for i in range(coco3_width - 1, -1, -1) if has[i]), coco3_width - 1)
    tw = R - L + 1
    if tw >= coco3_width:
        return coco3_bitmap, coco3_width
    nb = bytearray()
    for r in range(height):
        nb.extend(coco3_bitmap[r * coco3_width + L:r * coco3_width + R + 1])
    return nb, tw


def count_chroma(bitmap_bytes, h, w, start_col, flip):
    """Convert once; return (orange_count, blue_count, white, black)."""
    packed, cw = convert_sprite_to_coco3(bitmap_bytes, h, w,
                                         start_col=start_col, parity_flip=flip)
    o = b = wh = bk = 0
    for byte in packed:
        for p in range(4):
            v = (byte >> (6 - p * 2)) & 3
            if v == 1: o += 1
            elif v == 2: b += 1
            elif v == 3: wh += 1
            else: bk += 1
    return o, b, wh, bk


def pick_parity(bitmap, h, w, target):
    """Pick parity_flip so the interior dominant chroma matches `target`
    ('orange' or 'blue'). Returns (flip, orange, blue, white, black, note)."""
    # flip=False and flip=True swap orange<->blue; evaluate both.
    o0, b0, wh, bk = count_chroma(bitmap, h, w, 0, False)
    o1, b1, _, _ = count_chroma(bitmap, h, w, 0, True)
    # choose the variant whose dominant chroma == target
    if target == 'orange':
        flip = False if o0 >= b0 else True
    else:
        flip = False if b0 >= o0 else True
    o, b = (o0, b0) if not flip else (o1, b1)
    tot_ch = o + b
    if tot_ch == 0:
        note = 'F1:no-chroma(all-white/black)'
    elif abs(o - b) <= max(1, tot_ch // 10):
        note = 'F3:near-half-and-half'
    else:
        note = 'ok'
    return flip, o, b, wh, bk, note


CATDIR = {'player': 'player', 'guard': 'guard'}


def find_existing_dir(outroot, kind, addr):
    """An existing content/<kind>/<dir> whose name embeds this 4-hex address
    (case-insensitive) = a blind asset to RE-CONVERT IN PLACE (R2). Guard
    in-place is only for a mirrored variant (guard cels are draw-B); a player
    in-place only for a non-mirror variant. Returns the dir path or None."""
    catroot = os.path.join(outroot, CATDIR[kind])
    if not os.path.isdir(catroot):
        return None
    ah = f"{addr:04x}"
    for name in os.listdir(catroot):
        if ah in name.lower() and os.path.isdir(os.path.join(catroot, name)):
            return os.path.join(catroot, name)
    return None


def convert_one(dump, cel, kind, target, mirror, outroot, dry):
    a = cel['ptr']
    h, w, bitmap = extract_cel(dump, a)
    flip, o, b, wh, bk, note = pick_parity(bitmap, h, w, target)
    dom = 'orange' if o > b else ('blue' if b > o else 'tie')
    # R2: re-convert an existing blind dir IN PLACE (tracked diff); else new dir
    # (untracked until Jay's hue gate). A guard variant only reuses an existing
    # dir when it is the mirrored copy (guard = draw-B); a shared cel's player
    # variant that would collide with a guard-only existing dir gets a new dir.
    # In-place R2 is restricted to PLAYER non-mirror cels: a clean color-only
    # (parity) bug-fix with no geometry change, exactly R2's described scope.
    # Guard cels need --mirror (a geometry change) + are often shared, so their
    # existing blind dirs are SUPERSEDED by new assets (flagged for Jay), not
    # silently re-geometried in place.
    existing = find_existing_dir(outroot, kind, a) if (kind == 'player' and not mirror) else None
    if existing:
        catdir, placement = existing, 'in-place(R2)'
    else:
        label = f"scene6_{kind}_{a:04X}" + ("_mir" if mirror else "")
        catdir, placement = os.path.join(outroot, CATDIR[kind], label), 'new(untracked)'
    if not dry:
        os.makedirs(catdir, exist_ok=True)
        label = os.path.basename(catdir)
        packed, cw = convert_sprite_to_coco3(bitmap, h, w, start_col=0,
                                             parity_flip=flip, mirror=mirror)
        packed, cw = trim_cols(packed, cw, h)
        write_s_file(os.path.join(catdir, 'converted.s'), label, h, cw, packed,
                     'dump05_imprison.bin', f"addr_{a:04X}", start_col=0)
    return dict(ptr=f"{a:04X}", kind=kind, target=target, flip=flip,
                mirror=mirror, orange=o, blue=b, white=wh, black=bk,
                dominant=dom, note=note, placement=placement,
                dir=os.path.relpath(catdir, REPO), hxw=f"{h}x{w}")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--min-draws', type=int, default=4)
    ap.add_argument('--outroot', default=os.path.join(REPO, 'content'))
    ap.add_argument('--manifest', default=os.path.join(REPO, 'build',
                    'scene6-stage0-manifest.csv'))
    ap.add_argument('--dry-run', action='store_true')
    args = ap.parse_args()

    dump = load_dump()
    cels = [c for c in parse_facelog() if c['draws'] >= args.min_draws]
    rows = []
    for c in cels:
        kind = classify(c)
        if kind is None:
            rows.append(dict(ptr=f"{c['ptr']:04X}", kind='deferred',
                             target='-', flip='-', mirror='-', orange='-',
                             blue='-', white='-', black='-', dominant='-',
                             note='scenery/floor/HUD - deferred',
                             placement='-', dir='-',
                             hxw=f"{c['h']}x{c['w']}"))
            continue
        if kind == 'shared':
            rows.append(convert_one(dump, c, 'player', 'orange', False,
                                    args.outroot, args.dry_run))
            rows.append(convert_one(dump, c, 'guard', 'blue', True,
                                    args.outroot, args.dry_run))
        elif kind == 'player':
            rows.append(convert_one(dump, c, 'player', 'orange', False,
                                    args.outroot, args.dry_run))
        else:  # guard
            rows.append(convert_one(dump, c, 'guard', 'blue', True,
                                    args.outroot, args.dry_run))

    os.makedirs(os.path.dirname(args.manifest), exist_ok=True)
    cols = ['ptr', 'hxw', 'kind', 'target', 'flip', 'mirror', 'orange',
            'blue', 'white', 'black', 'dominant', 'note', 'placement', 'dir']
    with open(args.manifest, 'w') as f:
        f.write(','.join(cols) + '\n')
        for r in rows:
            f.write(','.join(str(r[k]) for k in cols) + '\n')
    conv = [r for r in rows if r['kind'] != 'deferred']
    print(f"cast cels: {len(cels)}  outputs: {len(conv)}  "
          f"deferred(scenery/floor/HUD): {len(rows)-len(conv)}")
    print(f"flags F1(no-chroma): {sum(1 for r in conv if 'F1' in r['note'])}  "
          f"F3(half-half): {sum(1 for r in conv if 'F3' in r['note'])}")
    print(f"manifest: {args.manifest}")


if __name__ == '__main__':
    main()
