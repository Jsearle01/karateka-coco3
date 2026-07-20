## Form B Report — Stage B0: run-composition port (oracle → `[animation] run:`)

### §1  Timing (C-35 — mandatory)
t0=2026-07-20T21:18:54.589249900Z
commit-time=2026-07-20T17:28:21-04:00  (= 2026-07-20T21:28:21Z, `git show -s --format=%cI` of `4cceb50`)
Elapsed: 9.5 min (arithmetic on the two machine-stamped artifacts above).
Predicted: **no empirical/legacy band was supplied in this dispatch** — flagged in §8; no band
table entry is claimed.
Classification: n/a (no predicted band to classify against).

### §2  Summary
Traced the oracle's RUN animation in the running attract and ported its per-frame composition the
`climb_crawl` way. The run plays **twice per attract cycle** (f6423–6630 approach run into the guard
fight; f8610–8947 — which is Recon 1's scene-6 "walk-off", execution-confirmed here to be a RUN).
**42 pose observations across those two independent windows give 10 `(legs,torso)` pairings, each
with a UNIQUE and invariant `(dx, dy, rowLegs, rowTorso)` — zero contradictions.** The result: the
16 run cels compose **11 frames** (2 start + an 8-frame cycle + 1 stop), **not** the "16-frame cycle"
`conventions.md §12.3` asserts — 16 is a CEL count. The frame **anchor was read off the trace, not
chosen**: legs `$05` == `$62` (player position) in every steady-state pose ⇒ legs `xadj`=0 ⇒ the
frame origin IS the player X and the torso sits at a measured `+dx`. Ported as a `run:` block in the
`[animation]` section with sub-byte carried per part; the sprite tool now assembles all 11 frames.
Pure data port — no engine build, prod `88eba89b…` byte-identical (re-verified after `build.bat`).

### §3  Files modified
- `content/scene6/scene6_placement.txt` — +16 `[registry]` rows (8 run legs + 8 run torsos) and the
  new `[animation] run:` block (11 frames × 2 parts, `col,sub,row` each). *(Also carries a
  pre-existing uncommitted working-tree change from before this task: the `authored` flags on
  `A3C5`/`A3E9`. Committed with it since it is the same file; not authored by this task — §7.)*
- `docs/project/run-composition-map.md` — NEW; the analogue of `climb-beat-composition-map.md`.
- `harness/tools/stageb0_run_capture.lua` — NEW; the blit-trampoline run-bank capture instrument.
- `harness/tools/gen_stageb0_run.py` — NEW; CoCo3 registration for the run frames, reusing the exact
  `gen_climb_anim` formula (`x = col*7 + sub + 20`; `col=(x>>2)+leading_trim`, `sub=x&3`).
- `mame-idioms-apple2e-oracle.md` — NEW §12a (log the actor-position var beside each draw so a
  moving animation's anchor is readable; log `$10` or sub-byte-only steps collapse).
- `tests/scripted/scene6_placement_gen.s` — regenerated: +16 `reg_*` `fcb w,h,start_col` rows
  (codegen output, additive data only).
- `build/logs/stageb0_run_attract.txt` — raw trace evidence (untracked; `build/` is gitignored).

### §4  Reasoning (the dispatch-named questions)
**Which leg + which torso per frame, and their offsets — by execution.** Read-taps on the four blit
trampolines `$1903/$1906/$1909/$190C` (these fire on 6502 — idioms §7b, JMP-trampoline entries, not
a §1 routine-body false-0), logging cel `$04:$03`, col `$05`, **sub-byte `$10`**, row `$06`, flip
`$0F`, and `$52/$62/$72` per draw, filtered to the run bank so a 200-emulated-second whole-cycle run
stays readable. Legs and torso are drawn **consecutively, legs first**, so pairing is direct from the
trace order; offsets are computed in apple-px (`x = col*7 + sub`) and are identical on every
recurrence of a pairing in **both** windows.

**Why the anchor is derived, not assumed.** The climb is a fixed scene position, so its absolute
`col,sub,row` port verbatim; the run translates, so "relative to what?" had to be answered. Logging
`$62` beside each draw answered it empirically — in the free-running walk-off stretch legs `$05`
equals `$62` in every pose. Frames are therefore normalized to a single anchor (`$13*7`, a real
observed steady-state legs X) so the block cycles **in place**, with Stage B2 supplying the live X.

**Falsification checks (independent of the derivation).** (a) Per-pairing `(dx,dy)` invariance across
two independent windows — a wrong anchor would make a "constant" offset drift. (b) Geometry never
used to derive anything: `rowTorso + heightTorso == rowLegs` **exactly, for all 11 frames** (torso
bottom abuts legs top, no gap/overlap), and every frame's foot line lands on y161 except `c1`/`c5`
at y160 (the raised foot mid-stride).

**Why the port is data-only.** `gen_scene6_placement.py` emits asm for the `climb_crawl` block only
(`if cur_block == "climb_crawl"`), so the `run:` block produces no asm; the 16 new `[registry]` rows
emit `fcb w,h,start_col` data into `scene6_placement_gen.s`, which the **prod link line does not
include** (prod = `src/engine/*` + `scene5_e2e_driver.s`). Hence prod is byte-identical, verified.

### §5  Verification (AC-by-AC)
- **AC1 — trace the oracle run animation; leg+torso and offsets per frame, execution-confirmed.**
  `build/logs/stageb0_run_attract.txt`, 42 poses over f6423–6630 + f8610–8947. Pairing table (all
  observations, `dx/dy/rowL/rowT` unique per pairing):
  `9B00+9D68 n=5 (7,-15,141,126)` · `9B00+9D97 n=5 (7,-15,141,126)` · `9B6B+9D68 n=5 (10,-15,141,126)`
  · `9B6B+9D97 n=5 (10,-15,141,126)` · `9BE5+9DD5 n=9 (14,-23,149,126)` · `9C1B+9E05 n=5 (7,-13,138,125)`
  · `9C65+9E2E n=3 (7,-13,138,125)` · `9CAF+9E4A n=2 (7,-20,143,123)` · `9CD7+9E74 n=2 (7,-14,139,125)`
  · `9D1E+9E92 n=1 (0,-12,138,126)`.
- **AC2 — ported to an `[animation] run:` block matching the `climb_crawl` schema, sub-byte carried.**
  11 rows `fid dwell cel:col,sub,row cel:col,sub,row` in `content/scene6/scene6_placement.txt`; every
  part carries `col,sub,row` (subs 0/1/3 present — never flattened).
- **AC3 — composition map doc.** `docs/project/run-composition-map.md` with method, evidence,
  per-frame table (frame | legs | torso | dx | dy | rows | port col,sub,row | dwell), the anchor
  derivation, dwell measurements and residue.
- **AC4 — the sprite tool assembles run frames.** Fresh tool-module output (§6).
- **AC5 — confirm the 16, and 16-distinct vs mirrored-8.** Neither: **16 cels → 11 frames**; all 8
  legs and all 8 torsos are in use; **not** a mirrored 8 — every draw came through entry `A` with
  `flip=$00` (no `$1909/$190C` mirror draw in either window).
- **AC6 — no engine/scroll build; prod byte-identical.** §6 hash.

### §6  Verdict-time evidence (§11)
25.1 fresh tool output (verbatim):
```
--- build.bat ---
wrote C:\Projects\karateka_coco3\tests\scripted\scene6_fuji_gen.s: 4 fuji rows
wrote C:\Projects\karateka_coco3\tests\scripted\scene6_climb_opacity_gen.s: 2 authored climb cel(s) -> ['scene6_climb_A3E9', 'scene6_climb_A3C5']
  ... (all 22 drivers assembled) ...
  tests/scripted/bootloader.bin (403 bytes)
=== BUILD COMPLETE ===

--- tests/scripted/run_kernel_dispatch_test.bat ---
DP$52 frame_done      = 0x00 (expect 0x00)
DP$53 frame_countdown = 0x00 (expect 0x00)
DP$54 frame_sync_dc   = 0x00 (expect 0x00)
DP$50 page_register   = 0x40 (expect 0x40, phase-matched to frame-700)
DP$51 page_source_blit= 0x20 (expect 0x20, phase-matched to frame-700)
invariant $50+$51     = 0x60 (expect 0x60)
RESULT: PASS
=== P2.2 MAME TEST: PASS ===

--- prod hash (post-build) ---
88eba89b15cdf17c8d25e082d2d3e1f3cce57d38 *build/karateka.bin      [byte-identical]
```
25.2 bundled-artifact grep — sprite-tool assembly of the ported block (verbatim):
```
blocks: ['climb_crawl', 'run']
run frames: ['s0', 's1', 'c0', 'c1', 'c2', 'c3', 'c4', 'c5', 'c6', 'c7', 'e0']
player anim entries: [... 'run s0', 'run s1', 'run c0', 'run c1', 'run c2', 'run c3',
                          'run c4', 'run c5', 'run c6', 'run c7', 'run e0']
player individual cels still listing run_?: []
  run[s0]: canvas 15x39 at (157,123) parts=2 painted_px=249
  run[s1]: canvas 23x37 at (153,125) parts=2 painted_px=358
  run[c0]: canvas 32x36 at (153,126) parts=2 painted_px=395
  run[c1]: canvas 40x35 at (153,126) parts=2 painted_px=379
  run[c2]: canvas 26x36 at (157,126) parts=2 painted_px=345
  run[c3]: canvas 23x37 at (153,125) parts=2 painted_px=326
  run[c4]: canvas 35x36 at (153,126) parts=2 painted_px=425
  run[c5]: canvas 40x35 at (153,126) parts=2 painted_px=409
  run[c6]: canvas 26x36 at (157,126) parts=2 painted_px=345
  run[c7]: canvas 23x37 at (153,125) parts=2 painted_px=356
  run[e0]: canvas 20x36 at (153,126) parts=2 painted_px=358
```
(The run cels no longer appear as individual cels ⇒ they are assembled, per `catalog.entries_for`.)
25.3 operator-runtime-smoke: **pending Jay** — Jay's eye on the assembled run frames in the sprite
tool (category → player → `run c0…c7`). Clyde makes no pixel-content claim (CLAUDE.md §3).

### §7  Reactive deviations
- The `[animation] run:` block is normalized to a single anchor rather than carrying the oracle's
  advancing per-frame X. This is required by the port split (B0 = composition, B2 = the engine's X
  advance) and the anchor itself is execution-derived, not invented — reasoning in §4 and in the map
  doc. Surfacing it because it is the one place the ported numbers are not literally the trace's.
- `content/scene6/scene6_placement.txt` already carried an **uncommitted pre-existing** change when
  this task started (the `authored` flags on `A3C5`/`A3E9`, from earlier work). It is committed along
  with this task's additions because it is the same file; it is not this task's edit.

### §8  Uncertainty flags
- **`plan_stage-b.md` NOT FOUND** in the repo (as `plan_recon1-scroll-stop.md` was not, last
  dispatch). Worked from the dispatch §1–§3, which is self-contained. Two dispatches running, so the
  plan-file reference is drifting — worth re-establishing.
- **No predicted band supplied** in the dispatch, so §1 states elapsed without a classification.
- **Mirrored/leftward run: not execution-confirmed.** Entry map is `A`-only, `flip=$00` in both
  windows; a leftward run would presumably mirror via `$1909/$190C` but the attract never showed it.
- **Dwell is measured, not a located code constant.** Clean free-running cadence = **11 VBL**
  (f8802–8947: 11,12,11,11,11,12,11,11,11,12,11,11,10); the same animation shows 17–21 and 7–19 under
  heavier scene load because the main loop is compute-bound (idioms §8a). 11 is what the block
  carries; a per-frame dwell table in the game code was not found this pass.
- **`e0` (stop) observed once** (f6630) — the second run was cut by the loop-back at f8951.
- **Cycle wrap `c7→c0`** is confirmed by observation in both windows, but the game's own frame-index
  wrap was not read from code.
- **`conventions.md §12.3` is wrong** ("16-frame run cycle"): execution says 16 cels → 11 frames.
  NOT edited by this task (not dispatched); see §9.

### §9  Follow-up candidates
- Correct `conventions.md §12.3` to "16 cels (8 legs + 8 torsos) composing 11 frames — 2 start, an
  8-frame cycle, 1 stop" citing `run-composition-map.md`.
- Stage B2: the run's X advance. The trace gives the raw material — legs col == `$62` per pose, and
  `$62` steps +1..+3 cols per frame in the free-running stretch — so the per-frame advance is
  measurable from the same log without a new run.
- Locate the run's dwell/frame-index in code to replace the measured 11 with a constant (settles the
  §8 dwell residue).
- The f8610–8947 run **is** Recon 1's walk-off; Recon 1's "the sole advancing figure is the player"
  and its `$8E9B/$8EC1` at col `$2A` ambiguity can now be re-read against this cel-level trace.
- Mirror check for a leftward run — would need a game (non-attract) capture or a forced state.

### §10 User interaction during task
None. (Earlier in the session, before this dispatch, Jay asked for the oracle to be run at 2× — a
separate viewing request, already closed; it is not part of this task's evidence.)

### §11 Candidate(s) captured this task
`seeds/karateka/live/2026-07-20-read-the-animation-anchor-off-the-trace-dont-invent-one.md` —
when porting a MOVING animation, the frame anchor is a measurable fact in the reference's draw trace
(log the actor-position variable beside each draw; find the part whose column EQUALS it), not a
modelling choice; falsify with per-pairing offset invariance across independent windows plus
independent geometry. Also added as MAME idiom §12a (`mame-idioms-apple2e-oracle.md`).

### §12 Commit
`4cceb500dfe9b120b8c1603b027759e5934dd56a` — port + map doc + instruments + idiom.
(This report is committed on top; both pushed to `origin/wip`.)

---

## CORRECTION — appended 2026-07-20 after Jay's visual gate (25.3 partial)

**Jay's two notes on the assembled frames:** (1) "there should be a standing straight pose at the
end of the run that I don't see"; (2) "any byte duplicates? a few look like duplicates by eye."

### Note 1 — CONFIRMED, and it exposed a second defect. My error, not the oracle's.
`stageb0_run_capture.lua` filtered to the run bank `$9B00-$9EB7`. That filter hid **two** things:
- the **standing straight pose** Jay expected — it is `$899C`+`$8ACB`+`$8E9B`, none of them run-bank
  cels, so the filtered pass could not see it at all;
- the **head `$8E9B`**, which draws in **EVERY** run pose — so all 11 shipped frames were missing a
  part and the run figure was headless.

This is **idioms §9 verbatim** — *"wholesale bank exclusion hides actors sharing the bank"* — the
exact trap that file warns about, walked into while quoting the file for everything else. The
filtered trace was self-consistent (42 poses, invariant offsets), which is precisely why it read as
complete: **a filter makes absence look like structure.** Nothing in the filtered data could have
flagged it; the operator's eye did (CLAUDE.md §2 / the "past scene 4 the eye wins" idiom, earning
its keep again).

**Re-trace, unfiltered** (`build/logs/stageb0_run_full1.txt` f6390–6700, `stageb0_run_full2.txt`
f8580–8960): **44 poses, 0 incomplete, 11 pairings — each with a UNIQUE and invariant torso AND head
offset.** Composition parts = entry-`A`, `flip=$00` draws (entry `By` = the guard; `flip=$FF` = the
mask pass, excluded — inferred as mask/erase, residue). Draw order = **legs → head → torso**.

The `run:` block is now **12 frames × 3 parts** (`s0,s1,c0..c7,e0,st`). The new `st` frame is
`899C:39,1,138  8E9B:39,3,116  8ACB:39,1,124`, dwell 21 VBL (f6649→f6670, observed once) — and it
lands on **the same trio and the same rows as `climb_crawl f6`**, so two independently-derived beats
of the port agree on the standing figure. No new `[registry]` rows were needed (`$8E9B`/`$899C`/
`$8ACB` were already members via the climb block).

**A transcription bug in my own analysis, caught and fixed:** the first grouping pass sorted draws
by `(frame, cel)`, which reordered same-frame draws (cel `$8E9B` sorts before `$9C1B`) and produced
9 spurious "incomplete" poses plus two phantom offset variants. Preserving **execution order**
resolved all 9 and both variants — the invariance is exact, not approximate.

### Note 2 — no byte duplicates; the repetition is compositional
All 16 run cels are **byte-distinct** in the oracle dump (header+data MD5) and all 16 `converted.s`
are byte-distinct in the port. What reads as duplication:
- **`c2` and `c6` are the identical frame** (same trio, same offsets) — it genuinely occurs twice
  per 8-frame cycle. That is the oracle's cycle, not a data error.
- **`c0`/`c4`, `c1`/`c5`, `c3`/`c7` are near-twins:** same legs, same head, differing only in the
  torso cel (`$9D68` vs `$9D97`; `$9E05` vs `$9E2E`) — the arm-swing alternation that makes an
  8-frame cycle out of 5 leg phases. Those torso cels differ even in **width** (3 vs 4 bytes; 3 vs
  2), so they are genuinely different art, not copies.

### Re-verification after the correction
```
--- build.bat ---                    === BUILD COMPLETE ===
--- run_kernel_dispatch_test.bat --- === P2.2 MAME TEST: PASS ===
--- prod hash ---                    88eba89b15cdf17c8d25e082d2d3e1f3cce57d38   [byte-identical]
--- sprite tool ---
  run[s0] dwell=11 parts=3 [9CAF 8E9B 9E4A]   run[c5] dwell=11 parts=3 [9B6B 8E9B 9D97]
  run[s1] dwell=11 parts=3 [9CD7 8E9B 9E74]   run[c6] dwell=11 parts=3 [9BE5 8E9B 9DD5]
  run[c0] dwell=11 parts=3 [9B00 8E9B 9D68]   run[c7] dwell=11 parts=3 [9C65 8E9B 9E2E]
  run[c1] dwell=11 parts=3 [9B6B 8E9B 9D68]   run[e0] dwell=11 parts=3 [9D1E 8E9B 9E92]
  run[c2] dwell=11 parts=3 [9BE5 8E9B 9DD5]   run[st] dwell=21 parts=3 [899C 8E9B 8ACB]
  run[c3] dwell=11 parts=3 [9C1B 8E9B 9E05]
  run[c4] dwell=11 parts=3 [9B00 8E9B 9D97]
```
Figure height went 35–39 px → 42–46 px with the head restored.

### Consequences for §8/§9 of the report above
- The §5 AC1 pairing table and the §4 anchor derivation are **unaffected** — torso offsets and the
  legs==`$62` anchor are identical in the unfiltered data. What changed is **completeness**, not
  correctness.
- **25.3 remains pending Jay** on the corrected 12-frame, 3-part set.
- New residue: the `flip=$FF` mask-pass reading is inferred, not read from the blit code; `st` and
  its 21-VBL dwell are observed once.
- **Second candidate captured:** `a-bank-filter-makes-absence-look-like-structure` — see §11.
