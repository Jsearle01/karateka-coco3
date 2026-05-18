* tests/scripted/sub_byte_shifter_test_driver.s
*
* P2.4.1 sub-byte shifter unit test driver.
* Blits a 2-byte × 8-row $FF sprite at subbytes 0, 1, 2, 3
* at the same byte column (col=10) but different rows (20, 35, 50, 65).
*
* Expected visual (Jay verifies live):
*   subbyte=0 (row 20): solid 8-px white block, left edge at pixel 40 (byte 10)
*   subbyte=1 (row 35): 1-px indent left, 1 overflow px right of byte 11
*   subbyte=2 (row 50): 2-px indent left, 2 overflow px right of byte 11
*   subbyte=3 (row 65): 3-px indent left, 3 overflow px right of byte 11
*
* Expected framebuffer dump:
*   subbyte=0: row 20-27, bytes 10-11 = $FF (8 white pixels)
*   subbyte=1: row 35-42, byte10=$3F byte11=$FF byte12=$C0
*   subbyte=2: row 50-57, byte10=$0F byte11=$FF byte12=$F0
*   subbyte=3: row 65-72, byte10=$03 byte11=$FF byte12=$FC
*
* The sprite ($FF $FF, 2 bytes) when shifted:
*   subbyte=1: row output = $3F ($FF>>2), byte11=$FF (output+overflow), byte12=$C0
*   subbyte=2: row output = $0F ($FF>>4), byte11=$FF, byte12=$F0
*   subbyte=3: row output = $03 ($FF>>6), byte11=$FF, byte12=$FC
*
* [ref: docs/conventions.md §2 — DP $08-$0F HAL internal scratch band]
* [ref: src/hal/coco3-dsk/gfx.s HAL_gfx_blit_sprite P2.4.1]
*
* Self-contained inline HAL copies. blit_subbyte ($0C) set before each blit.
*
* Assemble (from repo root):
*   lwasm --decb -o tests/scripted/sub_byte_shifter_test_driver.bin \
*         tests/scripted/sub_byte_shifter_test_driver.s
* ---------------------------------------------------------------

* ---------------------------------------------------------------
* Dispatch block $0100-$0111
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
* Main code $0200
* ---------------------------------------------------------------
        org     $0200
        setdp   0

page_register       equ $50
PAGE_A_TOKEN        equ $20
PAGE_B_TOKEN        equ $40
blit_subbyte        equ $0C         ; sub-byte offset — set before each blit

blit_height_d       equ $08
blit_width_d        equ $09
blit_col_d          equ $0A
blit_row_d          equ $0B
blit_ovf_new        equ $0D
blit_ovf_prev       equ $0E
FB_A_BASE           equ $8000
FB_B_BASE           equ $C000

* Blit positions
TEST_COL            equ 10          ; byte column 10 for all blits
SB0_ROW             equ 20          ; subbyte=0 at row 20
SB1_ROW             equ 35          ; subbyte=1 at row 35
SB2_ROW             equ 50          ; subbyte=2 at row 50
SB3_ROW             equ 65          ; subbyte=3 at row 65

test_start:
        orcc    #$50
        lds     #$01FF
        clra
        tfr     a,dp

        lda     #PAGE_A_TOKEN
        sta     <page_register

        jsr     HAL_sys_init
        lda     #$00
        jsr     HAL_gfx_init

        * --- Blit 1: subbyte=0 at col=10, row=20 ---
        lda     #$00
        sta     <blit_subbyte           ; subbyte=0
        ldx     #test_sprite
        lda     #TEST_COL
        ldb     #SB0_ROW
        jsr     HAL_gfx_blit_sprite

        * --- Blit 2: subbyte=1 at col=10, row=35 ---
        lda     #$01
        sta     <blit_subbyte           ; subbyte=1
        ldx     #test_sprite
        lda     #TEST_COL
        ldb     #SB1_ROW
        jsr     HAL_gfx_blit_sprite

        * --- Blit 3: subbyte=2 at col=10, row=50 ---
        lda     #$02
        sta     <blit_subbyte           ; subbyte=2
        ldx     #test_sprite
        lda     #TEST_COL
        ldb     #SB2_ROW
        jsr     HAL_gfx_blit_sprite

        * --- Blit 4: subbyte=3 at col=10, row=65 ---
        lda     #$03
        sta     <blit_subbyte           ; subbyte=3
        ldx     #test_sprite
        lda     #TEST_COL
        ldb     #SB3_ROW
        jsr     HAL_gfx_blit_sprite

        jsr     HAL_gfx_present         ; show Frame A

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
* HAL_gfx_blit_sprite — inline copy of src/hal/coco3-dsk/gfx.s (P2.4.1)
* Sub-byte runtime shifter. blit_subbyte ($0C) must be set before call.
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
        lda     <blit_subbyte
        beq     bs_do_sb0
        cmpa    #1
        beq     bs_do_sb1
        cmpa    #2
        beq     bs_do_sb2
        bra     bs_do_sb3

bs_do_sb0:
        lda     <blit_height_d
bs_row_sb0:
        ldb     <blit_width_d
bs_byte_sb0:
        lda     ,x+
        sta     ,y+
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
        sta     ,y+
        lda     <blit_ovf_new
        sta     <blit_ovf_prev
        decb
        bne     bs_byte_sb1
        lda     <blit_ovf_prev
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
        sta     ,y+
        lda     <blit_ovf_new
        sta     <blit_ovf_prev
        decb
        bne     bs_byte_sb2
        lda     <blit_ovf_prev
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
        sta     ,y+
        lda     <blit_ovf_new
        sta     <blit_ovf_prev
        decb
        bne     bs_byte_sb3
        lda     <blit_ovf_prev
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

* ---------------------------------------------------------------
* HAL_gfx_present — inline copy (Option I)
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
* Test sprite: 2 bytes × 8 rows, all $FF
* 8 white pixels wide, 8 rows tall.
* At subbyte=0: solid 8-pixel white block.
* At subbyte=1/2/3: left edge indented by 1/2/3 pixels, overflow on right.
* ---------------------------------------------------------------
test_sprite:
        fcb     8,2             ; height=8 rows, width=2 bytes
        fcb     $FF,$FF         ; row 0: 8 white pixels
        fcb     $FF,$FF         ; row 1
        fcb     $FF,$FF         ; row 2
        fcb     $FF,$FF         ; row 3
        fcb     $FF,$FF         ; row 4
        fcb     $FF,$FF         ; row 5
        fcb     $FF,$FF         ; row 6
        fcb     $FF,$FF         ; row 7

        end     test_start
