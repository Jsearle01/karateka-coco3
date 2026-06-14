* tests/scripted/visual_smoke_driver.s
*
* P2.3a.5 visual smoke test driver.
* Tests HAL_sys_init + HAL_gfx_init + HAL_gfx_present end-to-end.
* Jay observes alternating squares in two positions.
*
* Self-contained: inline copies of sys.s (HAL_sys_init),
* gfx.s (HAL_gfx_init, HAL_gfx_present), plus draw primitive.
* Any changes to production sources must be mirrored here.
*
* Visual test: two white squares alternate between two positions.
*   Square A: rows 72-119, bytes 34-45 in Frame A ($8000-based)
*             Base = $8000 + (72*80) + 34 = $96A2
*   Square B: rows 88-135, bytes 38-49 in Frame B ($C000-based)
*             Base = $C000 + (88*80) + 38 = $DBA6
*
* INTENTIONAL WEAK TEST: positions are approximate, not pre-derived.
* P2.3a.1 sentinel test handles rigorous VOFFSET discharge.
*
* Expected visual: white 48x96-pixel square flickering between a
*   centered position (A) and a slightly offset position (B).
*
* Assemble (from repo root):
*   lwasm --decb -o tests/scripted/visual_smoke_driver.bin \
*         tests/scripted/visual_smoke_driver.s
*
* NOTE: Plan D1 spec says `lds #$0100`; corrected to `lds #$01FF`
*   (same fix as sys_init_driver.s — S=$0100 would corrupt DP on
*   first PSHS). Plan-deviation-discipline: flagged in R-h.
* ---------------------------------------------------------------

* ---------------------------------------------------------------
* Handler dispatch block (inline copy from sys.s)
* $0100-$0111 (18 bytes) — Sockmaster-correct ordering
* [ref: docs/ground-truth/SockmasterGime.md §1]
* ---------------------------------------------------------------
        org     $0100

        rti                         ; $0100 swi3_handler
        nop
        nop
        rti                         ; $0103 swi2_handler
        nop
        nop
        rti                         ; $0106 swi_handler
        nop
        nop
        rti                         ; $0109 nmi_handler
        nop
        nop
        rti                         ; $010C irq_handler
        nop
        nop
        rti                         ; $010F firq_handler
        nop
        nop

* ---------------------------------------------------------------
* Main code
* ---------------------------------------------------------------
        org     $0200
        setdp   0

* DP variable
page_register       equ $50         ; active draw buffer (back); $20=buf-A, $40=buf-B
                                    ; [ref: src/engine/timer_framesync.s — Option I canon]
PAGE_A_TOKEN        equ $20
PAGE_B_TOKEN        equ $40

* Square base addresses (pre-computed)
* [ref: docs/project/memory-map.md §4.8-4.9] frame buffer CPU bases
* Square A: $8000 + (72*80) + 34 = $96A2
SQUARE_A_BASE       equ $96A2
* Square B: $C000 + (88*80) + 38 = $DBA6
SQUARE_B_BASE       equ $DBA6

* Draw primitive constants
ROW_HEIGHT          equ 48          ; rows per square (rows 72-119 or 88-135)
ROW_BYTES           equ 12          ; bytes per square row (bytes 34-45 or 38-49)
ROW_STRIDE          equ 80          ; bytes per screen row (320px / 4px/byte)
NEXT_ROW            equ ROW_STRIDE-ROW_BYTES    ; = 68 (no spaces: lwasm §3.5)

* ---------------------------------------------------------------
* test_start — driver entry point
* ---------------------------------------------------------------
test_start:
        orcc    #$50                ; disable IRQ/FIRQ (driver-level mask)
        lds     #$01FF              ; stack above dispatch block
        clra
        tfr     a,dp                ; DP = 0

        * Step 0: HAL_sys_init (inline copy below)
        jsr     HAL_sys_init

        * Step 3: HAL_gfx_init (inline copy below; A=$00 = Brøderbund palette)
        lda     #$00
        jsr     HAL_gfx_init

        * Initialize page_register = $20: buffer A is the draw target (back buffer).
        * HAL_gfx_init left GIME displaying Frame B. With A as draw target,
        * first loop iteration draws to A, then HAL_gfx_present shows A.
        lda     #PAGE_A_TOKEN       ; $20
        sta     <page_register

* ---------------------------------------------------------------
* Draw-flip loop (runs forever; Jay observes via MAME window)
* ---------------------------------------------------------------
draw_flip_loop:
        lda     <page_register      ; read draw-target (Option I: back buffer)

        cmpa    #PAGE_A_TOKEN       ; back=A (page_register=$20)?
        beq     draw_to_a           ; yes: draw to A at A-position

        * Back=B ($40): draw to buffer B at B-position
        ldx     #SQUARE_B_BASE      ; $DBA6 = $C000 + row88*80 + byte38
        jsr     draw_square_to_x
        bra     do_flip

draw_to_a:
        * Back=A ($20): draw to buffer A at A-position
        ldx     #SQUARE_A_BASE      ; $96A2 = $8000 + row72*80 + byte34

        jsr     draw_square_to_x

do_flip:
        jsr     HAL_gfx_present     ; flip VOFFSET based on page_register

        * Toggle page_register: $20↔$40 via XOR $60
        lda     <page_register
        eora    #$60
        sta     <page_register

        bra     draw_flip_loop

* ---------------------------------------------------------------
* draw_square_to_x
*
* Fill a 48×12-byte rectangle with $FF (palette index 3 = white).
* Input: X = base address (row_top × 80 + col_left, in back buffer)
*
* Outer loop: ROW_HEIGHT=48 rows
* Inner loop: ROW_BYTES=12 bytes per row
* After inner loop: advance X by NEXT_ROW=68 bytes to next screen row
* ---------------------------------------------------------------
draw_square_to_x:
        ldy     #ROW_HEIGHT         ; Y = row counter (48 rows)
draw_row:
        ldb     #ROW_BYTES          ; B = byte counter (12 bytes)
draw_byte:
        lda     #$FF                ; all 4 pixels = palette index 3 (white)
        sta     ,x+                 ; store and post-increment X
        decb
        bne     draw_byte           ; inner loop: 12 bytes
        leax    NEXT_ROW,x          ; skip remaining bytes in row (68 bytes)
        leay    -1,y
        bne     draw_row            ; outer loop: 48 rows
        rts

* ---------------------------------------------------------------
* HAL_sys_init — inline copy of src/hal/coco3-dsk/sys.s
* [ref: sys.s HAL_sys_init — P2.3a.0]
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
* [ref: gfx.s HAL_gfx_init — P2.3a]
* Note: $FF90=$4C written again here (idempotent; HAL_sys_init
*       already wrote it; no harm in re-writing same value)
* ---------------------------------------------------------------
HAL_gfx_init:
        pshs    u,y

        * $FF90 FIRST: expose RAM at $8000/$C000
        lda     #$4C
        sta     $FF90

        * Clear Frame A ($8000-$BBFF)
        ldx     #$8000
        ldd     #$0000
        ldy     #$1E00
gfx_init_clr_a:
        std     ,x++
        leay    -1,y
        bne     gfx_init_clr_a

        * Clear Frame B ($C000-$FBFF)
        ldx     #$C000
        ldy     #$1E00
gfx_init_clr_b:
        std     ,x++
        leay    -1,y
        bne     gfx_init_clr_b

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
        sta     $FFB0
        lda     #$26
        sta     $FFB1
        lda     #$1B
        sta     $FFB2
        lda     #$FF
        sta     $FFB3

        * gfx_initialized = $01
        lda     #$01
        sta     <$12

        puls    u,y
        andcc   #$FE
        rts

* ---------------------------------------------------------------
* HAL_gfx_present — inline copy of src/hal/coco3-dsk/gfx.s (P2.3a.5)
* [ref: gfx.s HAL_gfx_present — writes VOFFSET based on page_register]
* ---------------------------------------------------------------
HAL_gfx_present:
        pshs    u,y

        ; Option I: display the buffer page_register points at (just drawn).
        lda     <page_register
        cmpa    #PAGE_A_TOKEN       ; back=A → show Frame A
        beq     gpres_show_a

        ldd     #$F800              ; VOFFSET for Frame B ($FF9D=$F8,$FF9E=$00)
        bra     gpres_write

gpres_show_a:
        ldd     #$F000              ; VOFFSET for Frame A ($FF9D=$F0,$FF9E=$00)

gpres_write:
        std     $FF9D               ; [ref: GIME-RM §13] VOFFSET registers

        puls    u,y
        andcc   #$FE
        rts

        end     test_start
