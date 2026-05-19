# karateka-coco3 — project state

## Current state

- Methodology version: Claude-Orchestrated Development Methodology v0.2
- Project phase: P2 IN PROGRESS (P2.3 COMPLETE per audit 2026-05-17;
  canonical P2.4 not started — see §Execution history)
- Last update: 2026-05-19

## P2 trajectory

**P2 target deliverable:** bootable CoCo3 disk running the complete intro/attract
sequence (Brøderbund logo → title → cliff approach → demo combat → Akuma throne
room cutscene → loop). Corresponds to integration milestone INT-3.

**Three workstreams:**
- P2.x engine ports against smart HAL stubs (P2.1 complete; P2.2+ scoped per milestone)
- P3.x real HAL implementations (interleaves after P2.2 lands)
- Content conversion in waves scoped to integration milestones; each wave uses the
  visual-verification protocol (design doc Section 6.7)

**Integration milestones:** INT-1 (first scene), INT-2 (logo→title→cliff sequence),
INT-3 (full attract cycle) — see milestones.md for detail.

**Next (canonical):** Major-work decision pending among R-p24 (canonical P2.4 /
intro.s scene-1 path), R-vbl (real GIME VBL; first deliverable of P3.1), R-boot (boot-path
integration). P2.3 COMPLETE per audit 2026-05-17 (see §Execution history).
INT-1 content-asset preconditions are substantially complete (see §Execution history).

## Phase status

- P0: complete (karateka_dissasembly_claude M1/M2 closure provided
  the intro-time reference oracle; P0b ongoing for gameplay-state
  coverage)
- P1.0: complete (commit c4b06ec, 2026-05-13)
- P1.1: complete (commit 71c6894, 2026-05-13)
- P1.2: complete (commit 88ffb27, 2026-05-13; follow-up: aa5753a/381bc43)
- P1.3: complete (commit b319e42, 2026-05-13; follow-up: a97d41c)
- P1.4: complete (commit ba88652, 2026-05-13)
- P1.5: DEFERRED TO P2 (pattern bootstrap; populates during P2 engine porting)
- P1.6: complete (commit e921889, 2026-05-13)
- P1: PHASE COMPLETE (2026-05-14); P1.5 deferred to P2
- P2.0a: complete (2026-05-14; commit 396a293 in karateka_dissasembly_claude)
- P2.0b: complete (2026-05-14)
- P2.1: complete (2026-05-14; commit e7a1e6b)
- P2.2: complete (2026-05-15; this commit)
- P2.3 (canonical blit/graphics engine port, INT-1 scope): COMPLETE per audit 2026-05-17
  (3 deferred routines: routine_1c5b, routine_1c64, L0A03 — combat-path, not INT-1 scope)
- P2.4 (canonical intro.s scene-1 path): not started
- P2.5-P5: not started

## Execution history (informal session sub-numbering, 2026-05-17)

**Numbering note:** The sub-numbering below (P2.3a, P2.4.1, etc.) is informal
session shorthand, not canonical project numbering. Canonical numbering per
docs/p2-scoping-survey.md: P2.3 = blit/graphics engine port; P2.4 = intro.s
scene-1 path. Design-doc v0.1 §7.4 numbering (P2.3 = gameplay state, P2.4 = combat
animation) is superseded by the execution trajectory.

### P2.3a chain — HAL infrastructure + display setup (CONFIRMED 2026-05-17)

Work executed 2026-05-16/17. This is HAL capability and display infrastructure
work, NOT the canonical blit/graphics engine port (P2.3). [Note 2026-05-19: the
P2.3a chain + P2.4 chain together satisfy canonical P2.3 per 2026-05-17 audit —
see §Canonical P2.3 scope audit below.]

- P2.3a.0: HAL_sys_init + HAL_gfx_init scaffolding: CONFIRMED
- P2.3a.6: Brøderbund splash + palette descriptor 0: CONFIRMED
  (logos rendered, palette MAME-verified, Option I double-buffer convention established)
- P2.3a.7: framebuffer dump harness + decode tool (tools/lib/framebuffer_dump.lua,
  tools/decode_framebuffer.py): CONFIRMED
- P2.3a.8: lwasm expression evaluation characterization (whitespace terminates
  operand; documented in shared T-toolchain patterns): CONFIRMED
- P2.3a.9: visual_smoke NEXT_ROW fix: CONFIRMED
- P2.3a.10: "presents" glyph conversions (6 glyphs, start_col=119): CONFIRMED
- P2.3a.11: presents test driver, byte-aligned positions (3 followups): CONFIRMED

### P2.4 chain — sub-byte rendering HAL capability (CONFIRMED 2026-05-17)

Work executed 2026-05-17. This is a HAL capability extension, NOT the canonical
intro.s scene-1 engine port (P2.4).

- P2.4.1: HAL_gfx_blit_sprite sub-byte shifter (4 cases: sb0/1/2/3): CONFIRMED
  (visual gate via Jay + framebuffer structural verification)
- P2.4.1-followup-1: transparency-aware blit (256-byte mask LUT, key-color
  semantics): CONFIRMED
- P2.4.2: "presents" sub-byte positions via visible-extent formula (3 followups,
  centered at CoCo3 pixel 160): CONFIRMED
- P2.4.3: existing test driver inline HAL copy updates: NOT EXECUTED (deferred)
- P2.4.4: docs/conventions.md §§20-23 (sub-byte rendering, transparency, visible-
  extent metadata, provenance): CONFIRMED

### Brøderbund + presents combined scene driver (CONFIRMED 2026-05-17)

Static-display test harness rendering all three Brøderbund scene elements on a
single CoCo3 frame. Visual gate: Jay "the visual looks good."

- Logos and "presents" rendered on one back buffer with transparency layering.
- "presents" centered at CoCo3 pixel 160 (screen center), matching Apple II
  centering at pixel 140.
- D2 (render order parity fix): CLOSED — driver now matches Apple II routine_b898
  badge-first/wordmark-second order; output byte-identical before and after fix.
- Position parity Q1-Q4 reconciliation: CONFIRMED from source (all three elements
  verified as DOCUMENTED TRANSFORM per docs/conventions.md §19).
- INT-1 content-asset preconditions (per p2-scoping-survey.md §5): SUBSTANTIALLY
  COMPLETE. Logos converted, 6 "presents" glyphs converted (INT-1 minimum met;
  full 30-glyph alphabet not yet done), positions proven, palette verified.
  Font metrics regeneration bypassed — CoCo3 uses direct per-glyph blit calls
  rather than porting Apple II text_render.s font-metrics path.

### Canonical P2.3 scope audit (COMPLETE per audit 2026-05-17; recorded 2026-05-19)

Route-by-route audit of Apple II video.s + render_frame_0a00.s against karateka-coco3.
INT-1-bounded interpretation (Jay's call 2026-05-17).

Audit results (14 routines total):
- ABSORBED-HAL: 11 — all functionality provided via HAL_gfx_clear (gfx.s:242-258)
  and HAL_gfx_blit_sprite (gfx.s:415-603)
- OUT-OF-SCOPE (deferred to combat-path): 3
    * video.s routine_1c5b (draw-B, no Y offset) — gameplay only; 0 splash-path fires
    * video.s routine_1c64 (draw-B, Y offset) — gameplay only; 0 splash-path fires
    * render_frame_0a00.s L0A03 / render_pass_b — attract/combat path, not splash
- UNPORTED: 0 / PARTIAL: 0 / UNCLEAR: 0

Interpretation choice: INT-1-bounded scope. Literal-files scope would return
SUBSTANTIAL (3 UNPORTED-DEFERRED); INT-1-bounded returns COMPLETE. Jay's
2026-05-17 call: INT-1-bounded. Deferred 3 reactivate when combat-path work begins.

### INT-1 distance

INT-1 ("first scene displays correctly") is NOT closed by the above work.
Three remaining requirements:
- R-p24: canonical intro.s scene-1 path (P2.4) — not started
- R-vbl: real GIME VBL implementation (first deliverable of P3.1) — not started
- R-boot: boot-path integration (scene runs at karateka.bin boot) — not started
R-p23 (canonical blit/graphics engine port) CLOSED 2026-05-17 per canonical
P2.3 audit (INT-1-bounded; 11 ABSORBED-HAL, 3 OUT-OF-SCOPE; see
§Canonical P2.3 scope audit above).

---

## Calibration phase tracking

Per methodology Section 9, the first 10-20 tasks of karateka-coco3
are calibration. Higher human gate involvement, criteria
refinement expected.

Calibration task counter: 14 (as of 2026-05-15; P2.3a/P2.4 chain tasks not
enumerated individually — see §Execution history above)

## Cross-project coordination

External resources (consumed via path/URL reference, no git
coupling):
- `../karateka_dissasembly_claude/` — reference oracle
- `../6502-6809-conversion-patterns/` — shared porting patterns
- `../apple2-disasm-patterns/` — disassembly methodology patterns

Pattern repo updates: monitor commits in those repos; consume
patterns when relevant to a task. No version pinning.

Reference oracle updates: when karateka_dissasembly_claude
advances substantively (new gameplay-state dumps disassembled),
capture a sync-point commit per design doc Section 11.6.

## Methodology lessons (will accumulate)

- Visible-extent metadata (wlead, trail) is subbyte-invariant for the 6 "presents"
  glyphs (p, r, e, s, n, t) measured at all 4 subbyte positions. Method applies to
  other sprites; values await measurement. See docs/conventions.md §22.
- docs/methodology.md Rule 1 (no color from screenshots) + framebuffer dump as
  canonical verification signal established across P2.3a chain.
- Task C methodology patterns filed to 6502-6809-conversion-patterns:
  G.3-G.38 (36 G-methodology patterns, commits 1724351) and T-technical/T-toolchain
  (6 references, commit 5785ee0). Both pushed to Jsearle01/6502-6809-
  conversion-patterns on 2026-05-17.
- HAL absorption is legitimate porting. Classify ABSORBED-HAL distinctly from UNPORTED
  in subsystem audits — an ABSORBED-HAL routine is complete via HAL contract, not a gap.
  A subsystem-audit verdict of COMPLETE requires that the absorbed routines cover the
  subsystem's load-bearing call surface AND that the remaining routines are explicitly
  OUT-OF-SCOPE under a documented interpretation choice. The P2.3 audit found 11
  ABSORBED-HAL / 0 UNPORTED; the "not started" label persisted because the
  implementation path was HAL-mediated rather than literal source translation. Watch
  for this when recording future phase-status entries.

## Open questions (will accumulate)

See `docs/open-questions.md` (to be created as questions surface).
