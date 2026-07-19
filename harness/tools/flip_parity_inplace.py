#!/usr/bin/env python3
"""flip_parity_inplace.py — swap blue/orange (chroma index 1<->2) on an already-
converted CoCo3 sprite .s, in place. Byte-identical to re-running sprite_convert.py
with --flip-parity (verified vs eagle_body_9FC4 oracle, 2026-06-14). Use for the
scene-5 fig_* cast that was converted "by address" and has no clean source .s.

Swaps the 2-bit pixel fields 01<->10 on every fcb DATA row; leaves the header
fcb (height,width), labels, and comments untouched. Adds a provenance line.
"""
import sys

def swap_byte(b):
    out = 0
    for sh in (0, 2, 4, 6):
        f = (b >> sh) & 3
        if f == 1:
            f = 2
        elif f == 2:
            f = 1
        out |= f << sh
    return out

def flip_file(path):
    lines = open(path, encoding='utf-8', errors='replace').read().splitlines()
    out = []
    seen_fcb = 0
    inserted = False
    for ln in lines:
        stripped = ln.strip()
        # provenance note right after the start_col comment
        if not inserted and stripped.startswith('* start_col='):
            out.append(ln)
            out.append('*   PARITY-FLIPPED 2026-06-14 (blue<->orange column-parity color fix)')
            inserted = True
            continue
        if stripped.startswith('fcb'):
            seen_fcb += 1
            if seen_fcb == 1:
                out.append(ln)  # header fcb height,width — leave
                continue
            head, _, tail = ln.partition('fcb')
            data, semi, comment = tail.partition(';')
            vals = [v.strip() for v in data.strip().split(',') if v.strip()]
            newvals = []
            for v in vals:
                n = int(v.lstrip('$'), 16) if v.startswith('$') else int(v)
                newvals.append(f'${swap_byte(n):02X}')
            rebuilt = head + 'fcb' + '     ' + ','.join(newvals)
            if semi:
                rebuilt += '  ;' + comment
            out.append(rebuilt)
        else:
            out.append(ln)
    open(path, 'w', encoding='utf-8').write('\n'.join(out) + '\n')
    print(f'flipped {path}')

if __name__ == '__main__':
    for p in sys.argv[1:]:
        flip_file(p)
