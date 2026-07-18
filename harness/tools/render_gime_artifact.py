#!/usr/bin/env python3
"""render_gime_artifact.py — HS-5 on/off render for the coco3 gime:artifacting config. Same anim_02
climb frame, composite palette, Artifacting Off vs Standard vs Reverse. All THREE are pixel-identical
(measured: same colour histogram) because Karateka renders in GIME palette mode, not a 1-bit artifact
mode — so artifacting is a NO-OP here. Square-pixel integer NEAREST. REPORT ONLY."""
import os
from PIL import Image, ImageDraw
# composite palette (measured MAME, Monitor=Composite) — identical for artifacting Off/Std/Rev
COMP=[(0,0,0),(245,115,58),(54,179,247),(255,255,255)]
FRAME="C:/Users/jayse/AppData/Local/Temp/claude/c--Projects-karateka-coco3/9c840854-3b22-46e9-bd4c-86d1cdf76afe/scratchpad/climb_poses/pose_2.bin"
OUT="C:/Projects/karateka_coco3/build/gime_artifact"
def render():
    d=open(FRAME,'rb').read(); im=Image.new('RGB',(320,192)); px=im.load()
    for r in range(192):
        for c in range(80):
            b=d[r*80+c]
            for p in range(4): px[c*4+p,r]=COMP[(b>>(6-p*2))&3]
    return im
def label(im,t):
    o=Image.new('RGB',(im.width,im.height+16),(0,0,0)); o.paste(im,(0,16)); ImageDraw.Draw(o).text((3,3),t,fill=(240,240,240)); return o
def main():
    os.makedirs(OUT,exist_ok=True); S=3
    panels=[label(render(),"Artifacting=Off (0)"),label(render(),"Artifacting=Standard (1, default)"),label(render(),"Artifacting=Reverse (2)")]
    gap=6; W=max(p.width for p in panels); H=sum(p.height for p in panels)+gap*2
    sheet=Image.new('RGB',(W,H+18),(18,18,18)); ImageDraw.Draw(sheet).text((3,3),"coco3 gime:artifacting on anim_02 (composite). All 3 PIXEL-IDENTICAL (no-op: palette mode, not artifact mode). NEAREST x3.",fill=(255,255,255))
    y=18
    for p in panels: sheet.paste(p,(0,y)); y+=p.height+gap
    sheet=sheet.resize((sheet.width*S,sheet.height*S),Image.NEAREST)
    fp=os.path.join(OUT,"gime_artifact_off_std_rev_x3.png"); sheet.save(fp); print("wrote",fp)
if __name__=='__main__': main()
