#!/usr/bin/env python3
"""
render_pose_set.py — render the live-sequence per-pose framebuffer dumps (pose_0..6.bin, 15360B
each, coco3 2bpp) into square-pixel PNGs for Jay to pinpoint the carryover pose. REPORT ONLY.

Per pose emits TWO square-pixel (1:1, integer NEAREST, no stretch/smoothing) PNGs:
  <label>_full.png  — whole 320x192 frame, scale x3 (context)
  <label>_crop.png  — player region crop, scale x8 (the 1px lines)
A label bar (pose index + descriptor) is drawn ON the image (HS-6). No circles, arrows, or
interpretation marks (HS-7) — clean renders; Jay identifies the artifact.

Decode = render_square.py's verified coco3 path (2bpp MSB-first, 80 bytes/row, MAME palette).
"""
import argparse, os
from PIL import Image, ImageDraw

PAL = [(0, 0, 0), (230, 111, 0), (25, 144, 255), (255, 255, 255)]  # 0 blk 1 orange 2 blue 3 wht
COLS, ROWS, W = 80, 192, 320

# player crop (byte cols 20..32 -> px 80..131; rows 112..167). Generous margin.
CROP_X0, CROP_X1 = 64, 144      # px (cols 16..36)
CROP_Y0, CROP_Y1 = 104, 176     # rows


def decode(path):
    data = open(path, 'rb').read()
    img = Image.new('RGB', (W, ROWS))
    px = img.load()
    for row in range(ROWS):
        for col in range(COLS):
            b = data[row * COLS + col]
            for p in range(4):
                px[col * 4 + p, row] = PAL[(b >> (6 - p * 2)) & 3]
    return img


def label_bar(img, text, scale):
    """Prepend a black label bar (text in white) above the scaled image."""
    bar_h = 16
    out = Image.new('RGB', (img.width, img.height + bar_h), (0, 0, 0))
    out.paste(img, (0, bar_h))
    d = ImageDraw.Draw(out)
    d.text((3, 3), text, fill=(255, 255, 255))
    return out


def emit(binpath, outdir, label):
    img = decode(binpath)
    # full x3
    full = img.resize((img.width * 3, img.height * 3), Image.NEAREST)
    full = label_bar(full, f"{label}  full 320x192  NEAREST x3  (live seq, post-draw)", 3)
    fp = os.path.join(outdir, f"{label}_full.png")
    full.save(fp)
    # crop x8
    crop = img.crop((CROP_X0, CROP_Y0, CROP_X1, CROP_Y1))
    cw, ch = crop.size
    crop = crop.resize((cw * 8, ch * 8), Image.NEAREST)
    crop = label_bar(crop, f"{label}  crop px[{CROP_X0}-{CROP_X1}) rows[{CROP_Y0}-{CROP_Y1})  NEAREST x8", 8)
    cp = os.path.join(outdir, f"{label}_crop.png")
    crop.save(cp)
    return fp, cp


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--indir', required=True)
    ap.add_argument('--outdir', required=True)
    a = ap.parse_args()
    os.makedirs(a.outdir, exist_ok=True)
    names = {0: 'anim_00', 1: 'anim_01', 2: 'anim_02', 3: 'anim_03',
             4: 'anim_04', 5: 'anim_05', 6: 'anim_06_settle'}
    for i in range(7):
        binp = os.path.join(a.indir, f'pose_{i}.bin')
        fp, cp = emit(binp, a.outdir, names[i])
        print(f"{names[i]}: {os.path.basename(fp)}  {os.path.basename(cp)}")


if __name__ == '__main__':
    main()
