# Protection catalog — which content/ cels are pure converter output vs altered (2026-07-18) — REPORT ONLY, nothing converted, Jay rules the list

**Method (Jay's behavioural test):** re-convert each cel fresh from the oracle dump
(`karateka_dissasembly_claude/dumps/dump05_imprison.bin`) into a **scratch dir** (never over `content/`),
then byte-diff only the CEL DATA (`fcb H,W` header + `H*W` bitmap; ORIGIN/comment lines ignored) vs the
committed asset. **Identical ⇒ pure converter output ⇒ safe. ANY diff ⇒ PROTECTED.** `content/` untouched.

## Determinism (F-A1) — PASS
`$A3E9` converted twice with identical params → byte-identical. The method is deterministic; the diff
results are trustworthy (F-A1 not triggered).

## Re-convertible cels (188 of 280) — 184 pure, 4 altered
Recipes that supply exact params + oracle addr: `stage0_convert_scene6.py`, `stage0_convert_scene6_bg.py`,
`stage3_convert_climb.py`, `stage2_convert_arrow.py`.

| set | recipe | count | identical (pure) | DIFF (protected) |
|---|---|---:|---:|---:|
| cast-player `scene6_player_*`/`player_run_*` | stage0 | 77 | 77 | 0 |
| cast-guard `scene6_guard_*_mir` | stage0 | 66 | 66 | 0 |
| climb-player `scene6_climb_*` | stage3 | 12 | 12 | 0 |
| climb-cliff `scene6_cliff_*` | stage3 | 7 | 7 | 0 |
| hud arrow `arrow_0B12(_mir)` | stage2 | 2 | 2 | 0 |
| scene6-bg `scene6_bg_*` | stage0_bg | 24 | 20 | **4** |
| **total** | | **188** | **184** | **4** |

**Param caveat (report, not adjudication):** the full 143-dir cast was re-converted with **fixed per-kind
params** (player=orange/no-mirror, guard=blue/`--mirror`, `start_col=0`) because the current
`guard_facing.log` at draws≥4 only re-emits 50 of them. All 143 came out pure under those per-kind params;
a per-cel manifest would tighten this, but the pure verdict held for every one.

## The 4 ALTERED cels — the Mt-Fuji backdrop (PROTECTED) — shape only, Jay adjudicates
The only diffs are the **entire Mt-Fuji stack** (`$A948`, `$A976`, `$A9B8`, `$A9E2`). Shape:
- **LOCALISED** to the mountain's **edge byte-column(s)** (rightmost col; also col 0 for A9B8/A9E2) —
  every interior byte identical.
- The committed bytes **hand-extend the edge to solid `$AA` (solid blue)** where fresh convert leaves a
  partial/trimmed edge byte (`$A8`/`$80`/`$2A`/`$A0`/`$F0`/`$0A`). e.g. A948 rows 0–7 col 6: fresh `A8` →
  committed `AA`; A9E2 all 3 rows col 26: fresh `80` → committed `AA`.
- **Localised + recurring across the 4-cel Fuji subset, but only 4 of 188** ⇒ the pattern is a **themed
  authored edit** (Fuji silhouette edges filled solid to the tile boundary), **NOT** whole-set converter
  drift (which would touch every cel, not just Fuji). **⇒ the Fuji set is PROTECTED.** *(Adjudication is
  Jay's; this reports the shape per HS-A2.)*

## Working-tree nuance — `scene6_climb_A3E9` (flag, not adjudicate)
This is one of the pre-existing working-tree modifications (from before this dispatch; commit `c95c0de`
region + uncommitted edits to `content/player/scene6_climb_A3E9/converted.s` and
`harness/tools/stage3_convert_climb.py`). **On disk it is IDENTICAL to fresh convert (pure).** But the
**committed HEAD** version differs **systematically** (~21 bytes, a blue↔orange parity swap `$AA`↔`$55`,
`$54`↔`$A8`, `$2A`↔`$15`) — i.e. HEAD was converted with a parity flip; the uncommitted edit re-baked it to
pure. Against HEAD it scores DIFF (SYSTEMATIC = converter-param drift, not a localised hand-edit). Flagged
for Jay; not resolved here.

## No-recipe / no-source (auto-protected, UNVERIFIABLE) — 92 cels — HS-A4
The test **cannot run** (no recipe among the scene-6 scripts covers them; they came from earlier scene-5 /
title / font / logo converters). **Auto-protected.**

| category | count | members (abbrev.) |
|---|---:|---|
| font | 27 | `glyph_a…y`, `glyph_period/comma/colon/hyphen` |
| princess | 17 | `fig_1530 … fig_1DD7` |
| akuma | 14 | `akuma_frame_0…8`, `akuma_elem_984F`, `akuma_feet_9F8C`, `akuma_throne_room_9EB8`, `fig_974B`, `fig_9F8C` |
| floor | 8 | `floor_9600/964A/964A_cell/96CE/971D/9743`, `fig_1200`, `fig_14BE` |
| scenery (scene-5) | 7 | `s5_9858/9a18/9a2a/9a74_banner/9980_cell_door`, `fig_12C8`, `fig_18BF` |
| title | 7 | `title_a/e/k/r/t`, `title_k_flourish`, `title_ra_connector` |
| bird | 3 | `eagle_body_9FC4`, `eagle_head_9FD8`, `s5_985c_eagle_head` |
| broderbund | 3 | `broderbund_logo_sprite_1/2`, `copyright` |
| guard (scene-5) | 3 | `fig_899C`, `fig_8ACB`, `fig_8F2B` |
| unsorted | 2 | `fig_18D0`, `fig_8EC1` |
| initial_palette | 1 | `initial_palette` |
| **total** | **92** | |

## Authored — NO oracle source at all (auto-protected) — HS-A4
- `content/scenery/scene6_wall_post/authored.s`, `content/scenery/scene6_wall_rail/authored.s` — Jay's
  ratified post/rail, hand-authored via `gen_wall_post_rail.py` ("NO converter, NO parity, Jay's palette
  indices direct"). They use **`authored.s`, not `converted.s`** → already outside the 280-cel set, but
  **must be listed as protected**.
- The wall **rail** column is **not a cel** — drawn as **direct row-fills baked into the drivers**
  (`scene6_backdrop.s`, `scene6_cliff.s`, `scene6_cliff_walltop.s`, `scene6_stage3_driver.s`).
  **Driver-baked, unverifiable-by-re-convert, protected.**

## Proposed STRUCTURAL protection mechanism (HS-A5 — propose, do NOT build)
*"Remember not to run it on those"* fails at 1am — protection must be in the tool, keyed on a checked-in
list:
- **A checked-in protected manifest** (`content/PROTECTED.list`, or a `.protected` marker file per dir)
  enumerating: the 4 Fuji cels, the 92 no-source cels, `authored.s` dirs, and the driver-baked rail.
- **A converter/batch HARD-STOP:** before writing any output path, the converter (and the bulk-convert
  driver) reads the manifest and **REFUSES to overwrite** a protected path (non-zero exit, named error),
  requiring an explicit `--force-overwrite-protected` to proceed. The refusal lives in the tool, not in
  anyone's memory. **Proposed only — not implemented.**

## Bottom line (Jay rules)
Of 188 re-convertible cels, **184 pure / 4 altered (the Mt-Fuji set — PROTECTED)**; **92 no-recipe/no-source
auto-protected**; plus the **authored wall post/rail** and the **driver-baked rail**. Over-inclusion is
free (HS-A3): the auto-protected 92 are protected because the test *can't run*, not because they're proven
edited. **Jay rules the final protected list.**
