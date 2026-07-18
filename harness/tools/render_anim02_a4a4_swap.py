#!/usr/bin/env python3
"""
render_anim02_a4a4_swap.py — Phase B: swap blue<->orange on $A4A4's PIXELS ONLY, at the HYBRID palette.
REPORT ONLY, no verdict. $A45A = control (untouched); substrate untouched.

$A4A4's pixels are identified from PLACEMENT + CEL DATA (not colour, not a bbox): we replay the two
anim_02 blits onto the clean substrate in draw order (cl_f2 lists $A4A4 FIRST = back, $A45A SECOND =
over), tagging each canvas pixel with the cel that last wrote it. The A4A4 mask = pixels tagged A4A4
(i.e. A4A4-written AND NOT overdrawn by A45A). Self-check: the simulated composite must match the real
captured frame pose_2.bin. Then the swap re-colours index 1<->2 ONLY at A4A4-tagged pixels.
Palette held at HYBRID (blue $2D / orange $26) => one variable: the swap. CoCo3_px = Apple_px + 20.
Square-pixel integer NEAREST; fused (x3) + countable (x8). Facts only.
"""
import os, re
from PIL import Image, ImageDraw

HYBRID = [(0,0,0),(245,115,58),(54,179,247),(255,255,255)]   # blk / orange $26 / blue $2D / white
APPLE  = [(0,0,0),(230,111,0),(25,144,255),(255,255,255)]
SWAP   = {1:2, 2:1}

SCR = "C:/Users/jayse/AppData/Local/Temp/claude/c--Projects-karateka-coco3/9c840854-3b22-46e9-bd4c-86d1cdf76afe/scratchpad"
CONTENT = "C:/Projects/karateka_coco3/content/player"
ORACLE_PNG = SCR + "/oracle_anim02/apple2e/0000.png"
PORT_BIN = SCR + "/climb_poses/pose_2.bin"
SUBSTRATE = SCR + "/climb_poses/substrate_clean.bin"
OUTDIR = "C:/Projects/karateka_coco3/build/anim02_compare"
XOFF, CW = 20, 320

# anim_02 placements from cl_frames (byte_col, sub, row) — climb_controller.s cl_f2
PLACE = {"A4A4": (22, 2, 143), "A45A": (26, 0, 139)}   # A4A4 first (back), A45A second (over)

def grid_from_bin(path):
    d = open(path,'rb').read()
    return [[(d[r*80+c]>>(6-p*2))&3 for c in range(80) for p in range(4)] for r in range(192)]

def parse_cel(name):
    lines = open(os.path.join(CONTENT, f"scene6_climb_{name}", "converted.s")).read().splitlines()
    fcb = [l for l in lines if re.search(r'^\s*fcb\s', l)]
    h, w = (int(x) for x in re.findall(r'\d+', fcb[0].split(';')[0])[:2])
    rows = [[int(v,16) for v in re.findall(r'\$([0-9A-Fa-f]{2})', l.split(';')[0])] for l in fcb[1:1+h]]
    return h, w, rows

def cel_pixels(name):
    h, w, rows = parse_cel(name)
    out = []  # (local_x, local_y, index)
    for y in range(h):
        for c in range(w):
            b = rows[y][c]
            for p in range(4):
                idx = (b >> (6-p*2)) & 3
                out.append((c*4+p, y, idx))
    return out

def main():
    os.makedirs(OUTDIR, exist_ok=True)
    port = grid_from_bin(PORT_BIN)
    sub = grid_from_bin(SUBSTRATE)

    # ---- replay the two blits, tag source ----
    comp = [row[:] for row in sub]                 # composite index grid (start = substrate)
    tag = [[None]*320 for _ in range(192)]         # 'A4A4' / 'A45A' / None
    for name in ["A4A4", "A45A"]:                  # draw order: A4A4 then A45A (over)
        bc, sb, row = PLACE[name]
        base_x = bc*4 + sb
        for lx, ly, idx in cel_pixels(name):
            if idx == 0:      # index-0 = transparent (blit keys it out)
                continue
            X, Y = base_x + lx, row + ly
            if 0 <= X < 320 and 0 <= Y < 192:
                comp[Y][X] = idx
                tag[Y][X] = name

    # ---- self-check: simulated composite vs real pose_2 (cel region rows 139..165, cols 80..132) ----
    mism = tot = 0
    for y in range(139, 166):
        for x in range(80, 132):
            tot += 1
            if comp[y][x] != port[y][x]:
                mism += 1
    print(f"BLIT-SIM self-check (rows139-165 cols80-132): {tot-mism}/{tot} match, {mism} mismatch")

    # ---- A4A4 visible mask + facts ----
    a4a4_rows = {}
    touches_base = 0
    for y in range(192):
        for x in range(320):
            if tag[y][x] == "A4A4":
                a4a4_rows[y] = a4a4_rows.get(y, 0) + 1
                if y in (166, 167): touches_base += 1
    vis = sorted(a4a4_rows)
    print(f"draw order: A4A4 (back) FIRST, A45A (over) SECOND -> A45A overdraws A4A4 in the overlap")
    print(f"$A4A4 VISIBLE pixels: {sum(a4a4_rows.values())} px, rows {vis[0]}-{vis[-1]}")
    print(f"  per-row visible count: " + " ".join(f"r{r}:{a4a4_rows[r]}" for r in vis))
    print(f"HS-B3 substrate scope-proof: A4A4 mask touches rows 166/167? {touches_base} px (MUST be 0)")

    # ---- build canvases ----
    def port_canvas(swap_a4a4):
        im = Image.new('RGB',(CW,192),(18,18,18)); px=im.load()
        for y in range(192):
            for x in range(320):
                idx = port[y][x]
                if swap_a4a4 and tag[y][x]=="A4A4":
                    idx = SWAP.get(idx, idx)
                px[x,y] = HYBRID[idx]
        return im
    def oracle_canvas():
        im=Image.open(ORACLE_PNG).convert('RGB'); W,H=im.size
        o=im.resize((W//2,H),Image.NEAREST); c=Image.new('RGB',(CW,192),(18,18,18)); c.paste(o,(XOFF,0)); return c

    oc, pc, ps = oracle_canvas(), port_canvas(False), port_canvas(True)
    def label(im,t):
        out=Image.new('RGB',(im.width,im.height+15),(0,0,0)); out.paste(im,(0,15))
        ImageDraw.Draw(out).text((3,3),t,fill=(240,240,240)); return out
    def stack(panels,scale):
        L=[label(im,t) for im,t in panels]; g=6
        W=max(p.width for p in L); H=sum(p.height for p in L)+g*(len(L)-1)
        out=Image.new('RGB',(W,H),(18,18,18)); y=0
        for p in L: out.paste(p,(0,y)); y+=p.height+g
        return out.resize((out.width*scale,out.height*scale),Image.NEAREST) if scale!=1 else out
    panels=[(oc,"ORACLE anim_02 +20"),(pc,"port HYBRID"),(ps,"port HYBRID, $A4A4 swapped (index1<->2, A4A4 pixels only)")]
    stack(panels,3).save(os.path.join(OUTDIR,"anim02_a4a4swap_full_x3.png"))
    cx0,cx1,cy0,cy1=64,144,128,176
    stack([(im.crop((cx0,cy0,cx1,cy1)),t+" [crop]") for im,t in panels],8).save(os.path.join(OUTDIR,"anim02_a4a4swap_lowerbody_x8.png"))
    # fused 1:1 too (HS-B6 gate)
    stack(panels,1).save(os.path.join(OUTDIR,"anim02_a4a4swap_full_1x1.png"))
    print("wrote anim02_a4a4swap_full_x3.png / _full_1x1.png / _lowerbody_x8.png (oracle|hybrid|hybrid+A4A4swap)")

    # ---- three fact-sets (cols 72..112) ----
    def orow(og,y): return ''.join('.oBw'[og[y][x-XOFF]] if 0<=x-XOFF<len(og[0]) else ' ' for x in range(72,113))
    og = grid_from_bin.__self__ if False else None
    oc_im=Image.open(ORACLE_PNG).convert('RGB'); W,H=oc_im.size; o280=oc_im.resize((W//2,H),Image.NEAREST); opx=o280.load()
    def onn(x,y):
        rgb=opx[x,y]; return min(range(4),key=lambda i:sum((a-b)**2 for a,b in zip(rgb,APPLE[i])))
    print("\n=== FACTS (cols 72..112) — HYBRID palette classified {.=blk o=orange B=blue w=wht} ===")
    print("(1) $A4A4 swapped vs oracle  &  (2) rows show CURRENT(hybrid) / SWAPPED / ORACLE")
    for y in list(range(150,168)):
        cur=''.join('.oBw'[port[y][x]] for x in range(72,113))
        swp=''.join('.oBw'[(SWAP.get(port[y][x],port[y][x]) if tag[y][x]=="A4A4" else port[y][x])] for x in range(72,113))
        orc=''.join('.oBw'[onn(x-XOFF,y)] if 0<=x-XOFF<280 else ' ' for x in range(72,113))
        a4=''.join('^' if tag[y][x]=="A4A4" else ' ' for x in range(72,113))
        print(f" row{y}: ORACLE {orc}")
        print(f"        HYBRID {cur}")
        print(f"        SWAP   {swp}")
        print(f"        A4A4>  {a4}")
    print("\n(3) rows 166/167 are substrate (A4A4 mask = 0 there) -> SWAP row == HYBRID row (unchanged).")

if __name__=='__main__': main()
