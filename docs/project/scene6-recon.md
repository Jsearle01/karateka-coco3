# Scene-6 Oracle Recon — the attract fight-demo (asset + timing/placement spec)

**Execution-grounded recon.** Scene 6 (the CoCo port's next scene) = the Apple oracle's
**attract "one fight" demo** (intro-cycle scene 8: hero vs one guard, in the gameplay space,
scripted, hero wins). Scene 6 is **past the scene-4 oracle wall**, so the spine is: **the
running game is authority; the oracle `.s` is a HYPOTHESIS source.** Every entry below is
tagged `[CONFIRMED]` (execution-observed) or `[HYP]` (hypothesis — oracle label / bank
cross-ref, pending Jay's live-MAME adjudication). Identity/color/position is **Jay's call**
(HS-4) — this doc LOCALIZES (source→object→frame→column) and hands Jay a targeted list.
**t0:** 2026-07-06T15:46:32. Read-only (oracle repo + prod `88eba89…` untouched; no
conversion/code/build). Trace tools: `karateka_dissasembly_claude/tools/attract_scene6_trace.lua`,
`scene6_sprite_localize.lua` (untracked in the oracle repo).

---

## Phase A — reach, hold, repeatability, trace vocabulary

### Reach + hold `[CONFIRMED]`
Boot `apple2e -flop1 dumps/karateka.dsk` and let the intro+attract cycle run **from RAM,
no key press**. Timeline (per-second cluster sample):
- **0-6.5 s** black (boot load). **~7 s** scene 1 appears. **~7-64 s** intro scenes (cluster
  static `$52=00`). **~65-107 s** a held-cluster cinematic (`$52=30 $51=FE` static — scene 5
  imprison `[HYP]`). **~108 s+** the **FIGHT DEMO** — the full coordinate cluster starts
  actively decrementing (`$52`: 30→2C→27→22→1E…, `$51/$62/$72/$91` moving in lockstep).
- The **active-cluster signature** (whole cluster moving = character positions changing)
  distinguishes the fight demo from the static-cluster scene 5. Onset frame ≈ **6480 (~108 s)**.

### Repeatability `[CONFIRMED]` — HS-2 gate PASSES (deterministic)
**3 runs land byte-identical at the fight-demo onset** (t108 `$50=05 $51=FA $52=2C $62=0F
$72=2C`; t110 `$50=05 $51=20 $52=22 $62=10 $72=22 $91=42` — identical run 1/2/3). This game's
attract cycle plays **frame-for-frame deterministically** from a fixed boot — the
"demonstration fight" is scripted, **no RNG divergence**. So the reach is fully repeatable
(boot + wait to ~108 s). *(Notable: contradicts the general "attract loop non-deterministic"
assumption — the ≥3-run gate REVEALED determinism, which simplifies all downstream work.)*

### Trace vocabulary `[CONFIRMED by observed change]` (HS-3)
Which candidates are LIVE during the cycle (change-count over 125 s), and their role `[HYP]`:
- **`$03/$04` (67/59 changes) — the SPRITE-SOURCE POINTER** (`src = $04·256 + $03`), most
  active; drives which sprite is blitted. The primary localization handle.
- **`$50/$51/$52/$62/$72/$91` — the q016 coordinate cluster** (10-18 changes): `$51` column
  counter, `$52` a group/column, `$62/$72/$91` the x/y coordinate triple; maintained in
  lockstep by `attract_state.s` batch primitives `[HYP: q016]`. Active-decrement = the fight
  demo's character motion.
- **`$39/$3A/$3B` (16-17) — animation-state** candidates. **`$3D` (4) — barely active** (not
  a fight-demo driver).

---

## Phase B — asset inventory (LOCALIZED; identity OPEN, pending Jay — HS-4/HS-5)

Distinct sprite sources sampled per-frame across the fight demo (frames 6400-7400): **286
distinct** — an OPEN inventory (many are transient animation cels/scenery). Top sources by
dwell (frames present), with the oracle bank as `[HYP]` data-location:

| # | source | frames | dwell | col@first | bank / oracle note `[HYP]` |
|--:|--------|--------|------:|:---:|---|
| 1 | **`$A684`** | f6529-7399 | 165 | `$28`→dec | `$A400` combat/climbing bank — **dominant MOVER** (walks across) |
| 2 | `$AA11` | f6458-7165 | 60 | `$2F` | `$A400` — oracle: **floor pattern** (scenery) |
| 3-… | `$A686 $A688 $A68A $A68C $A68E $A690 $A703 $A705` | f6529-7400 | 10-32 | `$24-$1D` | `$A400` — **2-byte-stepped cels = one combatant's animation cycle** |
| 4-… | `$0B12-$0B1B` (cluster) | f6423-7390 | 14-30 | `$2C-$30` | `gameplay_state_0b00.s` — **2nd combatant / gameplay-driven object** |
| 12 | `$A688` | f6636-7061 | 21 | `$20` | `$A400` combat |
| 13 | `$8ACB` | f6400-6419 | 20 | `$30` | `$8300` bank — brief at the scene-5→6 transition |
| 20-21 | `$AB90 $AB4A` | f6420-6537 | 6 | `$30` | `$A400` — oracle: **floor patterns** (scenery, early) |
| 19,23,28 | `$83DA $8EC3 $83B2` | f6499-7354 | 4-6 | `$1B-$2B` | `$8300` bank sprites |
| 29 | `$9A3B` | f7210-7376 | 4 | `$21` | `$9800` bank — scenery `[HYP]` |

**Catalog structure (OPEN — HS-5):**
- **LOCALIZED-BUT-UNRESOLVED** (identity pending Jay): every source above — trace-localized
  (source→frames→column), but who/what/color is Jay's live-MAME call.
- **Strong hypotheses for Jay** `[HYP]`: (a) the `$A68x-$A70x` 2-byte-stepped cluster = **one
  combatant's animation cels**, moving col `$28→$1D` = walking across — likely the **hero**
  (the dominant mover); (b) the `$0B1x` cluster = the **second combatant (guard?)** or a
  gameplay-state object, near-static column; (c) `$AA11/$AB4A/$AB90` = **floor/scenery**
  (oracle floor-pattern labels); (d) the `$8300/$9800`-bank sources = additional scenery/cels.
- **The remaining ~256 sources** = transient cels/scenery — SEEN-BUT-UNRESOLVED; not falsely
  closed.

### TARGETED adjudication list for Jay (HS-8) — bounded per-object questions
Run the demo (boot, wait to ~108 s, watch ~108-125 s; use the operator-gate flags `-window
-speed 0.5 -prescale 3`) and adjudicate:
1. The **dominant mover** (`$A684`+`$A68x` cels, col `$28`→decreasing): is it the **hero**?
   its color? which cel = which action (walk/kick/punch/block)?
2. The **`$0B1x` object** (near col `$30/$50`, static-ish): is it the **guard**? scenery? UI?
3. `$AA11`, `$AB4A`, `$AB90`: **floor/scenery** confirm? colors?
4. Any on-screen object NOT in the top-30 above (e.g. a hit-spark, a background element)?

---

## Phase C — timing & placement (mechanism CONFIRMED; per-object pending Jay)

- **Motion mechanism `[CONFIRMED]`:** the coordinate cluster (`$52/$51/$62/$72/$91`) is
  batch-updated in lockstep (per q016 `[HYP]`), so a combatant's column moves smoothly (the
  dominant mover: col `$28`→`$1D` over f6529-7399 ≈ walking left/across the gameplay space).
- **Appearance timing `[CONFIRMED]`:** fight-demo onset f≈6480 (~108 s); the mover (`$A684`)
  enters f6529; the `$0B1x` object is present from f6423 (spans the transition); floor sprites
  early (f6420-6537).
- **Per-object position/cadence `[pending Jay]`:** the trace localizes each source's
  column@first and frame span (table above); the exact per-frame position + the animation
  cadence that makes the fight "read" right is trace-derivable for the IDENTIFIED assets once
  Jay names them — a follow-up trace scoped to the confirmed sources.
- **Variance `[CONFIRMED none]`:** deterministic — the ≥3-run byte-identity means timing
  captured in one run IS the timing (no attract variance for this game).

---

## Status / open items
- **25.3-V is the core gate:** Jay's live-MAME adjudication is the SOURCE of asset identity —
  the LOCALIZED-BUT-UNRESOLVED entries stay open until he watches the demo and answers the
  targeted list. Clyde localized; Jay identifies.
- **Data-location `[HYP]`:** identified sprites' data lives in the `$A400`/`$0B00`/`$8300`/
  `$9800` oracle banks (cross-ref above) — mark confirmed only once a trace confirms the
  source address IS the actual sprite data (not just a pointer value) at conversion time.
- **NOT done (later dispatches):** conversion, the scene-6 CoCo hook, the sandbox — this recon
  is the spec they consume.
