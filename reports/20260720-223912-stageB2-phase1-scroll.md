## Form B Report — Stage B2: phase-1 scroll — **§0 BUDGET GATE: NO-GO (STOPPED, not built)**

### §1  Timing (C-35 — mandatory)
t0=2026-07-20T22:39:12.748676000Z
commit-time=<this commit, `git show -s --format=%cI HEAD`> — stated inline in the dispatch reply.
Elapsed: see inline. Predicted: **no empirical/legacy band supplied in the dispatch** (§8).
Classification: n/a (no band to classify against).

### §2  Summary
**The §0 VBL-budget gate FAILED, so I stopped before building the phase-1 path — as the dispatch
instructs ("If it BLOWS the window: STOP + report with the measured overage").** Measured on the
running port under MAME (execution, not estimation): **the per-frame draw-on-demand full-scene
re-blit that §2 specifies costs ~5 VBL on its own, against a 1 VBL budget.** With the run frame and
the `$52±xadj` sprites added, phase-1 as literally specified is **≈5.9 VBL/frame ≈ 590% of the
window — over by ~4.9 VBL (~145,000 cycles) every frame.** No code was written toward the phase-1
path; prod `88eba89b…` untouched and byte-identical.

The good news is bounded and useful: **the existing Stage-A amortized architecture already measures
ON budget** (16 phases in exactly 16 VBLs, zero overruns), and **cel blits are cheap** (≥12 in one
VBL, so a 3-part run frame ≈ 0.25 VBL). The budget killer is not sprites — **it is redrawing the
scene substrate every frame.** So phase 1 is achievable, but on the amortized architecture, not on
literal per-frame draw-on-demand. §4 gives the numbers and the one architectural change needed.

### §3  Files added (measurement instruments only — NO phase-1 build)
- `harness/tools/stageb2_budget.lua` — NEW; frame-loop overrun probe (taps `HAL_time_vbl_wait`
  entry + `main_loop+3`, logs per-phase frame deltas, `mg_phase`, `cur52`).
- `harness/tools/stageb2_initcost.lua` — NEW; per-routine VBL cost of one full-scene draw, plus
  blits-per-frame.
- `mame-idioms-coco3-port.md` — NEW §0 (how to measure port cost when MAME exposes no cycle
  counter; the DECB low-RAM tap-arming gotcha).
- `build/logs/stageb2_budget.txt`, `stageb2_initcost.txt`, `b2_probe.txt` — raw evidence
  (untracked; `build/` is gitignored).

### §4  The measurement (execution evidence)

**The budget unit.** VBL window = **29,859 cycles / 16.68 ms**.
**[VERIFIED 2026-07-20 by execution — see `reports/20260720-225328-verify-cpu-speed.md`.** The
double-speed premise below was, at the time of writing, a static read (a `$FFD9` write + a comment).
It has since been execution-confirmed: one frame was measured spending **29,736 cycles**, which the
0.89 MHz window (14,929) cannot hold, and a forced-slow control reproduced the normal-speed window.
**The budget and this gate's NO-GO verdict stand unchanged.]** Clock derived, not assumed: coco3
`maincpu` = **894,886 Hz** (`mame -listxml coco3`, `<chip type="cpu" tag="maincpu" …>`), **×2**
because `HAL_gfx_init` writes `$FFD9` (SAM 1.78 MHz double speed, `src/hal/coco3-dsk/gfx.s:198`),
÷ 59.94 Hz.

**Method (and why it is VBLs, not cycles).** MAME 0.281's Lua device wrapper exposes **neither
`cpu.clock` nor `cpu:total_cycles()`** (both `nil`, probed → `build/logs/b2_probe.txt`), and
`manager.machine.time` is **quantised to the scheduler timeslice** — an intra-frame time delta
around a routine reads as **4 cycles**, i.e. it reports heavy work as free. That false-cheap reading
was caught and discarded, not reported. `frame_number()` **is** exact, so cost is measured in **VBL
units** via read-taps on routine entry addresses (6809 read-taps fire on opcode fetch — coco3
idioms §10). Since 1 VBL *is* the whole budget, a cost in frame-deltas is already the verdict.

**M1 — the existing Stage-A amortized scroll: ON budget.** (`stageb2_budget.lua`, 140 samples,
`cur52` sweeping `$30→$27` = the real scroll running.)

| phase | n | VBLs consumed | overruns |
|---|---|---|---|
| 1–11 (strip chunks) | 8–9 each | **1** (min=med=max) | **0** |
| 12 Fuji redraw | 8 | 1 | 0 |
| 13 cliff re-blit | 8 | 1 | 0 |
| 14 present+flip | 8 | 0 (shares a frame) | 0 |
| 15 idle | 8 | 1 | 0 |

**Sum of medians over one 16-phase scroll step = 16 VBL = SA_HOLD.** The port keeps up exactly:
one phase per VBL, no dropped frames. (Phase 0's `max=32` is the **one-shot init**, isolated in M2 —
not a steady-state overrun.)

**M2 — cost of ONE full-scene draw (what §2's draw-on-demand asks for EVERY frame).**
(`stageb2_initcost.lua`, entry marks through the Stage-A init; frame numbers verbatim.)

| step | frames | VBL cost | ≈ cycles |
|---|---|---:|---:|
| HAL init (sys/time/gfx/palette) — one-shot, not per-frame | f300→f317 | 17 | — |
| `fill_sky` → `fill_walltop` | f317→f319 | **2** | 59,700 |
| `fill_walltop`+`draw_climb_scenery_back` → `draw_climb_striations` | f319→f320 | **1** | 29,900 |
| `draw_climb_striations` → `draw_climb_ground_right` | f320→f321 | **1** | 29,900 |
| `draw_climb_ground_right`+`draw_hud_player` → `snapshot_band` | f321→f322 | **1** | 29,900 |
| **FULL SCENE SUBSTRATE DRAW (sky+walltop+scenery+striations+ground+HUD)** | **f317→f322** | **5** | **≈149,000** |
| `snapshot_band` (6,480 B) | f322→f325 | 3 | 89,600 (≈13.8 cyc/B) |
| `copy_a_to_b` (16,000 B full page) | f325→f332 | 7 | 209,000 (≈13.1 cyc/B) |

The two independent copy measurements agree at **≈13 cycles/byte**, which is a sane 6809
copy-loop rate — a coherence check that the VBL-unit method is measuring real work.

**M3 — cel blits are CHEAP.** Blit counter across the init: **frame 322 executed 12 blits inside a
single VBL** (frames 321/325/326: 3/2/3). So ≥12 cel blits fit one frame ⇒
**a 3-part run frame ≈ 0.25 VBL**, and ~8 `$52±xadj` scene sprites ≈ 0.6 VBL. **Sprites are not the
problem.**

**M4 — phase-1 as literally specified.**

| per-frame item (dispatch §1–§3) | measured VBL |
|---|---:|
| full-scene draw-on-demand re-blit (M2) | 5.0 |
| run-frame blit, 3 parts (M3) | 0.25 |
| `$52±xadj` scene sprites (M3) | ~0.6 |
| scroll step bookkeeping | ~0.05 |
| **TOTAL** | **≈5.9 VBL** |
| **available** | **1.0 VBL** |
| **OVERAGE** | **≈4.9 VBL ≈ 145,000 cycles/frame (≈590% of budget)** |

**⇒ NO-GO.** Building it would ship a path that cannot hit frame rate — precisely what §0/§6 forbid.

### §5  Verification (AC-by-AC — §0 only; §1–§4 ACs not attempted by design)
- **§0 AC "measure phase-1 per-frame workload in actual cycles vs the VBL window" — DONE.** M1–M4;
  clock derived from `-listxml` + the `$FFD9` write; budget 29,859 cyc/VBL.
- **§0 AC "if it fits, proceed; confirm bulk copies amortized" — N/A: it does not fit.** Recorded
  for the successor: Stage-A's bulk copies **are** already amortized and measured on budget (M1).
- **§0 AC "if it blows the window, STOP + report the measured overage" — DONE.** Overage ≈4.9
  VBL/frame; **stopped; no phase-1 code written.**
- §1–§4 ACs (scroll mechanic, redraw, run animation, Jay's visual gate) — **not attempted**, gated.
- **Prod byte-identical** — no build performed; `88eba89b15cdf17c8d25e082d2d3e1f3cce57d38` on disk
  unchanged, working tree carries only the two new Lua instruments + the idioms edit.

### §6  Verdict-time evidence (§11)
25.1: **no build run** — this task added no assembly and changed no source the build reads
(instruments are Lua under `harness/tools/`). Prod hash on disk unchanged:
`88eba89b15cdf17c8d25e082d2d3e1f3cce57d38`.
25.2: raw measurement output (verbatim, `build/logs/stageb2_initcost.txt`):
```
# armed at f=300 (bin loaded, PC=0200)
test_start               f=300
fill_sky                 f=317
fill_walltop             f=319
draw_climb_scenery_back  f=319
draw_climb_striations    f=320
draw_climb_ground_right  f=321
draw_hud_player          f=321
snapshot_band            f=322
copy_a_to_b              f=325
draw_cliff_cels          f=325
draw_fuji_cels           f=325
HAL_gfx_present          f=332
main_loop                f=332
frame 321: +3 blits   frame 322: +12 blits   frame 325: +2 blits   frame 326: +3 blits
```
25.3 operator-runtime-smoke: **N/A this task** — the gate failed before there was anything to
gate visually. No visual claim is made.

### §7  Reactive deviations
- **Stopped at §0 and did not build phase 1.** This is the dispatch's own instruction on a failed
  gate, so it is compliance, not deviation — recorded here because the deliverable differs from the
  dispatch title.
- Cost is reported in **VBL units** rather than raw cycles because MAME exposes no Lua cycle
  counter (§4). Cycles are given as VBL×29,859. The conversion is stated so it can be checked.

### §8  Uncertainty flags
- **`plan_stage-b.md` NOT FOUND** — third dispatch running (also `plan_recon1-scroll-stop.md`,
  `plan_stage-b.md` at B0). Worked from the dispatch text. **The plan-file reference is broken and
  worth re-establishing**, since §4/§3 cite plan sections I cannot read.
- **The 5-VBL scene-draw figure is the Stage-A tableau**, which is the closest existing analogue to
  the phase-1 scene but **not identical** to it (phase 1 adds fills out to col `$2B` and the arch).
  The true phase-1 figure would be **≥** this, so the NO-GO direction is safe; the exact overage
  would shift.
- **Frame-granularity floor:** costs below ~1 VBL are bounded, not resolved (e.g. `fill_walltop`
  and `draw_hud_player` land inside another routine's frame). Fine for a go/no-go; too coarse for
  micro-tuning.
- **Blits/frame (12) was measured under init conditions**, where other work shares the frame — so
  ≥12 is a **lower bound** on blit throughput, which is the conservative direction for M3/M4.
- The dispatch's §3 **colour-parity** check and §2 arch/fill behaviour were **not reached**.

### §9  Follow-up candidates — what the successor dispatch needs to decide
1. **Architecture: keep the amortized strip-scroll (measured on budget), not per-frame
   draw-on-demand.** Draw-on-demand is faithful to the *oracle's* mechanism, but the oracle is a
   1 MHz 6502 pushing a 7-px-per-byte HGR buffer; the port's 4-px-per-byte 320×200 substrate costs
   ~13 cyc/byte to touch and cannot be fully repainted at 60 Hz. **This is a
   `port-the-visual-not-the-mechanism` case** — reproduce what the scroll LOOKS like, not the
   per-frame repaint that produces it.
2. **The cadence squeeze (the real design question).** B0 measured the oracle at **~11 VBL per run
   pose with `$62` advancing 1–3 cols**; Stage A amortizes over **16** frames per **1** col. So the
   port must compress the window 16→~11 *and* handle up to 3 cols/step. Cost is **per byte, not per
   column**, so a 3-col shift costs the same as 1 — the squeeze is the 16→11 window, needing ~9–10
   rows/chunk instead of 7 (~800 B/frame ≈ 35% of a VBL by the 13 cyc/B rate). **Plausible, but it
   must be measured after the change, not assumed.**
3. **Budget headroom for the run animation is confirmed** (0.25 VBL) — it can ride the existing
   phases.
4. Re-run `stageb2_budget.lua` against the phase-1 build as the acceptance check: **1 frame-delta
   per loop iteration = on budget**; that is now a cheap standing gate.

### §10 User interaction during task
None during this task.

### §11 Candidate(s) captured this task
`measure-cost-in-vbls-when-the-emulator-exposes-no-cycle-counter` — recorded as coco3 idioms §0;
**pool row not yet pushed** (flagged, will be captured on the next pool write): when the emulator
exposes no cycle counter and its clock is timeslice-quantised, do not report the quantised number
(it reads as "the work is free" — a false-cheap that would have passed this gate); measure in units
of the budget itself (VBLs via exact frame counts), where the measurement IS the verdict.

### §12 Commit
<hash — stated inline>. **No phase-1 code; instruments + idioms only.**
