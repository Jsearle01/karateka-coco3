# content/ provenance manifest — hand-tuned vs generated

**Purpose:** `content/*/converted.s` is a HYBRID — most files are pure converter
output, but some were **hand-modified during scene-5 fine-tuning** and are
**irreplaceable** (re-running the converter would silently overwrite the tuning).
This manifest classifies each file **mechanically** (by diffing against a fresh
converter run — NOT from memory) so regeneration never clobbers tuned work.

> **⚠ REGEN WARNING — read before running the converter over `content/`:**
> Only the **CLEAN-GENERATED** list below is safe to regenerate in place. The
> **DIFFERS-FROM-CONVERTER** and **BINARY-DUMP** lists must NOT be regenerated
> without re-applying / re-verifying — regenerating them **destroys** hand-tuning
> or produces wrong output (they don't come from this converter). When in doubt,
> convert to a TEMP path and diff first.

## Method (mechanical, regenerable — HS-2)
For each `content/**/converted.s`: parse its ORIGIN header (source `.s`, Apple II
label, `start_col`), run `harness/tools/sprite_convert.py` fresh to a **temp**
path (never over `content/`, HS-3) with the header args × {default, `--flip-parity`},
and byte-compare the `fcb` data.
- **EXACT match** → clean-generated (converter reproduces it).
- **Differs** → hand-tuned OR converter-edge-nuance (protect).
- **ORIGIN is a binary dump** (`dump05*`, not a `.s`) → `sprite_convert.py` can't
  reproduce it (a different tool/dump path made it) → unverifiable via this
  converter → protect.
Coverage: 108 `converted.s`; converter is `harness/tools/sprite_convert.py`;
inputs `C:/Projects/karateka_dissasembly_claude/src/*.s`.

## CLEAN-GENERATED — safe to regenerate (46)
Exact `fcb` match with a fresh conversion (parity/start_col in brackets).
- `akuma/`: akuma_feet_9F8C[flip], akuma_frame_0/1/2/5 [flip]
- `bird/`: eagle_body_9FC4[flip], s5_985c_eagle_head[def]
- `broderbund/copyright`[def]
- `font/`: a,b,c,colon,comma,d,e,f,g,h,hyphen,i,j,l,m,n,o,p,period,r,s,t,u (all sc=119[def])
- `player/`: legs_9B00, legs_9BE5, legs_9C1B, legs_9D1E, torso_9E92 [def]
- `scenery/`: s5_9858, s5_9a2a, s5_9a74_banner [def]
- `title/`: title_a, title_e, title_k, title_k_flourish, title_r, title_ra_connector, title_t [def]

## DIFFERS-FROM-CONVERTER — PROTECT, do NOT blind-regenerate (25)
Differ from every fresh-conversion attempt (a small # of rows at best args → a mix
of genuine hand-tunes and minor converter-edge nuances; treat ALL as protected).
- **`akuma/akuma_throne_room_9EB8`** — CONFIRMED hand-tune (the blue-floor-line
  removal, rows 32/34/36/38 zeroed; Jay-known, cross-check ✓).
- `akuma/`: akuma_frame_3, akuma_frame_4, akuma_frame_6, akuma_frame_7, akuma_frame_8
- `bird/eagle_head_9FD8`
- `broderbund/`: broderbund_logo_sprite_1 (sc=119), broderbund_logo_sprite_2 (sc=84)
- `font/`: glyph_k, glyph_v, glyph_w, glyph_y
- `player/`: legs_9B6B, legs_9C65, legs_9CAF, legs_9CD7, torso_9D68, torso_9D97,
  torso_9DD5, torso_9E05, torso_9E2E, torso_9E4A, torso_9E74
- `scenery/s5_9a18`

## BINARY-DUMP — PROTECT, not reproducible via sprite_convert.py (37)
ORIGIN is a binary dump (`dump05` / `dump05_imprison.bin`) or has none — this
converter reads `.s` sources only, so these are **source-of-truth** (verify with
the dump-conversion path, not `sprite_convert.py`).
- `akuma/`: akuma_elem_984F, fig_974B, fig_9F8C
- `floor/`: fig_1200, fig_14BE, floor_9600, floor_964A, floor_964A_cell, floor_96CE, floor_971D, floor_9743
- `guard/`: fig_899C, fig_8ACB, fig_8F2B
- `princess/`: fig_1530, 1588, 1611, 169A, 16CC, 175E, 17D3, 1829, 1867, 1CC4, 1CD4,
  1D00, 1D36, 1D5A, 1D7E, 1DA2 (all `dump05_imprison.bin`); fig_1DD7 (`sprite_1dd7.s` not in oracle src)
- `scenery/`: fig_12C8, fig_18BF, s5_9980_cell_door
- `unsorted/`: fig_18D0, fig_8EC1
- `initial_palette` (no sprite ORIGIN)

## Cross-check vs Jay's memory (HS-4)
- **`akuma_throne_room_9EB8` blue-line removal** — Jay-known; **caught** in
  DIFFERS ✓.
- **Princess leg/turn/fall X-offset tuning** (Jay mentioned) — these live in
  **`src/engine/princess_controller.s` (code: `pr_leg_align`, pose aligns), NOT in
  `content/`** sprites. So they are not content hand-tunes; the princess *content*
  is all binary-dump (unverifiable via this converter). Discrepancy surfaced: Jay's
  "princess tables" tuning is code, not sprite content.

## Regenerate (the converter command)
```
python harness/tools/sprite_convert.py \
  --source C:/Projects/karateka_dissasembly_claude/src/<sprite_data*.s> \
  --label <AppleII label from the ORIGIN header> \
  --start-col <start_col from the header>  [--flip-parity] \
  --output content/<category>/<name>/converted.s
```
**Only for CLEAN-GENERATED files.** For DIFFERS/BINARY-DUMP files, convert to a
temp path and diff first — never overwrite in place.

## Caveats / uncertainty (HS-2 best-effort)
- The 25 DIFFERS are a **candidate** set: "differs" ⊇ "hand-tuned" (a targeted
  edit) but also includes minor converter-version-drift (the converter evolved —
  parity fix 2026-06-14, color-cell-fill 2026-06-13) and start_col/parity
  reconstruction limits. Separating a true hand-tune from a converter nuance needs
  per-file diff inspection — but for the PROTECTION goal all 25 (and the 37
  binary-dump) are treated identically: **do not blind-regenerate.**
- The 46 CLEAN-GENERATED are definitive (exact byte match).
