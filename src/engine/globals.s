* src/engine/globals.s
*
* Project-wide DP allocations and constants.
* Single source of truth for DP variable assignments and shared
* constants across engine and HAL subsystems.
*
* USAGE in production multi-file builds:
*   Listed alongside all other .s files in the lwasm invocation.
*   All symbols defined here are visible to all other files in the
*   same lwasm pass. Individual source files no longer declare these
*   variables locally (except test drivers, which maintain inline
*   self-contained equ declarations per the self-contained build
*   pattern — test driver values must match the canonical values here).
*
* USAGE in test drivers:
*   Test drivers keep their own inline equ declarations. globals.s is
*   NOT included in single-file test driver builds. Test driver values
*   must be manually kept in sync with the canonical values below.
*
* Reference citations:
*   [ref: docs/project/conventions.md §2 — DP band allocations]
*   [ref: docs/project/memory-map.md §4.1 — DP is physical page $38 offset 0]
*   [ref: src/hal.inc — HAL_ZP_BASE, calling conventions]
*
* ---------------------------------------------------------------

        setdp   0

* ---------------------------------------------------------------
* HAL scratch band $00-$1F
* [ref: docs/project/conventions.md §2 — $00-$1F HAL scratch (reserved)]
* [ref: src/hal.inc — HAL_ZP_BASE, HAL_ZP_PARAM0-3, HAL_ZP_PTR0-1]
*
* $00-$03: HAL_ZP_PARAM0-3 (byte parameter scratch; defined in hal.inc)
* $04-$05: HAL_ZP_PTR0      (pointer scratch 0; defined in hal.inc)
* $06-$07: HAL_ZP_PTR1      (pointer scratch 1; defined in hal.inc)
* $08-$0F: reserved for HAL internal use
* ---------------------------------------------------------------

* --- HAL time subsystem ($10-$11) ---
hal_frame_hi        equ $10     ; frame counter high byte (time.s; P2.1)
hal_frame_lo        equ $11     ; frame counter low byte  (time.s; P2.1)

* --- HAL gfx subsystem ($12) ---
gfx_initialized     equ $12     ; $00=not init; $01=HAL_gfx_init done (gfx.s; P2.3a)

* --- HAL sys subsystem ($13) ---
sys_init_cc_mask    equ $13     ; CC value captured post-HAL_sys_init by test driver
                                ; predicted $50 & mask (I=1,F=1); test diagnostic only
                                ; [ref: src/hal/coco3-dsk/sys.s — P2.3a.0]

* $14-$1F: reserved for future HAL subsystem allocations

* ---------------------------------------------------------------
* Engine frame-coherent band $50-$5F
* [ref: docs/project/conventions.md §2 — $50-$5F frame-coherent variables]
*
* CONVENTION (Option I, project-canonical per P2.3a.6-followup-1):
*   page_register identifies the BACK BUFFER (active draw target).
*   HAL_gfx_present displays the buffer page_register points at.
*   Caller flow: draw to back → HAL_gfx_present (shows just-drawn) → toggle.
*   $20 = buffer A ($8000-range) is the draw target.
*   $40 = buffer B ($C000-range) is the draw target.
*   See docs/project/conventions.md §2 CONVENTION NOTE for full explanation.
*   [ref: src/hal/coco3-dsk/gfx.s — HAL_gfx_present Option I implementation]
* ---------------------------------------------------------------
page_register       equ $50     ; active draw buffer ($20=buf-A, $40=buf-B)
page_source_blit    equ $51     ; prior draw buffer (blit source; P2.1)
frame_done          equ $52     ; frame sync reference value ($D0 analog; P2.2)
frame_countdown     equ $53     ; frame down-counter ($D2 analog; P2.2)
frame_sync_dc       equ $54     ; frame sync state flag ($DC analog; P2.2)

* $55-$5F: reserved for future engine frame-coherent use

* ---------------------------------------------------------------
* Engine working / combat bands $20-$4F, $60-$7F
* [ref: docs/project/conventions.md §2 — engine-owned; allocated during P2]
* Specific allocations added to this file when assigned during P2
* engine porting.
* ---------------------------------------------------------------

* ---------------------------------------------------------------
* Sprite/animation engine state block ($30-$3A) — R-engine.
* ONE generic data-driven animation core (src/engine/sprite_engine.s);
* characters are DATA (an animation table + a sprite set). This block is
* one character's runtime state; it scales to a per-character struct array
* for multi-character scenes (scene 6 / combat, INT-3).
* Allocated in the engine working band (away from HAL $00-$13, frame-coherent
* $50-$5F, intro $60-$61, scene-4 scroll $62-$6E).
* [ref: src/engine/sprite_engine.s — eng_anim_init / eng_tick / eng_render]
* ---------------------------------------------------------------
eng_tbl             equ $30     ; 16-bit: active animation-table pointer — $30/$31
eng_idx             equ $32     ; 8-bit:  current frame index (0..count-1)
eng_cnt             equ $33     ; 8-bit:  frame count (cycle length)
eng_cad             equ $34     ; 8-bit:  cadence reload (VBL frames per anim frame)
eng_cadctr          equ $35     ; 8-bit:  cadence down-counter
eng_clrw            equ $36     ; 8-bit:  clear-box width  (bytes)
eng_clrh            equ $37     ; 8-bit:  clear-box height (rows)
eng_col             equ $38     ; 8-bit:  current frame byte column (scratch from table)
eng_sub             equ $39     ; 8-bit:  current frame sub-byte offset (0-3)
eng_row             equ $3A     ; 8-bit:  current frame pixel row

* --- Engine intro / scene-1 state ($60-$61) — R-p24 ---
* Game-start signal flags set by scene-1 input detection. Apple II
* analogs: $86 ("input received") and $4F (companion); both set to $01
* by LB7DE on key/button press. The game-start consumer is STUBBED
* until R-p25 (scene 2). Cleared at scene-1 controller entry (boot.s).
* [ref: karateka_dissasembly_claude/src/intro.s LB7DE — $86/$4F=$01]
intro_input_flag    equ $60     ; $86 analog: input-received signal
intro_inputaux_flag equ $61     ; $4F analog: companion flag

* ---------------------------------------------------------------
* Scene-4 scroll engine scratch (R-p26; engine working DP band).
* Used only during the scene-4 VOFFSET sliding-window scroll.
* ---------------------------------------------------------------
s4_scroll_s         equ $62     ; 16-bit: current scroll position S (rows) — $62/$63
s4_next_top         equ $64     ; 16-bit: next line-slot logical top row    — $64/$65
s4_dest_row         equ $66     ; 16-bit: scroll-blit dest physical row      — $66/$67
s4_next_slot        equ $68     ; 8-bit:  next slot index to refill (0..)
s4_kcount           equ $69     ; 8-bit:  VBL-cadence down-counter (frames/step)
s4_copy_i           equ $6A     ; 16-bit: incremental copy-down row index (0..SHIFT) — $6A/$6B
s4_base             equ $6C     ; 16-bit: logical row of buffer row 0 (rebase accumulator) — $6C/$6D
s4_ctmp             equ $6E     ; 8-bit:  copy-loop word counter (ldd clobbers B, so count in mem)

* ---------------------------------------------------------------
* Shared constants (used by both engine and HAL)
* ---------------------------------------------------------------

* Page-flip tokens (Option I convention: page_register identifies BACK buffer;
* HAL_gfx_present displays the buffer page_register points at).
* [ref: src/hal/coco3-dsk/gfx.s HAL_gfx_present — Option I implementation]
* [ref: src/engine/timer_framesync.s — page flip logic]
*
* Heritage note: PAGE_A_TOKEN ($20) and PAGE_B_TOKEN ($40) are inherited
* from Apple II Karateka source where $20/$40 are the high bytes of the
* hires display page base addresses ($2000 = page 1, $4000 = page 2).
* On CoCo3, these values are OPAQUE TOKENS identifying which buffer is the
* active draw target. They have no CoCo3 hardware significance; the $20/$40
* values were retained for continuity with the Apple II source reference.
* [ref: karateka_dissasembly_claude/src/kernel.s — $07 draw page: $20/$40]
PAGE_A_TOKEN        equ $20     ; draw target = buffer A ($8000-range); Apple II page 1 heritage
PAGE_B_TOKEN        equ $40     ; draw target = buffer B ($C000-range); Apple II page 2 heritage
