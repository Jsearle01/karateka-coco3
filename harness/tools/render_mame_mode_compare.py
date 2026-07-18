#!/usr/bin/env python3
"""
render_mame_mode_compare.py — pin which monitor decode MAME coco3 uses. REPORT ONLY.

MAME coco3 has NO composite-vs-RGB toggle (no -listconfig option, no monitor config/slot, no rgb/
composite driver variant; -monitorprovider is host-window only). So there is no "RGB flag" to flip — it
renders one fixed decode. This shows the SAME scene-6 climb frame (anim_02 index dump) under two palette
DECODES of the SAME GIME register values ($FFB0-3 = $00/$26/$2D/$3F hybrid):
  - MAME COMPOSITE (measured): the RGB MAME actually renders (pal_sweep / snapshot measured).
  - RGB-MONITOR bitpack (computed): the digital-RGB interpretation (bits R1 G1 B1 R0 G0 B0, 2b/channel).
Same frame, same render path, square-pixel integer NEAREST — only the DECODE differs (the variable under
test). If the panels differ, MAME's decode != RGB-monitor (i.e. it is composite). Jay confirms by eye.
"""
import os
from PIL import Image, ImageDraw

# index -> RGB. hybrid regs: 0=$00 1=$26 2=$2D 3=$3F
MAME_COMPOSITE = [(0,0,0),(245,115,58),(54,179,247),(255,255,255)]   # MEASURED (what MAME renders)
def rgb_bitpack(v):
    r=(((v>>5)&1)<<1)|((v>>2)&1); g=(((v>>4)&1)<<1)|((v>>1)&1); b=(((v>>3)&1)<<1)|(v&1)
    s={0:0,1:85,2:170,3:255}; return (s[r],s[g],s[b])
RGB_MONITOR = [rgb_bitpack(0x00), rgb_bitpack(0x26), rgb_bitpack(0x2D), rgb_bitpack(0x3F)]  # COMPUTED

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
    a=label(render(MAME_COMPOSITE), "MAME COMPOSITE (as rendered): $26->(245,115,58) $2D->(54,179,247)")
    b=label(render(RGB_MONITOR),   f"RGB-MONITOR bitpack (computed): $26->{RGB_MONITOR[1]} $2D->{RGB_MONITOR[2]}")
    gap=6; W=max(a.width,b.width); H=a.height+gap+b.height
    sheet=Image.new('RGB',(W,H+18),(18,18,18)); dr=ImageDraw.Draw(sheet)
    dr.text((3,3),"anim_02 climb frame: MAME's composite decode vs the RGB-monitor decode (same GIME regs). NEAREST x3.",fill=(255,255,255))
    sheet.paste(a,(0,18)); sheet.paste(b,(0,18+a.height+gap))
    sheet=sheet.resize((sheet.width*S,sheet.height*S),Image.NEAREST)
    fp=os.path.join(OUT,"mame_composite_vs_rgb_x3.png"); sheet.save(fp)
    print("wrote",fp)
    print("\nDECODE TABLE (GIME reg -> RGB):")
    for nm,v in [("orange $26",0x26),("blue $2D",0x2D),("blue $1B",0x1B)]:
        print(f"  {nm}: MAME-measured composite vs RGB-bitpack {rgb_bitpack(v)}")

if __name__=='__main__': main()
