* tests/scripted/sprite_engine_sandbox_driver.s
*
* Sprite/animation ENGINE SANDBOX (R-engine, P2/P3/P4 harness).
*
* Exercises the REAL single-source animation engine (src/engine/
* sprite_engine.s) against the REAL HAL — by INCLUDE, never by copy.
* This driver is the ONLY thing not shared with production: it supplies a
* boot-excluded entry point + a character animation table (DATA). The
* engine, HAL, and globals are the production sources, included verbatim,
* so a sandbox pass is a production-code pass (no drift, AC-5/AC-6).
*
* BOOT-EXCLUDED (AC-5): this file is NOT on the production boot path
* (boot.s never references it; it is built only by its own runner,
* run_sprite_engine_sandbox.bat/.sh). Building production never assembles
* this driver.
*
* WHAT IT PROVES:
*   - the engine cycles a character's frame sequence (DATA-driven: change
*     the table, change the animation — no engine edit) at a tunable
*     cadence, clearing + re-blitting through the proven Option-I A/B flip;
*   - on the Akuma 9-frame set (content/akuma_frame_0..8 — converted by
*     address from the unlabeled oracle bank).
*
* CONTROLS (P4 live gate) — starts PAUSED on frame 0:
*   - TAP any key:  SINGLE-STEP — advance exactly one frame per press (edge).
*   - HOLD any key:  FREE-RUN — auto-advance every CADENCE VBLs while held;
*                    release to pause again.
*   Nothing auto-runs unless you hold a key, so the cadence can never feel
*   "too fast" — you drive it. (Set-select is a one-line table-pointer swap
*    in eng_anim_init; only the Akuma set is converted, so one set is wired.)
*
* TIMING (AC-1 basis): the loop is VBL-locked (real GIME VBL IRQ, opted in
*   via andcc #$EF after HAL_time_init). At real-time (Jay's interactive
*   MAME) that is true 60 fps; render+flip must complete within one VBL
*   period — see docs for the HS-1 cycle budget.
*
* Assemble (from repo root):
*   lwasm --decb -o build/sprite_engine_sandbox.bin \
*         tests/scripted/sprite_engine_sandbox_driver.s
*
* [ref: src/engine/sprite_engine.s — the engine under test]
* [ref: tests/scripted/visual_smoke_driver.s — proven Option-I A/B flip]
* [ref: docs/verification-plan_engine-core.md — P2/P3/P4]
* ---------------------------------------------------------------

* ---------------------------------------------------------------
* Segment 1: interrupt-handler dispatch block $0100-$0111.
* RTI stubs; HAL_time_init patches $010C -> hal_vbl_handler (irq_vbl.s).
* ---------------------------------------------------------------
        org     $0100

        rti                             ; $0100 SWI3
        nop
        nop
        rti                             ; $0103 SWI2
        nop
        nop
        rti                             ; $0106 SWI
        nop
        nop
        rti                             ; $0109 NMI
        nop
        nop
        rti                             ; $010C IRQ  (patched -> hal_vbl_handler)
        nop
        nop
        rti                             ; $010F FIRQ
        nop
        nop

* ---------------------------------------------------------------
* Segment 2: sandbox entry $0200.
* globals.s (equates only, 0 bytes) included first so all eng_*/
* page_register/PAGE_*_TOKEN symbols are defined.
* ---------------------------------------------------------------
        org     $0200
        setdp   0

        include "../../src/engine/globals.s"

* Akuma anchor: byte col 34 (px 136), row 80. Frame 7 is the widest
* (9 bytes -> col+9=43 <= 80); frame 6 is the tallest (19 rows ->
* row+19=99 <= 192). Clear box 10 x 19 covers every frame at the anchor
* (9 bytes + 1 sub-byte-overflow margin; 19 rows).
AKUMA_COL       equ 34
AKUMA_ROW       equ 80
AKUMA_CLRW      equ 10
AKUMA_CLRH      equ 19
AKUMA_CADENCE   equ 20              ; VBLs per frame while HELD (~3 fps) — TUNABLE, Jay-gated
HOLD_THRESH     equ 25              ; key down this many VBLs => free-run (else = single tap)

* Sandbox-local input state (engine band $40-$41; clear of eng_* $30-$3A).
sb_prevkey      equ $40             ; nonzero = key was down on the previous poll
sb_holdctr      equ $41             ; consecutive VBLs the key has been held

test_start:
        orcc    #$50                ; mask IRQ/FIRQ during setup
        lds     #$01FF              ; stack above dispatch block
        clra
        tfr     a,dp                ; DP = 0

        * HAL INIT ORDER (subset needed by the sandbox; hal.inc §0-4)
        jsr     HAL_sys_init        ; mask + $FF90 + MMU
        jsr     HAL_time_init       ; zero frame ctr; patch $010C; enable GIME VBL
        lda     #$00                ; descriptor 0 (Brøderbund palette)
        jsr     HAL_gfx_init        ; GIME mode + clear both buffers
        jsr     HAL_input_init      ; PIA0 data-register mode

        * page_register = buffer A is the draw target (back buffer).
        lda     #PAGE_A_TOKEN
        sta     <page_register

        * Opt in to real VBL IRQ: unmask CC.I only (clear bit 4).
        * HAL_time_init already enabled VBORD + IEN; now allow the CPU to
        * take the IRQ so HAL_time_vbl_wait blocks on the real frame ctr.
        andcc   #$EF

        * Load the Akuma animation table + render frame 0 (then PAUSED).
        clr     <sb_prevkey
        clr     <sb_holdctr
        ldx     #akuma_anim
        jsr     eng_anim_init

* ---------------------------------------------------------------
* Run loop — VBL-locked. PAUSED by default. Edge (rising) = single-step
* one frame; holding past HOLD_THRESH VBLs = free-run at cadence.
* ---------------------------------------------------------------
sandbox_loop:
        jsr     HAL_time_vbl_wait   ; pace at one real VBL (60 fps at real-time)
        jsr     HAL_input_poll      ; CC.C set = key/button down
        bcc     sb_key_up

        * --- key is DOWN ---
        lda     <sb_prevkey
        bne     sb_key_held         ; was down last poll -> held
        * rising edge: single-step exactly one frame
        lda     #$01
        sta     <sb_prevkey
        clr     <sb_holdctr
        jsr     eng_step
        bra     sandbox_loop
sb_key_held:
        inc     <sb_holdctr
        lda     <sb_holdctr
        cmpa    #HOLD_THRESH
        blo     sandbox_loop        ; not held long enough: stay paused on this frame
        jsr     eng_tick            ; held: free-run (advance every CADENCE VBLs)
        bra     sandbox_loop

sb_key_up:
        clr     <sb_prevkey         ; reset edge detector
        clr     <sb_holdctr
        bra     sandbox_loop        ; PAUSED: hold current frame

* ---------------------------------------------------------------
* akuma_anim — the Akuma character (DATA): one animation table + its
* sprite set. The engine is generic; THIS is what makes it "Akuma".
* Header: frame_count, cadence, clear_w, clear_h.
* Entry (x9): fdb sprite_ptr ; fcb byte_col, subbyte, row.
* All 9 frames share the anchor (engine cycles the set in place).
* ---------------------------------------------------------------
akuma_anim:
        fcb     9,AKUMA_CADENCE,AKUMA_CLRW,AKUMA_CLRH
        fdb     akuma_frame_0_coco3
        fcb     AKUMA_COL,0,AKUMA_ROW
        fdb     akuma_frame_1_coco3
        fcb     AKUMA_COL,0,AKUMA_ROW
        fdb     akuma_frame_2_coco3
        fcb     AKUMA_COL,0,AKUMA_ROW
        fdb     akuma_frame_3_coco3
        fcb     AKUMA_COL,0,AKUMA_ROW
        fdb     akuma_frame_4_coco3
        fcb     AKUMA_COL,0,AKUMA_ROW
        fdb     akuma_frame_5_coco3
        fcb     AKUMA_COL,0,AKUMA_ROW
        fdb     akuma_frame_6_coco3
        fcb     AKUMA_COL,0,AKUMA_ROW
        fdb     akuma_frame_7_coco3
        fcb     AKUMA_COL,0,AKUMA_ROW
        fdb     akuma_frame_8_coco3
        fcb     AKUMA_COL,0,AKUMA_ROW

* ---------------------------------------------------------------
* REAL engine + REAL HAL (included verbatim — single source of truth).
* ---------------------------------------------------------------
        include "../../src/engine/sprite_engine.s"
        include "../../src/hal/coco3-dsk/sys.s"
        include "../../src/hal/coco3-dsk/irq_vbl.s"
        include "../../src/hal/coco3-dsk/gfx.s"
        include "../../src/hal/coco3-dsk/time.s"
        include "../../src/hal/coco3-dsk/input.s"

* ---------------------------------------------------------------
* Akuma sprite set — converted by address (content/akuma_frame_N).
* ---------------------------------------------------------------
        include "../../content/akuma_frame_0/converted.s"
        include "../../content/akuma_frame_1/converted.s"
        include "../../content/akuma_frame_2/converted.s"
        include "../../content/akuma_frame_3/converted.s"
        include "../../content/akuma_frame_4/converted.s"
        include "../../content/akuma_frame_5/converted.s"
        include "../../content/akuma_frame_6/converted.s"
        include "../../content/akuma_frame_7/converted.s"
        include "../../content/akuma_frame_8/converted.s"

        end     test_start
