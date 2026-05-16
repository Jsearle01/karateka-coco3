"""
sprite_render_apple2.py — Render Apple II hi-res sprite source to PNG.

Independent decoder for the Apple II side of the karateka-coco3
sprite conversion pipeline. Used with sprite_visualize.py to verify
conversion correctness via visual comparison.

Color model — empirically derived from MAME Apple II ground truth:
  [ref: MAME apple2e emulation, snaps 0082-0085 in C:\karateka-capture\snap\apple2e\]
  [ref: TASK 1/2 gate 2026-05-16 — screen-col parity; TASK 4 gate 2026-05-16 — leading-edge chroma]

  For each pixel at sprite-local column x, with sprite placed at Apple II
  screen pixel column start_col:
    screen_col = start_col + x

  4-category model (113/113 leading + 110/110 parity validated against snap 0083):

    - pixel OFF                                               → Black
    - pixel ON  + isolated + bit7=1 + screen_col even        → Blue   [MAME verified]
    - pixel ON  + isolated + bit7=1 + screen_col odd         → Orange [MAME verified]
    - pixel ON  + leading of adjacent run + gap_before==1    → Blue/Orange per screen-col parity
    - pixel ON  + leading of adjacent run + gap_before>=2    → White  [no NTSC carrier buildup]
    - pixel ON  + interior or trailing of adjacent run       → White
    - pixel ON  + isolated + bit7=0 + screen_col even        → Green  [predicted, not verified]
    - pixel ON  + isolated + bit7=0 + screen_col odd         → Violet [predicted, not verified]

  gap_before: number of consecutive OFF pixels between end of preceding run
  and start of current run. Threshold gap==1 validated: 113/113 gap=1 runs show
  chroma; 120/120 gap>=2 runs show White. Clean binary cutoff with no exceptions.

  Context-dependency tradeoff (accepted): the conditional rule applies leading-edge
  chroma uniformly at gap==1, regardless of preceding chroma context. Sparse sprites
  (few runs with gap==1) produce less chroma than dense sprites. This correctly
  reproduces Logo 1 (sparse, ~3 chroma runs) vs Logo 2 (dense, ~110 chroma runs).
  Dense and sparse regions within a single sprite are handled automatically.

  Screen-col parity rule: color depends on (start_col + local_col) % 2, NOT
  local-col parity alone. Diverges for even-start sprites (Logo 2 at col 84).
    bit7=1: Blue (even screen col) or Orange (odd screen col)
    bit7=0: Green (even) or Violet (odd) — predicted by spec, not MAME-validated

  Karateka logo starting columns (Apple II screen pixel col):
    broderbund_logo_sprite_1: start_col=119
    broderbund_logo_sprite_2: start_col=84

  Cross-byte adjacency handled in run-detection scan (scans full width_pixels
  range, so byte boundaries are transparent to the run finder).
"""

import argparse
import re
import sys

try:
    from PIL import Image
except ImportError:
    print("ERROR: PIL/Pillow required. Install: pip install Pillow")
    sys.exit(1)

# Apple II hires colors — empirically validated against MAME ground truth
# [ref: MAME apple2e 2026-05-15 verification of Karateka Logo 1 and Logo 2]
# [ref: TASK 1/2 gate 2026-05-16 — screen-col parity rule; corrects prior local-col rule]
COLOR_BLACK  = (  0,   0,   0)   # pixel OFF
COLOR_BLUE   = (  0,   0, 255)   # bit7=1 + even screen col isolated ON [MAME verified]
COLOR_ORANGE = (255, 140,   0)   # bit7=1 + odd screen col isolated ON  [MAME verified]
COLOR_GREEN  = (  0, 255,   0)   # bit7=0 + even screen col isolated ON (predicted, not verified)
COLOR_VIOLET = (150,   0, 200)   # bit7=0 + odd screen col isolated ON  (predicted, not verified)
COLOR_WHITE  = (255, 255, 255)   # adjacent ON pair (interior of run)


def parse_byte_directive(line):
    line = re.sub(r';.*$', '', line)
    m = re.search(r'\.byte\s+(.+)$', line, re.IGNORECASE)
    if not m:
        return []
    values = []
    for v in re.split(r',\s*', m.group(1).strip()):
        v = v.strip()
        if not v:
            continue
        if v.startswith('$'):
            values.append(int(v[1:], 16))
        elif v.startswith('%'):
            values.append(int(v[1:], 2))
        elif re.match(r'^\d+$', v):
            values.append(int(v))
    return values


def extract_sprite(source_path, label):
    with open(source_path) as f:
        lines = f.readlines()

    label_re = re.compile(r'^' + re.escape(label) + r'\s*:')
    collecting = False
    raw = []

    for line in lines:
        if label_re.match(line):
            collecting = True
            continue
        if collecting:
            if re.match(r'^[A-Za-z_][A-Za-z0-9_]*\s*:', line):
                break
            raw.extend(parse_byte_directive(line))

    if not collecting:
        raise ValueError(f"Label '{label}' not found")
    if len(raw) < 2:
        raise ValueError(f"Too few bytes for '{label}'")

    height, width_bytes = raw[0], raw[1]
    bitmap = raw[2:2 + height * width_bytes]
    return height, width_bytes, bitmap


def _classify_row(row_data, width_pixels):
    """Pre-scan a row's bytes; return col_info mapping ON pixel col -> (pos_in_run, run_len, gap_before, pal_bit).

    gap_before: OFF pixels between end of preceding run and start of this run.
    First run's gap_before = its start position (≥2 for all karateka sprites).
    """
    col_info = {}
    in_run = False
    run_start = 0
    prev_run_end = None

    for col in range(width_pixels + 1):
        if col < width_pixels:
            byte_idx = col // 7
            bit_pos  = col % 7
            p = (row_data[byte_idx] >> bit_pos) & 1 if byte_idx < len(row_data) else 0
        else:
            p = 0

        if p and not in_run:
            in_run = True
            run_start = col
        elif not p and in_run:
            run_end = col - 1
            run_len = run_end - run_start + 1
            gap = (run_start - prev_run_end - 1) if prev_run_end is not None else run_start
            pal_bit = (row_data[run_start // 7] >> 7) & 1 if run_start // 7 < len(row_data) else 0
            for i in range(run_len):
                col_info[run_start + i] = (i, run_len, gap, pal_bit)
            prev_run_end = run_end
            in_run = False

    return col_info


def render(height, width_bytes, bitmap, output_path, scale=8, start_col=0):
    """Render Apple II sprite to PNG.

    start_col: Apple II screen pixel column where the sprite's left edge appears.
               Required for correct color (screen-col parity rule).
               Karateka: Logo 1 = 119, Logo 2 = 84.
    """
    width_pixels = width_bytes * 7
    img = Image.new('RGB', (width_pixels * scale, height * scale), COLOR_BLACK)
    px = img.load()

    for row in range(height):
        row_data = bitmap[row * width_bytes:(row + 1) * width_bytes]
        col_info = _classify_row(row_data, width_pixels)
        y0 = row * scale

        for col in range(width_pixels):
            if col in col_info:
                pos_in_run, run_len, gap, pal_bit = col_info[col]
                screen_col = start_col + col

                if run_len == 1:
                    # Isolated pixel: chroma at this col, screen-col parity rule.
                    color = (COLOR_BLUE if screen_col % 2 == 0 else COLOR_ORANGE) if pal_bit == 1 \
                            else (COLOR_GREEN if screen_col % 2 == 0 else COLOR_VIOLET)
                    x0 = col * scale
                    for dy in range(scale):
                        for dx in range(scale):
                            px[x0 + dx, y0 + dy] = color

                elif pos_in_run == 0 and gap == 1 and col > 0:
                    # NTSC chroma: gap=1 preceding OFF pixel keeps carrier active,
                    # producing chroma spanning right-sub of OFF col + left-sub of
                    # this ON col. Chroma attributed to this ON pixel (run source);
                    # painted at col-1 to align with sub-pixel render boundary.
                    sc = start_col + col  # ON pixel's screen col drives color
                    chroma = (COLOR_BLUE if sc % 2 == 0 else COLOR_ORANGE) if pal_bit == 1 \
                             else (COLOR_GREEN if sc % 2 == 0 else COLOR_VIOLET)
                    x_c = (col - 1) * scale
                    for dy in range(scale):
                        for dx in range(scale):
                            px[x_c + dx, y0 + dy] = chroma
                    # This ON pixel itself is White (part of the adjacent run body)
                    x0 = col * scale
                    for dy in range(scale):
                        for dx in range(scale):
                            px[x0 + dx, y0 + dy] = COLOR_WHITE

                else:
                    # Interior, trailing, or leading with gap>=2: White
                    x0 = col * scale
                    for dy in range(scale):
                        for dx in range(scale):
                            px[x0 + dx, y0 + dy] = COLOR_WHITE
            else:
                # OFF pixel: Black (already the image default; explicit for clarity)
                x0 = col * scale
                for dy in range(scale):
                    for dx in range(scale):
                        px[x0 + dx, y0 + dy] = COLOR_BLACK

    img.save(output_path)
    print(f"Apple II render: {output_path}  ({width_pixels}×{height} logical px, scale {scale}×, start_col={start_col})")


def main():
    p = argparse.ArgumentParser(description='Render Apple II sprite to PNG')
    p.add_argument('--source', required=True)
    p.add_argument('--label',  required=True)
    p.add_argument('--output', required=True)
    p.add_argument('--scale', type=int, default=8)
    p.add_argument('--start-col', type=int, default=0,
                   help='Apple II screen pixel column of sprite left edge '
                        '(required for correct isolated-pixel color). '
                        'Karateka: Logo1=119, Logo2=84.')
    args = p.parse_args()

    height, width_bytes, bitmap = extract_sprite(args.source, args.label)
    render(height, width_bytes, bitmap, args.output, args.scale, args.start_col)


if __name__ == '__main__':
    main()
