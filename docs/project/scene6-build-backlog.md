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
- **Right-edge source-feed RECON** *(now a Stage-B prerequisite — see below)* —
  the next actionable step. Discover the oracle's mechanism for the incoming
  right side (off-screen buffer / draw-columns-on-demand / other). Past scene 4,
  trace is authority. **Shapes Stage B's scroll architecture** — must precede it.
- **Stage B** — the player walk drives the **complete** scroll (walk control +
  run cels `$9B00–$9E92` + real-column parity fix + **the right-edge source-feed
  integration**) + the **combined-budget pre-check** (scroll + player vs the tight
  VBL headroom). **BLOCKED on the right-edge recon** — the scroll and the
  source-feed are one mechanism, not two features; building the scroll before the
  recon risks the wrong architecture. The guard (next) enters on the right edge
  and needs the filled scene.
- **Stage C** — the `$52 + xadj` fight scenery. **BLOCKED** (see BLOCKED).

## OPEN — investigations (recon before build)
- **Concurrency-model read** — read-the-repo (scene 5 demonstrates it); goes
  **before the guard**; parallelizable. Confirms the model so the guard is built
  concurrent from the start.
- *(Right-edge source-feed recon promoted to NEXT — it's a Stage-B prerequisite.)*

## FOLLOW-UP — small, queued
- **Registry: pull UNPLACED cels** — the migration pulled *placed* cels only;
  add **registry rows** for converted-but-unplaced cels (run/walk `$9B00–$9E92`,
  any other converted frames) so the **graphics tool can load them**. Derivable
  (file + dims + `start_col`); placement rows arrive when placed. Registry-only,
  quick. (Raised after the finish-migration dispatch was already in flight.)

## Sprite tool (hand-authoring editor)
- **Tool plan update** — fold in the `[animation]` + **sub-byte** (`col,sub,row`)
  schema before the dispatch, so the tool assembles animated/climb frames at the
  right sub-pixel position (plan: `plan_sprite-authoring-tool.md`).
- **Tool build** (~3–4 days) — cels-only editor: table-driven live assembly, Old
  (read-only) vs New, 4-colour + trans (flat gray) palette, undo/redo, zoom/grid/
  coords, fixed dims (no silent registration change), save-to-`.s` with `.bak`,
  lossless round-trip as the first gate.

## Climb / content
- **Climb sprite shadows** — hand-authored (Jay), likely a **black
  transparent-vs-opaque** issue, sorted **by eye**; NOT a converter change. Each
  cel has some shadow(s); ≥1 cel has two different shadows in one cel. The
  tool's proving use.
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

## STANDING debt
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
