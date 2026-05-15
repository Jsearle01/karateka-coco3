* tests/scripted/timer_framesync_driver.s
*
* Test driver for P2.1 timer/frame-sync behavioral verification.
* Self-contained: inline copies of page_flip and HAL_time stubs so
* the test builds without a linker.
*
* Production sources: src/engine/timer_framesync.s,
*                     src/hal/coco3-dsk/time.s,
*                     src/hal/coco3-dsk/gfx.s
* Any changes to those files must be mirrored here for test accuracy.
*
* Expected final DP state (after 3 page_flip calls from PAGE_A=$20):
*   DP $50 (page_register)    = $40
*   DP $51 (page_source_blit) = $20  ($50+$51=$60 invariant holds)
*   DP $10/$11 (frame_count)  = $0000+3 = $0003
*
* Assemble (from repo root):
*   lwasm --decb -o tests/scripted/timer_framesync_driver.bin \
*         tests/scripted/timer_framesync_driver.s
* ---------------------------------------------------------------

        org     $0200               ; load/exec address in CoCo3 RAM
        setdp   0

* DP variables
page_register       equ $50
page_source_blit    equ $51
hal_frame_hi        equ $10
hal_frame_lo        equ $11
PAGE_A              equ $20
PAGE_B              equ $40

* ---------------------------------------------------------------
* test_start — driver entry point
* ---------------------------------------------------------------
test_start:
        orcc    #$50                ; disable IRQ/FIRQ
        clra
        tfr     a,dp                ; DP = 0

        jsr     HAL_time_init       ; zero frame counter

        lda     #PAGE_A
        sta     <page_register      ; init page_register to $20

        jsr     page_flip           ; call 1: $20->$40
        jsr     page_flip           ; call 2: $40->$20
        jsr     page_flip           ; call 3: $20->$40

test_loop:
        bra     test_loop           ; spin; harness captures here

* ---------------------------------------------------------------
* page_flip — inline copy of src/engine/timer_framesync.s
* [ref: karateka_dissasembly_claude src/kernel.s $0799/routine_0799]
* ---------------------------------------------------------------
page_flip:
        lda     <page_register
        cmpa    #PAGE_B
        beq     page_flip_to_a
        sta     <page_source_blit
        lda     #PAGE_B
        sta     <page_register
        lda     #1
        jsr     HAL_time_vbl_wait
        jsr     HAL_gfx_present
        rts

* [ref: karateka_dissasembly_claude src/kernel.s $07AC/routine_07ac]
page_flip_to_a:
        sta     <page_source_blit
        lda     #PAGE_A
        sta     <page_register
        lda     #1
        jsr     HAL_time_vbl_wait
        jsr     HAL_gfx_present
        rts

* ---------------------------------------------------------------
* HAL_time_init — inline copy of src/hal/coco3-dsk/time.s
* ---------------------------------------------------------------
HAL_time_init:
        clr     <hal_frame_hi
        clr     <hal_frame_lo
        andcc   #$FE
        rts

* ---------------------------------------------------------------
* HAL_time_vbl_wait [STUB-P3]
* [ref: karateka_dissasembly_claude src/kernel.s $07D7/routine_07d7]
* ---------------------------------------------------------------
HAL_time_vbl_wait:
hal_vbl_loop:
        inc     <hal_frame_lo
        bne     hal_vbl_no_carry
        inc     <hal_frame_hi
hal_vbl_no_carry:
        deca
        bne     hal_vbl_loop
        andcc   #$FE
        rts

* ---------------------------------------------------------------
* HAL_gfx_present [STUB-P3]
* ---------------------------------------------------------------
HAL_gfx_present:
        andcc   #$FE
        rts

        end     test_start
