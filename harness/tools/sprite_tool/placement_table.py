#!/usr/bin/env python3
"""
placement_table.py — read content/scene6/scene6_placement.txt into a structured model.

Wraps the §2F single-home table format (same sections gen_scene6_placement.py emits from):
  [registry]   sprite_id  cel_file
  [placement]  placement_id sprite_id col sub row     (static single position)
  [fuji]       sprite_id col sub row
  [animation]  <name>:  then rows "frame dwell cel:col,sub,row ..."  (animated, per-frame/part)

Read fresh each open; no persisted manifest (§2F).
"""
import os, re

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
DEFAULT = os.path.join(ROOT, "content", "scene6", "scene6_placement.txt")

class Part:
    def __init__(self, cel_id, col, sub, row):
        self.cel_id, self.col, self.sub, self.row = cel_id, col, sub, row
    @property
    def x_px(self):  return self.col * 4 + self.sub   # sub-byte pixel origin (4 px/byte)
    @property
    def y_px(self):  return self.row

class Frame:
    def __init__(self, fid, dwell, parts):
        self.fid, self.dwell, self.parts = fid, dwell, parts

class Table:
    def __init__(self, path=DEFAULT):
        self.path = path
        self.registry = {}    # sprite_id -> cel_file (repo-relative)
        self.placement = {}   # placement_id -> (sprite_id, col, sub, row)
        self.fuji = {}        # sprite_id -> (col, sub, row)
        self.anim = {}        # block_name -> [Frame, ...]
        self._parse()

    def _parse(self):
        section, block = None, None
        with open(self.path, encoding="utf-8") as fh:
            for line in fh:
                s = line.split("#", 1)[0].strip()
                if not s:
                    continue
                if s == "[registry]":  section = "reg";  continue
                if s == "[placement]": section = "plc";  continue
                if s == "[fuji]":      section = "fuji"; continue
                if s == "[animation]": section = "anim"; block = None; continue
                p = s.split()
                if section == "reg":
                    self.registry[p[0]] = p[1]
                elif section == "plc":
                    self.placement[p[0]] = (p[1], int(p[2]), int(p[3]), int(p[4]))
                elif section == "fuji":
                    self.fuji[p[0]] = (int(p[1]), int(p[2]), int(p[3]))
                elif section == "anim":
                    if len(p) == 1 and s.endswith(":"):
                        block = s[:-1]; self.anim[block] = []; continue
                    fid, dwell, toks = p[0], int(p[1]), p[2:]
                    parts = []
                    for t in toks:
                        cel, csr = t.split(":")
                        c, sub, r = (int(v) for v in csr.split(","))
                        parts.append(Part(cel, c, sub, r))
                    self.anim[block].append(Frame(fid, dwell, parts))

    def cel_path(self, cel_id):
        return os.path.join(ROOT, self.registry[cel_id], "converted.s")
