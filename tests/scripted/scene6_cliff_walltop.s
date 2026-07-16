* tests/scripted/scene6_cliff_walltop.s — WALL-TOP variant, Jay's 11x7 (2026-07-16), CLEAN RMW fills.
* Hand-authored so the fallback scene6_cliff.s stays byte-identical.
*
* Old AA23/AA31 posts + AA11 ledge + AB4A/AB7C/AB94 rails all PULLED (Jay). New wall-top = 2 posts
* + rail, drawn as DIRECT read-modify-write fills (no opaque-shift blit, no §9a nub).
* Art: 11 rows (3 sky / white / 3 black / 3 sky / white), 7 cols; cols 0-5 = opaque block, col 6 =
* rail. PLACEMENT ROW 101. POSTS at bytes 46 & 67, SUB 0 (px 184 &
* 268) per Jays live gate (1px left of the sub-1/px185 that was there). Spurious col-11 post stays dropped. AA7D base stays.
*
* Rail bands (col 6): WHITE screen rows 104 & 111, BLACK rows 105/106/107; else sky.
* Post/rail placed by a table-driven RMW: for bytes 46,47,67,68 across rows 99..109, apply
*   byte = (byte & andmask) | ormask  (masks Python-computed + verified vs Jay's grid). The rail
*   MIDDLE (bytes 48-67) is a full-byte fill; the sub-byte post/rail-connect edges live in the table.
* ---------------------------------------------------------------

draw_climb_scenery_back:                ; old AA31 back layer DROPPED
        rts

draw_climb_scenery:                     ; new wall-top (rail middle fill + post/edge RMW), then AA7D
        jsr     draw_walltop_rail
        jsr     draw_walltop_posts
        ldy     #climb_scn_tbl          ; AA7D base (opaque, byte-identical to fallback)
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

* --- rail MIDDLE full-byte fill: bytes 48..67 (px 192..271) at rail rows; posts overpaint byte 67 ---
WT_L        equ 48
WT_N        equ 10                       ; 10 words = 20 bytes (48..67)
draw_walltop_rail:
        ldu     #$FFFF                   ; white rows 104 & 111
        ldb     #104
        bsr     wt_fill
        ldb     #111
        bsr     wt_fill
        ldu     #$0000                   ; black rows 105,106,107
        ldb     #105
        bsr     wt_fill
        ldb     #106
        bsr     wt_fill
        ldb     #107
        bsr     wt_fill
        rts
wt_fill:                                 ; B = row, U = colour word (survives MUL). clobbers A,B,D,X,Y.
        tfr     b,a
        ldb     #80
        mul
        addd    #$8000+WT_L
        tfr     d,x
        tfr     u,d
        ldy     #WT_N
wt_fl:
        std     ,x++
        leay    -1,y
        bne     wt_fl
        rts

* --- posts + rail-connect edges: table-driven RMW over bytes 46,47,67,68, rows 101..111 ---
wt_bytes:
        fcb     46,47,67,68,$FF          ; byte columns to RMW per row ($FF = end)
* per row: (and46,or46) (and47,or47) (and67,or67) (and68,or68)  [SUB 0 px184/268, rows 101-111;
* Python-computed from Jay's 11x7 grid]
wt_rmw:
        fcb     $00,$F0,$0F,$00,$00,$F0,$0F,$00   ; row 101 (sky/white-edge)
        fcb     $00,$F0,$0F,$00,$00,$F0,$0F,$00   ; row 102
        fcb     $00,$F0,$0F,$00,$00,$F0,$0F,$00   ; row 103
        fcb     $00,$F0,$00,$0F,$00,$F0,$03,$0C   ; row 104 (upper WHITE line)
        fcb     $00,$00,$00,$00,$00,$00,$03,$00   ; row 105 (black band)
        fcb     $00,$00,$00,$00,$00,$00,$03,$00   ; row 106
        fcb     $00,$00,$00,$00,$00,$00,$03,$00   ; row 107
        fcb     $00,$F0,$0F,$00,$00,$F0,$0F,$00   ; row 108
        fcb     $00,$F0,$0F,$00,$00,$F0,$0F,$00   ; row 109
        fcb     $00,$F0,$0F,$00,$00,$F0,$0F,$00   ; row 110
        fcb     $00,$F0,$00,$0F,$00,$F0,$03,$0C   ; row 111 (lower WHITE line)
draw_walltop_posts:
        ldu     #wt_rmw
        lda     #101                     ; row
wtp_row:
        pshs    a
        ldb     #80
        mul                              ; D = row*80  (A=row, B=80)
        addd    #$8000
        tfr     d,y                      ; Y = row base
        ldx     #wt_bytes
wtp_byte:
        ldb     ,x+                      ; byte offset (46/47/67/68) or $FF
        cmpb    #$FF
        beq     wtp_row_done
        pshs    y
        leay    b,y                      ; Y = base + byte offset
        lda     ,u+                      ; andmask
        anda    ,y
        ora     ,u+                      ; | ormask   (U advances past both)
        sta     ,y
        puls    y
        bra     wtp_byte
wtp_row_done:
        puls    a
        inca
        cmpa    #112                     ; rows 101..111
        blo     wtp_row
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

* AA7D base ONLY (old AA23/AA31 + AB rails + AA11 ledge PULLED; AA7D is cliff base, row 152).
climb_scn_tbl:
        fdb     scene6_cliff_AA7D
        fcb     0,15,152
        fdb     0                        ; end

* --- cel data (AA7D base + start-pose cels; post/rail are direct fills, no sprite) ---
        include "../../content/scenery/scene6_cliff_AA7D/converted.s"
        include "../../content/player/scene6_climb_A3C5/converted.s"
        include "../../content/player/scene6_climb_A3E9/converted.s"
