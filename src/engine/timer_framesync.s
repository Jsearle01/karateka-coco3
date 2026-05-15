* src/engine/timer_framesync.s
*
* Attract-loop timer/frame-sync subsystem — page-flip and VBL gate.
*
* ORIGIN: karateka_dissasembly_claude src/kernel.s
*         Apple II $0799 (routine_0799 / page-flip A),
*                  $07AC (routine_07ac / page-flip B),
*                  $07D7 (routine_07d7 / VBL sync — replaced by HAL_time_vbl_wait)
*
* Purpose:
*   Implements the double-buffer page-flip cycle used by the attract
*   loop. On each call, switches the active draw buffer ($20 <-> $40)
*   and records the old buffer in page_source_blit for the subsequent
*   blit pass. Calls HAL_time_vbl_wait to advance the frame counter
*   (P3 replaces with real GIME VBL sync). Calls HAL_gfx_present to
*   switch the displayed buffer (replaces Apple II TXTPAGE1/TXTPAGE2
*   hardware strobe).
*
* Inputs:
*   page_register (DP $50) — current draw-buffer selector ($20 or $40)
*   (initialized to $20 by caller before first page_flip call)
*
* Outputs:
*   page_register (DP $50) toggled: $20 -> $40 or $40 -> $20
*   page_source_blit (DP $51) = prior page_register value
*
* Clobbers:   A, CC
* Preserves:  B, X, Y, U, DP
*
* HAL calls:
*   HAL_time_vbl_wait  (A=1) — advance frame counter, return
*   HAL_gfx_present         — swap displayed / draw buffers
*
* Reference citations:
*   [ref: kernel.s routine_0799 — sta $E4; sta $07; jsr routine_07d7; lda TXTPAGE1]
*   [ref: kernel.s routine_07ac — sta $E4; sta $07; jsr routine_07d7; lda TXTPAGE2]
*   [ref: hal.inc HAL_time_vbl_wait — advance frame counter (P3: real VBL sync)]
*   [ref: hal.inc HAL_gfx_present — swap front/back buffers]
*   [ref: conventions.md §2 — DP $50-$5F frame-coherent variables band]
* ---------------------------------------------------------------

        setdp   0               ; DP=0; lwasm uses direct-page for <addr

* DP variable declarations.
* [NOTE: migrate to src/engine/globals.s when that file is created in P2.]
page_register       equ $50     ; active draw buffer ($20=buf-A, $40=buf-B)
page_source_blit    equ $51     ; prior buffer; used by blit loop each frame

* Page-flip value constants.
* [ref: data-areas-catalog.md ZP$07 — $20=hires page 1 ($2000), $40=hires page 2 ($4000)]
* CoCo3 maps these to frame buffer A ($8000) and B ($C000) conceptually;
* the $20/$40 values are preserved as behavioral tokens, not hardware addresses.
PAGE_A              equ $20     ; "page 1" token (Apple II hires page 1 base)
PAGE_B              equ $40     ; "page 2" token (Apple II hires page 2 base)

* ---------------------------------------------------------------
* page_flip
*
* Toggle active draw buffer and sync to next frame.
* Entry point for the frame-gate call (replaces JSR L0783 in the
* attract loop). Called once per animation step by the outer frame
* driver.
*
* ORIGIN: karateka_dissasembly_claude src/kernel.s
*         Apple II $0783 (JMP trampoline) -> $0799 (routine_0799)
*
* If page_register == PAGE_B ($40): tail-fall to page_flip_to_a
* Otherwise: save page_register to page_source_blit,
*            set page_register = PAGE_B, wait 1 frame, present.
*
* Clobbers: A, CC
* ---------------------------------------------------------------
page_flip:
        lda     <page_register          ; [ref: kernel.s routine_0799 lda $07]
        cmpa    #PAGE_B                 ; already on buf-B?
        beq     page_flip_to_a          ; [ref: kernel.s beq routine_07ac]
        * Path: cur=PAGE_A -> switch to PAGE_B
        sta     <page_source_blit       ; [ref: kernel.s sta $E4 (save blit source)]
        lda     #PAGE_B
        sta     <page_register          ; [ref: kernel.s lda #$40 / sta $07]
        lda     #1
        jsr     HAL_time_vbl_wait       ; [ref: kernel.s jsr routine_07d7 (VBL sync)]
        jsr     HAL_gfx_present         ; [ref: kernel.s lda TXTPAGE1 (display gate)]
        rts

* ---------------------------------------------------------------
* page_flip_to_a (internal label)
*
* Second half of the page-flip pair (cur=PAGE_B -> switch to PAGE_A).
* Entered via beq from page_flip when page_register already == PAGE_B.
* A = PAGE_B on entry (loaded before the beq; preserved across branch).
*
* ORIGIN: karateka_dissasembly_claude src/kernel.s $07AC (routine_07ac)
*
* [ref: kernel.s routine_07ac — sta $E4; lda #$20; sta $07; jsr routine_07d7; lda TXTPAGE2]
* ---------------------------------------------------------------
page_flip_to_a:
        sta     <page_source_blit       ; A = PAGE_B; [ref: kernel.s sta $E4]
        lda     #PAGE_A
        sta     <page_register          ; [ref: kernel.s lda #$20 / sta $07]
        lda     #1
        jsr     HAL_time_vbl_wait       ; [ref: kernel.s jsr routine_07d7 (VBL sync)]
        jsr     HAL_gfx_present         ; [ref: kernel.s lda TXTPAGE2]
        rts
