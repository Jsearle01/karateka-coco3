# Column-parity converter fix — derive origin from render position (2026-07-18) — PARITY ONLY, NOT clean|fringed

## The fix
The climb PLAYER poses were converted with **`start_col=0` + a `pick_parity('orange')` heuristic + a
hand-maintained `FLIP_OVERRIDE` list** — the heuristic guessed the chroma parity and humans hand-patched
its misses. That silently **inverted `$A4A4`** (it passed its hue gate while blue↔orange swapped — Jay's
fused-read finding). **Fix:** derive each pose's `start_col` from its **traced Apple render column**
(`byte_col*7 + sub`, from the clean blit-entry trace via `gen_climb_anim` FRAMES) with `parity_flip=False`
— the **same model the cliff cels already used**. Parity is now correct per-cel by construction; no
heuristic, no override list. `harness/tools/stage3_convert_climb.py`.

## HS-1 / HS-4 — the rule reproduces every override + flips the control (verified in scratch)
| pose | render col | was override? | derived vs content/ |
|---|---|---|---|
| A3E9 | 63 (odd) | YES | SAME (reproduced) |
| A3C5 | 70 (even) | YES | SAME (reproduced) |
| A4F2 | 70 (even) | YES | SAME (reproduced) |
| A572 | 70 (even) | YES | SAME (reproduced) |
| **A4A4** | 70 (even) | no (missed) | **DIFF — FLIPPED (control ✓)** |
| A40B/A425/A45A/A4D2/A548/A5DC/A5CC | 63–84 | no | SAME |
| 7 cliff cels (AA23/AA31/AA7D/AB4A/AB7C/AB8E/AB94) | native | — | SAME (already render-col) |

**All 4 former `FLIP_OVERRIDE`s reproduce automatically (SAME); `$A4A4` flips (the one silently-missed
cel).** The derived rule = the removed hand-list, made principled. (F1 not hit — no override lost; F2 not
hit — the control flipped.)

## HS-3 — the diff over the 184 re-convertible cels
**Exactly one cel's DATA changes: `$A4A4`.** The other 11 climb poses + 7 cliff cels reproduce byte-
identical. The 165 non-climb re-convertible cels (scene-6 cast, arrow, scene6-bg) use **unmodified
recipes** (`stage0_convert_scene6.py`, `stage2_convert_arrow.py`, `stage0_convert_scene6_bg.py`) — the
converter is deterministic (verified), so their fresh convert is byte-identical to `content/` (they were
already established pure by the protection catalog). **Net content/ change: `content/player/scene6_climb_A4A4/converted.s` only.**
*(The recipe now records the accurate `start_col` for all 12 poses; the 11 data-unchanged poses' header
comment still reads `start_col=0` — cosmetic metadata, no data/render change — left un-adopted to keep the
change surgical to the one render fix. A future full re-run would sync those headers, data-identical.)*

## HS-9 — the fallback render change (framebuffer-diffed, surfaced for Jay)
`$A4A4` is anim_02's lower/back cel. Re-captured pose_2 pre vs post fix: **31 bytes differ, confined to
rows 143–164 / byte-cols 22–25 = exactly `$A4A4`'s placement** — nothing else moved. Spot-check render
(oracle | port pre-fix | port post-fix, hybrid palette, CoCo3=Apple+20, square-pixel NEAREST):
`build/parity_fix/anim02_parity_spotcheck_{full_x3,lowerbody_x8}.png`. The post-fix `$A4A4` is the swap
Jay already ruled correct (the report-only preview that this converter change now produces natively).
**Jay gates the render live (AC-6).**

## Safety
- **NO hue-gate re-run** — parity fixes *which index* a pixel gets, not its look (`$A4A4` passed its hue
  gate while inverted — that's why the heuristic missed it).
- **Protected untouched:** the 4 Mt-Fuji + 92 no-source + authored wall-top were not re-converted (stage3
  only emits climb player + cliff; none are protected).
- **Prod `88eba89…` byte-identical:** `$A4A4` (and all climb cels) are scene-6 content, NOT in the prod
  build — prod pulls only broderbund/font/princess/title (all no-source protected), none of the 184.
- **Scope-only:** no `src/` engine change, no palette change, no clean|fringed, no `+20` change.

## Deferred (not over-reached)
The scene-6 **cast** recipe (`stage0`) also uses the `pick_parity` heuristic (per-kind orange/guard-blue)
rather than render-position derivation — a **potential** same-class instance, but with **no confirmed bug
and no control cel** here. Not changed. If a cast cel later gates wrong, apply the same render-position
derivation (its columns are in the facing trace). Recorded, not acted on.
