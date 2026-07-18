#!/usr/bin/env python3
"""render_fuji_altered.py — surface the 4 ALTERED (protected) Mt-Fuji cels for Jay: committed (content/,
altered) vs fresh re-convert (pure converter output), side by side. Fresh convert is computed in-memory
(NEVER written to content/). REPORT/SURFACE ONLY — no interpretation on the image; Jay identifies.
Square-pixel integer NEAREST. Transparency (index 0) = gray checker; 1=orange 2=blue 3=white."""
import os, re, sys
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, HERE)
from sprite_convert import convert_sprite_to_coco3
from stage0_convert_scene6 import load_dump, extract_cel, trim_cols
from PIL import Image, ImageDraw

PAL = {1:(245,115,58), 2:(54,179,247), 3:(255,255,255)}   # hybrid look
CHK = [(90,90,90),(140,140,140)]
CELS = [("A948",126),("A976",112),("A9B8",105),("A9E2",84)]   # (addr, start_col)
REPO = os.path.abspath(os.path.join(HERE,'..','..'))
OUT = os.path.join(REPO,'build','protection')

def parse_committed(addr):
    p = os.path.join(REPO,'content','background',f'scene6_bg_{addr}','converted.s')
    fcb=[l for l in open(p).read().splitlines() if re.search(r'^\s*fcb\s',l)]
    h,w=(int(x) for x in re.findall(r'\d+',fcb[0].split(';')[0])[:2])
    rows=[[int(v,16) for v in re.findall(r'\$([0-9A-Fa-f]{2})',l.split(';')[0])] for l in fcb[1:1+h]]
    return h,w,[b for r in rows for b in r]

def fresh(addr,start_col,dump):
    a=int(addr,16); h,w,bitmap=extract_cel(dump,a)
    packed,cw=convert_sprite_to_coco3(bitmap,h,w,start_col=start_col)
    packed,cw=trim_cols(packed,cw,h)
    return h,cw,list(packed)

def to_img(h,w,data,scale):
    im=Image.new('RGB',(w*4,h)); px=im.load()
    for r in range(h):
        for c in range(w):
            b=data[r*w+c] if r*w+c<len(data) else 0
            for p in range(4):
                idx=(b>>(6-p*2))&3; x=c*4+p
                px[x,r]=PAL[idx] if idx else CHK[((x//1+r//1))%2]
    return im.resize((im.width*scale,im.height*scale),Image.NEAREST)

def main():
    os.makedirs(OUT,exist_ok=True); dump=load_dump(); S=14
    panels=[]
    for addr,sc in CELS:
        hc,wc,dc=parse_committed(addr)
        hf,wf,df=fresh(addr,sc,dump)
        ic=to_img(hc,wc,dc,S); ifr=to_img(hf,wf,df,S)
        H=max(ic.height,ifr.height); gap=24; lblh=18
        row=Image.new('RGB',(ic.width+gap+ifr.width+20, H+lblh),(20,20,20))
        d=ImageDraw.Draw(row)
        d.text((2,2),f"${addr}  COMMITTED (content/, altered)",fill=(255,180,180))
        row.paste(ic,(2,lblh))
        d.text((ic.width+gap+2,2),f"${addr}  FRESH re-convert (pure)",fill=(180,255,180))
        row.paste(ifr,(ic.width+gap+2,lblh))
        panels.append(row)
    W=max(p.width for p in panels); Ht=sum(p.height for p in panels)+8*len(panels)
    sheet=Image.new('RGB',(W,Ht+24),(20,20,20)); d=ImageDraw.Draw(sheet)
    d.text((4,4),"ALTERED/PROTECTED cels = the Mt-Fuji backdrop (committed vs pure re-convert). NEAREST x14.",fill=(240,240,240))
    y=24
    for p in panels: sheet.paste(p,(4,y)); y+=p.height+8
    fp=os.path.join(OUT,"fuji_altered_committed_vs_fresh.png"); sheet.save(fp)
    print("wrote",fp)
    # also report the per-cel data-byte diff count (structured fact)
    for addr,sc in CELS:
        hc,wc,dc=parse_committed(addr); hf,wf,df=fresh(addr,sc,dump)
        n=sum(1 for i in range(min(len(dc),len(df))) if dc[i]!=df[i])+abs(len(dc)-len(df))
        print(f"  ${addr}: committed {hc}x{wc} ({len(dc)}B) vs fresh {hf}x{wf} ({len(df)}B) -> {n} data bytes differ")

if __name__=='__main__': main()
