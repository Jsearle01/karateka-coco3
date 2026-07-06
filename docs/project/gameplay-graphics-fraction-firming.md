# Gameplay-Scene Graphics Fraction — Firming the Projection Band

**Investigation** (byte-classification + arithmetic only — no build/convert/code/disk).
**t0 (C-35):** 2026-07-05T23:36:22
**Refines:** `content-expansion-capacity-projection.md` (the ±10 KB band whose center
sat on the 153 KB DECB line; the graphics-fraction extrapolation was the dominant
uncertainty). **Ratio held at 1.65× (HS-5) — only the mix is revisited.**
**HS status:** HS-1 measurement-only (no build/convert/code/disk — held) · HS-2 the
gameplay-vs-intro test could NOT be run as posed (see §1 — the dumps don't support it;
reported, not forced) · HS-3 anchor-parity method (sprite-bank bytes ÷ non-system
content) · HS-4 per-image vs full-game separated · HS-5 ratio + format decision untouched.

---

## 1. Scope finding (HS-2) — the available dumps are ALL intro-cinematic, sharing ONE resident image

The 7 oracle dumps (`dump01_intro … dump07_attract`) are **not** distinct gameplay
levels. The differential analysis (`../karateka_dissasembly_claude/docs/differential-analysis.md`,
dump-based = high authority per CLAUDE.md §2) shows:

- **$6000–$BFFF (24 KB) is byte-IDENTICAL across all 7 dumps** (100% stable).
- **$1000–$1FFF is 99.9% stable** (4 SMC bytes vary); $0200–$0CFF is 100% stable.
- The **only** per-scene variation is the **hi-res framebuffers** ($2000–$5FFF, ~14%
  vary — *rendered* output, not stored content) plus ZP state.

So a **single resident content image (~31.5 KB non-system)** underlies every one of the
7 captured states, and it **already contains every combatant actor sprite** — player,
Akuma, guard, **princess**, eagle, floor, scenery (the 37 "dump05_imprison-sourced"
CoCo sprites live in the stable $1000–$1FFF / $6000–$BFFF banks, resident in *all*
dumps including the intro).

**Two consequences:**
1. **The dispatch's premise is largely void.** "Intro is less sprite-dense than
   gameplay" is false for *actors* — the intro dump already carries them. Gameplay
   adds mainly simple **sprite-drawn level backgrounds** (Karateka stores no full-screen
   art — see the prior doc), not a new denser class.
2. **The actual gameplay LEVELS (cliff / courtyard / throne-fight) are not captured in
   any dump.** So the *full-game* graphics fraction cannot be directly measured from
   existing artifacts — that needs new gameplay-level dump capture + classification
   (**out of measurement-only scope, HS-1**). This is the honest gap, not closed here.

---

## 2. Achievable refinement — the resident-image graphics fraction (firmer than 36%)

What the dumps *do* let me firm, by the anchor's method (sprite-bank bytes ÷ non-system
content), is the **resident-image** fraction — and it corrects the prior loose 36%.

- **Denominator (non-system content):** 64 KB − system (ZP 256 + stack 256 + hi-res
  buffers 16,384 + I/O 4,096 + ROM/LC 12,288 = 33,280) = **32,256 B (31.5 KB)**. (The
  prior doc's ~39 KB denominator double-counted — the coverage-map classes sum to 111%
  of 64 KB; 31.5 KB is the clean, method-consistent figure.)
- **Graphics numerator (documented sprite banks, all resident/stable):**
  $0400-067F, $11E8-18FF, $1C7A-1DFF, $1E00-1FFF, $8000-8C66, $8C67-97FF, $9B00-9FFF,
  $A400-ACFF, $BBEC-BFE7 (+ the $9800-9AFF second bank).

| variant | graphics B | fraction |
|---|---:|---:|
| low (exclude $11E8-18FF as possible code) | 12,290 | **38.1%** |
| core (documented ORIGINs) | 14,106 | **43.7%** |
| high (+ $9800-9AFF bank) | 14,874 | **46.1%** |

**Firmed resident-image graphics fraction ≈ 38–46% (mid ~44%)** — meaningfully **higher
than the prior loose 36%**, driven by the corrected (smaller) denominator and the fact
that all actor sprite banks are fully resident. The residual ±4% is the sprite-vs-code
ambiguity at $11E8-18FF and the sound-data share of the "sprite/animation/sound" tables.

---

## 3. Recomputed projection (ratio held 1.65×, HS-5)

`CoCo = (1−gf)·124·1.0 + gf·124·1.65`, using the refined anchor as the disk-content gf:

| gf | CoCo KB | vs 153 DECB | vs 157.5 raw-35 | vs 175 40-trk |
|--:|--:|:--:|:--:|:--:|
| 36% (prior loose) | 153.0 | on the line | fits | fits |
| **38% (refined low)** | **154.6** | **OVER** | fits | fits |
| **44% (refined mid)** | **159.5** | **OVER** | **OVER** | fits |
| 46% (refined high) | 161.1 | OVER | OVER | fits |

**Refined band ~155–161 KB, center ~158 KB** — shifted **up ~6 KB** from the prior
~151.5 KB, now sitting **OVER the 153 KB DECB-usable line and at/over the 157.5 KB
raw-35 limit**. Two-disk still ruled out; 40-track enters only at the high band + any
code-reimplementation >1×.

**Load-bearing caveat:** this applies the *resident-image* fraction (~44%) as the
full-disk gf. The disk is ~124 KB; the resident image is only ~31.5 KB of it. The other
~92 KB (gameplay-level overlays) is **uncaptured** — if those overlays are code-heavier
(level logic/AI) the full-disk gf falls back toward ~36%; if graphics-heavier it rises.
So the center is a **refined anchor, not a firmed full-game point** — the direction
(upward, over 153) is robust; the exact center still awaits the level dumps.

---

## 4. Threshold verdict + DECB-vs-raw input (§6)

> **The refined anchor pushes the projection center OVER the 153 KB DECB line (~155–161 KB,
> center ~158 KB), up from "right on the line." The DECB directory tax (~4.6 KB) is now
> LIKELY LOAD-BEARING — DECB-vs-raw leans toward the straddle/raw side.**

Mapping to §6:
- **gf > 42% (refined mid/high)** → center **over 157.5 KB** → **raw-35 doesn't fit
  either** → **40-track or a ~3–8 KB content trim/compression enters**; format-independent
  capacity work.
- **gf 38–42%** → center **153–157.5 KB** → the load-bearing straddle → **raw-35 buys the
  fit** (at the cost of `LOADM`/`DIR` + `DOS`-boot); DECB needs a small trim.
- The prior "fits DECB with margin" reading **does not survive** the refined anchor — the
  center no longer sits comfortably under 153.

**Direction is firm (upward, over 153); the exact rung (raw-35 vs 40-track vs trim) still
turns on the uncaptured gameplay-level mix.** Do NOT commit the format (Jay's call / 3b-2).

---

## 5. Gaps — the residual uncertainty

1. **Gameplay-level overlays (~92 KB of the 124 KB) are uncaptured.** The 7 dumps are all
   intro-cinematic; no cliff/courtyard/throne-fight dump exists. This is the dominant
   residual band cause. **Firming it needs new dump capture (MAME to those game states) +
   classification — a separate task (HS-1 STOP), not measurement of existing artifacts.**
2. **Sprite-vs-code / sprite-vs-sound ambiguity** at $11E8-18FF and the "sprite/animation/
   sound" tables (±4% on the resident fraction).
3. Ratio is settled (1.62×/1.68×, HS-5) — not a contributor.

---

## 6. Candidates / deviations

- **CANDIDATE (reframing):** all 7 dumps share ONE byte-identical resident image
  ($6000-$BFFF 100% stable) that **already contains every actor sprite** — the
  "gameplay denser than intro" premise is largely void; gameplay adds simple
  sprite-drawn backgrounds, not a denser class. [differential-analysis.md:40-90]
- **CANDIDATE (correction):** the resident-image graphics fraction is **~38–46% (mid
  ~44%)**, not 36% — the prior denominator was inflated (~39 KB vs the clean 31.5 KB).
- **CANDIDATE (verdict shift):** refined center **~158 KB, OVER the 153 KB DECB line**
  (up from ~151.5) → DECB directory tax likely load-bearing; raw-35/40-track/trim enters;
  the "fits DECB with margin" reading does not survive.
- **CANDIDATE (gap):** the gameplay LEVELS are uncaptured — the full-game fraction needs
  new dump capture, not existing-artifact measurement.
- **DEVIATION (HS-2):** the posed gameplay-vs-intro classification could **not** be run —
  the available dumps are all intro-cinematic with an identical resident image; the
  gameplay levels aren't captured. Reported as the scope finding (per HS-2's "if only the
  intro is classifiable, that's the finding — do NOT re-report the intro as if it firmed
  the full game"), and delivered the achievable refinement (resident-image fraction) with
  the full-game extrapolation explicitly caveated.
