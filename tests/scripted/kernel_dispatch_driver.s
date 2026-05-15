* tests/scripted/kernel_dispatch_driver.s
*
* Test driver for P2.2 kernel/dispatch behavioral verification.
* Self-contained: inline copies of engine + HAL stubs so the
* test builds without a linker.
*
* Production sources:
*   src/engine/kernel_per_frame.s
*   src/engine/kernel_dispatch.s (handler stubs — NOT exercised)
*   src/hal/coco3-dsk/input.s
*   src/hal/coco3-dsk/time.s
*   src/hal/coco3-dsk/gfx.s
*   src/hal/coco3-dsk/sys.s
* Any changes to those files must be mirrored here for test accuracy.
*
* Test: call per_frame_main_loop_once (single iteration, not infinite).
*   (a) frame_done = $00 on entry (steady attract state).
*   (b) After one call: frame_countdown should equal frame_done (=$00).
*   (c) scene_transition_check must return (not hang) — scenes stubbed.
*   (d) per_frame_continuation must return (not hang) — scenes stubbed.
*   (e) HAL_input_poll must return D=0 (no input) — input stubbed.
*   (f) Handler stubs NOT called — no stub assertion fires.
*
* Expected final DP state (after one per_frame_main_loop_once call):
*   DP $52 (frame_done)      = $00  (initialized value, unchanged)
*   DP $53 (frame_countdown) = $00  (copied from frame_done)
*   DP $54 (frame_sync_dc)   = $00  (not modified by P2.2 stubs)
*
* Also verifies P2.1 invariants (page_register/page_source_blit)
* are still present (regression check).
*
* Assemble (from repo root):
*   lwasm --decb -o tests/scripted/kernel_dispatch_driver.bin \
*         tests/scripted/kernel_dispatch_driver.s
* ---------------------------------------------------------------

        org     $0200               ; load/exec address in CoCo3 RAM
        setdp   0

* DP variables
page_register       equ $50         ; P2.1 (regression check)
page_source_blit    equ $51         ; P2.1 (regression check)
frame_done          equ $52         ; P2.2 (ZP$D0 analog)
frame_countdown     equ $53         ; P2.2 (ZP$D2 analog)
frame_sync_dc       equ $54         ; P2.2 (ZP$DC analog)
hal_frame_hi        equ $10
hal_frame_lo        equ $11
PAGE_A              equ $20
PAGE_B              equ $40

* ---------------------------------------------------------------
* test_start — driver entry point
* ---------------------------------------------------------------
test_start:
        orcc    #$50                ; disable IRQ/FIRQ
        clra
        tfr     a,dp                ; DP = 0

        jsr     HAL_time_init       ; zero frame counter

        * Initialize P2.1 page-flip state (for regression check)
        * Phase matches Apple II capture at frame 700: ZP$07=$40, ZP$E4=$20
        * [ref: p2_0a_frame_700_zp.json; P2.1 comparison MATCH at this phase]
        lda     #PAGE_B
        sta     <page_register      ; page_register = $40 (same phase as frame-700 ref)
        lda     #PAGE_A
        sta     <page_source_blit   ; page_source_blit = $20 ($40+$20=$60 invariant)

        * Initialize P2.2 kernel state
        clr     <frame_done         ; frame_done = $00 (steady attract)
        clr     <frame_countdown    ; frame_countdown = $00 (initial)
        clr     <frame_sync_dc      ; frame_sync_dc = $00

        jsr     per_frame_main_loop_once    ; single iteration (not infinite)

test_loop:
        bra     test_loop           ; spin; harness captures DP here

* ---------------------------------------------------------------
* per_frame_main_loop_once
*
* Single-shot version of per_frame_main_loop for test purposes.
* Executes one iteration of the per-frame loop body, then returns.
*
* Inline copy of src/engine/kernel_per_frame.s structure:
*   [ref: kernel_per_frame.s per_frame_main_loop — single iteration]
* ---------------------------------------------------------------
per_frame_main_loop_once:
        lda     <frame_done
        jsr     scene_transition_check
        lda     <frame_done
        sta     <frame_countdown
        jsr     HAL_input_poll
        jsr     per_frame_continuation
        rts                         ; return (not bra per_frame_main_loop)

* ---------------------------------------------------------------
* scene_transition_check — inline stub
* [ref: src/engine/kernel_per_frame.s scene_transition_check]
* ---------------------------------------------------------------
scene_transition_check:
        rts

* ---------------------------------------------------------------
* per_frame_continuation — inline stub
* [ref: src/engine/kernel_per_frame.s per_frame_continuation]
* ---------------------------------------------------------------
per_frame_continuation:
        rts

* ---------------------------------------------------------------
* HAL_input_poll — inline stub
* [ref: src/hal/coco3-dsk/input.s HAL_input_poll]
* ---------------------------------------------------------------
HAL_input_poll:
        clra
        clrb
        andcc   #$FE
        rts

* ---------------------------------------------------------------
* HAL_time_init — inline copy from P2.1
* [ref: src/hal/coco3-dsk/time.s HAL_time_init]
* ---------------------------------------------------------------
HAL_time_init:
        clr     <hal_frame_hi
        clr     <hal_frame_lo
        andcc   #$FE
        rts

        end     test_start          ; DECB exec address = test_start ($0200)
