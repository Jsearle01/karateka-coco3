* src/hal/coco3-dsk/disk_read.s
*
* HALT-based double-density single-sector READ primitive.
* Implements design docs/project/disk-read-primitive-design.md (011863c).
*
* SHARED SOURCE: `include`d by the disk-read sandbox harness (this build) and,
*   later, by the boot stage-1 loader and the resident game image, each linked
*   at its own load address (no PIC). This build is its FIRST client.
*
* Mechanism (branch b, settled a91d080): DSKREG b7=1 wires the WD1773 DRQ to the
*   6809 HALT line, so the data-register read blocks in hardware until each byte
*   is ready — no poll, no timing margin (the CPU cannot outrun the disk). INTRQ
*   (end-of-command) fires NMI AND auto-clears HALT b7 (Unravelled §FDC line 398).
*
* Interface (RAM params, set by caller before `jsr disk_read`):
*   dr_track  (1)  target track  0..34
*   dr_sector (1)  target sector 1..18
*   dr_dest   (2)  destination buffer pointer (256 bytes written)
* Returns:
*   dr_status (1)  final WD1773 status byte
*   CC.C           set on error (RNF b4 | CRC b3 | Lost-Data b2), clear on OK
*   dr_nmi_done    non-zero iff INTRQ->NMI reached our handler (mechanism proof)
* Clobbers: A, B, X, Y. Assumes caller masked IRQ/FIRQ (NMI stays enabled) and
*   called disk_read_init once (installs the NMI vector + handler).
*
* HS-2 design-refinements (flagged, not silent divergence):
*   (1) DSKREG b7 (HALT) is armed ONLY for the Type II Read transfer, NOT during
*       Type I Restore/Seek — Type I generates no DRQ, so b7=1 during positioning
*       would halt the CPU until INTRQ. Positioning uses b7=0 + Busy-poll (the
*       design's "wait Busy-clear" step).
*   (2) Transfer loop is count-bounded (256) — the design's named safety-bound
*       option — rather than purely NMI-terminated; robust because INTRQ clears
*       HALT to free the final store. NMI is retained as the completion SIGNAL
*       (handler sets dr_nmi_done) proving the mechanism engaged.
* ---------------------------------------------------------------

* --- WD1773 / DSKREG registers (addresses: DECB Unravelled; fn: WD1773 dsheet) ---
DSKREG      equ $FF40        ; control latch (write-only)
FDC_CMDST   equ $FF48        ; write=Command, read=Status
FDC_TRACK   equ $FF49
FDC_SECTOR  equ $FF4A
FDC_DATA    equ $FF4B

* --- DSKREG bit fields (Unravelled §$FF40) ---
DSK_DRV0    equ $01          ; drive select 0 (b0)
DSK_MOTOR   equ $08          ; motor enable  (b3)
DSK_DD      equ $20          ; density=double (b5)
DSK_HALT    equ $80          ; HALT enable   (b7)
DSK_POS     equ DSK_DRV0+DSK_MOTOR+DSK_DD          ; $29 positioning (no HALT)
DSK_XFER    equ DSK_DRV0+DSK_MOTOR+DSK_DD+DSK_HALT ; $A9 transfer (HALT armed)

* --- WD1773 commands (WD1773 datasheet Type I / Type II) ---
FDC_RESTORE equ $00          ; Restore, no verify, 6ms rate
FDC_SEEK    equ $10          ; Seek,    no verify, 6ms rate
FDC_READ    equ $80          ; Read Sector, single, side0, no side-compare
FDC_ERRMASK equ $1C          ; RNF(b4)|CRC(b3)|Lost-Data(b2)

* --- caller-set parameters (fixed low-RAM block; client reserves $0170-$0174) ---
dr_track    equ $0170        ; target track  0..34
dr_sector   equ $0171        ; target sector 1..18
dr_dest     equ $0172        ; destination pointer (2 bytes)
dr_status   equ $0174        ; final WD1773 status byte

* --- NMI landing in the constant Vector Page ($FE00-$FEED, safe siting) ---
dr_nmi_done equ $FE00        ; completion flag (1 byte, below secondary vectors)
DR_NMI_HDLR equ $FE20        ; our NMI handler (installed by disk_read_init)
DR_NMI_VEC  equ $FEFD        ; NMI secondary vector ($FFFC[ROM]->$FEFD->handler)

* ---------------------------------------------------------------
* disk_read_init — install our NMI vector + handler in the constant page.
*   Call ONCE after the GIME is in MC3=1 (constant $FExx). M1 lesson: our own
*   vector, sited above the game load ($4823) and the framebuffer loader ($FBFF).
* ---------------------------------------------------------------
disk_read_init:
        * handler at $FE20:  INC dr_nmi_done ; RTI
        lda     #$7C                 ; INC (extended) opcode
        sta     DR_NMI_HDLR
        ldd     #dr_nmi_done
        std     DR_NMI_HDLR+1
        lda     #$3B                 ; RTI
        sta     DR_NMI_HDLR+3
        * vector at $FEFD:  JMP DR_NMI_HDLR
        lda     #$7E                 ; JMP (extended) opcode
        sta     DR_NMI_VEC
        ldd     #DR_NMI_HDLR
        std     DR_NMI_VEC+1
        clr     dr_nmi_done
        rts

* ---------------------------------------------------------------
* disk_read — read dr_track/dr_sector (256 bytes) into (dr_dest) via HALT.
* ---------------------------------------------------------------
disk_read:
        * --- positioning config: drive0 + motor + DD, HALT OFF ---
        lda     #DSK_POS
        sta     DSKREG
        bsr     dr_spinup            ; motor spin-up settle (real HW ~0.5-1s)

        * --- Restore to track 0 ---
        lda     #FDC_RESTORE
        sta     FDC_CMDST
        bsr     dr_settle            ; let Busy assert before polling
        bsr     dr_wait_notbusy

        * --- Seek to target track ---
        lda     dr_track
        sta     FDC_DATA             ; desired track -> Data reg
        lda     #FDC_SEEK
        sta     FDC_CMDST
        bsr     dr_settle
        bsr     dr_wait_notbusy

        * --- select sector ---
        lda     dr_sector
        sta     FDC_SECTOR

        clr     dr_nmi_done          ; arm completion detector
        ldx     dr_dest              ; destination

        * --- issue Read Sector (HALT still OFF), THEN arm HALT ---
        lda     #FDC_READ
        sta     FDC_CMDST
        lda     #DSK_XFER            ; b7=1: DRQ now gates HALT
        sta     DSKREG

        * --- HALT-paced, count-bounded transfer (256 bytes) ---
        ldy     #256
dr_xfer:
        lda     FDC_DATA             ; HALT holds CPU here until DRQ (byte ready)
        sta     ,x+
        leay    -1,y
        bne     dr_xfer
        * INTRQ at end-of-sector cleared HALT b7 + fired NMI (dr_nmi_done set).

        * --- disarm HALT, read final status ---
        lda     #DSK_POS
        sta     DSKREG
        lda     FDC_CMDST
        sta     dr_status
        anda    #FDC_ERRMASK
        bne     dr_err
        andcc   #$FE                 ; C clear = OK
        rts
dr_err:
        orcc    #$01                 ; C set = error
        rts

* --- dr_wait_notbusy: poll Status b0 (Busy) until clear, with a timeout ---
dr_wait_notbusy:
        ldy     #$8000               ; timeout guard (never hang the sandbox)
dr_wnb:
        lda     FDC_CMDST
        bita    #$01                 ; Busy?
        beq     dr_wnb_ok
        leay    -1,y
        bne     dr_wnb
dr_wnb_ok:
        rts

* --- dr_settle: short delay so the FDC asserts Busy / updates status ---
dr_settle:
        ldb     #$20
dr_st1:
        exg     a,a                  ; ~8 cy delay each (DECB-style status-valid wait)
        decb
        bne     dr_st1
        rts

* --- dr_spinup: coarse motor spin-up delay (~real HW needs it; MAME tolerant) ---
dr_spinup:
        pshs    x
        ldx     #$C000
dr_su1:
        leax    -1,x
        bne     dr_su1
        puls    x
        rts
