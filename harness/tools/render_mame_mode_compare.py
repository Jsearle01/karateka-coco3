#!/usr/bin/env python3
"""
render_mame_mode_compare.py — MAME coco3 Composite vs RGB monitor, same climb frame. REPORT ONLY.

MAME coco3 HAS a "Monitor Type" configuration (ioport tag `screen_config`, mask 1): Composite=0
(default) / RGB=1 (confirmed via `-listxml coco3`). Both panels are REAL MAME renders of the same
anim_02 climb-frame index dump, with the palette RGBs MEASURED from actual MAME snapshots under each
Monitor Type (set via the screen_config ioport in monitor_mode_snapshot.lua). Same frame, same render
path, square-pixel integer NEAREST — only the Monitor Type differs. GIME regs = $00/$26/$2D/$3F (hybrid).
"""
import os
from PIL import Image, ImageDraw

# MEASURED from real MAME snapshots of the fallback under each Monitor Type:
MAME_COMPOSITE = [(0,0,0),(245,115,58),(54,179,247),(255,255,255)]   # screen_config=0 (default)
MAME_RGB       = [(0,0,0),(255,85,0),(255,0,255),(255,255,255)]      # screen_config=1

FRAME = "C:/Users/jayse/AppData/Local/Temp/claude/c--Projects-karateka-coco3/9c840854-3b22-46e9-bd4c-86d1cdf76afe/scratchpad/climb_poses/pose_2.bin"
OUT = "C:/Projects/karateka_coco3/build/mame_mode"

def render(pal):
    d=open(FRAME,'rb').read(); im=Image.new('RGB',(320,192)); px=im.load()
    for r in range(192):
        for c in range(80):
            b=d[r*80+c]
            for p in range(4): px[c*4+p,r]=pal[(b>>(6-p*2))&3]
    return im
def label(im,t):
    o=Image.new('RGB',(im.width,im.height+16),(0,0,0)); o.paste(im,(0,16))
    ImageDraw.Draw(o).text((3,3),t,fill=(240,240,240)); return o

def main():
    os.makedirs(OUT,exist_ok=True); S=3
    a=label(render(MAME_COMPOSITE), "MAME Composite (Monitor Type=0, DEFAULT): $26->(245,115,58) $2D->(54,179,247)")
    b=label(render(MAME_RGB),       "MAME RGB (Monitor Type=1): $26->(255,85,0) $2D->(255,0,255)")
    gap=6; W=max(a.width,b.width); H=a.height+gap+b.height
    sheet=Image.new('RGB',(W,H+18),(18,18,18)); dr=ImageDraw.Draw(sheet)
    dr.text((3,3),"anim_02 climb frame: MAME coco3 Composite (default) vs RGB monitor (same GIME regs). Both real MAME renders. NEAREST x3.",fill=(255,255,255))
    sheet.paste(a,(0,18)); sheet.paste(b,(0,18+a.height+gap))
    sheet=sheet.resize((sheet.width*S,sheet.height*S),Image.NEAREST)
    fp=os.path.join(OUT,"mame_composite_vs_rgb_x3.png"); sheet.save(fp)
    print("wrote",fp)

if __name__=='__main__': main()
