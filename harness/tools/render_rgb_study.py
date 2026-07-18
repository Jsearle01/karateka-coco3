#!/usr/bin/env python3
"""render_rgb_study.py — RGB palette selection panel: oracle | CoCo3 composite anchor (current hybrid) |
CoCo3 RGB candidate[i], same anim_02 frame, one row per RGB candidate. Fused 1:1 + a countable x8 crop.
RGB candidates rendered with the bitpack decode = what MAME renders under Monitor Type=RGB (verified:
$19->(0,170,255), $26->(255,85,0), $34->(255,170,0)). Composite anchor = measured composite (value-
verified). Oracle = apple2e snapshot (+20). REPORT ONLY — no palette committed; Jay selects."""
import os
from PIL import Image, ImageDraw

SC="C:/Users/jayse/AppData/Local/Temp/claude/c--Projects-karateka-coco3/9c840854-3b22-46e9-bd4c-86d1cdf76afe/scratchpad"
ORACLE=SC+"/oracle_anim02/apple2e/0000.png"; FRAME=SC+"/climb_poses/pose_2.bin"
OUT="C:/Projects/karateka_coco3/build/rgb_study"; XOFF,CW=20,320
ORACLE_BLUE=(25,144,255); ORACLE_ORANGE=(230,111,0)
COMP_ANCHOR=[(0,0,0),(245,115,58),(54,179,247),(255,255,255)]  # composite $26 orange / $2D blue (measured)

def bitpack(v):
    r=(((v>>5)&1)<<1)|((v>>2)&1); g=(((v>>4)&1)<<1)|((v>>1)&1); b=(((v>>3)&1)<<1)|(v&1)
    s={0:0,1:85,2:170,3:255}; return (s[r],s[g],s[b])
def dist(a,b): return round(sum((x-y)**2 for x,y in zip(a,b))**0.5)

# (slot, blue6, orange6, class)
CANDS=[("C1",0x19,0x26,"nearest-oracle (blue+orange both closest)"),
       ("C2",0x1B,0x26,"native-strong cyan blue"),
       ("C3",0x1D,0x26,"lighter blue (R-lifted)"),
       ("C4",0x09,0x26,"native-strong pure blue"),
       ("C5",0x19,0x34,"native-strong amber orange"),
       ("C6",0x19,0x22,"muted brown-orange")]

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
def lab(im,t,h=14):
    o=Image.new('RGB',(im.width,im.height+h),(0,0,0)); o.paste(im,(0,h)); ImageDraw.Draw(o).text((2,2),t,fill=(235,235,235)); return o

def build(crop, scale, fname):
    oc=oracle(); an=port(COMP_ANCHOR)
    rows=[]
    for slot,bl,org,cls in CANDS:
        pal=[(0,0,0),bitpack(org),bitpack(bl),(255,255,255)]
        cells=[(oc,"ORACLE (apple composite)"),(an,"CoCo3 COMPOSITE anchor: $2D/$26"),
               (port(pal),f"{slot} RGB: blue ${bl:02X}{bitpack(bl)} orange ${org:02X}{bitpack(org)}")]
        if crop:
            cx0,cx1,cy0,cy1=64,144,128,176
            cells=[(im.crop((cx0,cy0,cx1,cy1)),t) for im,t in cells]
        cells=[lab(im.resize((im.width*scale,im.height*scale),Image.NEAREST),t) for im,t in cells]
        gap=8; rw=sum(c.width for c in cells)+gap*2; rh=max(c.height for c in cells)
        row=Image.new('RGB',(rw,rh+14),(18,18,18)); ImageDraw.Draw(row).text((2,2),f"{slot}: {cls}",fill=(255,235,150))
        x=0
        for c in cells: row.paste(c,(x,14)); x+=c.width+gap
        rows.append(row)
    W=max(r.width for r in rows); H=sum(r.height for r in rows)+10*len(rows)
    sheet=Image.new('RGB',(W,H+4),(18,18,18)); y=4
    for r in rows: sheet.paste(r,(0,y)); y+=r.height+10
    os.makedirs(OUT,exist_ok=True); sheet.save(os.path.join(OUT,fname)); print("wrote",fname,sheet.size)

def main():
    build(False,1,"panel_fused_1x1.png")     # fused 1:1 — THE selection surface
    build(True,8,"panel_countable_x8.png")    # x8 crop — countable reference only
    # values doc
    lines=["# RGB palette selection — candidate values (2026-07-18) — REPORT ONLY, Jay selects",
           "",
           "Oracle sampled: blue (25,144,255) · orange (230,111,0). Composite anchor (current hybrid, value-verified):",
           "blue $2D->(54,179,247) · orange $26->(245,115,58). RGB candidates = bitpack decode = MAME Monitor Type=RGB",
           "(verified: $19->(0,170,255), $26->(255,85,0), $34->(255,170,0)).","",
           "| slot | class | blue 6-bit | blue RGB | d(blue,oracle) | orange 6-bit | orange RGB | d(orange,oracle) |",
           "|---|---|---|---|---|---|---|---|"]
    for slot,bl,org,cls in CANDS:
        lines.append(f"| {slot} | {cls} | ${bl:02X} | {bitpack(bl)} | {dist(bitpack(bl),ORACLE_BLUE)} | "
                     f"${org:02X} | {bitpack(org)} | {dist(bitpack(org),ORACLE_ORANGE)} |")
    lines+=["","**Reference — composite anchor distances to oracle:** blue $2D (54,179,247) d="
            f"{dist((54,179,247),ORACLE_BLUE)} · orange $26 (245,115,58) d={dist((245,115,58),ORACLE_ORANGE)}.",
            "Note: RGB C1 blue $19 d="+str(dist((0,170,255),ORACLE_BLUE))+" and orange $26 d="+str(dist((255,85,0),ORACLE_ORANGE))+
            " — RGB can beat the composite anchor's distances (native-strong may win the fused read; Jay decides).",
            "","Nothing committed. Selection = Jay's fused 1:1 read (`panel_fused_1x1.png`); x8 is countable-only."]
    open(os.path.join(OUT,"rgb_candidates.md"),"w").write("\n".join(lines)+"\n")
    print("wrote rgb_candidates.md")

if __name__=='__main__': main()
