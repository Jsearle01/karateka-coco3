#!/usr/bin/env python3
"""glyph_extent.py — compute §22.1 visible-extent (wlead, trail) for a
converted CoCo3 glyph, directly from its 2bpp bitmap data.

§22.1 definitions:
  wlead = pixel-column offset (from the glyph's left edge / nominal blit
          position) to the FIRST white (index 3) pixel anywhere in the glyph.
  trail = pixel-column offset to the LAST non-black (index != 0) pixel.
  (subbyte-invariant, so measured on the unshifted converted bitmap.)

The converter lacks an extent capability; §22.4 says authoritative values
come "from data" — this is that computation. Validated against §22.4's
hand-measured p,r,e,s,n,t before use on new glyphs.
"""
import re
import sys


def parse_glyph(path):
    """Return (height, width_bytes, [pixel rows as byte lists])."""
    rows = []
    fcb_re = re.compile(r'^\s*fcb\s+(.+?)(?:;.*)?$', re.IGNORECASE)
    seen_header = False
    h = w = None
    for line in open(path):
        m = fcb_re.match(line)
        if not m:
            continue
        vals = []
        for tok in m.group(1).split(','):
            tok = tok.strip()
            if tok.startswith('$'):
                vals.append(int(tok[1:], 16))
            elif tok:
                vals.append(int(tok))
        if not seen_header:
            h, w = vals[0], vals[1]
            seen_header = True
        else:
            rows.append(vals)
    return h, w, rows


def extent(path):
    h, w, rows = parse_glyph(path)
    width_px = w * 4
    first_white = None   # wlead: first col with a white(3) pixel
    last_nonblack = None  # trail: last col with any non-black pixel
    for row in rows:
        for bi, byte in enumerate(row):
            for p in range(4):                      # MSB-first: px0=bits7:6
                col = bi * 4 + p
                idx = (byte >> (6 - 2 * p)) & 3
                if idx != 0:
                    last_nonblack = col if last_nonblack is None else max(last_nonblack, col)
                if idx == 3 and first_white is None:
                    first_white = col
                elif idx == 3:
                    first_white = min(first_white, col)
    wlead = first_white if first_white is not None else 0
    trail = last_nonblack if last_nonblack is not None else 0
    return h, width_px, wlead, trail


if __name__ == '__main__':
    for path in sys.argv[1:]:
        h, wpx, wlead, trail = extent(path)
        vis = trail - wlead + 1
        print(f"{path}: H={h} Wpx={wpx} wlead={wlead} trail={trail} visible_width={vis}")
