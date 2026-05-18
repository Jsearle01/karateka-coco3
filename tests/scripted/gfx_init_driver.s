* tests/scripted/gfx_init_driver.s
*
* Test driver for P2.3a HAL graphics init behavioral verification.
* Self-contained: inline copies of sys.s (HAL_sys_init), gfx.s
* (HAL_gfx_init, HAL_gfx_clear, HAL_gfx_present) and time.s
* (HAL_time_init) so the test builds with a single lwasm --decb
* invocation.
*
* P2.3a.0 AMENDMENT: Added HAL_sys_init call (before HAL_gfx_init)
* and dispatch block at $0100 (inline copy from sys.s). HAL_sys_init
* now owns the $FF90=$4C write and MMU slot programming; HAL_gfx_init's
* redundant $FF90 write is harmless (idempotent).
*
* Production sources:
*   src/hal/coco3-dsk/sys.s   (HAL_sys_init, dispatch block; P2.3a.0)
*   src/hal/coco3-dsk/gfx.s   (HAL_gfx_init, HAL_gfx_clear, HAL_gfx_present)
*   src/hal/coco3-dsk/time.s  (HAL_time_init)
*   src/engine/timer_framesync.s (page_register initialization)
* Any changes to those files must be mirrored here for test accuracy.
*
* Boot integration (D3): this driver exercises the INIT ORDER per hal.inc:
*   Step 2: HAL_time_init
*   Step 3: HAL_gfx_init (A=0, Brøderbund palette descriptor 0)
*   Post-init: page_register = PAGE_A ($20) [engine responsibility]
*   Post-init: HAL_gfx_clear (clears back buffer = Frame A)
*
* Expected post-init state (P2.3a verification predictions):
*   DP $12 (gfx_initialized)   = $01
*   DP $50 (page_register)     = $20 (PAGE_A; engine sets after init)
*   DP $10/$11 (frame_counter) = $0000
*   $8000                      = $00  (Frame A cleared by HAL_gfx_init)
*   $BBFF                      = $00  (Frame A tail byte)
*   $C000                      = $00  (Frame B cleared by HAL_gfx_init)
*   $FBFF                      = $00  (Frame B tail byte)
*   GIME: $FF98=$80, $FF99=$15, $FF90=$4C (write-only; unverifiable)
*   GIME: $FF9D=$F8, $FF9E=$00 (VOFFSET → Frame B displayed; unverifiable)
*   GIME: $FFB0=$00,$FFB1=$26,$FFB2=$1B,$FFB3=$FF (unverifiable)
*
* Assemble (from repo root):
*   lwasm --decb -o tests/scripted/gfx_init_driver.bin \
*         tests/scripted/gfx_init_driver.s
* ---------------------------------------------------------------

* ---------------------------------------------------------------
* Handler dispatch block (inline copy from sys.s)
* $0100-$0111 (18 bytes); loaded before main code block
* [ref: docs/SockmasterGime.md §1]
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
* Main test code
* ---------------------------------------------------------------
        org     $0200               ; load/exec address in CoCo3 RAM
        setdp   0

* DP variables
gfx_initialized     equ $12         ; $00=not init; $01=init complete
hal_frame_hi        equ $10
hal_frame_lo        equ $11
page_register       equ $50         ; active draw buffer (back); $20=buf-A, $40=buf-B
PAGE_A_TOKEN        equ $20
PAGE_B_TOKEN        equ $40

* Frame buffer constants
GFX_FB_A_BASE       equ $8000
GFX_FB_B_BASE       equ $C000
GFX_FB_WORDS        equ $1E00       ; 15,360 bytes / 2 = 7,680 words

* ---------------------------------------------------------------
* test_start — driver entry point (boot integration sequence)
* ---------------------------------------------------------------
test_start:
        orcc    #$50                ; disable IRQ/FIRQ
        clra
        tfr     a,dp                ; DP = 0

        * HAL init order step 0: sys init (bare-metal transition)
        * [ref: hal.inc INIT ORDER — HAL_sys_init runs before all others]
        jsr     HAL_sys_init

        * HAL init order step 2: time init
        jsr     HAL_time_init

        * HAL init order step 3: gfx init (palette descriptor 0)
        lda     #$00
        jsr     HAL_gfx_init

        * Engine responsibility: set page_register to PAGE_A
        * (engine draws to frame A; GIME displays frame B)
        lda     #PAGE_A_TOKEN
        sta     <page_register

        * Post-init: clear back buffer (frame A)
        jsr     HAL_gfx_clear

test_loop:
        bra     test_loop           ; spin; harness captures state here

* ---------------------------------------------------------------
* HAL_sys_init — inline copy of src/hal/coco3-dsk/sys.s
* [ref: sys.s HAL_sys_init — CoCo3 bare-metal transition; P2.3a.0]
* Any change to sys.s must be mirrored here.
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
* HAL_time_init — inline copy of src/hal/coco3-dsk/time.s
* [ref: time.s HAL_time_init — zero frame counter]
* ---------------------------------------------------------------
HAL_time_init:
        clr     <hal_frame_hi
        clr     <hal_frame_lo
        andcc   #$FE
        rts

* ---------------------------------------------------------------
* HAL_gfx_init — inline copy of src/hal/coco3-dsk/gfx.s
* [ref: gfx.s HAL_gfx_init — initialize GIME 320x192x4]
* ---------------------------------------------------------------
HAL_gfx_init:
        pshs    u,y

        * $FF90 FIRST: enable GIME MMU, expose flat RAM at $8000/$C000
        * [see gfx.s Step 1 constraint note — P1.6 ROM territory fix]
        lda     #$4C
        sta     $FF90

        * Clear Frame A ($8000-$BBFF)
        ldx     #GFX_FB_A_BASE
        ldd     #$0000
        ldy     #GFX_FB_WORDS
gfx_init_clr_a:
        std     ,x++
        leay    -1,y
        bne     gfx_init_clr_a

        * Clear Frame B ($C000-$FBFF)
        ldx     #GFX_FB_B_BASE
        ldy     #GFX_FB_WORDS
gfx_init_clr_b:
        std     ,x++
        leay    -1,y
        bne     gfx_init_clr_b

        * GIME mode 320x192x4 (mode BEFORE palette per P2.3a.6-followup-3)
        * [ref: GIME-RM §10] $FF98=$80, $FF99=$15
        ldd     #$8015
        std     $FF98

        * VOFFSET: display Frame B (initial front)
        * [ref: memory-map.md §4.10, §4.9] VOFFSET = $7C000/8 = $F800
        ldd     #$F800
        std     $FF9D               ; $FF9D=$F8 (hi), $FF9E=$00 (lo)

        * VSCROL = 0 (required at reset)
        clr     $FF9C

        * HOFFSET = 0 (required at reset)
        clr     $FF9F

        * SAM: 1.78 MHz clock and RAM at $C000
        * [ref: refs/GFXMODE3.ASM lines 36, 56]
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

        * Set initialized flag
        lda     #$01
        sta     <gfx_initialized

        puls    u,y
        andcc   #$FE
        rts

* ---------------------------------------------------------------
* HAL_gfx_clear — inline copy of src/hal/coco3-dsk/gfx.s
* [ref: gfx.s HAL_gfx_clear — clear active back buffer]
* ---------------------------------------------------------------
HAL_gfx_clear:
        lda     <page_register
        cmpa    #PAGE_A_TOKEN
        bne     gfx_clr_b
        ldx     #GFX_FB_A_BASE
        bra     gfx_clr_common
gfx_clr_b:
        ldx     #GFX_FB_B_BASE
gfx_clr_common:
        ldd     #$0000
        ldy     #GFX_FB_WORDS
gfx_clr_loop:
        std     ,x++
        leay    -1,y
        bne     gfx_clr_loop
        andcc   #$FE
        rts

* ---------------------------------------------------------------
* HAL_gfx_present — no-op stub for gfx_init test (gfx_init does not exercise present).
* Production gfx.s HAL_gfx_present is fully implemented (P2.3a.6-followup-1).
* ---------------------------------------------------------------
HAL_gfx_present:
        andcc   #$FE
        rts

        end     test_start
