* tests/scripted/palette_test_driver.s
*
* Palette diagnostic test driver — 4-band color test.
*
* Fills framebuffer A in four horizontal bands of 48 rows each
* using a single palette index per band:
*
*   Band 0 (rows   0-47):  all $00 = palette index 0 (expected: black)
*   Band 1 (rows  48-95):  all $55 = palette index 1 (expected: index1 color)
*   Band 2 (rows 96-143):  all $AA = palette index 2 (expected: index2 color)
*   Band 3 (rows 144-191): all $FF = palette index 3 (expected: white)
*
* $55 = 01010101b = 4 pixels all index 1
* $AA = 10101010b = 4 pixels all index 2
* $FF = 11111111b = 4 pixels all index 3
*
* This unambiguously shows what each palette index renders as on screen.
* Uses current palette descriptor 0 from HAL_gfx_init inline copy.
*
* [ref: plan P2.3a.6-followup-1 orange-pixel-diagnosis Part II §2.1]
* [ref: docs/SockmasterGime.md §FFB0-FFBF — palette register format]
*
* Self-contained: inline HAL copies (sys_init, gfx_init, present).
* No blit sprite needed — fills framebuffer directly.
*
* Assemble (from repo root):
*   lwasm --decb -o tests/scripted/palette_test_driver.bin \
*         tests/scripted/palette_test_driver.s
* ---------------------------------------------------------------

* ---------------------------------------------------------------
* Dispatch block $0100-$0111 (Sockmaster ordering)
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

* DP variables
page_register       equ $50
PAGE_A_TOKEN        equ $20
PAGE_B_TOKEN        equ $40

* Frame buffer
FB_A_BASE           equ $8000

* Band geometry: 48 rows × 80 bytes = 3840 bytes per band = $0F00
* NOTE: lwasm does not evaluate N*SYMBOL correctly (only N*literal works).
* Explicit hex values used to avoid the N*label evaluation failure.
BAND_BYTES          equ 48*80       ; = $0F00 = 3840 bytes per band
BAND_0_BASE         equ $8000       ; rows 0-47
BAND_1_BASE         equ $8F00       ; rows 48-95   (= $8000 + $0F00)
BAND_2_BASE         equ $9E00       ; rows 96-143  (= $8000 + $1E00)
BAND_3_BASE         equ $AD00       ; rows 144-191 (= $8000 + $2D00)

* Loop word counts: BAND_BYTES / 2 = 1920 word stores = $0780
BAND_WORDS          equ BAND_BYTES/2                ; = $0780

test_start:
        orcc    #$50
        lds     #$01FF
        clra
        tfr     a,dp

        lda     #PAGE_A_TOKEN
        sta     <page_register          ; buffer A is draw target

        jsr     HAL_sys_init
        lda     #$00
        jsr     HAL_gfx_init            ; init GIME, clear both buffers, load palette

        * --- Band 0: rows 0-47, all $00 (palette index 0) ---
        * HAL_gfx_init already cleared both buffers with $00, so band 0 is done.
        * No explicit fill needed.

        * --- Band 1: rows 48-95, all $55 (palette index 1 × 4) ---
        ldx     #BAND_1_BASE
        ldd     #$5555
        ldy     #BAND_WORDS
band1_loop:
        std     ,x++
        leay    -1,y
        bne     band1_loop

        * --- Band 2: rows 96-143, all $AA (palette index 2 × 4) ---
        ldx     #BAND_2_BASE
        ldd     #$AAAA
        ldy     #BAND_WORDS
band2_loop:
        std     ,x++
        leay    -1,y
        bne     band2_loop

        * --- Band 3: rows 144-191, all $FF (palette index 3 × 4) ---
        ldx     #BAND_3_BASE
        ldd     #$FFFF
        ldy     #BAND_WORDS
band3_loop:
        std     ,x++
        leay    -1,y
        bne     band3_loop

        jsr     HAL_gfx_present         ; flip: GIME shows frame A with four bands

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
* Palette descriptor 0 values (reverted per P2.3a.6-followup-2):
*   $FFB0=$00 (black), $FFB1=$26 (orange, hue 6 intensity 2), $FFB2=$1B (blue, hue 11 intensity 1), $FFB3=$3F (white)
* MAME composite format per SockmasterGime.md lines 241-242; values from GFXMODE3.ASM MAME-verified Nov 2025.
* ---------------------------------------------------------------
HAL_gfx_init:
        pshs    u,y

        lda     #$4C
        sta     $FF90

        * Clear Frame A
        ldx     #FB_A_BASE
        ldd     #$0000
        ldy     #$1E00
gi_clr_a:
        std     ,x++
        leay    -1,y
        bne     gi_clr_a

        * Clear Frame B ($C000-$FBFF)
        ldx     #$C000
        ldy     #$1E00
gi_clr_b:
        std     ,x++
        leay    -1,y
        bne     gi_clr_b

        * GIME mode 320x192x4 (mode BEFORE palette per P2.3a.6-followup-3)
        ldd     #$8015
        std     $FF98

        * VOFFSET: display Frame B initially
        ldd     #$F800
        std     $FF9D

        * VSCROL = 0, HOFFSET = 0
        clr     $FF9C
        clr     $FF9F

        * SAM
        clra
        sta     $FFD9
        sta     $FFDF

        * Palette descriptor 0 — LAST per P2.3a.6-followup-3 ordering
        * [ref: refs/GFXMODE3.ASM lines 57-64; palette after mode]
        lda     #$00
        sta     $FFB0                   ; index 0 = black
        lda     #$26
        sta     $FFB1                   ; index 1 = orange    (composite hue 6, intensity 2)
        lda     #$1B
        sta     $FFB2                   ; index 2 = blue/cyan (composite hue 11, intensity 1)
        lda     #$3F
        sta     $FFB3                   ; index 3 = white

        * gfx_initialized = $01
        lda     #$01
        sta     <$12

        puls    u,y
        andcc   #$FE
        rts

* ---------------------------------------------------------------
* HAL_gfx_present — inline copy (Option I convention)
* ---------------------------------------------------------------
HAL_gfx_present:
        pshs    u,y

        lda     <page_register
        cmpa    #PAGE_A_TOKEN           ; back=A → show Frame A
        beq     gp_show_a

        ldd     #$F800                  ; Frame B VOFFSET
        bra     gp_write

gp_show_a:
        ldd     #$F000                  ; Frame A VOFFSET

gp_write:
        std     $FF9D

        puls    u,y
        andcc   #$FE
        rts

        end     test_start
