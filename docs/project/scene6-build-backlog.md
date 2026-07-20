# Scene-6 build backlog / tracked to-dos

The single durable in-repo home for tracked scene-6 (fight-arc) work. Items are
tracked, not scheduled — they surface into dispatches when their turn comes.
Authored content (Orchestrator-owned per §2D); Clyde commits. Status tags:
IN-FLIGHT / NEXT / OPEN (investigation) / FOLLOW-UP / PARALLEL / BLOCKED /
STANDING / CLOSED.

---

## IN-FLIGHT
- **(none — §2F migration complete; see CLOSED)**

## NEXT — build steps (fight-order)
- **Recon 1 — scene-6 scroll-stop + bounded-scene measurement** *(Stage-B
  prerequisite; the next actionable step)*. The earlier "right-edge source-feed"
  framing was WRONG (no off-screen buffer). Jay's ground truth: scene 6 is a
  **bounded scene** — `$52` sweeps to a **fixed stop**, then (in the demo) hits a
  transition point and **`jmp`s back to restart the intro loop** (real progression
  is NOT resident in the demo — see Recon 2). The black right edge = Stage A swept
  the band but didn't (a) draw the **`$52`-relative sprites** into the exposed
  columns or (b) **extend the fills** rightward. Deliverables:
  1. **Scroll-stop condition** — the position/limit test that halts `$52` (Stage
     B's target; ends the sweep).
  2. **The bound value** — `$52`/position at stop = scene right extent (bounds the
     fills).
  3. **Archway + guard = `$52`-relative sprites** (the known `$52+xadj`
     scene-sprite group), final positions at the stop. **Scenery/actors, NOT the
     transition trigger** (later scenes transition with no sprite there → the
     trigger is player-position, not the arch). Archway cel is inventoried → the
     trace handle.
  4. **Fills** — wall/floor/wall-top extend-into-exposed-columns rule + right
     extent (fills continue as substrate throughout).
  5. **Confirm the demo loop-back** — end-of-scroll → transition point → `jmp`
     intro-restart. Marks exactly where Stage B's responsibility ENDS.
  Consistency check: stop-bound ≤ arch framed position ≤ transition point (Jay's
  remembered order: stop, then walk toward/through arch, then transition). Past
  scene 4 — trace is authority, `.s` a hypothesis, Jay's eye the gate. **Pure
  recon — no build.**
- **Stage B** — the player walk drives the **complete** scroll (walk control + run
  cels `$9B00–$9E92` + real-column parity fix + **the `$52`-relative sprite draw +
  fill extension** to the measured stop) + the **combined-budget pre-check**
  (scroll + player vs the tight VBL headroom). **BLOCKED on Recon 1.** Builds the
  scroll UP TO the stop/transition point; the transition itself is NOT Stage B's
  job (Recon 2 / disk-boot arc) — Stage B must not overrun into it.
- **Stage C** — the `$52 + xadj` fight scenery. **BLOCKED** (see BLOCKED).

## OPEN — investigations (recon before build)
- **Recon 2 — scene-progression mechanism (FOUNDATIONAL; NOT in the demo)** —
  *how the oracle progresses scenes: sequencing (scene table vs hardcoded),
  content (per-scene table vs hardcoded draw), placement (coordinate source).*
  **Jay's caution (load-bearing):** the progression mechanism is likely **NOT
  resident in the intro/demo fight** — it isn't needed there (the demo loops), so
  it's probably **wired in by the post-keypress disk load**. So the demo's
  loop-back (Recon 1 #5) is the *positive evidence* progression isn't resident —
  don't chase a ghost in the demo. Recon 2 = **trace keypress → disk load → what
  loads + how progression gets wired**. Folds into the **disk-boot arc**. Valid
  outcome: "not resident in demo; reachable only via that disk load — here's how
  to trace it." **This is the architecture-validation question** — does the
  oracle's scene organization match our `[registry]`/`[placement]` table-driven
  port model, or is our model a re-architecture? Affects scene 5, the guard,
  everything forward. Past scene 4 — execution-grounded, labels unreliable.
- **Concurrency-model read** — read-the-repo (scene 5 demonstrates it); goes
  **before the guard**; parallelizable. Confirms the model so the guard is built
  concurrent from the start.

## FOLLOW-UP — small, queued
- **Registry: pull UNPLACED cels** — the migration pulled *placed* cels only;
  add **registry rows** for converted-but-unplaced cels (run/walk `$9B00–$9E92`,
  any other converted frames) so the **graphics tool can load them**. Derivable
  (file + dims + `start_col`); placement rows arrive when placed. Registry-only,
  quick. (Raised after the finish-migration dispatch was already in flight.)

## Sprite tool (hand-authoring editor)
- **M1–M3 DONE** (`1c5bfb5`/`b065049`, wip) — lossless `converted.s` round-trip
  (byte-identical, 170/170 cels), table-driven sub-byte assembly, aspect-correct
  render (4:5) + exact click↔pixel (0/720 mismaps), runnable Tkinter viewer.
- **M4/M5 + polish + (C) reload + (A) category selector — DONE** (through
  `9b8270f`, wip): painting (color + opacity), derive-and-verify (no default), save
  (cel byte-identical + sidecar + three-state + `.bak`), lint, **all three encodings
  (mixed/masked/stencil)**, active-swatch highlight + three-outcome save feedback +
  atomic save, **reload existing opacity on open** (refine, no overwrite), **category
  selector** (reach any character's cels; climb assembled, others standalone). Jay
  authored A3C5 (now **stencil** — fine per-pixel confirmed). **Tool is functional
  for shadow authoring.**
- **Tool follow-ons (flagged):** run/walk/guard **composition port** (oracle → 
  `[animation]`, for assembled frames; run = Stage-B precursor); **build-render wiring**
  (authored shadows shown in a running scene — in-game validation).
- **Opacity model — RESOLVED (no format change):** shadows use the EXISTING
  `HAL_gfx_blit_sprite_mixed` (region descriptor) / `_masked` (per-column
  pixel-level) — 2bpp preserved, opacity in a **sidecar** beside `converted.s`
  (atomic, absence-explicit). NOT the 4bpp f-refactor.
- **Three-state opacity (in `[registry]`):** `converted` (born, unreviewed,
  all-trans) → `none` (reviewed clean, no sidecar) or `authored` (opaque work,
  sidecar). Set by saving, never hand-managed. Lint: `authored` ⟺ valid sidecar
  (hard error else). **"Needs opacity review" = the `converted` set**
  (self-maintaining; no separate list).
- **`opaque-black-f-refactor-plan.md` → mark SUPERSEDED** (mixed/masked blits made
  it moot; one-line note, don't delete). Orchestrator supplies the text (§2D).

## Climb / content
- **Climb sprite shadows** — hand-authored (Jay), by eye; opaque-black vs trans
  per-pixel **within a cel** via `masked`/`mixed` (the tool's proving use). Each
  cel has some shadow(s); ≥1 cel has two different shadows in one cel. **Tracked
  as `converted` cels needing review** (the self-maintaining set).
- **Climb animation touch-ups** — broader polish set (enumerate when scheduled).
- **`AA23`/`AA31` cels** — RESOLVED: the old crawl `_a`/`_b` variants (their only
  non-stage-3 user) were deleted; `AA23`/`AA31` are now **stage-3-static only**,
  their placement in `[placement]`. No stale second use remains.

## PARALLEL — gated by nothing
- **Guard 3-part sprite registration fix** — per-frame X-offset, same converter
  issue as the princess. Independent of the walk build.

## BLOCKED — need a Jay ruling
- **Fight-cast conversion** — ~45/50 recurring fight cels unconverted (gates
  Stage C).
- **`content/scene6_assets/` folder-scheme** — open stage-0 STOP (gates Stage C).

## STANDING debt / integration
- **`wip` → `main` merge (scene-6 deliverable)** — all scene-6 work (Stage A, the
  climb crawl, the six-dispatch §2F migration, the sprite tool) lives on **`wip`
  (~14 commits ahead of `main`)**; the docs (§2F.1, CLAUDE.md, this backlog)
  landed on **`main`**. So `main` *describes* the scene-6 state but does not yet
  *contain* the code. **No prod risk** — prod `88eba89…` is byte-identical on both
  branches and scene 6 is sandbox — but at some point a `wip`→`main` merge brings
  the deliverable across. **Jay's call on timing** (when scene 6 is a deliverable);
  not a reflexive step. Tracked so the doc/code split on `main` isn't a surprise.
- **Methodology-pool credential rotation** — in the *other* repo
  (methodology-candidate-pool); flagged multiple times; not karateka-coco3.

## CLOSED (context, not action)
- **§2F single-home placement — FULLY RETIRED.** All scene-6 cel placement lives
  in `content/scene6/scene6_placement.txt` (`[registry]`/`[placement]` col,sub,row
  /`[animation]`/`[fuji]`); the build reads only the table; zero inline cel
  placement in any scene-6 driver (whole-tree grep). Retired across: climb
  (`2e32ede`), Stage-A + stage-3 + Fuji (`07b1434`), old-variant deletion, and the walltop climb_scn_tbl pointer migration
  (`80cf1ec`, both-form grep = zero). *Note: commit `07b1434`'s message said "debt fully retired"
  prematurely — the crawl `variant_a` inline placement remained until the variant
  deletion; the accurate retirement point is that cleanup commit.*
- **Orange-lines dirty-rect artifact** — CLEARED.
- **Wall-top representation** — RMW fills stay (VBL headroom); provenance in
  `walltop-fills-provenance.md`. §2F table treats it as fills/substrate.
- **Scroll mechanic** — `$52` is the global scene scroll (mid-ground `−offset`,
  scene-sprite `+xadj`, Fuji fixed); walk-scroll = the `$52` sweep, before the
  guard. *(Right-edge source-feed still OPEN — see OPEN.)*
- **Colour arc** — RGB palette selected/landed/default/gate; composite retained;
  artifacting = no-op; distribution tooling. Decision record authoritative.
- **Repo public** — README, all-rights-reserved, secret scan (292 commits clean),
  working-tree cleanup (tree spotless), §2F single-home invariant established
  + hardened (§2F.1).
