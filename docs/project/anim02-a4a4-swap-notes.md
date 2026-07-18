# anim_02 — hybrid palette applied + $A4A4-only swap preview (2026-07-18) — Phase A build change, Phase B report-only

## The prior GLOBAL swap result is VOID (do not carry F-1)
The earlier swap test (`f800f2e`) was **globally scoped by my spec** — it flipped *every* index-1 pixel,
substrate included. So its "F-1: breaks base rows 166/167" finding is **void as evidence for Jay's
hypothesis**: rows 166/167 are **substrate**, never part of the hypothesis; the global flip conflated
sprite with substrate and never tested the sprite-scoped claim. This dispatch re-runs it correctly
scoped to `$A4A4` only.

## Phase A — HYBRID palette applied globally (Jay-ruled)
Jay gated the panels: *"the hybrid looks closest."* Applied **HYBRID = blue `$2D` (54,179,247) d46 +
orange `$26` (245,115,58) d60** (Jay's eye chose `$26` over the nearer `$25` d30 — his eye is authority).
- **Where:** a named index-selected table `palette_sets` + `apply_palette_hybrid` in the **fallback**
  (`tests/scripted/scene6_climb_crawl_driver.s`), written **after** `HAL_gfx_init`. **Deliberately NOT
  in `src/hal/coco3-dsk/gfx.s`** (the study's proposed site): prod builds from `src/` including `gfx.s`,
  so a shared-palette change would move prod on any rebuild — violating the byte-identity STOP. The
  fallback override keeps `gfx.s` (prod's source) untouched ⇒ **prod byte-identical even on rebuild**,
  while re-colouring every scene THIS build renders. Structured for a second (composite/RGB) set + a
  future startup RGB/composite selector (recorded as a deliberate oracle divergence) — **neither built**.
  Tuned-for output = MAME composite.
- **Scope proof (HS-A5):** the captured **index frame is byte-identical pre/post** (pose_2 SHA1
  `DEAD5A64…` both) — no index moved; the change is purely index→RGB. **Runtime proof:** a MAME video
  snapshot of the rebuilt fallback renders blue **(54,179,247)=`$2D`** (no `(94,44,255)` violet) — the
  build actually applies hybrid.
- **Prod:** `karateka.bin` `88eba89…` **byte-identical** (not rebuilt; `gfx.s` untouched). Global re-look
  of every gated scene is Jay's, later (prior hue-gates stay valid — they chose the index, not its look).

## Phase B — $A4A4-only swap preview at HYBRID (facts only, NO verdict)
`$A4A4`'s pixels identified from placement (byte-col 22, sub 2, row 143, 22×4) + cel data by replaying
the two anim_02 blits in draw order — **`$A4A4` (back) FIRST, `$A45A` (over) SECOND**, so `$A45A`
overdraws `$A4A4` in the overlap. **Self-check: the simulated composite matches the real `pose_2.bin`
1404/1404 px** in the cel region ⇒ the `$A4A4` mask is trustworthy. Index 1↔2 swapped **only** on
`$A4A4`-tagged pixels; palette held at HYBRID (one variable = the swap).
- **`$A4A4` visible = 206 px, rows 143–164** (A45A covers the rest — the visible change is smaller than
  the cel's extent; expected, not a partial failure).
- **HS-B3 substrate scope-proof:** the `$A4A4` mask touches rows 166/167 = **0 px** → SWAP == HYBRID at
  166/167 (unchanged). **HS-B2 control:** `$A45A` pixels are never in the mask → unchanged by the swap.
- **Facts (cols 72–112, hybrid palette):** where `$A4A4` carries orange (e.g. rows 151/153/155/157 left
  clusters), the swap turns it **blue, matching the oracle** there; `$A4A4` white pixels are unaffected;
  `$A45A` and substrate rows are untouched. Full per-row map in the tool output / the panels. **No
  verdict — Jay rules from the FUSED read** (HGR artifact colour blends on composite, GIME indices
  don't, so per-pixel and fused reads can diverge).
- Renders: `build/anim02_compare/anim02_a4a4swap_{full_x3,full_1x1,lowerbody_x8}.png` (oracle | port
  hybrid | port hybrid+A4A4-swap). Preview re-colour only — no cel/converter/shipped-build change.

## PARKED (record, do NOT act)
- **Shadows** (feet/hands) — after palette + orange. Untested: `HAL_gfx_blit_sprite_opaque`
  (`gfx.s:436–441`, black shadows, oracle `$0F` blend `routine_1927`) exists; climb uses the transparent
  blit (index-0 keys transparent) ⇒ an all-black shadow cel would vanish ⇒ maybe a **draw-path omission**,
  not an art defect. Do not investigate.
- **`$AA7D` shape/extent delta** (rows 157–165) — parked.
