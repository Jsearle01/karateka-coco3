* src/engine/princess_controller.s
*
* PRINCESS CONTROLLER — CoCo3 port of the oracle scene-5 princess walk-in
* (display_7700.s: advance_princess_anim $7F33 + draw_princess + the
* tbl_princess_* table). Her OWN controller, driving the ONE shared render
* leaf (HAL_gfx_blit_sprite) — multi-animator model, NOT a second render path.
*
* ORACLE BASIS (pre-flight confirmed, docs/project/reports 2026-06-14):
*  - CADENCE (GATE 1): advance_princess_anim cycles $39 1->4 (the 4 walk legs)
*    and on each completed cycle steps her position. The oracle's $3A mod-7 +
*    extra-$3B is Apple-II 7px/byte sub-byte bookkeeping for a UNIFORM
*    8-Apple-px/cycle advance. $10(:=$3A) is the blit's sub-byte pixel index
*    (0-6, video.s L1A84 7-case shift) — a byte-packing ARTIFACT. The converter
*    is 1:1 px and CoCo3 is 4px/byte, so 8 Apple-px = exactly 2 CoCo3
*    byte-cols: the port is a clean +2 byte-cols/cycle, subbyte stays 0. No
*    mod-7, no fixed-point fraction (GATE-1 native-integer branch).
*  - COMPOSITE (draw_princess): each rendered princess = body $1D00 (idx5) +
*    part $1CD4 (idx6) + leg $39 (idx1-4) + part $1CC4 (idx7). Vertical stack
*    from tbl_princess_y (Apple rows, ~1:1 CoCo3): body/part6 at +0, leg at
*    +26 ($3E-$24), part7 at +41 ($4D-$24). X all ~= her column (tbl_x[2..7]=0).
*  - DIRTY-RECT (GATE 2): draw_princess_bg = render_pass_a single-colour band
*    behind her ([$3B-1..$3B+4] x rows $77-$A3). CoCo3: reuse eng_clear_box
*    (the existing region-fill primitive) over her moving band each frame.
*  - $3B-analog (pr_x) FREE-RUNS in the sandbox (no $0D fall check — the fall
*    is the scene $3B clock, pass one). We WRAP pr_x so the walk-in re-enters
*    for the live gate (AC-7: isolated walk-in, no fall).
*
* [ref: src/engine/sprite_engine.s eng_clear_box / eng_render]
* [ref: src/hal/coco3-dsk/gfx.s HAL_gfx_blit_sprite / HAL_gfx_present]
* ---------------------------------------------------------------

        setdp   0

* --- princess controller state (ZP $43-$45; $40/$42 are the sandbox's) ---
pr_leg          equ $43         ; current leg index 0..3 (oracle $39 1..4)
pr_x            equ $44         ; byte column (oracle $3B-analog; +2/cycle)
pr_cadctr       equ $45         ; cadence down-counter

* --- tunable layout constants (AC-5 live-gate tunes the composite) ---
PR_CAD          equ 8           ; VBLs per leg frame (walk pace within a cycle)
PR_STARTX       equ 2           ; left start byte-col
PR_ENDX         equ 64          ; wrap point (re-enter from left) — isolated demo
PR_STEP         equ 2           ; +2 byte-cols/cycle = 8px (GATE-1 native integer)
PR_BASEROW      equ 60          ; top row of the composite (body/part6)
PR_DY_LEG       equ 26          ; leg row offset  ($3E-$24)
PR_DY_PART7     equ 41          ; part7 row offset ($4D-$24)
PR_CLR_LEFT     equ 4           ; dirty-rect margin left of pr_x (covers vacated)
PR_CLR_W        equ 18          ; dirty-rect width (max part 13 + movement margin)
PR_CLR_H        equ 46          ; dirty-rect height (full composite + margin)

* ===============================================================
* pr_init — initialise the walk-in controller + render frame 0.
* ===============================================================
pr_init:
        clr     <pr_leg
        lda     #PR_STARTX
        sta     <pr_x
        lda     #PR_CAD
        sta     <pr_cadctr
        jsr     pr_render
        rts

* ===============================================================
* pr_tick — per-VBL tick. Cadence down-counter; on expiry advance the leg
*   (0->1->2->3->wrap). On a completed cycle (leg wraps to 0) step pr_x by
*   PR_STEP (the oracle per-cycle position advance). Then render.
* ===============================================================
pr_tick:
        dec     <pr_cadctr
        beq     pr_tick_adv
        rts
pr_tick_adv:
        lda     #PR_CAD
        sta     <pr_cadctr
        ; advance leg index, wrap 4->0
        lda     <pr_leg
        inca
        cmpa    #4
        blo     pr_tick_store
        clra                            ; completed 4-frame cycle -> wrap
        ; --- per-cycle position step (GATE-1: +2 byte-cols) ---
        ldb     <pr_x
        addb    #PR_STEP
        cmpb    #PR_ENDX
        blo     pr_tick_setx
        ldb     #PR_STARTX              ; wrap: re-enter from left ($3B free-runs)
pr_tick_setx:
        stb     <pr_x
pr_tick_store:
        sta     <pr_leg
        jsr     pr_render
        rts

* ===============================================================
* pr_render — dirty-rect clear behind/around her, composite the 4 sprites
*   (body + part6 + leg + part7) via the shared leaf, then present + flip.
* ===============================================================
pr_render:
        ; (1) dirty-rect: clear a band at (pr_x - PR_CLR_LEFT, PR_BASEROW)
        lda     <pr_x
        suba    #PR_CLR_LEFT
        bcc     pr_clr_x_ok
        clra                            ; clamp to col 0
pr_clr_x_ok:
        sta     <eng_col
        lda     #PR_BASEROW
        sta     <eng_row
        lda     #PR_CLR_W
        sta     <eng_clrw
        lda     #PR_CLR_H
        sta     <eng_clrh
        jsr     eng_clear_box

        ; (2) composite blits (shared leaf). subbyte=0 (native-integer X).
        clr     <blit_subbyte
        ; body $1D00 (idx5) at (pr_x, PR_BASEROW)
        ldx     #fig_1D00_coco3
        lda     <pr_x
        ldb     #PR_BASEROW
        jsr     HAL_gfx_blit_sprite
        ; part6 $1CD4 (idx6) at (pr_x, PR_BASEROW)
        ldx     #fig_1CD4_coco3
        lda     <pr_x
        ldb     #PR_BASEROW
        jsr     HAL_gfx_blit_sprite
        ; leg (idx1-4) at (pr_x, PR_BASEROW + PR_DY_LEG)
        jsr     pr_leg_ptr              ; X = leg sprite ptr for pr_leg
        lda     <pr_x
        ldb     #PR_BASEROW+PR_DY_LEG
        jsr     HAL_gfx_blit_sprite
        ; part7 $1CC4 (idx7) at (pr_x, PR_BASEROW + PR_DY_PART7)
        ldx     #fig_1CC4_coco3
        lda     <pr_x
        ldb     #PR_BASEROW+PR_DY_PART7
        jsr     HAL_gfx_blit_sprite

        ; (3) reveal + flip (Option-I double buffer)
        jsr     HAL_gfx_present
        lda     <page_register
        eora    #$60                    ; $20<->$40
        sta     <page_register
        rts

* ---------------------------------------------------------------
* pr_leg_ptr — X = walk-leg sprite ptr for the current pr_leg (0..3).
* ---------------------------------------------------------------
pr_leg_ptr:
        lda     <pr_leg
        lsla                            ; *2 (fdb table entries)
        ldx     #pr_leg_tbl
        leax    a,x                     ; X = pr_leg_tbl + pr_leg*2
        ldx     ,x                      ; X = leg sprite ptr
        rts

pr_leg_tbl:
        fdb     fig_1D36_coco3          ; leg 0  ($39=1)
        fdb     fig_1D5A_coco3          ; leg 1  ($39=2)
        fdb     fig_1D7E_coco3          ; leg 2  ($39=3)
        fdb     fig_1DA2_coco3          ; leg 3  ($39=4)
