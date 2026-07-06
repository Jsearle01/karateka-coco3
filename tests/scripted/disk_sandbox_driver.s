* tests/scripted/disk_sandbox_driver.s
*
* STANDALONE sandbox harness for the HALT read primitive (BUILD #1 + BUILD #2).
* Exercises the REAL shared-source primitive (src/hal/coco3-dsk/disk_read.s) in
* isolation. NOT linked into prod — assembled as its own unit so karateka.bin
* stays byte-identical. Three tests:
*   (Build #1 regression) single-sector read T2/S5, verify byte[i]=i + RNF path.
*   (Build #2) multi-track m=1 range read tracks 33-34 (36 sectors, crosses a track
*     boundary), verify position-encoded byte[k][i]=(k+i) in order.
*   (Build #2 error) bad-track range returns without hanging.
*
* Fixture (tools/make_test_dsk.sh): 35x18x256 DD disk; T2/S5 = byte[i]=i;
*   tracks 33-34 all sectors = byte[k][i]=(k+i) where k is the 0-based ordinal.
*
* Result locations (read by tests/scripted/disk_sandbox.lua):
*   $2200 single-sector PASS ($A5/$5A) · $2201 status · $2202 nmi_done · $2203 ccerr
*   $2204 bad-sector RNF status · $2205 bad-sector ccerr
*   $2206 RANGE PASS ($A5/$5A) · $2207 range status · $2208 bad-track ccerr
*   $2000.. single-sector buffer · $4000.. range buffer (36x256)
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
RES_RANGE_PASS equ $2206            ; Build #2: multi-track range match ($A5/$5A)
RES_RANGE_STAT equ $2207            ; Build #2: last-track status
RES_BADTRK_CC  equ $2208            ; off-end range (track 40) CC.C — expect $01 (caught)
RES_FAILGUARD  equ $220B            ; 3a: $A5 => a failed read did NOT jump (boot-safety)
RES_JUMP_BAD   equ $220C            ; 3a: $5A => the good read unexpectedly failed (should stay $00)
RJ_LOADADDR    equ $220D            ; 3a: saved load address (disk_read_range advances dr_dest)
TEST_TRACK  equ 2
TEST_SECTOR equ 5
RANGE_BUF   equ $4000              ; multi-track dest (36 sectors x 256 = 9216 B)
RANGE_TRACK equ 33                 ; range spans tracks 33-34 (last two; crosses a
RANGE_COUNT equ 36                 ; boundary, HS-5; edge-adjacent for the advance test)

test_start:
        orcc    #$50                 ; mask IRQ/FIRQ (NMI stays enabled)
        lds     #$1F00               ; stack grows down; clear of code ($0200) and the
                                     ; relocated params ($2100, above the stack init)
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
        clr     RES_RANGE_PASS       ; stays $00 if the range read HANGS (finding)
        clr     RES_RANGE_STAT
        clr     RES_BADTRK_CC
        clr     RES_FAILGUARD        ; stays $00 if a failed read wrongly jumped (finding)
        clr     RES_JUMP_BAD

        jsr     disk_read_init       ; install our NMI vector + handler ($FEFD/$FE20)

    ifdef READJUMP
        jmp     do_readjump          ; READJUMP build: prove read-and-jump in a CLEAN FDC state
    endif

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

        * --- Build #1 regression: bad SECTOR (99) -> RNF, no hang. Run in a clean
        *     FDC state (right after the single-sector read, before the edge tests). ---
        lda     #TEST_TRACK
        sta     dr_track
        lda     #99                  ; sector 99 does not exist (18/track)
        sta     dr_sector
        ldd     #$2300               ; separate dest
        std     dr_dest
        jsr     disk_read            ; must return (not hang); RNF in status
        lda     #$00                 ; NB: lda #0 preserves CC.C (clra would clear it)
        bcc     bad_noerr
        lda     #$01
bad_noerr:
        sta     RES_BAD_CCERR        ; expect $01 (CC.C error return)
        lda     dr_status
        sta     RES_BAD_STATUS       ; expect bit4 (RNF, $10) set

        * === Build #2: multi-track range read (tracks 33-34 = 36 sectors) -> $4000 ===
        lda     #RANGE_TRACK
        sta     dr_r_track
        lda     #RANGE_COUNT
        sta     dr_r_count
        ldd     #RANGE_BUF
        std     dr_dest
        jsr     disk_read_range      ; m=1 per track + Seek-advance across boundary
        lda     dr_status
        sta     RES_RANGE_STAT

        * verify: sector ordinal k=0..35, byte[k*256+i] == (k+i) mod 256
        ldx     #RANGE_BUF
        clrb                         ; B = k (sector ordinal, first byte of sector k = k)
rng_ksec:
        pshs    b
        tfr     b,a                  ; A = expected start value (= k)
        clrb                         ; inner counter (256 via wrap)
rng_ibyte:
        cmpa    ,x+                  ; expected(A) vs actual
        bne     rng_fail
        inca                         ; next expected = (k+i+1) mod 256
        decb
        bne     rng_ibyte            ; 256 bytes/sector
        puls    b                    ; restore k
        incb
        cmpb    #RANGE_COUNT         ; all 36 sectors verified?
        bne     rng_ksec
        lda     #$A5                 ; whole range matched in order -> PASS
        bra     rng_done
rng_fail:
        puls    b                    ; balance stack
        lda     #$5A                 ; gap/dup/reorder/mismatch -> FAIL
rng_done:
        sta     RES_RANGE_PASS

        * === CORRECTION: off-end range MUST error (was Build #2's silent zeros) ===
        * (a) clearly off-end: start track 40 (> 34) -> bound errors before seeking.
        lda     #40
        sta     dr_r_track
        lda     #SECS_TRACK
        sta     dr_r_count
        ldd     #$6400               ; scratch dest (RAM, past the range buffer)
        std     dr_dest
        jsr     disk_read_range      ; must set carry (off-end), not silently succeed
        lda     #$00
        bcc     bt_noerr
        lda     #$01
bt_noerr:
        sta     RES_BADTRK_CC        ; expect $01 (off-end CAUGHT — the correction)
        * NOTE: the off-end bound fires BEFORE any seek (cmpa dr_track / bhs), so it
        * is MAME-edge-independent by construction. A "read valid tracks then cross
        * off-end" variant was dropped — it exercises MAME's quirky edge-track read
        * (reading track 34 after a direct 0->34 seek stalls), not our bound; the bound
        * is the same code every iteration, proven by the track-40 case above.

test_spin:
        bra     test_spin            ; harness captures results here

* ============================================================
* BUILD #3a: READ-AND-JUMP (the one new loader mechanism)
*   Reached only in the READJUMP build (jmp'd from just after disk_read_init, in a
*   CLEAN FDC state). A separate build so MAME's coco_fdc state quirk — where m=1
*   reads stall after the regressions' off-end/failed-guard Restore sequence — does
*   not mask the mechanism. Same pattern as SCENE5_STANDALONE.
* ============================================================
do_readjump:
        * (a) FAILED-READ GUARD (HS-6): a bad (off-end) range must NOT jump into a
        *     half-loaded/garbage payload — try_read_and_jump must RETURN.
        lda     #40                  ; off-end -> disk_read_range sets carry
        sta     dr_r_track
        lda     #SECS_TRACK
        sta     dr_r_count
        ldd     #$6400               ; harmless dest
        std     dr_dest
        jsr     try_read_and_jump    ; must return (rj_fail), NOT jump
        lda     #$A5
        sta     RES_FAILGUARD        ; $A5 => we returned = no jump on a failed read

        * (b) SUCCESSFUL READ-AND-JUMP: load the image-shaped payload (tracks 5-6)
        *     to $3000 (NOT the framebuffer), then jump into it. The loaded stub
        *     writes its signature ($CAFE->$2500, $A5->$2502) and halts at $300B.
        clr     $2500                ; clear the signature area — the STUB alone
        clr     $2501                ; writes it, so a nonzero value proves it ran
        clr     $2502
        lda     #5                   ; payload on tracks 5-6
        sta     dr_r_track
        lda     #36                  ; 2 whole tracks
        sta     dr_r_count
        ldd     #$3000               ; controllable load address (HS-4: not $8000+)
        std     dr_dest
        std     RJ_LOADADDR          ; SAVE it — disk_read_range advances dr_dest past the payload
        jsr     try_read_and_jump    ; success -> jmp $3000 (loaded stub); NEVER returns
        lda     #$5A                 ; only reached if the good read unexpectedly failed
        sta     RES_JUMP_BAD
rj_spin:
        bra     rj_spin

* --- try_read_and_jump: read the range; jump into it ONLY on success ---
try_read_and_jump:
        jsr     disk_read_range      ; the proven primitive (unchanged)
        bcs     rj_fail              ; read FAILED -> do NOT jump (boot-safety, HS-6)
        ldx     RJ_LOADADDR          ; X = ORIGINAL load address (dr_dest is now advanced)
        jmp     ,x                   ; jump into the loaded code (does not return)
rj_fail:
        rts                          ; return with carry set (no jump taken)

* --- the primitive under test (shared source) ---
        include "disk_read.s"

        end     test_start
