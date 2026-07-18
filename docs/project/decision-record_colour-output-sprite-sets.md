# Decision record — colour output & sprite-set architecture (karateka-coco3)

Consolidated colour decisions from the 2026-07-18 palette/RGB arc. Companion to `palette-study.md`
(sampling + candidates) and the port post-mortem Vol II. **Report/record only — the values below are
landed in the fallback driver's `palette_sets`; prod `karateka.bin` `88eba89…` is untouched.**

## D1 — The two palette sets (FINAL, landed)
Named `palette_sets` table in `tests/scripted/scene6_climb_crawl_driver.s`; each row = 4 bytes
(`$FFB0..$FFB3` = black/orange/blue/white):

| set | index | black | orange | blue | white | monitor | measured blue / orange |
|---|---|---|---|---|---|---|---|
| 0 COMPOSITE | `$00,$26,$2D,$3F` | `$00` | `$26` | **`$2D`** | `$3F` | Monitor Type=Composite | (54,179,247) / (245,115,58) |
| 1 RGB | `$00,$26,$19,$3F` | `$00` | `$26` | **`$19`** | `$3F` | Monitor Type=RGB | (0,170,255) / (255,85,0) |

**Black `$00`, orange `$26`, white `$3F` are shared; only index 2 (blue) differs (`$2D` vs `$19`)** — a
one-entry diff, so the two sets are the same art under a different monitor decode. Jay's fused-read chose
`$19` for RGB (reads best with the orange in context) and `$2D` for composite (the earlier hybrid gate).

## D2 — Palette-per-monitor selector axis
The selector carries **{monitor → palette table}** atop the (future) **{clean/fringed → asset set}** axis.
- The two palette tables differ in **exactly one entry** (the blue).
- The active set is a **boot-time USER CHOICE** — the CoCo3 GIME emits composite AND RGB simultaneously and
  the 6809 cannot sense which monitor is attached, so there is **no auto-detect**. Landed as a `pal_select`
  byte read at boot from `PAL_SEL_DEFAULT` (a runtime byte a future boot menu can write).
- **Interactive boot menu = deferred** (separate infra); today the selection is the assemble-time default
  (`-DPAL_SEL_DEFAULT=0|1`).
- The selector is a **deliberate oracle divergence** — the Apple II boots straight to attract with no such
  choice; it exists because real CoCo3 hardware demands it. Do not later remove it as "infidelity."

## D3 — Composite re-tune ruled out (measured)
The composite blue was NOT re-tuned further because no closer composite value exists:
- Swept **all 64 GIME composite palette values** (measured via MAME's gime composite decode,
  `pal_sweep.lua`): `$2D`→(54,179,247) is the **nearest composite to the oracle blue (25,144,255), d=46**;
  the next candidates are farther (`$2C` d54, `$1C` d55). No composite value beats `$2D` toward the oracle.
- **RGB `$19` (d=36) is closer to the oracle blue than the best composite `$2D` (d=46)** — so for the blue,
  **RGB is the more faithful mode.** The residual cross-mode blue gap (`$2D` composite vs `$19` RGB ≈ 55) is
  a **gamut floor**: composite's intensity/hue decode and RGB's 4-level bitpack simply reach different
  points, and neither reaches the oracle's exact (25,144,255) (RGB has no G=144 / R=25 level; composite's
  nearest is `$2D`). Conclusion: the two-set design (best-per-monitor) is the right response, not a single
  re-tuned value.

## D4 — Through-line (recorded, not re-decided)
Every composite-fidelity question is unanswerable without a real CoCo3, and MAME's composite fidelity is
itself unverified — so the pragmatic path is **target RGB (verifiable now, Monitor Type=RGB), observe
composite when hardware exists**, and don't compensate for an effect that can't be measured. The standing
visual gate now defaults to RGB (CLAUDE.md §4). Storage: two full cel sets fit stock 128KB (measured, ~60KB
slack); **addressability** (a resident second set needs a bank-aware blit; the 6809 sees only 64KB) is a
separate, unmeasured cost that only comes due on the both-sets-in-one-build path — tracked, not solved here.

*Landed values: `510ee85` (palette_sets + pal_select). Standing gate flip: CLAUDE.md §4. Default flip to
RGB: the code commit accompanying this record.*
