## Build Report — smooth scroll via static band + sprite-only motion

**Class:** build (live-channel). `wip`. Prod `88eba89…` byte-identical. **Status: STOPPED at the §5
verification — the dispatch's core mechanism assumption ("leave the wall-top black") is empirically not
viable; surfacing the refined design before building on it.** No code changed.

### §0  Receipt / status
t0=`2026-07-24T13:58:10-04:00` (HEAD `400d143`, `wip`). git status: clean (only pre-existing untracked
PDFs / `oracle_arch_*.lua` / `nvram/`). Prod `build/karateka.bin` sha1 `88eba89b15cd…` untouched. No build.

### §1  What I verified FIRST (the dispatch's §5, done up front)
The dispatch's §1/§5 plan: draw the band once, **leave the wall-top region (rows 101–111) black**, let the
sprite RMW path (`draw_posts_over_fuji`) carry the wall-top. §5 flagged "verify no wall-top ghost/gap over
the black band." I verified this before writing band code, because everything downstream depends on it.

**It fails.** Two pieces of evidence:

1. **Empirical wall-top decomposition** (dumped the displayed wall-top at scroll shift=2 vs shift=8, diffed):
   the scrolling content sweeps **cols 20–68 across rows 101–104, 108–111** (the posts), over a **blue (`$AA`)
   sky background** between and around the posts. Rows 100/114/116 are static. So the wall-top is *posts
   moving over a blue-sky background* — not content over black.

2. **The RMW is background-dependent.** `draw_posts_over_fuji`/`draw_walltop_posts` do `dest = (dest AND mask)
   OR data`. In `wt_rmw` row 101, **41 of 49 byte-pairs (83%) are keep-background** (`mask=$FF, data=$00`).
   Over the blue sky those keep blue; **over a black band they render black.** So leaving the wall-top black
   would turn 83% of each wall-top row black instead of blue — a gross visual break, exactly the §5 ghost/gap.

**Conclusion:** the wall-top RMW **requires its blue-sky background**. "Leave the band black there" is not a
viable mechanism. This is a real correction to the dispatch's §1/§5, not a tuning detail.

### §2  The refined (viable) design — small correction, same win
The recon's core insight still holds fully: **70 of 81 band rows are scroll-invariant** (uniform black wall +
horizontally-uniform floor + striations) and can be drawn **once**. The only correction is how the wall-top
is handled:

- **Static band, drawn once into both buffers — INCLUDING the blue wall-top background** (the sky + static
  rail that the posts move over), not black. Rows 100, 112–180, striations, borders: truly static.
- **The wall-top posts are MOVING SPRITES over that static blue background** — so, exactly like the actors in
  §3, they need a **per-frame bbox restore-and-redraw**: restore the blue background under each post's
  footprint, then draw the post (RMW or opaque) at the sub-byte-scrolled position. This is the §3
  actor-eraser mechanism, extended to the wall-top posts (the dispatch treated the posts as free-standing
  sprites and missed that a mover over a static bg needs bbox-erase).
- **Delete the full 81-row strip.** Per-frame band work drops from ~6,480 B (whole band) to just the moving
  bboxes: post footprints + arch (already bbox-scoped) + actor footprints. That is the dispatch's saving —
  the strip is gone; only mover-bbox restores remain (which the arch/actors already need anyway).

So the strip IS deleted; what replaces it is not a residual band-copy but **bbox restores for the movers**
(§3's mechanism), which is the correct and minimal form. The 12 KB pre-shift, the tight budget, and the
foot-skate all still dissolve exactly as the recon said (static/uniform floor ⇒ grounded feet free).

Net change vs the dispatch: §1 "leave wall-top black" → **"bake the blue wall-top background static; posts
bbox-erase like the actors (§3)."** §8's "no residual per-step copy" is honored (no band strip); the posts
just join the actors as bbox-restored movers.

### §3  Why I stopped here (not building on the broken premise)
Building the static band with the wall-top black — then the sub-byte posts, then discovering 83% of the
wall-top is black — would be a large rewrite founded on a verified-wrong assumption, with the break only
visible at Jay's gate at the end. The dispatch's own §5 asked for this verification; it came back negative,
so per "don't proceed on assumption," I'm surfacing the corrected design before the rewrite rather than after.

### §4  Recommendation / next step
Proceed with the **refined design (§2)**: static band with the blue wall-top background baked, and the
wall-top posts folded into the §3 actor-eraser as bbox-restored movers, driven (with the arch and actors)
from one sub-byte scroll position; `SUBBYTE_ENABLE=0` = byte-granular (today) as the correctness/Classic
floor. This is a one-line correction to the dispatch's §1 and I can execute it directly. Flagged for
confirmation only because it changes the stated mechanism (black → blue-bg + bbox-erase); the saving,
storage (0 pre-shift), and grounded-feet dividend are unchanged.

### §5  Out of scope / untouched
No build performed. Prod `88eba89…` byte-identical. B3 / transition / fight / Stage C untouched.

### §6  Uncertainty flags
- The refined design's per-frame cost = mover bboxes (posts + arch + actors). Small, but **must be measured**
  in the build (0-overrun gate), not assumed — the actor/post bbox-restore is the one real new cost, as §3/§8
  already flagged.
- Sub-byte adaptation of the wall-top post draw (the `dpg_phase` pattern) is straightforward but unbuilt.

### §7  Candidate captured
Candidate-worthy: *"a read-modify-write sprite is not background-independent — verify what it keeps from the
substrate before assuming you can change that substrate (here: 83% keep-background ⇒ can't blank the band
under an RMW wall-top)."* Ties to the recon's layer-decomposition and to [[filter-a-draw-trace-by-position-not-by-cel-id-range]].
