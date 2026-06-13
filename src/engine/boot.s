* src/engine/boot.s
*
* Production boot entry point for karateka-coco3.
*
* Two segments:
*   .org $0100 — Interrupt handler dispatch block
*   .org $0200 — Boot entry sequence
*
* Purpose:
*   (1) Handler dispatch block at $0100-$0111 provides RTI stubs for
*       all six CoCo3 interrupt dispatch destinations. The CoCo3 ROM
*       routes interrupts through $FFxx(ROM) → $FExx → $01xx; these
*       stubs are the $01xx destinations.
*   (2) boot entry at $0200: executes HAL INIT ORDER (hal.inc §0-6),
*       then enters per_frame_main_loop.
*
* DISPATCH BLOCK OWNERSHIP:
*   The dispatch block lives in boot.s for the PRODUCTION build.
*   Test drivers maintain their own inline dispatch block (self-
*   contained build pattern). sys.s no longer contains .org $0100.
*
* INIT ORDER (per src/hal.inc):
*   0. HAL_sys_init         — bare-metal: mask + $FF90 + MMU
*   1. HAL_mem_size_detect  — memory probe (stub: returns 128K)
*   2. HAL_time_init        — zero frame counters
*   3. HAL_gfx_init         — GIME mode + clear frame buffers
*   4. HAL_input_init       — input hardware (stub)
*   5. HAL_sound_init       — sound hardware (stub)
*   6. HAL_file_init        — disk subsystem (stub)
*
* INTERRUPT MASK POLICY:
*   boot.s starts with ORCC #$50 (defensive; HAL_sys_init also
*   masks). With all interrupt sources disabled and dispatch stubs
*   providing safe RTI landing pads, the system is interrupt-safe.
*   [ref: docs/conventions.md §16 — interrupt mask policy]
*   [ref: docs/open-questions.md Q001 — interrupt migration plan]
*
* Reference citations:
*   [ref: docs/SockmasterGime.md §1] — $01xx dispatch block routing
*   [ref: docs/memory-map.md §2] — $0100 dispatch block within stack
*   [ref: docs/memory-map.md §4.3] — $0200 engine code start address
*   [ref: src/hal.inc INIT ORDER] — boot sequence
*   [ref: docs/interrupt-handling.md] — dispatch block design
*   [ref: docs/conventions.md §16] — interrupt mask policy
*   [ref: 6502-6809-conversion-patterns/shared/G-methodology/
*         G.3-coco3-platform-assumptions.md — G.3.3 vector dispatch]
* ---------------------------------------------------------------

* ---------------------------------------------------------------
* Segment 1: Interrupt handler dispatch block
* Physical location: $0100-$0111 (18 bytes)
*
* Address order per Sockmaster-GIME §1 ($01xx routing table):
*   SWI3 → $0100, SWI2 → $0103, SWI → $0106
*   NMI  → $0109, IRQ  → $010C, FIRQ → $010F
*
* P3.1 replacement: to install a real handler, replace RTI ($3B)
*   at the slot with JMP opcode ($7E) + 2-byte handler address.
*   [ref: docs/interrupt-handling.md §4 — P3.1 procedure]
* ---------------------------------------------------------------
        org     $0100

swi3_handler:
        rti                         ; $0100 — SWI3: $FFF2(ROM)→$FEEE→here
        nop
        nop
swi2_handler:
        rti                         ; $0103 — SWI2: $FFF4(ROM)→$FEF1→here
        nop
        nop
swi_handler:
        rti                         ; $0106 — SWI:  $FFFA(ROM)→$FEFA→here
        nop
        nop
nmi_handler:
        rti                         ; $0109 — NMI:  $FFFC(ROM)→$FEFD→here
        nop
        nop
irq_handler:
        rti                         ; $010C — IRQ:  $FFF8(ROM)→$FEF7→here
        nop
        nop
firq_handler:
        rti                         ; $010F — FIRQ: $FFF6(ROM)→$FEF4→here
        nop
        nop

* ---------------------------------------------------------------
* Segment 2: Boot entry sequence
* Entry address: $0200 per memory-map.md §4.3 (engine code start)
* ---------------------------------------------------------------
        org     $0200

boot:
* Driver bootstrap (not HAL_sys_init's job; boot.s owns these)
        orcc    #$50                    ; mask IRQ+FIRQ (defensive;
                                        ; HAL_sys_init also masks as step 1)
        lds     #$01FF                  ; stack: first push lands at $01FE,
                                        ; above $0112 (dispatch block end)
        clra
        tfr     a,dp                    ; DP = 0 (direct-page addressing)

* INIT ORDER per hal.inc:
* Step 0: HAL_sys_init — bare-metal transition
*   Masks interrupts, writes $FF90=$4C (GIME MMU mode), programs
*   FFA0-FFA7 = $38-$3F (P1.6 physical layout).
*   [ref: src/hal/coco3-dsk/sys.s]
        jsr     HAL_sys_init

* Step 1: HAL_mem_size_detect — memory probe (stub: 128K default)
*   [ref: src/hal/coco3-dsk/mem.s]
        jsr     HAL_mem_size_detect

* Step 2: HAL_time_init — zero frame counter
*   [ref: src/hal/coco3-dsk/time.s]
        jsr     HAL_time_init

* Step 3: HAL_gfx_init — GIME 320x192x4, clear frame buffers, palette
*   A = 0 = Brøderbund palette descriptor 0
*   [ref: src/hal/coco3-dsk/gfx.s]
        lda     #$00
        jsr     HAL_gfx_init

* Step 4: HAL_input_init — input hardware (stub)
*   [ref: src/hal/coco3-dsk/input.s]
        jsr     HAL_input_init

* Step 5: HAL_sound_init — sound hardware (stub)
*   [ref: src/hal/coco3-dsk/sound.s]
        jsr     HAL_sound_init

* Step 6: HAL_file_init — disk subsystem (stub)
*   [ref: src/hal/coco3-dsk/file.s]
        jsr     HAL_file_init

* Initialize engine page_register:
*   page_register = PAGE_A_TOKEN ($20): buffer A is the draw target.
*   HAL_gfx_init left GIME displaying Frame B ($FF9D=$F8).
*   Option B convention: $20 = buffer A is back (draw target); GIME shows B.
*   [ref: docs/conventions.md §2 CONVENTION NOTE — Option B]
        lda     #PAGE_A_TOKEN           ; $20 = buffer A is draw target (back)
        sta     <page_register

* INT-1: Brøderbund splash scene (R-boot)
*
* Late VBL opt-in (D4.b): andcc #$EF here, right before rendering.
* HAL_time_init (step 2) already installed handler + configured GIME.
* Frame counter now interrupt-driven; HAL_time_delay uses real-VBL timing.
* [ref: docs/interrupt-handling.md §10.2 — opt-in sequence]
        andcc   #$EF                    ; unmask IRQ — VBL handler now fires

* ===============================================================
* INT-1 / R-p24: Canonical scene-1 controller
*
* Ports Apple II outer_caller_b77c ($B77C-$B797) as a linear controller:
*   scene-1 render → 160-frame hold → 1→2 transition → 80-frame blank →
*   halt at the scene-1→scene-2 cut ($B798). Replaces R-boot's blocking
*   HAL_time_delay holds with per-frame VBL-counted holds that POLL input
*   every frame (= stub_b823 outer loop + routine_b7f5 per-frame poll;
*   the Apple II $80/$D2 inner-count is replaced by real VBL).
*
* Input during a hold sets the canonical game-start flags (= LB7DE:
*   $86/$4F = $01) and breaks the hold early. The game-start CONSUMER is
*   STUBBED until R-p25 (scene 2) — detection only here.
*
* Scene-1 input is POLLED (HAL_input_poll); NO PIA CA/CB re-enable
*   (R-boot IRQ config untouched — verified against sys.s).
*
* NOT ported here (deferred — beyond the scene-1→scene-2 cut, §2b):
*   jmptable_b760 per-frame continuation + intro_prelude_b769 prelude +
*   the attract loop-back. Adding the prelude would also diverge from the
*   R-boot visual baseline (AC-10). See report scope-deviation note.
*
* [ref: karateka_dissasembly_claude/src/intro.s outer_caller_b77c,
*       stub_b823, routine_b7f5, LB7DE]
* [ref: docs/project-state.md — R-p24]
* ===============================================================
        clr     <intro_input_flag       ; clear game-start flags ($86 analog)
        clr     <intro_inputaux_flag    ; ($4F analog)

* Scene 1 — Brøderbund presents (= $B77C: L1900 / b898 / b8c2 / L0783).
* broderbund_scene renders Logo 1, Logo 2, "presents" and presents.
* [ref: src/engine/broderbund_scene.s]
        jsr     broderbund_scene
        lda     #160                    ; 160-frame hold (= stub_b823 X=$A0)
        jsr     scene1_hold_poll
        bcs     scene1_input_break      ; input during hold → "pressed" early break

* Transition 1→2 (= $B78D: 80-frame blank):
        jsr     HAL_gfx_clear
        jsr     HAL_gfx_present
        lda     #80
        jsr     scene1_hold_poll
        bcs     scene1_input_break

* Scene 2 — Mechner credit (= $B79B: L1900 / b8ce / holds).
* Oracle's 160+80 holds show the credit continuously; merged to one
* 240-frame hold (no mid-scene re-present — avoids the CoCo3 Option-I
* flip to a stale back buffer). [ref: src/engine/intro_scenes.s]
        jsr     HAL_gfx_clear           ; = L1900
        jsr     scene2_render           ; "a game by" + "jordan mechner"
        jsr     HAL_gfx_present         ; = L0783
        lda     #240                    ; 160 + 80, credit held continuously
        jsr     scene1_hold_poll
        bcs     scene1_input_break

* Scene 3 pass 1 — karateka title (= $B7AE: L1900 / b8e6 / hold160):
        jsr     HAL_gfx_clear
        jsr     scene3_title_render
        jsr     HAL_gfx_present
        lda     #160
        jsr     scene1_hold_poll
        bcs     scene1_input_break

* Scene 3 pass 2 — add copyright BELOW the held title (= $B7BC: b8f3).
* No clear, no title re-render: rendering is single-buffered (page_register
* stays on buffer A; HAL_gfx_present only sets the GIME display offset, it
* does not flip), so the title is already on the displayed buffer — clearing
* or re-rendering it blanked + redrew the visible title (the flash). Just
* draw the copyright onto A and present.
        jsr     scene3_copyright
        jsr     HAL_gfx_present
        lda     #160
        jsr     scene1_hold_poll
        bcs     scene1_input_break

* Transition 3→4 (= $B7D2: 80-frame blank):
        jsr     HAL_gfx_clear
        jsr     HAL_gfx_present
        lda     #80
        jsr     scene1_hold_poll
        bcs     scene1_input_break

* Scene 4 — scrolling narrative (= $B7D5: routine_b833). GIME VOFFSET
* scroll with amortized memmove-on-wrap (R-p26 v3). Polls input each frame;
* a press early-breaks to "pressed" (shared with scenes 1-3).
* [ref: src/engine/scene4_scroll.s; conventions §19/§22.4b]
        jsr     scene4_scroll
        bcs     scene1_input_break      ; press during scroll → "pressed" early break

* Reached the scene-4 → scene-5 cut ($B7DB). Scene 5 = R-p27+.
        bra     boot_halt

* Input detected during any hold (= LB7DE): set the game-start flags, then
* show the shared "pressed" screen. The real game-start consumer is STUBBED
* (P3+); "pressed" is a DEBUG PLACEHOLDER (the intended R-p25+N replacement).
* [ref: src/engine/intro_scenes.s pressed_screen]
scene1_input_break:
        lda     #$01
        sta     <intro_input_flag       ; $86 = $01 ("input received")
        sta     <intro_inputaux_flag    ; $4F = $01 (companion)
        jsr     pressed_screen          ; clear → "pressed" → present (debug placeholder)
        bra     boot_halt

boot_halt:
        bra     boot_halt

* ---------------------------------------------------------------
* scene1_hold_poll  [R-p24]
*
* Hold for A frames under real VBL, polling input each frame.
* = Apple II stub_b823 outer loop (X frames) with routine_b7f5 per-frame
*   poll; the $80/$D2 inner-count is replaced by real VBL — one
*   HAL_time_vbl_wait per iteration. Mirrors HAL_time_delay's
*   pshs/puls/deca idiom (time.s) so A=0 ⇒ 256 frames.
*
* Args:    A = frame count (0 ⇒ 256).
* Returns: CC.C set  = input detected this hold (early break);
*          CC.C clear = full count elapsed, no input.
* Clobbers: A, B, CC.  Preserves X, Y, U.
* ---------------------------------------------------------------
scene1_hold_poll:
hold_poll_loop:
        pshs    a                       ; save remaining frame count
        jsr     HAL_time_vbl_wait       ; wait 1 real-VBL frame (clobbers A,B)
        jsr     HAL_input_poll          ; poll keyboard/buttons (CC.C = input)
        bcs     hold_poll_input         ; input this frame → early break
        puls    a                       ; restore remaining count
        deca
        bne     hold_poll_loop
        andcc   #$FE                    ; full count elapsed: CC.C clear
        rts
hold_poll_input:
        leas    1,s                     ; discard saved count (early break)
        orcc    #$01                    ; CC.C set = input detected
        rts
* NOTE: exec address set by `end boot` in last assembled file (src/hal/coco3-dsk/mem.s)
