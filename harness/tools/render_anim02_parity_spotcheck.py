#!/usr/bin/env python3
"""render_anim02_parity_spotcheck.py — spot-check the column-parity fix at anim_02 (the $A4A4 control).
oracle | port PRE-fix (old $A4A4) | port POST-fix (derived-parity $A4A4), same frame, hybrid palette
(what the fallback renders), CoCo3_px=Apple_px+20, square-pixel NEAREST. Facts for Jay. REPORT ONLY."""
import os
from PIL import Image, ImageDraw
HYBRID=[(0,0,0),(245,115,58),(54,179,247),(255,255,255)]
SC="C:/Users/jayse/AppData/Local/Temp/claude/c--Projects-karateka-coco3/9c840854-3b22-46e9-bd4c-86d1cdf76afe/scratchpad"
ORACLE=SC+"/oracle_anim02/apple2e/0000.png"; PRE=SC+"/climb_poses/pose_2_PREFIX.bin"; POST=SC+"/climb_poses/pose_2.bin"
OUT="C:/Projects/karateka_coco3/build/parity_fix"; XOFF,CW=20,320
def port(binp):
    d=open(binp,'rb').read(); im=Image.new('RGB',(CW,192),(18,18,18)); px=im.load()
    for r in range(192):
        for c in range(80):
            b=d[r*80+c]
            for p in range(4): px[c*4+p,r]=HYBRID[(b>>(6-p*2))&3]
    return im
def oracle():
    im=Image.open(ORACLE).convert('RGB'); W,H=im.size; o=im.resize((W//2,H),Image.NEAREST)
    c=Image.new('RGB',(CW,192),(18,18,18)); c.paste(o,(XOFF,0)); return c
def label(im,t):
    o=Image.new('RGB',(im.width,im.height+15),(0,0,0)); o.paste(im,(0,15)); ImageDraw.Draw(o).text((3,3),t,fill=(240,240,240)); return o
def stack(panels,scale):
    L=[label(im,t) for im,t in panels]; g=6; W=max(p.width for p in L); H=sum(p.height for p in L)+g*(len(L)-1)
    out=Image.new('RGB',(W,H),(18,18,18)); y=0
    for p in L: out.paste(p,(0,y)); y+=p.height+g
    return out.resize((out.width*scale,out.height*scale),Image.NEAREST) if scale!=1 else out
def main():
    os.makedirs(OUT,exist_ok=True)
    panels=[(oracle(),"ORACLE anim_02 +20"),(port(PRE),"port PRE-fix (old $A4A4)"),(port(POST),"port POST-fix (derived-parity $A4A4)")]
    stack(panels,3).save(os.path.join(OUT,"anim02_parity_spotcheck_full_x3.png"))
    cx0,cx1,cy0,cy1=64,144,128,176
    stack([(im.crop((cx0,cy0,cx1,cy1)),t+" [crop]") for im,t in panels],8).save(os.path.join(OUT,"anim02_parity_spotcheck_lowerbody_x8.png"))
    print("wrote anim02_parity_spotcheck_{full_x3,lowerbody_x8}.png (oracle | pre | post)")
if __name__=='__main__': main()
