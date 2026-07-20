#!/usr/bin/env python3
"""gen_stageb0_run.py — compute the CoCo3 registration for the RUN animation, reusing the
EXACT gen_climb_anim registration (x = col*7 + sub + 20; col = (x>>2) + leading_trim,
sub = x & 3) so the run frames register consistently with the climb crawl.

Oracle composition from the clean blit-entry trace build/logs/stageb0_run_attract.txt
(read-taps on $1903/$1906/$1909/$190C, attract f6423-6630 + f8610-8947, 42 pose
observations, every (legs,torso) pairing giving a UNIQUE (dx,dy,rowLegs,rowTorso)).

ANCHOR (execution-confirmed): the LEGS cel is drawn at the player position itself —
legs col == $62 in every steady-state pose (f8791-8870), i.e. legs xadj = 0. So a frame's
origin IS the player X; the torso sits at +dx apple-px. We normalize every frame's legs to
one anchor apple-x (0x13*7 = 133, a real observed steady-state legs X) so the ported block
cycles IN PLACE; the engine (Stage B2) supplies the live X advance. Rows are verbatim oracle.

Prints the [animation] run: rows for content/scene6/scene6_placement.txt.
"""
import os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from sprite_convert import convert_sprite_to_coco3
from stage0_convert_scene6 import load_dump, extract_cel

_DUMP = None
def leading_trim(addr):
    global _DUMP
    if _DUMP is None:
        _DUMP = load_dump()
    h, w, bitmap = extract_cel(_DUMP, addr)
    packed, cw = convert_sprite_to_coco3(bitmap, h, w, start_col=0)
    has = [any(packed[r*cw+c] != 0 for r in range(h)) for c in range(cw)]
    return next((i for i in range(cw) if has[i]), 0)

ANCHOR = 0x13 * 7          # apple-px legs origin (observed steady-state pose, sub 0)
DWELL  = 11                # VBL, steady-state measured (f8802-8947: 11,12,11,11,11,12,...)

def place_px(x_apple, addr):
    """apple pixel X -> CoCo3 (col, sub), same formula as gen_climb_anim.place()."""
    x = x_apple + 20
    return (x >> 2) + leading_trim(addr), x & 3

# (fid, legs_addr, torso_addr, dx, rowLegs, rowTorso) — dx/rows verbatim from the trace
FRAMES = [
    ("s0", 0x9CAF, 0x9E4A,  7, 143, 123),   # run start  (accelerate 1)
    ("s1", 0x9CD7, 0x9E74,  7, 139, 125),   # run start  (accelerate 2)
    ("c0", 0x9B00, 0x9D68,  7, 141, 126),   # cycle
    ("c1", 0x9B6B, 0x9D68, 10, 141, 126),
    ("c2", 0x9BE5, 0x9DD5, 14, 149, 126),
    ("c3", 0x9C1B, 0x9E05,  7, 138, 125),
    ("c4", 0x9B00, 0x9D97,  7, 141, 126),
    ("c5", 0x9B6B, 0x9D97, 10, 141, 126),
    ("c6", 0x9BE5, 0x9DD5, 14, 149, 126),
    ("c7", 0x9C65, 0x9E2E,  7, 138, 125),
    ("e0", 0x9D1E, 0x9E92,  0, 138, 126),   # run stop / settle
]

for fid, legs, torso, dx, rl, rt in FRAMES:
    lc, ls = place_px(ANCHOR, legs)
    tc, ts = place_px(ANCHOR + dx, torso)
    print(f"  {fid:<3} {DWELL:>3}   {legs:04X}:{lc},{ls},{rl}   {torso:04X}:{tc},{ts},{rt}")
