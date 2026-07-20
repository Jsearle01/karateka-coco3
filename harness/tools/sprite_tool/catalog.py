#!/usr/bin/env python3
"""
catalog.py — enumerate content categories + the frames/cels in each (Part A).

Category = a content/<category>/ dir that holds cels (player, guard, akuma, princess, bird,
floor, scenery, hud, title, broderbund, font, background, unsorted, ...). Within a category:
  - cels that belong to an [animation] block show as ASSEMBLED frames (existing sub-byte assembly);
  - all other cels show as INDIVIDUAL cels (standalone, authorable at their own dims).
No composition is invented for non-animation cels — individual is the correct current-state view.
"""
import os, glob
from placement_table import ROOT

CONTENT = os.path.join(ROOT, "content")

def categories(table):
    """content/ subdirs that actually contain cels, sorted; 'unsorted' = uncategorized."""
    out = []
    for d in sorted(os.listdir(CONTENT)):
        p = os.path.join(CONTENT, d)
        if os.path.isdir(p) and glob.glob(os.path.join(p, "*", "converted.s")):
            out.append(d)
    return out

def _block_category(table, block):
    cats = set()
    for fr in table.anim[block]:
        for part in fr.parts:
            if part.cel_id in table.registry:
                cats.add(table.registry[part.cel_id].split("/")[1])
    return cats

def entries_for(table, cat):
    """List of (label, kind, arg):
         kind='anim' arg=(block, index) — an assembled animation frame
         kind='cel'  arg=cel_dir        — a standalone individual cel
       Animation frames (whose cels live in `cat`) first, then individual cels not in a block."""
    out, anim_dirs = [], set()
    for block in table.anim:
        if cat in _block_category(table, block):
            for i, fr in enumerate(table.anim[block]):
                out.append((f"{block} {fr.fid}", "anim", (block, i)))
            for fr in table.anim[block]:
                for part in fr.parts:
                    if part.cel_id in table.registry:
                        anim_dirs.add(os.path.normpath(os.path.join(ROOT, table.registry[part.cel_id])))
    for celdir in sorted(glob.glob(os.path.join(CONTENT, cat, "*"))):
        if os.path.isdir(celdir) and os.path.exists(os.path.join(celdir, "converted.s")):
            if os.path.normpath(celdir) not in anim_dirs:
                out.append((os.path.basename(celdir), "cel", celdir))
    return out
