# FORM B — Dispatch Completion Report

**Dispatch:** Sprite color fix — blue/orange parity (cast) + logo striping
**Executor:** Clyde · **Operator/Gate:** Jay · **Date:** 2026-06-14
**Commit:** `b80b6ed` (pushed, `main`)

## Outcome: COMPLETE — all ACs met, both Jay visual gates PASS

| AC | Result |
|----|--------|
| AC-1 — converter `--flip-parity` | Added (color-only parity XOR, no shape change) |
| AC-2 — flip flagged cast sprites | Akuma (gloat+throne+feet), eagle body, princess (body/walk/poses), guard, floor/props |
| AC-3 — cast color gate (Jay) | **PASS** vs Apple II reference (imprisonment `0097–0102.png`) |
| AC-4 — re-convert logo | All 7 `title_*` through striping-fixed converter |
| AC-5 — scene-3 gate (Jay) | **PASS** — striping gone, R-A connector tuned to byte 32 / row 111 |
| AC-6 — docs + build + commit | `docs/known-issues.md`; build clean; committed + pushed |

## Root cause
The converter derives each chroma pixel's hue (orange vs blue) from the Apple II
**screen-column parity** (`start_col + col`): for a palette-1 dot, even screen
column → blue (index 2), odd → orange (index 1). Cast sprites converted at an
assumed column origin whose parity differed from the sprite's true on-screen
column came out with **every** blue/orange reversed. Because CoCo3 is
palette-indexed (not parity-derived like Apple II hi-res), the reversal is baked
permanently into the converted data.

## Key technical result
For the by-address `fig_*` cast (no clean source `.s`), built
`tools/flip_parity_inplace.py` to swap the 2-bit pixel fields `01↔10` directly on
an already-converted `.s`. Verified **byte-identical** to re-running the converter
with `--flip-parity` (oracle: `eagle_body_9FC4`) before applying to any cast file.

## Build verification
- Prod boot `build/karateka.bin`: **7359 bytes** (unchanged — logo/connector edits
  don't alter size; cast flips don't touch the boot path)
- `build.bat`: clean, all 10 drivers assemble
- Sandbox `sprite_engine_sandbox.bin`: 5308 bytes (unchanged — flips are color-only)

## Staging decision (Jay-directed)
Scene-5 cast content **left untracked** (scene-5 WIP). Commit = converter + flip
tool + 7 logo sprites + scene-3 + docs only (11 files). Cast flips persist on-disk
and are reproducible via the committed tools. Captures, gitignored previews,
reference docs, and unrelated `.sh` drift not staged.

## Open / follow-up
- Jay noted more cast color issues may surface **as the full scene-5 is
  assembled** — expected, not a blocker. When scene-5 is built as a unit, the
  cast content gets committed then.
