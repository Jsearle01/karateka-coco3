* tests/scripted/presents_test_driver.s
*
* P2.3a.11 "presents" text test driver.
* Displays the word "presents" using 6 converted glyphs at row 110.
*
* Sequence:
*   HAL_sys_init → HAL_gfx_init (palette descriptor 0, clears both bufs)
*   → blit p, r, e, s, e, n, t, s at row 110
*   → HAL_gfx_present → spin
*
* Position derivation (Apple II → CoCo3 + 5-byte border offset):
*   [ref: docs/project/conventions.md §19 — border offset formula]
*   [ref: font glyph inspection report R-c — per-letter pixel positions]
*   Row: Apple II hires row 110 = CoCo3 row 110 (1:1 vertical mapping)
*
*   Letter | A2 pixel col | /4 (floor) | +5 border | CoCo3 byte col
*   -------|--------------|------------|-----------|---------------
*     p    |    101       |    25      |    +5     |     30
*     r    |    112       |    28      |    +5     |     33
*     e    |    123       |    30      |    +5     |     35
*     s    |    132       |    33      |    +5     |     38
*     e    |    140       |    35      |    +5     |     40
*     n    |    149       |    37      |    +5     |     42
*     t    |    159       |    39      |    +5     |     44
*     s    |    169       |    42      |    +5     |     47
*
* Glyph data: content/font/glyph_{letter}/converted.s (start_col=119)
* [ref: docs/project/conventions.md §18 — canonical start_col=119 convention]
*
* Self-contained: inline copies of HAL functions (sys_init, gfx_init,
* gfx_blit_sprite, gfx_present). Glyph data via include.
* Any changes to production sources must be mirrored here.
*
* Assemble (from repo root):
*   lwasm --decb -o tests/scripted/presents_test_driver.bin \
*         tests/scripted/presents_test_driver.s
* ---------------------------------------------------------------

* ---------------------------------------------------------------
* Segment 1: Interrupt handler dispatch block
* Physical location: $0100-$0111 (18 bytes)
* [ref: docs/ground-truth/SockmasterGime.md §1]
* ---------------------------------------------------------------
        org     $0100

        rti                         ; $0100 — SWI3
        nop
        nop
        rti                         ; $0103 — SWI2
        nop
        nop
        rti                         ; $0106 — SWI
        nop
        nop
        rti                         ; $0109 — NMI
        nop
        nop
        rti                         ; $010C — IRQ
        nop
        nop
        rti                         ; $010F — FIRQ
        nop
        nop

* ---------------------------------------------------------------
* Segment 2: Main code
* Entry: $0200
* ---------------------------------------------------------------
        org     $0200
        setdp   0

* DP variables (from src/engine/globals.s)
page_register       equ $50         ; Option I: back buffer token
PAGE_A_TOKEN        equ $20         ; buffer A ($8000) is draw target
PAGE_B_TOKEN        equ $40         ; buffer B ($C000) is draw target

* HAL-private blit scratch (from gfx.s, HAL band $08-$0F)
blit_height_d       equ $08
blit_width_d        equ $09
blit_col_d          equ $0A
blit_row_d          equ $0B

* Frame buffer addresses
FB_A_BASE           equ $8000
FB_B_BASE           equ $C000

* "presents" glyph positions — CoCo3 (byte, subbyte) per P2.4.2-followup-3
* Formula: nominal(N+1) = nominal(N) + trail(N) + 1 + GAP - wlead(N+1)
* trail: p=10 r=10 e=8 s=7 n=9 t=9; wlead: p=1 r=1 e=1 s=2 n=1 t=1; GAP=1
* Matrices are subbyte-invariant; formula per-glyph per-subbyte inspection 2026-05-17.
* [ref: P2.4.2-followup-3 — corrected trail/wlead visible-extent positions]
*
*   Pos | Letter | nominal px | byte | sub
*   ----|--------|------------|------|----
*     1 |   p    |    135     |  33  |  3
*     2 |   r    |    146     |  36  |  2
*     3 |   e    |    157     |  39  |  1
*     4 |   s    |    165     |  41  |  1
*     5 |   e    |    173     |  43  |  1
*     6 |   n    |    182     |  45  |  2
*     7 |   t    |    192     |  48  |  0
*     8 |   s    |    201     |  50  |  1
*
PRESENTS_ROW        equ 110
blit_subbyte        equ $0C         ; sub-byte offset 0-3 — set before each blit

blit_ovf_new        equ $0D         ; HAL internal overflow accumulator
blit_ovf_prev       equ $0E         ; HAL internal overflow carry per row
blit_tmp            equ $0F         ; transparency scratch: source byte during mask sequence

test_start:
        orcc    #$50                    ; mask IRQ+FIRQ
        lds     #$01FF                  ; stack: first push at $01FE
        clra
        tfr     a,dp                    ; DP = 0

        lda     #PAGE_A_TOKEN
        sta     <page_register          ; buffer A is draw target; HAL_gfx_init shows B first

        jsr     HAL_sys_init

        lda     #$00                    ; descriptor 0
        jsr     HAL_gfx_init            ; clears both bufs, sets mode + palette

        * --- Blit 8 glyphs: p-r-e-s-e-n-t-s (P2.4.2 sub-byte positions) ---

        * Position 1: 'p' byte=33 sub=3 (A2 col 101 → CoCo3 pixel 135)
        lda     #3
        sta     <blit_subbyte
        ldx     #glyph_p_coco3
        lda     #33
        ldb     #PRESENTS_ROW
        jsr     HAL_gfx_blit_sprite

        * Position 2: 'r' byte=36 sub=2 (P2.4.2-f3 corrected: pixel 146)
        lda     #2
        sta     <blit_subbyte
        ldx     #glyph_r_coco3
        lda     #36
        ldb     #PRESENTS_ROW
        jsr     HAL_gfx_blit_sprite

        * Position 3: 'e' byte=39 sub=1 (P2.4.2-f2 visible-extent: pixel 157)
        lda     #1
        sta     <blit_subbyte
        ldx     #glyph_e_coco3
        lda     #39
        ldb     #PRESENTS_ROW
        jsr     HAL_gfx_blit_sprite

        * Position 4: 's' byte=41 sub=1 (P2.4.2-f2 visible-extent: pixel 165)
        lda     #1
        sta     <blit_subbyte
        ldx     #glyph_s_coco3
        lda     #41
        ldb     #PRESENTS_ROW
        jsr     HAL_gfx_blit_sprite

        * Position 5: 'e' byte=43 sub=1 (P2.4.2-f3 corrected: pixel 173)
        lda     #1
        sta     <blit_subbyte
        ldx     #glyph_e_coco3
        lda     #43
        ldb     #PRESENTS_ROW
        jsr     HAL_gfx_blit_sprite

        * Position 6: 'n' byte=45 sub=2 (P2.4.2-f2 visible-extent: pixel 182)
        lda     #2
        sta     <blit_subbyte
        ldx     #glyph_n_coco3
        lda     #45
        ldb     #PRESENTS_ROW
        jsr     HAL_gfx_blit_sprite

        * Position 7: 't' byte=48 sub=0 (P2.4.2-f3 corrected: pixel 192)
        clr     <blit_subbyte
        ldx     #glyph_t_coco3
        lda     #48
        ldb     #PRESENTS_ROW
        jsr     HAL_gfx_blit_sprite

        * Position 8: 's' byte=50 sub=1 (P2.4.2-f3 corrected: pixel 201)
        lda     #1
        sta     <blit_subbyte
        ldx     #glyph_s_coco3
        lda     #50
        ldb     #PRESENTS_ROW
        jsr     HAL_gfx_blit_sprite

        jsr     HAL_gfx_present         ; flip: GIME now displays Frame A

spin:
        bra     spin

* ---------------------------------------------------------------
* HAL_sys_init — inline copy of src/hal/coco3-dsk/sys.s
* [ref: src/hal/coco3-dsk/sys.s HAL_sys_init — P2.3a.0]
* ---------------------------------------------------------------
HAL_sys_init:
        pshs    u,y
        orcc    #$50
        lda     #$4C
        sta     $FF90
        lda     #$38
        sta     $FFA0
        lda     #$39
        sta     $FFA1
        lda     #$3A
        sta     $FFA2
        lda     #$3B
        sta     $FFA3
        lda     #$3C
        sta     $FFA4
        lda     #$3D
        sta     $FFA5
        lda     #$3E
        sta     $FFA6
        lda     #$3F
        sta     $FFA7
        puls    u,y
        andcc   #$FE
        rts

* ---------------------------------------------------------------
* HAL_gfx_init — inline copy of src/hal/coco3-dsk/gfx.s
* Palette descriptor 0: $FFB0=$00 $FFB1=$26 $FFB2=$1B $FFB3=$3F
* [ref: src/hal/coco3-dsk/gfx.s HAL_gfx_init — P2.3a.6-followup-2]
* ---------------------------------------------------------------
HAL_gfx_init:
        pshs    u,y

        lda     #$4C
        sta     $FF90

        ldx     #FB_A_BASE
        ldd     #$0000
        ldy     #$1E00
gi_clr_a:
        std     ,x++
        leay    -1,y
        bne     gi_clr_a

        ldx     #FB_B_BASE
        ldy     #$1E00
gi_clr_b:
        std     ,x++
        leay    -1,y
        bne     gi_clr_b

        ldd     #$8015
        std     $FF98

        ldd     #$F800
        std     $FF9D

        clr     $FF9C
        clr     $FF9F

        clra
        sta     $FFD9
        sta     $FFDF

        lda     #$00
        sta     $FFB0
        lda     #$26
        sta     $FFB1
        lda     #$1B
        sta     $FFB2
        lda     #$3F
        sta     $FFB3

        lda     #$01
        sta     <$12

        puls    u,y
        andcc   #$FE
        rts

* ---------------------------------------------------------------
* HAL_gfx_blit_sprite — inline copy of src/hal/coco3-dsk/gfx.s (P2.4.1)
* Sub-byte runtime shifter. blit_subbyte ($0C) must be set before call.
* Mirrors production HAL exactly per docs/project/methodology.md Rule 4.
* [ref: src/hal/coco3-dsk/gfx.s HAL_gfx_blit_sprite — P2.4.1]
* ---------------------------------------------------------------
HAL_gfx_blit_sprite:
        pshs    u
        sta     <blit_col_d
        stb     <blit_row_d
        lda     ,x+
        sta     <blit_height_d
        lda     ,x+
        sta     <blit_width_d
        lda     <blit_col_d
        adda    <blit_width_d
        lbcs    bs_invalid
        cmpa    #81
        lbhs    bs_invalid
        lda     <blit_row_d
        adda    <blit_height_d
        lbcs    bs_invalid
        cmpa    #193
        lbhs    bs_invalid
        lda     <page_register
        cmpa    #PAGE_A_TOKEN
        beq     bs_buf_a
        ldy     #FB_B_BASE
        bra     bs_got_base
bs_buf_a:
        ldy     #FB_A_BASE
bs_got_base:
        lda     #80
        ldb     <blit_row_d
        mul
        leay    d,y
        ldb     <blit_col_d
        leay    b,y
        ldu     #bs_trans_table_mid     ; U = transparency mask table midpoint
        lda     <blit_subbyte
        beq     bs_do_sb0
        cmpa    #1
        beq     bs_do_sb1
        cmpa    #2
        beq     bs_do_sb2
        lbra    bs_do_sb3

bs_do_sb0:
        lda     <blit_height_d
bs_row_sb0:
        ldb     <blit_width_d
bs_byte_sb0:
        lda     ,x+
        pshs    b
        tfr     a,b
        lda     b,u
        coma
        anda    ,y
        stb     <blit_tmp
        ora     <blit_tmp
        sta     ,y+
        puls    b
        decb
        bne     bs_byte_sb0
        ldb     #80
        subb    <blit_width_d
        leay    b,y
        dec     <blit_height_d
        bne     bs_row_sb0
        lbra    bs_done

bs_do_sb1:
        lda     <blit_height_d
bs_row_sb1:
        clr     <blit_ovf_prev
        ldb     <blit_width_d
bs_byte_sb1:
        clr     <blit_ovf_new
        lda     ,x+
        lsra
        ror     <blit_ovf_new
        lsra
        ror     <blit_ovf_new
        ora     <blit_ovf_prev
        pshs    b
        tfr     a,b
        lda     b,u
        coma
        anda    ,y
        stb     <blit_tmp
        ora     <blit_tmp
        sta     ,y+
        puls    b
        lda     <blit_ovf_new
        sta     <blit_ovf_prev
        decb
        bne     bs_byte_sb1
        lda     <blit_ovf_prev
        tfr     a,b
        lda     b,u
        coma
        anda    ,y
        stb     <blit_tmp
        ora     <blit_tmp
        sta     ,y
        ldb     #80
        subb    <blit_width_d
        leay    b,y
        dec     <blit_height_d
        bne     bs_row_sb1
        lbra    bs_done

bs_do_sb2:
        lda     <blit_height_d
bs_row_sb2:
        clr     <blit_ovf_prev
        ldb     <blit_width_d
bs_byte_sb2:
        clr     <blit_ovf_new
        lda     ,x+
        lsra
        ror     <blit_ovf_new
        lsra
        ror     <blit_ovf_new
        lsra
        ror     <blit_ovf_new
        lsra
        ror     <blit_ovf_new
        ora     <blit_ovf_prev
        pshs    b
        tfr     a,b
        lda     b,u
        coma
        anda    ,y
        stb     <blit_tmp
        ora     <blit_tmp
        sta     ,y+
        puls    b
        lda     <blit_ovf_new
        sta     <blit_ovf_prev
        decb
        bne     bs_byte_sb2
        lda     <blit_ovf_prev
        tfr     a,b
        lda     b,u
        coma
        anda    ,y
        stb     <blit_tmp
        ora     <blit_tmp
        sta     ,y
        ldb     #80
        subb    <blit_width_d
        leay    b,y
        dec     <blit_height_d
        bne     bs_row_sb2
        lbra    bs_done

bs_do_sb3:
        lda     <blit_height_d
bs_row_sb3:
        clr     <blit_ovf_prev
        ldb     <blit_width_d
bs_byte_sb3:
        clr     <blit_ovf_new
        lda     ,x+
        lsra
        ror     <blit_ovf_new
        lsra
        ror     <blit_ovf_new
        lsra
        ror     <blit_ovf_new
        lsra
        ror     <blit_ovf_new
        lsra
        ror     <blit_ovf_new
        lsra
        ror     <blit_ovf_new
        ora     <blit_ovf_prev
        pshs    b
        tfr     a,b
        lda     b,u
        coma
        anda    ,y
        stb     <blit_tmp
        ora     <blit_tmp
        sta     ,y+
        puls    b
        lda     <blit_ovf_new
        sta     <blit_ovf_prev
        decb
        bne     bs_byte_sb3
        lda     <blit_ovf_prev
        tfr     a,b
        lda     b,u
        coma
        anda    ,y
        stb     <blit_tmp
        ora     <blit_tmp
        sta     ,y
        ldb     #80
        subb    <blit_width_d
        leay    b,y
        dec     <blit_height_d
        bne     bs_row_sb3

bs_done:
        andcc   #$FE
        puls    u
        rts

bs_invalid:
        lda     #$02
        orcc    #$01
        puls    u
        rts

* Transparency mask table — inline copy of gfx.s blit_trans_table
* U = bs_trans_table_mid; lda b,u via signed-B offset for all 256 source values
bs_trans_table_base:
        fcb     $C0,$C3,$C3,$C3,$CC,$CF,$CF,$CF,$CC,$CF,$CF,$CF,$CC,$CF,$CF,$CF  ; src $80-$8F
        fcb     $F0,$F3,$F3,$F3,$FC,$FF,$FF,$FF,$FC,$FF,$FF,$FF,$FC,$FF,$FF,$FF  ; src $90-$9F
        fcb     $F0,$F3,$F3,$F3,$FC,$FF,$FF,$FF,$FC,$FF,$FF,$FF,$FC,$FF,$FF,$FF  ; src $A0-$AF
        fcb     $F0,$F3,$F3,$F3,$FC,$FF,$FF,$FF,$FC,$FF,$FF,$FF,$FC,$FF,$FF,$FF  ; src $B0-$BF
        fcb     $C0,$C3,$C3,$C3,$CC,$CF,$CF,$CF,$CC,$CF,$CF,$CF,$CC,$CF,$CF,$CF  ; src $C0-$CF
        fcb     $F0,$F3,$F3,$F3,$FC,$FF,$FF,$FF,$FC,$FF,$FF,$FF,$FC,$FF,$FF,$FF  ; src $D0-$DF
        fcb     $F0,$F3,$F3,$F3,$FC,$FF,$FF,$FF,$FC,$FF,$FF,$FF,$FC,$FF,$FF,$FF  ; src $E0-$EF
        fcb     $F0,$F3,$F3,$F3,$FC,$FF,$FF,$FF,$FC,$FF,$FF,$FF,$FC,$FF,$FF,$FF  ; src $F0-$FF
bs_trans_table_mid:
        fcb     $00,$03,$03,$03,$0C,$0F,$0F,$0F,$0C,$0F,$0F,$0F,$0C,$0F,$0F,$0F  ; src $00-$0F
        fcb     $30,$33,$33,$33,$3C,$3F,$3F,$3F,$3C,$3F,$3F,$3F,$3C,$3F,$3F,$3F  ; src $10-$1F
        fcb     $30,$33,$33,$33,$3C,$3F,$3F,$3F,$3C,$3F,$3F,$3F,$3C,$3F,$3F,$3F  ; src $20-$2F
        fcb     $30,$33,$33,$33,$3C,$3F,$3F,$3F,$3C,$3F,$3F,$3F,$3C,$3F,$3F,$3F  ; src $30-$3F
        fcb     $C0,$C3,$C3,$C3,$CC,$CF,$CF,$CF,$CC,$CF,$CF,$CF,$CC,$CF,$CF,$CF  ; src $40-$4F
        fcb     $F0,$F3,$F3,$F3,$FC,$FF,$FF,$FF,$FC,$FF,$FF,$FF,$FC,$FF,$FF,$FF  ; src $50-$5F
        fcb     $F0,$F3,$F3,$F3,$FC,$FF,$FF,$FF,$FC,$FF,$FF,$FF,$FC,$FF,$FF,$FF  ; src $60-$6F
        fcb     $F0,$F3,$F3,$F3,$FC,$FF,$FF,$FF,$FC,$FF,$FF,$FF,$FC,$FF,$FF,$FF  ; src $70-$7F

* ---------------------------------------------------------------
* HAL_gfx_present — inline copy of src/hal/coco3-dsk/gfx.s (Option I)
* [ref: src/hal/coco3-dsk/gfx.s HAL_gfx_present — P2.3a.6-followup-1]
* ---------------------------------------------------------------
HAL_gfx_present:
        pshs    u,y

        lda     <page_register
        cmpa    #PAGE_A_TOKEN
        beq     gp_show_a

        ldd     #$F800
        bra     gp_write

gp_show_a:
        ldd     #$F000

gp_write:
        std     $FF9D

        puls    u,y
        andcc   #$FE
        rts

* ---------------------------------------------------------------
* Glyph data — included from content/font/glyph_*/converted.s
* Canonical start_col=119 per docs/project/conventions.md §18
* ---------------------------------------------------------------
        include "../../content/font/glyph_p/converted.s"
        include "../../content/font/glyph_r/converted.s"
        include "../../content/font/glyph_e/converted.s"
        include "../../content/font/glyph_s/converted.s"
        include "../../content/font/glyph_n/converted.s"
        include "../../content/font/glyph_t/converted.s"

        end     test_start
