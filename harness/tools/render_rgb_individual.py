#!/usr/bin/env python3
"""render_rgb_individual.py — emit the RGB study sources as SEPARATE, aligned, full-frame PNGs so Jay can
overlay/flip/compare them one at a time: oracle, composite anchor, and each RGB candidate. Same anim_02
frame, same 320x192 canvas (oracle placed +20), integer NEAREST scale so all PNGs are pixel-exact aligned.
REPORT ONLY — no palette committed. Files -> build/rgb_study/individual/."""
import os
from PIL import Image

SC="C:/Users/jayse/AppData/Local/Temp/claude/c--Projects-karateka-coco3/9c840854-3b22-46e9-bd4c-86d1cdf76afe/scratchpad"
ORACLE=SC+"/oracle_anim02/apple2e/0000.png"; FRAME=SC+"/climb_poses/pose_2.bin"
OUT="C:/Projects/karateka_coco3/build/rgb_study/individual"; XOFF,CW=20,320; SCALE=4
COMP_ANCHOR=[(0,0,0),(245,115,58),(54,179,247),(255,255,255)]
def bitpack(v):
    r=(((v>>5)&1)<<1)|((v>>2)&1); g=(((v>>4)&1)<<1)|((v>>1)&1); b=(((v>>3)&1)<<1)|(v&1)
    s={0:0,1:85,2:170,3:255}; return (s[r],s[g],s[b])
CANDS=[("C1",0x19,0x26,"nearest-oracle"),("C2",0x1B,0x26,"native-cyan"),("C3",0x1D,0x26,"lighter-blue"),
       ("C4",0x09,0x26,"native-pure-blue"),("C5",0x19,0x34,"native-amber"),("C6",0x19,0x22,"muted-orange")]
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
def save(im,name):
    im=im.resize((im.width*SCALE,im.height*SCALE),Image.NEAREST)
    p=os.path.join(OUT,name); im.save(p); print(" ",name)
def main():
    os.makedirs(OUT,exist_ok=True)
    save(oracle(),"00_oracle.png")
    save(port(COMP_ANCHOR),"01_composite_anchor_2D_26.png")
    for slot,bl,org,cls in CANDS:
        save(port([(0,0,0),bitpack(org),bitpack(bl),(255,255,255)]),
             f"02_{slot}_{cls}_blue{bl:02X}_orange{org:02X}.png")
    print(f"all {SCALE}x NEAREST, 320x192 canvas, aligned (oracle +20).")
if __name__=='__main__': main()
