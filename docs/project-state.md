# karateka-coco3 — project state

## Current state

- Methodology version: Claude-Orchestrated Development Methodology v0.2
- Project phase: P2 IN PROGRESS; P3.1 COMPLETE (2026-05-21)
  P2.3 COMPLETE per audit 2026-05-17; P2.4 not started — see §Execution history
- Last update: 2026-06-13 (scene-5 cast: princess [14 frames, $11e8/$1c7a] +
  guard [3 frames, $8300/$8c67] FOUND EMPIRICALLY by execution trace — corrects
  the earlier wrong "skeleton reuse" claim; previews sorted by character;
  R-engine CONFIRMED + converter color-cell fix; R-p26 scroll CONFIRMED)

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

**Next (canonical):** the cliff-APPROACH scene (post-scroll) — closes INT-2 per
the boundary ruling (milestones.md). R-p24 (scene-1) + R-p25 (scene-2/3) +
R-p26 (scene-4 cliff narrative scroll, Option B lower-bank) all CONFIRMED at
Jay's gate (2026-06-13); scene-2 CoCo3 port credit added. Content Wave 3
complete. R-vbl/R-boot CLOSED (2026-05-21); P2.3 COMPLETE per audit 2026-05-17.
INT-2 still IN PROGRESS (scroll done; cliff-approach + scene 5/6-opening remain).

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
- P2.4 (canonical intro.s scene-1 path / R-p24): CONFIRMED on agent-verifiable
  criteria (2026-06-13); INT-1 close pending Jay MAME visual gate. Linear
  scene-1 controller + real polled HAL_input_poll; halts at scene-1→scene-2 cut.
  jmptable_b760 continuation + intro_prelude_b769 prelude deferred (beyond cut).
- P3.1 (R-vbl + R-boot): COMPLETE (2026-05-21; commits d687e01, ee3fa08)
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

INT-1 ("first scene displays correctly") is NOT yet closed, but its sole
remaining requirement is CONFIRMED on agent-verifiable criteria pending Jay's
visual gate:
- R-p24: canonical intro.s scene-1 path (P2.4) — controller CONFIRMED
  2026-06-13 (AC-1..AC-9 [E]/[T] all pass); INT-1 close awaits AC-10 (Jay MAME
  visual no-regression gate). See §R-p24 execution.

CLOSED requirements:
- R-p23: CLOSED 2026-05-17 per canonical P2.3 audit (INT-1-bounded;
  11 ABSORBED-HAL, 3 OUT-OF-SCOPE; see §Canonical P2.3 scope audit above).
- R-vbl: CLOSED 2026-05-21 (commit d687e01) — real GIME VBL IRQ handler installed,
  frame counter interrupt-driven at ~60 Hz, CC.I opt-in via andcc #$EF verified.
- R-boot: CLOSED 2026-05-21 (commit ee3fa08) — Brøderbund splash scene boots from
  karateka.bin with 160-frame hold + 80-frame blank; Jay's visual gate PASSED.
  Two architectural fixes bundled: HAL_gfx_init IEN preservation (gfx.s $FF90 $4C→$6C)
  and HAL_sys_init PIA IRQ disable (sys.s, new Step 2).

### R-vbl execution (CONFIRMED 2026-05-21; commit d687e01)

R-vbl = real GIME VBL IRQ implementation (first deliverable of P3.1).

- hal_vbl_handler installed at $010C dispatch slot via HAL_time_init patch.
- GIME VBL configured: $FF90=$6C (IEN=1), $FF92=$08 (VBORD only), $FF93=$00.
- Real-VBL spin in HAL_time_vbl_wait: cmpb <hal_frame_lo / beq spin.
- N3=β synthetic fallback for masked callers (CC.I=1): HAL_time_vbl_wait
  detects CC.I and increments counter without spinning.
- HAL_time_frame_count race fix: pshs cc / orcc #$10 around dual load / puls cc.
- Verification: V-counter-rate confirmed ~60 Hz advance in interrupt-driven mode
  vs polling stub.
- Q001 (interrupt discipline migration) CLOSED 2026-05-19; decisions per §Q001.1–4
  and EXTRA-1/EXTRA-2/EXTRA-3 filed to docs/interrupt-handling.md §10.

### R-boot execution (CONFIRMED 2026-05-21; commit ee3fa08)

R-boot = Brøderbund splash scene integrated at boot entry point.

- boot.s extended: andcc #$EF → jsr broderbund_scene → HAL_time_delay(160) →
  clear + present → HAL_time_delay(80) → boot_halt.
- Root cause identified via MAME 0.281 -debug instruction-level trace: CoCo3 BASIC
  leaves PIA0 keyboard IRQ enabled; PIA IRQ lines OR directly onto 6809 IRQ pin
  bypassing GIME IRQENR; 833,172 non-VBORD IRQ iterations in 30 seconds trapped
  the CPU at $0226 (jsr broderbund_scene never executed).
- Fix 1 (HAL_gfx_init IEN, gfx.s): $FF90 value changed $4C→$6C to preserve IEN=1
  written by HAL_time_init. Applies whenever HAL_time_init + HAL_gfx_init are
  both called.
- Fix 2 (HAL_sys_init PIA IRQ, sys.s): added Step 2 — read-modify-write with mask
  $FC on $FF01, $FF03, $FF21, $FF23 disables CA1/CA2/CB1/CB2 IRQ generation on
  PIA0 and PIA1. Future keyboard input (R-p24+) must re-enable selectively.
- Investigation: 9 rounds of static/dynamic hypothesis-test before instruction-
  level trace revealed PIA trap. See methodology lessons P3/P5/P7.
- V-regression: all 5 drivers PASS post-fix. Visual gate: Jay confirmed
  Brøderbund scene visible ~2.67s, blank ~1.33s, held blank.

### R-p24 execution (CONFIRMED agent-verifiable 2026-06-13; INT-1 close pending Jay)

R-p24 = canonical intro.s scene-1 controller port (last INT-1 blocker).

- Replaced boot.s's hardcoded splash (blocking HAL_time_delay holds) with a
  linear scene-1 controller mirroring Apple II outer_caller_b77c $B77C-$B797:
  broderbund_scene → 160-frame hold-with-poll → 1→2 transition (gfx_clear +
  present) → 80-frame blank-with-poll → halt at the scene-1→scene-2 cut ($B798).
- scene1_hold_poll (boot.s): per-frame VBL-counted hold (= stub_b823 +
  routine_b7f5); each iteration HAL_time_vbl_wait + HAL_input_poll. The Apple II
  $80/$D2 inner-count is replaced by the real VBL frame (R-vbl).
- Real HAL_input_poll (input.s): polled CoCo3 keyboard-matrix + joystick-button
  scan (drive $FF02=$00, read $FF00, mask PA7, complement → pressed mask).
  HAL_input_init asserts CR bit 2 = 1 (data mode), keeps CA/CB IRQ disabled.
  NO PIA re-enable — polled data-register reads work under the R-boot CR config
  (source-confirmed in sys.s; DDR-persistence sweep found no $FF00-$FF03 DDR
  write in the boot path).
- Input detection (= LB7DE): a press sets intro_input_flag/$aux ($60/$61 = $01,
  $86/$4F analogs) and early-breaks the hold. Game-start consumer STUBBED (R-p25).
- Verification: AC-1..AC-6 [E] (structure + clean build + all 7 automated tests
  PASS; karateka.bin 2171→2251 B). AC-7 [T]: MAME read-tap on $0A86 counted
  ~1 poll/frame, total 241 ≈ 240 (=160+80). AC-8 [T]: $FF00 row-0 injection
  detected at next frame, flags set $01/$01, early break (44 polls). AC-9 [T]:
  160-then-80 frame split confirmed. AC-10 [H]: PENDING Jay MAME visual.
- Deferred (beyond the cut, §2b): jmptable_b760 per-frame continuation +
  intro_prelude_b769 prelude + attract loop-back. Prelude omission also
  preserves the R-boot visual baseline (AC-10 no-regression).
- Doc tension corrected: hal.md previously suggested HAL_input_init re-enable
  PIA IRQ for keyboard — superseded (would reintroduce the R-boot trap); polled
  input is the confirmed approach.

### Content Wave 2 — scene-2/3 asset conversion (2026-06-13; render port = R-p25)

Asset half of the R-p25 split. Ran the calibrated Wave-1 pipeline
(tools/sprite_convert.py) over the 18 unconverted scene-2/3 assets:

- Scene 2 (Mechner credit): 10 font glyphs from oracle sprite_data_0400.s
  (a,b,c,d,g,h,j,m,o,y; address-form labels sprite_0400/0416/042c/0442/
  0488/04a2/0632/04f2/051e/060c), start_col=119 uniform per Wave-1
  convention (display position/parity handled at blit via blit_subbyte).
  e,n,r reused; p,s,t untouched.
- Scene 3 (karateka title): 7 title sprites from sprite_data_logo.s
  (sprite_logo_a/k/k_flourish/t/e/r/ra_connector, $BBEC-$BFE7) at slot
  pixel_x 35/0/0/133/168/69/104 (each sprite's multi-uses share parity)
  + copyright sprite_1f09 (sprite_data_1E00.s, 9×24).
- All 18 → content/<name>/converted.s (Wave-1 format: fcb H,W + pixels);
  18 PNG previews → content/wave2-previews/{scene2,scene3}/ (gitignored).
- Verification: 18 assets lwasm syntax-check standalone; build clean
  (karateka.bin 2251 B, unchanged — not yet referenced); 7/7 tests PASS.
  Per-asset VISUAL GATE pending (R-p25 / Jay).
- REFERENCE GAP (HS-2): no authoritative MAME apple2e capture confirmed
  for scene 2 or scene 3 (snap 0083 is the scene-1 chroma reference only).
  Jay must capture scene-2/3 Apple II references before the visual gate;
  assets NOT validated against a substitute. copyright start_col uncertain
  (column not cleanly derived) — re-convert if parity is off at the gate.

### R-p25 — scene-2/3 render port + "pressed" early-break (2026-06-13; visual gate pending Jay)

Extended the linear controller scene-1 → 2 → 3, halting at the scene-3→4 cut
($B7D5 equiv). New `src/engine/intro_scenes.s` (render routines + tables +
new content includes); boot.s controller extended; early-break freeze replaced
by a shared "pressed" debug screen.

- HS-2 fix (first attempt halted on missing extents): generated wlead/trail for
  the 10 new glyphs via `tools/glyph_extent.py` (validated against §22.4's
  p,r,e,s,n,t exactly); recorded in §22.4a. Inter-word gap = glyph-m width = 16px.
- Scene 2 (Mechner credit): positions baked offline via §22 (route i,
  `tools/bake_text.py`), centered@160, rows 85/99 (§19 1:1 from Apple $55/$63).
- Scene 3 (karateka title): Apple II $B926-$B95C slot positions converted via
  §19 (coco3_px = apple_px+20) into a packed table; the title_render 11-slot loop
  ported as the shared `render_glyph_run`; copyright (sprite_1f09) rendered.
- "pressed" (D3): shared early-break screen (clear → blit "pressed" → present),
  fired from scene1_input_break in ANY scene (re-gates scene 1). DEBUG
  PLACEHOLDER for the still-stubbed game-start consumer (P3+); $60/$61 still set.
- CoCo3 deviation: scene-2's oracle 160+80 holds merged to one 240-frame hold
  (no mid-scene re-present — avoids the Option-I flip to a stale back buffer);
  each scene render preceded by a clear. Visual progression unchanged.
- Verification: AC-0..AC-S3-2, AC-D3-1, AC-G-1/2 [E] (build clean, karateka.bin
  2251→5011 B, 7/7 tests PASS). AC-G-2 trace: no-input reached boot_halt @ frame
  939 with flags clear; inject reached boot_halt @ 56 with $60/$61=$01 (pressed
  path). VISUAL gates AC-S2-3/S3-3/D3-2 [H] **PASSED** (Jay, 2026-06-13).
- Visual-gate fixes (applied during the gate):
  * Scene-2 spacing re-baked from oracle font_glyph_xstep_* metrics (commit
    f6b9ab0): word space 7px (was the §2-F 16px guess, ~2× too wide).
  * Scene-3 copyright flash fixed: rendering is single-buffered (page_register
    never toggles; HAL_gfx_present only sets the GIME display offset), so pass-2
    must NOT clear/re-render the title (that blanked+redrew the visible title) —
    only draw the copyright onto buffer A and present.
  * Title spacing: the converter strips leading blank bytes (title_k, title_t =
    1 byte) but blit positions were a uniform §19 +20, skewing spacing. Added
    per-sprite leading-strip compensation (k slots 3,4 + t slot 7: +7px).
  * k-flourish dialed to +3px (4px left of each k) via Jay's visual nudges.
- Deferred: scene 4 (R-p26+); real game-start consumer (P3+).

### Content Wave 3 — scene-4 scroll glyphs (2026-06-13; render port = R-p26)

Asset half of the R-p26 split. Ran the calibrated pipeline over the 11
unconverted scene-4 narrative glyphs:

- 7 letters (f,i,k,l,u,v,w) + 4 punctuation (period,comma,colon,hyphen) from
  oracle `sprite_data_0400.s`, address-form labels (sprite_046e/0626/04d0/
  04e6/05aa/05c0/05d6 + sprite_0640/064c/065a/0668), start_col=119 uniform per
  the Wave-1/2 convention. → `content/font/glyph_<name>/converted.s` (Wave-1 format).
- Extents (wlead/trail) generated for all 11 via `tools/glyph_extent.py`,
  recorded in conventions §22.4b alongside each glyph's oracle pen-model xstep
  (the R-p26 bake input) — folds the extent step into conversion so R-p26's
  bake cannot re-hit the R-p25 HS-2 (missing-extents) gap. No leading byte
  column stripped on any of the 11 (lead_stripped=0) → no position compensation.
- HS-1 (punctuation class) PASSED — all 4 convert cleanly; baselines reported:
  period rows 8–9 (low), comma rows 8–11 (left-shifting descender, H=12),
  colon rows 4–5/7–8 (internal gap row 6, H=12), hyphen rows 5–6 (mid bar).
  The Apple bit-7 color-set bit (set on every row) is read as pal_bit, not a
  pixel — "empty" $80 rows convert to all-black. HS-2 (extent quality) PASSED.
- 11 PNG previews → `content/wave3-previews/scene4/` (gitignored).
- Verification: build clean (karateka.bin 5005 B, byte-identical — glyphs not
  yet `include`d; R-p26 adds them); 11/11 lwasm syntax-check standalone; 7/7
  automated tests PASS. Per-asset VISUAL GATE PASSED (Jay, 2026-06-13, AC-6) —
  glyph fidelity confirmed against scene4_scroll_a/b; positioning deferred to
  render time in R-p26.
- No reference gap this wave: the scene-4 scroll references were captured
  proactively (the tiling set) before this conversion.

### R-p26 — scene-4 scroll port (2026-06-13; HARD-STOP at the option-2 fit)

Attempted the scene-4 scrolling narrative as a GIME VOFFSET sliding-window
scroll (option 2, per Jay's case-(2) ruling after the option-1 HS-1 halt).
Substantial implementation; HALTED before shipping on a geometric fit finding.

- RECORD CORRECTION (confirmed this task): scene 4 = the scrolling narrative
  (oracle routine_b833 + text_strings.s indices 4..21 = 16 prose lines + 2
  blank paragraph breaks; rendered via render_pass_a). The combat hot-path
  (render_pass_b / routine_1c5b/1c64) is a LATER scene, not scene 4. Any
  R-p24-era "scene 4 = combat" note is superseded.
- VALIDATED + COMMITTED (reusable infra): tools/bake_scene4.py (left-aligned
  oracle pen-model bake from the encoded strings; Apple X=0 -> CoCo3 px 20),
  src/engine/scene4_text.s (18 per-line glyph tables, GENERATED), and
  HAL_gfx_blit_scroll in gfx.s (full-region blit into the combined buffers,
  16-bit dest row, no 192 bounds check, shares the sub-byte dispatch). MAME
  confirmed the text renders legibly and scrolls (S advances, lines enter
  from the bottom) up to the first ring wrap.
- HARD-STOP (the fit): the duplicate-zone ring does NOT fit stock 128K.
  Seamless ring period L >= window + line_height = 192+14 = 206 (else the
  entering line's wrapped real-copy spills into the window top — the
  corruption seen at S~60). The duplicate zone doubles the footprint to ~2L
  rows, whose top band-clear must stay below the GIME I/O at $FF00 (~row
  405). 2L <= 405 AND L >= 206 is a contradiction (412 > 405): the combined
  display buffers (392 rows) are ~10-14 rows too small, and a larger ring
  collides with $FF00. (= seed hardware-scroll-ring-needs-2x-window-plus-
  line-footprint.) src/engine/scene4_scroll.s committed HELD (not in the
  build); boot.s remains at the scene-3->4 halt (main stable, 7/7 tests).
- DECISION PENDING (orchestrator/Jay): (i) memmove-on-wrap variant — drops
  the duplicate zone, ~L footprint, at a per-wrap row copy; fits 128K;
  (ii) lower-bank scroll buffer (pages $30-$37, more RAM, but content-bank
  conflict + MMU paging); (iii) escalate to 512K (Q-512kb-architecture).
- Deferred with the port: the §3 doc deliverables (INT-2 boundary ruling;
  the 512K Q/disk-load-catalog records) ride with the chosen architecture.

### R-p26 v3 — memmove-on-wrap scroll (2026-06-13; wrap SOLVED, residual band bug)

Jay ruled option-1 (amortized memmove-on-wrap). Rebuilt scene4_scroll.s as a
single-zone buffer with continuous incremental copy-down (no duplicate zone):
window scrolls 0->SHIFT(192); as rows scroll off the top they are copied back
(2 rows/step, ~1740 cyc, <6% of a frame — amortized, no stall, HS-1 satisfied),
so the VOFFSET reset is pixel-identical. Max row ~395 ($FB30) — clears $FF00.

- WRAP MECHANISM SOLVED: no crash; the scroll runs end-to-end through multiple
  wraps and COMPLETES (returns to the controller halt at $028F). The v2
  duplicate-zone fit blocker is gone.
- RENDERING MOSTLY CLEAN (MAME-verified): the copied region (buffer rows 2-81
  at one sample) is all clean, correct text; post-wrap frames render the full
  paragraph cleanly (legible, 14px spacing, paragraph breaks, punctuation
  incl. "karate:"). Confirms bake + blit + copy + wrap all work.
- RESIDUAL BUG (not gate-ready): some line bands show RANDOM-byte garbage in
  their upper rows (e.g. slot 3 @ buffer row 220: rows 221-222,224-225 = random,
  row 223 blank), STABLE across consecutive frames (real framebuffer content,
  not a capture artifact). The slot's glyph table is valid; garbage = non-glyph
  random (distinct=32/36). ROOT-CAUSED + FIXED (2026-06-13, debugger pass):
  the copy-down's row-copy loop used `ldb #40` as the counter, but `ldd ,y++`
  (load source word) CLOBBERS B every iteration, so `decb`/`bne` ran on copied
  data — the loop ran an unbounded, data-dependent count. X (dest) and Y (src)
  marched past the 80-byte row; Y climbed into the GIME I/O near $FFFF and
  wrapped to low RAM, writing register/garbage bytes onto the screen. Found via
  bisect (disable copy -> garbage gone) + Jay's "activity near $FFFF shouldn't
  happen" (= runaway pointer). The guards failed and the watchpoint looked
  contradictory because the controlling quantity wasn't copy_i — it was the
  clobbered counter. FIX: count in a DP byte (s4_ctmp) that `ldd` doesn't touch.
  MAME-verified CLEAN: full scroll, all wraps seamless, text legible, no
  garbage band; 7/7 tests; scroll completes. (= seed
  ldd-clobbers-loop-counter-runaway-pointer.) Now READY for Jay's AC-6 gate.
- Committed ACTIVE (boot.s calls scene4_scroll; halts at $B7DB) so the next
  debug pass can iterate directly. Build clean (karateka.bin ~7.3KB); 7/7
  automated tests PASS. NOT yet Jay-gated (the band must be fixed first).
- Cycle count (AC-2): copy = 2 rows/step = 40 words/row * 2 = ~1740 cyc, once
  per K=3-frame step => <6% of one 60Hz frame. Amortized; no single-frame stall.

### R-p26 gate iteration -> Option B (lower-bank pre-render; 2026-06-13)

At Jay's visual gate the copy/wrap (v3) read as choppy + "smeared"; a no-copy
display-buffer rewrite (v4, pure VOFFSET over a pre-rendered 398-row buffer)
was smooth and clean but NOT faithful (couldn't fit content+window+travel, so
it started/ended with text parked on screen — Jay rejected that trade-off).
Resolution: **Option B** (Jay's call) — render the full 636-row scroll (entry
192 + content 252 + exit 192) into the LOWER BANK (physical $60000, real RAM on
128K), then scroll with PURE VOFFSET ($C000 + 10*top). Pure-VOFFSET runtime is
the v4-proven smooth path; faithful because the lower bank holds the full
travel. Probe confirmed the GIME displays the lower bank (VOFFSET=$C000).
- Build (once): clear lower bank via the $4000 MMU window; render 18 lines in
  the display region (blit); bulk-copy (MMU-window chunks, byte-aligned) to
  lower-bank row 192. Sidesteps the 8KB-page vs 80-byte-row misalignment.
- Scroll: VOFFSET = $C000 + 10*top, top 0..444. Faithful (scrolls in from
  bottom, off the top), smooth (no per-frame render). Jay CONFIRMED scrolling.
- METHODOLOGY: MAME -nothrottle screen:snapshot() proved UNRELIABLE here
  (mistimed captures showed phantom "smear"/"stuck" frames absent from the live
  view) — the perceived smear/choppy were largely capture/motion artifacts.
  Trust the live gate, not nothrottle snapshots, for scroll QA. Stock 128K
  (lower bank borrowed during the intro; not 512K).
- GATE FIXES (Jay): (1) the content render targeted the display buffer while it
  was still shown -> the full pre-render page flashed before the scroll; fixed
  by switching VOFFSET to the (blank) lower bank BEFORE rendering (render
  off-screen). (2) scroll slowed (S4_KFRAMES 3->4, ~30s) per "a bit slower".
- R-p26 CONFIRMED at Jay's visual gate (2026-06-13): faithful in/out, smooth,
  speed approved, no flash. AC-6/7 [H] PASS.
- ADDITION (scene 2): CoCo3 port credit "coco port by / jay searle" appears
  centered below the Mechner credit after a delay (custom; gate-approved;
  scene-3 copyright add-below pattern). Scene-2 holds 160 (mechner) + 160 (port).
- Build clean (karateka.bin 7359 B); 7/7 automated tests PASS.
- Held doc records filed: INT-2 boundary ruling (milestones.md — INT-2 closes
  at the cliff-APPROACH, still in progress); Q-512kb-architecture + empty
  disk-load-catalog.md (open-questions.md). R-p24 "scene 4 = combat" record
  corrected earlier (scene 4 = the text scroll; combat = a later scene).

### R-engine — sprite/animation engine core + sandbox (2026-06-13; CONFIRMED)

Built the single-source, data-driven animation engine and proved it on the
Akuma 9-frame set. The engine is the foundation for scene-5+, the demo combat,
and gameplay; the combat LAYER (hit detection / round manager / two-combatant
interaction) is INT-3, additive on top.

- ENGINE (src/engine/sprite_engine.s): render leaf delegates to the real
  HAL_gfx_blit_sprite (C-13 decision — its transparency blit IS the oracle
  routine_1927 mask/eor/AND/OR blend; NO self-modifying blend ported, "port
  the visual not the Apple mechanism"); frame sequencer (cadence countdown ->
  advance + wrap -> render); state block ZP $30-$3A (verified free); region-
  clear of a set-union bbox per buffer; proven Option-I A/B page-flip
  (draw hidden -> HAL_gfx_present -> toggle page_register). Characters are
  DATA: an animation table (count, cadence, clear_w/h, then per-frame
  fdb sprite ; fcb col,sub,row) + a sprite set. One engine drives all.
- SANDBOX (tests/scripted/sprite_engine_sandbox_driver.s + _trace_driver.s,
  *.lua, run_*.bat/.sh): INCLUDES the real engine+HAL+globals verbatim (single
  source, never a copy); boot-excluded (boot.s never refs it; prod link list
  unchanged, builds 7359 B). Interactive driver: PAUSED on frame 0, tap=single-
  step (edge), hold=free-run at cadence (~3fps); trace driver free-runs for the
  automated P2/P3 read without input injection.
- AKUMA conversion (AC-0): the 9 frames (oracle sprite_data.s labels
  sprite_9879/988b/989d/98af/98c1/98d3/9908/9956/9a62, start_col 120) ->
  content/akuma/akuma_frame_0..8 (untracked per content rule).
- GATES: P2 (static render clean at anchor, no garbage) PASS; P3 (memory trace:
  cadence delta=8 VBL exact, eng_idx cycles 0..8 wrapping, page_register toggles
  $20<->$40 each advance) PASS; HS-1 (worst-case render+flip ~4430 cy ~= 15% of
  one VBL period, ~6x headroom; scaling baseline ~6 simultaneous worst-case
  redraws/frame) PASS by static analysis; P4 (Jay live, real-time) CONFIRMED
  (motion + single-step both work).
- CONVERTER COLOR-CELL FIX (P4-surfaced): the live gate showed vertical
  color/black striping on Akuma's solid orange/blue fills. ROOT CAUSE
  (tools/sprite_convert.py): Apple II solid color = an alternating-dot pattern
  (1010), and the 1:1 dot map classified each lit dot as run_len==1 "isolated"
  -> colored at its col, leaving the in-cell dark dots Black -> stripes. FIX:
  after per-dot classification, fill any Black dot flanked by the SAME chroma
  (Orange/Blue) on both sides (color-cell fill). Re-converted all 9 frames +
  regenerated previews; Jay confirmed striping gone. White runs / isolated thin
  color features untouched. Gated color content (scene-3 title) is UNCHANGED on
  disk (old converter output, no regression) — re-converting through the
  improved model is an available follow-up. Cadence is NOT oracle-extractable
  (un-disassembled) -> tunable default, Jay-gated.
- Sequencing (Jay-gated, §22.5): on the P4 striping finding, Jay chose "fix
  converter first, then commit together" (engine + converter fix one commit);
  and "leave content/ untracked" (converter fix is the durable correction;
  converted.s + previews regenerable, stay untracked per standing rule).
- TUNING NOTE: sandbox loads the Brøderbund palette (descriptor 0) so Akuma
  HUES are not throne-room-accurate; the striping fix is palette-independent.
  A throne-room palette is downstream (scene 5+).

### Scene-5 cast scale-out (2026-06-13; find = the variance driver, as predicted)

Locate the scene-5 cutscene cast by CONTENT, convert through the fixed
converter, extend the sandbox to cycle the sets, Jay visually IDs.

- FIND (HS-1 path): the dispatch premised separate animating princess + guard
  frame sets. Walking the banks + scene-pointers by content found NO such sets.
  HS-1 fired -> Jay chose "watch scene 5 in MAME first." Ran the real Apple II
  Karateka (apple2e, refs disk); Jay observed: Akuma center-bottom, **princess
  walks across toward the door**, guard left/center, **eagle on Akuma's
  shoulder**. That re-scoped the cast to the $9800+$9B00 region (the recon's
  "$9B00=player" label was tentative; corrected by content — but see ID below).
- CONVERTED (35 sprites, unlabeled by handle, fixed converter): $9800 props +
  figures (eagle-head, cell-door, banner, 9858, 9a18, 9a2a) + the full $9B00
  bank (player walk legs×8 + torso×8, akuma throne+feet, eagle body/head).
  Akuma 9-frame already done (R-engine). Content untracked per rule; previews
  gitignored (content/engine-previews/).
- SANDBOX: extended to 7-set select (tap = next set; each set free-runs its
  frames; full-buffer clear on switch). Boot-excluded; includes the real engine.
- JAY ID GATE (AC-4): Akuma=set0 (CONFIRMED), eagle=set4, props=set6 (cell
  door+banner) CONFIRMED. **Sets 1/2 (the $9B00 walk cycle) = PLAYER, NOT
  princess.** Set 5 figures = unresolved (guard candidate). **No striping on any
  set** -> color-cell fix holds across the cast (AC-5 clean).
- ESCALATION (Jay-gated): searched $8300 + $a400 + low banks by LABEL — found
  no *labeled* princess/guard set, and I wrongly concluded "skeleton reuse."
- **RETRACTED + CORRECTED (Jay rejected the reuse conclusion; 2026-06-13):** the
  princess and guard DO exist as their own sprite records. Found EMPIRICALLY by
  instrumenting the real Apple II run (tests/scripted/trace_scene5_sprites.lua,
  diag_sprite_ptr.lua) and tracing the sprite-source pointer ($1B/$1C saved
  START) every frame from imprisonment start ($3D=$01, ~f3909) to climbing start
  (f6019=$A3E9), mapping each start to bank+dims via dump05_imprison.bin.
  Result: scene 5 draws figures from the $11e8 and $1c7a banks (recon's
  "gameplay blobs") + the $8300/$8c67 region — NOT the player walk set.
  - PRINCESS = 14 frames ($11e8: $1530/$1867/$1611/$1588 standing+turning,
    $169A torso, $16CC/$175E/$17D3 falling, $1829 on-floor; $1c7a: $1D00 body,
    $1D36/$1D5A/$1D7E/$1DA2 walking legs). Jay-IDed each in the previews.
  - GUARD = 3 frames ($8F2B head [oracle mislabel "feet_shadow"], $899C torso/
    standing, $8ACB below-torso). Jay-IDed.
  - The $96xx/$97xx cluster = FLOOR patterns (background), not characters.
    Scenery (Jay-IDed): bench $12C8 (right wall), floor $14BE/$1200, wall $18BF.
  - Both are composited multi-part figures (head/torso/legs) — assembly is
    scene-5 orchestration (out of scope). Full map: docs/scene5-cast-map.md.
- LESSON (reinforced): negative label-grep proves nothing; an OBSERVED-to-exist
  asset must be found by execution trace, not inferred. Do not convert a
  reasoned conclusion into a stated finding.
- Figures converted by ADDRESS from dump05 (banks are single-label blobs).
  Previews reorganized BY CHARACTER (content/engine-previews/cast/<char>/).
  Content + previews untracked per rule; trace tooling committed.

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

### R-boot investigation patterns (2026-05-21)

Filed from the R-boot root-cause investigation. These augment the earlier Task C patterns.

- P1. **Gate discipline applies to diffs, not summaries.** Reviewer approval requires
  a verbatim diff, not a directional description. "D1.a confirmed — proceed" authorizes
  the approach but is not diff approval. Separating directional from diff approval caught
  precision issues multiple times this session.

- P2. **Verdict stability: more data before a verdict.** When evidence is ambiguous
  (multiple readings consistent with observations), the correct move is to request
  additional data that discriminates between hypotheses, not to pick the most plausible
  reading and proceed. Cycling a verdict after new data arrives is correct; committing
  to a reading with insufficient evidence is not.

- P3. **Per-frame sampling cannot observe sub-frame execution.** A per-frame Lua
  notifier sampling the 6809 PC once per MAME frame (60 Hz) cannot detect code that
  executes and completes within a single frame interval. The "CPU at $0226 for 101
  frames" observation was real but misleading — it showed where the CPU was at each
  frame boundary, not that the CPU was stuck. For sub-frame diagnosis, instruction-level
  tracing is required.

- P4. **Reporting format must be specified by the requester.** When a reviewer prompt
  asks Clyde for information without specifying output structure, the answer is
  unstructured and harder to act on. Prompts specifying §SectionN headings and
  verbatim-vs-summary requirements produced directly usable outputs. Apply this to
  all prompts requesting multi-part answers.

- P5. **Instruction-level tracing is the correct next move after static exhaustion.**
  When 9 rounds of hypothesis-test-analysis eliminate all statically-checkable
  suspects without convergence, the remaining bug class is dynamic: between-instruction
  state changes, timing dependencies, interrupt interactions. MAME's -debug
  -debugscript instruction-level tracer resolves these definitively. Don't extend
  static analysis past the point of diminishing returns.

- P6. **Transitive inference for write-only registers.** GIME registers $FF90, $FF92,
  and (inferred) $FF9D behave as write-only at the program-space read level — reads
  return hardware status, not the last-written value. Verify writes via observable
  downstream consequences (interrupt rate, display mode, etc.), not post-write
  read-back. See docs/interrupt-handling.md §8.4.

- P7. **V-counter-rate is necessary but not sufficient for real-VBL verification.**
  During the R-boot PIA trap, `hal_frame_lo` advanced at ~60 Hz (occasional VBL
  interleaved with 833,172 PIA-driven non-VBL IRQs). Counter rate alone cannot
  distinguish "VBL is the dominant IRQ source" from "VBL fires occasionally among
  many other IRQs." When real-VBL must be the mechanism, verify VBORD=1 in the
  handler (instruction-level trace or explicit register log), not just counter rate.

## Open questions (will accumulate)

See `docs/open-questions.md` (to be created as questions surface).
