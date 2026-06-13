#!/usr/bin/env python3
"""bake_text.py — offline §22 position bake (route i) for CoCo3 text.

Applies the §22.2 formula:
    nominal(N+1) = nominal(N) + trail(N) + 1 + GAP - wlead(N+1)
with inter-letter GAP=1 (§22.3) and inter-word GAP=16 (glyph-m width, §2-F),
then centers the string's visible extent at a target CoCo3 pixel column and
emits per-glyph (byte_col, subbyte) via §20.3 (byte=px//4, subbyte=px%4).

Extents (wlead, trail) — validated against §22.4 for p,r,e,s,n,t.
"""
# wlead, trail per glyph (validated; new glyphs from glyph_extent.py)
EXT = {
    'a': (1, 8), 'b': (1, 9), 'c': (1, 8), 'd': (1, 8), 'e': (1, 8),
    'g': (1, 8), 'h': (1, 9), 'j': (1, 5), 'm': (1, 13), 'n': (1, 9),
    'o': (1, 9), 'p': (1, 10), 'r': (1, 10), 's': (2, 7), 't': (1, 9),
    'y': (1, 10),
}
LETTER_GAP = 1
WORD_GAP = 16     # = glyph-m pixel width (§2-F)
CENTER = 160      # CoCo3 screen-center pixel (320px wide)


def bake(text, center=CENTER):
    glyphs = [c for c in text if c != ' ']
    # nominal positions, anchor first glyph at 0
    nominals = [0]
    prev = None
    pending_gap = LETTER_GAP
    out_order = []
    i = 0
    nom = 0
    first = True
    for ch in text:
        if ch == ' ':
            pending_gap = WORD_GAP
            continue
        if first:
            nom = 0
            first = False
        else:
            ptrail = EXT[prev][1]
            wlead = EXT[ch][0]
            nom = nom + ptrail + 1 + pending_gap - wlead
            pending_gap = LETTER_GAP
        out_order.append((ch, nom))
        prev = ch
    # visible extent
    vis_left = out_order[0][1] + EXT[out_order[0][0]][0]
    last_ch, last_nom = out_order[-1]
    vis_right = last_nom + EXT[last_ch][1]
    vis_w = vis_right - vis_left + 1
    shift = round(center - (vis_left + vis_w / 2.0))
    result = []
    for ch, nom in out_order:
        px = nom + shift
        result.append((ch, px, px // 4, px % 4))
    return result, vis_w


if __name__ == '__main__':
    import sys
    for text in sys.argv[1:]:
        res, vw = bake(text)
        print(f'"{text}"  visible_width={vw}px  centered@{CENTER}')
        for ch, px, byte, sub in res:
            print(f'   {ch}  px={px:3d}  byte={byte:2d} sub={sub}')
