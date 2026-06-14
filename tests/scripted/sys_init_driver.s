* tests/scripted/sys_init_driver.s
*
* Test driver for P2.3a.0 HAL_sys_init behavioral verification.
* Self-contained: inline copy of HAL_sys_init from sys.s.
*
* Production source:
*   src/hal/coco3-dsk/sys.s  (HAL_sys_init, dispatch block)
* Any changes to that file must be mirrored here for test accuracy.
*
* Boot integration: driver runs after BASIC-ready state (frame 300+
*   with PC in ROM, per P2.3a.2 harness boot-context discipline).
*
* Verification predictions (P2.3a.0):
*   DP $13 (sys_init_cc_mask)  = $50  (CC: I=1, F=1 — interrupts masked)
*   $FFA0 (mmu_slot_0)         = $38
*   $FFA1 (mmu_slot_1)         = $39
*   $FFA2 (mmu_slot_2)         = $3A
*   $FFA3 (mmu_slot_3)         = $3B
*   $FFA4 (mmu_slot_4)         = $3C
*   $FFA5 (mmu_slot_5)         = $3D
*   $FFA6 (mmu_slot_6)         = $3E
*   $FFA7 (mmu_slot_7)         = $3F
*   $0100 (swi3_handler)       = $3B  (RTI opcode)
*   $010C (irq_handler)        = $3B  (RTI opcode; P3.1 replacement slot)
*   $010F (firq_handler)       = $3B  (RTI opcode)
*
* Assemble (from repo root):
*   lwasm --decb -o tests/scripted/sys_init_driver.bin \
*         tests/scripted/sys_init_driver.s
*
* NOTE: Plan D3 spec says `lds #$0100`. This is incorrect — S=$0100
*   would push to $00FF (DP) on first PSHS. Corrected to `lds #$01FF`
*   per plan-deviation-discipline. STOP condition not triggered; this
*   is an obvious plan typo, not a design question.
* ---------------------------------------------------------------

* ---------------------------------------------------------------
* Handler dispatch block (inline copy from sys.s)
* Physical location: $0100-$0111 (18 bytes)
* [ref: docs/ground-truth/SockmasterGime.md §1] — $01xx routing table
* ---------------------------------------------------------------
        org     $0100

swi3_handler:
        rti                         ; $3B — $FFF2(ROM)→$FEEE→$0100
        nop
        nop

swi2_handler:
        rti                         ; $3B — $FFF4(ROM)→$FEF1→$0103
        nop
        nop

swi_handler:
        rti                         ; $3B — $FFFA(ROM)→$FEFA→$0106
        nop
        nop

nmi_handler:
        rti                         ; $3B — $FFFC(ROM)→$FEFD→$0109
        nop
        nop

irq_handler:
        rti                         ; $3B — $FFF8(ROM)→$FEF7→$010C
        nop
        nop

firq_handler:
        rti                         ; $3B — $FFF6(ROM)→$FEF4→$010F
        nop
        nop

* ---------------------------------------------------------------
* Main test code
* ---------------------------------------------------------------
        org     $0200               ; load/exec address in CoCo3 RAM
        setdp   0

* DP variables (HAL scratch band $00-$1F)
sys_init_cc_mask    equ $13         ; CC after HAL_sys_init (diagnostic)
mmu_pre_0           equ $14         ; FFA0 value before HAL_sys_init
mmu_pre_1           equ $15
mmu_pre_2           equ $16
mmu_pre_3           equ $17
mmu_pre_4           equ $18
mmu_pre_5           equ $19
mmu_pre_6           equ $1A
mmu_pre_7           equ $1B

* ---------------------------------------------------------------
* test_start — driver entry point
* ---------------------------------------------------------------
test_start:
        orcc    #$50                ; disable IRQ/FIRQ (driver-level mask)
        lds     #$01FF              ; stack above dispatch block; first push → $01FE
        clra
        tfr     a,dp                ; DP = 0

        * Pre-capture: snapshot MMU slots before HAL_sys_init
        * (BASIC's values; expected to already be $38-$3F per boot)
        lda     $FFA0
        sta     <mmu_pre_0
        lda     $FFA1
        sta     <mmu_pre_1
        lda     $FFA2
        sta     <mmu_pre_2
        lda     $FFA3
        sta     <mmu_pre_3
        lda     $FFA4
        sta     <mmu_pre_4
        lda     $FFA5
        sta     <mmu_pre_5
        lda     $FFA6
        sta     <mmu_pre_6
        lda     $FFA7
        sta     <mmu_pre_7

        * Call HAL_sys_init (inline copy below)
        jsr     HAL_sys_init

        * Post-capture: save CC mask state for harness verification
        * TFR CC,A moves CC to A so we can STA it to DP
        tfr     cc,a
        sta     <sys_init_cc_mask   ; $13 = CC (expect $50: I=1, F=1)

test_loop:
        bra     test_loop           ; spin; harness captures state here

* ---------------------------------------------------------------
* HAL_sys_init — inline copy of src/hal/coco3-dsk/sys.s
* [ref: sys.s HAL_sys_init — CoCo3 bare-metal transition]
* Any change to sys.s must be mirrored here.
* ---------------------------------------------------------------
HAL_sys_init:
        pshs    u,y

        orcc    #$50                ; mask IRQ + FIRQ

        lda     #$4C                ; COCO=0,MMUEN=1,MC3=1,MC2=1
        sta     $FF90               ; [ref: sys.s Step 2]

        lda     #$38                ; [ref: docs/project/memory-map.md §3.2]
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
        andcc   #$FE                ; CC.C clear; CC.I, CC.F remain SET
        rts

        end     test_start
