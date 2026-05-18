# karateka-coco3 — project state

## Current state

- Methodology version: Claude-Orchestrated Development Methodology v0.2
- Project phase: P2 IN PROGRESS (P2.2 complete; canonical P2.3 not started;
  P2.3a chain + P2.4 chain HAL/capability work CONFIRMED — see §Execution history)
- Last update: 2026-05-17

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

**Next (canonical):** P2.3 (blit/graphics engine port: video.s + render_frame_0a00.s +
display setup bundled). INT-1 content-asset preconditions are substantially complete
(see §Execution history); INT-1 closure additionally requires P3.1 (real GIME VBL),
canonical P2.4 (intro.s scene-1 path), and boot-path integration.

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
- P2.3 (canonical blit/graphics engine port): not started
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
work, NOT the canonical blit/graphics engine port (P2.3).

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

### INT-1 distance

INT-1 ("first scene displays correctly") is NOT closed by the above work.
Four remaining requirements (per milestones.md + scoping survey §6.2):
- R-p23: canonical blit/graphics engine port (P2.3) — not started
- R-p24: canonical intro.s scene-1 path (P2.4) — not started
- R-vbl: real GIME VBL implementation (P3.1) — not started
- R-boot: boot-path integration (scene runs at karateka.bin boot) — not started

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

## Open questions (will accumulate)

See `docs/open-questions.md` (to be created as questions surface).
