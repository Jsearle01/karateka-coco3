* tests/scripted/sprite_engine_trace_driver.s
*
* R-engine AUTOMATED TRACE driver (P2/P3, agent-verifiable).
*
* Same single-source engine + HAL as the interactive sandbox
* (sprite_engine_sandbox_driver.s), but with NO input gate: it free-runs
* eng_tick every VBL so the harness Lua can trace cadence/cycle/flip from
* memory without injecting keystrokes. The interactive sandbox is paused-
* by-default (tap=step / hold=run) for Jay's live P4 gate; THIS driver
* exists only so P2/P3 reproduce unattended.
*
* Boot-excluded (AC-5): not on the production boot path.
*
* Assemble (from repo root):
*   lwasm --decb -o tests/scripted/sprite_engine_trace.bin \
*         tests/scripted/sprite_engine_trace_driver.s
* [ref: tests/scripted/sprite_engine_sandbox_driver.s — interactive variant]
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

        org     $0200
        setdp   0

        include "../../src/engine/globals.s"

AKUMA_COL       equ 34
AKUMA_ROW       equ 80
AKUMA_CLRW      equ 10
AKUMA_CLRH      equ 19
AKUMA_CADENCE   equ 8               ; fast cadence: trace many advances quickly

test_start:
        orcc    #$50
        lds     #$01FF
        clra
        tfr     a,dp

        jsr     HAL_sys_init
        jsr     HAL_time_init
        lda     #$00
        jsr     HAL_gfx_init
        jsr     HAL_input_init

        lda     #PAGE_A_TOKEN
        sta     <page_register
        andcc   #$EF                ; opt in to real VBL IRQ

        ldx     #akuma_anim
        jsr     eng_anim_init

trace_loop:
        jsr     HAL_time_vbl_wait
        jsr     eng_tick            ; unconditional free-run (cadence advance)
        bra     trace_loop

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

        include "../../src/engine/sprite_engine.s"
        include "../../src/hal/coco3-dsk/sys.s"
        include "../../src/hal/coco3-dsk/irq_vbl.s"
        include "../../src/hal/coco3-dsk/gfx.s"
        include "../../src/hal/coco3-dsk/time.s"
        include "../../src/hal/coco3-dsk/input.s"

        include "../../content/akuma/akuma_frame_0/converted.s"
        include "../../content/akuma/akuma_frame_1/converted.s"
        include "../../content/akuma/akuma_frame_2/converted.s"
        include "../../content/akuma/akuma_frame_3/converted.s"
        include "../../content/akuma/akuma_frame_4/converted.s"
        include "../../content/akuma/akuma_frame_5/converted.s"
        include "../../content/akuma/akuma_frame_6/converted.s"
        include "../../content/akuma/akuma_frame_7/converted.s"
        include "../../content/akuma/akuma_frame_8/converted.s"

        end     test_start
