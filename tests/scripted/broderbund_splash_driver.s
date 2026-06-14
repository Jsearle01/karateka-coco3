* tests/scripted/broderbund_splash_driver.s
*
* P2.3a.6 Brøderbund visible test driver.
* First visible Karateka asset on CoCo3 milestone.
*
* Tests HAL_gfx_blit_sprite + palette descriptor 0
* ($00/$26/$1B/$3F — P2.3a.6-followup-2 MAME-verified values).
*
* Sequence:
*   HAL_sys_init → HAL_gfx_init (palette descriptor 0, clears both bufs)
*   → blit Logo 2 at A=26,B=88 → blit Logo 1 at A=35,B=72
*   → HAL_gfx_present → spin
*
* Position derivation (Apple II → CoCo3 + 5-byte border offset):
*   Logo 2: Apple II col 84 → CoCo3 byte 84/4=21 → +5 border → A=26, row 88
*   Logo 1: Apple II col 119 → CoCo3 byte 119/4=29.75 rounded to 30 → +5 → A=35, row 72
*
* [ref: karateka_dissasembly_claude/src/intro.s routine_b898 — row values]
* [ref: content/broderbund/broderbund_logo_sprite_1/converted.s — sprite 1 start_col=119]
* [ref: content/broderbund/broderbund_logo_sprite_2/converted.s — sprite 2 start_col=84]
* [ref: docs/conventions.md §2 — Option I page_register convention]
* [ref: plan P2.3a.6-plan-v1 — A3 border offset, A5 position table]
*
* Self-contained: inline copies of HAL functions (sys_init, gfx_init,
* gfx_blit_sprite, gfx_present). Sprite data inlined from converted.s.
* Any changes to production sources must be mirrored here.
*
* Assemble (from repo root):
*   lwasm --decb -o tests/scripted/broderbund_splash_driver.bin \
*         tests/scripted/broderbund_splash_driver.s
* ---------------------------------------------------------------

* ---------------------------------------------------------------
* Segment 1: Interrupt handler dispatch block
* Physical location: $0100-$0111 (18 bytes)
* Address order per Sockmaster-GIME §1:
*   SWI3 → $0100, SWI2 → $0103, SWI → $0106
*   NMI  → $0109, IRQ  → $010C, FIRQ → $010F
* [ref: docs/SockmasterGime.md §1]
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
page_register       equ $50         ; Option B: back buffer token
PAGE_A_TOKEN        equ $20         ; buffer A ($8000) is draw target
PAGE_B_TOKEN        equ $40         ; buffer B ($C000) is draw target

* HAL-private blit scratch (from gfx.s, HAL band $08-$0F)
blit_height_d       equ $08
blit_width_d        equ $09
blit_col_d          equ $0A
blit_row_d          equ $0B

* Frame buffer addresses (from hal.inc / memory-map.md §4.8-4.9)
FB_A_BASE           equ $8000
FB_B_BASE           equ $C000

* Logo positions at call site [ref: plan P2.3a.6-plan-v1 §A5]
*   Logo 2: col=84/4=21 +5 border = 26; row=88
*   Logo 1: col=119/4=29.75 →30 +5 border = 35; row=72
LOGO2_COL           equ 26
LOGO2_ROW           equ 88
LOGO1_COL           equ 35
LOGO1_ROW           equ 72

test_start:
        orcc    #$50                    ; mask IRQ+FIRQ
        lds     #$01FF                  ; stack: first push at $01FE (above dispatch block)
        clra
        tfr     a,dp                    ; DP = 0

        * Initialize page_register to PAGE_A_TOKEN:
        * buffer A ($8000) is the draw target (back buffer).
        * HAL_gfx_init will leave GIME displaying Frame B; we draw to A.
        * [ref: docs/conventions.md §2 Option B convention]
        lda     #PAGE_A_TOKEN
        sta     <page_register          ; DP $50 = $20

        jsr     HAL_sys_init            ; inline copy below

        lda     #$00                    ; descriptor 0 (Brøderbund palette)
        jsr     HAL_gfx_init            ; inline copy below; also clears both buffers

        * Blit Logo 2 first (wider, lower — draws to A at col 26, row 88)
        ldx     #logo2_data
        lda     #LOGO2_COL              ; A = 26
        ldb     #LOGO2_ROW              ; B = 88
        jsr     HAL_gfx_blit_sprite     ; inline copy below

        * Blit Logo 1 (narrower, upper — draws to A at col 35, row 72)
        ldx     #logo1_data
        lda     #LOGO1_COL              ; A = 35
        ldb     #LOGO1_ROW              ; B = 72
        jsr     HAL_gfx_blit_sprite

        jsr     HAL_gfx_present         ; flip: GIME now displays Frame A
                                        ; [Option I: page_register=$20 → show buffer A]
spin:
        bra     spin                    ; hold indefinitely for Jay to observe

* ---------------------------------------------------------------
* HAL_sys_init — inline copy of src/hal/coco3-dsk/sys.s
* Masks interrupts, sets $FF90=$4C (CoCo3 mode), programs FFA0-FFA7=$38-$3F.
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
* Palette descriptor 0: MAME-composite-empirical values (P2.3a.6-followup-2 revert).
*   $FFB0=$00 (black), $FFB1=$26 (orange, hue 6 intensity 2), $FFB2=$1B (blue, hue 11 intensity 1), $FFB3=$3F (white)
* [ref: refs/GFXMODE3.ASM — MAME-verified Nov 2025; composite format per SockmasterGime.md lines 241-242]
* [ref: src/hal/coco3-dsk/gfx.s HAL_gfx_init — P2.3a.6-followup-2]
* ---------------------------------------------------------------
HAL_gfx_init:
        pshs    u,y

        * $FF90 FIRST: expose RAM at $8000/$C000
        lda     #$4C
        sta     $FF90

        * Clear Frame A ($8000-$BBFF = $1E00 word stores)
        ldx     #FB_A_BASE
        ldd     #$0000
        ldy     #$1E00
gi_clr_a:
        std     ,x++
        leay    -1,y
        bne     gi_clr_a

        * Clear Frame B ($C000-$FBFF)
        ldx     #FB_B_BASE
        ldy     #$1E00
gi_clr_b:
        std     ,x++
        leay    -1,y
        bne     gi_clr_b

        * GIME mode 320x192x4 (mode BEFORE palette per P2.3a.6-followup-3)
        ldd     #$8015
        std     $FF98

        * VOFFSET: display Frame B initially (engine draws to Frame A)
        ldd     #$F800
        std     $FF9D

        * VSCROL = 0, HOFFSET = 0 (required; undefined at reset)
        clr     $FF9C
        clr     $FF9F

        * SAM: 1.78 MHz clock + RAM at $C000
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
        sta     $FFB3                   ; index 3 = white     (composite intensity 3)

        * gfx_initialized = $01
        lda     #$01
        sta     <$12

        puls    u,y
        andcc   #$FE
        rts

* ---------------------------------------------------------------
* HAL_gfx_blit_sprite — inline copy of src/hal/coco3-dsk/gfx.s
* Copy packed sprite into back buffer at (A=byte_col, B=pixel_row).
* [ref: src/hal/coco3-dsk/gfx.s HAL_gfx_blit_sprite — P2.3a.6]
* ---------------------------------------------------------------
HAL_gfx_blit_sprite:
        pshs    u                       ; preserve U

        * Save args to DP scratch before clobbering
        sta     <blit_col_d             ; $0A = destination byte column
        stb     <blit_row_d             ; $0B = destination pixel row

        * Read sprite header: byte 0 = height, byte 1 = width
        lda     ,x+                     ; A = height
        sta     <blit_height_d          ; $08 = height
        lda     ,x+                     ; A = width
        sta     <blit_width_d           ; $09 = width (bytes per row)
        * X now points at row 0 data

        * Bounds check: col + width > 80?
        lda     <blit_col_d
        adda    <blit_width_d
        bcs     bs_invalid              ; carry → definitely > 80
        cmpa    #81
        bhs     bs_invalid              ; col+width >= 81

        * Bounds check: row + height > 192?
        lda     <blit_row_d
        adda    <blit_height_d
        bcs     bs_invalid              ; carry → definitely > 192
        cmpa    #193
        bhs     bs_invalid              ; row+height >= 193

        * Compute back buffer base → Y (Option B convention)
        lda     <page_register
        cmpa    #PAGE_A_TOKEN           ; $20 = buffer A is back?
        beq     bs_buf_a
        ldy     #FB_B_BASE              ; buffer B ($C000)
        bra     bs_row_offset
bs_buf_a:
        ldy     #FB_A_BASE              ; buffer A ($8000)

bs_row_offset:
        * Y += row * 80   [MUL: A*B → D, unsigned 8x8→16]
        lda     #80
        ldb     <blit_row_d
        mul                             ; D = 80 * row
        leay    d,y                     ; Y = buffer_base + row*80

        * Y += col
        ldb     <blit_col_d
        leay    b,y                     ; Y = buffer_base + row*80 + col

bs_row_loop:
        * Copy blit_width bytes from X to Y
        ldb     <blit_width_d
bs_byte_loop:
        lda     ,x+
        sta     ,y+
        decb
        bne     bs_byte_loop

        * Advance Y to next screen row: add (80 - width)
        ldb     #80
        subb    <blit_width_d
        leay    b,y

        dec     <blit_height_d
        bne     bs_row_loop

        andcc   #$FE                    ; CC.C clear = success
        puls    u
        rts

bs_invalid:
        lda     #$02                    ; ERR_INVALID
        orcc    #$01                    ; CC.C set = error
        puls    u
        rts

* ---------------------------------------------------------------
* HAL_gfx_present — inline copy of src/hal/coco3-dsk/gfx.s (Option I, P2.3a.6-followup-1)
* Option I: displays the buffer page_register identifies (the one just drawn to).
* [ref: src/hal/coco3-dsk/gfx.s HAL_gfx_present]
* ---------------------------------------------------------------
HAL_gfx_present:
        pshs    u,y

        ; Option I: display the buffer page_register points at (just drawn).
        lda     <page_register
        cmpa    #PAGE_A_TOKEN           ; back=A → show Frame A
        beq     gp_show_a

        ldd     #$F800                  ; VOFFSET for Frame B ($F8,$00)
        bra     gp_write

gp_show_a:
        ldd     #$F000                  ; VOFFSET for Frame A ($F0,$00)

gp_write:
        std     $FF9D                   ; [ref: GIME-RM §13] VOFFSET registers

        puls    u,y
        andcc   #$FE
        rts

* ---------------------------------------------------------------
* Sprite data — inlined from content/*/converted.s
* [ref: tools/sprite_convert.py chroma model P1.2 (2026-05-16)]
* Color model: adjacency + screen-col parity (MAME-verified snap 0083)
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*
* Logo 2 blitted first (wider, lower), Logo 1 second (narrower, upper).
* ---------------------------------------------------------------

* Logo 2: 9 rows × 28 bytes = 252 bitmap bytes + 2 header = 254 bytes total
* [ref: content/broderbund/broderbund_logo_sprite_2/converted.s — start_col=84]
logo2_data:
        fcb     9,28                    ; height=9 rows, coco3_width=28 bytes/row
        fcb     $00,$FF,$00,$00,$00,$03,$C0,$00,$00,$3C,$00,$00,$00,$00,$0F,$00,$FC,$00,$00,$F0,$00,$00,$00,$00,$00,$00,$00,$00  ; row 0
        fcb     $03,$C3,$C0,$00,$00,$03,$C0,$00,$00,$3C,$00,$00,$00,$00,$0F,$03,$C0,$00,$03,$C3,$C0,$00,$00,$00,$00,$00,$00,$00  ; row 1
        fcb     $03,$C3,$C3,$F7,$C0,$3F,$C3,$F0,$3F,$7F,$C3,$EF,$0F,$C0,$FF,$03,$C0,$0F,$EF,$FF,$F7,$EF,$7C,$3F,$03,$F7,$F0,$00  ; row 2
        fcb     $03,$FF,$0F,$0F,$0A,$F7,$EF,$7E,$F0,$3E,$F7,$EF,$7E,$F7,$EF,$03,$F0,$3E,$F7,$C3,$C3,$EF,$7E,$F7,$EF,$0F,$7C,$00  ; row 3
        fcb     $03,$C3,$EF,$0F,$7E,$F7,$EF,$7E,$F0,$3E,$F7,$EF,$7E,$F7,$EF,$00,$FC,$3E,$F7,$C3,$C3,$EF,$7C,$03,$EF,$0F,$7C,$00  ; row 4
        fcb     $03,$C3,$EF,$0F,$7E,$F7,$EF,$F0,$F0,$3E,$F7,$EF,$7E,$F7,$EF,$00,$3F,$7E,$F7,$C3,$C3,$EF,$7C,$3F,$EF,$0F,$F0,$00  ; row 5
        fcb     $03,$C3,$EF,$0F,$7E,$F7,$EF,$00,$F0,$3E,$F7,$EF,$7E,$F7,$EF,$00,$0F,$7E,$F7,$C3,$C3,$EF,$7E,$F7,$EF,$0F,$00,$00  ; row 6
        fcb     $03,$C3,$EF,$08,$3E,$F7,$EF,$7E,$F0,$3E,$F7,$EF,$7E,$F7,$EF,$00,$0F,$7E,$F7,$C3,$C3,$EF,$7E,$F7,$EF,$0F,$7C,$00  ; row 7
        fcb     $03,$FF,$0F,$00,$F0,$3F,$03,$F0,$F0,$0F,$C0,$FC,$3E,$F0,$FC,$00,$FC,$0F,$C3,$C0,$F0,$F0,$F0,$3F,$EF,$03,$F0,$00  ; row 8

* Logo 1: 14 rows × 9 bytes = 126 bitmap bytes + 2 header = 128 bytes total
* [ref: content/broderbund/broderbund_logo_sprite_1/converted.s — start_col=119]
logo1_data:
        fcb     14,9                    ; height=14 rows, coco3_width=9 bytes/row
        fcb     $00,$00,$00,$20,$00,$00,$02,$00,$00  ; row 0
        fcb     $00,$00,$00,$FC,$00,$00,$0F,$C0,$00  ; row 1
        fcb     $00,$00,$FC,$20,$FC,$0F,$C2,$0F,$C0  ; row 2
        fcb     $00,$03,$C3,$FF,$0F,$BC,$3F,$F0,$F0  ; row 3
        fcb     $00,$00,$F0,$00,$3C,$0F,$00,$03,$C0  ; row 4
        fcb     $00,$00,$20,$00,$20,$02,$00,$02,$00  ; row 5
        fcb     $00,$00,$3C,$00,$F0,$43,$C0,$0F,$00  ; row 6
        fcb     $00,$00,$0F,$FC,$43,$F0,$5F,$FC,$00  ; row 7
        fcb     $00,$00,$00,$05,$F0,$43,$C4,$00,$00  ; row 8
        fcb     $00,$00,$00,$0F,$0F,$FC,$3C,$00,$00  ; row 9
        fcb     $00,$00,$00,$03,$C0,$00,$F0,$00,$00  ; row 10
        fcb     $00,$00,$00,$00,$40,$00,$40,$00,$00  ; row 11
        fcb     $00,$00,$00,$00,$F0,$03,$C0,$00,$00  ; row 12
        fcb     $00,$00,$00,$00,$3F,$FF,$00,$00,$00  ; row 13

        end     test_start
