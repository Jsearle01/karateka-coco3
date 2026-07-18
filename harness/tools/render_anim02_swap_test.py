#!/usr/bin/env python3
"""
render_anim02_swap_test.py — Deliverable B: blue<->orange SWAP test at the CURRENT palette. REPORT ONLY.
Panels: ORACLE | port current | port SWAPPED (index 1 <-> index 2 exchanged in the RENDERED output).
This is a preview re-colour of the captured index-frame (pose_2.bin) — NO cel re-convert, NO converter
change, NO shipped-build change. Palette held at CURRENT ($1B/$26) so the ONLY variable is the swap.
Emits the two-band per-pixel fact report: mid-body rows (153/155/157,160-164) and base rows (166/167).
CoCo3_px = Apple_px + 20; square-pixel integer NEAREST (factor stated).
"""
import os
from PIL import Image, ImageDraw

CURRENT = [(0,0,0),(245,115,58),(94,44,255),(255,255,255)]        # 0 blk,1 orange,2 blue,3 wht
SWAPPED = [(0,0,0),(94,44,255),(245,115,58),(255,255,255)]        # index1->blue, index2->orange
APPLE   = [(0,0,0),(230,111,0),(25,144,255),(255,255,255)]

ORACLE_PNG = "C:/Users/jayse/AppData/Local/Temp/claude/c--Projects-karateka-coco3/9c840854-3b22-46e9-bd4c-86d1cdf76afe/scratchpad/oracle_anim02/apple2e/0000.png"
PORT_BIN = "C:/Users/jayse/AppData/Local/Temp/claude/c--Projects-karateka-coco3/9c840854-3b22-46e9-bd4c-86d1cdf76afe/scratchpad/climb_poses/pose_2.bin"
OUTDIR = "C:/Projects/karateka_coco3/build/anim02_compare"
XOFF, CW = 20, 320

def port_grid():
    d=open(PORT_BIN,'rb').read()
    return [[(d[r*80+c]>>(6-p*2))&3 for c in range(80) for p in range(4)] for r in range(192)]
def oracle_280():
    im=Image.open(ORACLE_PNG).convert('RGB'); W,H=im.size; return im.resize((W//2,H),Image.NEAREST)
def oracle_grid(o):
    px=o.load(); W,H=o.size
    nn=lambda rgb: min(range(4),key=lambda i:sum((a-b)**2 for a,b in zip(rgb,APPLE[i])))
    return [[nn(px[x,y]) for x in range(W)] for y in range(H)]
def port_canvas(g,pal):
    im=Image.new('RGB',(CW,192),(18,18,18)); px=im.load()
    for y in range(192):
        for x in range(320): px[x,y]=pal[g[y][x]]
    return im
def oracle_canvas(o):
    c=Image.new('RGB',(CW,192),(18,18,18)); c.paste(o,(XOFF,0)); return c
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
    g=port_grid(); o280=oracle_280(); og=oracle_grid(o280)
    panels=[(oracle_canvas(o280),"ORACLE anim_02  +20  (artifact colour)"),
            (port_canvas(g,CURRENT),"port CURRENT  $1B blue / $26 orange"),
            (port_canvas(g,SWAPPED),"port SWAPPED  index1<->2 (blue<->orange), CURRENT palette")]
    full=stack(panels,3); fp=os.path.join(OUTDIR,"anim02_swap_full_x3.png"); full.save(fp)
    cx0,cx1,cy0,cy1=64,144,128,176
    cpanels=[(im.crop((cx0,cy0,cx1,cy1)),t+" [crop]") for im,t in panels]
    crop=stack(cpanels,8); cp=os.path.join(OUTDIR,"anim02_swap_lowerbody_x8.png"); crop.save(cp)
    print(f"wrote {fp} (oracle|current|swapped, x3 NEAREST)")
    print(f"wrote {cp} (lower-body cols72-112 rows150-167 crop, x8 NEAREST)")

    # ---- two-band per-pixel facts (canvas cols 72..112). swapped = current with o<->B. ----
    def crow(grid,y,off):   # classified letters for a grid row over cols 72..112
        return ''.join('.oBw'[grid[y][x-off]] if 0<=x-off<len(grid[0]) else ' ' for x in range(72,113))
    def prow(y,pal_is_swap):
        s=''
        for x in range(72,113):
            i=g[y][x]
            if pal_is_swap: i={1:2,2:1}.get(i,i)
            s+='.oBw'[i]
        return s
    print("\n=== BAND 1 — mid-body (rows 153,155,157,160,161,162,163,164), cols 72..112 ===")
    for y in [153,155,157,160,161,162,163,164]:
        print(f" row{y}: ORACLE {crow(og,y,XOFF)}")
        print(f"        CURRENT{prow(y,False)}")
        print(f"        SWAPPED{prow(y,True)}")
    print("\n=== BAND 2 — base rows that CURRENTLY MATCH (rows 166,167), cols 72..112 ===")
    for y in [166,167]:
        print(f" row{y}: ORACLE {crow(og,y,XOFF)}")
        print(f"        CURRENT{prow(y,False)}")
        print(f"        SWAPPED{prow(y,True)}")
    print("\nlegend: '.'=black 'o'=orange 'B'=blue 'w'=white   (facts only, no conclusion)")

if __name__=='__main__': main()
