"""
sound_convert.py — Apple II audio data → CoCo3-ready binaries.

Two sections from sound_data_0e00.s:

  pcm  ($0E00-$0EFF, 256 bytes): PCM sample amplitudes.
       Apple II 8-bit unsigned → CoCo3 6-bit DAC via right-shift by 2.

  tone ($0F00-$0FFF, 256 bytes): Tone records for sound engine.
       Data-driven format; pass through unchanged.
"""

import re
import argparse


def parse_byte_directive(line):
    """Parse a single .byte line; return list of byte values."""
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


def extract_section_bytes(source_path, label):
    """Collect all .byte values from label until the next label."""
    with open(source_path, 'r') as f:
        lines = f.readlines()

    label_pattern = re.compile(r'^' + re.escape(label) + r'\s*:')
    collecting = False
    raw = []

    for line in lines:
        if label_pattern.match(line):
            collecting = True
            continue
        if collecting:
            if re.match(r'^[A-Za-z_][A-Za-z0-9_]*\s*:', line):
                break
            raw.extend(parse_byte_directive(line))

    if not collecting:
        raise ValueError(f"Label '{label}' not found in {source_path}")
    return raw


def convert_pcm_samples(apple_pcm_bytes):
    """Apple II 8-bit unsigned PCM → CoCo3 6-bit DAC samples (right-shift 2)."""
    return bytes(b >> 2 for b in apple_pcm_bytes)


def convert_tone_records(apple_tone_bytes):
    """Pass through; data-driven format is compatible with CoCo3 sound engine."""
    return bytes(apple_tone_bytes)


SECTIONS = {
    'pcm':  ('pcm_samples_0e00',  256, convert_pcm_samples),
    'tone': ('tone_records_0f00', 256, convert_tone_records),
}


def main():
    parser = argparse.ArgumentParser(description='Apple II sound data → CoCo3 converter')
    parser.add_argument('--source', required=True, help='Path to ca65 .s source file')
    parser.add_argument('--section', required=True, choices=['pcm', 'tone'],
                        help='Section to convert: pcm or tone')
    parser.add_argument('--output', required=True, help='Output binary path')
    args = parser.parse_args()

    label, expected_count, converter = SECTIONS[args.section]
    raw = extract_section_bytes(args.source, label)

    if len(raw) != expected_count:
        print(f"WARNING: expected {expected_count} bytes for section '{args.section}', "
              f"got {len(raw)}")

    output = converter(raw)
    with open(args.output, 'wb') as f:
        f.write(output)

    if args.section == 'pcm':
        max_val = max(output) if output else 0
        print(f"PCM: {len(output)} bytes written; max value={max_val} "
              f"({'OK: in 6-bit range' if max_val <= 63 else 'WARNING: exceeds 63'})")
    else:
        print(f"Tone: {len(output)} bytes written (pass-through)")


if __name__ == '__main__':
    main()
