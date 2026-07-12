# Known Issues

Tracked defects in the CoCo3 port and their resolution status. Most recent first.

---

## PREVIEW-GATE PASSED (Stage 0) — Scene-6 cast color-swap: blind column origin
**Date:** 2026-07-09; resolved 2026-07-12 · **Area:** `harness/tools/sprite_convert.py`, scene-6 assets

### RESOLUTION — Stage-0 mass-convert + Jay's authored parity rule + preview hue gate `[2026-07-12]`
The full scene-6 asset set was converted at correct parity and **Jay's preview hue gate PASSED**
("they all look good", pending further sandbox verification). Three sub-resolutions:
- **Combatants (player/guard), the CROSS-parity movers:** parity is an **authored choice** (a mover
  has no single true column) — Jay's rule: **player = ORANGE-dominant, guard = BLUE-dominant**
  (guard cels also `--mirror`, STATIC draw-B). Implemented in `stage0_convert_scene6.py` by
  converting both parities and picking the target-dominant one. This **supersedes** the old
  "3 CROSS candidates flagged" note below — CROSS parity is resolved by the authored target, not by
  a single traced column.
- **Background (Fuji `$A948`/`$A976`/`$A9B8`/`$A9E2`, floor `$AA11`, scroll `$A6/A7/A8` bank):** these
  are **static-position, single-parity** → parity correct **by construction** from the traced column
  (`stage0_convert_scene6_bg.py`, columns from the background-inclusive trace `scene6_bg.log`). No
  target guessing, no mirror.
- **Existing blind scene-6 player cels:** re-converted in place at correct parity (16 `player_run_*`
  color-only diffs, `46df721`).
- Gate artifacts: `build/scene6-stage0-preview/scene6_{player,guard,background}_sheet.png` (167 cels).
  Converted assets are on-disk **untracked** pending Jay's sandbox verification, then promote to
  tracked. (`content/scenery/`+`content/floor/` are SCENE-5, not scene-6 — excluded.)
- **OQ-6 provenance [2026-07-12]:** the 4 background cels `content/background/scene6_bg_{A948,A976,
  A9B8,A9E2}` were **flood-filled post-hue-gate** during Stage 1 (Jay-authorized) — sky/edge/interior
  index-0 reclassified for the opaque backdrop blit (`harness/tools/floodfill_bg_sky.py`; coco3
  idiom §9b). Recorded so the disk matches the record; **not re-gated / not re-converted**.
- **HUD arrow `$0B12` [2026-07-12, Stage-2 prereq]:** converted from dump05 into `content/hud/`
  (player-orange `arrow_0B12` draw-A + guard-blue `arrow_0B12_mir` `--mirror`) per the Stage-0
  color-target rule. Cel is **NOT left-right palindromic** (`--mirror` genuinely reverses). On-screen
  column parity **CLOSED — Jay hue gate PASSED 2026-07-12** ("hue check is sat") on
  `scene6_hud_sheet.png` (player reads orange / guard reads blue).

### (original 2026-07-09 report)
**Area:** `harness/tools/sprite_convert.py`, scene-6 cast candidates

### Symptom
Scene-6 cast candidates converted with a **blind/default column origin** (`--start-col 0`
in the prior id-sheet pass) baked the wrong blue/orange for any candidate whose true
on-screen parity is ODD — the same column-parity reversal as the scene-5 cast (below),
but for the scene-6 actors. Jay's ruling: the color-swap fix is **inert without the real
per-sprite render column** — the converter cannot pick parity blind.

### Root cause
Hue is baked from `screen_col = start_col + col` parity (see the scene-5 entry). The
converter already parameterized `--start-col` correctly (there was **no hardcoded ~133
assumption** — code is authority over that premise), but the scene-6 pass fed it `0`.
The missing input was the **actual render column**, which past the scene-4 oracle wall
must come from the **running game, not `attract_state.s` labels**.

### Fix (trace-driven column origin)
1. Traced the **L1903 draw entry** (`$1903 → routine_1a42`) over the scene-6 window
   (climb ~f6019 → fight ~f6480, deterministic). Column model, from `routine_1927`
   (CODE authority over the "$06 = X base" comment): **`$05` = horizontal byte column,
   `$10` = sub-byte pixel shift (0-6), `$06` = Y start row.** Screen pixel column =
   **`$05`·7 + `$10`**; parity = that mod 2.
2. Added `--render-col-byte`/`--render-shift` to `harness/tools/sprite_convert.py`: feed
   the traced `$05`/`$10` directly, converter computes `start_col = byte*7 + shift`, so
   the origin is trace-sourced by construction (overrides `--start-col`; backward
   compatible). Header now stamps the screen-col parity.
3. Prove-on-one (diff): `cand@$9B00` (traced ODD) at old `start_col=0` (EVEN) vs traced
   (85, ODD) → `fcb` color bytes **flipped** (that flip IS the fix); `cand@$8E9B` (traced
   EVEN) vs `start_col=0` (EVEN) → `fcb` data **identical** (parity matched).

### Still OPEN (per-candidate, Jay's ruling)
Most candidates hold **one parity across their frames** (the game steps `$05`/`$10`
together to preserve hue → one baked CoCo3 color is faithful). Three candidates —
`cand@$942A`, `cand@$93AB`, `cand@$9A18` — **CROSS parity** across frames: one baked
color cannot be faithful to the Apple's moving hue. These are **flagged, not resolved**
— the per-parity-variant call (bake variants, or accept one) is Jay's. Identity of every
candidate is Jay's live-MAME gate off the preview sheet (`build/scene6-cast-preview/`).

---

## RESOLVED — Sprite blue/orange column-parity reversal (cast)
**Date:** 2026-06-14 · **Area:** `tools/sprite_convert.py`, scene-5 cast content

### Symptom
Several scene-5 cast sprites rendered with blue and orange **swapped** versus the
Apple II original (e.g. Akuma's robe/head came out blue instead of orange; the
eagle's body came out orange instead of blue).

### Root cause
The converter derives each chroma pixel's hue (orange vs blue) from the Apple II
**screen-column parity** of that pixel: for a palette-1 (orange/blue) dot,
`even screen column → blue (index 2)`, `odd → orange (index 1)`. The screen column
is computed as `start_col + col`, so the entire hue assignment hinges on the
`--start-col` passed at conversion time. Cast sprites converted at an assumed
column origin whose parity differed from the sprite's true on-screen column came
out with **every** blue/orange reversed. Because CoCo3 is palette-indexed (not
parity-derived like Apple II hi-res), this reversal is baked permanently into the
converted data — it is not a runtime artifact.

### Fix
1. Added `--flip-parity` to `tools/sprite_convert.py` — XORs the parity test
   (`(screen_col % 2 == 0) ^ parity_flip`), a **color-only** swap with no shape
   change. Use when a sprite was converted at the wrong column parity.
2. For the scene-5 `fig_*` cast (converted "by address" with no clean source `.s`),
   added `tools/flip_parity_inplace.py`, which swaps the 2-bit pixel fields
   `01<->10` directly on an already-converted `.s`. Verified **byte-identical** to
   re-running the converter with `--flip-parity` (oracle: `eagle_body_9FC4`).

### Verification
Jay visual gate against Apple II reference snapshots of the imprisonment scene
(`C:\karateka-capture\snap\apple2e\0097-0102.png`, frames 4000-6000, `$3D=$01`).
All flagged sprites flipped and re-confirmed: Akuma (gloat + throne, orange),
eagle body (blue), princess body/walk/poses, guard, and floor/props. Cast colors
PASS; remaining sprites may surface as the full scene is assembled.

---

## RESOLVED — Karateka logo vertical-line striping
**Date:** 2026-06-13/14 · **Area:** `tools/sprite_convert.py` color-cell fill, scene 3

### Symptom
The KARATEKA title logo (scene 3) showed thin vertical black lines striping the
otherwise-solid letterforms.

### Root cause
Apple II hi-res color-cell fill: a black dot flanked by the same chroma on both
sides reads as solid color. The converter was leaving those interior gap dots
black, producing vertical striping in solid letter strokes.

### Fix
Color-cell fill in `convert_sprite_to_coco3` fills a Black dot when flanked by the
same chroma (index 1 or 2) on both sides. The title logo content
(`content/title/title_*/converted.s`) was re-converted through the fixed converter; the
only diff is gap-filled bytes (e.g. R-A connector row `$11 -> $15`) — geometry
unchanged. The R-A connector position was then hand-tuned to byte 32 / row 111.

### Verification
Jay visual gate, scene 3: striping gone, connector position PASS.
