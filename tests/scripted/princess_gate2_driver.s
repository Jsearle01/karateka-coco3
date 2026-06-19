* tests/scripted/princess_gate2_driver.s
*
* SCENE-5 1b GATE 2 — the princess arc back half: throne->cell TRANSITION +
* (Milestone B) door-triggered turn + collapse, driving the real scene clock.
* Builds on Gate 1's proven driver model + clean-buffer composite (e4cfc19).
* Boot-excluded (built only by run_princess_gate2.sh).
*
* ORACLE (trace cell_arc.log, apple2e):
*   throne walk $3B $15->$22 (13 cyc) -> at $22 RESET to $04 = TRANSITION (f4905),
*   $39 (walk pose) CONTINUOUS across it -> cell walk-in $3B $04->$0D (cadence ~10f)
*   -> at $3B>=$0D AND $39==1 (walk-complete, f5222): the turn fires. f5226 $39=$13
*   (bow, dwell ~9), f5235 $39=8 (TURN) + $84=5 (DOOR) — co-triggered siblings, NOT
*   door->turn. HOLDS: $39=8 (1530) 173f; $39=$0C (169A facing-left) 173f; cadence 11f.
*
* MILESTONE A (this commit step): the transition + cell walk-in + CONTINUITY (P3).
*   She walks (throne), the backdrop switches to the cell at clock $22->$04 with
*   her walk state PRESERVED (no reset), she finishes walking in, STOPS at the
*   $0D trigger. Door + turn + collapse = Milestone B.
* ---------------------------------------------------------------

* --- controller placement overrides (BEFORE the include) — cell floor (the
* throne 5th line, row 161, also lands within the cell floor strip rows159-168) ---
PR_TORSO_ROW    equ 119
PR_BASEROW      equ 145
PR_SHADOW_ROW   equ 161
PR_STARTPX      equ 80          ; throne start (as Gate 1) — walks $15->$22 (~px184)
PR_ENDPX        equ 240         ; no walk-loop wrap before the arc completes
PR_THRONE_RESTORE equ 1         ; clean-buffer restore + post-overlay (Gate 1)
* oracle collapse holds (HS-1) — swap the controller's demo PR_*_HOLD
PR_TURN0_HOLD   equ 173         ; $39=8  (1530) facing — oracle 173f
PR_TF_DELAY     equ 173         ; $39=0C (169A) facing-left — oracle 173f
PR_BOW_HOLD     equ 9           ; $39=13 (1867) bow — oracle ~9f
PR_FLOOR_HOLD   equ 32000       ; HALT collapsed (no demo loop) for the gate window
* turn/collapse poses on the CELL floor (+85, matching the walk Y)
PR_POSE_TOP     equ 119         ; 34 + 85 (TURN top-align)
PR_FLOOR_ROW    equ 163         ; 78 + 85 (FALL bottom-align ref = feet on cell floor)
PR_POSE_ROW     equ 113         ; 28 + 85 (pose dirty-rect top)

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

scene_clk       equ $42         ; the port's $3B-analog (scene clock) — driven by her walk
g1_prevleg      equ $3C
g1_prevstate    equ $3D
thr_off         equ $40         ; pr_throne_restore: 16-bit copy offset ($40/$41)
g2_phase        equ $3E         ; 0 = throne, 1 = cell  (NOT $41 — that is thr_off hi)

CLK_THRONE_START equ $15
CLK_THRONE_END  equ $22         ; throne phase end -> transition (reset to $04)
CLK_CELL_START  equ $04
CLK_CELL_TRIG   equ $0D         ; cell: turn fires at $3B>=$0D AND walk-complete
CELL_ENTRY_PX   equ 36          ; cell: she re-enters IN the doorway opening (~byte9,
                                ; where the door appears) and walks THROUGH it inward
G2_STAND_VBL    equ 383         ; oracle pre-walk stand
CLEAN_BUF       equ $4400       ; clean backdrop snapshot (re-taken at the transition)

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

        ; --- render the THRONE stage to both buffers + snapshot clean ---
        jsr     HAL_time_vbl_wait
        jsr     draw_throne_stage
        jsr     HAL_gfx_present
        lda     <page_register
        eora    #$60
        sta     <page_register
        jsr     HAL_time_vbl_wait
        jsr     draw_throne_stage
        jsr     HAL_gfx_present
        lda     <page_register
        eora    #$60
        sta     <page_register
        jsr     g2_snapshot_clean

        ; clock + phase (set AFTER the stage render — sc_mir aliases $42)
        lda     #CLK_THRONE_START
        sta     <scene_clk
        clr     <g2_phase               ; throne

        ; --- init the princess STAND inline (no pr_clear_both: preserve backdrop) ---
        lda     #STATE_STAND
        sta     <pr_state
        lda     #4
        sta     <pr_seqlen
        lda     #4
        sta     <pr_leg
        clr     <pr_frac
        clr     <pr_fullseq
        ldd     #G2_STAND_VBL
        std     <pr_holdctr
        lda     #PR_CAD
        sta     <pr_cadrel
        sta     <pr_cadctr
        clr     <pr_shadow_lead
        lda     #PR_STARTPX
        sta     <pr_px
        jsr     pr_render_walk          ; frame 0

gate2_loop:
        jsr     HAL_time_vbl_wait
        lda     <pr_leg
        sta     <g1_prevleg
        lda     <pr_state
        sta     <g1_prevstate
        jsr     pr_tick
        ; --- a completed WALK leg-cycle (leg 3->0) advances the scene clock ---
        lda     <g1_prevstate
        bne     g2_next                 ; only during WALK
        lda     <g1_prevleg
        cmpa    #3
        bne     g2_next
        tst     <pr_leg                 ; wrapped to 0?
        bne     g2_next
        lda     <g2_phase
        bne     g2_cell
* --- THRONE phase: clock $15->$22, then TRANSITION ---
        lda     <scene_clk
        cmpa    #CLK_THRONE_END
        bhs     g2_next                 ; capped
        inca
        sta     <scene_clk
        cmpa    #CLK_THRONE_END
        bne     g2_next                 ; reached $22?
        jsr     do_transition
        bra     g2_next
* --- CELL phase: clock $04->$0D, then STOP (Milestone A) ---
g2_cell:
        lda     <scene_clk
        cmpa    #CLK_CELL_TRIG
        bhs     g2_next                 ; already stopped
        inca
        sta     <scene_clk
        cmpa    #CLK_CELL_TRIG
        bne     g2_next                 ; reached $0D (+ walk-complete)?
        jsr     g2_do_collapse          ; door appears + turn/bow/collapse fire (co-trigger)
g2_next:
        bra     gate2_loop

* ===============================================================
* do_transition — throne->cell at clock $22 (=$3B reset to $04). Switch the
*   backdrop to the cell on BOTH buffers + re-snapshot the clean buffer, while
*   PRESERVING the princess controller state ($43-$4F) so her walk is continuous
*   (HS-3: no reset/jump). The cell render clobbers $40-$4F (shared stage scratch)
*   — save/restore $43-$4F around it; set scene_clk/g2_phase AFTER.
* ===============================================================
do_transition:
        ; save princess controller state ($43-$4F = 13 bytes)
        ldx     #$43
        ldy     #g2_save
        ldb     #13
dt_save:
        lda     ,x+
        sta     ,y+
        decb
        bne     dt_save
        ; render the CELL stage to both buffers
        jsr     HAL_time_vbl_wait
        jsr     draw_cell_stage
        jsr     HAL_gfx_present
        lda     <page_register
        eora    #$60
        sta     <page_register
        jsr     HAL_time_vbl_wait
        jsr     draw_cell_stage
        jsr     HAL_gfx_present
        lda     <page_register
        eora    #$60
        sta     <page_register
        jsr     g2_snapshot_clean       ; clean = the CELL backdrop now
        ; restore princess state
        ldx     #g2_save
        ldy     #$43
        ldb     #13
dt_rest:
        lda     ,x+
        sta     ,y+
        decb
        bne     dt_rest
        lda     #1
        sta     <g2_phase               ; cell
        lda     #CLK_CELL_START
        sta     <scene_clk              ; $3B reset $22 -> $04
        ; she does NOT continue from her throne X — the scene CUTS to the cell
        ; and she RE-ENTERS at the doorway, walking in (Jay gate). Walk cycle
        ; (pr_leg/pr_frac) stays continuous; only her X resets.
        lda     #CELL_ENTRY_PX
        sta     <pr_px
        rts

* g2_snapshot_clean — snapshot buffer A ($8000) to CLEAN_BUF (the pristine
*   backdrop pr_throne_restore copies from). 15360 bytes ($8000..$BC00).
g2_snapshot_clean:
        ldx     #$8000
        ldy     #CLEAN_BUF
g2sc_loop:
        ldd     ,x++
        std     ,y++
        cmpx    #$BC00
        blo     g2sc_loop
        rts

* g2_do_collapse — clock $0D + walk-complete: the DOOR appears AND the turn fires
*   (co-trigger, GATE D2). (1) re-render the cell WITH the door to both buffers +
*   re-snapshot the clean buffer (so the restore preserves the door through the
*   collapse), preserving the princess walk state; (2) kick the controller chain
*   BOW -> TURN(173) -> 169A(173) -> FALL -> halt collapsed (PR_FLOOR_HOLD long).
g2_do_collapse:
        ; save princess state ($43-$4F)
        ldx     #$43
        ldy     #g2_save
        ldb     #13
dc_save:
        lda     ,x+
        sta     ,y+
        decb
        bne     dc_save
        ; render cell + DOOR to both buffers
        jsr     HAL_time_vbl_wait
        jsr     draw_cell_door
        jsr     HAL_gfx_present
        lda     <page_register
        eora    #$60
        sta     <page_register
        jsr     HAL_time_vbl_wait
        jsr     draw_cell_door
        jsr     HAL_gfx_present
        lda     <page_register
        eora    #$60
        sta     <page_register
        jsr     g2_snapshot_clean       ; clean = cell + door
        ; restore princess state
        ldx     #g2_save
        ldy     #$43
        ldb     #13
dc_rest:
        lda     ,x+
        sta     ,y+
        decb
        bne     dc_rest
        ; kick the collapse chain (BOW first, per the controller chain order)
        lda     #STATE_BOW
        sta     <pr_state
        ldd     #PR_BOW_HOLD
        std     <pr_holdctr
        clr     <pr_shadow_lead
        rts

g2_save:        rmb     16              ; saved princess state across the transition

* --- pr_throne_restore / pr_post_overlay (Gate 1, backdrop-agnostic clean copy) ---
pr_throne_restore:
        bra     pr_copy_from_clean
POST_OUTER      equ 68
SHADOW_R0       equ 161
pr_post_overlay:
        lda     <eng_col
        adda    <eng_clrw
        cmpa    #POST_OUTER
        blo     ppo_skip
        ldx     #$8000
        lda     <page_register
        cmpa    #PAGE_A_TOKEN
        beq     ppo_a
        ldx     #$C000
ppo_a:
        ldd     CLEAN_BUF+SHADOW_R0*80+POST_OUTER
        std     SHADOW_R0*80+POST_OUTER,x
        ldd     CLEAN_BUF+(SHADOW_R0+1)*80+POST_OUTER
        std     (SHADOW_R0+1)*80+POST_OUTER,x
ppo_skip:
        rts
pr_copy_from_clean:
        lda     #80
        ldb     <eng_row
        mul
        addb    <eng_col
        adca    #0
        std     <thr_off
        addd    #CLEAN_BUF
        tfr     d,u
        ldx     #$8000
        lda     <page_register
        cmpa    #PAGE_A_TOKEN
        beq     pcc_a
        ldx     #$C000
pcc_a:
        ldd     <thr_off
        leax    d,x
        tfr     x,y
        lda     <eng_clrh
pcc_row:
        pshs    a,y,u
        ldb     <eng_clrw
pcc_byte:
        lda     ,u+
        sta     ,y+
        decb
        bne     pcc_byte
        puls    a,y,u
        leay    80,y
        leau    80,u
        deca
        bne     pcc_row
        rts

* --- REAL engine + controller + HAL (single source, by include) ---
        include "../../src/engine/sprite_engine.s"
        include "../../src/engine/princess_controller.s"
        include "../../src/hal/coco3-dsk/sys.s"
        include "../../src/hal/coco3-dsk/irq_vbl.s"
        include "../../src/hal/coco3-dsk/gfx.s"
        include "../../src/hal/coco3-dsk/time.s"
        include "../../src/hal/coco3-dsk/input.s"

* --- the gated 1a throne stage (shared helpers: draw_setdressing/make_flipped/
*     rev2/ZP + floor_9600/96CE) THEN the cell stage (reuses them) ---
        include "scene5_throne_stage.s"
        include "scene5_cell_stage.s"

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
