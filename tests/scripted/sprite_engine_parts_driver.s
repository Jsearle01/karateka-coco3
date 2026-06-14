* tests/scripted/sprite_engine_parts_driver.s
*
* PRINCESS PARTS INSPECTOR (R-engine sandbox) — displays the composite pieces
* draw_princess layers (body $1D00, parts $1CD4 idx6 / $1CC4 idx7) individually,
* spaced across the TOP of the screen, plus a walk leg ($1D36) for reference.
* Static (no animation) so each part can be inspected before compositing.
* Boot-excluded. [ref: princess controller AC-1 compositing increment]
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
        rti                             ; $010C IRQ
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
TOPROW          equ 12              ; row band for the inspected parts

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

        jsr     clear_both_buffers

        ; --- display each part at the top, spaced (col, row=TOPROW) ---
        clr     <blit_subbyte
        ; body $1D00 (idx5) @ col 6
        ldx     #fig_1D00_coco3
        lda     #6
        ldb     #TOPROW
        jsr     HAL_gfx_blit_sprite
        ; part $1CD4 (idx6) @ col 16
        ldx     #fig_1CD4_coco3
        lda     #16
        ldb     #TOPROW
        jsr     HAL_gfx_blit_sprite
        ; part $1CC4 (idx7, 13B wide) @ col 26
        ldx     #fig_1CC4_coco3
        lda     #26
        ldb     #TOPROW
        jsr     HAL_gfx_blit_sprite
        ; walk leg $1D36 (reference) @ col 52
        ldx     #fig_1D36_coco3
        lda     #52
        ldb     #TOPROW
        jsr     HAL_gfx_blit_sprite

        jsr     HAL_gfx_present         ; reveal buffer A

parts_idle:
        jsr     HAL_time_vbl_wait
        bra     parts_idle

clear_both_buffers:
        ldx     #FB_A_LO
        ldd     #$0000
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

        include "../../src/engine/sprite_engine.s"
        include "../../src/hal/coco3-dsk/sys.s"
        include "../../src/hal/coco3-dsk/irq_vbl.s"
        include "../../src/hal/coco3-dsk/gfx.s"
        include "../../src/hal/coco3-dsk/time.s"
        include "../../src/hal/coco3-dsk/input.s"

        include "../../content/princess/fig_1D00/converted.s"
        include "../../content/princess/fig_1CD4/converted.s"
        include "../../content/princess/fig_1CC4/converted.s"
        include "../../content/princess/fig_1D36/converted.s"

        end     test_start
