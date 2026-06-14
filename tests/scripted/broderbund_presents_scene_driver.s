* tests/scripted/broderbund_presents_scene_driver.s
*
* Combined Brøderbund splash scene test driver.
* Draws Logo 2, Logo 1, then "presents" text — all on the same frame.
* Static display: draw everything, present once, spin.
*
* Sequence:
*   HAL_sys_init → HAL_gfx_init (palette descriptor 0, clears both bufs)
*   → blit Logo 2 (col=26, row=88)
*   → blit Logo 1 (col=35, row=72)
*   → blit p-r-e-s-e-n-t-s at row 110 (P2.4.2-followup-3 positions)
*   → HAL_gfx_present → spin
*
* Logo positions (Apple II → CoCo3, §19 border formula):
*   Logo 1 (sprite_1): start_col=119 → byte=35, row=72
*   Logo 2 (sprite_2): start_col=84  → byte=26, row=88
*
* "presents" positions (P2.4.2-followup-3 visible-extent formula):
*   trail: p=10 r=10 e=8 s=7 n=9 t=9; wlead: all=1 except s=2; GAP=1
*   [ref: docs/project/conventions.md §22 — visible-extent position formula]
*
* ORIGIN: Apple II outer_caller_b77c $B77C,
*         karateka_dissasembly_claude/src/intro.s:268-280
*
* Glyph data: content/font/glyph_{letter}/converted.s (start_col=119)
* Logo data:  content/broderbund/broderbund_logo_sprite_{1,2}/converted.s
*
* Self-contained: inline copies of HAL functions (sys_init, gfx_init,
* gfx_blit_sprite, gfx_present). Data via include.
* Any changes to production sources must be mirrored here.
*
* Assemble (from repo root):
*   lwasm --decb -o tests/scripted/broderbund_presents_scene_driver.bin \
*         tests/scripted/broderbund_presents_scene_driver.s
* ---------------------------------------------------------------

* ---------------------------------------------------------------
* Segment 1: Interrupt handler dispatch block $0100-$0111
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
* Segment 2: Main code $0200
* ---------------------------------------------------------------
        org     $0200
        setdp   0

page_register       equ $50
PAGE_A_TOKEN        equ $20
PAGE_B_TOKEN        equ $40

blit_height_d       equ $08
blit_width_d        equ $09
blit_col_d          equ $0A
blit_row_d          equ $0B
blit_subbyte        equ $0C         ; sub-byte offset 0-3 — set before each blit
blit_ovf_new        equ $0D
blit_ovf_prev       equ $0E
blit_tmp            equ $0F

FB_A_BASE           equ $8000
FB_B_BASE           equ $C000

* Logo positions
LOGO2_COL           equ 26          ; Logo 2: wider, lower (Apple II col=84)
LOGO2_ROW           equ 88
LOGO1_COL           equ 35          ; Logo 1: narrower, upper (Apple II col=119)
LOGO1_ROW           equ 72

* "presents" row
PRESENTS_ROW        equ 110

test_start:
        orcc    #$50                    ; mask IRQ+FIRQ
        lds     #$01FF
        clra
        tfr     a,dp                    ; DP = 0

        lda     #PAGE_A_TOKEN
        sta     <page_register          ; buffer A is draw target

        jsr     HAL_sys_init

        lda     #$00                    ; descriptor 0
        jsr     HAL_gfx_init

        * --- Logo 1 (Brøderbund badge — narrower, upper) ---
        * Apple II: routine_b898 first JSR L1903 call (Logo 1 / badge, sprite_1 at $A126)
        * [ref: karateka_dissasembly_claude/src/intro.s:592-605]
        clr     <blit_subbyte           ; logos are byte-aligned (sub=0)
        ldx     #broderbund_logo_sprite_1_coco3
        lda     #LOGO1_COL
        ldb     #LOGO1_ROW
        jsr     HAL_gfx_blit_sprite

        * --- Logo 2 (Brøderbund wordmark — wider, lower) ---
        * Apple II: routine_b898 second JMP L1903 tail call (Logo 2 / wordmark, sprite_2 at $A16E)
        * [ref: karateka_dissasembly_claude/src/intro.s:606-612]
        clr     <blit_subbyte
        ldx     #broderbund_logo_sprite_2_coco3
        lda     #LOGO2_COL
        ldb     #LOGO2_ROW
        jsr     HAL_gfx_blit_sprite

        * --- "presents" glyphs (centered at CoCo3 pixel 160 = screen center) ---
        * Apple II: routine_b8c2 → LB960(X=0) → L0700
        * [ref: karateka_dissasembly_claude/src/intro.s:627-632]
        * Positions: visible-extent formula, GAP=1, p=123 anchors center at 160.
        * Apple II: "presents" at pixel 101 on 280px screen → center 140 = screen center.
        * CoCo3: "presents" at pixel 123, visible 124-196 → center 160 = screen center.

        * Position 1: 'p' byte=30 sub=3 (pixel 123)
        lda     #3
        sta     <blit_subbyte
        ldx     #glyph_p_coco3
        lda     #30
        ldb     #PRESENTS_ROW
        jsr     HAL_gfx_blit_sprite

        * Position 2: 'r' byte=33 sub=2 (pixel 134)
        lda     #2
        sta     <blit_subbyte
        ldx     #glyph_r_coco3
        lda     #33
        ldb     #PRESENTS_ROW
        jsr     HAL_gfx_blit_sprite

        * Position 3: 'e' byte=36 sub=1 (pixel 145)
        lda     #1
        sta     <blit_subbyte
        ldx     #glyph_e_coco3
        lda     #36
        ldb     #PRESENTS_ROW
        jsr     HAL_gfx_blit_sprite

        * Position 4: 's' byte=38 sub=1 (pixel 153)
        lda     #1
        sta     <blit_subbyte
        ldx     #glyph_s_coco3
        lda     #38
        ldb     #PRESENTS_ROW
        jsr     HAL_gfx_blit_sprite

        * Position 5: 'e' byte=40 sub=1 (pixel 161)
        lda     #1
        sta     <blit_subbyte
        ldx     #glyph_e_coco3
        lda     #40
        ldb     #PRESENTS_ROW
        jsr     HAL_gfx_blit_sprite

        * Position 6: 'n' byte=42 sub=2 (pixel 170)
        lda     #2
        sta     <blit_subbyte
        ldx     #glyph_n_coco3
        lda     #42
        ldb     #PRESENTS_ROW
        jsr     HAL_gfx_blit_sprite

        * Position 7: 't' byte=45 sub=0 (pixel 180)
        clr     <blit_subbyte
        ldx     #glyph_t_coco3
        lda     #45
        ldb     #PRESENTS_ROW
        jsr     HAL_gfx_blit_sprite

        * Position 8: 's' byte=47 sub=1 (pixel 189)
        lda     #1
        sta     <blit_subbyte
        ldx     #glyph_s_coco3
        lda     #47
        ldb     #PRESENTS_ROW
        jsr     HAL_gfx_blit_sprite

        jsr     HAL_gfx_present         ; flip: show Frame A

spin:
        bra     spin

* ---------------------------------------------------------------
* HAL_sys_init — inline copy of src/hal/coco3-dsk/sys.s
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
* HAL_gfx_blit_sprite — inline copy (P2.4.1-followup-1)
* Transparency-aware: source index 0 preserves destination.
* blit_subbyte ($0C) must be set before call.
* [ref: src/hal/coco3-dsk/gfx.s HAL_gfx_blit_sprite — P2.4.1-followup-1]
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
        ldu     #bs_trans_table_mid
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

* Transparency mask table — signed-B offset trick; U = bs_trans_table_mid
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
* Sprite data — included from content/
* ---------------------------------------------------------------
        include "../../content/broderbund/broderbund_logo_sprite_2/converted.s"
        include "../../content/broderbund/broderbund_logo_sprite_1/converted.s"
        include "../../content/font/glyph_p/converted.s"
        include "../../content/font/glyph_r/converted.s"
        include "../../content/font/glyph_e/converted.s"
        include "../../content/font/glyph_s/converted.s"
        include "../../content/font/glyph_n/converted.s"
        include "../../content/font/glyph_t/converted.s"

        end     test_start
