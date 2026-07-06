# Content Expansion Factor + Disk-Capacity Projection

**Investigation** (measurement + arithmetic only — no build/convert/code/disk).
**t0 (C-35):** 2026-07-05T23:07:04
**Method:** measure CoCo-bytes ÷ Apple-bytes from the already-converted
`content/**/converted.s` set, break down by class, project the full CoCo image
from the Apple ~124 KB, compare to the fixed disk-capacity thresholds.
**HS status:** HS-1 measurement-only (no build/convert/code/disk — held) ·
HS-2 every ratio has a known Apple denominator (dump-sourced flagged, not
estimated) · HS-3 class breakdown (not a blended average) · HS-4 mix stated with
source + low/high band.

---

## 1. Formats (why graphics expand and code doesn't)

- **Apple sprite:** `byte0=height`, `byte1=width` (**7 px/byte**), then `H×W_a`
  bitmap → Apple bytes = `2 + H·W_a`. (Oracle `sprite_data_*.s`, format verified
  commit 2c4de8b.)
- **CoCo sprite:** `fcb H, W_c` (**4 px/byte**), then `H×W_c` → CoCo bytes =
  `2 + H·W_c`. Height is preserved across conversion.
- The expansion is fundamentally the **7→4 px/byte re-pack**: to hold the same
  pixel width, `W_c = ceil(W_a·7/4)`, so the bitmap grows toward **7/4 = 1.75×**
  (the ceiling), less for narrow sprites where byte-rounding bites.
- **No full-screen imagery class exists.** The Apple hi-res pages `$2000-$5FFF`
  are **render buffers** (rebuilt per scene from sprites+code), not stored disk
  content (oracle `memory-coverage-map.md:142-143`). Karateka draws every screen
  from sprites — there are **no stored 8 KB bitmaps to expand**. This retires the
  "imagery expands 2-3×" fear: content is **sprites (~1.65×) + code/tables (~1×)**.

---

## 2. Measured expansion — per class (this task)

CoCo side: all 108 `content/**/converted.s` parsed (11,922 CoCo bytes total).
Apple side: `.s`-sourced labels resolved in the oracle (`../karateka_dissasembly_claude/src`),
Apple bytes = `2 + H·W_a`. **71 of 108 have a complete `.s` denominator (HS-2);**
37 are binary-dump-sourced (`dump05*`) — same sprite class/physics, but the Apple
denominator is not in `.s` form → flagged unmeasured, **not estimated**.

| Class (measured, `.s`-sourced) | n  | CoCo B | Apple B | ratio |
|--------------------------------|---:|-------:|--------:|------:|
| scenery                        |  4 |   322  |   180   | **1.789** |
| broderbund (logo sprites)      |  3 |   762  |   436   | **1.748** |
| title (letterforms)            |  7 |  1710  |  1020   | **1.676** |
| player (run legs+torso)        | 16 |  1520  |   952   | **1.597** |
| akuma                          | 11 |   873  |   549   | **1.590** |
| bird (eagle)                   |  3 |    78  |    54   | 1.444 |
| font (glyphs)                  | 27 |   794  |   556   | 1.428 |
| **ALL-MEASURED**               | 71 |  6059  |  3747   | **1.617** |

**By size** (quantization effect, HS-3):

| Bucket                 | n  | CoCo B | Apple B | ratio |
|------------------------|---:|-------:|--------:|------:|
| LARGE (Apple >50 B)    | 22 |  4409  |  2623   | **1.681** |
| SMALL (Apple ≤50 B)    | 49 |  1650  |  1124   | 1.468 |

**Reading:** the **large-sprite ratio 1.68×** is the planning number for
substantial content (it approaches the 1.75 pixel-repack ceiling — e.g.
`akuma_throne_room` 1.79, `title_r` 1.79, logos 1.74-1.78). Small/narrow sprites
average **1.47×** (byte-width rounding). Blended across all measured: **1.62×**.
Mask handling is not a separate axis here — these sprites are stored bitmap-only
(no separate mask plane in `converted.s`), so no with/without-mask split applies.

**Dump-sourced (unmeasured denominator — HS-2 gap):** 37 artifacts, 5863 CoCo
bytes (princess 17 / floor 8 / akuma 3 / guard 3 / scenery 3 / unsorted 2 /
initial_palette 1). Same sprite format and 7→4 px physics, so the **1.62-1.68×
class ratio applies**; only the exact Apple denominators are not in `.s` form.

---

## 3. Content mix of the ~124 KB (HS-4 — sourced anchor + band)

**Base:** the Apple game ships on `karateka.dsk` = 143,360 B (35×16×256, DOS 3.3),
**~124 KB used content**, spread across 7 streamed 64 KB scene images
(`dumps/dump01_intro … dump07`).

**Mix anchor (sourced):** the one image with a byte-classified coverage map is
`dump01_intro` (`memory-coverage-map.md`). Removing system regions (ZP/stack/
hi-res buffers/ROM = not stored content), its stored content ≈ 39 KB, of which the
sprite banks sum to **14.1 KB = ~36% graphics** (`sprite_data_*.s` ORIGIN sizes:
640+1816+512+390+3175+2969+1280+2304+1020). The remaining ~64% is code/data.

**Band (assumed extrapolation to the full game):** the intro anchors **~36%
graphics**; gameplay/imprison scenes are sprite-heavier, intro/attract code-heavier.
Banded **25% (low) – 45% (high)** graphics fraction. *This is the load-bearing
soft input — the ratio itself is well-measured; the full-game graphics fraction is
the extrapolation.*

**Code/tables ratio:** no converted-code sample exists (the CoCo engine is a fresh
6809 reimplementation, not a byte-conversion), so non-graphics content is taken at
**~1.0×** (Apple content ported 1:1). Flagged assumed; sensitivity below.

---

## 4. Projection (Σ class bytes × class ratio)

`CoCo = (1−gf)·124·code_ratio + gf·124·gfx_ratio`

| graphics % | gfx ratio | **CoCo KB** | vs 153 DECB | vs 157.5 raw35 | vs 175 40-trk |
|-----------:|----------:|------------:|:-----------:|:--------------:|:-------------:|
| 25% (low)  | 1.55 | **141.1** | fits | fits | fits |
| 30%        | 1.60 | 146.3 | fits | fits | fits |
| **36% (intro anchor)** | 1.617 | **151.5** | fits | fits | fits |
| 40%        | 1.65 | 156.2 | OVER | fits | fits |
| 45% (high) | 1.681 | 162.0 | OVER | OVER | fits |

**Primary band: ~141–162 KB, centered ~151.5 KB (code = 1.0×).**

**Threshold sensitivity** (code = 1.0×, gfx 1.65×): exceed **153 KB DECB** needs
graphics > **36%**; exceed **157.5 KB raw-35** needs > **42%**; exceed **175 KB
40-track** needs > **63%**; exceed **306 KB two-disk** needs > **226%** (impossible).

**Code-ratio sensitivity** (gfx 36%): code 1.0×→151 KB · 1.1×→160 KB · 1.2×→167 KB
· 1.3×→175 KB. A CoCo reimplementation materially >1× (the new HAL/blit/disk-loader
code has no Apple equivalent — but that is *new* code, not expansion of Apple
content) shifts the whole band up.

---

## 5. Threshold verdict (§2 fixed arithmetic)

Reference rungs: **35-track raw** 161,280 B = 157.5 KB · **35-track DECB usable**
156,672 B = 153.0 KB (dir tax ≈ 4.6 KB) · **40-track DECB** ≈ 175 KB (granule count
vs `disk-basic-unravelled.pdf` unverified; stock-drive 40-track compat is a
separate hardware caveat — flagged, not resolved) · **two-disk** = 2×153 KB.

> **VERDICT: single 35-track disk — projected ~141–162 KB, landing right at the
> DECB usable line (~151.5 KB vs 153 KB).**
>
> - The band **straddles 153 KB (DECB usable) and 157.5 KB (raw 35-track)** across
>   the 36–42% graphics range. This is precisely the §6 "format-vs-capacity
>   interact" zone: the **~4.6 KB DECB directory tax becomes load-bearing**, so
>   **DECB-vs-raw is the one live capacity sub-question**.
> - **40-track** is a tail risk only — reached if graphics exceed ~63% of content
>   (well above the 36% anchor and 45% high band) **or** code reimplementation runs
>   ≳1.3×. Format-independent if it happens.
> - **Two-disk is ruled out** under any realistic mix (would need graphics >100%
>   of content). The original "1 disk vs 2" range collapses to **"one 35-track
>   disk; DECB-vs-raw is the only lever."**

---

## 6. Gaps — which input most needs firming

1. **Full-game graphics fraction (the band driver).** Anchored at 36% from the
   *intro* image only; scenes 2-7 (`dump02…dump07`) lack a byte-classified
   coverage map. Firming this (classify graphics vs code per scene dump) would
   collapse the 141-162 band toward a point. **This, not the ratio, is the
   dominant uncertainty.**
2. **Code reimplementation ratio** (assumed 1.0×). No converted-code sample; the
   6809 reimplementation + new CoCo-only HAL/render/loader code could push
   non-graphics content >1×, shifting the band up (1.3× → ~175 KB).
3. **37 dump-sourced sprite denominators** (princess/floor/guard/imprison) not in
   `.s` form (HS-2). Same class/physics as the measured 1.62-1.68×, so they don't
   change the ratio — noted for completeness, not a projection driver.

---

## 7. Candidates

- **CANDIDATE (decisive):** measured sprite expansion is **1.62× blended / 1.68×
  large** (n=71, provenance-complete), converging on the **7/4 = 1.75 px-repack
  ceiling** — *not* the guessed 1.75-3×. [content-expansion-capacity-projection.md §2]
- **CANDIDATE (scope-collapsing):** **Karateka stores no full-screen imagery** —
  hi-res pages are render buffers, all content is sprites+code
  (`memory-coverage-map.md:142`). The imagery-expansion fear is void.
- **CANDIDATE (verdict):** projected **~141-162 KB → single 35-track disk**,
  straddling the DECB/raw line; **two-disk ruled out**; DECB-vs-raw is the only
  live capacity lever.
- **CANDIDATE (gap):** the full-game **graphics fraction** (not the ratio) is the
  band's dominant uncertainty — firm it by classifying `dump02…dump07`.

---

## 8. Deviations

- **Denominator source:** used the Apple `.byte H,W` sprite headers (oracle `.s`)
  as the per-artifact denominator rather than address-delta name arithmetic —
  exact and format-verified. 37 dump-sourced artifacts flagged unmeasured (HS-2),
  not estimated.
- **Mix is banded, not a point** (HS-4): the full-game graphics fraction is
  extrapolated from the intro anchor; reported as a 25-45% band with the verdict's
  straddle called out honestly.
