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

* Render scene: Logo 1, Logo 2, "presents" → present to screen.
* [ref: src/engine/broderbund_scene.s]
        jsr     broderbund_scene

* 160-frame hold: scene visible on screen.
* [ref: Apple II outer_caller_b77c stub_b823 — 160-frame static display hold]
        lda     #160
        jsr     HAL_time_delay

* Scene clear: blank the back buffer and present.
        jsr     HAL_gfx_clear
        jsr     HAL_gfx_present

* 80-frame transition: blank screen.
        lda     #80
        jsr     HAL_time_delay

* Halt. R-p24 (intro.s scene-1 path) will replace this with scene-2 hand-off.
* [ref: docs/project-state.md — R-p24 next INT-1 blocker after R-boot]
boot_halt:
        bra     boot_halt
* NOTE: exec address set by `end boot` in last assembled file (src/hal/coco3-dsk/mem.s)
