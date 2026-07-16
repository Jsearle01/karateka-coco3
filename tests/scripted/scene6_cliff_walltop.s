* tests/scripted/scene6_cliff_walltop.s — WALL-TOP variant (Jay's 9x7 post), CLEAN direct-fill render.
* Hand-authored so the fallback scene6_cliff.s stays byte-identical.
*
* Old AA23/AA31 wall-top posts REMOVED. New wall-top = 2 posts + rail, drawn as DIRECT FILLS with
* read-modify-write on the sub-byte edges — NO opaque-shift blit, so NO §9a black nub (the true
* background is preserved at px 184-185 / px 268-269). Positions exact: posts at bytes 46 & 67
* sub 2 (px 186 & 270), row 100; spurious col-11 post dropped.
*
* Post (Jay 9x7, cols 0-5 = the drawn block; col 6 = rail): white cols 0-1 (px base..+1), black
* cols 2-5 (px base+2..+5); rows 100/101/102/106/107/108 have the white edge, rows 103/104/105 are
* all black. => left byte low-nibble = $0F (white rows) or $00 (black rows); right byte = $00.
* Rail (= post col 6, direct row-fills): white rows 102 & 108, black rows 103/104/105, bytes 48-67
* (px 192-271); posts overpaint their columns after.
* AB rails (AB4A/AB7C/AB94) + AA7D base + start-pose: BYTE-IDENTICAL to scene6_cliff.s.
* ---------------------------------------------------------------

draw_climb_scenery_back:                ; old AA31 back layer DROPPED
        rts

draw_climb_scenery:                     ; new wall-top (rail fills + post fills), then AB rails + AA7D
        jsr     draw_walltop_rail
        jsr     draw_walltop_posts
        ldy     #climb_scn_tbl          ; AB rails + AA7D base (opaque, byte-identical to fallback)
dcs_loop:
        ldx     ,y++
        beq     dcs_done
        lda     ,y+
        sta     <blit_subbyte
        lda     ,y+
        ldb     ,y+
        pshs    y
        jsr     HAL_gfx_blit_sprite_opaque
        puls    y
        bra     dcs_loop
dcs_done:
        rts

* --- rail row-fills: white rows 102 & 108, black rows 103/104/105; bytes 48..67 (px 192..271) ---
WT_L        equ 48                      ; left byte
WT_N        equ 10                      ; 10 words = 20 bytes (bytes 48..67)
draw_walltop_rail:
        ldu     #$FFFF                  ; white rows 102 & 108
        ldb     #102
        bsr     wt_fill
        ldb     #108
        bsr     wt_fill
        ldu     #$0000                  ; black rows 103,104,105
        ldb     #103
        bsr     wt_fill
        ldb     #104
        bsr     wt_fill
        ldb     #105
        bsr     wt_fill
        rts
* fill one full-byte row run: B = row, U = colour word (U survives MUL). clobbers A,B,D,X,Y.
wt_fill:
        tfr     b,a
        ldb     #80
        mul                             ; D = row*80
        addd    #$8000+WT_L
        tfr     d,x
        tfr     u,d                     ; D = colour
        ldy     #WT_N
wt_fl:
        std     ,x++
        leay    -1,y
        bne     wt_fl
        rts

* --- 2 posts (bytes 46 & 67) as RMW fills: left byte low-nibble per row, right byte $00 (rows 100-108).
*     left-byte low nibble = $0F white rows / $00 black rows; upper 2px preserved (sky / rail). ---
wt_post_nib:
        fcb     $0F,$0F,$0F,$00,$00,$00,$0F,$0F,$0F   ; rows 100,101,102 | 103,104,105 | 106,107,108
draw_walltop_posts:
        ldu     #46                     ; post 2 left byte
        bsr     wt_postall
        ldu     #67                     ; post 3 left byte
        bsr     wt_postall
        rts
wt_postall:                             ; U = left byte
        ldx     #wt_post_nib
        ldb     #100                    ; row
wtp_l:
        lda     ,x+                     ; nibble ($0F/$00)
        pshs    u,x,b
        bsr     wt_postrow              ; A=nibble, B=row, U=left byte
        puls    u,x,b
        incb
        cmpb    #109
        blo     wtp_l
        rts
* one post row: A=nibble, B=row, U=left byte. left = (left & $F0) | nibble; right = $00.
wt_postrow:
        pshs    a                       ; save nibble
        tfr     b,a
        ldb     #80
        mul                             ; D = row*80
        addd    #$8000
        tfr     d,x
        tfr     u,d                     ; D = left byte (B low)
        abx                             ; X = &buffer + row*80 + left_byte
        lda     ,x
        anda    #$F0                    ; preserve upper 2px (sky / rail)
        ora     ,s+                     ; | nibble (pop)
        sta     ,x                      ; write left byte
        clr     1,x                     ; right byte = $00 (black cols 2-5)
        rts

* draw_climb_startpose — IDENTICAL to scene6_cliff.s.
draw_climb_startpose:
        lda     #3
        sta     <blit_subbyte
        lda     #21
        ldb     #158
        ldx     #scene6_climb_A3E9
        jsr     HAL_gfx_blit_sprite
        lda     #2
        sta     <blit_subbyte
        lda     #22
        ldb     #141
        ldx     #scene6_climb_A3C5
        jsr     HAL_gfx_blit_sprite
        rts

* AA7D base ONLY. Old AA23/AA31 posts + AB rails (AB4A/AB7C/AB94) + AA11 ledge all PULLED
* (Jay 2026-07-16 — old wall-top). AA7D is the cliff base (row 152), NOT wall-top, so it stays.
climb_scn_tbl:
        fdb     scene6_cliff_AA7D
        fcb     0,15,152
        fdb     0                       ; end

* --- cel data (AA7D base + start-pose cels; the post/rail are direct fills, no sprite) ---
        include "../../content/scenery/scene6_cliff_AA7D/converted.s"
        include "../../content/player/scene6_climb_A3C5/converted.s"
        include "../../content/player/scene6_climb_A3E9/converted.s"
