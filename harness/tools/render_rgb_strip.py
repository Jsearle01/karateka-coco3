#!/usr/bin/env python3
"""render_rgb_strip.py — a vertical strip of chosen sources for direct comparison. Default: oracle, C1, C3.
Pass slot names as args to change (e.g. `oracle C2 C5`). Same anim_02 frame, square-pixel NEAREST.
REPORT ONLY. -> build/rgb_study/strip.png"""
import os, sys
from PIL import Image, ImageDraw
SC="C:/Users/jayse/AppData/Local/Temp/claude/c--Projects-karateka-coco3/9c840854-3b22-46e9-bd4c-86d1cdf76afe/scratchpad"
ORACLE=SC+"/oracle_anim02/apple2e/0000.png"; FRAME=SC+"/climb_poses/pose_2.bin"
OUT="C:/Projects/karateka_coco3/build/rgb_study"; XOFF,CW,SCALE=20,320,3
def bitpack(v):
    r=(((v>>5)&1)<<1)|((v>>2)&1); g=(((v>>4)&1)<<1)|((v>>1)&1); b=(((v>>3)&1)<<1)|(v&1)
    s={0:0,1:85,2:170,3:255}; return (s[r],s[g],s[b])
CAND={"C1":(0x19,0x26,"nearest-oracle"),"C2":(0x1B,0x26,"native-cyan"),"C3":(0x1D,0x26,"lighter-blue"),
      "C4":(0x09,0x26,"native-pure-blue"),"C5":(0x19,0x34,"native-amber"),"C6":(0x19,0x22,"muted-orange"),
      "COMP":(None,None,"composite-anchor")}
def port(pal):
    d=open(FRAME,'rb').read(); im=Image.new('RGB',(CW,192),(18,18,18)); px=im.load()
    for r in range(192):
        for c in range(80):
            b=d[r*80+c]
            for p in range(4): px[c*4+p,r]=pal[(b>>(6-p*2))&3]
    return im
def oracle():
    im=Image.open(ORACLE).convert('RGB'); W,H=im.size; o=im.resize((W//2,H),Image.NEAREST)
    c=Image.new('RGB',(CW,192),(18,18,18)); c.paste(o,(XOFF,0)); return c
def lab(im,t):
    o=Image.new('RGB',(im.width,im.height+16),(0,0,0)); o.paste(im,(0,16)); ImageDraw.Draw(o).text((3,3),t,fill=(235,235,235)); return o
def cell(name):
    if name.lower()=="oracle": return lab(oracle().resize((CW*SCALE,192*SCALE),Image.NEAREST),"ORACLE  blue(25,144,255) orange(230,111,0)")
    bl,org,cls=CAND[name.upper()]
    if bl is None: pal=[(0,0,0),(245,115,58),(54,179,247),(255,255,255)]; t="COMPOSITE anchor $2D(54,179,247)/$26(245,115,58)"
    else: pal=[(0,0,0),bitpack(org),bitpack(bl),(255,255,255)]; t=f"{name.upper()} {cls}: blue ${bl:02X}{bitpack(bl)} orange ${org:02X}{bitpack(org)}"
    return lab(port(pal).resize((CW*SCALE,192*SCALE),Image.NEAREST),t)
def main():
    seq=sys.argv[1:] or ["oracle","C1","C3"]
    cells=[cell(n) for n in seq]; gap=10
    W=max(c.width for c in cells); H=sum(c.height for c in cells)+gap*(len(cells)-1)
    sheet=Image.new('RGB',(W,H),(18,18,18)); y=0
    for c in cells: sheet.paste(c,(0,y)); y+=c.height+gap
    os.makedirs(OUT,exist_ok=True); name="strip_"+"_".join(seq)+".png"; sheet.save(os.path.join(OUT,name)); print("wrote",name,sheet.size)
if __name__=='__main__': main()
