* tests/scripted/princess_gate1_driver.s
*
* SCENE-5 1b GATE 1 — princess walk-in DRIVES THE REAL SCENE CLOCK.
* Exercises the REAL controller (src/engine/princess_controller.s) + REAL engine
* + HAL by include. Boot-excluded (built only by run_princess_gate1.sh).
*
* THE PROOF (HS-1/AC-0/AC-2): her leg-cycle advances the scene clock (the oracle
* $3B analog) at the oracle walk cadence, NOT a free-run/stand-in:
*   STAND ($1DD7, 383 VBL, clock=$15) -> WALK: each completed 4-leg cycle (52 VBL)
*   advances the clock +1 ($16..$22). Clock capped at $22 (phase-1 end; the
*   $3B=$04 transition is GATE 2).
* NOTE: the oracle's $3B is the CoCo3 port's eng_fillval ($3B) — so the scene
*   clock lives at a free ZP ($42), the port's $3B-analog. Driven here by her walk.
* Gate 1 = walk-in only (throne stage layered next milestone); no transition/
*   collapse/BOW (fullseq cleared -> walk-loop).
* ---------------------------------------------------------------

        org     $0100
        rti
        nop
        nop
        rti
        nop
        nop
        rti
        nop
        nop
        rti
        nop
        nop
        rti                             ; $010C IRQ (patched -> hal_vbl_handler)
        nop
        nop
        rti
        nop
        nop

        org     $0200
        setdp   0

        include "../../src/engine/globals.s"

FB_A_LO         equ $8000
FB_A_HI         equ $BC00
FB_B_LO         equ $C000
FB_B_HI         equ $FC00

scene_clk       equ $42         ; the port's $3B-analog (scene clock) — driven by her walk
g1_prevleg      equ $3C         ; pr_leg before pr_tick (leg-wrap detect)
g1_prevstate    equ $3D         ; pr_state before pr_tick

CLK_PHASE1_START equ $15        ; throne phase-1 start (stand)
CLK_PHASE1_END  equ $22         ; phase-1 end (transition boundary = GATE 2)
G1_STAND_VBL    equ 383         ; oracle pre-walk stand (replaces demo PR_STAND_HOLD)

test_start:
        orcc    #$50
        lds     #$01FF
        clra
        tfr     a,dp

        jsr     HAL_sys_init
        jsr     HAL_time_init
        lda     #$00
        jsr     HAL_gfx_init
        jsr     HAL_input_init

        lda     #PAGE_A_TOKEN
        sta     <page_register
        andcc   #$EF

        ; scene clock starts at phase-1 ($15); her walk drives it to $22.
        lda     #CLK_PHASE1_START
        sta     <scene_clk

        ; STAND ($1DD7) then WALK. Override the demo stand with the oracle 383;
        ; clear fullseq so WALK loops (Gate 1 = walk-only, no BOW/turn).
        lda     #STATE_STAND
        jsr     pr_set_state
        clr     <pr_fullseq
        ldd     #G1_STAND_VBL
        std     <pr_holdctr

gate1_loop:
        jsr     HAL_time_vbl_wait
        lda     <pr_leg
        sta     <g1_prevleg
        lda     <pr_state
        sta     <g1_prevstate
        jsr     pr_tick
        ; --- drive the scene clock: a completed WALK leg-cycle (leg 3->0) = +1 ---
        lda     <g1_prevstate
        bne     gl_next                 ; only during WALK (state 0)
        lda     <g1_prevleg
        cmpa    #3
        bne     gl_next
        tst     <pr_leg                 ; wrapped to 0?
        bne     gl_next
        lda     <scene_clk
        cmpa    #CLK_PHASE1_END
        bhs     gl_next                 ; cap at $22 (phase-1 end -> GATE 2)
        inca
        sta     <scene_clk
gl_next:
        bra     gate1_loop

* --- REAL engine + controller + HAL (single source, by include) ---
        include "../../src/engine/sprite_engine.s"
        include "../../src/engine/princess_controller.s"
        include "../../src/hal/coco3-dsk/sys.s"
        include "../../src/hal/coco3-dsk/irq_vbl.s"
        include "../../src/hal/coco3-dsk/gfx.s"
        include "../../src/hal/coco3-dsk/time.s"
        include "../../src/hal/coco3-dsk/input.s"

* --- princess content ---
        include "../../content/princess/fig_1D36/converted.s"
        include "../../content/princess/fig_1D5A/converted.s"
        include "../../content/princess/fig_1D7E/converted.s"
        include "../../content/princess/fig_1DA2/converted.s"
        include "../../content/princess/fig_1D00/converted.s"
        include "../../content/princess/fig_1CD4/converted.s"
        include "../../content/princess/fig_1CC4/converted.s"
        include "../../content/princess/fig_1530/converted.s"
        include "../../content/princess/fig_1588/converted.s"
        include "../../content/princess/fig_1611/converted.s"
        include "../../content/princess/fig_169A/converted.s"
        include "../../content/princess/fig_16CC/converted.s"
        include "../../content/princess/fig_175E/converted.s"
        include "../../content/princess/fig_17D3/converted.s"
        include "../../content/princess/fig_1829/converted.s"
        include "../../content/princess/fig_1DD7/converted.s"
        include "../../content/princess/fig_1867/converted.s"

        end     test_start
