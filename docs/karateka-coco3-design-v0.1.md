# Karateka — Color Computer 3 Port

**Project name:** karateka-coco3
**Version:** v0.1
**Date:** May 12, 2026
**Status:** Initial design. Phase 0a complete (intro-time memory image reconstruction verified via M1/M2 closure of the karateka_dissasembly_claude project). Phase 0b ongoing (gameplay-state dump capture and disassembly continuing in karateka_dissasembly_claude). Phase 1 not yet begun.
**Methodology:** Claude-Orchestrated Development Methodology v0.2 (inherited from pop-coco3)

---

## 1. Executive summary

### 1.1 What this project is

Port of Karateka (Jordan Mechner, 1984, Apple IIe) to the Tandy Color Computer 3. Native 6809/6309 assembly. Faithful gameplay reproduction. Designed for bare-metal CoCo3 deployment (floppy initially, hard drive and DriveWire deferred).

### 1.2 Scope summary

**v1.0 deliverable:** Engine + intro sequence (5 scenes) + gameplay (cliff approach, courtyard combat, throne-room final fight) + win/lose endings. Playable from start to finish. Single HAL target initially (RSDOS floppy). Runs on stock 128KB CoCo3 with 6809; 6309 and 512KB optimizations layered in as discovered necessary.

**v2.0 deliverable (deferred):** Additional HAL targets (HDB-DOS hard drive, DriveWire, NitrOS-9), Orchestra-90 sound cartridge support, possibly enhanced graphics modes.

### 1.3 Phase 0 status: intro-time baseline complete; ongoing disassembly required

The Apple IIe Karateka baseline at intro time is verified working. The karateka_dissasembly_claude project (M1 complete 2026-05-12, M2 complete 2026-05-12) produced:

- 38 src/*.s files covering 100% of Karateka's RAM contents at intro time (32,256 bytes from dump01_intro.bin)
- Three-phase build pipeline (per-range round-trips → memory image reconstruction → sector overlay) producing a bootable build/karateka_fresh.dsk
- Round-trip byte-identity verified at all three phases for the intro-time snapshot
- Gameplay verified in MAME

**However: the intro-time snapshot is not the complete game.** Karateka loads additional content from disk as gameplay progresses — scene-specific code, sprite banks, level data, animation tables, and sound assets that aren't present in dump01_intro.bin. The karateka_dissasembly_claude project's continuing work captures these additional gameplay states via supplementary memory dumps (dump04_castle_entry, dump07_first_fight, and others) and extends src/ to cover them.

For karateka-coco3, this means:

- The Phase 0 reference oracle is **not yet complete** despite the M1/M2 milestones being closed for the intro-time territory
- Ongoing karateka_dissasembly_claude work expands the reference oracle as additional gameplay-state dumps are processed
- karateka-coco3 P2 work on engine subsystems whose code is fully captured in dump01_intro.bin can proceed in parallel with karateka_dissasembly_claude gameplay-state work
- karateka-coco3 P4 work on per-scene content depends on karateka_dissasembly_claude having captured and disassembled the relevant gameplay states
- The complete source tree (intro + all gameplay states) is itself a deliverable artifact of the combined project effort

This verified baseline serves as the reference oracle for the CoCo3 port at the level of detail currently captured. The reference oracle deepens as karateka_dissasembly_claude work continues.

### 1.4 Methodology

The project follows the Claude-Orchestrated Development Methodology v0.2 (inherited from pop-coco3). This design document is a project-specific binding (per methodology Section 10) of that methodology to karateka-coco3.

Karateka-disasm methodology (the per-commit plan-and-review discipline that produced M1/M2) continues at the micro level. POP-style phase-and-gate discipline operates at the macro level.

### 1.5 Estimated timeline

3–9 months for v1.0. Karateka is smaller than POP (~32KB game code vs POP's larger codebase, single-scene environments rather than 12 levels, simpler animation system). The timeline scales accordingly:

- Methodology calibration phase (first 10–20 tasks)
- HAL contract design and implementation
- Engine porting (largest line item)
- Subsystem integration and testing
- Cross-configuration validation

This is a hobby-project estimate. Active development time is fractional. The timeline reflects calendar time at a sustainable pace.

### 1.6 Relationship to karateka_dissasembly_claude

karateka-coco3 is downstream of karateka_dissasembly_claude AND runs in parallel with continuing karateka_dissasembly_claude work. The src/ tree from karateka_dissasembly_claude is the input source; this project produces the 6809 port.

karateka_dissasembly_claude continues work after M1/M2:

- **Capturing additional memory dumps** at distinct game states (intro is dump01; gameplay states captured as dump04, dump07, etc.)
- **Disassembling new code/data** that appears in gameplay-state dumps but not in dump01_intro.bin
- **Documenting the complete game** — not just the intro-time RAM snapshot
- **Producing the complete reassembled disk artifact** — a working .dsk derived from src/ that includes all gameplay code and data, not just intro-time content

This is a deliverable artifact in its own right: the complete Karateka source tree is valuable to the retrocomputing community independently of the CoCo3 port.

Cross-project dependency direction:

- **karateka_dissasembly_claude → karateka-coco3:** new src/ files become available as karateka_dissasembly_claude processes new dumps. karateka-coco3 schedules subsystem porting after the relevant subsystem's source is fully captured.
- **karateka-coco3 → karateka_dissasembly_claude:** porting work surfaces questions about Apple II behavior that drive karateka_dissasembly_claude investigation. ("What does this scene transition do?" → check the relevant dump, disassemble if not yet done.)

Coordination protocol:

1. karateka-coco3 work consults karateka_dissasembly_claude src/ at the level of detail currently captured
2. When karateka-coco3 needs a subsystem not yet fully disassembled, schedule karateka_dissasembly_claude dump capture + disassembly first
3. When karateka_dissasembly_claude src/ changes (rare after M1; possible when new dumps are processed or when porting work surfaces errors), the changes propagate via:
   - Update karateka_dissasembly_claude src/, verify round-trip + smoke test PASS
   - Re-run any karateka-coco3 work that referenced the changed source
   - Document the cross-project dependency in the affected subsystem's port log

**Note on karateka_dissasembly_claude milestones:** karateka_dissasembly_claude's original M3 (CoCo3 port) is now this separate karateka-coco3 project. karateka_dissasembly_claude's docs/milestones.md will be updated to reflect its independent ongoing milestone path:

- **M1** — 100% intro-time territory ✓ COMPLETE (2026-05-12)
- **M2** — Bootable Apple II disk from src/ ✓ COMPLETE (2026-05-12)
- **M3** — Gameplay-state territory complete (all gameplay-state dumps disassembled with round-trip verification)
- **M4** — Complete reassembled Apple II disk (entire .dsk derivable from src/, not just intro-time portion)

This renumbering is karateka_dissasembly_claude's housekeeping; karateka-coco3 doesn't depend on it but tracks karateka_dissasembly_claude's progress against the new milestone framework.

---

## 2. Background and motivation

### 2.1 Karateka historical context

Karateka was developed by Jordan Mechner from 1982–1984 and published by Brøderbund Software in 1984. It runs on the Apple II family with notable features:

- Rotoscoped character animation (predecessor to Mechner's later work on POP)
- Cinematic scene transitions (intro sequences with credits)
- Tile-based environmental rendering (cliff approach, courtyard, throne room)
- Engineering achievement: complete game in 32KB of game code + sprites + sound data at intro time, with additional content loaded from disk during gameplay

Source code was never officially released. The karateka_dissasembly_claude project produced a clean-room disassembly from a cracked .dsk variant, with full byte-identity verification at the memory-image level for the intro-time RAM snapshot.

### 2.2 Why CoCo3

The Color Computer 3 (1986) is a contemporary of the Apple IIe, with comparable hardware capabilities. The CoCo3 has:

- Motorola 6809 CPU (1.79 MHz effective), with optional HD6309 upgrade
- GIME (Graphics Interrupt Memory Enhancer) chip providing 320×192 graphics modes
- 128KB minimum RAM, up to 2MB with aftermarket upgrades
- 6-bit DAC for sound
- Floppy disk system via WD1773 controller
- Strong active community in 2026

Karateka has never been officially ported to CoCo3. Cross-port projects for that era's games are a recognized hobby-development category.

### 2.3 Relationship to pop-coco3

Jay's pop-coco3 project is the sibling project to karateka-coco3. The two projects share methodology and a shared pattern library (Gate K.1.9, Section 6.5); they are not parent/child but peers.

Sharing flows in both directions:

- Patterns surfaced during karateka-coco3 work propagate to pop-coco3 if applicable
- Patterns surfaced during pop-coco3 work propagate to karateka-coco3 if applicable
- Methodology refinements (CODM revisions) apply to both
- Toolchain and infrastructure investments (MAME harness Lua patterns, lwasm idioms, GIME programming approaches) are shared

karateka-coco3 is smaller scope than pop-coco3 (single-engine game, simpler animation system, fewer levels). It is in some ways a "warm-up" for the pop-coco3 work and a proving ground for shared patterns. Patterns that work in karateka-coco3's smaller surface area get tested before pop-coco3's larger surface area exercises them.

Where pop-coco3 patterns apply directly, this document references them; where karateka requires different patterns, this document specifies the karateka-specific form.

---

## 3. Goals and non-goals

### 3.1 Goals

**Playable Karateka on a stock CoCo3.** A user with a CoCo3, a disk drive, and a 128KB stock 6809 system can boot the disk and play the game from start to finish.

**Faithful gameplay.** Combat mechanics, scene progression, win/lose conditions, intro sequence — all match the Apple IIe behavior. Pixel-by-pixel rendering need not match (different display hardware) but visual feel should.

**Layered architecture.** Same engine code, different HAL implementations. Boot-time CPU detection where it matters; same shipped binary handles both 6809 and 6309 CoCo3s. (Pattern inherited from pop-coco3.)

**Visible engineering quality.** Documentation-first discipline. Documented HAL contract. Documented engine conventions. Documented pattern library. Test harness with automated verification. Review-gate discipline.

**Eventual community release.** Source and binaries published. Project structured to invite contribution, study, and adaptation.

**Methodology proving ground.** karateka-coco3 is smaller and faster than pop-coco3. Patterns surfaced here that work get carried to pop-coco3; patterns that don't get corrected before pop-coco3 inherits them.

### 3.2 Non-goals

**Apple IIe feature parity at pixel level.** Karateka's Apple II hi-res output has specific color-fringing characteristics from the Apple II's display hardware. CoCo3 graphics will look different. Behavioral fidelity is the goal; visual fidelity is bounded by hardware differences.

**Byte-identical reproduction.** karateka_dissasembly_claude produced byte-identical Apple II output; karateka-coco3 produces functionally-equivalent CoCo3 output. Different goal, different verification approach.

**Cross-platform disk format.** CoCo3 disks aren't Apple II disks. No attempt at dual-platform media.

**Other Karateka ports.** Karateka was ported to Atari 8-bit, C64, IBM PC, and other platforms in its commercial run. Those ports are out of scope. karateka-coco3 derives from the Apple IIe source disassembly only.

**Mobile, web, or modern-platform versions.** This is a Color Computer 3 port.

---

## 4. Prior art

### 4.1 Karateka Apple II source

The original Karateka source was never released. karateka_dissasembly_claude src/ is the authoritative source for the CoCo3 port. Mechner's other work (Prince of Persia source, available through jmechner/Prince-of-Persia-Apple-II) provides reference for his engineering style of that era.

### 4.2 Karateka technical references

karateka_dissasembly_claude project documentation:

- `docs/milestones.md` — M1/M2 status, acceptance criteria
- `docs/memory-coverage-map.md` — full address-to-content map
- `docs/data-areas-catalog.md` — code regions, sprite banks, jump tables
- `docs/open-questions.md` — unresolved questions, including Q016 (ZP cluster semantics), Q017 (M1 coverage), and others
- `src/` tree — 38 .s files covering the full game

These references are authoritative for "what the engine does." They are checked into the karateka_dissasembly_claude repository and accessible to this project.

### 4.3 CoCo3 reference material

- **GIME white-room behavioral specs** — Authoritative for GIME hardware behavior. Reference for graphics HAL. Separately maintained in Jay's GIME white-room project.
- **CoCo3 hardware references** — Specific document selection during P1.
- **NitrOS-9 reference** — System call manual, RBF documentation, module format. Reference for OS-9 HAL target (v2.0).
- **lwasm documentation** — Assembler syntax, pseudo-ops, listing format.

### 4.4 Cross-port precedent

- **pop-coco3** (in progress, Jay) — Methodologically the parent project. Patterns documented in pop-coco3 inform this project. pop-coco3 design doc at v0.7.
- **Other Apple II → CoCo3 ports** in the community provide informal precedent.

---

## 5. Closed design decisions (gates)

The following decisions are baked into the design and not open for re-litigation during execution. Each gate references the conversation log entry where it was decided.

### 5.1 Gate K.1.0 — Source baseline: karateka_dissasembly_claude src/

The canonical source tree for cross-reference during porting is the karateka_dissasembly_claude repository's `src/` directory. The source tree is in a state of ongoing development:

- M1 closure (2026-05-12) captured 100% of Karateka's intro-time RAM contents (38 files, 32,256 bytes from dump01_intro.bin)
- Additional disassembly work continues for gameplay-state dumps (dump04_castle_entry, dump07_first_fight, others as captured)
- karateka_dissasembly_claude produces a complete reassembled disk artifact as gameplay-state coverage matures

Rationale: M1 closure produced a byte-identical, round-trip-verified, smoke-tested source tree for the intro-time snapshot. This is sufficient for karateka-coco3 to begin P1 and substantial P2 work. Subsystems whose code is fully captured in dump01_intro.bin (kernel, dispatch, intro flow, attract mode, combat animation tables) can proceed. Subsystems with content in gameplay-state dumps wait for the corresponding karateka_dissasembly_claude coverage.

Cross-project sequencing is detailed in Section 1.6.

### 5.2 Gate K.1.1 — Graphics target: GIME 320×192×4

Graphics mode is GIME CRES=01, 80 bytes per row, 4 colors per pixel selected from the 64-color GIME palette. Per-scene palettes swap on scene transitions; expect ~3-5 distinct palettes for Karateka's scene set (cliff approach, courtyard, throne room, intro/credits, attract).

Rationale: Inherited from pop-coco3 Gate 1.2. Same hardware constraints; same tradeoffs. 4-color mode uses 15KB per frame (vs 30KB for 16-color), enabling double-buffering in tight memory. Apple II HGR's effective on-screen color count is similar in practice.

### 5.3 Gate K.1.2 — HAL targets

v1.0 ships a single HAL target: **RSDOS floppy disk** (coco3-dsk).

v2.0 adds: HDB-DOS hard drive (coco3-hdb), DriveWire (coco3-dw), NitrOS-9 (coco3-os9).

Rationale: Karateka is smaller than POP and single-target ships faster. Additional HAL targets are valuable but not gating for v1.0. The HAL contract is designed for multi-target from the start (so v2.0 doesn't require redesign), but only one implementation is required for v1.0.

This differs from pop-coco3 Gate 1.4 (four HAL targets at v1.0). Justification: Karateka's smaller scope makes single-target v1.0 viable; POP's longer timeline justifies the multi-target investment up-front.

### 5.4 Gate K.1.3 — CPU support

Single shippable binary. Boot-time CPU detection. Engine code in 6809-compatible instructions only. Optimization layer (expected 2-3 routines for Karateka, smaller than POP's 5-8) has dual implementations: 6809 and 6309. Boot-time probe selects optimization layer at boot.

Rationale: Inherited from pop-coco3 Gate 1.6. Same detection mechanism (TFR MD,A sentinel for bare-metal; keyboard override for testing).

Karateka's expected optimization layer:

- `render_frame_blit` — equivalent to Karateka's $0A00 render_frame_0a00.s (262K fires/frame on Apple II — THE hot path)
- `vbl_sync` — equivalent to Karateka's $779A vbl_sync (per-frame timing backbone)
- Possibly one or two more surfaced during P2 profiling

### 5.5 Gate K.1.4 — Memory target

128KB stock supported. 512KB+ benefits explicitly leveraged where they matter (sprite cache, audio buffer). 128KB and 512KB both tested on every build.

Rationale: Inherited from pop-coco3 Gate 1.5.

Karateka's RAM-resident code is ~32KB on Apple II. CoCo3 needs additional space for:
- Code (similar size after porting, possibly larger due to 6809 vs 6502 encoding)
- Frame buffers (15KB × 2 for double-buffering at 320×192×4)
- Sprite cache (sprites are converted to CoCo3 format)
- HAL state, stack, direct page

128KB should fit comfortably with margin. 512KB enables sprite pre-conversion caching that may help frame rate.

### 5.6 Gate K.1.5 — Sound

Sound HAL ships with DAC default. 1-bit sound option may be added if community demand. Orchestra-90 deferred to v2.0.

Rationale: Karateka's audio is simpler than POP's (no music engine; mostly hit sounds, footsteps, voices). DAC at 6-bit resolution is more than sufficient.

This is simpler than pop-coco3 Gate 1.7 (which has explicit DAC + 1-bit dual paths). Justification: Karateka's audio data is small enough that the additional complexity isn't justified for v1.0.

### 5.7 Gate K.1.6 — Copy protection

The cracker's loader (as used in karateka_dissasembly_claude M2's sector overlay approach) included copy-protection stripping. Karateka's original copy protection (per Q010 investigation in karateka_dissasembly_claude, closed as scope-out) is not relevant to the port — the input source is the cracked memory image, not the original protected disk.

Karateka-coco3 has no copy protection. Matches pop-coco3 Gate 1.8 (strip protection from port).

### 5.8 Gate K.1.7 — Test harness as P1 deliverable 1

Inherited from pop-coco3 Gate 1.5a. The MAME test harness is built before any engine modules. Three rigor levels (smoke, demo-loop, scripted-playback). Shares MAME Lua instrumentation patterns with pop-coco3 and karateka_dissasembly_claude where possible.

The karateka_dissasembly_claude smoke test infrastructure (scripts/smoke_test.sh, three-phase build via build_disk.py) is a precedent and an asset. Pattern reuse expected. Adaptation:

- karateka_dissasembly_claude smoke tests the Apple II reassembly
- karateka-coco3 smoke tests the CoCo3 port
- Both share the principle of "verification infrastructure built first"

### 5.9 Gate K.1.8 — Methodology binding

karateka-coco3 inherits Claude-Orchestrated Development Methodology v0.2 from pop-coco3. Project-specific bindings appear in Section 10 of this document.

Karateka-disasm's per-commit plan-and-review discipline (verification plans filed before execution, review verdicts with per-prediction match tables, methodology lessons captured for plan-vs-execution deviations) continues for individual tasks within phases.

### 5.10 Gate K.1.9 — Shared pattern library hosted in 6502-6809-conversion-patterns repo

The pattern library is shared between karateka-coco3 and pop-coco3 and hosted in its own repository: `6502-6809-conversion-patterns`. This repo contains:
- `shared/` — Categories A, B, D, E, F (general translation, idioms, HAL interaction, DEV_MODE, anti-patterns)
- `project/karateka/` — Karateka-specific Category C patterns
- `project/pop/` — POP-specific Category C patterns

A separate repository, `apple2-disasm-patterns`, hosts disassembly-methodology patterns (caller-chain enumeration, anchored-grep, mid-instruction-label detection, build-artifact recognition, content-classification protocols). These patterns are upstream of porting work and useful for any Apple II reverse-engineering project, not specific to CoCo3.

Consumption mechanism: both pattern repos are consumed via path/URL reference at session time, not via submodule or subtree. Claude Code reads pattern docs when relevant to a task. No git coupling between consuming repos (karateka-coco3, pop-coco3, karateka_dissasembly_claude) and the pattern repos.

Rationale: Bidirectional reuse is a first-class design property. Both projects benefit from accumulated insight without duplication. Karateka-coco3 starts smaller and faster; patterns it surfaces help pop-coco3. Pop-coco3 is larger and longer; its accumulated patterns help future karateka-coco3 work and any subsequent CoCo3 ports using this methodology.

The hosting-in-separate-repo choice (rather than embedding in one consuming project) reflects symmetric ownership: neither karateka-coco3 nor pop-coco3 is the "primary" host. Patterns are first-class artifacts with their own version history.

Read-at-session-time consumption (rather than git submodule) reflects that patterns are documentation — they don't need to be assembled or linked into consuming builds. Updates propagate immediately to all consumers. The stability discipline (Section 6.5.5) protects against the failure mode where pattern changes silently affect in-progress work.

Apple II disassembly patterns are split into their own repo to keep `6502-6809-conversion-patterns` focused on porting concerns. Methodology patterns from karateka_dissasembly_claude (and applicable to any Apple II reverse-engineering work) live in `apple2-disasm-patterns`, where they may serve future projects beyond the CoCo3 port effort.

P1.5 deliverable for karateka-coco3 contributes to the bootstrap of `6502-6809-conversion-patterns`: identify initial Karateka-specific Category C patterns, contribute them to `project/karateka/`. Pop-coco3's P1.5 contributes Category C patterns for `project/pop/`. Shared categories (A, B, D, E, F) are bootstrapped from pop-coco3 design v0.7 Section 6.13 content. Coordination expected between both projects.

### 5.11 Gate K.1.10 — Repository topology: five separate repos

The karateka-coco3 project lives in its own repository. Cross-project resources are accessed via specific mechanisms documented in Section 11.

Five repositories total:

| Repository | Purpose | Consumption mechanism |
|-----------|---------|----------------------|
| `karateka_dissasembly_claude` | Apple II reverse engineering; reference oracle | Path reference at sibling directory |
| `karateka-coco3` | Karateka 6809 port | (this project) |
| `pop-coco3` | POP 6809 port | Sibling project; references same patterns repo |
| `6502-6809-conversion-patterns` | Shared porting pattern library | Path/URL reference at session time |
| `apple2-disasm-patterns` | Apple II disassembly methodology | Path/URL reference at session time |

Rationale:

- **Separate karateka-coco3 repo** (not subdirectory of karateka_dissasembly_claude, not fork): different lifecycles, methodologies, and toolchains. karateka_dissasembly_claude is Apple II 6502 work; karateka-coco3 is CoCo3 6809 work. Different ca65 vs lwasm, different MAME drivers, different build pipelines. Co-locating would mix concerns; forking would create merge conflict surface area for shared docs.

- **karateka_dissasembly_claude via path reference** (not submodule, not embedded copy): for solo-developer hobby-project scale, submodule operational friction outweighs reproducibility benefits. Karateka-coco3 expects karateka_dissasembly_claude to be checked out as a sibling directory. Both developer and Claude Code sessions assume the convention path.

- **Pattern repos as path/URL reference** (not submodule, not embedded): patterns are documentation, not code. They don't need to be assembled or linked. Read-at-session-time keeps the operational story simple. Updates propagate immediately to all consumers.

- **Two pattern repos** (not one combined): keeps porting concerns separate from disassembly concerns. `apple2-disasm-patterns` serves projects beyond CoCo3 ports (any future Apple II reverse-engineering work). `6502-6809-conversion-patterns` is CoCo3-port-specific.

This topology differs from pop-coco3's current structure (which has patterns documented only in design doc Section 6.13, not yet extracted to a repo). pop-coco3 P1.5 would consume the new patterns repos once bootstrapped; bootstrap is a standalone task (Section 11.8) ahead of either project's P1.5 execution.

Section 11 specifies the consumption details, directory conventions, bootstrap protocol, and cross-project coordination.

### 5.12 Gate K.1.11 — Reference discipline for CoCo3 / 6809 content

CoCo3 and 6809 platform content generation must cite project
reference documentation or explicitly surface the absence of a
covering reference. Discipline detailed in Section 6.6.

Rationale: CoCo3 / 6809 details have subtle quirks (GIME revisions,
6309 vs 6809 differences, timing dependencies). Project reference
docs are authoritative; training-data recall or web-search-derived
content is not. Citation creates audit trail enabling efficient
debugging when real-hardware testing surfaces issues.

This gate complements:
- Gate K.1.9 (shared pattern library) — where the discipline is
  documented as G.1
- Gate K.1.10 (repository topology) — where the consumption
  mechanism for the pattern is specified (path/URL reference)

---

## 6. Architecture

### 6.1 Layered architecture

Same structure as pop-coco3 Section 6.1:

```
┌─────────────────────────────────────────────────────────┐
│ Game content (sprites, sound data, scene scripts)       │
├─────────────────────────────────────────────────────────┤
│ Engine code (game logic, state machines, AI, combat)    │
│ 6809-compatible. Single implementation across CPUs.     │
├─────────────────────────────────────────────────────────┤
│ Optimization layer (~2-3 hot-path routines)             │
│ Dual implementations: 6809 and 6309. Boot-selected.     │
├─────────────────────────────────────────────────────────┤
│ HAL (graphics, input, disk, sound, time)                │
│ v1.0: single target (coco3-dsk).                        │
│ v2.0: hdb, dw, os9 added.                               │
└─────────────────────────────────────────────────────────┘
        │
        ▼
   ┌────────┐
   │ coco3- │
   │ dsk    │
   │ binary │
   └────────┘
```

### 6.2 Engine subsystems (mapped from karateka_dissasembly_claude)

Karateka's engine breaks into these subsystems (mapping karateka_dissasembly_claude src/ files to CoCo3 port responsibilities):

| Subsystem | Karateka-disasm source | Port responsibility |
|-----------|------------------------|---------------------|
| Kernel & dispatch | kernel.s, kernel_per_frame.s, kernel_dispatch_handlers.s | Main loop, per-frame dispatch, jump tables |
| Disk loader | disk_loader.s | Replaced by CoCo3 HAL file loading |
| Text rendering | font_metrics.s, text_render.s | Reimplemented for GIME |
| Hi-res rendering | hires_rows.s, render_frame_0a00.s | Replaced by GIME-native rendering |
| Sprite engine | video.s, sprite_data_*.s | Reimplemented for GIME 4-color sprites |
| Sound engine | sound_engine.s, pcm_player.s, sound_data_0e00.s | Reimplemented for 6-bit DAC |
| Timer dispatch | timer_dispatch.s, timer_sound_data_1100.s | Reimplemented for CoCo3 VBL/timer |
| Gameplay state | gameplay_state_0b00.s, gameplay_6000.s, gameplay_7000.s | Ported with minimal changes (logic, not platform) |
| Combat animation | fight_engine.s, $6000-$63FF animation tables | Ported with minimal changes |
| Input | input.s | Reimplemented for CoCo3 keyboard/joystick |
| Display | display_7700.s, attract_dispatch.s, attract_render.s, attract_state.s | Reimplemented for GIME |
| Scene dispatch | scene_dispatch.s, intro.s | Ported (control flow, not rendering) |

The mapping reveals two categories:
- **Engine code (ports with minimal changes):** kernel dispatch, gameplay state, combat animation, scene dispatch
- **Platform code (reimplemented behind HAL):** rendering, sound, input, timer, disk

Total engine code (estimated): ~10-15KB ported with logic preserved. Platform code (~17-22KB on Apple II) becomes the HAL implementation and is essentially rewritten.

### 6.3 The HAL contract

Same principles as pop-coco3 Section 6.2 / 6.11. The HAL contract is the most load-bearing artifact in the codebase.

Karateka HAL subsystems (mapping to pop-coco3 structure):

- **Memory HAL** — memory probing, allocation (simpler than POP; no level-resident streaming)
- **Time HAL** — frame timing, VBL sync, frame counter (parallel to Karateka's $779A vbl_sync)
- **Graphics HAL** — GIME programming, shape blitting (sprite render), palette management, text rendering
- **Input HAL** — keyboard and joystick polling (parallel to Karateka's input.s)
- **File HAL** — disk I/O for loading the game (replaces Karateka's disk_loader.s)
- **Sound HAL** — DAC output, sound event playback (replaces sound_engine.s + pcm_player.s)
- **System HAL** — CPU detection result, target identification, panic

Expected function count: ~20-25 functions (smaller than POP's 27 since Karateka has simpler memory and file requirements).

Full HAL contract specification is a P1.3 deliverable (`hal.inc` + `hal.md`).

### 6.4 Engine conventions

Same principles as pop-coco3 Section 6.12. To be specified as a P1.4 deliverable (`conventions.md`).

Karateka-specific conventions to capture:

- **ZP cluster naming** — Karateka uses $20-$2F (active combat), $60-$6F (combatant A), $70-$7F (combatant B). Port should preserve semantic naming via direct-page allocation.
- **Animation table indexing** — Karateka's combat animation system uses $20 (action code) + $26 (animation frame) to index into 22 tables at $6000-$63FF. This pattern translates directly.
- **Jump table dispatch** — Karateka has multiple jump tables (kernel $0780, jmptable_7000, jmptable_7800, jmptable_7D00, jmptable_6780). All translate to 6809 dispatch idioms (Pattern B.4 from pop-coco3).
- **Body-part composited sprites** — The 16-frame run cycle (8 legs + 8 torso) at $9B00-$9EB7 and the Akuma throne-room pose composition technique need a port-specific pattern.

### 6.5 Pattern library

The pattern library is a **shared resource between karateka-coco3 and pop-coco3**, not a project-local artifact. This is a load-bearing architectural decision: patterns surfaced in either project propagate to the other, ensuring both benefit from accumulated insight without duplication.

#### 6.5.1 Layout

Patterns live in two external repositories accessed via path/URL reference at session time (per Gate K.1.10):

**`6502-6809-conversion-patterns/`** (porting concerns):

```
6502-6809-conversion-patterns/
├── README.md                   # library structure, naming, versioning
├── shared/
│   ├── A-translation/          # General 6502→6809 translation
│   │   ├── A.1-register-mapping.md
│   │   ├── A.2-addressing-modes.md
│   │   └── ...
│   ├── B-idioms/               # Common 6502 idioms
│   │   ├── B.1-16bit-arithmetic.md
│   │   ├── B.2-pointer-deref.md
│   │   ├── B.3-self-modifying.md
│   │   ├── B.4-lookup-dispatch.md
│   │   └── ...
│   ├── D-hal/                  # HAL interaction patterns
│   │   ├── D.1-per-frame-sequence.md
│   │   ├── D.2-file-loading.md
│   │   └── ...
│   ├── E-devmode/              # DEV_MODE conditional assembly
│   │   └── ...
│   └── F-antipatterns/         # Anti-patterns: idioms to avoid
│       └── ...
└── project/
    ├── karateka/               # Karateka-specific Category C patterns
    │   ├── C.1-scene-dispatch.md
    │   ├── C.2-combat-animation-lookup.md
    │   ├── C.3-per-frame-update.md
    │   ├── C.4-body-part-composition.md
    │   └── ...
    └── pop/                    # POP-specific Category C patterns
        ├── C.1-state-machine.md
        └── ...
```

**`apple2-disasm-patterns/`** (disassembly methodology concerns):

```
apple2-disasm-patterns/
├── README.md
├── caller-chain-enumeration.md
├── anchored-grep.md
├── mid-instruction-label-detection.md
├── build-artifact-recognition.md
├── content-classification-protocol.md
├── trace-fire-analysis.md
├── round-trip-verification.md
└── ...
```

Three tiers visible across both repos:

- **shared/** (in `6502-6809-conversion-patterns`) — Categories A, B, D, E, F. Patterns applicable to both Karateka and POP port projects (and any future CoCo3 port using this methodology). Category F (anti-patterns) documents idioms to avoid, complementing the positive patterns in A/B/D/E.
- **project/<name>/** (in `6502-6809-conversion-patterns`) — Category C and project-specific extensions. Patterns tied to a single game's architecture.
- **apple2-disasm-patterns/** — Methodology patterns from Apple II reverse-engineering work. Useful for any disassembly project, not specific to porting.

#### 6.5.2 Pattern numbering

Pattern IDs are stable identifiers. Each pattern has a unique ID within its category:

- Shared categories use letter + number (A.1, A.2, B.1, B.2, ...)
- Project-specific patterns use project prefix + number (K.1, K.2 for karateka; P.1, P.2 for pop)
- Category C (engine architectural) lives under `project/` since engine architecture differs between games; each project has its own C.1, C.2, etc.

Pattern IDs do not change once assigned. New patterns get the next number; deprecated patterns are marked deprecated but remain at their ID.

#### 6.5.3 When a pattern surfaces in either project

The execution discipline:

1. **Discovery** — While porting a routine, a recurring idiom is recognized
2. **Classification** — Is this shared (general 6502→6809 or general CoCo3) or project-specific (engine-architectural for this game)?
3. **Place in correct tier** — shared/<category>/ or project/<name>/
4. **Cross-project review (for shared patterns)** — Before committing a new shared pattern, evaluate whether it applies to the other project. If yes, add cross-reference; if no, demote to project-specific
5. **Versioning** — Pattern documents have a version header; revisions bump the version

#### 6.5.4 Cross-project notification

When a shared pattern is added or revised, both projects' `project-state.md` files note the change with a one-line entry. This makes pattern updates visible during the next session for either project.

Mechanism (manual operation): pattern author appends entry to both state files in the same commit.

Mechanism (claude-bridge automation, future): a shared patterns/state.md is the source of truth; both projects' state files reference it.

#### 6.5.5 Shared pattern stability

Shared patterns are designed for stability. A pattern's documented canonical form should not change once the pattern is in use across both projects. Stability rules:

- **Additions are cheap.** New patterns can be added freely.
- **Refinements are reviewable.** Clarifying wording, adding examples, fixing typos: fine without notification.
- **Semantic changes are expensive.** If a pattern's canonical translation changes meaningfully, both projects must review the change and update any code written against the old form. Treat as a contract change.
- **Deprecation is allowed.** Mark deprecated; keep at original ID; provide migration note to replacement pattern.

#### 6.5.6 Initial pattern set

The initial shared pattern set is bootstrapped from pop-coco3 Section 6.13 (POP design v0.7). Categories A, B, D, E, F content moves to `patterns/shared/`. Category C content moves to `patterns/project/pop/`.

karateka-coco3 begins with the same shared patterns available and adds Category K (karateka-specific) as patterns surface during P2 work.

Initial bootstrap is a P1.5 deliverable for both projects (coordinated):
- karateka-coco3 P1.5: place initial shared pattern set in patterns/shared/, add patterns/project/karateka/ initial entries
- pop-coco3 P1.5 (if not yet executed): same layout; place initial Category C entries in patterns/project/pop/

If pop-coco3 has already begun P1 work with patterns in a different layout, the bootstrap includes migration.

#### 6.5.7 Category C — Engine architectural patterns

Engine architecture differs between games. Category C is project-specific, not shared. Examples:

**POP Category C (from pop-coco3 v0.7 Section 6.13.6):**
- C.1 — State machine advancement (prince, guard, sword, level state machines)
- C.2 — Animation sequence advancement (byte-array sequences)
- C.3 — Per-frame engine update structure
- C.4 — Room rendering
- C.5 — Collision detection
- C.6 — Input → action mapping
- C.7 — Sound trigger from state transitions

**Karateka Category C (initial draft, expanded during P2):**
- C.1 — Scene-driven dispatch (intro.s linear flow + scene_dispatch.s state machine for scene 5)
- C.2 — Combat animation lookup (action code $20 + frame $26 → tables at $6000-$63FF)
- C.3 — Per-frame update structure (similar to POP C.3 but smaller subsystem set)
- C.4 — Sprite rendering with body-part composition (run cycle, Akuma throne pose)
- C.5 — Jump-table dispatch (kernel $0780, gameplay $7000, render $7800/$7D00, combat $6780)
- C.6 — Input → combat action mapping (parallel to POP C.6 but Karateka-specific moves)
- C.7 — Build-artifact recognition (dead code + mid-instruction JSR targets)

Some Karateka C-patterns may turn out to apply to POP (or vice versa) on closer examination — if so, they get promoted to shared. The default placement is project-specific; promotion to shared requires confirming applicability in the other project.

#### 6.5.8 Karateka-specific shared pattern candidates

Patterns surfaced in karateka_dissasembly_claude that may be valuable shared additions (to be confirmed against pop-coco3 during P1):

- **Caller-chain enumeration** (methodology pattern: before porting a routine, grep all callers to understand the contract). Likely shared methodology pattern.
- **Anchored-grep** (technique for finding byte-level references without false positives). Likely shared.
- **Mid-instruction-label detection** (build-artifact signature). Probably project-specific (Mechner's development style).
- **Cross-segment branch handling** (.org directive workaround for ca65). Toolchain-specific; may be lwasm equivalent in CoCo3 context.

These get evaluated and placed during P1.5 bootstrap.

#### 6.5.9 Pattern review during cross-project work

When a pattern surfaces during work on either project:

1. Check if existing pattern covers the case (consult shared/ first, then project/)
2. If yes, follow the existing pattern; note any deviation as a candidate refinement
3. If no, classify (shared vs project-specific) and create
4. Document in the commit message which pattern was applied or created

The shared library becomes more valuable over time as both projects accumulate patterns. Velocity in P2/P3 work depends on the library being mature; investing in pattern discipline early pays off later.

---

---

### 6.6 Reference discipline

CoCo3 / 6809 information generation in karateka-coco3 must cite
project reference documentation or explicitly surface the absence
of a reference. This is binding for:

- HAL implementations (graphics, sound, input, file, time,
  memory, system)
- Engine code that touches platform-specific registers, timing,
  or conventions
- Memory map decisions
- DAC / sound programming
- GIME programming
- Floppy / disk I/O
- Boot-time CPU detection
- Any architectural decision dependent on platform behavior

Pure 6502 → 6809 instruction translation, platform-neutral engine
logic, and build tooling are not subject to this rule (those
follow their own discipline per Section 6.5 patterns).

The full discipline is documented in
`6502-6809-conversion-patterns/shared/G-methodology/G.1-reference-discipline.md`
(consumed by path/URL reference per Gate K.1.10).

#### 6.6.1 Reference document inventory

Authoritative references available in `docs/`:

| Reference | Short tag | Authority for |
|-----------|-----------|---------------|
| MC6809-MC6809E 8-Bit Microprocessor Programming Manual | MC6809 | CPU behavior, instruction semantics, cycle counts |
| 6809 Assembly Language Programming | 6809-ALP | Programming idioms, register/addressing-mode conventions |
| Color Computer Technical Reference Manual | CC3-TR | CoCo3 hardware, memory map, peripherals |
| Color Computer 3 Service Manual | CC3-SM | Hardware service-level detail, schematics |
| Lomont CoCo Hardware | Lomont | Community-augmented hardware reference, cross-check for CC3-TR |
| GIME Reference Manual | GIME-RM | GIME chip programming (graphics modes, palette, video timing) |
| Sockmaster GIME documentation | Sockmaster-GIME | GIME quirks and demoscene-derived empirical insights |
| Color BASIC Unravelled | CB-Unravelled | Color BASIC ROM internals and entry points |
| Extended BASIC Unravelled | EB-Unravelled | Extended BASIC ROM internals |
| Super Extended BASIC Unravelled | SEB-Unravelled | Super Extended BASIC (CoCo3-specific) ROM internals |
| Disk BASIC Unravelled | DB-Unravelled | RSDOS / Disk BASIC, file system, disk I/O |

#### 6.6.2 Citation format

Inline in source comments and commit messages:

    [ref: <short-tag> <section-or-page>]

Examples:
- `[ref: MC6809 §4.5]`
- `[ref: CC3-TR §6.3]`
- `[ref: GIME-RM §3.2]`
- `[ref: Sockmaster-GIME, "Palette"]`
- `[ref: CB-Unravelled p.187]`

#### 6.6.3 Surfacing absent reference

When a decision is made without a covering reference, mark it
explicitly:

    ; [no-ref: brief description of what's unverified]

Examples:
- `; [no-ref: optimal VBL polling pattern not yet verified]`
- `; [no-ref: assumed 6309 NSC behavior matches 6809]`

This creates an audit trail. When real-hardware testing reveals
a problem, we can quickly identify which decisions need revisit.

#### 6.6.4 Conflict resolution

When references disagree, document both interpretations and the
chosen one with reasoning. Example pattern:

    ; [ref: CC3-TR §6.3] GIME palette write timing unrestricted
    ; [ref: Sockmaster-GIME, "Palette"] empirical: writes during
    ;   active scanline cause artifact
    ; → schedule writes during VBL per Sockmaster's empirical
    ;   observation; Tandy's spec is permissive but doesn't
    ;   address the artifact

If real-hardware testing later reveals one interpretation was
wrong, the audit trail identifies the specific decision to
revisit.

#### 6.6.5 Calibration phase emphasis

During karateka-coco3's calibration phase (first 10-20 tasks),
reference discipline applies rigorously. The discipline becomes
habitual through repeated application; early laxness creates
precedent that's harder to correct later.

#### 6.6.6 Cross-references

- Pattern definition: `6502-6809-conversion-patterns/shared/G-methodology/G.1-reference-discipline.md`
- Related discipline (approach-level): `apple2-disasm-patterns/plan-deviation-discipline.md`
- Related discipline (gate-level): `apple2-disasm-patterns/blocking-gate-discipline.md`

### 6.7 Content-Conversion Visual Verification

Each Apple II content asset converted for CoCo3 use is verified through human visual
review at conversion time, before the converted assemblable form is committed for
engine use.

#### 6.7.1 Rationale

Cross-platform content conversion is not pixel-equivalence — the CoCo3 (320×192,
4 colors) cannot exactly reproduce the Apple II (280×192, 6 colors with half-pixel
constraints). The "correct" conversion is a *fair representation* given platform
differences, not a bit-exact match. There is no behavioral verification (compare.py
and the P2.0 infrastructure handle engine state, not content fidelity). Human visual
review is the appropriate verification mechanism for content fidelity.

Without conversion-time visual review, content bugs would surface during integration
testing, requiring backwards debugging through engine ports + HAL implementations +
content conversion to find the actual cause. Visual review at conversion time catches
content bugs at their source.

#### 6.7.2 Protocol

Each converted content asset produces three artifacts:

1. **Apple II reference PNG** — rendered from the original Apple II content via
   `sprite_render_apple2.py` (the independent decoder from P1.2 follow-up; not
   downstream of the converter being tested)
2. **CoCo3 converted PNG** — rendered from the converted CoCo3 bytes via
   `sprite_visualize.py` (also an independent decoder)
3. **CoCo3 assemblable `.s` file** — the actual engine deliverable

Human review compares (1) and (2) side by side, asking: "Is this recognizably the
same image, with expected platform differences?" If yes, (3) gets committed for
engine use. If no, the converter is debugged before re-running.

#### 6.7.3 Sound exception

Sound conversion (Apple II speaker click data → CoCo3 DAC samples or tone-record
data) has no natural visual analog. Produces WAV file pairs instead — Apple II
reference WAV + CoCo3 converted WAV — for human ear comparison. Same approval gate.

#### 6.7.4 Workflow

Content conversion proceeds in waves scoped to integration milestones (Section 7.4.3).
Each wave:

1. Identifies the assets needed (e.g., for INT-1: Brøderbund logo sprite,
   title-screen palette, etc.)
2. Runs conversion + paired-PNG/WAV generation
3. Produces a structured output directory:
   ```
   content/<asset>/
       apple2.png
       coco3.png
       converted.s
   ```
4. Generates a summary view (HTML or markdown index) showing all pairs for quick
   visual scanning
5. Human review: scan all pairs, approve or flag bugs
6. Approved `.s` files commit for engine use; flagged pairs trigger converter fixes
   (P1.2 tooling work)

#### 6.7.5 Pattern promotion candidate

This protocol is karateka-coco3-specific now but will likely transfer to pop-coco3
(the sibling port project, which faces the same Apple II → CoCo3 content conversion
challenge). After the first content-conversion wave exercises this protocol and
surfaces any refinements, it is a candidate for promotion to a shared pattern in
`6502-6809-conversion-patterns` for both projects to consume.

## 7. Phase plan

### 7.1 Phase overview

| Phase | Description | Estimated duration | Gate |
|-------|-------------|-------------------|------|
| P0 | Reference oracle | Intro-time complete; gameplay-states ongoing in parallel | Partial — intro-time territory closed via karateka_dissasembly_claude M1/M2 |
| P1 | Foundations | 4-8 weeks | End-of-P1 review gate |
| P2 | Engine port | 8-16 weeks | End-of-P2 review gate |
| P3 | HAL implementations | 4-8 weeks | End-of-P3 review gate |
| P4 | Integration + content | 4-8 weeks | End-of-P4 review gate |
| P5 | Release prep | 2-4 weeks | Release decision |

Total: ~22-44 weeks calendar time at sustainable pace. P0 work in karateka_dissasembly_claude runs concurrently with karateka-coco3 P1-P4 phases.

### 7.2 P0 — Reference oracle (PARTIAL; ongoing in karateka_dissasembly_claude)

Phase 0 closure for karateka-coco3 is two-part:

**P0a — Intro-time territory (COMPLETE 2026-05-12 via karateka_dissasembly_claude M1/M2):**

- 100% of intro-time RAM in src/ (32,256 bytes, 38 files, from dump01_intro.bin)
- Bootable disk reassembled from src/, gameplay verified
- Smoke test infrastructure (per-range round-trips, memory image reconstruction, sector overlay)
- All architectural findings documented for intro-time content (scene dispatch, combat pipeline, sprite system, etc.)

**P0b — Gameplay-state territory (ONGOING in karateka_dissasembly_claude):**

karateka_dissasembly_claude continues capturing memory dumps at distinct gameplay states and disassembling the code/data that overlays or extends what's in dump01_intro.bin. Expected dumps:

- dump04_castle_entry — courtyard entry (post-cliff approach)
- dump07_first_fight — first opponent combat state
- dumpNN_throne_room — final fight with Akuma
- Additional dumps as scene transitions surface new content

For each new dump, karateka_dissasembly_claude:

1. Identifies regions that differ from dump01_intro.bin (new or modified)
2. Disassembles those regions using established methodology (caller-chain enumeration, trace fires, content classification)
3. Adds new src/*.s files or extends existing ones with multi-segment definitions per dump-of-origin
4. Verifies round-trip byte-identity for the new dump
5. Documents the dump-to-content mapping

karateka_dissasembly_claude's existing tagging convention (every routine carries its dump-of-origin tag) supports multi-dump src/ organization. See karateka_dissasembly_claude instructions.md Section 4.

**P0b closure criterion:** all dumps required for v1.0 gameplay are captured and disassembled with round-trip verification. Specific dump list determined during P0b execution.

**Dependency on karateka-coco3 phases:**

- karateka-coco3 P1 (foundations) does not depend on P0b — only on P0a
- karateka-coco3 P2 (engine port) can proceed for subsystems fully captured in P0a
- karateka-coco3 P2 work on subsystems whose code is in gameplay-state dumps waits for the relevant P0b coverage
- karateka-coco3 P4 (per-scene content) requires the corresponding P0b dumps to be complete

This parallel structure means P0b doesn't block karateka-coco3 startup. The two projects' work interleaves, with karateka_dissasembly_claude staying ahead of karateka-coco3's content needs.

### 7.3 P1 — Foundations

**P1.0 — Project state setup**
- Create karateka-coco3 repository structure per Section 11.4
- Verify `../karateka_dissasembly_claude/` exists at sibling directory (reference oracle access)
- Verify `../6502-6809-conversion-patterns/` and `../apple2-disasm-patterns/` exist at sibling directories (after pattern repos bootstrap per Section 11.8)
- Establish `docs/project-state.md` (methodology state file)
- Initialize cross-project coordination protocol per Section 11.3

**P1.1 — MAME test harness**
- CoCo3 MAME instrumentation (Lua scripts adapted from karateka_dissasembly_claude)
- Three rigor levels: smoke, demo-loop, scripted-playback
- Both 128K and 512K configurations tested

**P1.2 — Asset conversion tooling**
- Sprite converter (Apple II hi-res → CoCo3 GIME 4-color)
- Sound converter (Apple II PCM samples → 6-bit DAC format)
- Palette derivation per scene
- Tooling docs: `tools.md`

**P1.3 — HAL contract**
- `hal.inc` (assembly-syntactic contract)
- `hal.md` (human-readable companion)
- Function reference, conventions, data formats

**P1.4 — Engine conventions**
- `conventions.md`
- Register usage, naming, comments, ZP allocation
- Karateka-specific conventions (body-part composition, animation indexing, jump tables)

**P1.5 — Pattern library bootstrap (cross-project)**
- Contribute karateka-specific Category C patterns to `6502-6809-conversion-patterns/project/karateka/`
- Coordinate with pop-coco3 on shared category (A, B, D, E, F) bootstrap to `6502-6809-conversion-patterns/shared/`
- Contribute karateka_dissasembly_claude methodology patterns to `apple2-disasm-patterns/` (caller-chain enumeration, anchored-grep, etc.)
- Pattern path/URL references documented in karateka-coco3 docs
- Linter for engine convention compliance (per pop-coco3 P1.4 sub-deliverable) if applicable

**P1.6 — Memory map**
- Final CoCo3 memory layout
- DP allocation
- Engine vs HAL vs frame buffer placement
- 128K and 512K variants

**End-of-P1 review gate.** Foundations complete, calibration phase status assessed, P2 readiness confirmed.

### 7.4 P2 — Engine port

#### 7.4.1 P2 target deliverable

> **P2 target deliverable:** a bootable CoCo3 disk that loads and runs the complete
> intro/attract sequence (Brøderbund logo → title screen → cliff approach scene →
> demo combat → Akuma throne room cutscene → loop), matching Apple IIe behavior
> within unavoidable cross-platform differences (4-color GIME palette vs 6-color
> Apple II hires; DAC sound vs Apple speaker; GIME timing vs Apple II VBL).

#### 7.4.2 Three converging workstreams

P2 runs three workstreams in parallel that converge at integration milestones (Section 7.4.3):

**P2.x — Engine subsystem ports** against smart HAL stubs. Each port is verified
per-subsystem via P2.0 infrastructure (Apple II capture + CoCo3 capture +
compare.py against mapping.json). P2.1 (timer/frame-sync) is complete; P2.2+
continue with remaining subsystems, ordered by a scoping pass before each
milestone.

Individual P2.x subsystem targets (order refined during scoping pass; P2.2+ TBD):
- **P2.1 — Timer/frame-sync** (timer_dispatch.s → engine/timer.s + HAL interface) — COMPLETE (2026-05-14)
- **P2.2+** — remaining subsystems, ordered by scoping pass per integration milestone

Subsystem candidates (portable surface; see Section 7.4.4):
- Blit/graphics (display_7700.s, attract_*.s → engine/display.s + HAL interface)
- Sound triggering (sound_engine.s + pcm_player.s → engine/sound.s + HAL interface)
- Scene management + scene transitions (scene_dispatch.s, intro.s → engine/scene.s)
- Display setup / palette
- Basic keyboard scan (input.s → engine/input.s + HAL interface)
- Combat animation playback (fight_engine.s + animation tables → engine/combat.s)
- Sprite composition / body-part assembly
- Cutscene machinery
- Kernel/dispatch (kernel.s, kernel_per_frame.s, kernel_dispatch_handlers.s → engine/kernel.s)

Each subsystem has its own review gate per methodology Section 4.3.

**P3.x — Real HAL implementations** replacing stubs. Begins in parallel with P2.x
after P2.2 lands (P2.2 surfaces any remaining HAL contract gaps before real
implementation commits). Each P3.x implementation verified against the smart-stub
behavior plus hardware-correctness (real VBL fires at GIME VBL, real palette writes
during VBL, etc.). See Section 7.5 for P3 detail.

**Content conversion** — Apple II sprite/palette/sound assets converted to CoCo3
assemblable form via P1.2 tooling. Each conversion wave produces paired visual
verification artifacts (Apple II PNG + CoCo3 PNG, or WAV pair for sound) for human
review before content is committed for engine use. Conversion proceeds in waves
scoped to integration milestones — convert what's needed for each milestone, not
all-at-once. Protocol: Section 6.7.

#### 7.4.3 Integration milestones

Integration milestones are convergence checkpoints where P2.x + P3.x +
content-conversion subsystems combine into a running deliverable. Naming uses
`INT-N` prefix to distinguish from karateka_dissasembly_claude's disassembly
milestones (M1/M2/M3/M4).

- **INT-1:** First scene displays correctly. Requires engine ports + real HAL for:
  scene management (basic), display setup, palette, blit/graphics. Content: first-scene
  assets converted (Brøderbund logo + palette). Verification: human visual inspection
  against Apple II reference rendering.
- **INT-2:** Logo → title → cliff scene sequence with transitions. Adds: scene-transition
  machinery (frame_countdown, disk_load_trigger handling), additional scenes' content
  assets converted.
- **INT-3:** Full attract cycle including sound, cutscenes. Adds: sound HAL real
  implementation, tone-record interpreter, cutscene-specific machinery, Akuma throne
  room composition + content. Target deliverable: bootable disk looping the complete
  attract sequence (= P2 target deliverable).

#### 7.4.4 Portable vs P0b-dependent subsystems

**Portable from current M1/M2 disassembly** (exercised by the intro/attract
sequence; available now without P0b):
- Timer/frame-sync (P2.1 — COMPLETE)
- Blit/graphics
- Sound (attract music + demo SFX)
- Scene management including scene transitions
- Display setup / palette
- Basic keyboard scan (attract→gameplay break-out poll)
- Combat animation playback (demo fight visuals)
- Sprite composition / body-part assembly (Akuma throne pose)
- Cutscene machinery (Akuma throne room cutscene)
- Kernel/dispatch

**Waiting for P0b coverage** (only reachable through actual gameplay; wait for
relevant karateka_dissasembly_claude dumps):
- Combat input mapping (key codes → combat actions)
- Player-driven scene state machines (cliff/courtyard/throne gameplay loops)
- Win/lose ending sequences
- Code paths reached only via player decisions

**End-of-P2 review gate.** Engine ported; INT-3 delivered (bootable attract disk loops correctly).

### 7.5 P3 — HAL implementations

**P3.1 — coco3-dsk HAL implementation**
- All HAL subsystems implemented for RSDOS floppy target
- Per-subsystem review gates

**P3.2 — Optimization layer**
- 6809 + 6309 implementations of hot routines (expected 2-3 routines)
- Boot-time CPU detection integration

**End-of-P3 review gate.** HAL complete, all subsystems integrated, gameplay verifiable on coco3-dsk target.

### 7.6 P4 — Integration + content

**P4.1 — Sprite conversion runs**
- All Karateka sprite banks (8 banks, ~263 sprites) converted to CoCo3 format
- Visual sweep verification (some of this is post-M1 backlog from karateka_dissasembly_claude)

**P4.2 — Sound conversion runs**
- All sound assets converted

**P4.3 — Scene-by-scene gameplay validation**
- Intro sequence (5 scenes)
- Cliff approach
- Courtyard combat
- Throne-room final fight
- Win/lose endings

**End-of-P4 review gate.** v1.0 feature-complete.

### 7.7 P5 — Release prep

**P5.1 — Documentation finalization**
- `release-notes-v1.0.md`
- Build instructions for community contributors

**P5.2 — Real-hardware verification**
- Actual CoCo3 hardware test (not just MAME)
- Both 6809 and 6309 systems if available
- Both 128K and 512K configurations

**P5.3 — Release**
- Source published to public repository
- Binary release for community

**Release decision.** Ship v1.0.

---

## 8. Open questions

To be resolved during P1 execution. Initial inventory:

### 8.1 Architectural

- **Sprite format conversion specifics.** Apple II hi-res sprite format (height byte, width byte, row-major bitmap) → CoCo3 GIME 4-color format. Conversion algorithm needs design.
- **Palette derivation per scene.** Which 4 colors per scene? Source from Apple II's visual content + designer intent + GIME palette.
- **Animation table format.** Karateka's 22 tables × 42 entries at $6000-$63FF index by ($20 action code, $26 animation frame). Format on CoCo3 likely identical structure but possibly different stride.

### 8.2 Engineering

- **Hot path performance.** render_frame_0a00 fires 262K times per frame on Apple II at 1 MHz. CoCo3 6809 at 1.79 MHz has more headroom but 4-color GIME blit might be slower per-pixel. Profile early.
- **Frame budget.** Karateka runs at ~30 FPS effective on Apple II (per-frame routines fire 60×/sec for VBL but game logic at 30Hz). CoCo3 target similarly.
- **Disk layout.** Single-file BLOAD-equivalent vs multi-file? RSDOS conventions vs custom layout.

### 8.3 Methodology

- **Calibration phase length.** pop-coco3 expects 20-50 tasks. Karateka may be shorter (10-20 tasks) due to smaller scope.
- **Pattern reuse from pop-coco3.** Which patterns transfer directly? Which need karateka-specific variants?

### 8.4 From karateka_dissasembly_claude carry-over

Open items from karateka_dissasembly_claude that may matter for porting:

- **Q016 sub-questions** (axis/direction encoding in $60-$6F / $70-$7F clusters). May surface during gameplay porting; resolve as encountered.
- **$11C1/$11D8 scene-draw callers** (zero-fire entries with unknown callers). May be gameplay-only paths; resolve during P2.
- **$07FA-$07FF / $BFFA-$BFFF dual sync stubs.** May or may not be relevant to port.
- **$07E4-$07F9 22-byte data table purpose.** Resolve during P2 kernel port.
- **Visual sweep backlog** (~7,300 bytes across 6 pre-visualizer sprite banks). Resolved during P4 sprite conversion (visual review happens as part of conversion verification).

### 8.5 P0b cross-project sequencing

Questions related to the parallel-running P0b (gameplay-state disassembly) work in karateka_dissasembly_claude:

- **Dump capture order.** Which gameplay states should be captured first? Likely sequence: courtyard combat (covers most gameplay code) → throne room (final fight specifics) → cliff approach (scene-transition specifics) → win/lose ending states. To be confirmed by karateka_dissasembly_claude Q-entries.
- **Multi-dump src/ organization.** karateka_dissasembly_claude's tagging convention requires every routine to carry its dump-of-origin. When a routine appears in multiple dumps with different content (overlay loaded over earlier content), how is this organized in src/? Existing instructions.md Section 4 covers tagging; specific multi-segment layout determined as gameplay-state work proceeds.
- **Round-trip verification per dump.** Each new dump needs its own round-trip target. karateka_dissasembly_claude's build_disk.py three-phase pipeline currently verifies against dump01_intro.bin only. Extension needed to verify against multiple dumps.
- **Reassembled disk completeness.** The intro-time karateka_fresh.dsk boots and reaches gameplay because the cracker's loader handles the disk-to-RAM transfer. As gameplay-state content gets disassembled, when does the reassembled disk's GAMEPLAY portion (not just intro) become byte-derivable from src/? Likely a karateka_dissasembly_claude M3 or M4 milestone.
- **karateka-coco3 P2 dependency graph.** Which P2 subsystem ports depend on which P0b dumps? Map subsystems to gameplay states. Build dependency graph showing which ports can proceed in parallel vs which wait for upstream P0b.

---

## 9. Documentation deliverables

Documents produced during the project:

**Phase 0a (complete, in karateka_dissasembly_claude repo):**
- karateka_dissasembly_claude repository at M1/M2 closure state (intro-time territory)

**Phase 0b (ongoing in karateka_dissasembly_claude, deliverables accrue during karateka-coco3 P1-P4):**
- karateka_dissasembly_claude src/ expansions covering gameplay-state dumps
- karateka_dissasembly_claude reassembled .dsk artifact including gameplay code/data (not just intro-time content)
- karateka_dissasembly_claude completeness milestones (gameplay-state coverage analogous to M1)

**Phase 1:**
- `karateka-coco3-design-v0.1.md` — this document
- `docs/hal.md` — HAL contract companion (src/hal.inc is the syntactic form)
- `docs/conventions.md` — engine conventions
- `docs/memory-map.md` — final CoCo3 memory layout
- `docs/sprite-format.md` — CoCo3 sprite format specification
- `docs/harness.md` — MAME harness implementation documentation
- `docs/tools.md` — conversion tooling documentation
- `docs/project-state.md` — methodology state file
- External: contributions to `6502-6809-conversion-patterns/project/karateka/`
- External: contributions to `apple2-disasm-patterns/` (from karateka_dissasembly_claude experience)

**Phase 2+:**
- `engine-architecture.md` — engine internals
- Per-subsystem documentation as subsystems complete
- `release-notes-v1.0.md` — at release

Cross-references maintained:
- karateka_dissasembly_claude repository (the reference oracle)
- pop-coco3-design-v0.7.md (parent methodology binding)
- claude-orchestrated-methodology-v0.2.md (methodology reference)
- GIME white-room specs (external)
- CoCo3 hardware references (TBD)
- lwasm reference (external)

---

## 10. Project state and gates

### 10.1 Current state

- Methodology version: v0.2 (inherited from pop-coco3)
- Project phase: P0a complete (intro-time territory), P0b ongoing in karateka_dissasembly_claude (gameplay-state territory), P1 not started
- Last design update: May 12, 2026

### 10.2 Closed gates

All gates required to begin P1 are closed:
- K.1.0 — Source baseline (karateka_dissasembly_claude src/)
- K.1.1 — Graphics target (320×192×4)
- K.1.2 — HAL targets (single for v1.0, multi for v2.0)
- K.1.3 — CPU support (boot-time detection)
- K.1.4 — Memory target (128K min, 512K leveraged)
- K.1.5 — Sound (DAC default, simpler than POP)
- K.1.6 — Copy protection (none, source already clean)
- K.1.7 — Test harness as P1 deliverable 1
- K.1.8 — Methodology binding (CODM v0.2)
- K.1.9 — Shared pattern repos (6502-6809-conversion-patterns + apple2-disasm-patterns)
- K.1.10 — Five-repo topology with sibling-path consumption for karateka_dissasembly_claude; path/URL reference for pattern repos

### 10.3 Open gates

None at the design level. P1 will surface detail-level questions resolved during P1 execution.

### 10.4 Review gates within phases

Per methodology Section 4:

- End of P1 (foundations complete, calibration status)
- End of P2 (engine ported)
- End of P3 (HAL complete)
- End of P4 (v1.0 feature-complete)
- Release decision at end of P5
- Subsystem boundaries within phases have their own review gates

---

## 11. Repository topology

Per Gate K.1.10, the karateka-coco3 project participates in a five-repo ecosystem. This section specifies access mechanisms and coordination protocols.

### 11.1 Repository inventory

| Repository | Role | Owner | Status |
|-----------|------|-------|--------|
| `karateka_dissasembly_claude` | Apple II reverse engineering; reference oracle | Jay | M1/M2 complete; P0b ongoing |
| `karateka-coco3` | Karateka 6809 port (this project) | Jay | New, P1 not started |
| `pop-coco3` | POP 6809 port | Jay | P0 complete; P1 may be in progress |
| `6502-6809-conversion-patterns` | Shared porting pattern library | Jay | New, bootstrap during P1.5 |
| `apple2-disasm-patterns` | Apple II disassembly methodology library | Jay | New, bootstrap from karateka_dissasembly_claude patterns |

### 11.2 Consumption mechanisms

**karateka_dissasembly_claude → karateka-coco3 (path reference, no git coupling):**

karateka-coco3 expects karateka_dissasembly_claude to be checked out at a sibling directory path (convention: `../karateka_dissasembly_claude/`). karateka-coco3's tooling, documentation references, and Claude Code task contexts assume this path.

When karateka_dissasembly_claude advances (gameplay-state dumps disassembled, new src/ added), the changes are immediately visible to karateka-coco3 — no submodule pointer to update, no version pin. The developer (or Claude Code session) consults karateka_dissasembly_claude at its current HEAD when porting work needs reference oracle content.

Tradeoffs:

- **Loss:** Reproducibility — a specific karateka-coco3 commit doesn't lock down what karateka_dissasembly_claude src/ it referenced
- **Gain:** Operational simplicity — no submodule machinery, no update steps, no detached HEAD confusion
- **Mitigation:** karateka-coco3 commit messages document which karateka_dissasembly_claude content was referenced when significant; major karateka_dissasembly_claude advances trigger a karateka-coco3 sync-point commit that captures the consuming project's awareness

For solo-developer hobby-project scale, this tradeoff favors operational simplicity. Reproducibility matters most for distributed teams or production CI; here it's overhead without commensurate value.

**`6502-6809-conversion-patterns` → karateka-coco3 (path/URL reference, no coupling):**

karateka-coco3 references patterns by name/path in task contexts. Claude Code reads pattern docs when relevant to a task. No git submodule, no embedded copy, no version pinning. Updates to patterns are immediately visible.

**`apple2-disasm-patterns` → karateka-coco3 (path/URL reference, no coupling):**

Same as above. Methodology patterns are read when relevant.

**`6502-6809-conversion-patterns` ↔ `pop-coco3` (path/URL reference, no coupling):**

Symmetric to karateka-coco3.

**`apple2-disasm-patterns` ↔ `karateka_dissasembly_claude` (path/URL reference, no coupling):**

karateka_dissasembly_claude work draws from `apple2-disasm-patterns` and contributes to it as new methodology patterns surface.

### 11.3 Cross-project coordination protocol

**Pattern updates:**

When a pattern is added, refined, or revised in either pattern repo:

1. Commit lands in the pattern repo
2. The author appends a one-line entry to relevant consuming projects' `project-state.md` files (manual mechanism)
3. Consuming projects' next sessions see the entry and consult the updated pattern as needed

Future automation (claude-bridge, etc.) may make this propagation more visible without changing the underlying mechanism.

**Reference oracle updates:**

When karateka_dissasembly_claude advances:

1. karateka_dissasembly_claude commits new src/ content to its repo
2. karateka-coco3 (when ready to consume) optionally captures a sync-point commit per Section 11.6
3. karateka-coco3 sync-point commit message documents which port work the new content unblocks
4. Any in-progress karateka-coco3 work referencing the changed area is re-validated

**Methodology updates:**

If CODM (Claude-Orchestrated Development Methodology) is revised:

1. Methodology repo or document is updated
2. All projects' design docs note the version bump in their next design-doc revision
3. Methodology lessons learned in any project propagate to the methodology document

### 11.4 Directory conventions within karateka-coco3

```
karateka-coco3/
├── README.md                          # quick start
├── docs/
│   ├── karateka-coco3-design-v0.1.md  # this document
│   ├── hal.md                         # HAL contract companion
│   ├── conventions.md                 # engine conventions
│   ├── memory-map.md                  # CoCo3 memory layout
│   ├── sprite-format.md               # CoCo3 sprite format
│   ├── tools.md                       # tooling docs
│   ├── harness.md                     # MAME harness docs
│   ├── project-state.md               # methodology state file
│   └── milestones.md                  # P1-P5 status
├── src/
│   ├── hal.inc                        # HAL contract (assembly)
│   ├── engine/                        # platform-neutral engine code
│   │   ├── kernel.s
│   │   ├── scene.s
│   │   ├── gameplay.s
│   │   ├── combat.s
│   │   ├── input.s
│   │   ├── display.s
│   │   ├── sound.s
│   │   └── timer.s
│   ├── opt/                           # optimization layer
│   │   ├── 6809/
│   │   │   ├── render_frame_blit.s
│   │   │   └── vbl_sync.s
│   │   └── 6309/
│   │       ├── render_frame_blit.s
│   │       └── vbl_sync.s
│   └── hal/                           # HAL implementations
│       └── coco3-dsk/                 # v1.0 target
│           ├── memory.s
│           ├── time.s
│           ├── gfx.s
│           ├── input.s
│           ├── file.s
│           ├── sound.s
│           └── system.s
├── content/                           # converted assets
│   ├── sprites/                       # CoCo3-format sprite data
│   ├── sound/                         # CoCo3-format sound data
│   └── palettes/                      # per-scene GIME palettes
├── tools/                             # conversion + build tooling
│   ├── sprite_convert.py
│   ├── sound_convert.py
│   ├── palette_derive.py
│   └── build_coco3.py
├── harness/                           # MAME test harness
│   ├── smoke/                         # rigor level 1
│   ├── demo/                          # rigor level 2
│   └── scripted/                      # rigor level 3
├── build/                             # build outputs (gitignored)
├── dist/                              # release artifacts (gitignored)
└── session-notes/                     # per-session handoff
```

Reference oracle access: `../karateka_dissasembly_claude/` (sibling directory, no embedded copy).
Pattern repo access: `../6502-6809-conversion-patterns/` and `../apple2-disasm-patterns/` (sibling directories).

### 11.5 Pattern repo references (no embedding)

Patterns are referenced by full path or URL in task contexts, never copied into karateka-coco3:

- `6502-6809-conversion-patterns/shared/B-idioms/B.1-16bit-arithmetic.md`
- `6502-6809-conversion-patterns/project/karateka/C.4-body-part-composition.md`
- `apple2-disasm-patterns/caller-chain-enumeration.md`

Claude Code's task context construction (per methodology Section 5) includes pattern paths/URLs as references. The patterns themselves are not bundled into karateka-coco3's repo.

### 11.6 Karateka-disasm sibling-path convention

**Initial setup (P1.0):**

When initializing karateka-coco3 work, the developer checks out both repos at sibling directories:

```
~/projects/
├── karateka_dissasembly_claude/          # existing
├── karateka-coco3/           # new (this project)
├── pop-coco3/                # Jay's other project
├── 6502-6809-conversion-patterns/   # new
└── apple2-disasm-patterns/   # new
```

karateka-coco3's tooling, documentation, and task contexts assume `../karateka_dissasembly_claude/` is accessible. No git-level coupling between the repos.

**Working with karateka_dissasembly_claude advances:**

When karateka_dissasembly_claude advances (gameplay-state dumps disassembled, new src/ added):

```
cd ../karateka_dissasembly_claude
git pull
cd ../karateka-coco3
# karateka_dissasembly_claude's new content is now visible at ../karateka_dissasembly_claude/src/
```

No karateka-coco3 commit required. The reference oracle update is operational, not architectural.

**Documenting significant syncs:**

When karateka_dissasembly_claude advances substantively (e.g., a new gameplay-state dump completes its disassembly), karateka-coco3 may capture awareness via a sync-point commit:

```
cd karateka-coco3
git commit --allow-empty -m "Note karateka_dissasembly_claude advance: <description>

karateka_dissasembly_claude at commit <hash> now includes:
- New src/ files for <subsystem>
- Round-trip verified for <dump>
- Unblocks karateka-coco3 P<N>.<M> work on <subsystem>"
```

This is optional but recommended for substantive advances; documents the cross-project relationship without coupling git histories.

**Verification:**

When consulting karateka_dissasembly_claude src/, the work should be at a commit where karateka_dissasembly_claude's smoke test PASSes — i.e., the karateka_dissasembly_claude state is a valid reference oracle. Consulting karateka_dissasembly_claude src/ at a broken state could propagate errors.

### 11.7 Build reproducibility

Given the topology, a karateka-coco3 build is reproducible if:

- karateka-coco3 repo at a specific commit
- `../karateka_dissasembly_claude/` at a known commit (recorded externally; e.g., in karateka-coco3 commit messages at substantive sync points)
- `6502-6809-conversion-patterns` and `apple2-disasm-patterns` at any version (patterns are documentation, don't affect build output)
- Build toolchain (lwasm, Python, etc.) at compatible versions

The path-reference consumption mechanism means karateka_dissasembly_claude's version isn't pinned in karateka-coco3's repo. Reproducibility requires external tracking — the developer (or the karateka-coco3 commit messages at sync points) records which karateka_dissasembly_claude commit corresponds to a given karateka-coco3 state.

For a solo-developer hobby project, this informal tracking is sufficient. For distributed work or production CI, the submodule alternative (rejected per Gate K.1.10) would provide stronger reproducibility at the cost of operational complexity.

The patterns repos affect *how* the build content was created (via the porting work) but not the build output itself.

### 11.8 Pattern repo bootstrap protocol

Both pattern repos (`6502-6809-conversion-patterns` and `apple2-disasm-patterns`) need initial population before karateka-coco3 P1.5 and pop-coco3 P1.5 can consume them. The bootstrap is treated as standalone work, not coupled to either consuming project's phase plan.

**Bootstrap Task 1 — `6502-6809-conversion-patterns` initial population:**

Source: pop-coco3-design-v0.7.md Section 6.13 content (categories A, B, D, E, F patterns documented as outline form).

Activities:
- Create new repository `6502-6809-conversion-patterns`
- Set up directory structure per Section 6.5.1 layout
- Extract each pattern from pop-coco3-design Section 6.13 to its own `.md` file
- Format consistently: title, description, before (6502), after (6809), notes
- Place in appropriate `shared/<category>/` directory
- Create empty `project/karateka/` and `project/pop/` directories with README.md placeholders for future contributions
- Initial README.md documenting library structure, naming convention, versioning, contribution protocol

Estimated effort: 2-4 hours mechanical extraction work.

Owner: standalone task; could be performed by anyone with the source design doc. Most natural to land as one focused commit to the new repo.

**Bootstrap Task 2 — `apple2-disasm-patterns` initial population:**

Source: karateka_dissasembly_claude session history, instructions.md, and accumulated methodology lessons.

Activities:
- Create new repository `apple2-disasm-patterns`
- Extract methodology patterns:
  - caller-chain-enumeration
  - anchored-grep
  - mid-instruction-label-detection
  - build-artifact-recognition (the four documented cases as exemplars)
  - content-classification-protocol
  - trace-fire-analysis
  - round-trip-verification
  - visualizer-vs-mechanical-sprite-identification
  - multi-dump-tagging-convention
  - plan-deviation-discipline (the methodology lesson from the sector-overlay commit)
- Format consistently
- Initial README.md

Estimated effort: 3-5 hours.

Owner: standalone task.

**Sequencing:**

Bootstrap tasks should complete before karateka-coco3 P1.5 begins. karateka-coco3 P1.0-P1.4 can proceed without the bootstrap (patterns become available later in P1).

Pop-coco3 P1.5 can begin after Task 1 completes. Pop-coco3's contribution is then populating `project/pop/` with POP-specific Category C patterns.

**Bootstrap as plan-and-review work:**

Each bootstrap task follows the same methodology as karateka_dissasembly_claude commits: filed verification plan before execution, review verdict against predictions, commit message documenting findings. The bootstrap tasks are simpler than disassembly work but the discipline pattern applies.

---

## Appendix A: Quick reference

### A.1 Key facts

- Game: Karateka (1984) by Jordan Mechner
- Source: karateka_dissasembly_claude repository (Jay's clean-room disassembly)
- Source language: 6502 assembly (ca65 dialect)
- Target platform: Tandy Color Computer 3
- Target CPU: 6809 (with 6309 optimization layer)
- Target memory: 128KB minimum, 512KB leveraged
- Target graphics: 320×192×4 (GIME CRES=01)
- Target OS: bare-metal RSDOS (v1.0)
- Methodology: Claude-Orchestrated Development v0.2 (inherited from pop-coco3)
- Estimated timeline: 3-9 months to v1.0

### A.2 Gate quick reference

| Gate | Decision |
|------|----------|
| K.1.0 | karateka_dissasembly_claude src/ as canonical source |
| K.1.1 | 320×192×4 with per-scene palettes |
| K.1.2 | Single HAL target for v1.0 (coco3-dsk); multi-target deferred to v2.0 |
| K.1.3 | Single binary, boot-time CPU detection, dispatch tables |
| K.1.4 | 128K min, 512K leveraged; both tested on every build |
| K.1.5 | Sound v1 DAC default, simpler than POP |
| K.1.6 | No copy protection (source already clean) |
| K.1.7 | MAME harness as P1 deliverable 1 |
| K.1.8 | CODM v0.2 inherited from pop-coco3 |
| K.1.9 | Shared patterns hosted in `6502-6809-conversion-patterns` repo; disasm methodology in `apple2-disasm-patterns` |
| K.1.10 | Five-repo topology: karateka_dissasembly_claude via sibling path-reference; pattern repos via path/URL reference |

### A.3 File naming conventions

- Design docs: `karateka-coco3-<topic>-v<version>.md`
- HAL implementations: `src/hal/coco3-dsk/<subsystem>.s`
- Engine code: `src/engine/<subsystem>.s`
- Optimization layer: `src/opt/<cpu>/<routine>.s`
- Reference oracle (sibling path): `../karateka_dissasembly_claude/src/<file>.s`
- Patterns (porting, external): `6502-6809-conversion-patterns/shared/<category>/<id>-<name>.md` or `6502-6809-conversion-patterns/project/karateka/<id>-<name>.md`
- Patterns (disassembly methodology, external): `apple2-disasm-patterns/<name>.md`
- State file: `docs/project-state.md`

### A.4 Cross-document references

- This document: `karateka-coco3-design-v0.1.md`
- Sibling project: `pop-coco3-design-v0.7.md`
- Methodology: `claude-orchestrated-methodology-v0.2.md`
- Phase 0 reference: `karateka_dissasembly_claude` repository (via sibling path)
- Pattern library (porting): `6502-6809-conversion-patterns` repository
- Pattern library (disassembly methodology): `apple2-disasm-patterns` repository

---

## Appendix B: Decision log

Decisions made during initial design conversation (2026-05-12):

1. Project goal scope (port Karateka to CoCo3, deferring multi-platform to v2.0) — Gate K.1.0
2. Graphics mode (320×192×4 inherited from pop-coco3) — Gate K.1.1
3. HAL target reduction (single target for v1.0 vs POP's four) — Gate K.1.2
4. CPU support (boot-time detection inherited from pop-coco3) — Gate K.1.3
5. Memory target (128K min, 512K leveraged) — Gate K.1.4
6. Sound simplification (DAC only for v1.0 vs POP's DAC+1-bit) — Gate K.1.5
7. Copy protection (none, source already clean) — Gate K.1.6
8. Test harness as P1 first deliverable (inherited) — Gate K.1.7
9. Methodology binding (CODM v0.2 from pop-coco3) — Gate K.1.8
10. Shared pattern library (hosted in `6502-6809-conversion-patterns`, separate `apple2-disasm-patterns` for disassembly methodology) — Gate K.1.9
11. Repository topology (five separate repos; karateka_dissasembly_claude via sibling path; pattern repos via path/URL reference) — Gate K.1.10

---

## Appendix C: Karateka-disasm cross-reference

The karateka_dissasembly_claude repository contains the reference oracle for this project. It is in active ongoing development.

**Source tree (intro-time territory, M1/M2 closed):** 38 files in `src/` totaling 32,256 bytes from dump01_intro.bin.

**Source tree (gameplay-state territory, ongoing):** karateka_dissasembly_claude continues capturing memory dumps at distinct game states (dump04_castle_entry, dump07_first_fight, additional dumps as needed) and disassembling the code/data that overlays or extends what's in dump01_intro.bin. Per the project's existing tagging convention (instructions.md Section 4), every routine carries its dump-of-origin tag.

**Architectural documentation:**
- `docs/data-areas-catalog.md` — full address-to-content map
- `docs/memory-coverage-map.md` — coverage tracking (per dump)
- `docs/dump-registry.md` — list of all captured dumps with capture-state notes
- `docs/open-questions.md` — unresolved questions
- `docs/milestones.md` — M1/M2 acceptance status; future milestones for gameplay-state completeness
- `regions/dumpNN.md` — per-dump region classification

**Build infrastructure:**
- `scripts/build_disk.py` — three-phase Apple II build (intro-time scope at M1/M2 closure; expected extension for gameplay-state dumps)
- `scripts/smoke_test.sh` — verification orchestration
- `tools/roundtrip.py` — per-range byte-identity verification (per-dump scoped)

**Key architectural findings to carry forward (from intro-time M1 work):**

- **Combat pipeline:** fight_engine.s AI selection → gameplay_6000.s L6540 action exec dispatcher → animation tables $6000-$63FF → gameplay_7000.s state machine → display_7700.s rendering → attract_dispatch.s sprite render
- **Scene flow:** intro.s linear scenes 1-4 (Broderbund, Mechner, karateka logo, scrolling) → scene_dispatch.s scene 5 entry $B4B9 → $79A3 → $7AF7 fight_round_main
- **Hot paths:** render_frame_0a00 at 262K fires/frame (THE blit engine), vbl_sync at $779A 18.7 fires/frame
- **Jump tables:** kernel $0780, jmptable_7000, jmptable_7800, jmptable_7D00, jmptable_6780
- **ZP cluster semantics:** $20-$2F active combat, $60-$6F combatant A, $70-$7F combatant B
- **Sprite system:** 8 banks, ~263 sprites total, body-part composition technique (16-frame run cycle, Akuma throne pose)
- **Build artifacts:** four documented cases of dead code + mid-instruction JSR targets (Mechner's development residue)

These findings are the working knowledge that karateka-coco3's port will leverage. They were discovered, verified, and documented during karateka_dissasembly_claude M1 work. Additional findings will accrue as karateka_dissasembly_claude continues with gameplay-state disassembly; updates to this appendix happen as the cross-project work progresses.

---

**End of karateka-coco3-design-v0.1**
