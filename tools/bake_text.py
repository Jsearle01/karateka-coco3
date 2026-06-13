#!/usr/bin/env python3
"""bake_text.py — offline text position bake from the ORACLE font metrics.

Oracle-faithful proportional pen model (text_render.s / font_metrics.s):
each character advances the pen by its own per-glyph X-advance
    xstep_px = font_glyph_xstep_byte*7 + font_glyph_xstep_subbyte   (Apple px)
The space ('`' = glyph 0) is drawn-skipped but still advances (1,0 = 7px).
Apple px == CoCo3 px (§19 is a +20 border offset, 1:1 scale), so the
advances carry over unchanged.

Pen model:  draw glyph at pen; pen += xstep(glyph). For a space, advance
only. The visible run is then centered at a target CoCo3 pixel column,
and each drawn glyph emitted as (byte_col, subbyte) = (px//4, px%4).

This supersedes the prior §22 visible-extent bake + the §2-F 16px word-gap:
the oracle word space is 7px, and ALL inter-glyph spacing is the oracle
xstep — not the §22 packing. (wlead/trail are used only to center.)
"""
# Oracle X-advance in pixels (font_glyph_xstep_byte*7 + subbyte), font_metrics.s
XSTEP = {
    ' ': 7, 'a': 8, 'b': 10, 'c': 9, 'd': 9, 'e': 9, 'f': 7, 'g': 9, 'h': 10,
    'i': 4, 'j': 6, 'k': 9, 'l': 7, 'm': 14, 'n': 10, 'o': 10, 'p': 11,
    'q': 11, 'r': 11, 's': 8, 't': 10, 'u': 10, 'v': 11, 'w': 17, 'x': 10,
    'y': 10, 'z': 10, '.': 7, ',': 3, ':': 7, '-': 7,
}
# wlead / trail (validated, §22.4 + §22.4a) — used only for centering bounds
EXT = {
    'a': (1, 8), 'b': (1, 9), 'c': (1, 8), 'd': (1, 8), 'e': (1, 8),
    'g': (1, 8), 'h': (1, 9), 'j': (1, 5), 'm': (1, 13), 'n': (1, 9),
    'o': (1, 9), 'p': (1, 10), 'r': (1, 10), 's': (2, 7), 't': (1, 9),
    'y': (1, 10),
}
CENTER = 160


def bake(text, center=CENTER):
    pen = 0
    drawn = []                       # (char, left_pixel)
    for ch in text:
        if ch != ' ':
            drawn.append((ch, pen))
        pen += XSTEP[ch]
    vis_left = drawn[0][1] + EXT[drawn[0][0]][0]
    last_ch, last_pos = drawn[-1]
    vis_right = last_pos + EXT[last_ch][1]
    vis_w = vis_right - vis_left + 1
    shift = round(center - (vis_left + vis_w / 2.0))
    out = []
    for ch, pos in drawn:
        px = pos + shift
        out.append((ch, px, px // 4, px % 4))
    return out, vis_w


if __name__ == '__main__':
    import sys
    for text in sys.argv[1:]:
        res, vw = bake(text)
        print(f'"{text}"  visible_width={vw}px  centered@{CENTER}  (oracle xstep model)')
        for ch, px, byte, sub in res:
            print(f'   {ch}  px={px:3d}  byte={byte:2d} sub={sub}')
