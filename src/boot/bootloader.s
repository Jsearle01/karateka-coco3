* src/boot/bootloader.s
*
* BUILD #3b-2 — the boot loader (framebuffer-resident, raw-loads the real game).
*
* Executes from a FRAMEBUFFER address ($8000+, boot-dead space — the running game
* never writes code/data there, only pixels AFTER this loader has handed off), raw-
* reads the REAL game image from raw 1:1-sequential DMK tracks 0-3 into the game's
* REAL resident region ($0100-$48FF, disjoint from this loader), and jumps to the
* game's REAL entry ($0200). The loader does NOT set up the screen — the game's
* $0200 boot does its own HAL_sys_init/HAL_gfx_init (mask, $FF90, MMU, GIME, clear
* framebuffers) after the jump.
*
* MMU: replicates the game's HAL_sys_init MMU setup exactly (PIA IRQ disable +
* $FF90=$4C + $FFA0-A7 = $38-$3F, the "constant" map = MMUEN=0 default) so the
* load lands in the physical memory the game will see, and $0200's own HAL_sys_init
* is idempotent. MC3=1 is required for the disk NMI handler in the constant page.
*
* Entry: the game entry ($0200) is a FIXED constant, distinct from the advancing
* dr_dest (3a's clobber invariant is trivially satisfied — we jump to the constant
* entry, never to dr_dest).
*
* Launched by tests/scripted/boot_launcher.lua (write the loader to $8000, set PC)
* — standing in for the DECB LOADM+EXEC front-end (the NEXT build). Primitive
* variables relocated to $BF00+ (-D DR_VARBASE=$BF00) clear of the $0100 load.
* ---------------------------------------------------------------

        org     $8000

GAME_LOAD    equ $0100          ; game resident base (segment 1 / dispatch block)
GAME_ENTRY   equ $0200          ; game exec entry (fixed constant)
    ifndef GAME_TRACK
GAME_TRACK   equ 1              ; game raw tracks start (3b-3: tracks 1-4, clear of BOOT@trk0
    endif                       ; and the track-17 directory; -D GAME_TRACK=0 for the 3b-2 standalone)
LOAD_TRACKS  equ 4              ; 4 whole tracks (72 sectors = 18432 B -> $0100-$48FF)
BL_STACK     equ $7F00          ; loader stack: above the game load ($48FF), below us
INIT0        equ $FF90
INIT0_CC3    equ $4C            ; COCO=0, MMUEN=1, MC3=1, MC2=1 (game's HAL_sys_init value)
BL_RESULT    equ $BF20          ; loader result marker (framebuffer, for the launcher)

bootloader:
        orcc    #$50                    ; mask IRQ+FIRQ (NMI stays enabled for the read)
        lds     #BL_STACK               ; stack clear of the game load + this loader
        clra
        tfr     a,dp                    ; DP = 0

        * --- replicate HAL_sys_init's PIA IRQ disable (defensive; game re-does it) ---
        lda     $FF01
        anda    #$FC
        sta     $FF01                   ; PIA0 CRA
        lda     $FF03
        anda    #$FC
        sta     $FF03                   ; PIA0 CRB
        lda     $FF21
        anda    #$FC
        sta     $FF21                   ; PIA1 CRA
        lda     $FF23
        anda    #$FC
        sta     $FF23                   ; PIA1 CRB

        * --- MMU: $FF90=$4C then $FFA0-A7 = $38-$3F (the constant map) ---
        lda     #INIT0_CC3
        sta     INIT0                   ; MMUEN=1, MC3=1 (constant vector page for NMI)
        ldx     #$FFA0
        lda     #$38
bl_mmu:
        sta     ,x+                     ; $FFA0=$38 .. $FFA7=$3F
        inca
        cmpa    #$40
        bne     bl_mmu

        * --- disk: install NMI handler, then single-call m=1 read tracks 0-3 -> $0100 ---
        clr     BL_RESULT               ; 0 = not done
        jsr     disk_read_init

        lda     #GAME_TRACK
        sta     dr_r_track              ; game raw tracks start (3b-3: track 1)
        lda     #LOAD_TRACKS*SECS_TRACK ; 72 sectors (whole tracks)
        sta     dr_r_count
        ldd     #GAME_LOAD
        std     dr_dest                 ; dest $0100 (disk_read_range advances this)
        jsr     disk_read_range         ; the validated single-call whole-track read
        bcs     bl_fail

        lda     #$A5
        sta     BL_RESULT               ; $A5 = load OK (launcher reads this pre-jump)
        jmp     GAME_ENTRY              ; jump to the game's fixed entry ($0200) — RUNS + RENDERS

bl_fail:
        lda     #$5A
        sta     BL_RESULT               ; $5A = load failed (no jump; visible as no render)
        lda     dr_status
        sta     BL_RESULT+1
bl_hang:
        bra     bl_hang

* --- the shared disk primitive (vars relocated via -D DR_VARBASE=$BF00) ---
        include "disk_read.s"

        end     bootloader
