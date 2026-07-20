#!/usr/bin/env python3
"""
test_milestones.py — reproducible gates for the sprite tool's headless-provable core.
Run: python harness/tools/sprite_tool/test_milestones.py
"""
import sys, os, glob
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from celio import roundtrip_ok
from placement_table import Table, ROOT
from frame_assembly import assemble_animation, assemble_static
from pixel_map import ASPECT_W, ASPECT_H, PIXEL_ASPECT, CELL_W, CELL_H, screen_to_sprite, sprite_to_screen_rect

def m1_roundtrip():
    cels = glob.glob(os.path.join(ROOT, "content", "*", "scene6_*", "converted.s"))
    fails = [p for p in cels if not roundtrip_ok(p)[0]]
    print(f"M1 lossless round-trip: {len(cels)} scene-6 cels, {len(fails)} fail")
    for p in fails[:10]:
        print("   FAIL", p, roundtrip_ok(p)[1])
    return len(cels) > 0 and not fails

def m2_assembly():
    t = Table()
    af = assemble_animation(t, "climb_crawl", 0)
    exp = {"A3E9": 21*4+3, "A3C5": 22*4+2}     # sub-byte X = col*4+sub
    ok = all(p.x == exp[p.cel_id] for p in af.placed if p.cel_id in exp) and len(af.placed) == 2
    sf = assemble_static(t, "AB4A")
    ok = ok and sf.placed[0].x == 5*4+0
    print(f"M2 table-driven assembly: climb_crawl[f0] {af.W}x{af.H}px, sub-byte X {'ok' if ok else 'WRONG'}")
    return ok

def m3_mapping():
    print(f"M3 aspect: {ASPECT_W}:{ASPECT_H} = {PIXEL_ASPECT} (narrower-than-tall={PIXEL_ASPECT<1}); cell {CELL_W}x{CELL_H}")
    allok = True
    for z in (1, 2, 3, 5):
        bad = 0
        for sx in range(12):
            for sy in range(12):
                x0, y0, cw, ch = sprite_to_screen_rect(sx, sy, z)
                for dx, dy in [(0, 0), (cw-1, 0), (0, ch-1), (cw-1, ch-1), (cw//2, ch//2)]:
                    if screen_to_sprite(x0+dx, y0+dy, z) != (sx, sy):
                        bad += 1
        allok = allok and bad == 0
        print(f"   zoom {z}x: {'PASS' if bad==0 else f'FAIL {bad}'}")
    return allok

if __name__ == "__main__":
    r = [("M1", m1_roundtrip()), ("M2", m2_assembly()), ("M3-math", m3_mapping())]
    print()
    for name, ok in r:
        print(f"  {name}: {'PASS' if ok else 'FAIL'}")
    sys.exit(0 if all(ok for _, ok in r) else 1)
