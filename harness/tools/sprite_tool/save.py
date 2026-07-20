#!/usr/bin/env python3
"""
save.py — Milestone 5: save an edited cel (converted.s + opacity sidecar + registry state).

Rules (from the plan):
  - converted.s written through the M1 lossless writer. OPACITY-ONLY edit => BYTE-IDENTICAL
    (black stays index-0; only the sidecar/state change). Colour edits change those bytes only.
  - Sidecar (opacity.s) written where opaque work exists; deleted when none remains.
  - Registry opacity STATE is a CONSEQUENCE of saving, never hand-set:
      save-with-opaque -> 'authored' (+ sidecar);  save-with-only-trans -> 'none' (no sidecar).
    Converter's born state 'converted' is NEVER touched for cels the user didn't open.
  - .bak per file; save only edited cels.
"""
import os, re, shutil, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from celio import Cel
import opacity as O
import sidecar as SC

def _bak(path):
    if os.path.exists(path):
        shutil.copy2(path, path + ".bak")

# ---- registry three-state in scene6_placement.txt [registry] (optional 3rd column) ----
def read_state(table_path, sprite_id):
    section = None
    for line in open(table_path, encoding="utf-8"):
        s = line.split("#", 1)[0].strip()
        if s == "[registry]": section = "reg"; continue
        if s.startswith("["):  section = None; continue
        if section == "reg":
            p = s.split()
            if p and p[0] == sprite_id:
                return p[2] if len(p) >= 3 else "converted"
    return None

def write_state(table_path, sprite_id, state):
    """Set sprite_id's [registry] state column (add/update); preserve everything else verbatim."""
    with open(table_path, "r", newline="") as f:
        raw = f.read()
    nl = "\r\n" if "\r\n" in raw else "\n"
    ends = raw.endswith(nl)
    lines = raw.split(nl)
    if ends: lines = lines[:-1]
    section = None
    for i, line in enumerate(lines):
        s = line.split("#", 1)[0].strip()
        if s == "[registry]": section = "reg"; continue
        if s.startswith("["):  section = None; continue
        if section == "reg" and s:
            p = s.split()
            if p[0] == sprite_id:
                comment = line.split("#", 1)[1] if "#" in line else None
                cols = [p[0], p[1], state]
                new = f"{cols[0]:<7} {cols[1]:<40} {cols[2]}"
                if comment is not None:
                    new += "   #" + comment
                lines[i] = new
                break
    out = nl.join(lines) + (nl if ends else "")
    with open(table_path, "w", newline="") as f:
        f.write(out)

def save_cel(cel, cel_dir, label, opacity_grid, sprite_id, table_path):
    """Derive+verify the opacity descriptor, then write converted.s + sidecar + state atomically.
    Returns (state, kind). Raises O.CannotEncode / AssertionError (STOP) — never a silent fallback."""
    kind, payload = O.derive(cel, opacity_grid)          # raises CannotEncode if unrepresentable
    ok, detail = O.verify(cel, opacity_grid, kind, payload)
    if not ok:
        raise AssertionError(f"opacity descriptor did NOT verify ({detail}) — STOP")

    conv = os.path.join(cel_dir, "converted.s")
    _bak(conv)
    cel.write(conv)                                      # M1 lossless writer

    if kind == 'none':
        _bak(SC.path_for(cel_dir))
        SC.remove_sidecar(cel_dir)
        state = 'none'
    else:                                                # mixed / masked = opaque authored
        _bak(SC.path_for(cel_dir))
        SC.write_sidecar(cel_dir, label, kind, payload)
        state = 'authored'

    write_state(table_path, sprite_id, state)
    return state, kind
