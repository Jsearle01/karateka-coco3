#!/usr/bin/env python3
"""Compute CoCo3 registration for the 7-frame climb crawl, reusing the EXACT
gen_scene6_cliff registration (place + leading_trim) so the 6 new frames register
consistently from the draw_climb_startpose anchor. Oracle (col,sub,row) from the
clean blit-entry trace (build/logs/blitsub.tr). Prints an asm-ready table."""
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

def place(col, sh, row, L):
    x = col*7 + sh + 20
    return (x >> 2) + L, x & 3, row

# frames: (name, dwell, [(label, addr, ocol, osub, orow), ...])  parts back-to-front
FRAMES = [
    ("anim00_start", 21, [("A3E9", 0xA3E9, 0x09,0,0x9E), ("A3C5", 0xA3C5, 0x0A,0,0x8D)]),
    ("anim01",        7, [("A425", 0xA425, 0x0A,0,0x94), ("A40B", 0xA40B, 0x0B,0,0x8C)]),
    ("anim02",        7, [("A4A4", 0xA4A4, 0x0A,0,0x8F), ("A45A", 0xA45A, 0x0C,0,0x8B)]),
    ("anim03",        7, [("A4F2", 0xA4F2, 0x0A,0,0x8F), ("A4D2", 0xA4D2, 0x0B,0,0x89)]),
    ("anim04",        7, [("A572", 0xA572, 0x0A,0,0x8D), ("A548", 0xA548, 0x0B,0,0x83)]),
    ("anim05",        7, [("A5DC", 0xA5DC, 0x0B,0,0x7F), ("A5CC", 0xA5CC, 0x0C,0,0x78)]),
    ("anim06_settle",255,[("899C", 0x899C, 0x0B,1,0x8A), ("8ACB", 0x8ACB, 0x0B,1,0x7C),
                          ("8E9B", 0x8E9B, 0x0C,0,0x74)]),
]

for name, dwell, parts in FRAMES:
    print(f"; {name}  dwell={dwell}")
    for label, addr, oc, os_, orow in parts:
        L = leading_trim(addr)
        byte, sub, row = place(oc, os_, orow, L)
        print(f";   {label}: byte={byte} sub={sub} row={row}  (oracle col={oc:#04x} sub={os_} row={orow:#04x} L={L})")
