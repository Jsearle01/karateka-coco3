#!/usr/bin/env python3
"""
stage0_convert_scene6_bg.py — convert the SCENE-6 background/midground.

The scene-6 backdrop is the Mt-Fuji stack ($A948/$A976/$A9B8/$A9E2), the floor
tile ($AA11) and the scrolling midground $A6/$A7/$A8 bank (recon §3) — NOT the
content/scenery|floor dirs (those are SCENE-5, the princess cell).

These are STATIC-position set-dressing drawn via draw-A: each has a single traced
render column (parity by construction), so — unlike the moving combatants — there
is no color-target ambiguity. Convert at the traced pixel column from the
background trace (scene6_bg.log, $A6-$AA range, EXLO disabled). No mirror (draw-A).
Output to content/background/ (a real scene-6 type), untracked until Jay's hue gate.
Source bytes from dump05_imprison.bin (64K, offset==addr).
"""
import os, re, sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from sprite_convert import convert_sprite_to_coco3, write_s_file
from stage0_convert_scene6 import trim_cols, load_dump, extract_cel

REPO = os.path.abspath(os.path.join(HERE, '..', '..'))
BGLOG = os.path.join(REPO, '..', 'karateka_dissasembly_claude',
                     'build', 'logs', 'scene6_bg.log')


def parse_bg():
    """Scene-6 background cels ($A600-$AAFF) with their traced pixel column
    (xmin, whose parity == the trace's par) + entry."""
    pat = re.compile(
        r'cel@\$([0-9A-F]+) ptr=\$[0-9A-F]+ (\d+)x(\d+) draws=(\d+) '
        r'par=(\w+)\([^)]*\) blend=\[[^]]*\] entry=\[([^]]*)\] X=(-?\d+)-(-?\d+)')
    out = []
    for line in open(BGLOG):
        m = pat.search(line)
        if not m:
            continue
        ptr = int(m.group(1), 16)
        if not (0xA600 <= ptr <= 0xAAFF):
            continue
        draws = int(m.group(4))
        if draws < 2:
            continue
        out.append(dict(ptr=ptr, h=int(m.group(2)), w=int(m.group(3)),
                        par=m.group(5), xmin=int(m.group(7)), draws=draws))
    return out


def main():
    dump = load_dump()
    cels = parse_bg()
    outroot = os.path.join(REPO, 'content', 'background')
    manifest = os.path.join(REPO, 'build', 'scene6-stage0-bg-manifest.csv')
    rows = []
    for c in cels:
        a = c['ptr']
        h, w, bitmap = extract_cel(dump, a)
        # traced pixel column carries the correct parity; static -> no ambiguity.
        # Clamp a wrap-artifact xmin (off-screen scroll) to its parity residue.
        col = c['xmin'] if 0 <= c['xmin'] < 280 else (c['xmin'] % 2)
        packed, cw = convert_sprite_to_coco3(bitmap, h, w, start_col=col)
        packed, cw = trim_cols(packed, cw, h)
        # count chroma for the manifest (informational; hue is Jay's gate)
        o = b = 0
        for byte in packed:
            for p in range(4):
                v = (byte >> (6 - p * 2)) & 3
                o += (v == 1); b += (v == 2)
        label = f"scene6_bg_{a:04X}"
        d = os.path.join(outroot, label)
        os.makedirs(d, exist_ok=True)
        write_s_file(os.path.join(d, 'converted.s'), label, h, cw, packed,
                     'dump05_imprison.bin', f"addr_{a:04X}", start_col=col)
        rows.append((f"{a:04X}", f"{h}x{w}", c['par'], col, o, b,
                     'orange' if o > b else ('blue' if b > o else 'tie/none'),
                     os.path.relpath(d, REPO)))
    os.makedirs(os.path.dirname(manifest), exist_ok=True)
    with open(manifest, 'w') as f:
        f.write('ptr,hxw,par,start_col,orange,blue,dominant,dir\n')
        for r in rows:
            f.write(','.join(str(x) for x in r) + '\n')
    print(f"scene-6 background cels converted: {len(rows)} -> content/background/")
    print(f"manifest: {manifest}")


if __name__ == '__main__':
    main()
