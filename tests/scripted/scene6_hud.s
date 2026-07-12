* tests/scripted/scene6_hud.s
*
* SHARED scene-6 static arrow-HUD module — SINGLE SOURCE, `include`d by
* scene6_stage2_driver.s and scene6_stage3_driver.s (accrete). Promoted verbatim
* from the Stage-2 driver (de-dup); framebuffer pixel-identical before/after.
*
* Entry: draw_hud — 14 player arrows (arrow_0B12 orange, draw-A) LEFT px 21->151 +
*   14 guard arrows (arrow_0B12_mir blue, BAKED mirror) RIGHT px 292->162, the
*   oracle $0B35/$0B7C count-driven model (draw exactly N, advance the 10px pitch),
*   transparent blit, Y=185, +20px-centered. Static (fixed 14 count, no dynamics).
*
* The including driver provides globals.s + the HAL + page_register + org/end.
* This module is include-only (no org/end).
* ---------------------------------------------------------------

hud_byte        equ $60         ; scratch: current arrow byte column
hud_sub         equ $61         ; scratch: current arrow sub-byte (0-3)
hud_cnt         equ $62         ; scratch: arrows remaining
ARROW_ROW       equ 185         ; Y = $B9 (bottom row, oracle $06)
ARROW_COUNT     equ 14          ; $0E (both sides, fixed this stage)

* ---------------------------------------------------------------
* draw_hud — 14 player arrows (draw-A) LEFT + 14 guard arrows (baked mirror) RIGHT,
*   the oracle $0B35/$0B7C count-driven model: draw exactly N, advance the 10px
*   pitch each. Transparent blit. Y=185.
* ---------------------------------------------------------------
draw_hud:
        * --- player: arrow_0B12 (orange, draw-A), byte 5 / sub 1, +10px each ---
        lda     #5
        sta     <hud_byte
        lda     #1
        sta     <hud_sub
        lda     #ARROW_COUNT
        sta     <hud_cnt
dp_loop:
        lda     <hud_sub
        sta     <blit_subbyte
        lda     <hud_byte               ; A = byte col
        ldb     #ARROW_ROW              ; B = row 185
        ldx     #arrow_0B12
        jsr     HAL_gfx_blit_sprite
        * advance +10px = +2 sub, +2 byte (carry a byte when sub wraps past 4)
        lda     <hud_sub
        adda    #2
        cmpa    #4
        blo     dp_nocarry
        suba    #4
        inc     <hud_byte
dp_nocarry:
        sta     <hud_sub
        lda     <hud_byte
        adda    #2
        sta     <hud_byte
        dec     <hud_cnt
        bne     dp_loop

        * --- guard: arrow_0B12_mir (blue, BAKED mirror), byte 73 / sub 0, -10px each ---
        lda     #73
        sta     <hud_byte
        clr     <hud_sub
        lda     #ARROW_COUNT
        sta     <hud_cnt
dg_loop:
        lda     <hud_sub
        sta     <blit_subbyte
        lda     <hud_byte
        ldb     #ARROW_ROW
        ldx     #arrow_0B12_mir
        jsr     HAL_gfx_blit_sprite
        * advance -10px = -2 sub, -2 byte (borrow a byte when sub goes negative)
        lda     <hud_sub
        suba    #2
        bpl     dg_noborrow
        adda    #4
        dec     <hud_byte
dg_noborrow:
        sta     <hud_sub
        lda     <hud_byte
        suba    #2
        sta     <hud_byte
        dec     <hud_cnt
        bne     dg_loop
        rts

* --- hud cel data (single source) ---
        include "../../content/hud/arrow_0B12/converted.s"
        include "../../content/hud/arrow_0B12_mir/converted.s"
