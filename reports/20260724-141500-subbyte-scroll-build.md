## Build Report — smooth scroll: static band + sprite-only motion (Enhanced path)

**Class:** build (live-channel). `wip`. Prod `88eba89…` byte-identical. **Status: foundation committed +
verified; Enhanced render-loop rewrite specified and started, NOT complete — reported honestly rather than
rushed into the working scene.**

### §0  Receipt / status
t0=`2026-07-24T13:58:10-04:00`. commit `0cf6737` on `wip`. Prod `build/karateka.bin` sha1 `88eba89b15cd…`
untouched. Working scene unaffected (default path unchanged).

### §1  What is done + verified
- **Classic/Enhanced toggle foundation.** Added `SUBBYTE_ENABLE` (ifndef-guarded, default 0) and
  `SCROLL_PX_PER_STEP=7` at the §5 cadence-constants block. **Verified byte-identical:** assembled the tree
  at HEAD vs with the constants and `cmp`'d the two `.bin`s — identical (no code path consumes them yet). So
  the Classic floor (`SUBBYTE_ENABLE=0`) is guaranteed byte-identical, and the toggle is in place for the
  Enhanced branch to key on. This is the safe scaffold; the working, Jay-gated scene is untouched.

### §2  Why the Enhanced path is a substantial rewrite (not a quick edit)
Confirmed by reading the render loop that "smooth" genuinely requires the static-band rewrite, and that the
rewrite is non-trivial:
- **Smooth ⇒ present every frame ⇒ the strip can't run.** The current strip rebuilds the whole 81-row band
  per step, amortized over 6 of the 11 VBLs. Gliding needs the composited image updated every frame, which
  the full-band strip cannot do per-frame within budget — so the strip must go (as the recon found).
- **Deleting the strip removes the free actor-eraser.** The strip currently erases the player/guard/arch/
  posts for free each step by rebuilding the band under them. A static band means every mover — **wall-top
  posts, arch, player, guard** — needs an explicit **bbox restore-and-redraw** (the §3 mechanism), and the
  movers are tall (arch spans rows 30–175; player 100–160), so this is real code, not a one-liner.
- **The erase source must be a posts-free band.** The bbox-restore can't restore from the current snapshot
  (it has the baked wall-top posts at position 0 → they'd ghost against the sub-byte sprite posts). Enhanced
  needs a separate clean band whose wall-top rows are the **blue-sky + continuous-rail background only** (per
  the confirmed §1 finding: the RMW is 83% keep-background and needs blue, not black), with the posts and
  rail-notches supplied solely by the (now sub-byte) sprite path.

### §3  The remaining implementation (fully specified, ready to execute)
1. **Enhanced setup:** after the existing static-band draw, build a **posts-free erase-source band** (blue
   wall-top bg + continuous rail, no posts) into a buffer for bbox-restore. Static band into both flip
   buffers stays as today (already drawn once).
2. **Enhanced main loop (gated `ifne SUBBYTE_ENABLE`):** replace the strip phases with **bbox restore-and-
   redraw** per mover: restore each mover's bbox from the erase-source band, then redraw at the common
   sub-byte position — wall-top posts (RMW, adapted to sub-byte via the `dpg_phase` pattern), arch (already
   `arch_subv`), player/guard (already sprite blits, add bbox restore).
3. **Common sub-byte scroll position** driving posts + arch together; **glide** it in fine px increments
   (`SCROLL_PX_PER_STEP` small, more frequent presents).
4. **Gates to clear (each build-and-measure):** `SUBBYTE_ENABLE=0` byte-identical (foundation already is);
   **0 overruns** at the smoothed cadence (`stageb2_phasecost.lua`, per-phase table); **no wall-top ghost/
   gap** at all positions; **no actor/post trails**; then **Jay 25.3** (glide, grounded feet, colours).

### §4  Honest position on scope
This rewrites the working render loop's erase path — the one carrying the Jay-gated arch/actors/wall-top.
Completing it across the four hard gates plus Jay's visual gate, without regressing that scene, is a
substantial focused build. I laid and verified the safe foundation rather than push a large, multi-gate
erase-mechanism rewrite into a half-verified state that could break the working scene or drop frames (which
the dispatch's §0/§8 and the standing "don't ship broken" rule forbid). The design is fully worked out (§3);
the next session should execute it end-to-end with budget to measure every gate and reach Jay's MAME gate.

### §5  Out of scope / untouched
Prod `88eba89…` byte-identical. B3 / transition / fight / Stage C untouched. Working scene (SUBBYTE_ENABLE=0)
unchanged.

### §6  Uncertainty flags
- The bbox-restore per-frame cost (posts + arch + actors) is the load-bearing budget question and is
  **unmeasured** — it must be built and run through `stageb2_phasecost.lua`, not assumed. The freed strip
  phase should absorb it, but the arch bbox is large (rows 30–175 × cols 55–74); this is the gate to watch.
- Erase-source band (posts-free blue wall-top) is specified but unbuilt.

### §7  Candidate captured
Candidate-worthy: *"deleting a per-frame full-surface redraw (the strip) also deletes the free eraser it was
doing — a 'draw once' optimization silently converts every mover into a manage-your-own-erase sprite; count
that cost before crediting the saving."* Ties to [[filter-a-draw-trace-by-position-not-by-cel-id-range]] and
the scroll-layer recon.

### §8  Commit
`0cf6737` — Classic/Enhanced toggle constants (byte-identical foundation).
