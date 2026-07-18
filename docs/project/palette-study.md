# Palette study — oracle-vs-port blue/orange (2026-07-18) — REPORT ONLY, nothing applied

**Why:** Jay: "the colors we have now look too vibrant in the fight scene compared to the oracle."
**Method:** sampled MAME's **actually-rendered** RGB (not a reference table) — oracle from a clean
apple2e capture, port from a coco3 MAME snapshot of the fallback; then swept `$FFB1`/`$FFB2` across
all 64 composite values on coco3 MAME and measured RGB distance. **CoCo3 runs in COMPOSITE mode in
MAME** (gfx.s note; SockmasterGime.md: composite = bits5-4 intensity, bits3-0 hue).

## Sampled colors (RGB, MAME-rendered)
| | ORACLE (apple2e, HGR artifact) | PORT current (coco3 composite) | port palette reg |
|---|---|---|---|
| blue | **(25, 144, 255)** — cyan/sky | **(94, 44, 255)** — violet | `$FFB2 = $1B` (int1 hue11) |
| orange | **(230, 111, 0)** — deep red-orange | **(245, 115, 58)** — brighter, washed | `$FFB1 = $26` (int2 hue6) |
| black / white | (0,0,0) / (255,255,255) | (0,0,0) / (255,255,255) | `$00` / `$3F` (match) |

**Finding:** the "too vibrant" is real and **mostly the BLUE** — the port's `$1B` renders **violet**
(G=44) vs the oracle's **cyan** (G=144); distance **121** (the largest among nearby entries). The
orange is closer (dist 60) but the current `$26` has B=58 (washed) vs the oracle's B=0.

## Nearest GIME composite entries (swept, measured)
**Blue** (target 25,144,255): current `$1B`→(94,44,255) **d=121**.
| cand | value | int/hue | RGB | dist |
|---|---|---|---|---|
| nearest | `$2D` | int2 hue13 | (54,179,247) | **46** |
| alt | `$2C` | int2 hue12 | (78,154,255) | 54 |
| lower-int | `$1C` | int1 hue12 | (16,94,233) | 55 |

**Orange** (target 230,111,0): current `$26`→(245,115,58) **d=60**.
| cand | value | int/hue | RGB | dist |
|---|---|---|---|---|
| nearest | `$25` | int2 hue5 | (221,140,1) | **30** |
| lower-int | `$16` | int1 hue6 | (182,52,2) | 76 |

## Candidate palettes (Jay picks — NOT applied)
Black `$00` and white `$3F` unchanged in all.
- **Candidate 1 (nearest match):** orange `$25` (221,140,1) · blue `$2D` (54,179,247).
- **Candidate 2 (alt blue):** orange `$25` · blue `$2C` (78,154,255).
- **Candidate 3 (less vibrant / lower intensity):** orange `$16` (182,52,2) · blue `$1C` (16,94,233).

**Comparison render (square-pixel, coco3 MAME):** `build/palette_study/palette_candidates_compare.png`
(current + the 3 candidates, stacked, each labeled with the oracle targets). **Jay picks by eye — not
self-certified.** F-B2 not triggered: nearer GIME entries DO exist (the vibrancy is a palette-choice
problem, fixable).

## HS-B4/B5 — how it should LAND (structure only; do NOT build here)
When Jay picks, land it as a **named table selected by an index**, not scattered immediates:
```
* palette_sets: one row of 4 bytes ($FFB0..$FFB3) per set; HAL_gfx_init loads palette_sets[sel*4].
palette_sets:
        fcb  $00,$26,$1B,$3F   ; set 0 = current (composite, MAME as-is)
        fcb  $00,<orng>,<blue>,$3F  ; set 1 = Jay's pick
```
- **Tuned-for output:** these values are tuned against **MAME's COMPOSITE decode** (what MAME
  emulates). State this so the future pass knows what it inherits.
- **RGB/composite two-set structure (future, do NOT author now):** the CoCo3 decodes the *same*
  `$FFBx` values differently on RGB vs composite monitors, so matching the oracle on real hardware
  needs a **second table** (RGB-format values) + a **startup RGB/composite selector**. Structure the
  table as `palette_sets[format][pick]` now so the composite/RGB set drops in as a second row and the
  **selector just chooses the index** — **do not author the RGB set, do not build the selector.**
- **DELIBERATE ORACLE DIVERGENCE (docs note):** a startup RGB/composite selector is a **port
  addition demanded by real CoCo3 hardware** — the oracle (Apple II) boots straight to attract with no
  such menu. Record it here so a later pass does not remove it as "infidelity."

## HS-B6 — blast radius (report only)
A palette change **re-colors every scene and every visual Jay has ever gated** (the climb, the logo,
scene-5 cast, the fight when ported). **Prior sprite hue-gates stay valid** — they decided which
palette *index* each pixel gets (index parity/adjacency), NOT what the index looks like — so the
index assignments don't need re-gating, but **every rendered scene needs a fresh visual re-look**
under the new palette. **Applying the palette is its own gated change — NOT done in this dispatch.**

## Tooling (new, coco3 side)
`harness/tools/coco3_snap.lua` (single coco3 render snapshot), `pal_sweep.lua` (sweep a `$FFBx`
register 0..63, snapshot each — reads MAME's composite→RGB), `pal_render.lua` (render the fallback
under a candidate `$FFB1`/`$FFB2`).
