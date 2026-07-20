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
  **only 826–827 bytes actually change per step**, inside a bounding box of rows 100–199 ×
  cols 0–79. Stage A rewrites **6,480 B** to achieve **827 B** of real change — an **~8× overdraw**.
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

| step | `cur52` | **changed bytes** | bbox rows | bbox cols | bbox area |
|---|---|---:|---|---|---:|
| 1–8 | `$2D`→`$26` | **826–827** (stable) | 100–199 (100 rows) | 0–79 (80 B = 320 px) | 8,000 B |

**Read carefully — the bbox and the working set are very different numbers.** The bounding box
spans the whole lower screen, but only **~827 bytes inside it actually differ** (10.3% of the bbox,
**12.8%** of the 6,480 B Stage A rewrites). Stage A pays an **~8× overdraw** for implementation
simplicity.

**Versus Jay's estimate (~40 rows × ~240 px = ~2,400 B):** the bbox is *taller and wider* than
estimated (100 rows × 320 px), but the **true working set is ~3× SMALLER** than the estimate at
**827 B**. Both halves of that matter: a delta-only redraw is cheaper than Jay expected, while any
scheme that redraws the *bounding box* is 10× more expensive than it needs to be.

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
| *if B2' redraws only the measured 827 B delta* | *≈37,000* | *≈11%* | *≈8%* |

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
- The 827 B delta is measured for Stage A's **1-column** step. B0 shows the oracle advancing **1–3
  columns** per pose; a 3-col step changes more bytes (bounded by the same bbox). Cost is per byte,
  so it scales with the delta, not with the column count — but it was not separately measured.
- `stageb2_dirtyregion.lua` diffs the **displayed** page; with double buffering the two pages
  alternate, so a step's diff is against the same-parity page two steps prior in buffer terms. The
  stable 826–827 across 8 consecutive steps indicates this is not distorting the figure.

### §9  Follow-up candidates
1. **B2' proceeds** on the amortized architecture. Budget is not the constraint; **phase scheduling**
   is (keep actors off the present/flip frame).
2. **The 8× overdraw is the optimization headroom** — a delta-only redraw (827 B vs 6,480 B) would
   cut scroll cost ~5×, buying the 16→11 cadence squeeze outright. Worth doing only if the squeeze
   proves tight; Stage A already fits at 11 VBL (56.8%) without it.
3. **Measure the arch once ported** — the only unmeasured item.
4. **Standing acceptance gate:** `stageb2_stepcost.lua` — any frame's `work` ≥ 29,859 is an overrun.

### §10 User interaction during task
Jay supplied the correct dispatch mid-run (after an initial paste of the review verdict), and
earlier falsified the NO-GO on two independent grounds (a 1 MHz Apple IIe runs this scene; the
figure describes a routine the sandbox never runs per-frame). Both were correct and both are the
reason this re-measurement exists.

### §11 Candidate(s) captured this task
`a-measurement-that-contradicts-a-working-system-in-the-same-repo-is-measuring-the-wrong-thing` —
the voided gate reported "the scroll cannot fit" while its own M1 table showed the scroll running on
budget three paragraphs above. Two artifacts in one report contradicted each other and the
contradiction was never reconciled. **The check is cheap and mechanical: before reporting an
infeasibility, look for a working instance of the thing you just declared impossible** — in the same
repo, in the reference implementation, or in the artifact you already measured. Here all three
existed (Stage A on budget; a 1 MHz Apple IIe doing the scene; M1). Pool row pending.

### §12 Commit
<hash — stated inline>. Measurement only; prod `88eba89b15cdf17c8d25e082d2d3e1f3cce57d38` untouched.
