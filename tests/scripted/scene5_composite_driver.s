* tests/scripted/scene5_composite_driver.s
*
* SCENE-5 THRONE STAGE + COMPOSITE LAYER (the static guard) — gated visually.
* Renders the gated 1a throne module (scene5_throne_stage.s) then the scene-5
* composite layer (scene5_composite.s — the static guard) OVER it, to BOTH
* buffers once, then holds (the guard is static — capture-confirmed). Boot-excluded.
* HS-3: the guard lives in the composite layer, NOT in the throne module.
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

        ; paint throne + guard to BOTH buffers once, then hold (static).
        jsr     HAL_time_vbl_wait
        jsr     draw_throne_stage
        jsr     draw_scene5_guard
        jsr     HAL_gfx_present
        lda     <page_register
        eora    #$60
        sta     <page_register
        jsr     HAL_time_vbl_wait
        jsr     draw_throne_stage
        jsr     draw_scene5_guard
        jsr     HAL_gfx_present
        lda     <page_register
        eora    #$60
        sta     <page_register
hold_loop:
        jsr     HAL_time_vbl_wait
        bra     hold_loop

* --- REAL engine + HAL (single source, by include) ---
        include "../../src/engine/sprite_engine.s"
        include "../../src/hal/coco3-dsk/sys.s"
        include "../../src/hal/coco3-dsk/irq_vbl.s"
        include "../../src/hal/coco3-dsk/gfx.s"
        include "../../src/hal/coco3-dsk/time.s"
        include "../../src/hal/coco3-dsk/input.s"

* --- the gated throne stage module THEN the scene-5 composite (guard) ---
        include "scene5_throne_stage.s"
        include "scene5_composite.s"

        end     test_start
