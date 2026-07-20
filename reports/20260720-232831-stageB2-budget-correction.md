## Form B Report — Stage B2 §0 budget CORRECTION — **IT FITS. The NO-GO is void.**

### §1  Timing (C-35 — mandatory)
t0=2026-07-20T23:28:31.812272200Z
commit-time=<this commit, `git show -s --format=%cI HEAD`> — stated inline in the dispatch reply.
Elapsed: see inline. Predicted: no band supplied. Classification: n/a.
*(Measurement began slightly before this stamp, under the CORRECTION paragraph of the review; the
dispatch proper arrived mid-run and the two agree. Stamped on receipt of the dispatch.)*

### §2  Summary — **FITS with large margin; the prior NO-GO was wrong in both terms**
- **§1 mechanism:** Stage A's scroll is a **SOFTWARE band-copy (strip-scroll)**, **amortized over
  16 frames**, presented by a double-buffer page flip. **Not** a GIME hardware offset. Cited below.
- **§2 changing region — the headline.** Framebuffer diff of consecutive scroll steps:
  **only 192 bytes actually change per step**, in rows 100–180 × cols 12–72 (**244 px wide**).
  Stage A rewrites **6,480 B** to achieve **192 B** of real change — a **~34× overdraw**.
  *(First pass said 826 B over rows 100–199/cols 0–79. That was wrong: the GIME mode is
  **320×192** (`gfx.s:165-170`, `$FF99=$15`), so rows 192–199 are allocated but **never
  displayed** — pages A and B differ there in **634/640 bytes** because nothing ever paints or
  syncs them, and the page flip made that off-screen garbage read as per-step "change". Corrected
  by Jay's observation that the scroll spans x=19..279, which prompted the per-column histogram
  that exposed the uniform 8-rows-everywhere signature. See §5.)*
- **§3 honest budget.** Real per-step cost of the *running* scroll = **186,484 cycles = 6.25 VBL**.
  Adding every actor (player run + guard + arch estimate) = **≈205,700 cycles ≈ 6.9 VBL/step**:
  **63% of the oracle's 11-VBL step, 43% of Stage A's own 16-frame window. It FITS.**
- Worst single frame today = **20,073 cyc = 67.2%** of a VBL, i.e. **9,786 cycles spare** in the
  tightest frame, with **zero overruns** across 300 frames.

**The prior NO-GO's 5.9-VBL figure was the one-shot scene BUILD path compared against a 1-VBL frame
budget. Both terms were wrong.** Corrected: the real scroll work, against the real step interval.

### §3  Files added (measurement only — no engine change)
- `harness/tools/stageb2_stepcost.lua` — NEW; per-frame WORK cycles via the spin counter
  (`work = VBL − spins×7`), phase-tagged, blits counted.
- `harness/tools/stageb2_dirtyregion.lua` — NEW; per-step framebuffer diff → the true changing region.
- `build/logs/stageb2_stepcost.txt`, `stageb2_dirtyregion.txt` — raw evidence (untracked).

### §4  §1 — What Stage A's scroll ACTUALLY does (read from code, confirmed by execution)
**Mechanism: software band-copy from a snapshot, amortized; page flip for presentation only.**
- `step_init` (phase 0) — `dec cur52`, then `shift = $30 − $52` (0..21), sets `back_band` to the
  **non-displayed** page, resets `strip_row`. So the scroll offset is a *software* shift value.
- `strip_chunk` (phases 0–11) — copies **`SA_RPC = 7` rows × 80 bytes = 560 B per frame** from the
  pristine `scroll_save` snapshot into the back buffer, each row displaced left by `scroll_shift`.
  `SA_BAND_ROWS = 81` rows total ⇒ **6,480 B per step**, spread over 12 frames.
- phase 12 `draw_a9e2_behind` + `draw_fuji_upper` (Fuji fixed, redrawn on top);
  phase 13 `draw_cliff_cels` + `draw_ground_seam` + `clip_left_border` (the cliff sprite re-blitted
  at the scrolled column); phase 14 `HAL_gfx_present` + page-register toggle; phase 15 idle.
- **Amortization: N = `SA_HOLD` = 16 frames per 1-column step**, one phase per VBL.
- **No hardware scroll register is involved** — no `$FF9D/$FF9E` start-address or VSCROL write in
  the loop. The only display-register action is the buffer flip. *(This kills the inferred
  "GIME hardware offset" story explicitly: the shift is paid in CPU cycles, and §5 M1 prices it.)*

### §5  §2 — The measured changing region (not an estimate)
`stageb2_dirtyregion.lua` snapshots the **displayed** page (200×80, base chosen from
`page_register`) at the end of each step and diffs consecutive steps:

| step | `cur52` | **changed bytes (visible)** | bbox rows | bbox cols | in x19–279 / outside |
|---|---|---:|---|---|---|
| 1 | `$2D` | **192** | 100–180 (81) | 12–72 (61 B = **244 px**) | 154 / 38 |
| 2 | `$2C` | 192 | 100–180 | 11–71 (244 px) | 154 / 38 |
| 3 | `$2B` | 193 | 100–180 | 10–70 (244 px) | 155 / 38 |
| 4 | `$2A` | 192 | 100–180 | 9–69 (244 px) | **192 / 0** |

**The working set is 192 bytes per step** — 3.0% of the 6,480 B Stage A rewrites (**~34× overdraw**).

**⚠ The first pass of this measurement was 4.3× too high, and the error is instructive.** It
reported 826 B over rows 100–199. The GIME mode is **320×192**, so **rows 192–199 are allocated but
never displayed**; pages A and B differ there in **634 of 640 bytes** (confirmed by a direct A-vs-B
read) because nothing paints or syncs off-screen rows — and since the page flips each step, that
static garbage read as 634 bytes of per-step "change". **I had hard-coded 200 rows from the buffer
size rather than reading the mode the HAL sets.** The tell was in the data: a *uniform* 8 changed
bytes in **every** column including the borders — scroll content is never uniform across the full
width. Jay's "the scroll is x=19..279, not 0..319" is what prompted the per-column histogram that
exposed it.

**Versus Jay's x=19–279 (byte-cols 4–69):** essentially confirmed — the changing content is a
**244 px window** (61 byte-cols), narrower than the 260 px he stated, and it **moves left** with the
scroll. At the start of the sweep ~38 bytes sit at cols 70–72 (x 280–291), i.e. just *outside* the
right boundary; by step 4 they have scrolled in and the split is 192/0. **That is not slop — it is
where new content enters from the right edge**, so a B2' clip must treat the right boundary as the
reveal seam rather than a hard cutoff.

### §6  §3 — The itemized budget, every blitter priced
**Window = 29,859 cycles** (double-speed, execution-verified — `20260720-225328-verify-cpu-speed.md`).
Measured per-frame WORK (`work = VBL − spins×7`), medians over 300 frames:

| phase | what it does | work (cyc) | % of 1 VBL | rate |
|---|---|---:|---:|---|
| 0 | `step_init` + first chunk | 2,482 | 8.3% | |
| 1–11 | `strip_chunk`, 560 B shifted | 12,583–12,653 | **42.2%** | **22.5 cyc/B** |
| 12 | Fuji redraw, 342 B of cels | 7,256 | 24.3% | **21.2 cyc/B** |
| 13 | cliff + ground seam + left clip (4 blits, 399 B) | 18,155 | 60.8% | |
| 14+15 | `HAL_gfx_present` + flip (+1 blit) | 20,073 | **67.2%** ← worst | |
| **Σ** | **PER SCROLL STEP (16 phases)** | **186,484** | **6.25 VBL-equiv** | |

**Actors not yet in Stage A**, priced at the measured **21.2 cyc/byte** blit rate using real cel
dimensions from `scene6_placement_gen.s`:

| actor | cels | bytes | cycles | % of 1 VBL |
|---|---|---:|---:|---:|
| **Player run frame** (widest, `c1`) | `9B6B`+`8E9B`+`9D68` | 276 | 5,851 | 19.6% |
| **Guard** (3-part) | `899C`+`8E9B`+`8ACB` | 130 | 2,756 | 9.2% |
| **Arch** | **NOT PORTED — no cel in `content/`** | ~500 est. | ~10,600 est. | ~35% est. |

**Totals per scroll step:**

| | cycles | vs 11-VBL oracle step (328,449) | vs 16-VBL Stage-A window (477,744) |
|---|---:|---:|---:|
| Stage-A scroll as built | 186,484 | 56.8% | 39.0% |
| **+ player + guard + arch estimate** | **≈205,691** | **≈63%** | **≈43%** |
| *floor: if B2' moved only the measured 192 B delta* | *≈4,300* | *≈1.3%* | *≈0.9%* |

**The delta floor is ~4,300 cycles — 14% of a SINGLE VBL.** The entire scroll step's real pixel
change could be done in one frame with room to spare; Stage A currently spends **43× that** to
achieve it. So the amortization exists to make the *implementation* simple, not because the work is
large — which means the 16→11 cadence squeeze has enormous headroom and needs no cleverness.

**⇒ IT FITS**, on the architecture that already exists, with the actors included, and with roughly
a **third to a half** of the step budget unused. **No item fails.** The only item I cannot measure
is the arch, because it is not ported (below).

### §7  Reactive deviations
- Actor costs are **derived** (measured cel-blit rate × real cel byte counts), not measured in situ,
  because the player/guard/arch are not in the Stage-A sandbox. The *rate* is measured; the *bytes*
  are read from the generated registry. Stated so it can't be mistaken for an in-situ measurement.
- Per-step accounting is used as the primary unit (the oracle advances one pose/step per ~11 VBL).
  Per-frame figures are given alongside so both readings are available.

### §8  Uncertainty flags
- **The arch is NOT PORTED** — no castle/arch cel exists under `content/`. Its ~500 B / ~35% figure
  is an **estimate** from the oracle's traced geometry (pattern-fill at fixed cols `$1B/$1C`,
  Recon 1) scaled to CoCo bytes, **not** a measurement. It is the single largest unmeasured item;
  if it lands much bigger the step still fits, but it should be measured once ported.
- **Actors are costed once per step.** If B2' redraws them every frame instead, the player (19.6%)
  plus a 42.2% strip chunk is 61.8% of a frame — still fits — but the worst frame today (67.2%)
  has only 9,786 cycles spare, so **actors must not land on the present/flip frame**. Phase
  placement is a real constraint; it is scheduling, not a budget failure.
- The 192 B delta is measured for Stage A's **1-column** step. B0 shows the oracle advancing **1–3
  columns** per pose; a 3-col step changes more bytes (bounded by the same 244 px window). Cost is
  per byte, so it scales with the delta, not with the column count — but it was **not separately
  measured**, and it is the one number B2' should re-check before sizing a delta-only redraw.
- **The right boundary is a reveal seam, not a static edge.** ~38 bytes/step sit at cols 70–72
  (x 280–291) early in the sweep and scroll in by step 4. A clip at x=279 would clip the pixels the
  scroll is revealing.
- `stageb2_dirtyregion.lua` diffs the **displayed** page; with double buffering the two pages
  alternate, so a step's diff is against the same-parity page two steps prior in buffer terms. The
  stable 192–193 across 8 consecutive steps indicates this is not distorting the figure. **This same
  alternation is what turned the never-painted off-screen rows into a phantom 634 B/step** — see §5.
- **Measurement-method flag for anyone reusing these tools:** buffer geometry ≠ display geometry.
  `stageb2_dirtyregion.lua` now hard-codes 192 rows with the mode citation; if a future mode change
  alters `$FF99`, that constant must follow it.

### §9  Follow-up candidates
1. **B2' proceeds** on the amortized architecture. Budget is not the constraint; **phase scheduling**
   is (keep actors off the present/flip frame).
2. **The ~34× overdraw is the optimization headroom — but it is almost certainly not needed.**
   A delta-only redraw would cut the scroll step from 186,484 cycles to ~4,300 (14% of ONE VBL).
   Stage A **already fits** an 11-VBL step at 56.8% as built, so the squeeze needs no cleverness;
   the delta figure matters as the answer to "is there room for X?" — and the answer is yes for
   essentially any X. **Do not spend B2' effort optimizing a budget that is not binding.**
3. **Measure the arch once ported** — the only unmeasured item.
4. **Standing acceptance gate:** `stageb2_stepcost.lua` — any frame's `work` ≥ 29,859 is an overrun.

### §10 User interaction during task
Jay supplied the correct dispatch mid-run (after an initial paste of the review verdict), and
earlier falsified the NO-GO on two independent grounds (a 1 MHz Apple IIe runs this scene; the
figure describes a routine the sandbox never runs per-frame). Both were correct and both are the
reason this re-measurement exists.

### §10a Correction history of this report (so the Orchestrator can see what moved)
This report has been corrected once since first commit; the numbers below are current.

| | first commit `83a9b6d` | **current `b522255`+** | why it moved |
|---|---|---|---|
| changed bytes/step | 826–827 | **192** | 200-row diff counted **off-screen** rows 192–199 (mode is 320×192) |
| changing region | rows 100–199, cols 0–79 | **rows 100–180, cols 12–72 (244 px)** | same |
| overdraw vs Stage A | ~8× | **~34×** | same |
| delta floor | ~37,000 cyc | **~4,300 cyc (14% of 1 VBL)** | same |
| **verdict** | **FITS (63% of an 11-VBL step)** | **FITS — unchanged** | the correction only widened the margin |

**Nothing in §4 (mechanism), §6 (per-frame work, actor pricing) or the verdict changed** — those
were measured against the running loop and are unaffected by the display-height error, which touched
only the dirty-region figure.

### §11 Candidate(s) captured this task
`a-measurement-that-contradicts-a-working-system-in-the-same-repo-is-measuring-the-wrong-thing` —
the voided gate reported "the scroll cannot fit" while its own M1 table showed the scroll running on
budget three paragraphs above. Two artifacts in one report contradicted each other and the
contradiction was never reconciled. **The check is cheap and mechanical: before reporting an
infeasibility, look for a working instance of the thing you just declared impossible** — in the same
repo, in the reference implementation, or in the artifact you already measured. Here all three
existed (Stage A on budget; a 1 MHz Apple IIe doing the scene; M1). Pool row pending.

`buffer-geometry-is-not-display-geometry-read-the-mode-not-the-allocation` — the dirty-region
measurement diffed 200 rows because that is the **buffer** size; the **display** is 192 rows
(`$FF99=$15`), and the 8 never-displayed rows contributed **77% of the measured "change"** as pure
artifact. Generalizes to any framebuffer/texture/tensor measurement where the allocation is padded
beyond the live extent. **The self-check that would have caught it without an external prompt: the
per-column histogram showed a UNIFORM count in every column including the borders — a signature no
localized change can produce.** When a measurement has a suspiciously flat component, isolate it
before reporting the total. Pool row pending.

### §12 Commit
<hash — stated inline>. Measurement only; prod `88eba89b15cdf17c8d25e082d2d3e1f3cce57d38` untouched.
