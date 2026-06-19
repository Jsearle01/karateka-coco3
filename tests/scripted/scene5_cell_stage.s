* tests/scripted/scene5_cell_stage.s
*
* SCENE-5 CELL STAGE (pass 1a-2) — the imprisonment cell backdrop, factored as
* an includable module like scene5_throne_stage.s. Provides draw_cell_stage
* (clear-to-black + cell floor strip + cell set-dressing). The princess's
* throne->cell TRANSITION (Gate 2) re-renders THIS to both buffers + re-snapshots
* the clean buffer; she then finishes walking in here, turns, collapses.
*
* REUSE: this module does NOT redefine the shared draw_setdressing / make_flipped
* / rev2 / scratch ZP — they come from scene5_throne_stage.s, which the Gate-2
* driver includes BEFORE this. Likewise floor_9600 / floor_96CE are already
* included there; here we add only the CELL-unique content.
* The cell DOOR ($9980) is NOT here — it is an animation beat (appears at the
* turn trigger), composited by the driver (HS-2). [authority: scene5-cell-draw-program.md]
* ---------------------------------------------------------------

* ===============================================================
* draw_cell_stage — paint the static cell stage to the back buffer.
*   (1) clear to black  (2) cell floor strip  (3) cell set-dressing.
* ===============================================================
draw_cell_stage:
        clr     <eng_col
        clr     <eng_row
        lda     #80
        sta     <eng_clrw
        lda     #192
        sta     <eng_clrh
        clr     <eng_fillval            ; black background
        jsr     eng_clear_box
        jsr     draw_cell_floor
        ldu     #cell_stage_tbl
        jsr     draw_setdressing        ; SHARED (scene5_throne_stage.s)
        rts

* ===============================================================
* draw_cell_floor — the cell floor STRIP (0A03 cols4-30 rows159-168 apple):
*   byte11..57 solid blue ($AA) on alternating rows; byte10 = $2A sliver
*   (gated 1a-2). [scene5-cell-draw-program.md]
* ===============================================================
draw_cell_floor:
        lda     #159
dcf_loop:
        pshs    a
        sta     <eng_row
        lda     #11
        sta     <eng_col
        lda     #47
        sta     <eng_clrw
        lda     #1
        sta     <eng_clrh
        lda     #$AA
        sta     <eng_fillval
        jsr     eng_clear_box
        lda     ,s                      ; sliver byte10 = $2A
        sta     <eng_row
        lda     #10
        sta     <eng_col
        lda     #1
        sta     <eng_clrw
        lda     #1
        sta     <eng_clrh
        lda     #$2A
        sta     <eng_fillval
        jsr     eng_clear_box
        puls    a
        adda    #2
        cmpa    #169
        blo     dcf_loop
        rts

* cell_stage_tbl — captured cell ORDER (opaque; actor + door excluded).
* entry: fdb ptr ; fcb apple_x, apple_y, mirror(0/1), opaque(0/1)
cell_stage_tbl:
        fdb     floor_9600_coco3        ; doorway lintel  M (x$20->$06) y$53   (shared sprite)
        fcb     $20,$53,1,1
        fdb     floor_964A_cell_coco3   ; doorway post    M (x$21->$05) y$5F
        fcb     $21,$5F,1,1
        fdb     fig_1200_coco3          ; floor texture   N x$08 y$A9  (transparent)
        fcb     $08,$A9,0,0
        fdb     fig_12C8_coco3          ; bench (right)   N x$1E y$84  (transparent)
        fcb     $1E,$84,0,0
        fdb     fig_14BE_coco3          ; floor texture   N x$0A y$99  (transparent)
        fcb     $0A,$99,0,0
        fdb     floor_96CE_coco3        ; doorway post    M (x$24->$02) y$5F   (shared sprite)
        fcb     $24,$5F,1,1
        fdb     fig_18D0_coco3          ; small element   N x$02 y$A9
        fcb     $02,$A9,0,1
        fdb     0                       ; terminator

* --- CELL-unique content (floor_9600 / floor_96CE come from the throne module) ---
        include "../../content/floor/floor_964A_cell/converted.s"
        include "../../content/floor/fig_1200/converted.s"
        include "../../content/scenery/fig_12C8/converted.s"
        include "../../content/floor/fig_14BE/converted.s"
        include "../../content/unsorted/fig_18D0/converted.s"
