* tests/scripted/sprite_engine_princess_driver.s
*
* PRINCESS CONTROLLER SANDBOX (R-engine) — the scene-5 princess WALK-IN,
* isolated. Exercises the REAL controller (src/engine/princess_controller.s)
* + REAL engine (eng_clear_box) + REAL HAL by INCLUDE. Boot-excluded
* (AC-7): built only by run_sprite_engine_princess.sh, never on prod boot.
*
* Runs the princess walk-in as a LIVE animation: leg cycle 1->4 (oracle $39),
* per-cycle position step (+2 byte-cols = 8px, GATE-1 native integer), the
* 4-sprite composite (body+part6+leg+part7) via the shared leaf, dirty-rect
* restore behind her (eng_clear_box). pr_x (the $3B-analog) free-runs + wraps
* (isolated walk-in; the FALL is the scene $3B clock, pass one — out of scope).
*
* VBL-locked (real GIME VBL IRQ via andcc #$EF); true 60 fps at real-time.
* [ref: docs/project/reports/2026-06-14-scene5-recon.md + the princess pre-flight]
* ---------------------------------------------------------------

        org     $0100
        rti
        nop
        nop
        rti
        nop
        nop
        rti
        nop
        nop
        rti
        nop
        nop
        rti                             ; $010C IRQ (patched -> hal_vbl_handler)
        nop
        nop
        rti
        nop
        nop

        org     $0200
        setdp   0

        include "../../src/engine/globals.s"

FB_A_LO         equ $8000
FB_A_HI         equ $BC00
FB_B_LO         equ $C000
FB_B_HI         equ $FC00

pk_prevkey      equ $40         ; key edge-detect
pk_demo         equ $41         ; demo state selector 0=walk 1=turn 2=fall

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
        andcc   #$EF

        ; index-0 stays BLACK (default palette) = the shadow color; FLOOR = index-2
        ; (blue). pr_set_state clears both buffers to the floor + renders frame 0.
        ; TAP ANY KEY -> toggle: 0 WALK(loop) <-> 1 TURN->delay->COLLAPSE->loop.
        clr     <pk_prevkey
        lda     #$01                    ; default = full chain (tap a key -> walk-loop)
        sta     <pk_demo
        lda     #STATE_STAND
        jsr     pr_set_state

princess_loop:
        jsr     HAL_time_vbl_wait
        jsr     HAL_input_poll
        bcc     pl_nokey
        lda     <pk_prevkey
        bne     pl_held
        lda     #$01
        sta     <pk_prevkey
        inc     <pk_demo
        lda     <pk_demo
        cmpa    #2
        blo     pl_set
        clr     <pk_demo
pl_set:
        lda     <pk_demo                ; 0 = WALK-loop, 1 = full chain (STAND...)
        beq     pl_setst
        lda     #STATE_STAND
pl_setst:
        jsr     pr_set_state            ; switch + clear + render
        bra     princess_loop
pl_held:
        bra     princess_loop
pl_nokey:
        clr     <pk_prevkey
        jsr     pr_tick
        bra     princess_loop

clear_both_buffers:
        ldx     #FB_A_LO
        ldd     #$AAAA                  ; floor = index-2 (blue) so the black shadow shows
pcb_a:
        std     ,x++
        cmpx    #FB_A_HI
        blo     pcb_a
        ldx     #FB_B_LO
pcb_b:
        std     ,x++
        cmpx    #FB_B_HI
        blo     pcb_b
        rts

* --- REAL engine + controller + HAL (single source, by include) ---
        include "../../src/engine/sprite_engine.s"
        include "../../src/engine/princess_controller.s"
        include "../../src/hal/coco3-dsk/sys.s"
        include "../../src/hal/coco3-dsk/irq_vbl.s"
        include "../../src/hal/coco3-dsk/gfx.s"
        include "../../src/hal/coco3-dsk/time.s"
        include "../../src/hal/coco3-dsk/input.s"

* --- princess content (walk legs + body + composite parts) ---
        include "../../content/princess/fig_1D36/converted.s"
        include "../../content/princess/fig_1D5A/converted.s"
        include "../../content/princess/fig_1D7E/converted.s"
        include "../../content/princess/fig_1DA2/converted.s"
        include "../../content/princess/fig_1D00/converted.s"
        include "../../content/princess/fig_1CD4/converted.s"
        include "../../content/princess/fig_1CC4/converted.s"
        ; turn sequence
        include "../../content/princess/fig_1530/converted.s"
        include "../../content/princess/fig_1588/converted.s"
        include "../../content/princess/fig_1611/converted.s"
        include "../../content/princess/fig_169A/converted.s"
        ; fall sequence
        include "../../content/princess/fig_16CC/converted.s"
        include "../../content/princess/fig_175E/converted.s"
        include "../../content/princess/fig_17D3/converted.s"
        include "../../content/princess/fig_1829/converted.s"
        ; chain lead-ins: rest legs ($1DD7) + head-bow ($1867)
        include "../../content/princess/fig_1DD7/converted.s"
        include "../../content/princess/fig_1867/converted.s"

        end     test_start
