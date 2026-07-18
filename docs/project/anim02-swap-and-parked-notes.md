# anim_02 swap test + parked notes (2026-07-18) — REPORT ONLY, nothing fixed/concluded/promoted

## Deliverable B — blue↔orange SWAP test at the CURRENT palette (facts only)
Re-coloured the captured anim_02 index-frame (`pose_2.bin`) with index 1 ↔ index 2 exchanged in the
rendered output, palette held at CURRENT (`$1B`/`$26`) so the ONLY variable is the swap. No cel
re-convert, no converter change, no shipped-build change. Panels: `build/anim02_compare/anim02_swap_*`.
Coord: `CoCo3_px = Apple_px + 20`; square-pixel NEAREST (×3 full / ×8 crop). The two-band per-pixel
facts (canvas cols 72–112; `.`=black `o`=orange `B`=blue `w`=white):

**BAND 1 — mid-body (the mismatch rows).** Where CURRENT shows an orange cluster and ORACLE shows blue,
the SWAP turns it blue (matches there) — BUT the swap simultaneously flips the mid-body blue that
CURRENTLY matches to orange (breaks there). E.g. row153: ORACLE `BBB…BBB oooooo` → CURRENT
`BBB…BBB oooooo` → SWAPPED `ooo…ooo BBBBBB` (the right cluster now matches, the whole left blue run
now mismatches). Same shape at rows 155/157; rows 160–164 are mixed (some cells improve, some worsen).

**BAND 2 — base rows that CURRENTLY MATCH (166/167).** SWAP BREAKS BOTH:
- row166: ORACLE orange, CURRENT orange (match) → SWAPPED **blue** (mismatch).
- row167: ORACLE blue,   CURRENT blue   (match) → SWAPPED **orange** (mismatch).

**Fact (no conclusion — Jay rules):** the blanket blue↔orange swap is **not clean** — it repairs some
mid-body orange clusters but flips currently-matching blue (mid-body) and the entire base rows 166/167
the other way. This matches Jay's standing objection that an all-or-nothing flip can't fix the
sky-region lines while leaving the correct lines alone. Whether this is acceptable / partial / wrong is
Jay's call from the panels + this table.

## PARKED — record, do NOT act
- **HS-P1 — missing shadows at the characters' feet/hands** (Jay noticed this session). **Ruling: NOT
  NOW — follow-up after palette + orange-lines are sorted.** Untested hypothesis (do NOT investigate,
  do NOT fix): the repo already has **`HAL_gfx_blit_sprite_opaque`** (`src/hal/coco3-dsk/gfx.s:436–441`,
  "Use for black shadows", faithful to the oracle's `$0F`-selected store blend `video.s routine_1927`).
  The climb poses call the **transparent** blit, where index-0 keys transparent — so an all-black shadow
  cel would vanish through it. **So the shadows may be a DRAW-PATH omission for the climb, not an art
  defect / not a re-convert.** Flagged untested.
- **`$AA7D` shape/extent delta** (port stripes vs oracle black, rows 157–165) — still parked; needs a
  fuller side-by-side, separate from palette/swap.
