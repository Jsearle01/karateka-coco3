* tests/scripted/scene5_e2e_driver.s
*
* SCENE-5 END-TO-END ASSEMBLY — the continuous run. ONE scene_clk timeline:
*   throne (guard + Akuma + princess + eagle, all 4) $15->$22
*     -> TRANSITION at $22 ($3B reset to $04): draw_cell_stage full-clears the
*        screen -> the throne backdrop + STATIC actors (guard, Akuma body, eagle
*        body) are DROPPED; g2_phase->1 stops the per-frame throne draws (HS-1).
*   -> SOLO CELL (princess only) walk-in $04->$0D
*   -> COLLAPSE (door + BOW -> TURN(173) -> 169A(173) -> FALL) -> HALT.
*
* ASSEMBLY of proven pieces (HS-3, no rebuild): the gate-2 scaffold
* (princess_gate2_driver.s: transition + cell + collapse, oracle holds) + the
* 4-actor throne composite (scene5_akuma.s + scene5_composite.s, Jay-gated). The
* novel work is the transition HAND-OFF: pr_post_overlay is g2_phase-gated so the
* throne actors are dropped clean at $3B=$04 (no leak into the solo cell).
*
* ORACLE timing (HS-2): STAND 383, TURN/facing 173/173, BOW 9, oracle PR_CAD=13
* (NOT the demo throne overrides). Boot-excluded; prod unchanged (HS-5).
* ---------------------------------------------------------------

* --- controller placement (cell floor lands on the throne 5th line too) ---
PR_TORSO_ROW    equ 119
PR_BASEROW      equ 145
PR_SHADOW_ROW   equ 161
* --- pacing (Jay gate: oracle was too slow / start too far left — use the gated
*     throne-demo feel). 2px/leg is preserved (no slide); only the TIME is faster. ---
PR_CAD          equ 7           ; demo walk cadence (engine oracle default = 13)
PR_PXDEN        equ 7           ; glide 2/7 px/VBL so 2/7 * PR_CAD(7) = 2px/leg (no slide)
PR_STARTPX      equ 140         ; centred start (Jay-gated throne value; oracle was 80 = too far left)
PR_ENDPX        equ 252         ; 140 + 13cyc*8px = 244 at $22 — no wrap before the transition
PR_THRONE_RESTORE equ 1         ; clean-buffer restore + post-overlay hook
* collapse holds — Jay gate: speed the cell/collapse the same as the throne (~2x).
* Oracle was 173/173/9 (HS-2); halved for watchability (deliberate, documented).
PR_TURN0_HOLD   equ 87          ; $39=8  (1530) facing — oracle 173f, ~2x
PR_TF_DELAY     equ 87          ; $39=0C (169A) facing-left — oracle 173f, ~2x
PR_BOW_HOLD     equ 9           ; $39=13 (1867) bow — oracle ~9f (already short)
PR_FLOOR_HOLD   equ 32000       ; HALT collapsed for the gate window
* turn/collapse poses on the CELL floor (+85, matching the walk Y)
PR_POSE_TOP     equ 119
PR_FLOOR_ROW    equ 163
PR_POSE_ROW     equ 113

* SCENE5_STANDALONE (lwasm -D) = the sandbox build (own boot + HAL + globals).
* PROD boot include has none of that (boot.s owns it) — only scene5_run + the arc.
    ifdef SCENE5_STANDALONE
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
    endc

scene_clk       equ $42                 ; canonical $3B-analog (princess writes, Akuma reads)
g1_prevleg      equ $3C
g1_prevstate    equ $3D
g2_phase        equ $3E                 ; 0 = throne, 1 = cell
thr_off         equ $40                 ; pr_copy_from_clean 16-bit offset ($40/$41)

CLK_THRONE_START equ $15
CLK_THRONE_END  equ $22                 ; throne end -> transition (reset to $04)
CLK_CELL_START  equ $04
CLK_CELL_TRIG   equ $0D                 ; cell: collapse fires at $3B>=$0D AND walk-complete
CELL_ENTRY_PX   equ 36                  ; cell: she re-enters in the doorway, walks inward
G2_STAND_VBL    equ 60                  ; short pre-walk stand (Jay: oracle 383 too slow to watch)
* CLEAN_BUF/FLIP_BUF relocated BELOW the framebuffers ($8000) so scene 5 coexists
* with the PROD boot image (code grew to ~$483A; the old $4000/$4400 scratch
* collided with it). CLEAN holds rows 0-167 (13440 B; max restore row = 166 =
* PR_POSE_ROW 113 + PR_POSE_H 54). FLIP_BUF at $7E80 (biggest mirrored sprite 327 B).
CLEAN_BUF       equ $4A00               ; clean backdrop snapshot (rows 0-167, ends $7E80)

    ifdef SCENE5_STANDALONE
test_start:                             ; sandbox entry: boot + HAL init, then the arc
        orcc    #$50
        lds     #$01FF
        clra
        tfr     a,dp

        jsr     HAL_sys_init
        jsr     HAL_time_init
        lda     #$00
        jsr     HAL_gfx_init
        jsr     HAL_input_init
        jmp     scene5_run
    endc

* scene5_run — the callable scene-5 arc (PROD entry: boot.s jsr's here at the
*   scene-4->scene-5 seam, HAL already inited). Never returns (halts collapsed).
*   draw_throne_stage self-clears both buffers, so the seam needs no extra clear.
scene5_run:
        lda     #PAGE_A_TOKEN
        sta     <page_register
        andcc   #$EF

        ; Akuma one-shot arm init (draw_throne_stage doesn't touch $52-$55).
        clr     <akuma_arm_idx
        clr     <akuma_arm_done
        clr     <akuma_clr_ctr
        lda     #AKUMA_ARM_CAD
        sta     <akuma_arm_ctr

        ; --- buffer A: throne + guard + eagle-body -> snapshot CLEAN -> full Akuma ---
        jsr     HAL_time_vbl_wait
        jsr     draw_throne_stage       ; NOTE: writes sc_mir ($42) = scene_clk
        jsr     draw_scene5_guard       ; STATIC guard (left doorway)
        jsr     draw_scene5_eagle_body  ; STATIC eagle body (Akuma's left shoulder)
        jsr     g2_snapshot_clean       ; CLEAN = throne + guard + eagle-body (static backdrop)
        lda     #CLK_THRONE_START       ; set scene_clk AFTER draw_throne_stage
        sta     <scene_clk
        clr     <g2_phase               ; throne
        jsr     draw_akuma_full         ; A += full Akuma over the static backdrop
        jsr     HAL_gfx_present
        lda     <page_register
        eora    #$60
        sta     <page_register
        ; --- buffer B: throne + guard + eagle-body + full Akuma ---
        jsr     HAL_time_vbl_wait
        jsr     draw_throne_stage
        jsr     draw_scene5_guard
        jsr     draw_scene5_eagle_body
        lda     #CLK_THRONE_START       ; re-set (throne render clobbered $42)
        sta     <scene_clk
        jsr     draw_akuma_full
        jsr     HAL_gfx_present
        lda     <page_register
        eora    #$60
        sta     <page_register

        ; --- init the princess STAND inline (no pr_clear_both: preserve backdrop) ---
        lda     #STATE_STAND
        sta     <pr_state
        lda     #4
        sta     <pr_seqlen
        lda     #4
        sta     <pr_leg
        clr     <pr_frac
        clr     <pr_fullseq             ; driver-triggered collapse (not the walk->bow chain)
        ldd     #G2_STAND_VBL
        std     <pr_holdctr
        lda     #PR_CAD
        sta     <pr_cadrel
        sta     <pr_cadctr
        clr     <pr_shadow_lead
        lda     #PR_STARTPX
        sta     <pr_px
        jsr     pr_render_walk          ; frame 0

e2e_loop:
        jsr     HAL_time_vbl_wait
        lda     <pr_leg
        sta     <g1_prevleg
        lda     <pr_state
        sta     <g1_prevstate
        jsr     pr_tick                 ; princess step (draws her + composite via hook + flip)
        ; --- ambient arm: THRONE phase only ---
        lda     <g2_phase
        bne     e2e_clkchk
        jsr     akuma_ctrl_tick
e2e_clkchk:
        ; --- drive scene_clk on a completed WALK leg-cycle (leg 3->0) ---
        lda     <g1_prevstate
        bne     e2e_next                ; only during WALK
        lda     <g1_prevleg
        cmpa    #3
        bne     e2e_next
        tst     <pr_leg                 ; wrapped to 0?
        bne     e2e_next
        lda     <g2_phase
        bne     e2e_cell
* --- THRONE phase: clock $15->$22, then TRANSITION ---
        lda     <scene_clk
        cmpa    #CLK_THRONE_END
        bhs     e2e_next                ; capped
        inca
        sta     <scene_clk
        cmpa    #CLK_THRONE_END
        bne     e2e_next                ; reached $22?
        jsr     do_transition
        bra     e2e_next
* --- CELL phase: clock $04->$0D, then COLLAPSE ---
e2e_cell:
        lda     <scene_clk
        cmpa    #CLK_CELL_TRIG
        bhs     e2e_next                ; already collapsing/halted
        inca
        sta     <scene_clk
        cmpa    #CLK_CELL_TRIG
        bne     e2e_next                ; reached $0D (+ walk-complete)?
        jsr     g2_do_collapse          ; door + BOW->TURN->FALL->halt
e2e_next:
        bra     e2e_loop

* ===============================================================
* do_transition — throne->cell at $22 ($3B reset to $04). draw_cell_stage
*   full-clears the screen -> the throne backdrop + STATIC actors (guard/Akuma
*   body/eagle body) are dropped. g2_phase->1 then stops the per-frame throne
*   draws in pr_post_overlay (HS-1: no throne-actor leak into the solo cell).
*   Princess controller state ($43-$4F) is preserved so her walk is continuous.
* ===============================================================
do_transition:
        ldx     #$43                    ; save princess state (13 bytes)
        ldy     #g2_save
        ldb     #13
dt_save:
        lda     ,x+
        sta     ,y+
        decb
        bne     dt_save
        jsr     HAL_time_vbl_wait
        jsr     draw_cell_stage         ; full-clear + cell backdrop (buffer A)
        jsr     HAL_gfx_present
        lda     <page_register
        eora    #$60
        sta     <page_register
        jsr     HAL_time_vbl_wait
        jsr     draw_cell_stage         ; buffer B
        jsr     HAL_gfx_present
        lda     <page_register
        eora    #$60
        sta     <page_register
        jsr     g2_snapshot_clean       ; CLEAN = the CELL backdrop now (no throne actors)
        ldx     #g2_save                ; restore princess state
        ldy     #$43
        ldb     #13
dt_rest:
        lda     ,x+
        sta     ,y+
        decb
        bne     dt_rest
        lda     #1
        sta     <g2_phase               ; -> cell (stops throne draws)
        lda     #CLK_CELL_START
        sta     <scene_clk              ; $3B reset $22 -> $04
        lda     #CELL_ENTRY_PX          ; she re-enters at the doorway (walk cycle continuous)
        sta     <pr_px
        rts

* g2_do_collapse — clock $0D + walk-complete: door appears + collapse chain fires.
g2_do_collapse:
        ldx     #$43
        ldy     #g2_save
        ldb     #13
dc_save:
        lda     ,x+
        sta     ,y+
        decb
        bne     dc_save
        ; Draw the DOOR SPRITE ONLY (no draw_cell_stage full-clear) over both
        ; buffers, so the princess stays visible — full-clearing wiped her, and the
        ; presented cell+door frames flashed her off. CLEAN stays = cell (she
        ; collapses ~byte27; the left-doorway door ~byte9 is outside her dirty rect,
        ; so it never gets restored-away and needn't be in CLEAN). Present/flip stay
        ; paired (un-paired flip/present desyncs page_register from the display).
        jsr     HAL_time_vbl_wait
        ldu     #cell_door_tbl
        jsr     draw_setdressing
        jsr     HAL_gfx_present
        lda     <page_register
        eora    #$60
        sta     <page_register
        jsr     HAL_time_vbl_wait
        ldu     #cell_door_tbl
        jsr     draw_setdressing
        jsr     HAL_gfx_present
        lda     <page_register
        eora    #$60
        sta     <page_register
        ldx     #g2_save
        ldy     #$43
        ldb     #13
dc_rest:
        lda     ,x+
        sta     ,y+
        decb
        bne     dc_rest
        lda     #STATE_BOW              ; kick the collapse chain (BOW first)
        sta     <pr_state
        ldd     #PR_BOW_HOLD
        std     <pr_holdctr
        clr     <pr_shadow_lead
        rts

g2_save:        rmb     16              ; saved princess state across a stage switch

* g2_snapshot_clean — buffer A ($8000) -> CLEAN_BUF (rows 0-167 = 13440 B,
*   $8000..$B480). Only the actor band (max restore row 166) is needed; the tail
*   rows 168-191 are never restored, so trimming them lets CLEAN fit below $8000.
g2_snapshot_clean:
        ldx     #$8000
        ldy     #CLEAN_BUF
g2sc_loop:
        ldd     ,x++
        std     ,y++
        cmpx    #$B480
        blo     g2sc_loop
        rts

* ===============================================================
* pr_post_overlay — the princess's post-draw hook (after she is drawn, before the
*   flip). THE TRANSITION HAND-OFF (HS-1): throne phase draws the 4-actor
*   composite OVER her; cell phase draws princess-only (+ doorway-post-over-shadow)
*   so no throne actor leaks into the solo cell.
* ===============================================================
pr_post_overlay:
        lda     <g2_phase
        bne     ppo_cell
* --- THRONE: doorway post + Akuma (fig_974B stencil occlusion) + eagle, over her ---
        jsr     restore_right_doorway
        jsr     punch_akuma_stencil
        jsr     draw_akuma_full
        jsr     draw_scene5_eagle_body
        jsr     draw_scene5_eagle_head
        rts
* --- CELL: princess-only. Re-lay the cell doorway post over her leading shadow. ---
ppo_cell:
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
POST_OUTER      equ 68
SHADOW_R0       equ 161

* restore_right_doorway — throne: re-lay the right-doorway post (CLEAN bytes 68-69,
*   rows 160-163) OVER her leading shadow (the dirty-rect restore runs before the
*   shadow). A no-op when the shadow isn't there. (Same as the gated throne demo.)
restore_right_doorway:
        lda     #61
        sta     <eng_col
        lda     #160
        sta     <eng_row
        lda     #12
        sta     <eng_clrw
        lda     #4
        sta     <eng_clrh
        jmp     pr_copy_from_clean

* --- pr_throne_restore (princess dirty-rect restore) — copy her rect from CLEAN_BUF ---
pr_throne_restore:
        bra     pr_copy_from_clean
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

* --- engine + controller (prod lacks these — always included here) ---
        include "../../src/engine/sprite_engine.s"
        include "../../src/engine/princess_controller.s"
* --- HAL: sandbox only (prod already links it) ---
    ifdef SCENE5_STANDALONE
        include "../../src/hal/coco3-dsk/sys.s"
        include "../../src/hal/coco3-dsk/irq_vbl.s"
        include "../../src/hal/coco3-dsk/gfx.s"
        include "../../src/hal/coco3-dsk/time.s"
        include "../../src/hal/coco3-dsk/input.s"
    endc

* --- throne stage (shared draw_setdressing/make_flipped/ZP) THEN the actors THEN cell ---
        include "scene5_throne_stage.s"
        include "scene5_akuma.s"
        include "scene5_composite.s"    ; guard + eagle
        include "scene5_cell_stage.s"   ; the cell backdrop (reuses throne helpers)

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

    ifdef SCENE5_STANDALONE
        end     test_start
    endc
