# Run-composition map — execution-confirmed (2026-07-20, Stage B0)

**Type:** READ-ONLY identification + data port (the analogue of `climb-beat-composition-map.md`).
**Recipe:** CLEAN `-video none -keyboardprovider none -sound none -nothrottle` oracle attract
(no key-leak, idioms §10a). **Prod ROM:** `88eba89b15cdf17c8d25e082d2d3e1f3cce57d38` untouched
(verified post-build). **Authority:** the run animation plays past scene 4, so every claim below is
from **execution** (blit-entry trace of the running oracle), never from a disasm label.

## Method + evidence
`harness/tools/stageb0_run_capture.lua` — read-taps on the four blit trampolines
`$1903/$1906/$1909/$190C` (these DO fire on 6502 — idioms §7b; not a §1 routine-body false-0).
Per draw it logs cel `$04:$03`, col `$05`, **sub-byte `$10`**, row `$06`, flip `$0F`, and
`$52/$62/$72`, tagged by frame; filtered to the run bank `$9B00-$9EB7`.
Run: 200 emulated s over a whole attract cycle → `build/logs/stageb0_run_attract.txt`.

The run animation plays **twice** per attract cycle:

| window | context | poses |
|---|---|---|
| f6423–6630 | the player's approach run into the guard fight | 17 |
| f8610–8947 | the scene-6 **walk-off** (Recon 1's `$62`→`$2A` advance — it is a RUN) | 25 |

**42 pose observations. Every `(legs,torso)` pairing yields a UNIQUE `(dx, dy, rowLegs, rowTorso)`
across both windows — zero contradictions.** `$9EB8` (akuma throne cel) is adjacent to the bank and
was excluded; it is not a run cel.

**Independent geometric confirmation (not used to derive anything):** for all 11 frames
`rowTorso + heightTorso == rowLegs` exactly — the torso's last row abuts the legs' first row, no gap
and no overlap. And every frame's foot line lands on **y161** except `c1`/`c5` (y160 — the raised
foot mid-stride).

## The structure — 16 CELS, **11 frames**, not "16 frames"
`conventions.md §12.3` calls it "the 16-frame run cycle is 8 leg sprites + 8 torso sprites."
Execution says the **16 is a CEL count, not a frame count**:

- **2 start frames** (`s0`,`s1`) — the accelerate-in, drawn once per run.
- **an 8-frame steady cycle** (`c0`..`c7`) — observed looping `c0→c7→c0…` in both windows.
- **1 stop frame** (`e0`) — the settle, observed at f6630.

All 8 legs and all 8 torsos are execution-confirmed in use (none dead). It is **not** a mirrored 8:
every draw in both windows came through entry **A** with `flip=$00` — no `$1909/$190C` mirror draw
was observed, so the attract only ever shows the rightward run (a leftward run would mirror; **not
execution-confirmable from this window** — residue).

**The cycle is a leg-phase × torso-phase composite, NOT a 1:1 leg→torso map:** `$9B00` pairs with
`$9D68` at `c0` and with `$9D97` at `c4`; `$9B6B` likewise; `$9BE5+$9DD5` occurs twice per cycle
(`c2`,`c6`). 5 legs + 5 torsos compose the 8 cycle frames; the remaining 3+3 are start/stop.

## The anchor (execution-confirmed — no invented origin)
In every steady-state pose of the f8791–8870 stretch, **legs col == `$62` (the player position)**
with sub 0 — the legs cel's `xadj` is **zero**, so *a frame's origin IS the player X* and the torso
sits at `+dx` apple-px from it. Frames are therefore normalized to one anchor
(`ANCHOR = $13*7 = 133`, a real observed steady-state legs X) so the ported cycle plays **in place**;
Stage B2's engine supplies the live X advance. Rows are carried **verbatim** from the oracle.

## Per-frame table
Oracle columns are apple-px offsets (`x = col*7 + sub`); port columns are the CoCo3 `col,sub,row`
via the **same** registration as the climb crawl (`x = col*7 + sub + 20`; `col = (x>>2) +
leading_trim`, `sub = x & 3`) — `harness/tools/gen_stageb0_run.py`.

| frame | legs | torso | dx | dy | rowLegs | rowTorso | port legs (col,sub,row) | port torso (col,sub,row) | dwell |
|---|---|---|---|---|---|---|---|---|---|
| s0 | `$9CAF` | `$9E4A` | +7 | −20 | 143 | 123 | 39,1,143 | 40,0,123 | 11 |
| s1 | `$9CD7` | `$9E74` | +7 | −14 | 139 | 125 | 38,1,139 | 40,0,125 | 11 |
| c0 | `$9B00` | `$9D68` | +7 | −15 | 141 | 126 | 38,1,141 | 41,0,126 | 11 |
| c1 | `$9B6B` | `$9D68` | +10 | −15 | 141 | 126 | 38,1,141 | 41,3,126 | 11 |
| c2 | `$9BE5` | `$9DD5` | +14 | −23 | 149 | 126 | 39,1,149 | 41,3,126 | 11 |
| c3 | `$9C1B` | `$9E05` | +7 | −13 | 138 | 125 | 38,1,138 | 40,0,125 | 11 |
| c4 | `$9B00` | `$9D97` | +7 | −15 | 141 | 126 | 38,1,141 | 41,0,126 | 11 |
| c5 | `$9B6B` | `$9D97` | +10 | −15 | 141 | 126 | 38,1,141 | 41,3,126 | 11 |
| c6 | `$9BE5` | `$9DD5` | +14 | −23 | 149 | 126 | 39,1,149 | 41,3,126 | 11 |
| c7 | `$9C65` | `$9E2E` | +7 | −13 | 138 | 125 | 38,1,138 | 40,0,125 | 11 |
| e0 | `$9D1E` | `$9E92` | 0 | −12 | 138 | 126 | 38,1,138 | 38,1,126 | 11 |

Draw order per frame = **legs then torso** (verbatim trace order; torso on top), matching the climb
block's back-to-front token order.

## Dwell — measured, load-dependent
Frame-to-frame VBL gaps (display VBL = MAME frame, idioms §8a):

- **f8802–8947 (free-running walk-off, scroll stopped): 11,12,11,11,11,12,11,11,11,12,11,11,10 →
  the clean steady-state cadence is 11 VBL.**
- f8610–8791 (same run, fight scenery still drawing): 17–21.
- f6423–6630 (approach run, load rising): 7,7,8,8,11,10,11,13,12,14,15,16,19,19,19,18.

The cycle advances **one pose per main-loop tick**; the loop is **compute-bound** (§8a), so the VBL
gap tracks scene load rather than an animation constant. **11 is the clean free-running value and is
what the ported block carries** — the 7–21 spread is load, not per-frame timing design. A per-frame
dwell constant in the game code was **not** located this pass (residue; would settle it definitively).

## Port status
- `content/scene6/scene6_placement.txt`: 16 `[registry]` rows + the `[animation] run:` block (above).
- The codegen (`gen_scene6_placement.py`) emits `reg_*` rows for the run cels (pure `fcb w,h,start_col`
  data) and **ignores** the `run:` block — only `climb_crawl` is emitted to asm. So this is a **pure
  data port**: no engine/scroll build (that is Stage B2), and **prod is byte-identical**
  (`88eba89b15cdf17c8d25e082d2d3e1f3cce57d38`, re-verified after `build.bat`).
- The sprite tool now lists all 11 run frames as **assembled** entries under `player`
  (`run s0 … run e0`), and no run cel appears as an individual cel any more.

## Residue (not execution-confirmed this pass)
- **Mirrored/leftward run** — never drawn in the attract window; entry map is `A`-only, `flip=$00`.
- **A per-frame dwell constant in code** — not located; dwell reported as measured VBL cadence.
- **`e0` (stop) observed once** (f6630); the second run was cut by the loop-back at f8951.
- **Where the cycle re-enters after `c7`** is confirmed as `c0` by observation, but the game's own
  frame-index wrap was not read from code.
- Visual fidelity of the assembled frames is **Jay's gate** (25.3), not a Clyde pixel read.
