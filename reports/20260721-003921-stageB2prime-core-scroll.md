## Form B Report — Stage B2' core scroll — **§6 confirm-from-code INVERTS §4's HARD constraint (surfaced before building)**

### §1  Timing (C-35 — mandatory)
t0=2026-07-21T00:39:21.084567200Z
commit-time=<this commit, `git show -s --format=%cI HEAD`> — stated inline in the dispatch reply.
Elapsed: see inline. Predicted: no band supplied. Classification: n/a.

### §2  Summary — **STOPPED before the build: §4's hard rule points at the wrong phase**
§6 ordered the present cadence be confirmed from code before setting cadence constants. Doing that
first was decisive:

1. **`HAL_gfx_present` is a bare VOFFSET register write** (`$FF9D/$FF9E`, `gfx.s:334-352`) — a
   pointer swap. **No copy, no vsync wait. Measured at 186 cycles = 0.6% of a VBL.**
2. **My own per-phase table in `b522255` was mis-attributed by one phase** (`ml_next` does
   `inc mg_phase` at the *end* of each frame's work, so a frame-end read names the wrong phase).
   **The "present/flip frame at 67.2%" does not exist.**
3. **Corrected, the busiest phase is 13 (`cliff + ground seam + clip`) at 74.9%**, and phases 14
   (present) and 15 (idle) are the **emptiest** at 0.6% / 0.5%.

**Consequence: §4's "HARD: actors must NOT land on the present/flip frame" is inverted.** Measured:

| actors (player 5,851 + guard 2,756 = 8,607 cyc) placed on… | result |
|---|---|
| **phase 14 (present)** | 186 + 8,607 = **8,793 = 29.4% — FITS** |
| phase 15 (idle) | 137 + 8,607 = 8,744 = 29.3% — FITS |
| **phase 13 (cliff), the phase the dispatch implicitly frees up** | 22,376 + 8,607 = **30,983 = 103.8% — OVERRUNS** |

**Building to the dispatch's rule produces the one schedule that overruns.** Draw order agrees with
the measurement: actors must be drawn *after* the band/cliff and *before* the display swap, so the
present iteration is not merely the cheapest slot — it is the **only** correct one.

I stopped here and surfaced rather than build to a constraint I had just measured to be backwards.
The scroll driver itself is **not built** this task.

### §3  Files added (instruments only — no driver yet)
- `harness/tools/stageb2_phasecost.lua` — NEW; **per-iteration** phase cost + a direct overrun
  detector (`spins == 0` on a VBL wait ⇒ the previous phase consumed the whole frame).
- `harness/tools/stageb2_stepcost.lua` — phase now sampled at work-start (the off-by-one fix).
- `build/logs/stageb2_phasecost.txt` — 400 sampled iterations (evidence).

### §4  §6 confirmations (the dispatch's prerequisites)
**(a) Present cadence — CONFIRMED FROM CODE, and it is not what the phase table implied.**
`HAL_gfx_present` (`gfx.s:334-352`): reads `page_register`, selects `$F000`/`$F800`, `std $FF9D`.
That is the whole operation — **a VOFFSET write; the buffers are never copied and nothing waits.**
Cadence in the loop: `ml_flip` runs it once per `SA_HOLD` iteration, i.e. **one present per scroll
step**, and it costs **186 cycles**. Both the mechanism and the cost are now execution-confirmed, so
the cadence constants can be set on fact rather than on a phase-table reading.

**(b) 3-column step delta — NOT YET MEASURED.** Stage A steps 1 column; measuring a 3-column delta
requires the B2' driver (or a modified Stage A) to actually take 3-column steps. Deferred with the
build, flagged in §8 — it is a prerequisite for sizing a delta-only redraw, not for this schedule.

### §5  The corrected per-phase table (the §4 spine)
Per-**iteration** measurement, 400 iterations. `work = VBL − spins×7`; VBL = 29,859 (verified).

| phase | what runs | median cyc | % VBL | headroom |
|---|---|---:|---:|---:|
| 0 | `step_init` + strip chunk 0 | 12,744 | 42.7% | 17,115 |
| 1–10 | strip chunk (560 B shifted) | ~12,700 | 42.4–42.6% | ~17,150 |
| 11 | strip chunk (partial, 4 rows) | 7,340 | 24.6% | 22,519 |
| 12 | Fuji (`a9e2_behind` + `upper`) | 18,155 | 60.8% | 11,704 |
| **13** | **cliff + ground seam + left clip** | **22,376** | **74.9%** | **7,483 ← busiest** |
| 14 | **PRESENT (VOFFSET write)** | **186** | **0.6%** | 29,673 |
| 15 | idle | 137 | 0.5% | 29,722 |
| **Σ** | **per scroll step** | **187,797** | **6.29 VBL-equiv** | |

**ZERO OVERRUNS: 0 of 400 iterations hit the no-wait condition.** This is a direct signal, not
arithmetic — if a phase had consumed its whole frame, the next `HAL_time_vbl_wait` would have
returned without spinning.

**How the attribution was validated (it had already fooled me twice):** the raw labels put 22,376
cycles on "present" and 137 on a phase that runs `step_init` + a strip chunk. **Both are physically
impossible** — a register write cannot cost 75% of a frame, and a 560-byte shifted copy cannot cost
137 cycles. Exactly one alignment makes every row physically sensible, and it is the one above.
Physics, not the label, decided it.

### §6  Proposed phase schedule (for the build, pending Orchestrator ack of the inversion)
| phase | assignment | cycles | % VBL |
|---|---|---:|---:|
| 0–11 | strip chunks (unchanged) | ≤12,744 | ≤42.7% |
| 12 | Fuji (unchanged) | 18,155 | 60.8% |
| 13 | cliff + seam + clip (unchanged) | 22,376 | 74.9% |
| **14** | **draw player run frame → draw guard → PRESENT** | **8,793** | **29.4%** |
| 15 | idle (spare) | 137 | 0.5% |

Actors land on 14 because it is (a) after the band and cliff are built, (b) before the display swap,
and (c) 99% empty. Phase 15 remains a spare slot if the arch (follow-on) needs one.

### §7  Reactive deviations
- **Did not build the driver.** The dispatch's §4 hard constraint was measured to be inverted, and
  §9 says "phase scheduling is the real problem." Building to a rule that produces the only
  overrunning arrangement would have burned the task. Surfacing first is the smaller cost.
- §5's named cadence constants are therefore also not yet written — they depend on the schedule.

### §8  Uncertainty flags
- **The 3-column step delta is unmeasured** (§4b). Needed before sizing any delta-only redraw.
- **Actor costs (5,851 / 2,756) remain derived**, not in-situ: measured blit rate (21.2 cyc/B) ×
  real cel byte counts. In-situ measurement comes with the build.
- **The arch is out of scope here and still unported** — phase 15 is reserved but unpriced.
- **My phase attribution has now been wrong twice** (frame-end sampling in `b522255`; raw
  per-iteration labels here). The table above is the one validated against physical plausibility;
  treat any future phase-cost claim as suspect until it passes that check.
- Nothing visual was produced, so **25.3 is not applicable this task** (no appearance claim).

### §9  Follow-up — what the build needs, in order
1. **Orchestrator ack that actors go ON the present phase** (14), not off it.
2. Extend `gen_scene6_placement.py` to emit the `run:` block as `run_frames` (today it emits
   `climb_crawl` only) — the run animation has no asm representation yet.
3. Build the B2' driver on Stage A: run animation anchored to the scripted `$62`, guard parked,
   actors on phase 14, cadence in named constants (`SCROLL_VBLS_PER_STEP`, `SCROLL_COLS_PER_STEP`,
   `PRESENT_VBLS_PER_STEP`).
4. Re-run `stageb2_phasecost.lua` on the built driver: **0 no-wait iterations is the acceptance bar.**
5. Measure the 3-col delta on the built driver; then Jay's 25.3 gate.

### §10 User interaction during task
None during this task (the dispatch arrived complete).

### §11 Candidate(s) captured this task
`validate-cost-attribution-against-physical-plausibility-not-the-label` — a profiler's phase label is
an index into a state machine, and an off-by-one silently moves a cost from one component to another
while every total stays correct (my per-step sum was right in *both* wrong versions). The check that
catches it needs no better instrument: **ask whether each component's cost is physically possible for
what that component does.** A register write costing 75% of a frame, and a 560-byte copy costing 137
cycles, are both impossible; exactly one alignment removes both impossibilities. Generalizes to any
sampled profiling where samples are attributed by a mutable label (state machines, request phases,
job queues). Pool row pending.

### §12 Commit
<hash — stated inline>. Instruments + report; **no driver built**; prod
`88eba89b15cdf17c8d25e082d2d3e1f3cce57d38` untouched.
