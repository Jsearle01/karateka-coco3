* tests/scripted/vbl_irq_test_driver.s
*
* R-vbl opt-in test driver.
* Verifies that HAL_time_init installs the VBL IRQ handler and
* configures GIME; that andcc #$EF causes real VBL interrupts
* to increment the frame counter at ~60 Hz; and that existing
* callers (timer_framesync chain) still work in masked-path mode.
*
* This driver IS the Q001.1/1.c opt-in: after setup it calls
* andcc #$EF and enters a tight spin. The MAME Lua harness
* measures counter advance rate to confirm interrupt-driven
* operation per X5 verification plan V-counter-rate.
*
* Verifications supported by this driver:
*   V-mem-read:  P-W1.a-c ($010C/$010D/$010E), P-W2.a ($FF90),
*                P-W2.b ($FF92), P-W2.d (hal_frame_hi/lo)
*   V-cc-trace:  P-W2.c (CC.I preserved after HAL_time_init)
*   V-counter-rate: P-INT.a, P-W4.b
*
* Self-contained: inline copies of HAL functions using R-vbl
* implementations. Dispatch block at $0100 (RTI stubs);
* HAL_time_init patches $010C at runtime.
*
* Assemble (from repo root):
*   lwasm --decb -o tests/scripted/vbl_irq_test_driver.bin \
*         tests/scripted/vbl_irq_test_driver.s
* ---------------------------------------------------------------

        setdp   0

* DP variable addresses
hal_frame_hi    equ $10
hal_frame_lo    equ $11
sys_init_cc_mask equ $13

* ---------------------------------------------------------------
* Segment 1: Interrupt dispatch block at $0100
* RTI stubs; HAL_time_init patches $010C with JMP hal_vbl_handler.
* [ref: docs/project/interrupt-handling.md §2 — three-level dispatch]
* [ref: docs/project/interrupt-handling.md §4 — dispatch block design]
* ---------------------------------------------------------------
        org     $0100

swi3_handler:   rti                     ; $0100
                nop
                nop
swi2_handler:   rti                     ; $0103
                nop
                nop
swi_handler:    rti                     ; $0106
                nop
                nop
nmi_handler:    rti                     ; $0109
                nop
                nop
irq_handler:    rti                     ; $010C — patched by HAL_time_init
                nop
                nop
firq_handler:   rti                     ; $010F
                nop
                nop

* ---------------------------------------------------------------
* Segment 2: Test driver code
* ---------------------------------------------------------------
        org     $0200

test_start:
        orcc    #$50                    ; mask IRQ+FIRQ (driver convention)
        clra
        tfr     a,dp                    ; DP = 0

        jsr     HAL_sys_init            ; bare-metal transition; returns CC.I=1

* Save CC after HAL_sys_init (V-cc-trace / P-W2.c: verify CC.I preserved
* through HAL_time_init)
        tfr     cc,a
        sta     <sys_init_cc_mask       ; record CC post-sys_init

        jsr     HAL_time_init           ; install handler, configure GIME
                                        ; CC.I must still be 1 after this call
                                        ; (E1.c invariant — do not relax here)

* V-cc-trace: CC.I after HAL_time_init must equal CC.I after HAL_sys_init.
* If E1.c is violated, these will differ. Harness reads sys_init_cc_mask
* and compares to CC register captured immediately after HAL_time_init.
* (Harness reads both; both should have CC.I bit set.)

* === OPT-IN: unmask IRQ — handler now fires on VBL ===
* [ref: docs/project/interrupt-handling.md §10.2 — opt-in sequence step 4]
        andcc   #$EF                    ; clear CC.I; VBL IRQ enabled

* === Tight spin loop — Lua harness measures counter rate ===
* Counter at DP $10/$11 advances via IRQ handler, not main thread.
* [ref: docs/project/interrupt-handling.md §10.3 — V-counter-rate pattern]
test_spin:
        bra     test_spin               ; spin forever; harness captures here

* ---------------------------------------------------------------
* Inline HAL implementations (R-vbl versions)
* ---------------------------------------------------------------

* HAL_sys_init — inline copy of src/hal/coco3-dsk/sys.s
* [ref: src/hal/coco3-dsk/sys.s — full implementation]
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

* HAL_time_init — inline copy of src/hal/coco3-dsk/time.s (R-vbl version)
* [ref: src/hal/coco3-dsk/time.s HAL_time_init — R-vbl extended]
HAL_time_init:
        clr     <hal_frame_hi
        clr     <hal_frame_lo
        lda     #$7E
        sta     $010C
        ldx     #hal_vbl_handler
        stx     $010D
        clra
        sta     $FF93
        lda     #$08
        sta     $FF92
        lda     #$6C
        sta     $FF90
        andcc   #$FE
        rts

* hal_vbl_handler — inline copy of src/hal/coco3-dsk/irq_vbl.s
* [ref: src/hal/coco3-dsk/irq_vbl.s hal_vbl_handler — R-vbl]
hal_vbl_handler:
        lda     $FF92
        bita    #$08
        beq     hal_vbl_irq_exit_d
        inc     <hal_frame_lo
        bne     hal_vbl_irq_exit_d
        inc     <hal_frame_hi
hal_vbl_irq_exit_d:
        rti

        end     test_start
