* tests/scripted/disk_sandbox_driver.s
*
* STANDALONE sandbox harness for the HALT read primitive (BUILD #1).
* Exercises the REAL shared-source primitive (src/hal/coco3-dsk/disk_read.s) in
* isolation: reads one known-pattern sector from a DD test .dsk via HALT and
* verifies the bytes + status + that INTRQ->NMI engaged. NOT linked into prod —
* assembled as its own unit so build/karateka.bin stays byte-identical.
*
* Fixture (tools/make_test_dsk.sh): 35x18x256 DD disk, track 2 / sector 5 holds
*   the incrementing pattern byte[i]=i (0..255). Image offset (2*18+4)*256=10240.
*
* Result locations (read by tests/scripted/disk_sandbox.lua):
*   $2200  = $A5 PASS (buffer matched) / $5A FAIL (mismatch)
*   $2201  = dr_status (final WD1773 status; expect clean, no $1C bits)
*   $2202  = dr_nmi_done (non-zero => INTRQ->NMI reached our handler)
*   $2203  = $01 if disk_read returned CC.C (error) / $00 if OK
*   $2000..$20FF = the 256-byte destination buffer
*
* Assemble (from repo root):
*   lwasm --decb -o tests/scripted/disk_sandbox.bin \
*         tests/scripted/disk_sandbox_driver.s
* ---------------------------------------------------------------

        org     $0200
        setdp   0

INIT0       equ $FF90
INIT0_CC3   equ $4C              ; COCO=0, MMUEN=1, MC3=1, MC2=1 (prod HAL config)
DEST_BUF    equ $2000            ; 256-byte read destination
RES_PASS    equ $2200            ; PASS/FAIL byte
RES_STATUS  equ $2201
RES_NMIDONE equ $2202
RES_CCERR   equ $2203
RES_BAD_STATUS equ $2204            ; AC-7: status from the bad-sector read (expect RNF b4)
RES_BAD_CCERR  equ $2205            ; AC-7: CC.C from the bad-sector read (expect $01)
TEST_TRACK  equ 2
TEST_SECTOR equ 5

test_start:
        orcc    #$50                 ; mask IRQ/FIRQ (NMI stays enabled)
        lds     #$1F00               ; stack clear of params ($0170) + code ($0200)
        clra
        tfr     a,dp                 ; DP = 0

        lda     #INIT0_CC3           ; CoCo3 mode + MC3=1 (constant $FExx page)
        sta     INIT0

        * mark results "not run"
        clr     RES_PASS
        clr     RES_STATUS
        clr     RES_NMIDONE
        clr     RES_CCERR
        clr     RES_BAD_STATUS       ; stays $00 if the bad-sector read HANGS (finding)
        clr     RES_BAD_CCERR

        jsr     disk_read_init       ; install our NMI vector + handler ($FEFD/$FE20)

        * --- drive the primitive: read track 2 / sector 5 -> $2000 ---
        lda     #TEST_TRACK
        sta     dr_track
        lda     #TEST_SECTOR
        sta     dr_sector
        ldd     #DEST_BUF
        std     dr_dest

        jsr     disk_read            ; the REAL primitive under test
        bcc     dr_noerr
        lda     #$01
        sta     RES_CCERR            ; record CC.C (error) return
dr_noerr:

        * --- record status + NMI-reached proof ---
        lda     dr_status
        sta     RES_STATUS
        lda     dr_nmi_done
        sta     RES_NMIDONE

        * --- verify buffer == incrementing pattern byte[i]=i ---
        ldx     #DEST_BUF
        clra                         ; expected 0,1,2,...
cmp_loop:
        cmpa    ,x+                  ; expected(A) vs actual byte
        bne     cmp_fail
        inca
        bne     cmp_loop             ; 256 compares (A wraps 255->0)
        lda     #$A5                 ; all matched -> PASS
        bra     cmp_done
cmp_fail:
        lda     #$5A                 ; mismatch -> FAIL
cmp_done:
        sta     RES_PASS

        * --- AC-7 stretch: read a NONEXISTENT sector (99) -> expect RNF, no hang ---
        lda     #TEST_TRACK
        sta     dr_track
        lda     #99                  ; sector 99 does not exist (18/track)
        sta     dr_sector
        ldd     #$2300               ; separate dest (keep $2000 good-read buffer intact)
        std     dr_dest
        jsr     disk_read            ; must return (not hang); RNF in status
        lda     #$00                 ; NB: lda #0 preserves CC.C (clra would clear it)
        bcc     bad_noerr
        lda     #$01
bad_noerr:
        sta     RES_BAD_CCERR        ; expect $01 (CC.C error return)
        lda     dr_status
        sta     RES_BAD_STATUS       ; expect bit4 (RNF, $10) set

test_spin:
        bra     test_spin            ; harness captures results here

* --- the primitive under test (shared source) ---
        include "disk_read.s"

        end     test_start
