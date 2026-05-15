# karateka-coco3 P2 Scoping Survey

Generated: 2026-05-15
Purpose: Inform P2.2 subsystem selection and INT-1 content asset wave.
Oracle: karateka_dissasembly_claude (read-only; commit 396a293 and earlier)

---

## 1. Survey scope and method

**What was surveyed (read-only):**
- `src/` — all source files; headers read in full, key bodies sampled
- `docs/intro-sequence-structure.md` — Jay's authoritative sequence description
- `docs/data-areas-catalog.md` — ZP pointer map, sprite-bank catalog
- `docs/scene-entries.md` — per-scene entry points and trace evidence
- `docs/differential-analysis.md` — per-dump register/ZP state
- `verification/mapping.json` (karateka-coco3) — confirmed P2.1 ZP mappings
- `docs/hal.md` (karateka-coco3) — HAL subsystem reference

**What was NOT surveyed (deferred):**
- `traces/` — raw trace files; too large; findings are already in docs/
- `src/gameplay_*.s`, `src/gameplay_state_0b00.s` — gameplay-only territory
  (waiting for P0b coverage per design doc §7.4.4)
- `src/sprite_data_11e8.s`, `src/sprite_data_1c7a.s` — 0 trace fires in
  full-cycle trace; gameplay-only per headers; not needed for attract

**Timer/frame-sync excluded:** P2.1 complete (timer_dispatch.s → engine/timer.s).

---

## 2. Subsystem boundary definitions

Subsystems as they map to karateka_dissasembly_claude source files:

| Subsystem | Primary files | Address range | Bytes |
|-----------|--------------|---------------|-------|
| Kernel/dispatch | kernel.s, kernel_per_frame.s, kernel_dispatch.s, kernel_dispatch_handlers.s | $0200-$02FF + $0780-$07E3 + $0C40-$0CBD | ~482 |
| Blit/graphics | video.s, render_frame_0a00.s | $0A00-$0AFF + $1900-$1C79 | ~1,148 |
| Scene management | intro.s, scene_dispatch.s | $B400-$B75F + $B760-$B909 | ~1,289 |
| Display setup/palette | video.s (routine_190f only) | $190F–$1A41 | ~210 |
| Sound | sound_engine.s (= sound.s part 1), pcm_player (= sound.s part 2), sound_data_0e00.s | $0D00-$0DFF + $0E00-$0EFF | ~256 |
| Basic keyboard scan | input.s ($7603-$7696 keyboard handler; $7697-$774A display helpers) | $7603-$774A | ~327 |
| Combat animation | fight_engine.s, attract_dispatch.s, attract_render.s, attract_state.s, display_7700.s ($7800-$7FFD) | $7800-$7FFD + $A000-$A397 + $AD00-$AFFF + $B000-$B3FF | ~3,475 |
| Cutscene machinery | scene_dispatch.s (scene5_entry_b400 portion), display_7700.s (fight_round_main) | $B400-$B4E6 + $7AF7-$7FFD | ~1,380 |

**Architectural note on display_7700.s:** This 2,229-byte file spans three
distinct subsystems:
- `$774B-$77FF` (`blit_hires_page`, `vbl_sync`, speaker helpers) — HAL territory;
  on CoCo3 these become `HAL_gfx_present` and `HAL_time_vbl_wait` stubs.
  Not ported as engine code; they are replaced by HAL calls.
- `$7800-$7FFD` — fight-scene rendering (combat animation subsystem)
- `$7C43` — `per_frame_dispatch` — kernel/dispatch subsystem

**Architectural note on kernel_dispatch_handlers.s:** The seven handlers at
$0C55-$0CBD were NOT executed in the dump01_intro full-cycle trace (78M lines,
2 cycles). [ref: kernel_dispatch_handlers.s header — "NONE of these handlers
were reached in dump01_intro's trace."] They are triggered only by specific
Ctrl-letter keypresses that don't occur during unattended attract playback.
For P2.2 these can be safely stubbed — they will not execute on the INT-1
through INT-3 attract-sequence path.

---

## 3. Per-subsystem inventory

### Subsystem: Kernel/dispatch

**Source files / ranges:**
- `src/kernel.s` — $0780-$07E3 (100 bytes; 292 lines)
  JMP trampoline table (2 entries: row-copy loop + page-flip-A), page-flip pair
  (routine_0799 + routine_07ac), hires row-pointer setup helper, VBL sync entry.
- `src/kernel_per_frame.s` — $0200-$02FF (256 bytes; 448 lines)
  Per-frame dispatcher: JMP dispatch table (4 entries), per-frame poll loop,
  Ctrl-key sync, input-detected video route, input polling loop, timeout exit,
  Ctrl-R entry body, video/blit helper, ZP pointer-setup + video dispatch.
- `src/kernel_dispatch.s` — $0C40-$0C54 (21 bytes; 140 lines)
  Cross-subsystem 7-entry JMP trampoline table. All callers are in input.s.
- `src/kernel_dispatch_handlers.s` — $0C55-$0CBD (105 bytes; 332 lines)
  Handler bodies for the $0C4x table. 0 trace fires in full-cycle trace.

**Total:** ~482 bytes source; 1,212 lines

**ZP footprint:**
[ref: kernel_per_frame.s] ZP reads/writes during per-frame loop include:
$07 (hires draw page), $D2 (frame countdown), $80 (inner-loop count, set by
$0209 per-frame handler), $86 (game-active flag), $4F (companion input flag),
$D0 (input state latch).
[ref: kernel.s] routine_0799/07ac: $07 (draw page, read/write), $E4 (saved prior
page = source page for blit). routine_07b9: $00/$01 (screen addr), $03/$04 (sprite
source pointer).

**HAL surface (predicted):**
- HAL_time_vbl_wait → replaces `vbl_sync` ($779A) called via L0783
- HAL_gfx_present → replaces page-flip dispatch through L0780/L0783 table
  (routine_0780/0786 row-copy + routine_0799/07ac page-flip pair in kernel.s)
- HAL_gfx_clear → replaces $1900 entry-0 (routine_190f, hires fill) called at
  the top of each frame via `jsr L1900` in outer_caller_b77c

**Cross-subsystem coupling:** HIGH
- Calls: video ($1900 init, $7609 display), sound (via $101C timer chain), input
  (keyboard scan), per-frame state update ($0237).
- Called by: intro.s (via jmptable_b760 → $B763 slot 1), attract_dispatch.s,
  scene_dispatch.s.

**INT-N criticality:** INT-1/INT-2/INT-3 — critical for all (nothing runs without
the per-frame dispatcher)

**Port estimate:** MEDIUM
- 256-byte per-frame dispatcher (kernel_per_frame.s) has a moderately complex
  poll loop, but the core structure maps cleanly to 6809
- kernel.s page-flip helpers are mostly HAL calls (VBL wait + buffer swap)
  with thin engine glue
- kernel_dispatch handlers can be stubbed (0 trace fires in attract path)
- Self-modifying code: none in kernel.s/kernel_per_frame.s

**Notes:** Natural continuation of P2.1 (timer_dispatch.s) — completes the kernel
layer. kernel_dispatch_handlers.s purpose is UNKNOWN; stub for P2.2, investigate
during P0b gameplay coverage.

---

### Subsystem: Blit/graphics

**Source files / ranges:**
- `src/video.s` — $1900-$1C79 (892 bytes; 785 lines)
  JMP dispatch table (5 entries at $1900-$190E). Entry 0: hires page fill.
  Entries 1-4: sprite-draw variants using two render routines (draw-A at
  routine_1927; draw-B at routine_1af4). Both variants self-modify their blend
  opcode at runtime (`routine_1927_blend_op`, `routine_1af4_blend_op`) based on
  ZP $0F.
- `src/render_frame_0a00.s` — $0A00-$0AFF (256 bytes; ~300 lines)
  3-entry JMP dispatch: render_pass_a (single-colour pixel blit, 262,264 trace
  fires), render_pass_b (dual-colour pixel blit), render_clear (AND-mask screen
  clear, 76,416 fires in clear_col inner loop). Callers: attract_render.s,
  attract_state.s, intro.s.

**Total:** ~1,148 bytes source; ~1,085 lines

**ZP footprint:**
[ref: data-areas-catalog.md §ZP pointer pairs]
- $00/$01 → screen RAM ($2000-$3FFF or $4000-$5FFF); set by video.s routine_190f,
  reconstructed per-column in routines_1927/1af4
- $03/$04 → sprite pixel descriptors (source pointer); per-scene setup stores
  immediates here; video.s advances incrementally per column
- $1B/$1C → saved copy of $03/$04 (restored at each sprite-draw entry)
- $07 → hires draw page base ($20=page1, $40=page2)
- $0D → column width (from sprite header byte 0, loaded by routine_1a61)
- $0E → row height (from sprite header byte 1)
- $0F → blend opcode selector (self-modifying code gate)
- $05, $06, $10 → sprite X-byte, Y-row, X-subbyte (render parameters)
- $11, $02, $13, $12 → pixel colour bytes for render_pass_a/b

**HAL surface (predicted):**
- HAL_gfx_blit_sprite — the primary deliverable of this subsystem port; replaces
  the video.s sprite engine and render_frame_0a00.s pixel blitters
- HAL_gfx_clear → replaces render_clear ($0A06 entry) + video.s entry 0
- The self-modifying opcode (blend mode select via $0F) needs CoCo3 equivalent;
  the HAL_gfx_blit_sprite signature may carry a blend-mode parameter

**Cross-subsystem coupling:** HIGH (called from nearly every other subsystem)
- Called by: intro.s (via L1903/L1906/L1909), scene_dispatch.s, attract_render.s
  (L0A00/L0A03/L0A18), attract_state.s (L0A00/L0A03), fight_engine.s (via
  $1903 dispatch), kernel_per_frame.s (via $0237 video dispatch)
- Calls: data tables in hires_rows.s (screen address lookup)

**INT-N criticality:** INT-1/INT-2/INT-3 — critical for all (no sprite can display
without it)

**Port estimate:** LARGE
- video.s routine_1927 is 120+ bytes of tight inner-loop 6502 with self-modifying
  code; the CoCo3 equivalent must handle 4bpp format, different row addressing
- render_frame_0a00.s has 5-deep nested timing loops in render_pass_a/b
- The hires row-address formula ($774B + $0800/$08C0 tables in display_7700.s) is
  Apple II-specific; CoCo3 uses a different row-stride formula
- Both variants need verification against Apple II sprite captures

**Notes:** Largest per-invocation complexity; most independent test surface (a sprite
blit can be verified against Apple II reference PNG without scene machinery).

---

### Subsystem: Scene management

**Source files / ranges:**
- `src/intro.s` — $B760-$B909 (425 bytes; 710 lines)
  Per-frame JMP dispatch table (jmptable_b760, 3 slots). intro_prelude_b769,
  intro_with_buttons_b779, outer_caller_b77c (linear scene 1-4 runner),
  stub_b823 (double loop), routine_b7f5 (per-frame input poll + input-detected
  handler), subroutine_b87c/b87f (video dispatch tail-calls), routine_b898-b8f3
  (per-scene sprite/text inits for scenes 1-3), routine_b895 (scene-5 handoff).
- `src/scene_dispatch.s` — $B400-$B75F (864 bytes; 972 lines)
  scene5_entry_b400 (ZP setup pass + engine init), attract main loop
  (attract_main_b584), attract-end loop-back gate (Q012 at $B5D3-$B5D7),
  attract state machine (routine_b260, routine_b30f, routine_b381, routine_b3df),
  helper routines (routine_b711 RNG-like, routine_b72e/b73f $B0/$B1 setup).

**Total:** ~1,289 bytes source; 1,682 lines

**ZP footprint:** [ref: data-areas-catalog.md §ZP game-state bytes]
Many — scene_dispatch.s alone writes ~30 ZP locations in its ZP setup pass.
Key ones: $AF/PRGEND (loop-back trigger), $3D (scene-5 active marker), $62/$72
(paired combatant positions), $52 (animation phase counter), $A1 (attract state),
$99 (scene-5 first-loop counter), $B0/$B1/$B6/$B7 (animation phase pairs).
intro.s uses: $80 (inner-loop count), $86 (game-active flag), $4F (input flag),
$D2 (frame countdown), $E4/$E7/$E8 (routine_b833 animation state).

**HAL surface (predicted):**
- HAL_time_vbl_wait → called indirectly via L0783 (routine_07ac) at end of each
  stub_b823 frame hold
- No direct Sound or Input HAL calls (sound triggering goes through timer_dispatch;
  keyboard scan goes through input.s which calls L7603)

**Cross-subsystem coupling:** MEDIUM
- intro.s calls: L1900 (video init), L1903 (sprite draw), LB90A (karateka_logo),
  LB960 (text string ptr), L0783 (display gate/VBL)
- scene_dispatch.s calls: fight_engine.s (via LA000), display_7700.s (via L79A3
  scene init chain), attract render machinery

**INT-N criticality:** INT-1 (intro.s outer_caller_b77c through scene 1 init
only), INT-2 (through scene 2-4), INT-3 (all of scene_dispatch.s attract loop)

**Port estimate:** LARGE
- intro.s outer_caller_b77c is ~85 bytes of scene orchestration; moderately
  straightforward (linear call sequence)
- scene_dispatch.s attract state machine is complex (coupled ZP state, 4-state
  dispatch, Q012 loop-back mechanism, RNG-like LCG)
- The attract state machine drives INT-3 but is not on the critical path for INT-1
- For INT-1, only intro.s through scene 1 completion is needed; scene_dispatch.s
  can be stubbed at its entry point ($B400)

**Notes:** Can be **split for INT-1**: port intro.s scene-1 path only (outer_caller_b77c
through scene 1 + stub_b823 exit), stub scene_dispatch.s entirely. This reduces
INT-1 critical-path size substantially.

---

### Subsystem: Display setup / palette

**Source files / ranges:**
- `src/video.s` routine_190f — $190F-$1A41 (210 bytes; within video.s 785 lines)
  Entry 0 of jmptable_1900: hires page fill with $80 (screen clear). This is
  how karateka initialises the display for a new scene.

**Total:** ~210 bytes; embedded in video.s

**ZP footprint:**
- $07 → hires draw page base (routine_190f reads this to select which page to fill)
- $00/$01 → screen address (reconstructed per-row)

**HAL surface (predicted):**
- HAL_gfx_init → replaces GIME 320×192×4 setup (entirely HAL; no Apple II
  equivalent — Apple II uses hires mode which is always active after boot)
- HAL_gfx_clear → replaces routine_190f ($80-fill screen clear)
- Palette derivation: [no-ref:] Apple II hires uses no explicit palette (pixel
  color comes from bit 7 of the byte + pixel position); CoCo3 GIME requires an
  explicit 4-color palette. `palette_derive.py` (P1.2 tooling) derives the
  CoCo3 palette from Apple II sprite bytes for each scene.

**Cross-subsystem coupling:** LOW
- Called from: outer_caller_b77c (via jsr L1900 before each scene)
- Calls: nothing beyond screen write

**INT-N criticality:** INT-1 — critical (screen must be cleared and initialized
before any sprite draws)

**Port estimate:** SMALL
- The Apple II init is a single screen-fill loop; the CoCo3 equivalent is
  HAL_gfx_init + HAL_gfx_clear
- Most of the work is in the P3.x HAL implementation (real GIME init), not in
  the P2.x engine port (just JSR HAL_gfx_init; JSR HAL_gfx_clear)
- This subsystem is best ported together with video.s (blit/graphics) since
  routine_190f is physically embedded there

---

### Subsystem: Basic keyboard scan

**Source files / ranges:**
- `src/input.s` — $7603-$774A (327 bytes; 472 lines)
  $7603-$7605: JMP trampoline to keyboard handler (L7697).
  $7606-$7696: Display/frame helpers (page-flip variants, frame state management)
  — noted in header as potential future migration to video.s or kernel.s.
  $7697-$774A: Actual keyboard handler: reads KBD, clears KBDSTRB, checks ESC
  ($9B), J/K mode toggles, Ctrl-letter codes via $0C4x dispatch table.

**Total:** ~327 bytes source; 472 lines

**ZP footprint:** [ref: input.s]
- $D0 (input state latch, read by key scanner)
- $86 (game-active flag, checked/set)
- Ctrl-letter handlers call $0C4x table which writes various ZP (UNKNOWN; handlers
  untraced)

**HAL surface (predicted):**
- HAL_input_poll → replaces keyboard read at L7697 (reads KBDSTRB + KBD)
- The frame-state / page-flip helpers at $7606-$7696 may migrate to kernel or
  graphics subsystem during P2 porting

**Cross-subsystem coupling:** LOW (for the attract path)
- Calls: kernel_dispatch.s ($0C4x table entries, for Ctrl-key handlers)
- Called by: routine_b7f5 (intro.s per-frame input poll), sound_engine.s (during
  tone playback), kernel_per_frame.s

**INT-N criticality:** NO for INT-1/INT-2/INT-3 (attract runs without key input);
YES for the attract→gameplay break-out (user presses key during attract)

**Port estimate:** MEDIUM
- Keyboard read itself is small; the $7606-$7696 display helpers may need sorting
  into the correct subsystem before porting
- Gameplay input (movement codes) is NOT here — it's in P0b territory

---

### Subsystem: Sound

**Source files / ranges:**
- `src/sound_engine.s` (= `src/sound.s` Part 1) — $0D00-$0DA5 (166 bytes; 383 lines)
  Multi-nested delay-loop tone generator. Reads variable-length records from
  ZP $F7/$F8 pointer. 5-deep nested timing loop per record; toggles SPKR ($C030).
  Gate: fires only when (ZP $4F AND ZP $86) != 0. 0 trace fires in full-cycle
  trace capture window.
- pcm_player (= `src/sound.s` Part 2) — $0DC0-$0DFF (64 bytes; within 404-line sound.s)
  1-bit delta-PCM. Reads 256 bytes from $0E00-$0EFF. Per bit: delays ZP $BA
  cycles, XOR-tests against accumulator ($9B), toggles SPKR on transition.
  Called: JSR from input.s L763C when ZP $4E timer expires.
- `src/sound_data_0e00.s` — $0E00-$0EFF (256 bytes of PCM data)

**Total:** ~230 bytes engine code + 256 bytes PCM data; 383+404 lines (sound.s
covers both routines)

**ZP footprint:** [ref: sound_engine.s]
$F6 (record index), $F7/$F8 (record-block pointer), $F9 (inner timing value),
$FA/$FB/$FC/$FD/$FE/$FF (timing variables in nested loop), $BA (PCM bit delay),
$9B (running accumulator for delta-PCM), $4E (PCM timer), $4F (sound gate),
$86 (game-active flag).

**HAL surface (predicted):**
- HAL_sound_tone_start → replaces sound_engine.s (tone-record interpreter)
- HAL_sound_dac_sample → replaces pcm_player (1-bit delta-PCM; CoCo3 uses 6-bit DAC)
- The 5-deep timing loop in sound_engine.s becomes CoCo3 DAC timing (different
  hardware; entire loop restructured for DAC rather than speaker click)

**Cross-subsystem coupling:** LOW
- sound_engine.s calls L7603 (keyboard check during playback) — one coupling point
- pcm_player has no subsystem calls

**INT-N criticality:** NOT critical for INT-1/INT-2; needed for INT-3 (full
attract cycle with sound)

**Port estimate:** MEDIUM
- sound_engine.s tone-record interpreter is complex but isolated
- pcm_player is small (64 bytes) but hardware-specific (1-bit Apple II SPKR vs
  6-bit CoCo3 DAC)
- 0 trace fires in the intro captures — cannot compare against Apple II capture
  via compare.py; verification must be WAV pair comparison (per Section 6.7 sound
  exception)

---

### Subsystem: Combat animation + sprite composition

**Source files / ranges:**
- `src/fight_engine.s` — $A000-$A397 (920 bytes; 608 lines)
  Fight AI (fight_ai_a000, 151 fires), LCG routines, entity-state copy
  trampolines (scene_copy_a30c, scene_copy_a316), sprite-parameter loader
  (trampoline_a350). Plus: $A0E7-$A305 (542 bytes) uncharted hi-res bitmap data
  (contains Brøderbund logo sprites at $A126/$A16E — see §5 below).
- `src/attract_dispatch.s` — $AD00-$AFFF (768 bytes; 691 lines)
  8-entry JMP dispatch table, render_row_ad18, draw_two_sprites_ad30,
  draw_combatant_ad56/ad75 (174 fires/cycle each), draw_background_ladd1,
  parallel sprite tables ($ADF7-$AE3E, 18 entries), load_scene_sprite_ae3f
  (1,758 fires/cycle), draw_scene_ae7a (174 fires/cycle).
- `src/attract_render.s` — $B000-$B1FF (512 bytes; 733 lines)
  scene_init_b015, setup_b069 (scene-sprite ZP param primer), per-frame render
  dispatcher ($B0C0-$B1FF, 2 trampolines).
- `src/attract_state.s` — $B200-$B3FF (512 bytes; 809 lines)
  render-setup helpers, attract-mode coupled-state machine (routine_b260 + 3
  step primitives), per-frame state update.
- `src/display_7700.s` ($7800-$7FFD only) — 765 bytes; within 1,148-line file
  jmptable_7800 (7-entry), draw_fight_scene_0-3, scene_init_entry ($79A3),
  fight_round_main ($7AF7), jmptable_7D00, draw_facing_right/left, draw_weapon,
  draw_score_display.

**Total:** ~3,477 bytes; ~2,841 lines

**ZP footprint:** Heavy. Key cluster [ref: data-areas-catalog.md §attract cluster]:
$62/$72 (paired combatant coordinates), $52 (animation phase counter), $91
(orphan position byte — 0 reads in attract trace; possible gameplay-only),
$50/$51 (entity copy buffers), $AB-$AE (sprite-render pipeline), $E0-$E5
(blit destination/source rows).

**HAL surface:** Graphics (heavy) — all sprite blits go through video.s ($1903+);
no direct HAL calls (calls go through engine sprite engine).

**Cross-subsystem coupling:** HIGH
- Calls: video.s ($1903, $190C, $1906), render_frame_0a00.s ($0A00/$0A03/$0A06),
  fight_engine.s (via $A000 fight AI), kernel_per_frame.s (per-frame entry),
  input.s (keyboard check)

**INT-N criticality:** INT-3 (full attract cycle); NOT needed for INT-1/INT-2

**Port estimate:** LARGE (largest subsystem group; most complex ZP state machine)

---

### Subsystem: Cutscene machinery

**Source files / ranges:**
- `src/scene_dispatch.s` (scene5_entry_b400 portion) — $B400-$B4E6 (231 bytes)
  ZP setup pass, engine init calls ($79A3 scene-sprite/animation init, $7003 TBD).
- `src/display_7700.s` (fight_round_main) — $7AF7-$7FFD (775 bytes)
  Main fight-round loop driving approach animation, round transitions, win/lose.
  Called from scene5_entry_b400 init chain ($B4B9 → $79A3 → $7AF7).

**Total:** ~1,006 bytes; split across multiple files

**INT-N criticality:** INT-3 only (Akuma throne room cutscene is in the attract
sequence but is the final scene); NOT needed for INT-1/INT-2

**Port estimate:** LARGE (fight_round_main drives the imprisonment animation +
combat loop; entangled with combat animation rendering)

---

## 4. First-scene identification

[ref: docs/intro-sequence-structure.md §The sequence]
[ref: docs/scene-entries.md §Scene 1]

**The sequence before any content displays:**
1. Boot disk load (disk activity; not relevant to attract port)
2. Screen clear to black
3. Scene 1 starts

**Scene 1: Brøderbund logo + "presents"**

Entry: `routine_b8c2` in `src/intro.s` (~frame 551 in cycle 1).
Preceded by: `routine_b898` ($B77F) which draws two sprite sets at $A126/$A16E
(Brøderbund logo bitmap sprites), then routine_b8c2 renders the "presents" string.

[ref: src/intro.s §outer_caller_b77c scene 1 comment]

**What "scene 1 displays correctly" means concretely:**
- Two Brøderbund logo sprites drawn at specific screen positions
- "presents" text string rendered below/beside the logo using the $0400 font

**Pre-scene: screen clear.** `outer_caller_b77c` calls `jsr L1900` (entry 0 =
routine_190f screen clear) before `routine_b898`. So the very first visible action
is a screen clear (black), then the logo sprites, then the "presents" text.

**No sound in scene 1.** [ref: docs/intro-sequence-structure.md] Scene 1 is
~3-5 seconds of static display; no tone engine activity. Sound comes later.

---

## 5. INT-1 content asset list

INT-1 = "first scene displays correctly" = Scene 1 (Brøderbund logo + "presents")

### INT-1 Content Assets

---

#### Asset 1: Brøderbund logo sprite 1

- **Type:** sprite (Apple II hires bitmap)
- **Source:** `src/fight_engine.s`, embedded in uncharted data block $A0E7-$A305.
  Sprite record starts at $A126 (= offset $3F from $A0E7).
  [ref: src/intro.s routine_b898 — stores $03=$26, $04=$A1 → pointer = $A126]
- **Format:** standard 2-byte sprite header (height-rows, width-bytes) + row-major
  bitmap. Height/width TBD: read bytes at $A126/$A127 from dump01_intro.bin to
  confirm.
  [ref: data-areas-catalog.md §Sprite format — 2-byte header confirmed]
- **Estimated size:** unknown until header bytes read; likely ~40-80 bytes based
  on Brøderbund logo visual complexity
- **Conversion tool:** `sprite_convert.py` (P1.2 tooling)
- **Pre-condition:** sprite record not yet labeled in fight_engine.s (the block
  is emitted as raw `.byte`). Extract by byte offset from dump01_intro.bin;
  read header to determine extent. May warrant a follow-up disassembly task to
  label $A126 and $A16E as named sprite records in fight_engine.s.
  [no-ref: sprite dimensions — need header read from dump01_intro.bin]

---

#### Asset 2: Brøderbund logo sprite 2

- **Type:** sprite (Apple II hires bitmap)
- **Source:** `src/fight_engine.s`, uncharted block. Sprite record starts at
  $A16E (= offset $87 from $A0E7).
  [ref: src/intro.s routine_b898 — stores $03=$6E, $04=$A1 → pointer = $A16E;
  rendered at screen Y=$58, X-byte=$0C]
- **Same considerations as Asset 1.** Headers not yet labeled; must extract by
  offset.

---

#### Asset 3: $0400 font (26 letters + 4 punctuation glyphs)

- **Type:** font — 30 sprite records in the $0400-$067F bank
- **Source:** `src/sprite_data_0400.s` — $0400-$067F (640 bytes; 755 source lines)
  [ref: sprite_data_0400.s header — "30 sprites in this bank form a Karateka-style
  font of mixed-case letter glyphs"]
- **Usage:** `text_render.s` / `render_string` reads font via `font_metrics.s`
  tables ($0680-$06FF), calls sprite engine at $1903 once per glyph. For scene 1,
  the "presents" string uses the glyphs for 'p','r','e','s','e','n','t','s'.
- **Conversion tool:** `sprite_convert.py` per glyph, or batch-convert all 30
  glyphs. All 30 are needed since later scenes use other letters.
- **INT-1 minimum:** only 7 distinct glyphs needed for "presents_" (p,r,e,s,n,t
  + space). Practical: convert all 30 for reuse across scenes 1-4.
- **Confirmed visually:** [ref: sprite_data_0400.s — "confirmed visually 2026-05-07"]

---

#### Asset 4: font metrics tables

- **Type:** data tables (not bitmaps; indirect lookup tables)
- **Source:** `src/font_metrics.s` — $0680-$06FF (128 bytes; 219 lines)
  [ref: data-areas-catalog.md §$0680-$069F font_glyph_lo, $06A0-$06BF
  font_glyph_hi_minus_4, $06C0-$06DF font_glyph_xstep_byte,
  $06E0-$06FF font_glyph_xstep_subbyte]
- **Conversion:** no bitmap conversion; these are index tables that must be
  reproduced in CoCo3 assemblable form pointing to the converted $0400 font
  glyph positions in CoCo3 memory. The glyph address hi/lo bytes change because
  CoCo3 memory layout differs from Apple II.
- **Conversion tool:** mechanical regeneration once CoCo3 glyph addresses are known
  (not a job for sprite_convert.py — needs a font-metric regenerator or hand-edit)
- **Note:** the `font_glyph_hi_minus_4` encoding (high byte stored minus the
  +$04 page offset that text_render.s adds) is Apple II-specific; CoCo3 port
  may store absolute high bytes instead.

---

#### Asset 5: "presents" text string descriptor

- **Type:** text string (encoded data, not a bitmap)
- **Source:** `src/text_strings.s` — string 0 at $B96B = `"presents_"`
  [ref: data-areas-catalog.md §$B96B — `"presents_"` confirmed]
  [ref: scene-entries.md §Scene 1 — "String 0 at $B96B = 'presents_'"]
- **Conversion:** the string encoding itself (ASCII chars with $5F terminator) is
  platform-neutral; reproduce verbatim. The 2-byte X-position header ($0E $03 at
  $B96B) specifies screen-byte X + sub-byte X position — these must be mapped to
  CoCo3 equivalent horizontal positions (different pixel-to-byte ratio: 4px/byte
  on CoCo3 vs 7px/byte on Apple II).
- **Conversion tool:** [no-ref:] no dedicated tool yet; positional adjustment is
  manual or requires a new helper

---

#### Asset 6: initial palette (scene 1)

- **Type:** palette (4-color GIME palette for HAL_gfx_init)
- **Source:** [no-ref:] implicit in the Apple II hires pixel values within assets
  1-3. Apple II hires has no explicit palette — color is determined by bit 7 of
  pixel bytes + pixel position relative to horizontal parity. For scene 1:
  background is black ($80 bytes), letter pixels are white/green hires patterns.
- **Conversion tool:** `palette_derive.py` (P1.2 tooling) — run against the
  converted scene 1 sprite bytes to derive a 4-color GIME palette
- **Pre-condition:** assets 1-3 must be extracted first; palette_derive.py runs
  against those bytes
- **Note:** the initial palette is shared across the "presents" text (asset 3/5)
  and the logo sprites (assets 1-2); one palette serves all scene 1 content

---

#### Summary of INT-1 pre-conditions

1. **Extract and label $A126 and $A16E sprites.** Read dump01_intro.bin at those
   offsets to determine header (height, width) and byte extent. The fight_engine.s
   uncharted block needs these two records labeled as named sprites before
   `sprite_convert.py` can target them cleanly.
2. **Convert $0400 font** (30 glyphs) via sprite_convert.py.
3. **Regenerate font metrics** for CoCo3 glyph addresses.
4. **Adapt "presents" string X-position** for CoCo3 horizontal layout.
5. **Derive initial palette** from extracted scene 1 sprite bytes.

All five are conversion tasks, not engine-port tasks. They feed the INT-1
content-conversion wave, not P2.x subsystem ports.

---

## 6. P2.2 selection summary

### Comparative table

| Subsystem | Lines | Bytes | HAL Surface | Coupling | INT-1 critical | Port estimate |
|-----------|-------|-------|-------------|----------|----------------|---------------|
| Kernel/dispatch | 1,212 | ~482 | Time (VBL), Graphics (page-flip) | HIGH | YES | Medium |
| Blit/graphics | ~1,085 | ~1,148 | Graphics (heavy) | HIGH | YES | Large |
| Scene mgmt (intro.s only) | 710 | ~425 | Time (VBL via L0783) | Medium | YES (scene 1) | Large |
| Display setup/palette | (in video.s) | ~210 | Graphics (init, clear) | Low | YES | Small |
| Sound | 383+404 | ~230 | Sound | Low | NO (INT-3) | Medium |
| Basic keyboard scan | 472 | ~327 | Input | Low | NO | Medium |
| Combat animation | ~2,841 | ~3,477 | Graphics (heavy) | HIGH | NO (INT-3) | Large |
| Cutscene machinery | — | ~1,006 | (via combat) | HIGH | NO (INT-3) | Large |

### P2.2 Recommendation

**Recommended: Kernel/dispatch**
(kernel.s + kernel_per_frame.s + kernel_dispatch.s + kernel_dispatch_handlers.s stub)

**Reasoning:**

1. **Natural continuation of P2.1.** P2.1 was `timer_dispatch.s` — the timer-based
   event handler that fires within the per-frame loop. kernel_per_frame.s IS the
   per-frame loop. Completing the kernel layer (P2.1 timer dispatch → P2.2 per-frame
   orchestrator) before moving to dependent subsystems follows the dependency order.

2. **INT-1 critical, well-scoped.** Kernel/dispatch is on the critical path for
   every integration milestone, yet its scope (~482 bytes, 1,212 lines) is the
   smallest of the INT-1-critical subsystems.

3. **Maximally independent from P2.x content.** The kernel makes HAL calls (VBL
   wait, page-flip/present); those HAL calls are already stubbed. The kernel port
   can be verified via P2.0 compare.py infrastructure using the existing
   `page_register` / `page_source_blit` mapping entries before any sprite or
   scene code is ported.

4. **kernel_dispatch handlers safely stubbed.** The seven handlers at $0C55-$0CBD
   have 0 trace fires in the full-cycle attract trace. Stubbing them for P2.2 is
   correct — they will not execute on the INT-1 through INT-3 attract path.

5. **Surfaces HAL contract gaps before P3 commits.** P2.2 will be the first port
   to exercise HAL_gfx_present and HAL_time_vbl_wait as engine callers (rather
   than just stubbing them). Any contract gap in the Time and partial Graphics
   HAL subsystems surfaces before P3.x real-HAL implementation commits.

**Alternatives considered:**

- **Blit/graphics (video.s):** most independently testable against Apple II sprite
  captures, but LARGE estimate and contains self-modifying code; better as P2.3
  after kernel establishes the per-frame harness. The sprite engine is what
  everything calls, but the caller (kernel/dispatch) should exist first.

- **Scene management (intro.s):** directly exercises scene 1 but has HIGH coupling
  to blit/graphics (can't run without video.s); better as P2.4 after the sprite
  engine is in place.

- **Display setup/palette (video.s entry 0):** SMALL estimate but physically
  embedded in video.s — port it bundled with blit/graphics (P2.3).

**Sequence implication:** P2.3 = blit/graphics (video.s + render_frame_0a00.s
+ display setup bundled), P2.4 = intro.s scene-1 path. After P2.4 + P3.1 HAL
implementations for Graphics + Time → INT-1 reachable. INT-1 content-conversion
wave (§5) runs in parallel with P2.2/P2.3.

---

## 7. Findings beyond plan

### Finding 1: Brøderbund logo sprites not yet labeled in disassembly

The sprites at $A126/$A16E (the Brøderbund logo, first scene 1 assets) are embedded
in fight_engine.s's `$A0E7-$A305` uncharted bitmap block. They are emitted as raw
`.byte` with no sprite-record label, no confirmed header read, and no visual
identification. [ref: fight_engine.s §$A0E7-$A305 — "Uncharted; no sprite header
or per-scene pointer evidence. Emitted as .byte."]

The sprites are functionally correct (routine_b898's explicit immediate stores to
$03/$04 confirm they are at those addresses). But the INT-1 content-conversion
wave needs to extract them by byte offset and read the 2-byte header before
sprite_convert.py can process them. This is a labeling gap in karateka_dissasembly_claude,
not a functional blocker — but it adds a pre-condition step to the INT-1 wave.

**Implication:** The INT-1 content-conversion wave begins with "read header bytes
at $A126/$A127 and $A16E/$A16F from dump01_intro.bin to determine sprite extents."
This is a read from dumps/ (karateka_dissasembly_claude), not a commit.

### Finding 2: kernel_dispatch handlers functionally unknown

The seven handlers at $0C55-$0CBD have unknown behavioral purposes. They are not
reached in the intro/attract trace. This means:
- They can be safely stubbed for INT-1 through INT-3
- Their behavior only matters for P0b gameplay paths (Ctrl-key debug functions,
  possibly score/round state updates)
- No plan deviation — just a note for the P0b era

### Finding 3: $7606-$7696 display helpers mixed into input.s

input.s's header explicitly notes that the display/page-flip helpers at $7606-$7696
"may migrate to src/video.s or src/kernel.s in a future commit." [ref: input.s
header §PURPOSE] When porting input.s, these helpers should be sorted into the
correct CoCo3 subsystem (likely kernel/dispatch or blit/graphics) rather than
carried into the input port.

### Finding 4: $0A00-$0AFF render engine callers span two subsystems

render_frame_0a00.s ($0A00-$0AFF) is called by both attract_render.s/attract_state.s
(combat animation subsystem) AND intro.s (scene management subsystem). This means
render_frame_0a00.s must be ported before either caller subsystem. It should be
bundled with blit/graphics (P2.3).

### Finding 5: font metrics require positional remapping for CoCo3

The `font_glyph_hi_minus_4` encoding and the 2-byte string X-position headers
(screen-byte X, sub-byte X in 0-6 range) are Apple II-specific (7 pixels/byte).
CoCo3 uses 4 pixels/byte (2 bits/pixel in 320×192 mode). The "presents" string
position ($0E $03 header) places text at specific Apple II byte positions; CoCo3
equivalent requires a pixel-position recalculation. This is a content-conversion
consideration, not an engine-port finding, but it means the font-metrics tables
will need regeneration rather than verbatim copy.

---

## 8. Reference citations

Throughout this document:

- `[ref: docs/intro-sequence-structure.md]` — Jay's authoritative sequence description
- `[ref: docs/scene-entries.md]` — per-scene entry points with trace evidence
- `[ref: docs/data-areas-catalog.md]` — ZP pointer map and sprite-bank catalog
- `[ref: docs/differential-analysis.md]` — per-dump register/ZP state
- `[ref: src/kernel.s header]` — VBL sync + page-flip architecture
- `[ref: src/kernel_per_frame.s header]` — per-frame dispatcher structure
- `[ref: src/kernel_dispatch_handlers.s header]` — 0 trace fires finding
- `[ref: src/video.s header]` — jmptable_1900, draw-A/B, self-modifying code
- `[ref: src/render_frame_0a00.s header]` — pixel blit passes, trace counts
- `[ref: src/display_7700.s header]` — blit_hires_page, vbl_sync trace counts
- `[ref: src/input.s header]` — display helpers note, keyboard handler scope
- `[ref: src/sound_engine.s header]` — tone generator, gate condition, 0 trace fires
- `[ref: src/intro.s header + outer_caller_b77c comment]` — scene 1 structure
- `[ref: src/fight_engine.s header]` — uncharted data block $A0E7-$A305
- `[ref: src/sprite_data_0400.s header]` — font visual confirmation
- `[ref: src/sprite_data_logo.s header]` — scene-3 logo sprites
- `[ref: karateka-coco3 docs/hal.md]` — HAL subsystem functions
- `[ref: karateka-coco3 verification/mapping.json]` — confirmed P2.1 ZP mappings

**[no-ref:] items:**
- Brøderbund logo sprite dimensions at $A126/$A16E — need header read from
  dump01_intro.bin
- Initial palette for scene 1 — implicit in sprite byte values; no explicit
  Apple II palette document
- CoCo3 equivalent horizontal positions for "presents" string — requires pixel/byte
  ratio conversion (7px/byte Apple II → 4px/byte CoCo3)
