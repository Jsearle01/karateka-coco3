#!/usr/bin/env python3
"""
stage3_climb_preview.py — Jay hue-gate sheets for the climb cels (poses + cliff).
Reuses build_scene6_preview.build_sheet/render_cel; reads stage3-climb-manifest.csv.
PNGs are diagnostic — Jay reviews hue (do not self-certify).
"""
import os, sys, csv
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from build_scene6_preview import build_sheet
REPO = os.path.abspath(os.path.join(HERE, '..', '..'))


def main():
    manifest = os.path.join(REPO, 'build', 'stage3-climb-manifest.csv')
    outdir = os.path.join(REPO, 'build', 'stage3-climb-preview')
    os.makedirs(outdir, exist_ok=True)
    rows = list(csv.DictReader(open(manifest)))
    for kind, title in [
        ('player',  'CLIMB player POSES (target: ORANGE; F3 = white-figure weak-orange)'),
        ('scenery', 'CLIMB CLIFF scenery (native parity — Jay grounds vs scene6_climb_*)')]:
        krows = [r for r in rows if r['kind'] == kind]
        res = build_sheet(krows, title, os.path.join(outdir, f'stage3_climb_{kind}.png'))
        if res:
            nf = sum(1 for r in krows if r['note'].startswith('F'))
            print(f"  {res[0]}  ({res[1]} cels, {nf} flagged)")


if __name__ == '__main__':
    main()
