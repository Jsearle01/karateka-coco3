#!/usr/bin/env python3
"""
gen_scene6_placement.py — codegen the scene-6 placement table (§2F single-home).

Reads the human-readable text-source (content/scene6/scene6_placement.txt):
  [registry]  sprite_id  cel_file        -> derive w/h/start_col FROM the cel converted.s
  [placement] placement_id sprite_id x y -> the resolved placed col,row
Emits the assembly table the build reads (tests/scripted/scene6_placement_gen.s):
  reg_<id>:  fcb w, h, start_col     ; start_col PROMOTED from the cel comment to structured
  plc_<pid>: fcb x, y

The cel converted.s carries: `fcb h,w` (header, byte0=h byte1=w) and a comment `start_col=N`.
No manifest; the build reads only this generated table + the cel .s.
"""
import re, sys, os

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SRC  = os.path.join(ROOT, "content", "scene6", "scene6_placement.txt")
OUT  = os.path.join(ROOT, "tests", "scripted", "scene6_placement_gen.s")   # registry + plc_ + plc_start
OUT_ANIM = os.path.join(ROOT, "tests", "scripted", "scene6_climb_anim_gen.s")  # cl_frames (crawl only)
OUT_FUJI = os.path.join(ROOT, "tests", "scripted", "scene6_fuji_gen.s")  # fuji_ (included by backdrop)
OUT_RUN  = os.path.join(ROOT, "tests", "scripted", "scene6_run_anim_gen.s")   # run_frames (B2')
OUT_ARCH = os.path.join(ROOT, "tests", "scripted", "scene6_arch_gen.s")       # arch composite (B2' arch)

def parse_cel(cel_dir):
    """Return (w, h, start_col) derived from the cel's converted.s (h/w from `fcb h,w`, start_col from comment)."""
    f = os.path.join(ROOT, cel_dir, "converted.s")
    with open(f, encoding="utf-8", errors="replace") as fh:
        txt = fh.read()
    # header: first `fcb h,w` after the label line (h = rows, w = bytes/row)
    m = re.search(r"^\s*fcb\s+(\d+)\s*,\s*(\d+)", txt, re.M)
    if not m:
        raise SystemExit(f"no fcb h,w header in {f}")
    h, w = int(m.group(1)), int(m.group(2))
    sc = re.search(r"start_col=(\d+)", txt)
    start_col = int(sc.group(1)) if sc else 0
    return w, h, start_col

def main():
    registry = {}   # sprite_id -> cel_file
    placement = []  # (placement_id, sprite_id, x, y)
    anim = []       # frames of the climb_crawl block: (frame_id, dwell, [(cel,col,sub,row)...])
    anim_loop = {}  # block -> (first_fid, last_fid) from an @loop directive (see below)
    blocks = {}     # EVERY [animation] block -> its frames (climb_crawl + run + future blocks)
    fuji = []       # (sprite_id, col, sub, row)  Fuji backdrop cels
    section = None
    cur_block = None    # current [animation] named block
    with open(SRC, encoding="utf-8") as fh:
        for line in fh:
            s = line.split("#", 1)[0].strip()
            if not s:
                continue
            if s == "[registry]":  section = "reg";  continue
            if s == "[placement]": section = "plc";  continue
            if s == "[fuji]":      section = "fuji"; continue
            if s == "[animation]": section = "anim"; cur_block = None; continue
            parts = s.split()
            if section == "reg":
                registry[parts[0]] = parts[1]
            elif section == "fuji":
                fuji.append((parts[0], int(parts[1]), int(parts[2]), int(parts[3])))
            elif section == "plc":
                # placement_id  sprite_id  col  sub  row  (sub carried always — climb lesson)
                placement.append((parts[0], parts[1], int(parts[2]), int(parts[3]), int(parts[4])))
            elif section == "anim":
                if len(parts) == 1 and s.endswith(":"):   # "<name>:" starts a named block
                    cur_block = s[:-1]
                    continue
                if parts[0] == "@loop":       # directive: the block's repeating span (first last).
                    anim_loop[cur_block] = (parts[1], parts[2])   # not a frame row — never emitted
                    continue                  #   as a frame; see the loop symbols below.
                # frame_id  dwell  cel:col,sub,row  cel:col,sub,row ...  (belongs to cur_block)
                fid, dwell, tokens = parts[0], int(parts[1]), parts[2:]
                pparts = []
                for tok in tokens:
                    cel, csr = tok.split(":")
                    v = [int(x) for x in csr.split(",")]
                    if len(v) == 3:                 # col,sub,row — single position
                        pparts.append((cel, v[0], v[1], v[2]))
                    elif len(v) == 5:               # col,sub,row0,row1,step — vertical tile
                        pparts.append((cel, v[0], v[1], v[2], v[3], v[4]))
                    else:
                        raise SystemExit(f"[animation] {cur_block} {fid}: bad part '{tok}'")
                blocks.setdefault(cur_block, []).append((fid, dwell, pparts))
                if cur_block == "climb_crawl":
                    anim.append((fid, dwell, pparts))

    # derive registry dims/start_col from the cels
    reg = {sid: parse_cel(path) for sid, path in registry.items()}

    out = []
    out.append("* tests/scripted/scene6_placement_gen.s — GENERATED by harness/tools/gen_scene6_placement.py")
    out.append("*   from content/scene6/scene6_placement.txt. DO NOT EDIT. Edit the text-source, re-run the codegen.")
    out.append("*   The single-home (§2F) scene-6 placement table the build reads. include-only; no org.")
    out.append("* --- registry: reg_<id> = fcb w, h, start_col (start_col promoted from the cel comment) ---")
    for sid in registry:
        w, h, sc = reg[sid]
        out.append(f"reg_{sid}:  fcb {w},{h},{sc}   ; w, h, start_col")
    out.append("* --- placement: plc_<id> = fcb col, sub, row (byte-col, sub-byte shift 0..3, row) ---")
    for pid, sid, col, sub, row in placement:
        out.append(f"plc_{pid}:  fcb {col},{sub},{row}   ; {sid}: col, sub, row")
    # startpose: DERIVED from [animation] climb_crawl frame 0 (the single home) — the stage-3 still's
    #   crawl-start pose. Pure data (fcb), no cel refs, so any includer is safe. plc_start_<cel>.
    if anim:
        f0 = anim[0][2]   # frame 0 parts: [(cel, col, sub, row), ...]
        out.append("* --- startpose: plc_start_<cel> = fcb col,sub,row (DERIVED from [animation] climb_crawl f0) ---")
        for cel, col, sub, row in f0:
            out.append(f"plc_start_{cel}:  fcb {col},{sub},{row}   ; crawl-start (= climb_crawl f0)")
    out.append("")
    with open(OUT, "w", encoding="utf-8") as fh:
        fh.write("\n".join(out))

    # --- Fuji backdrop table: fuji_<id> = fcb col,sub,row. Emitted to its own file, INCLUDED BY
    #     scene6_backdrop.s so every backdrop-user (draw_fuji_cels + Stage-A) reads one home. ---
    fj = []
    fj.append("* tests/scripted/scene6_fuji_gen.s — GENERATED by harness/tools/gen_scene6_placement.py")
    fj.append("*   from content/scene6/scene6_placement.txt [fuji]. DO NOT EDIT. Edit the text-source.")
    fj.append("*   The §2F single-home Fuji backdrop placement. Included by scene6_backdrop.s so the")
    fj.append("*   shared draw_fuji_cels AND Stage-A's fuji reads share one home. Pure fcb data; no org.")
    for sid, col, sub, row in fuji:
        fj.append(f"fuji_{sid}:  fcb {col},{sub},{row}   ; col, sub, row")
    fj.append("")
    with open(OUT_FUJI, "w", encoding="utf-8") as fh:
        fh.write("\n".join(fj))

    # --- climb animation table: a SEPARATE file (references the 15 climb cels, which the scrollA
    #     driver does NOT include; only the crawl drivers include this file) ---
    def label(cel_id):  # basename of the cel_file IS the assembly label (verified: label == basename)
        return os.path.basename(registry[cel_id])
    an = []
    an.append("* tests/scripted/scene6_climb_anim_gen.s — GENERATED by harness/tools/gen_scene6_placement.py")
    an.append("*   from content/scene6/scene6_placement.txt [climb_anim]. DO NOT EDIT. Edit the text-source.")
    an.append("*   The §2F single-home climb crawl animation table. Read by src/engine/climb_controller.s;")
    an.append("*   included ONLY by the crawl drivers (it references the 15 climb cels). include-only; no org.")
    an.append("*   frame block = {fcb dwell, pcnt; per part: fdb cel; fcb col,sub,row}.")
    an.append("cl_frames:")
    an.append("        fdb     " + ",".join("cl_" + fid for fid, _, _ in anim))
    # loop span: emitted ONLY if the block declares @loop (climb_crawl currently does not, so this
    # adds nothing today). The controller reads cl_loop_first/last as frame INDICES into cl_frames.
    if "climb_crawl" in anim_loop:
        ids = [fid for fid, _, _ in anim]
        first, last = anim_loop["climb_crawl"]
        an.append(f"cl_loop_first:  fcb {ids.index(first)}   ; @loop {first}")
        an.append(f"cl_loop_last:   fcb {ids.index(last)}   ; @loop {last}")
    for fid, dwell, pparts in anim:
        an.append(f"cl_{fid}:  fcb     {dwell},{len(pparts)}")
        for cel, col, sub, row in pparts:
            an.append(f"        fdb     {label(cel)}")
            an.append(f"        fcb     {col},{sub},{row}")
    an.append("")
    with open(OUT_ANIM, "w", encoding="utf-8") as fh:
        fh.write("\n".join(an))

    # --- RUN animation table (Stage B2') — same shape as cl_frames, its own file because it
    #     references the 16 run cels + the head/standing cels, which the climb drivers do not
    #     include. run_loop_first/last carry the @loop span so the controller (and the sprite
    #     tool) read the SAME single home for "where does the cycle repeat". ---
    if "run" in blocks:
        rn = blocks["run"]
        ids = [fid for fid, _, _ in rn]
        rr = []
        rr.append("* tests/scripted/scene6_run_anim_gen.s — GENERATED by harness/tools/gen_scene6_placement.py")
        rr.append("*   from content/scene6/scene6_placement.txt [animation] run:. DO NOT EDIT the generated file.")
        rr.append("*   The §2F single-home player RUN animation table (B0: 12 frames x 3 parts, legs->head->torso,")
        rr.append("*   execution-confirmed from the oracle attract). Read by the Stage-B2' driver; include-only.")
        rr.append("*   frame block = {fcb dwell, pcnt; per part: fdb cel; fcb col,sub,row}.")
        rr.append("run_frames:")
        rr.append("        fdb     " + ",".join("run_" + fid for fid in ids))
        rr.append(f"run_frame_count:  fcb {len(rn)}")
        if "run" in anim_loop:
            first, last = anim_loop["run"]
            rr.append(f"run_loop_first:   fcb {ids.index(first)}   ; @loop {first}")
            rr.append(f"run_loop_last:    fcb {ids.index(last)}   ; @loop {last}")
        for fid, dwell, pparts in rn:
            rr.append(f"run_{fid}:  fcb     {dwell},{len(pparts)}")
            for cel, col, sub, row in pparts:
                rr.append(f"        fdb     {label(cel)}")
                rr.append(f"        fcb     {col},{sub},{row}")
        rr.append("")
        with open(OUT_RUN, "w", encoding="utf-8") as fh:
            fh.write("\n".join(rr))
        print(f"wrote {OUT_RUN}: {len(rn)} run frames"
              + (f", @loop {anim_loop['run'][0]}..{anim_loop['run'][1]}" if "run" in anim_loop else ""))

    # --- ARCH table (Stage B2' arch) — the 14 $52-relative castle/archway cels as ONE static
    #     composite (frame a0) at the halt reference $52=$1B. The driver applies a common scroll
    #     delta = (cur52 - $1B)*7 px to every cel (they share the $52 coefficient; their differing
    #     fixed offsets are already baked into the halt cols), draws tiled pillars by their row
    #     range, and clips to the play area. Emit per cel: fdb label; fcb col, sub, row0, row1, step
    #     (singles get row1=row0, step=1). ---
    if "arch" in blocks:
        a0 = blocks["arch"][0][2]           # frame a0's parts
        ar = []
        ar.append("* tests/scripted/scene6_arch_gen.s — GENERATED by harness/tools/gen_scene6_placement.py")
        ar.append("*   from content/scene6/scene6_placement.txt [animation] arch:. DO NOT EDIT the generated file.")
        ar.append("*   The §2F single-home ARCH composite (14 $52-relative cels, traced by spatial region).")
        ar.append("*   Positions are the port registration at the halt reference $52=$1B; the driver applies")
        ar.append("*   the common scroll delta. Read by the Stage-B2' driver; include-only.")
        ar.append("*   Per cel: fdb cel ; fcb col, sub, row0, row1, step  (single => row1=row0, step=1).")
        ar.append(f"arch_count:  fcb {len(a0)}")
        ar.append("arch_tbl:")
        for part in a0:
            if len(part) == 4:                    # single
                cel, col, sub, row = part
                ar.append(f"        fdb     {label(cel)}")
                ar.append(f"        fcb     {col},{sub},{row},{row},1")
            else:                                 # tiled: col,sub,row0,row1,step
                cel, col, sub, r0, r1, step = part
                ar.append(f"        fdb     {label(cel)}")
                ar.append(f"        fcb     {col},{sub},{r0},{r1},{step}")
        ar.append("")
        with open(OUT_ARCH, "w", encoding="utf-8") as fh:
            fh.write("\n".join(ar))
        print(f"wrote {OUT_ARCH}: {len(a0)} arch cels")

    print(f"wrote {OUT}: {len(registry)} registry rows, {len(placement)} placement rows")
    print(f"wrote {OUT_ANIM}: {len(anim)} climb frames")
    print(f"wrote {OUT_FUJI}: {len(fuji)} fuji rows")

if __name__ == "__main__":
    main()
