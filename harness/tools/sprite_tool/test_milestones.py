#!/usr/bin/env python3
"""
test_milestones.py — reproducible gates for the sprite tool's headless-provable core.
Run: python harness/tools/sprite_tool/test_milestones.py
"""
import sys, os, glob, tempfile, shutil
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from celio import Cel, roundtrip_ok
from placement_table import Table, ROOT
from frame_assembly import assemble_animation, assemble_static
from pixel_map import ASPECT_W, ASPECT_H, PIXEL_ASPECT, CELL_W, CELL_H, screen_to_sprite, sprite_to_screen_rect
import opacity as O
from lint import lint as opacity_lint

class _Stub:
    def __init__(s, h, w, px): s.h, s.w, s.pixels = h, w, px

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

def m4b_derive_verify():
    def g(h, w): return [[0] * (w * 4) for _ in range(h)]
    ok = True
    # mixed (byte-aligned)
    c = _Stub(2, 2, g(2, 2)); op = O.blank_opacity(c)
    for rr in range(2):
        for k in range(4): op[rr][k] = True
    k, p = O.derive(c, op); v, _ = O.verify(c, op, k, p); ok = ok and k == 'mixed' and v
    # masked (sub-byte, column-uniform)
    c = _Stub(2, 1, g(2, 1)); op = O.blank_opacity(c)
    for rr in range(2): op[rr][0] = op[rr][1] = True
    k, p = O.derive(c, op); v, _ = O.verify(c, op, k, p); ok = ok and k == 'masked' and p == [0xF0] and v
    # STOP (row-varying sub-byte)
    c = _Stub(2, 1, g(2, 1)); op = O.blank_opacity(c)
    op[0][0] = op[0][1] = True; op[1][0] = True
    try:
        O.derive(c, op); ok = False
    except O.CannotEncode:
        pass
    print(f"M4b derive+verify (mixed/masked/STOP, no default): {'PASS' if ok else 'FAIL'}")
    return ok

def m5_save():
    from save import save_cel, read_state
    import sidecar as SC
    src = os.path.join(ROOT, "content", "player", "scene6_climb_A3C5", "converted.s")
    tmp = tempfile.mkdtemp(prefix="spritetool_")
    try:
        cd = os.path.join(tmp, "A3C5"); os.makedirs(cd)
        shutil.copy2(src, os.path.join(cd, "converted.s"))
        tbl = os.path.join(tmp, "table.txt")
        open(tbl, "w", newline="").write("[registry]\r\nA3C5   content/player/scene6_climb_A3C5\r\n")
        orig = open(os.path.join(cd, "converted.s"), newline="").read()
        cel = Cel(os.path.join(cd, "converted.s")); op = O.blank_opacity(cel)
        for rr in range(cel.h):
            for k in range(4):
                if cel.pixels[rr][k] == 0: op[rr][k] = True     # byte-col 0 opaque -> mixed
        state, kind = save_cel(cel, cd, "scene6_climb_A3C5", op, "A3C5", tbl)
        after = open(os.path.join(cd, "converted.s"), newline="").read()
        ok = (after == orig and state == "authored" and kind == "mixed"
              and SC.read_sidecar(cd) == O.derive(cel, op) and read_state(tbl, "A3C5") == "authored")
        print(f"M5 save: opacity-only converted.s byte-identical + sidecar + state=authored: {'PASS' if ok else 'FAIL'}")
        return ok
    finally:
        shutil.rmtree(tmp, ignore_errors=True)

def m5b_lint():
    errs, conv = opacity_lint()
    print(f"M5b lint (real tree clean): {len(errs)} errors, {len(conv)} converted — {'PASS' if not errs else 'FAIL'}")
    return not errs

if __name__ == "__main__":
    r = [("M1", m1_roundtrip()), ("M2", m2_assembly()), ("M3-math", m3_mapping()),
         ("M4b", m4b_derive_verify()), ("M5", m5_save()), ("M5b", m5b_lint())]
    print()
    for name, ok in r:
        print(f"  {name}: {'PASS' if ok else 'FAIL'}")
    sys.exit(0 if all(ok for _, ok in r) else 1)
