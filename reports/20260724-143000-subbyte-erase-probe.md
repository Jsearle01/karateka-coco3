## Probe Report — smooth-scroll erase-cost (does bbox restore-and-redraw fit?)

**Class:** minimal build + measurement (NO glide, NO visual gate). `wip`. Prod `88eba89…` byte-identical.
Everything lives behind `ifne SUBBYTE_ENABLE`; Classic (`=0`) verified byte-identical to HEAD.

### §0  Receipt / status
t0=`2026-07-24T14:31:52-04:00` (HEAD `930aa14`, `wip`). git status clean (pre-existing untracked only).
Prod `build/karateka.bin` sha1 `88eba89b15cd…` untouched.

### §1  What was built (minimal, gated)
Under `ifne SUBBYTE_ENABLE`: the strip phases (`ml_sc`) are replaced by **per-mover bbox restore-and-erase**
from `scroll_save` (the clean band — an identical-cost proxy for the posts-free source; posts-free is a
correctness concern for the full glide, not a cost one, per §4). One mover per phase (1–5) so the per-phase
table attributes cost per mover. Positions unchanged (byte-granular) — measuring erase+redraw **work**, not
motion. Copy is 16-bit (`ldd/std`); a naive 8-bit version was measured too (see §2 note). Build:
`lwasm --decb -D SUBBYTE_ENABLE=1`. Default build (no `-D`) = Classic, **cmp-verified byte-identical to HEAD**.

### §2  The measurement (per-phase, 16-bit restore, 300-iter sweep)
| phase | cyc | %VBL (29,859) |
|---|---|---|
| step_init | 242 | 0.8% |
| restore: wall-top | 1,747 | 5.9% |
| **restore: ARCH** | **10,518** | **35.2%** |
| restore: player | 5,723 | 19.2% |
| restore: guard | 15,635 | 52.4% *(see noise note)* |
| restore: cliff | 7,053 | 23.6% |
| fuji + posts (redraw) | 557 | 1.9% |
| **arch (redraw)** | **21,277** | **71.3%** |
| cliff (redraw) | 22,383 | 75.0% |
| actors + present | 21,655 | 72.5% |

- **0 OVERRUNS at the current cadence** (each phase in its own VBL; NO-WAIT frames = 0). Attribution-
  independent signal: the Enhanced mechanism runs within budget at today's once-per-11-VBL rate, same as
  Classic.
- **8-bit vs 16-bit note:** the first pass used a naive `lda/sta` copy — restore:ARCH = 29,187 (97.7%), the
  whole-band restores ~2× higher. Switching to `ldd/std` (16-bit; the bboxes are even-width) roughly halved
  every restore. The table above is the real 16-bit cost; the naive copy was over-measuring.
- **Noise note:** player and guard have identical bboxes (55×26) yet measured 19% vs 52%. That split is
  phasecost attribution skew (the known ml_next off-by-one); the **aggregate** and the **0-overrun signal**
  are reliable, the individual restore splits are indicative only.

### §3  The verdict (three outcomes — decision-free)
- **At the current cadence (once / 11 VBL): FITS — 0 overruns.** No regression from Classic.
- **Every-frame glide (all world movers redraw every frame): OVERRUNS ~2.9×.** World glide cost/frame
  (wall-top + arch + cliff restore + their redraws + present) = **85,190 cyc = 285% of a VBL.**
- **Moderate glide (~3-frame window, amortized): FITS (borderline).** 85,190 / 3 = **28,396 cyc/frame =
  95% VBL.** A ~2px-per-update, ~3-frame cadence ≈ the oracle's ~38 px/s and is **4× smoother than today's
  8px lurch**, and it holds under budget when the mover redraws are amortized across the window (exactly as
  Classic already amortizes the strip over 6 frames).

**The ARCH is the make-or-break, as predicted:** restore 10,518 (35%) + redraw 21,277 (71%) = **31,795
(106%)** — the arch alone exceeds one VBL, so it **cannot redraw every frame**; it must be amortized across
the glide window. This is the single line item that dictates the glide cadence. (The cliff redraw, 75%, is
the second-heaviest and behaves the same.)

### §4  Bottom line / recommendation input (decision is the Orchestrator's)
The erase cost **fits at today's cadence and fits a moderate ~3-frame amortized glide (95% VBL)**, but
**every-frame glide is out (285%)**. So the achievable Enhanced product is a **2px/~3-frame glide** — much
smoother than the 8px lurch, at ~oracle speed, holding 0 overruns — provided the mover redraws (arch above
all) are **amortized across the glide window**, not done whole every frame. This is the "same-ballpark →
greenlit for moderate glide" outcome, not "fits comfortably for free every-frame." If the goal is
per-frame-perfect smoothness, that overruns and needs a fallback (tighter arch bbox / partial-redraw / lower
present rate). If the goal is "same cost, visibly smoother" (Jay's stated win), the 3-frame amortized glide
delivers it.

### §5  Out of scope (probe)
No glide/sub-byte motion built; no Jay visual gate (positions unchanged — cost only). Classic untouched and
byte-identical. B3 / transition / fight — untouched. Prod `88eba89…` byte-identical.

### §6  Uncertainty flags
- Per-mover restore splits are attribution-noisy (player/guard); rely on the aggregate + 0-overrun signal.
- The 3-frame-amortized "95% fits" assumes the mover redraws distribute evenly across the window; the full
  build must confirm the actual amortized schedule holds 0 overruns (measure, don't assume) — but the
  headroom question is now bounded, not open.
- Erase source = `scroll_save` (has baked posts); the full glide needs the posts-free source for correctness
  — same cost, so this probe's numbers carry.

### §7  Candidate captured
Candidate-worthy: *"measure the primitive at its real width before verdicting — a naive 8-bit copy read 98%
where the 16-bit copy the real build would use reads 35%; the probe's own implementation shortcut can be the
thing that fails the budget, not the design."*

### §8  Commit
Probe apparatus committed (gated `ifne SUBBYTE_ENABLE`, Classic byte-identical). See §8 hash in the commit.
