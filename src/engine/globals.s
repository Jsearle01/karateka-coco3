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
*   [ref: docs/conventions.md §2 — DP band allocations]
*   [ref: docs/memory-map.md §4.1 — DP is physical page $38 offset 0]
*   [ref: src/hal.inc — HAL_ZP_BASE, calling conventions]
*
* ---------------------------------------------------------------

        setdp   0

* ---------------------------------------------------------------
* HAL scratch band $00-$1F
* [ref: docs/conventions.md §2 — $00-$1F HAL scratch (reserved)]
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
* [ref: docs/conventions.md §2 — $50-$5F frame-coherent variables]
*
* CONVENTION (Option I, project-canonical per P2.3a.6-followup-1):
*   page_register identifies the BACK BUFFER (active draw target).
*   HAL_gfx_present displays the buffer page_register points at.
*   Caller flow: draw to back → HAL_gfx_present (shows just-drawn) → toggle.
*   $20 = buffer A ($8000-range) is the draw target.
*   $40 = buffer B ($C000-range) is the draw target.
*   See docs/conventions.md §2 CONVENTION NOTE for full explanation.
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
* [ref: docs/conventions.md §2 — engine-owned; allocated during P2]
* Currently unallocated; specific allocations added to this file
* when assigned during P2 engine porting.
* ---------------------------------------------------------------

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
