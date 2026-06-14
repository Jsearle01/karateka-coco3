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
pr_x            equ $44         ; derived byte column (pr_px>>2) — traced
pr_cadctr       equ $45         ; cadence down-counter
pr_px           equ $46         ; PIXEL position (master)
pr_frac         equ $47         ; sub-pixel accumulator (PR_PXNUM/PR_PXDEN per VBL)
pr_tmp          equ $48         ; scratch (per-frame registration)

* --- tunable layout constants (AC-5 live-gate) ---
PR_CAD          equ 13          ; VBLs per leg frame — ORACLE-MEASURED (recon trace:
                                ; ~52 VBLs/walk-cycle / 4 legs = 13 VBLs/leg) — TUNABLE
PR_STARTPX      equ 8           ; left start, in pixels
PR_ENDPX        equ 240         ; wrap point (re-enter from left) — isolated demo
* position advances EVERY VBL by PR_PXNUM/PR_PXDEN px (decoupled from the leg
* cadence -> continuous glide). 2/13 px/VBL x (4*PR_CAD=52) VBLs/cycle = 8px/cycle.
* This is the oracle's MEASURED walk cadence (apple2e $3B-poll: +1 position byte
* /~52 VBLs, ~9px/sec) — 8px/cycle spatial gait at the oracle's wall-clock pace.
PR_PXNUM        equ 2
PR_PXDEN        equ 13
PR_BASEROW      equ 60          ; leg top row
PR_TORSO_ROW    equ 34          ; torso top row (= legs - 26, oracle body/leg y gap)
PR_TORSO_DX     equ 3           ; +px to align torso centroid (4.83) over leg (7.98)
PR_CLR_LEFT     equ 4           ; dirty-rect margin left of pr_x (covers vacated)
PR_CLR_W        equ 24          ; dirty-rect width (figure + leading shadow + margin)
PR_CLR_H        equ 46          ; dirty-rect height (torso row 34 .. leg bottom ~77)
* shadow ($1CC4) — all index-0 on Apple (black shadow on the colored floor); the
* transparency blit can't draw black, so render it as a solid bar leading her.
PR_SHADOW_ROW   equ 76          ; at her feet (leg bottom)
PR_SHADOW_LEADPX equ 12         ; pixels ahead = start at front of her toes — TUNABLE
PR_SHADOW_W     equ 13          ; $1CC4 width (bytes)
PR_SHADOW_H     equ 2           ; $1CC4 height
PR_FLOOR_FILL   equ $AA         ; sandbox floor = index-2 (blue); index-0 stays black (shadow)

* ===============================================================
* pr_init — initialise the walk-in controller + render frame 0.
* ===============================================================
pr_init:
        clr     <pr_leg
        clr     <pr_frac
        lda     #PR_STARTPX
        sta     <pr_px
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
        ; --- (a) smooth position: every VBL add PR_PXNUM/PR_PXDEN px ---
        lda     <pr_frac
        adda    #PR_PXNUM
        cmpa    #PR_PXDEN
        blo     pr_frac_store
        suba    #PR_PXDEN
        sta     <pr_frac
        ; carry one pixel (with wrap)
        lda     <pr_px
        inca
        cmpa    #PR_ENDPX
        blo     pr_px_store
        lda     #PR_STARTPX             ; wrap: re-enter from left
pr_px_store:
        sta     <pr_px
        bra     pr_leg_cad
pr_frac_store:
        sta     <pr_frac
        ; --- (b) leg cadence: advance leg every PR_CAD VBLs ---
pr_leg_cad:
        dec     <pr_cadctr
        bne     pr_tick_render
        lda     #PR_CAD
        sta     <pr_cadctr
        lda     <pr_leg
        inca
        cmpa    #4
        blo     pr_leg_store
        clra                            ; completed 4-frame cycle -> wrap
pr_leg_store:
        sta     <pr_leg
        ; --- (c) render EVERY VBL -> continuous motion ---
pr_tick_render:
        jsr     pr_render
        rts

* ===============================================================
* pr_render — dirty-rect clear behind/around her, composite the 4 sprites
*   (body + part6 + leg + part7) via the shared leaf, then present + flip.
* ===============================================================
pr_render:
        ; (1) dirty-rect: clear the torso+leg band. col = (pr_px>>2) - margin.
        lda     <pr_px
        lsra
        lsra
        suba    #PR_CLR_LEFT
        bcc     pr_clr_ok
        clra                            ; clamp to col 0
pr_clr_ok:
        sta     <eng_col
        lda     #PR_TORSO_ROW
        sta     <eng_row
        lda     #PR_CLR_W
        sta     <eng_clrw
        lda     #PR_CLR_H
        sta     <eng_clrh
        lda     #PR_FLOOR_FILL          ; dirty-rect RESTORES the floor (not black),
        sta     <eng_fillval            ; so the index-0 black shadow contrasts
        jsr     eng_clear_box

        ; (1b) SHADOW leading her (solid bar; $1CC4 is all index-0 black)
        jsr     pr_draw_shadow

        ; (2) TORSO $1D00 (waist+torso) at (pr_px + TORSO_DX, TORSO_ROW).
        ;     Centroid-aligned over the legs; one frame, moves smoothly w/ pr_px.
        lda     <pr_px
        adda    #PR_TORSO_DX
        jsr     pr_set_pos              ; A = byte col, blit_subbyte set
        ldb     #PR_TORSO_ROW
        ldx     #fig_1D00_coco3
        jsr     HAL_gfx_blit_sprite

        ; (3) LEG (idx pr_leg) at (pr_px + align[leg], BASEROW). Per-frame
        ;     registration [0,4,3,1] so the body stays put + only legs swing.
        ldx     #pr_leg_align
        lda     <pr_leg
        lda     a,x                     ; A = align[leg]
        adda    <pr_px
        jsr     pr_set_pos              ; A = byte col, blit_subbyte set
        sta     <pr_x                   ; (traced)
        ldb     #PR_BASEROW
        pshs    a                       ; save col across pr_leg_ptr
        jsr     pr_leg_ptr              ; X = leg ptr (clobbers A; B preserved)
        puls    a
        jsr     HAL_gfx_blit_sprite

        ; (4) reveal + flip (Option-I double buffer)
        jsr     HAL_gfx_present
        lda     <page_register
        eora    #$60                    ; $20<->$40
        sta     <page_register
        rts

* pr_set_pos — A = effective pixel X -> returns A = byte col (px>>2) and sets
*   blit_subbyte = px&3 (CoCo3 4px/byte sub-pixel). Clobbers B.
pr_set_pos:
        tfr     a,b
        andb    #$03
        stb     <blit_subbyte
        lsra
        lsra
        rts

* pr_draw_shadow — blit the shadow bar SPRITE via the shared leaf at
*   (pr_px + LEADPX), sub-pixel-positioned (blit_subbyte) so it tracks the
*   princess in lockstep (driven by the same pr_px) instead of stepping by
*   whole bytes. Starts at the front of her toes.
pr_draw_shadow:
        lda     <pr_px
        adda    #PR_SHADOW_LEADPX
        jsr     pr_set_pos              ; A = byte col, blit_subbyte = sub-pixel
        ldb     #PR_SHADOW_ROW
        ldx     #pr_shadow_spr
        jmp     HAL_gfx_blit_sprite_opaque   ; OPAQUE: black ($00) renders, not keyed out

* shadow bar sprite (HAL format: H,W then H*W bytes). REAL black ($00, index-0):
* drawn via the OPAQUE blit so it shows against the (non-black) floor — exactly
* what the in-game partially-black floor needs. ($1CC4 is all index-0.)
pr_shadow_spr:
        fcb     PR_SHADOW_H,PR_SHADOW_W
        fcb     $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        fcb     $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

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

* per-frame registration (+px) — added in pr_render so each frame's TORSO lands
* at the same screen x (ref = frame-0 torso col 5). The converter trimmed each
* frame's blanks independently -> torso-left was [5,1,2,4]px; offsets = 5-that =
* [0,4,3,1] re-align the body so only the legs swing (kills the ~4px back-lurch).
pr_leg_align:
        fcb     0,4,3,1
