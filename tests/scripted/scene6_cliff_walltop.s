* scene6_cliff_walltop.s � Jay's 11x7, 3 posts (first mirrored) + rail + BLACK WALL below, back slot.
* Posts px 98/183/268 rows 101..111; rail white 104&111 black 105-107 to px299. Black wall directly
* below the post/rail structure: bytes 24..74, rows 112..116 (fills the blue gap under the rail). AA7D base.
* ---------------------------------------------------------------

draw_climb_scenery_back:
        jsr     draw_walltop_posts
        jsr     draw_walltop_backwall
        rts

* black wall directly below the post/rail structure. Left edge = px99 (the post leg's left black
* line): byte 24 keeps px96-98 (bits7-2), sets only px99 (bits1-0) black; bytes 25..74 full black.
* Rows 112..116.
draw_walltop_backwall:
        ldb     #112
bwl_row:
        pshs    b
        tfr     b,a
        ldb     #80
        mul
        addd    #$8000
        tfr     d,x                     ; X = row base (byte 0)
        lda     24,x                    ; byte 24: black only px99 (bits1-0), preserve px96-98
        anda    #$FC
        sta     24,x
        leax    25,x                    ; X -> byte 25
        ldb     #50                     ; bytes 25..74 full black
bwl_byte:
        clr     ,x+
        decb
        bne     bwl_byte
        puls    b
        incb
        cmpb    #117
        blo     bwl_row
        rts

draw_climb_scenery:
        ldy     #climb_scn_tbl
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

wt_bytes:
        fcb     24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,67,68,69,70,71,72,73,74,$FF

wt_rmw:
        fcb     $FC,$00,$00,$03,$3F,$C0,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FC,$03,$00,$C0,$3F,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$00,$F0,$0F,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00   ; row 101
        fcb     $FC,$00,$00,$03,$3F,$C0,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FC,$03,$00,$C0,$3F,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$00,$F0,$0F,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00   ; row 102
        fcb     $FC,$00,$00,$03,$3F,$C0,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FC,$03,$00,$C0,$3F,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$00,$F0,$0F,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00   ; row 103
        fcb     $F0,$0C,$00,$03,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$C0,$00,$3F,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$F0,$00,$0F,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF   ; row 104
        fcb     $F0,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00   ; row 105
        fcb     $F0,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00   ; row 106
        fcb     $F0,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00   ; row 107
        fcb     $FC,$00,$00,$03,$3F,$C0,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FC,$03,$00,$C0,$3F,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$00,$F0,$0F,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00   ; row 108
        fcb     $FC,$00,$00,$03,$3F,$C0,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FC,$03,$00,$C0,$3F,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$00,$F0,$0F,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00   ; row 109
        fcb     $FC,$00,$00,$03,$3F,$C0,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FC,$03,$00,$C0,$3F,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$00,$F0,$0F,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00   ; row 110
        fcb     $F0,$0C,$00,$03,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$C0,$00,$3F,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$F0,$00,$0F,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF   ; row 111
draw_walltop_posts:
        ldu     #wt_rmw
        lda     #101
wtp_row:
        pshs    a
        ldb     #80
        mul
        addd    #$8000
        tfr     d,y
        ldx     #wt_bytes
wtp_byte:
        ldb     ,x+
        cmpb    #$FF
        beq     wtp_row_done
        pshs    y
        leay    b,y
        lda     ,u+
        anda    ,y
        ora     ,u+
        sta     ,y
        puls    y
        bra     wtp_byte
wtp_row_done:
        puls    a
        inca
        cmpa    #112
        blo     wtp_row
        rts

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

climb_scn_tbl:
        fdb     scene6_cliff_AB4A
        fcb     0,5,112
        fdb     scene6_cliff_AA7D
        fcb     0,15,152
        fdb     0

        include "../../content/scenery/scene6_cliff_AB4A/converted.s"
        include "../../content/scenery/scene6_cliff_AA7D/converted.s"
        include "../../content/player/scene6_climb_A3C5/converted.s"
        include "../../content/player/scene6_climb_A3E9/converted.s"
