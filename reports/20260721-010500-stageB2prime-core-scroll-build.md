## Form B Report — Stage B2' core scroll — **BUILT; 0 overruns at the faithful 5.45 steps/sec**

### §1  Timing (C-35 — mandatory)
t0=2026-07-21T00:39:21.084567200Z (dispatch receipt; the addendum authorised the build mid-task)
commit-time=<this commit, `git show -s --format=%cI HEAD`> — stated inline in the dispatch reply.
Elapsed: see inline. Predicted: no band supplied. Classification: n/a.

### §2  Summary
Built `tests/scripted/scene6_b2prime_driver.s` (7,229 B) on Stage A's strip-scroll, with the player
run animation, the parked guard, **actors on phase 14 (present)** per the corrected schedule, the
`$52==$1A` halt, and cadence in named constants. **Acceptance met: 0 no-wait iterations across 900
(16-VBL) and 700 (11-VBL) sampled iterations.** Cadence set to the **oracle-faithful 11 VBL/step =
5.45 steps/sec**, which required compressing 12×7-row strip chunks into **7×12-row** chunks — a
pure constant change, exactly what §5's named constants exist for. Prod
`88eba89b15cdf17c8d25e082d2d3e1f3cce57d38` untouched.

### §3  Files
- `tests/scripted/scene6_b2prime_driver.s` — NEW; the B2' driver.
- `harness/tools/gen_scene6_placement.py` — emits the `run:` block as `scene6_run_anim_gen.s`
  (`run_frames`, `run_frame_count`, `run_loop_first/last` from `@loop`).
- `tests/scripted/scene6_run_anim_gen.s` — NEW (generated).
- `harness/tools/stageb2_phasecost.lua`, `stageb2_dirtyregion.lua` — addresses/trigger parameterised
  via env (symbols move per driver).
- `build/logs/b2prime_phasecost.txt`, `b2prime_11vbl.txt` — evidence.

### §4  Verification (AC-by-AC)
**AC1 — run block emitted as asm.** `run_frames` = 12 frames (`s0 s1 c0..c7 e0 st`),
`run_loop_first=2`, `run_loop_last=9` — the `@loop c0 c7` span codegen'd from the single home, so
the tool and the engine read the same source.

**AC2 — driver on Stage A's architecture.** Extends the strip-scroll; no new scroll invented.

**AC3 — actors on phase 14, in-situ costs (replacing the derived estimates).**

| phase (11-VBL cadence) | median cyc | % VBL | headroom |
|---|---:|---:|---:|
| 0–6 strip chunks (12 rows each) | 16,048–21,340 | 53.7–71.5% | 8,519+ |
| 7 Fuji | 18,148 | 60.8% | 11,711 |
| **8 cliff + seam + clip** | **22,362** | **74.9%** | 7,497 ← busiest, actors kept OFF |
| **9 ACTORS (player+guard) + PRESENT** | **10,504** | **35.2%** | 19,355 |
| 10 idle | 123 | 0.4% | 29,736 |

**In-situ actor cost ≈ 10,380 cyc** (phase total minus the 123-cyc idle baseline); at the 16-VBL
cadence it measured **9,174**. The derived pre-build estimate was 8,793 — **in-situ is 4–18%
higher**, so the estimate was optimistic but not misleading.

**AC4 — 0 overruns (the spine).** `stageb2_phasecost.lua`: **0 no-wait iterations of 900** at 16 VBL
and **0 of 700** at 11 VBL. No phase reaches 29,859 cyc. This signal is attribution-independent.

**AC5 — halt.** `cur52` swept `$30 → $1B` and `scroll_halted=1`; the scene freezes (step_init
leaves `cur52`/`shift` untouched thereafter). Phase 2 walk-through is B3, not built.

**AC6 — run animation semantics.** Observed `run_idx`: `0,1` (s0,s1 play in once) → `2..9` repeating
(`c0..c7`) → on halt `10` (`e0` stop) → `11` (`st` standing, held). Exactly the `@loop` contract.

**AC7 — guard parked. ⚠ CORRECTED after Jay's 25.3 gate ("there are two players on screen; one
animates and moves, the other is dragged along"). Both halves were real defects:**
- **Wrong figure.** I built the guard from `$899C`/`$8ACB`/`$8E9B` — but `$8E9B` is the **player**
  head (draw-A only, faces right) and `$899C`/`$8ACB` are the climb settle figure, also the player.
  The screen genuinely had two players. I had taken "guard, 3-part" from Recon 1's **fight**-window
  model without checking what the **walk-off** window draws.
- **What the walk-off actually draws:** the guard appears **mirrored (draw-B)** from a
  **defeat-specific set absent from the fight** — `$8DA9`/`$8E83`/`$8F0E`/`$9290` — lying near the
  ground at rows 151–154. All four were already ported as `scene6_guard_*_mir`.
- **Wrong anchoring.** `col − $72` is a per-cel constant (`8DA9`+0, `8E83`+2, `9290`+3, `8F0E`+4)
  and `$72` tracks `$52`, so the guard is parked in **scene** space and travels with the scroll.
  Pinning it to a fixed **screen** column made it ride the viewport — Jay's "dragged along".
- **Fixed:** correct mirrored cels at traced rows, every column offset by `scroll_shift`.
  Re-measured: **still 0 overruns** (600 iterations); the actors phase rises 10,504 → **21,270 cyc
  (35.2% → 71.2%)** because the defeat set is 295 B vs the wrong trio's 130 B — 8,589 cyc spare.

**AC8 — named constants (§5, hard requirement).** `SCROLL_VBLS_PER_STEP`, `SCROLL_COLS_PER_STEP`,
`PRESENT_VBLS_PER_STEP`, `RUN_POSES_PER_STEP`, plus `PH_*` phase assignments, `SCROLL_HALT_S52`,
`SCROLL_SETTLE_S52`. **Proven by use:** the 16→11 VBL cadence change was made *through* the
constants (`SCROLL_VBLS_PER_STEP` 16→11, `SA_NCHUNK` 12→7, `SA_RPC` 7→12) with no scroll-logic edit
— the deferred Classic/Enhanced toggle is a constant swap, as required.

**AC9 — 3-column step delta (measured on the built driver).** Dirty-region diff, `SCROLL_COLS_PER_STEP`
1 vs 3 (the constant swap is the whole change):

| cols/step | changed bytes/step | changing window | ≈ cycles @22.5 cyc/B | % of the 11-VBL step |
|---|---:|---|---:|---:|
| **1** | 325–412 (med ~355) | rows 100–180, 244 px | ~8,000 | **2.4%** |
| **3** | 518–578 (med ~540) | rows 100–180, 220–252 px | ~12,150 | **3.7%** |

**A 3-column step costs ~1.5× a 1-column step, not 3×** — the scroll delta scales sub-linearly
(the moving features overlap) and the actor contribution is constant. So the oracle's 1–3 col
variation is a non-event for the budget; sizing a delta-only redraw for the worst case costs ~4% of
a step. *(The 1-col figure is 355 B against Stage A's 192 B because B2' now also redraws the run
pose and the guard each step — ~160 B of actors, which reconciles the two measurements.)*

**AC10 — second 25.3 pass (Jay): two further defects, both root-caused and fixed.**
- **"The right side is all black and not filling in."** NOT missing substrate. Jay: the game's
  virtual screen is **280 px**, so x280–319 (byte cols 70–79) is a **deliberate black border**.
  Verified on the live framebuffer: the band carries content in cols 64–69 (38/81 rows) and is
  black in 70+. The bug was that the strip **sampled and copied the border** — `edge_byte` came
  from snapshot col 79 (black) and was replicated into every vacated column, and the block copy
  spanned cols 25–79, dragging 10 columns of border-black leftward each step. Both now stop at
  `PLAY_R=69`; re-verified after ~54 steps (play area filled to col 69, border black).
  **Also added a right-border invariant** (clear cols 70–79 per row, mirroring the existing
  left-border clip): the first play-area clip still left cols 70/72 painted by another writer, and
  a border that relies on every routine stopping correctly breaks the next time one is edited.
- **"The player looks like he is pulled backward every animation cycle."** Foot-slip: the stride
  implies translation the pinned figure never performs. **Ruled out first:** the 153/157 per-frame
  anchor variation is *correct* registration (the converter trims leading blanks and `+leading_trim`
  re-adds them — verified the shipped cels carry zero leading blank columns). The oracle's player
  **creeps forward during the scroll** (`$62` 0F→13 over ~10 poses, B0 trace) ≈ 1 byte-col per 2–3
  poses; modelled as `PLAYER_STEPS_PER_COL=3` drift applied to every part of the run frame.
  **Residue:** the rate is derived from a 10-pose sample — it is a one-constant change if the drift
  reads wrong against the scrolling scene.
- Re-measured after both: **still 0 overruns** (500 iterations), busiest phase unchanged at 74.9%.

### §5  Verdict-time evidence (§11)
25.1: `build.bat` → `tests/scripted/scene6_b2prime_driver.bin (7229 bytes)` · `=== BUILD COMPLETE ===`
(the driver is wired into the build alongside the Stage-A driver). Prod hash unchanged:
`88eba89b15cdf17c8d25e082d2d3e1f3cce57d38`.
25.2: `iterations=700  NO-WAIT (overrun) = 0  ->  PASS: 0 OVERRUNS` ·
`cadence = 59.94/11 = 5.45 steps/sec  cur52 0x30->0x1b  halted=True` ·
`run_idx: [0,1,2,3,4,5,6,7,8,9,2,3,4,5] ... tail [3,4,5,10]`
25.3: **pending Jay** — nothing visual is claimed here.

### §6  Reactive deviations
- **Cadence set to 11 VBL/step, not Stage A's 16.** §5 specifies the faithful coupled baseline
  (~5.5 steps/sec); 16 VBL gives 3.7/s. Reaching 11 required 7 chunks × 12 rows instead of 12 × 7.
  Strip chunks rose to 69–71.5% of a VBL — still under the window and still below the busiest phase.
- **`build.bat` wiring — resolved.** An interrupt mid-task read as a rejection of the edit, so I
  reverted it; Jay clarified he had thought I was stuck. The driver is now wired into `build.bat`
  and a full build passes with prod byte-identical.

### §7  Uncertainty flags
- ~~3-column step delta: NOT MEASURED~~ **RESOLVED — measured (see §4 AC9).** The phase trigger
  never fired because the step machine's idle phase (123 cyc) can share a MAME frame; re-anchoring
  the trigger to a **`cur52` change** (which *is* the step boundary) fixed it.
- **Colour parity NOT verified.** §3's blue/orange swap check needs a pixel comparison at the run
  figure's render column — that is Jay's visual gate (CLAUDE.md §3 forbids my interpreting pixels).
  **This is an open acceptance item, not a pass.**
- **Fills / reveal seam inherited unverified.** The right-edge behaviour comes from Stage A's
  snapshot edge-extend; I did not re-verify that it reveals rather than clips at the seam.
- **Guard column derived, not traced:** `$72=$0E` → x=118 → col 29 sub 2. Recon 1 gives the parked
  value; the port column is arithmetic from it, not an execution-confirmed port position.
- Per-phase attribution again uses the −1 shift validated by physical plausibility (present must be
  ~free). The 0-no-wait result does not depend on it.

### §8  Follow-up
1. **Jay's 25.3 gate** — the visual acceptance, including colour parity.
2. ~~Measure the 3-col delta~~ — done (§4 AC9): 1 col = 2.4%, 3 col = 3.7% of the 11-VBL step.
3. ~~Decide whether the B2' driver joins `build.bat`~~ — done; it is in the build.
4. Arch (follow-on) can take phase 10 — 29,736 cycles spare there.

### §9  User interaction during task
An interrupt during the `build.bat` + full-build command surfaced to me as a tool-use rejection, so
I reverted the edit and reported the driver as unwired. Jay clarified he had interrupted because he
thought I was stuck, not to veto the change. Wiring restored, full build run, prod byte-identical.
**Note for future dispatches:** an interrupt and a rejection are indistinguishable from my side —
if a call is stopped, saying which it was avoids a needless revert.

### §10 Candidate(s) captured this task
`a-cadence-change-should-be-a-constant-swap-prove-it-by-doing-one` — §5 required named constants to
preserve a deferred toggle. The proof that the abstraction is real is not that the constants exist
but that a live requirement was satisfied *through* them: 16→11 VBL/step was a three-constant edit
with zero scroll-logic change. An abstraction claimed but never exercised is a hypothesis. Pool row
pending.

### §11 Commit
<hash — stated inline>. Prod `88eba89b15cdf17c8d25e082d2d3e1f3cce57d38` untouched.
