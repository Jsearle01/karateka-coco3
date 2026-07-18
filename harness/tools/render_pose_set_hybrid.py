#!/usr/bin/env python3
"""render_pose_set_hybrid.py — the 7 climb poses rendered under the HYBRID palette (Jay's current
visual baseline, HS-A7). Index dumps are palette-independent (identical to pre-hybrid); only the RGB
mapping differs. Square-pixel integer NEAREST."""
import os
from PIL import Image, ImageDraw
HYBRID=[(0,0,0),(245,115,58),(54,179,247),(255,255,255)]  # blk/orange $26/blue $2D/white
IN="C:/Users/jayse/AppData/Local/Temp/claude/c--Projects-karateka-coco3/9c840854-3b22-46e9-bd4c-86d1cdf76afe/scratchpad/climb_poses"
OUT="C:/Projects/karateka_coco3/build/climb_poses_hybrid"
NAMES=['anim_00','anim_01','anim_02','anim_03','anim_04','anim_05','anim_06_settle']
def decode(p):
    d=open(p,'rb').read(); im=Image.new('RGB',(320,192)); px=im.load()
    for r in range(192):
        for c in range(80):
            b=d[r*80+c]
            for k in range(4): px[c*4+k,r]=HYBRID[(b>>(6-k*2))&3]
    return im
os.makedirs(OUT,exist_ok=True)
imgs=[]
for i,n in enumerate(NAMES):
    im=decode(os.path.join(IN,f"pose_{i}.bin"))
    lab=Image.new('RGB',(320,192+14),(0,0,0)); lab.paste(im,(0,14))
    ImageDraw.Draw(lab).text((3,2),f"{n}  HYBRID palette (blue $2D / orange $26)",fill=(240,240,240))
    imgs.append(lab)
sheet=Image.new('RGB',(320,sum(im.height for im in imgs)+6*6),(18,18,18)); y=0
for im in imgs: sheet.paste(im,(0,y)); y+=im.height+6
sheet=sheet.resize((sheet.width*3,sheet.height*3),Image.NEAREST)
sheet.save(os.path.join(OUT,"climb_poses_hybrid_x3.png"))
print("wrote climb_poses_hybrid_x3.png (7 poses at hybrid, x3 NEAREST)")
