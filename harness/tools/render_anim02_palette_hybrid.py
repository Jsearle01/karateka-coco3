#!/usr/bin/env python3
"""
render_anim02_palette_hybrid.py — Deliverable A: palette panels at anim_02 (NO swap). REPORT ONLY.
Panels: ORACLE | current | hybrid | C1. hybrid and C1 share C1's blue ($2D), so the ONLY variable
between them is the ORANGE ($26 current vs $25 C1). Preview re-colour of the captured index-frame
(pose_2.bin) under each palette's measured MAME-composite RGB — nothing built/promoted.
CoCo3_px = Apple_px + 20; square-pixel integer NEAREST (factor stated). Same render path all panels.
"""
import os
from PIL import Image, ImageDraw

CURRENT = [(0,0,0),(245,115,58),(94,44,255),(255,255,255)]   # $26 / $1B (violet)
HYBRID  = [(0,0,0),(245,115,58),(54,179,247),(255,255,255)]  # $26 orange + $2D blue
C1      = [(0,0,0),(221,140,1),(54,179,247),(255,255,255)]   # $25 orange + $2D blue

ORACLE_PNG = "C:/Users/jayse/AppData/Local/Temp/claude/c--Projects-karateka-coco3/9c840854-3b22-46e9-bd4c-86d1cdf76afe/scratchpad/oracle_anim02/apple2e/0000.png"
PORT_BIN = "C:/Users/jayse/AppData/Local/Temp/claude/c--Projects-karateka-coco3/9c840854-3b22-46e9-bd4c-86d1cdf76afe/scratchpad/climb_poses/pose_2.bin"
OUTDIR = "C:/Projects/karateka_coco3/build/anim02_compare"
XOFF, CW = 20, 320

def port_grid():
    d = open(PORT_BIN,'rb').read()
    return [[(d[r*80+c]>>(6-p*2))&3 for c in range(80) for p in range(4)] for r in range(192)]
def port_canvas(g,pal):
    im=Image.new('RGB',(CW,192),(18,18,18)); px=im.load()
    for y in range(192):
        for x in range(320): px[x,y]=pal[g[y][x]]
    return im
def oracle_canvas():
    im=Image.open(ORACLE_PNG).convert('RGB'); W,H=im.size
    o=im.resize((W//2,H),Image.NEAREST); c=Image.new('RGB',(CW,192),(18,18,18)); c.paste(o,(XOFF,0)); return c
def label(im,t):
    out=Image.new('RGB',(im.width,im.height+15),(0,0,0)); out.paste(im,(0,15))
    ImageDraw.Draw(out).text((3,3),t,fill=(240,240,240)); return out
def stack(panels,scale):
    L=[label(im,t) for im,t in panels]; gap=6
    W=max(p.width for p in L); H=sum(p.height for p in L)+gap*(len(L)-1)
    out=Image.new('RGB',(W,H),(18,18,18)); y=0
    for p in L: out.paste(p,(0,y)); y+=p.height+gap
    if scale!=1: out=out.resize((out.width*scale,out.height*scale),Image.NEAREST)
    return out

def main():
    os.makedirs(OUTDIR,exist_ok=True)
    g=port_grid(); oc=oracle_canvas()
    panels=[(oc,"ORACLE anim_02  blue(25,144,255) orange(230,111,0)  +20"),
            (port_canvas(g,CURRENT),"current  blue $1B(94,44,255) violet   orange $26(245,115,58) d60"),
            (port_canvas(g,HYBRID), "hybrid   blue $2D(54,179,247) d46     orange $26(245,115,58) d60"),
            (port_canvas(g,C1),     "C1       blue $2D(54,179,247) d46     orange $25(221,140,1) d30")]
    full=stack(panels,3); fp=os.path.join(OUTDIR,"anim02_palette_hybrid_full_x3.png"); full.save(fp)
    cx0,cx1,cy0,cy1=64,144,128,176   # contains cliff-texture orange (left) + lower-body orange
    cpanels=[(im.crop((cx0,cy0,cx1,cy1)),t+" [crop]") for im,t in panels]
    crop=stack(cpanels,8); cp=os.path.join(OUTDIR,"anim02_palette_hybrid_crop_x8.png"); crop.save(cp)
    print(f"wrote {fp} (oracle|current|hybrid|C1, x3 NEAREST)")
    print(f"wrote {cp} (crop cliff+lowerbody x8 NEAREST)")
    print("hybrid vs C1: ONLY the orange differs ($26 vs $25); both share blue $2D. Preview re-colour, nothing promoted.")

if __name__=='__main__': main()
