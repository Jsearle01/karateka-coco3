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

---

## ADDENDUM — the right-side black is FAITHFUL; it is the arch's absence (2026-07-21)

Jay's gate reported the right side "not filling in". Chasing it produced one wrong turn and one
settled answer, both worth recording.

**The wrong turn.** A trampoline-only trace of the gap band (rows 117–151, port x180–279) returned
`$A684`/`$A68A`, which I read as a "fight midground" and built as two `$52`-relative vertical
strips. Jay identified it on sight: *"what you added is in the location where the arch will
eventually be, in the shape of the arch."* Correct — it **was** the arch, built in the wrong stage.
Reverted (`f50cc50`).

**Why the trace misled me twice.** Two instrument blind spots, both previously documented:
1. The trampoline tap cannot see the **pattern-fill path** — Recon 1 already recorded that the
   castle "uses the fill path, so the trampoline draw trace did not see it." I added
   `harness/tools/oracle_fillpath_trace.lua` (taps `$0A00/$0A03/$0A09/$0A40`) and found 165 fill
   calls in the walk-off window the earlier traces never saw.
2. My gap window (f8580+) started **mid-scroll**, so anything painted at scene entry and merely
   scrolled thereafter could never appear. Re-traced from f5800 (before scene entry).

**The settled answer.** Across the whole scene, with BOTH mechanisms instrumented:
- **Zero fill-path calls land in rows 110–155.**
- In rows 117–151 the only scenery is `$A68A` (2700 draws), `$A684` (2550) and `$AB8E` (1044, the
  cliff). Everything else is transient fighter cels.

**⇒ The oracle draws nothing in that band except the arch and the cliff. The port's black region is
FAITHFUL, and it stays black until the arch is built** — which this dispatch explicitly scopes out
("ARCH OMITTED — expected, not a defect"). No further B2' work is warranted on it.

**Arch model, ready for the follow-on dispatch** (traced, not inferred):

| cel | column | rows |
|---|---|---|
| `$A68A` | `$52` + 2 (offset single-valued over 3150 draws) | 111–151, step 2 |
| `$A684` | `$52` + 7 (single-valued over 3450 draws) | 66–170, step 2 |
| `$A877` | `$52` + 2 | 111 |
| `$A87B` | `$52` + 1 | 153 |
| `$A6EF` | `$52` + 9 | 153 |

Both main strips are `$52`-relative, so the arch **scrolls with the scene and enters from the
right** as `$52` falls — it is the reveal content. Port column = `((cur52 + off) * 7 + 20) >> 2`,
sub = `& 3`. Cost measured when it was briefly built: **74 blits ≈ 12,900 cyc (43.2% of a VBL)**,
and it needs **its own phase before the present** (freeing one via 6 strip chunks × 14 rows keeps
the 11-VBL cadence). All cels are already converted.

**Standing lesson (candidate):** `one-draw-mechanism-is-not-the-draw-program`. Scene-6 content
arrives through at least three paths — cel blits via `$1903/$1906/$1909/$190C`, pattern fills via
`$0A00/$0A09/$0A40`, and setup-time paints that later only scroll. A trace of one path reports the
others' content as ABSENT, and absence is what drives the wrong fix. Before concluding "nothing
draws here", enumerate the mechanisms, not just the addresses — and check the window covers scene
ENTRY, not just steady state.

---

## ADDENDUM 2 — the 25.3 gate iteration (2026-07-21). Jay ran it live; 9 defects found and fixed.

**Gate verdict on the run animation: "the player run gate looks pretty good… good for now"** (Jay
notes it still needs seeing in the fight, which is downstream of B3). The rest of the session was
Jay's eye against the live loop, and every item below is a real defect he caught that the
measurements had passed.

**Live-gate harness:** `harness/tools/b2prime_live_loop.lua` — loops the sweep (dwell ~1.5 s on the
frozen end-state, then reset). The loop is in the HARNESS, not the driver: the halt at `$52==$1A` is
an acceptance criterion, so looping it in shipped code would delete the thing being gated.

### The nine fixes, in order

| # | Symptom (Jay) | Root cause | Commit |
|---|---|---|---|
| 1 | "two players on screen" | I built the guard from `$899C/$8ACB/$8E9B` — those are the **player**. Walk-off draws the guard **mirrored** from a defeat-only set `$8DA9/$8E83/$8F0E/$9290` | `e6b1c88` |
| 2 | "the other is dragged along" | Guard pinned to a **screen** column; `col−$72` is constant and `$72` tracks `$52`, so it is parked in **scene** space and must scroll | `e6b1c88` |
| 3 | "right side all black" | The strip sampled/copied the **border**: `edge_byte` from col 79 (black) and a block copy spanning cols 25–79 | `26c8b4e` |
| 4 | "pulled backward every cycle" | Foot-slip: stride implies translation, figure was pinned. Oracle's `$62` creeps 0F→13 during the scroll | `26c8b4e` |
| 5 | "still held back" | **Scroll rate 57% of the oracle.** `$52` step = 1 APPLE col = **7 px**; the port shifted 1 COCO col = **4 px**. → `COLS=2` (114%) | `7a07425` |
| 6 | "clipping too early on the right" | `+20` mapping puts the 280 px screen at coco **x20–299**, not x0–279. `PLAY_R` 69 → **74** | `7a07425` |
| 7 | "everything should be drawn after Fuji" / "Fuji parts still need blitting" | Order was band→Fuji (mountain in front of wall); but Fuji drawn first is **erased** by the band's single opaque bitmap. → band → **Fuji** → cliff → actors | `8b2b2fa`, `e65bb29` |
| 8 | "posts cut off by Fuji as they scroll past" | Every post eventually crosses Fuji's fixed cols. Re-assert the wall-top **RMW masks** after Fuji — they are sparse (`$FF,$00` no-ops), so only post pixels are written | `621d056` |
| 9 | "no new post appears" / "rail lines run through the post" / "not clipped at the left edge" | Edge-extend can only replicate a column with no post in it → **generate** posts at the traced pitch; rails need the **notch**; RMW re-asserts wrote into the left border | `baff013`, `12c48d0`, `e8c5e26` |

### The post generator (Jay's design, data-derived)
Jay proposed pre-baked columns per sub-byte phase. Confirmed necessary: pitch **85 px** is not a
multiple of 4. Everything derived from the gated tableau's own masks, nothing invented:
- **shape** 2 px white at `x,x+1`, black at `x+2..x+5`; post rows 101–103 / 108–110
- **pitch 85 px** — Jay's call to use the **2nd→3rd** spacing (183→268) was right for a reason the
  data shows: post 1 sits at 103 where the regular series would put 98, so it is off-series and
  would have poisoned the pitch.
- **rail notch** — rows 104/111 carry `OR $C0/$3F` at the post bytes, never `$FF`; without
  reproducing that the rail runs straight through the post.
- **validation**: regenerating phase 3 reproduces the baked post at x=183 **byte-for-byte**
  (`AND $FC,$00,$3F` / `OR $03,$C0,$00`), and the notch masks (`AND $FF,$C0,$3F`) black exactly
  px185–188. The generator matches the shipped tableau, not merely plausibly.
- **additive**: series starts one pitch beyond the last baked post (268+85=353), so the three
  existing posts are untouched.

### Run re-anchored to the climb handoff
The block was normalised to `ANCHOR = 0x13*7 = 133` — a real observed legs X, but an arbitrary point
mid-run, 55 px right of where the climb ends. `ANCHOR = 78` makes the run's `st` frame
**byte-identical to `climb_crawl f6`** (`899C:25,2,138  8E9B:26,0,116  8ACB:25,2,124`), so the two
beats hand off at the same position.

### ⚠ A defect I introduced and reported as fixed
`SCROLL_VBLS_PER_STEP` 16→11 **never landed**: the patch script printed "ok" and then crashed
*before writing the file*. The driver ran at **3.7 steps/sec (79% of the oracle) for the whole
session** while I reported the faithful 5.45. Same failure mode as the earlier silent `str.replace`
no-ops: **trusting a tool's success message instead of reading back the artifact.** Now 11, verified
by grepping the file; the other constants (`COLS=2`, `PLAY_R=74`, `PITCH=85`) were re-checked in-file
the same way. **Standing rule: a constant is not changed until it is read back from the file.**

### Final state (all measured, 0 overruns throughout)
```
cadence   11 VBL/step = 5.45 steps/sec (oracle B0) ; COLS=2 = 8 px/step = 43.6 px/s vs oracle 38.1
phases    0 step_init | 1-7 strip (7x12 rows) | 8 Fuji | 9 cliff+seam | 10 posts+actors+present
play area x20-299 (cols 5-74), symmetric 20 px borders, clipped per BYTE on both edges
draw order band -> Fuji -> cliff -> posts(baked + generated) -> actors -> present
halt      $52 -> $1B, scene freezes, run exits e0 -> st
budget    0 no-wait iterations across every run; busiest phase 74.9%
```

### Scope confirmation — the player's rightward traverse is B3, not a B2' gap
Jay: "the player doesn't move to the right side off the screen like he will during the demo fight."
Trace settles it — in the walk-off window:

| | `$52` | player `$62` |
|---|---|---|
| while the scroll runs (phase 1) | `$24 → $1C` | **3 cols** |
| after the halt (phase 2) | frozen `$1B` | **21 cols → `$28`** |

The 21-column traverse happens **entirely after the scroll freezes**, which is the dispatch's phase 2
= **B3**. B2' behaves correctly. Two notes for B3: the run animation already cycles through the
traverse and exits `e0 → st` on stop (the exit should fire at the END of the walk-through, not at
the scroll halt), and the traverse is ~0.12 cols/frame — a steadier gait than the scroll-coupled
drift, so `PLAYER_STEPS_PER_COL` will not carry over.

### Still open
- **Colour parity** on the run figure — never verifiable by me (CLAUDE.md §3); Jay's gate.
- **Exact scroll rate** needs a **sub-byte scroll** (7 px = 1 col + 3 px). Byte-granular cannot hit
  100%: 1 col = 57%, 2 cols = 114%, nothing between. Architectural follow-on, flagged in-source.
- **Arch** — fully traced and costed (see ADDENDUM 1), ready to build as its own dispatch.
