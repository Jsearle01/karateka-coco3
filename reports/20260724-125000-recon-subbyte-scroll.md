## Recon Report — Sub-byte (pixel-granular) band-limited horizontal scroll

**Class:** PURE RECON (inventory + feasibility + cost). NO build. `wip`. Prod `88eba89…` untouched.

### §0  Receipt / C-35
t0=`2026-07-24T12:48:08-04:00` (HEAD `0af894c` at dispatch; interactive session, no separate stamp).
commit-time=`<this commit>` (`git show -s --format=%cI HEAD`).
git status at start: clean tree on `wip`; only untracked `docs/ground-truth/*.pdf`, the two
`oracle_arch_*.lua` tools, and `nvram/`. Prod ROM `build/karateka.bin` sha1 `88eba89b15cd…`.

---

### §1  The two sub-questions — answered
| Sub-question | Answer | Evidence |
|---|---|---|
| **Sub-byte granularity?** (pixel vs byte) | **NO — byte-granular only** (both HW and current SW) | GIME `$FF9F` X6–X0 = "Horizontal **byte** offset"; current strip copies whole bytes |
| **Band-limited?** (rows 100–180 vs global) | HW: **NO — global**. SW: **YES** (already band-limited) | GIME `$FF9F` is a whole-row start offset; the SW strip already touches only rows 100–180 |

The GIME horizontal register can do neither of what's needed at once; the software band-copy is
already band-limited but byte-granular. Sub-byte therefore = **software-only, and a new capability.**

---

### §2  Determination 1 — HAL inventory (byte vs sub-byte)
- **No horizontal-scroll HAL primitive exists.** The only HAL "scroll" is `HAL_gfx_blit_scroll`
  (`src/hal/coco3-dsk/gfx.s:959`) — a **vertical** VOFFSET sliding-window for scene-4's crawl. No
  hscroll / band-copy / horizontal-shift routine in `src/hal` or `src/engine`.
- **The current world-scroll is BYTE-granular (4 px/unit).** `scroll_shift` is a byte-column delta
  (`scene6_b2prime_driver.s:343-345`, `shift = $30 - $52`), and `draw_posts_generated` must multiply it
  by 4 to get pixels (`:918-921`, `ldb #4 / mul ; D = shift in PIXELS`). `strip_one_row` copies whole
  bytes verbatim — `ldb ,x+ / stb ,y+` — with **no LSR/ROR sub-byte shift** (`:409-413`); the shift only
  changes the byte boundary `B = WALL_L - scroll_shift`, never the pixel phase within a byte. The driver
  header already flags this: "EXACT fidelity needs a SUB-BYTE scroll (7 px = 1 col + 3 px), which the
  raw-byte strip copy cannot express" (`:112-122`).
- **Sub-byte machinery exists — but only for SPRITE blits.** `HAL_gfx_blit_sprite` (`gfx.s:360-390`)
  runtime-shifts by 2-bit units, 4 phases (`blit_subbyte` 0..3), overflow OR-merged into the next byte.
  Per-source-byte cost: **subbyte 0 ≈ 10 cy, 1 ≈ 47, 2 ≈ 55, 3 ≈ 63** (`gfx.s:386-391`). It is **not**
  wired into the band strip-copy.

**Outcome: none exists; the sub-byte shifter is present (for sprites) and could be adapted — a new
band-scroll capability, not an extension of a horizontal HAL primitive that already does this.**

---

### §3  Determination 2 — GIME HSCROLL feasibility (read the reference, NOT inherited)
Read from the primary **GIME Reference Manual** (`docs/ground-truth/GIME_Reference_Manual.pdf`) and
cross-checked against `docs/ground-truth/SockmasterGime.md`:

- **`$FF9F` HOFFSET** — "Bit 7 HVEN … X6–X0 = **Horizontal byte offset into each display row**. When
  HVEN=1, the GIME treats each row as 128 bytes wide … X6–X0 selects which **byte position** begins the
  visible window." (Sockmaster: "256 bytes per row … Horizontal offset **address**.")
  → **Granularity: BYTE** (X6–X0 index whole bytes; no sub-byte/pixel field). **Scope: GLOBAL** (it sets
    the row start for the *entire* display; there is no per-band or per-scanline horizontal offset).
- **`$FF9C` VSCROL** — "Vertical **fine**-scroll offset within a character row (0–15)." This is the GIME's
  only *fine* scroll, and it is **vertical**. **There is no horizontal fine-scroll register.**

**Verdict — the "GIME hardware offset" story is refuted for this need.** `$FF9F` is a **global,
byte-granular** row-start offset. It fails **both** sub-questions: it cannot step sub-byte, and it
cannot be limited to the rows 100–180 band (it moves HUD and everything). Stage A's choice of a software
band-copy was correct and remains necessary. (A theoretical band-limit via an HSYNC/`HBORD` interrupt
rewriting `$FF9F` per-scanline is possible in principle but is *still byte-granular*, so it does not
unlock sub-byte and is not pursued.)

---

### §4  Determination 3 — software sub-byte cost
Two software mechanisms; the choice hinges entirely on **per-frame budget**, which is now tight (arch
put the busiest phase at **81.2%** of the 29,859-cycle VBL window).

**Option A — pre-shifted data (RECOMMENDED if built).**
Build, once at init, the scrolled block at all 4 pixel phases; each step pick phase = (target_px & 3)
and byte-copy from that phase at byte-offset = (target_px >> 2). **Per-frame cost is UNCHANGED** — still
the byte-granular `ldb ,x+ / stb ,y+` copy, just sourced from a phase-selected buffer.
- **Storage:** block = 45 B/row (+1 overflow) × 81 rows = **3,726 B/phase**. Phase 0 = the existing
  snapshot, so only **3 extra phases = 11,178 B**. Free window `$4F52..$7FFF` = **12,462 B** → **FITS**
  (~1.3 KB spare). (4 fresh phases = 14,904 B would *not* fit — must reuse the snapshot as phase 0.)
- **Per-frame cycles:** **~0 added** (same copy loop; +1 boundary-merge byte/row for the sub-byte seam).
- **One-time init:** build 3 shifted copies of the band (~3 × a shifted band pass) — negligible, off the
  per-frame budget.

**Option B — per-frame software shift (NOT recommended at the current budget).**
Apply the LSR/ROR sub-byte shift inside `strip_one_row` each frame. The scrolled block is 45 B/row × 81
rows = 3,645 B/step. A tight sub-byte copy adds ~15–20 cy/byte over the ~10 cy byte-aligned baseline →
**+55K–73K cy/step**, i.e. **+9K–12K cy per strip chunk** on top of the ~24,250 cy (81.2%) the strip
already costs → **~110–120% = OVERRUN.** It only fits if re-amortized over ~9–10 chunks/step instead of
6, which **slows the scroll ~1.5×** (more VBLs between visible updates) — the opposite of "smooth."

**Cost verdict: sub-byte scroll is affordable ONLY as pre-shifted data (Option A): ~11 KB storage, ≈0
per-frame cost. The per-frame-shift approach does not fit the post-arch budget.**

---

### §5  The coupling check — grounded vs sliding (the crux)
The player runs **near-stationary on screen** while the scene (including the **floor**, part of the same
scrolling band) moves past ($62 ≈ $10 while $52 sweeps). The run poses are **discrete** (~11 VBL/pose);
each pose bakes the planted foot at a **fixed screen-x**.

- **Today (byte-granular, coupled):** the floor is **static during the 11-frame pose hold**, then floor +
  pose jump together 8 px. The planted foot is static relative to the static floor → **grounded**, but
  **chunky** (the 8-px lurch Jay named).
- **If we smooth the world (sub-byte every frame) but keep discrete poses:** the floor now slides
  sub-pixel *under* the foot for all 11 frames while the pose holds the foot at a fixed screen-x → the
  foot **skates** across the moving floor, then snaps at the pose change. This is **more** visible than
  the coupled clunk, not less — exactly the "floaty/ungrounded" failure.

**Verdict: faithful discrete pose + smooth position + grounded feet cannot all hold at once.** Grounding
the foot on a smoothly-moving floor requires the foot's screen-x to advance sub-pixel with the floor
during stance — which the discrete pose does not provide. The only ways to restore it are (a) re-couple
position to the pose's foot-plant (= reintroduce the clunk in another form) or (b) invent sub-pose foot
interpolation not present in the oracle. **They fight.**

**Important nuance (directly on Jay's "world's motion, not the poses"):** the coupling constraint is
**only** on the layer the feet stand on (the floor). The **background** layers — arch, wall-top posts,
distant scenery, sky — have **no foot-coupling**; smoothing *those* sub-byte is pure win with no skate.
So "smooth the world's motion" is achievable for the big background slide **if** the floor-under-the-feet
is kept coupled/byte-granular while the background smooths. That means **two scroll granularities in one
band**, which the current single-band strip-copy does not separate — a real but un-scoped follow-up.

---

### §6  Deliverable summary + recommendation
- **Mechanism:** **software-only.** Hardware (`$FF9F`) is byte-granular AND global — ruled out for a
  band-limited sub-byte scroll. Sub-byte must be software; the affordable form is **pre-shifted data**.
- **Cost:** **~11 KB storage (fits the 12.5 KB free window, tight), ≈0 added per-frame cycles** via
  Option A. The per-frame-shift alternative (Option B) overruns the 81.2%-busy budget.
- **Coupling:** **they fight** — smoothing the floor under discrete-pose feet skates the foot; grounded
  feet need coupling (the clunk) or invented sub-pose data. Background-only smoothing avoids this.

**Recommendation (decision-free; for the Orchestrator to choose):**
1. **Smooth the BACKGROUND only, keep floor+player coupled.** Best matches Jay's "world's motion, not the
   poses" and keeps feet grounded. Cost: needs a follow-up to split the floor out of the smoothed band
   (two granularities) — feasibility not yet done. *Preferred direction if the split is affordable.*
2. **Smooth the whole band (incl. floor), accept minor foot-skate.** Cheapest (Option A pre-shift, ~11 KB,
   ≈0/frame), smoothest world, but the feet go slightly floaty — the exact risk Jay flagged.
3. **Keep byte-granular clunk.** Faithful (the oracle is itself ~7-px chunky on the Apple's 7px/byte),
   grounded, no new storage. B3 proceeds byte-granular; the Classic/Enhanced toggle stays deferred.

The **capability is feasible and affordable** (Option A); the **open design question is layering** —
whether the floor can be smoothed with the world without skating the feet, which decides between
recommendation 1 (background-only, needs a small follow-up feasibility on splitting the floor) and 2/3.

### §7  Out of scope / untouched
No build. B3 traverse, the transition, in-game fight, Stage C — untouched. Prod `88eba89…` byte-identical.

### §8  Uncertainty flags
- Option-B cycle figures are static estimates (no MAME cycle counter in 0.281; measured via VBL-delta
  historically). Direction (overrun) is robust; exact % would need a spike to confirm — out of scope for
  pure recon.
- Recommendation 1's "split the floor from the smoothed band" is asserted feasible-in-principle but **not
  cost-verified** — it is the natural next recon if the Orchestrator wants smooth-world-grounded-feet.

### §9  Candidate(s) captured
None this task (pure recon). Possible methodology note if useful later: "a hardware register that does
one of {fine-step, region-limit} but not both does not solve a need that requires both — check both axes
before crediting the register" (the `$FF9F` byte+global result).
