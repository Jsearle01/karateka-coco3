* tests/scripted/scene6_cliff_walltop.s — WALL-TOP variant (Jay's 9x7 post).
* Hand-authored so the fallback scene6_cliff.s stays byte-identical.
* Replaces the old AA23/AA31 posts with: 5 RAIL ROW-FILLS + 2 OPAQUE 6x9 BLOCKS.
*   - spurious col-11 post DROPPED (only bytes 46 & 67 remain)
*   - opaque block (content/scenery/scene6_wall_post = cols 0-5 of Jay's 9x7) at byte 46 & 67,
*     SUB 2 (px 186 & 270), row 100, via HAL_gfx_blit_sprite_opaque (sub-byte shift 2)
*   - rail = direct row-fills (post col 6): white rows 102 & 108, black rows 103/104/105,
*     bytes 48..67 (px 192..271); blocks stamp over the rail ends
* AB rails (AB4A/AB7C/AB94) + AA7D base + start-pose: BYTE-IDENTICAL to scene6_cliff.s.
* NOTE (idiom 9a): opaque+shift stamps the leading 2px (px 184-185) of the left block as BLACK —
*   a 2px nub left of the left post on white rows; flagged for Jay's gate.
* ---------------------------------------------------------------

draw_climb_scenery_back:                ; old AA31 back layer DROPPED (new wall-top is front-drawn)
        rts

draw_climb_scenery:                     ; rail fills + 2 opaque blocks, then AB rails + AA7D base
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

* --- 2 opaque post blocks at byte 46 & 67, sub 2, row 100 (shift via _opaque, Phase-0 confirmed) ---
draw_walltop_posts:
        lda     #2
        sta     <blit_subbyte
        lda     #46
        ldb     #100
        ldx     #scene6_wall_post
        jsr     HAL_gfx_blit_sprite_opaque
        lda     #2
        sta     <blit_subbyte
        lda     #67
        ldb     #100
        ldx     #scene6_wall_post
        jsr     HAL_gfx_blit_sprite_opaque
        rts

* --- rail row-fills: white rows 102 & 108, black rows 103/104/105; bytes 48..67 (20 bytes) ---
*     direct to buffer-A logical base $8000 (setup-time; carried by clean-restore). ---
WT_L        equ 48                      ; left byte
WT_N        equ 10                      ; 10 words = 20 bytes (bytes 48..67, px 192..271)
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
* fill one row: B = row, U = colour word (U survives MUL; D/A/B are clobbered). clobbers A,B,D,X,Y.
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

* AB rails + AA7D base ONLY (old AA23/AA31 posts removed; new wall-top is the blocks+rail above).
climb_scn_tbl:
        fdb     scene6_cliff_AB4A
        fcb     0,5,112
        fdb     scene6_cliff_AB7C
        fcb     0,22,104
        fdb     scene6_cliff_AB94
        fcb     0,22,112
        fdb     scene6_cliff_AA7D
        fcb     0,15,152
        fdb     0                       ; end

* --- cel data ---
        include "../../content/scenery/scene6_wall_post/authored.s"
        include "../../content/scenery/scene6_cliff_AA7D/converted.s"
        include "../../content/scenery/scene6_cliff_AB4A/converted.s"
        include "../../content/scenery/scene6_cliff_AB7C/converted.s"
        include "../../content/scenery/scene6_cliff_AB94/converted.s"
        include "../../content/player/scene6_climb_A3C5/converted.s"
        include "../../content/player/scene6_climb_A3E9/converted.s"
