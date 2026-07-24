## Form B Report — Stage B2' — ARCH INTEGRATED INTO THE SCROLL (Jay visual-gate confirmed)

### §1  Timing (C-35 — mandatory)
t0=**unavailable** — this was a continuous interactive session (not a single §0-stamped dispatch),
so there is no machine-stamped receipt to quote verbatim. Per §5 I will not fabricate one.
commit-time=`2026-07-24T12:44:27-04:00` (`git show -s --format=%cI HEAD`, HEAD=`8eefcfa`).
Elapsed / Classification: **not computable** without t0 (flagged in §8).

### §2  Summary
Integrated the verified 17-cel arch composite into the live scrolling driver
(`scene6_b2prime_driver.s`) so it renders in full scene context — scroll + run + guard +
wall-top posts + arch — and drove it through Jay's visual gate to convergence. The arch now
slides in solid and steady, holds at the halt, is pixel-precisely opaque, has a correctly-lengthed
front leg reaching its oracle extent plus authored base cels, a gap-filler between A6C0/A684, and
correct post-vs-leg occlusion. Prod ROM `88eba89b…` untouched throughout; 0 VBL overruns retained
at every step.

### §3  Files modified
- `tests/scripted/scene6_b2prime_driver.s` — arch draw routine, per-sub stencil dispatch, floor
  clip, MIX_SCRATCH fix→removal, post-phase reorder, +2 cel includes.
- `content/scene6/scene6_placement.txt` — arch frame: added A6C0, A6D4, archfill1; A684 tile end
  160→170; registry/opacity states.
- `harness/tools/gen_arch_opacity_scroll.py` (new) — per-sub pixel-precise stencils.
- `content/background/scene6_bg_archfill1/{converted,opacity}.s` (new) — synthetic gap filler.
- `tests/scripted/scene6_cliff_face.s` — floor top line orange→blue.
- `harness/tools/b2prime_live_loop.lua` — `LOOP=0` stop-at-halt default.
- Regenerated: `scene6_arch_gen.s`, `scene6_arch_opacity_scroll_gen.s`, `scene6_placement_gen.s`;
  folded Jay's cel/opacity edits (A6A6/A6C0/A6D4/A68A/A85F/A865/A877/A703…).

### §4  Reasoning (mechanism, not restatement)
- **Blink** was `draw_arch`'s `tfr b,a` destroying `runtime_x`'s high byte before the 16-bit ÷4;
  every home position ≥256, so at the halt columns collapsed below PLAY_L and the arch was skipped.
  Fix: `pshs a`/`puls a` around the sub extraction.
- **Player vanishing** was the mixed-blit scratch `MIX_SCRATCH=$3E00` landing inside the player
  run-leg cel data (this driver loads to $43DD). Relocated, then eliminated by dropping the mixed
  blit entirely.
- **Dirty opacity** (splotches/vertical lines) was the mixed blit being byte-granular with per-region
  sub-byte overflow. Replaced with the approved static path — plain transparent blit + byte-aligned
  opaque **stencil** — pre-generating all 4 sub-shifts per cel (sub is only 0–3) so it is
  pixel-precise at any scroll position.
- **Front leg too short / missing base**: the old `ARCH_FLOOR_CLIP=152` was a static-test artifact;
  raised to honor A684's oracle tile-end (170). Re-traced the oracle with the cel range widened to
  `$A0xx–$AFxx` (the original recon filtered `$A7–$A8` and missed the `$A6xx` feet) — found A6C0
  (col 60, row 165) and A6D4 (col 64, row 171), placed from the `$62=$0F` halt context matching our
  existing cels.
- **Post showing through leg** was a z-order bug: posts drew in phase 10 (after the arch in phase 8).
  Moved both post draws into the fuji phase (before the arch); safe because posts sit at rows 101+
  (below `restore_arch_sky`'s 30–99 wipe) and the cliff is at row 152.

### §5  Verification (AC-by-AC)
- Arch in full scroll context — rendered live; guest sweeps `$52 $30→$1B` and halts, PC sane (no crash).
- No blink — arch identical on both flip buffers at halt (675 px above-band each), monotonic slide-in.
- Player intact — isolated by pre/post-`draw_player_run` diff: 120–152 px every frame through
  arch-entry and halt.
- Clean opacity, correct leg length (bottoms row 171 to A6EF's black), gap filled (px 259–263
  punched black), post occluded by leg — all **Jay visual-gate confirmed** ("that looks correct now").
- Budget — 0 overruns / 250 iterations, busiest phase 81.2%.

### §6  Verdict-time evidence (§11)
25.1 fresh tool output: `lwasm … scene6_b2prime_driver.bin` assembles clean, load span
`$0100..$4F51` (clear of `$8000` framebuffers); `stageb2_phasecost.lua` → NO-WAIT=0, PASS 0 OVERRUNS (250).
25.2 bundled-artifact: prod `build/karateka.bin` sha1 `88eba89b15cd…` unchanged.
25.3 operator-runtime-smoke: **Jay MAME visual gate — OBSERVED and confirmed** ("that looks correct
now") for the arch composite, opacity, leg, base, gap, and post occlusion.

### §7  Reactive deviations
- Added a **synthetic** cel (`archfill1`) not derived from the oracle — the oracle leaves that 5px
  gap as background; opaque fill is Jay-specified. Labelled synthetic in-file.
- `b2prime_live_loop.lua` default changed to stop-at-halt (Jay request).

### §8  Uncertainty flags
- **C-35 timing not computable** — no §0 receipt stamp for this interactive session; t0 unavailable.
- **Buffer-coverage at halt**: a single post-arch sample showed the arch fully in buffer A and empty
  in B at that instant. No blink is visible at the gate, so the display is stable on the arch buffer
  — but if a flicker ever appears at the frozen halt, this is the place to look.
- Exact scroll rate still 2 cols/step (114% of oracle) — the sub-byte-smooth option remains deferred (B3).

### §9  Follow-up candidates
- Colour parity pass (Jay's RGB gate) once appearance is final.
- B3: player walk-off to the right + sub-byte scroll rate.
- Decision-record / post-mortem updates are the Orchestrator's to author (§2D) — findings above are
  the input.

### §10 User interaction during task
Iterative Jay visual gates: shapes/sprite-set correction, opacity authoring rounds, floor line
colour, front-leg length, oracle A6A6 position query, missing base cels, gap fill, post occlusion —
each rebuilt-and-shown, converged to "looks correct now."

### §11 Candidate(s) captured this task
**None filed yet.** Recommended captures (pending Orchestrator go-ahead):
1. "Widen the trace range and filter by POSITION, not cel-ID range" — the `$A6xx` feet (A6C0/A6D4)
   were missed for the whole prior recon by an `$A7–$A8` cel filter; position-filtering a wide sweep
   caught them.
2. "Harness state-address staleness reads as a code regression" — stale `A_*` live-loop addresses
   (after the binary grew) silently corrupted the scene and masqueraded as an unfixed visual bug.

### §12 Commit
`8eefcfa` (tip of the arch-integration series on `wip`; ~26 commits, prod ROM byte-identical).
