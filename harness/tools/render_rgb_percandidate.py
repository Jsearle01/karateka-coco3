#!/usr/bin/env python3
"""render_rgb_percandidate.py — ONE PNG per RGB candidate, each showing ORACLE | COMPOSITE anchor | that
CANDIDATE side by side (so Jay views one candidate at a time with the references beside it, and flips
between the 6). Same anim_02 frame, square-pixel integer NEAREST, labeled. REPORT ONLY — no palette
committed. Files -> build/rgb_study/per_candidate/."""
import os, sys
from PIL import Image, ImageDraw
ORACLE_ONLY = "--oracle-only" in sys.argv   # drop the composite panel: oracle + rgb only
SC="C:/Users/jayse/AppData/Local/Temp/claude/c--Projects-karateka-coco3/9c840854-3b22-46e9-bd4c-86d1cdf76afe/scratchpad"
ORACLE=SC+"/oracle_anim02/apple2e/0000.png"; FRAME=SC+"/climb_poses/pose_2.bin"
OUT="C:/Projects/karateka_coco3/build/rgb_study/"+("oracle_vs_rgb" if ORACLE_ONLY else "per_candidate"); XOFF,CW=20,320; SCALE=3
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
def lab(im,t):
    o=Image.new('RGB',(im.width,im.height+16),(0,0,0)); o.paste(im,(0,16)); ImageDraw.Draw(o).text((3,3),t,fill=(235,235,235)); return o
def main():
    os.makedirs(OUT,exist_ok=True)
    oc=oracle().resize((CW*SCALE,192*SCALE),Image.NEAREST); an=port(COMP_ANCHOR).resize((CW*SCALE,192*SCALE),Image.NEAREST)
    oc=lab(oc,"ORACLE (apple composite)  blue(25,144,255) orange(230,111,0)")
    an=lab(an,"CoCo3 COMPOSITE anchor  $2D(54,179,247) $26(245,115,58)")
    for slot,bl,org,cls in CANDS:
        cand=port([(0,0,0),bitpack(org),bitpack(bl),(255,255,255)]).resize((CW*SCALE,192*SCALE),Image.NEAREST)
        cand=lab(cand,f"{slot} RGB {cls}: blue ${bl:02X}{bitpack(bl)} orange ${org:02X}{bitpack(org)}")
        cells=[oc,cand] if ORACLE_ONLY else [oc,an,cand]; gap=10
        W=max(c.width for c in cells); H=sum(c.height for c in cells)+gap*2
        sheet=Image.new('RGB',(W,H),(18,18,18)); y=0
        for c in cells: sheet.paste(c,(0,y)); y+=c.height+gap
        name=f"{slot}_{cls}_blue{bl:02X}_orange{org:02X}.png"; sheet.save(os.path.join(OUT,name)); print(" ",name)
    print(f"6 files, each ORACLE|COMPOSITE|CANDIDATE side by side, {SCALE}x NEAREST.")
if __name__=='__main__': main()
