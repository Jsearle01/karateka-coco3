* src/engine/princess_controller.s
*
* PRINCESS CONTROLLER — CoCo3 port of the oracle scene-5 princess (display_7700.s:
* advance_princess_anim $7F33 + draw_princess + tbl_princess_*). Her OWN controller
* driving the ONE shared render leaf (HAL_gfx_blit_sprite) — multi-animator model.
*
* Sandbox state machine (isolated demo of her animation states; the SCENE $3B clock
* drives these transitions in-game — pass one):
*   WALK  : walk-in. Legs (idx1-4) cycle + position glides; torso $1D00 composited
*           above; shadow $1CC4 (opaque black) leads her toes. -> TURN at target X.
*   TURN  : $1530->$1588->$1611->$169A (turning to face the cell). -> FALL.
*   FALL  : $16CC->$175E->$17D3->$1829 (collapse). Bottom-aligned (height shrinks
*           36->10 rows) so she sinks to the floor. -> FLOOR.
*   FLOOR : hold $1829 (collapsed on the cell floor).
* $1CD4 (blue-C) is NOT the princess (Jay ID) — excluded.
*
* CADENCE (GATE 1): native-integer; oracle-measured ~52 VBLs/walk-cycle = 8px/cycle.
* REGISTRATION: converter trims each frame's blanks independently -> per-frame X
*   offset tables re-align the body so it doesn't lurch between frames.
* [ref: docs/project/reports/2026-06-14-princess-controller-sandbox.md]
* ---------------------------------------------------------------

        setdp   0

* --- state ($43-$49; $40/$42 are the sandbox's) ---
pr_leg          equ $43         ; frame index within the current sequence (walk leg / pose)
pr_x            equ $44         ; derived byte column (traced)
pr_cadctr       equ $45         ; cadence down-counter
pr_px           equ $46         ; PIXEL position (master)
pr_frac         equ $47         ; sub-pixel accumulator
pr_tmp          equ $48         ; scratch (per-frame registration / align)
pr_state        equ $49         ; 0=walk 1=turn 2=fall
pr_seqlen       equ $4A         ; frames in the current pose sequence
pr_cadrel       equ $4B         ; cadence reload value (per-state: walk/turn vs fall)
pr_shadow_lead  equ $4C         ; shadow lead px (walk leads +; turn under her)
pr_holdctr      equ $4D         ; 16-bit ($4D/$4E) hold counter (stand 383 > 255)
pr_fullseq      equ $4F         ; 1 = full chain (walk -> bow...); 0 = walk-loop

STATE_WALK      equ 0
STATE_TURN      equ 1
STATE_FALL      equ 2
STATE_FLOOR     equ 3
STATE_STAND     equ 4           ; $1DD7 rest pose (pre-walk + chain lead-in)
STATE_BOW       equ 5           ; $1867 head-bow (collapse lead-in)

* --- tunables (live-gate) ---
PR_CAD          equ 13          ; walk-leg cadence — ORACLE-MEASURED (phase-1, 13 VBLs/leg)
PR_POSE_CAD     equ 11          ; turn & collapse cadence — ORACLE-MEASURED (~11 VBLs/frame)
* Demo-loop holds (sandbox watchability). ORACLE VBL values in comments — the
* scene-5 integration restores those; the per-frame animation CADENCES below
* (PR_CAD / PR_POSE_CAD / PR_BOW_HOLD) stay oracle-exact.
* PR_TF_DELAY/PR_TURN0_HOLD/PR_BOW_HOLD are ifndef-guarded so a stage driver can
* swap the demo holds for the ORACLE durations (Gate 2: 173/173/~9, trace-confirmed
* cell_arc.log). Undefined => the sandbox demo defaults below (watchability).
    ifndef PR_TF_DELAY
PR_TF_DELAY     equ 75          ; demo (oracle $169A/$39=0C = 173 VBLs/~2.9s)
    endc
    ifndef PR_TURN0_HOLD
PR_TURN0_HOLD   equ 40          ; demo (oracle 1530/$39=8 = 173 VBLs/~2.9s)
    endc
PR_STAND_HOLD   equ 60          ; demo (oracle $1DD7/$39=0 = 383 VBLs/~6.4s)
    ifndef PR_BOW_HOLD
PR_BOW_HOLD     equ 30          ; demo-visible (oracle $1867/$39=$13 = ~9 VBLs)
    endc
PR_FLOOR_HOLD   equ 60          ; hold collapsed before looping the demo
* PR_STARTPX/PR_ENDPX/PR_BASEROW/PR_TORSO_ROW/PR_SHADOW_ROW/PR_FLOOR_FILL are
* ifndef-guarded so a STAGE driver (e.g. the scene-5 throne composite) can
* override them BEFORE the include to place her on a real floor with a
* real-backdrop restore. Undefined => the sandbox defaults below (unchanged).
    ifndef PR_STARTPX
PR_STARTPX      equ 8           ; walk start (px)
    endc
    ifndef PR_ENDPX
PR_ENDPX        equ 220         ; walk-loop wrap (re-enter from left)
    endc
PR_CHAIN_BOWPX  equ 36          ; chain: walk this far, then BOW->turn (short demo walk)
PR_DEMO_CX      equ 56          ; turn/fall demo: stationary center (px)
PR_PXNUM        equ 2           ; walk speed = 2/13 px/VBL = 8px/cycle (oracle)
PR_PXDEN        equ 13
    ifndef PR_BASEROW
PR_BASEROW      equ 60          ; walk: leg top row
    endc
    ifndef PR_TORSO_ROW
PR_TORSO_ROW    equ 34          ; walk: torso top row
    endc
PR_TORSO_DX     equ 3           ; walk: torso centroid align (+px)
PR_FLOOR_ROW    equ 78          ; FALL bottom-align reference (base stays on floor)
PR_POSE_TOP     equ 34          ; TURN top-align row (43-row figures -> feet at floor)
PR_CLR_LEFT     equ 4
PR_CLR_W        equ 24          ; dirty-rect width (figure + leading shadow)
PR_CLR_H        equ 46          ; walk dirty-rect height
PR_POSE_ROW     equ 28          ; pose dirty-rect top (covers 43-row figures)
PR_POSE_H       equ 54          ; pose dirty-rect height (rows 28..~80)
    ifndef PR_SHADOW_ROW
PR_SHADOW_ROW   equ 76
    endc
PR_SHADOW_LEADPX equ 12
PR_SHADOW_W     equ 13
PR_SHADOW_H     equ 2
    ifndef PR_FLOOR_FILL
PR_FLOOR_FILL   equ $AA         ; sandbox floor = index-2 (blue); index-0 = black (shadow)
    endc

* ===============================================================
* pr_set_state — A = entry state. Two driver entries:
*   0 (WALK)  = walk-loop in isolation (wraps at PR_ENDPX, fullseq=0).
*   4 (STAND) = the full in-game chain: STAND($1DD7,383) -> WALK -> BOW($1867,4)
*               -> TURN(1530 h173/1588/1611/169A h173) -> COLLAPSE -> floor -> loop.
*   (1/2 still init TURN/FALL standalone for tuning.)
*   Resets, positions, clears both buffers, renders frame 0.
* ===============================================================
pr_set_state:
        sta     <pr_state
        ldb     #4                      ; sequence length (turn & fall = 4)
        stb     <pr_seqlen
        clr     <pr_leg
        clr     <pr_frac
        clr     <pr_holdctr             ; 16-bit
        clr     <pr_holdctr+1
        clr     <pr_fullseq
        ; --- STAND (chain lead-in) ---
        cmpa    #STATE_STAND
        bne     pr_ss_nstand
        inc     <pr_fullseq             ; chain mode
        lda     #4                      ; leg idx 4 = $1DD7 rest legs
        sta     <pr_leg
        ldd     #PR_STAND_HOLD          ; hold the stand (383 VBLs)
        std     <pr_holdctr
        lda     #PR_CAD
        sta     <pr_cadrel
        sta     <pr_cadctr
        clr     <pr_shadow_lead         ; stand: shadow under her (stationary)
        lda     #PR_STARTPX
        sta     <pr_px
        jsr     pr_clear_both
        jsr     pr_render_walk          ; STAND = walk composite (leg=4)
        rts
pr_ss_nstand:
        ; --- WALK (loop, isolated) ---
        cmpa    #STATE_WALK
        bne     pr_ss_pose
        lda     #PR_CAD
        sta     <pr_cadrel
        sta     <pr_cadctr
        lda     #PR_SHADOW_LEADPX
        sta     <pr_shadow_lead
        lda     #PR_STARTPX
        sta     <pr_px
        jsr     pr_clear_both
        jsr     pr_render_walk
        rts
pr_ss_pose:
        ; --- TURN / FALL standalone ---
        lda     #PR_POSE_CAD
        sta     <pr_cadrel
        sta     <pr_cadctr
        clr     <pr_shadow_lead
        lda     #PR_DEMO_CX
        sta     <pr_px
        jsr     pr_clear_both
        jsr     pr_render_pose
        rts

* ===============================================================
* pr_tick — per-VBL state machine. WALK loops (fullseq=0) or chains to BOW
*   (fullseq=1); STAND/BOW are timed holds; TURN/FALL run the pose sequence.
* ===============================================================
pr_tick:
        lda     <pr_state
        cmpa    #STATE_STAND
        lbeq    pr_tk_stand
        cmpa    #STATE_BOW
        lbeq    pr_tk_bow
        tsta
        lbne    pr_tick_pose

* --- WALK: glide; loop (fullseq=0) or chain to BOW at PR_DEMO_CX (fullseq=1) ---
        lda     <pr_frac
        adda    #PR_PXNUM
        cmpa    #PR_PXDEN
        blo     pr_w_frac
        suba    #PR_PXDEN
        sta     <pr_frac
        lda     <pr_px
        inca
        sta     <pr_px
        tst     <pr_fullseq
        beq     pr_w_wrap
        cmpa    #PR_CHAIN_BOWPX         ; chain: reached turn spot -> BOW
        blo     pr_w_cad
        lda     #STATE_BOW
        sta     <pr_state
        ldd     #PR_BOW_HOLD
        std     <pr_holdctr
        clr     <pr_shadow_lead
        jmp     pr_pose_render
pr_w_wrap:
        cmpa    #PR_ENDPX
        blo     pr_w_cad
        lda     #PR_STARTPX             ; loop: re-enter from left
        sta     <pr_px
        bra     pr_w_cad
pr_w_frac:
        sta     <pr_frac
pr_w_cad:
        dec     <pr_cadctr
        bne     pr_w_render
        lda     <pr_cadrel
        sta     <pr_cadctr
        lda     <pr_leg
        inca
        cmpa    #4
        blo     pr_w_legst
        clra
pr_w_legst:
        sta     <pr_leg
pr_w_render:
        jsr     pr_render_walk
        rts

* --- STAND ($1DD7 rest, hold PR_STAND_HOLD) -> WALK ---
pr_tk_stand:
        jsr     pr_dec_hold
        bne     pr_ts_hold
        clr     <pr_state               ; -> WALK (chain: fullseq stays 1)
        clr     <pr_leg
        lda     #PR_CAD
        sta     <pr_cadrel
        sta     <pr_cadctr
        lda     #PR_SHADOW_LEADPX
        sta     <pr_shadow_lead
        jsr     pr_render_walk
        rts
pr_ts_hold:
        jsr     pr_render_walk          ; still standing (leg=4 = $1DD7)
        rts

* --- BOW ($1867 head-bow, hold PR_BOW_HOLD) -> TURN (1530 held PR_TURN0_HOLD) ---
pr_tk_bow:
        jsr     pr_dec_hold
        bne     pr_tb_hold
        lda     #STATE_TURN
        sta     <pr_state
        clr     <pr_leg                 ; turn frame 0 = 1530
        lda     #PR_POSE_CAD
        sta     <pr_cadrel
        sta     <pr_cadctr
        clr     <pr_shadow_lead
        ldd     #PR_TURN0_HOLD          ; 1530 stand-hold ($39=8)
        std     <pr_holdctr
        jsr     pr_render_pose
        rts
pr_tb_hold:
        jsr     pr_render_pose          ; still bowing ($1867)
        rts

* --- TURN / FALL pose sequence (with 16-bit inter-anim holds) ---
pr_tick_pose:
        ldd     <pr_holdctr
        beq     pr_tp_anim
        subd    #1
        std     <pr_holdctr
        bne     pr_pose_render          ; still holding
        ; hold expired -> branch by state + frame
        lda     <pr_state
        cmpa    #STATE_TURN
        bne     pr_tp_he_fall
        lda     <pr_leg
        beq     pr_tp_resume            ; leg 0 (1530) hold done -> resume cadence
        ; leg 3 (169A) delay done -> COLLAPSE
        lda     #STATE_FALL
        sta     <pr_state
        clr     <pr_leg
        lda     #PR_POSE_CAD
        sta     <pr_cadrel
        sta     <pr_cadctr
        bra     pr_pose_render
pr_tp_resume:
        lda     #PR_POSE_CAD
        sta     <pr_cadctr
        inc     <pr_leg                 ; 1530 -> 1588
        bra     pr_pose_render
pr_tp_he_fall:
        lda     #STATE_STAND            ; floor hold done -> loop the chain
        jsr     pr_set_state
        rts
* --- frame advance (no hold pending) ---
pr_tp_anim:
        dec     <pr_cadctr
        bne     pr_pose_render
        lda     <pr_cadrel
        sta     <pr_cadctr
        inc     <pr_leg
        lda     <pr_leg
        cmpa    #4
        blo     pr_tp_chk3
        ; sequence end (FALL complete) -> hold last frame on floor
        deca
        sta     <pr_leg
        ldd     #PR_FLOOR_HOLD
        std     <pr_holdctr
        bra     pr_pose_render
pr_tp_chk3:
        ; reached last turn frame (169A, idx 3)? hold it (the facing-left delay)
        cmpa    #3
        bne     pr_pose_render
        lda     <pr_state
        cmpa    #STATE_TURN
        bne     pr_pose_render
        ldd     #PR_TF_DELAY
        std     <pr_holdctr
pr_pose_render:
        jsr     pr_render_pose
        rts

* pr_dec_hold — 16-bit decrement of pr_holdctr; Z set when it reaches 0.
pr_dec_hold:
        ldd     <pr_holdctr
        subd    #1
        std     <pr_holdctr
        rts

* ===============================================================
* pr_clear_both — clear both frame buffers to the floor color ($AA), so a
*   state switch wipes the previous sequence's remnants.
* ===============================================================
pr_clear_both:
        ldx     #$8000
        ldd     #(PR_FLOOR_FILL*256)+PR_FLOOR_FILL
pr_cb1:
        std     ,x++
        cmpx    #$BC00
        blo     pr_cb1
        ldx     #$C000
pr_cb2:
        std     ,x++
        cmpx    #$FC00
        blo     pr_cb2
        rts

* ===============================================================
* pr_render_walk — dirty-rect (floor restore) + shadow + torso + leg, flip.
* ===============================================================
pr_render_walk:
        lda     <pr_px
        lsra
        lsra
        suba    #PR_CLR_LEFT
        bcc     pr_w_clrok
        clra
pr_w_clrok:
        sta     <eng_col
        lda     #PR_TORSO_ROW
        sta     <eng_row
        lda     #PR_CLR_W
        sta     <eng_clrw
        lda     #PR_CLR_H
        sta     <eng_clrh
        ; dirty-rect restore: a STAGE driver supplies pr_throne_restore (real
        ; backdrop: black above the floor + floor stripes on it). Sandbox =
        ; flat PR_FLOOR_FILL. eng_col/row/clrw/clrh are set above.
    ifdef PR_THRONE_RESTORE
        jsr     pr_throne_restore
    else
        lda     #PR_FLOOR_FILL
        sta     <eng_fillval
        jsr     eng_clear_box
    endc
        jsr     pr_draw_shadow
        ; torso $1D00
        lda     <pr_px
        adda    #PR_TORSO_DX
        jsr     pr_set_pos
        ldb     #PR_TORSO_ROW
        ldx     #fig_1D00_coco3
        jsr     HAL_gfx_blit_sprite
        ; leg
        ldx     #pr_leg_align
        lda     <pr_leg
        lda     a,x
        adda    <pr_px
        jsr     pr_set_pos
        sta     <pr_x
        ldb     #PR_BASEROW
        pshs    a
        jsr     pr_leg_ptr
        puls    a
        jsr     HAL_gfx_blit_sprite
        ; STAGE overlay: re-render foreground the figure/shadow may have drawn
        ; over (e.g. a doorway post occludes her shadow). Sandbox = none.
    ifdef PR_THRONE_RESTORE
        jsr     pr_post_overlay
    endc
        jmp     pr_flip

* ===============================================================
* pr_render_pose — single full-figure pose frame (turn/fall/floor):
*   dirty-rect floor restore, shadow, then blit the frame X-registered +
*   BOTTOM-ALIGNED (Y = PR_FLOOR_ROW - height) so she stands/collapses on the
*   floor. Then flip.
* ===============================================================
pr_render_pose:
        lda     <pr_px
        lsra
        lsra
        suba    #PR_CLR_LEFT
        bcc     pr_p_clrok
        clra
pr_p_clrok:
        sta     <eng_col
        lda     #PR_POSE_ROW
        sta     <eng_row
        lda     #PR_CLR_W
        sta     <eng_clrw
        lda     #PR_POSE_H
        sta     <eng_clrh
        lda     #PR_FLOOR_FILL
        sta     <eng_fillval
        jsr     eng_clear_box
        ; Shadow (oracle draw_princess_frame, idx7 $1CC4): TURN draws it; FALL
        ; draws it for frames 0,1 ($16CC/$175E) only — $17D3/$1829 ($39 $11/$12)
        ; branch early in the oracle = NO shadow (she's hit the floor).
        lda     <pr_state
        cmpa    #STATE_TURN
        beq     pr_p_shadow
        cmpa    #STATE_BOW              ; BOW ($1867) draws idx7 shadow too
        beq     pr_p_shadow
        cmpa    #STATE_FALL
        bne     pr_p_noshadow
        lda     <pr_leg
        cmpa    #2
        bhs     pr_p_noshadow           ; fall frames 2,3 -> no shadow
pr_p_shadow:
        jsr     pr_draw_shadow
pr_p_noshadow:
        ; Facing-left turn frame (TURN, idx 3) overlays a 1611 BASE, per the
        ; oracle draw_princess_frame (draws idx$0B=1611 then 169A at the same
        ; origin x=0/y=$24). Pre-draw 1611 here; 169A blits on top below.
        lda     <pr_state
        cmpa    #STATE_TURN
        bne     pr_p_nobase
        lda     <pr_leg
        cmpa    #3
        bne     pr_p_nobase
        ; draw 1611 base (full turning body)
        lda     <pr_px
        adda    #-7                     ; 1611 align (= 169A align)
        jsr     pr_set_pos
        pshs    a                       ; save base byte col
        ldb     #PR_POSE_TOP
        ldx     #fig_1611_coco3
        jsr     HAL_gfx_blit_sprite
        ; clear 1611's UPPER region (its flying hair) to floor, so the 169A
        ; settled (hair-down) torso fully replaces it — kills the hair ghost.
        puls    a
        sta     <eng_col
        lda     #PR_POSE_TOP
        sta     <eng_row
        lda     #8
        sta     <eng_clrw
        lda     #16
        sta     <eng_clrh               ; = 169A height (no over-clear / cut)
        jsr     eng_clear_box
pr_p_nobase:
        jsr     pr_pose_ptr             ; X = frame ptr, pr_tmp = signed X align
        lda     <pr_px
        adda    <pr_tmp                 ; + per-frame registration (signed)
        jsr     pr_set_pos              ; A = byte col, blit_subbyte set; X,pr_tmp kept
        pshs    a                       ; save col
        ; Y: TURN top-aligns (fixed row, feet-at-floor for 43-row figures);
        ;    FALL bottom-aligns (base on floor as height shrinks = collapse).
        lda     <pr_state
        cmpa    #STATE_FALL
        beq     pr_p_bottom
        lda     #PR_POSE_TOP
        bra     pr_p_yset
pr_p_bottom:
        lda     ,x                      ; sprite height
        nega
        adda    #PR_FLOOR_ROW           ; Y = floor - height
pr_p_yset:
        tfr     a,b                     ; B = row
        puls    a                       ; A = col
        jsr     HAL_gfx_blit_sprite
        jmp     pr_flip

* ---------------------------------------------------------------
* pr_flip — reveal back buffer + toggle page (shared by walk/pose).
* ---------------------------------------------------------------
pr_flip:
        jsr     HAL_gfx_present
        lda     <page_register
        eora    #$60
        sta     <page_register
        rts

* pr_set_pos — A = effective px -> A = byte col, blit_subbyte = px&3. Clobbers B.
pr_set_pos:
        tfr     a,b
        andb    #$03
        stb     <blit_subbyte
        lsra
        lsra
        rts

* pr_draw_shadow — opaque black bar leading her toes, sub-pixel synced.
pr_draw_shadow:
        lda     <pr_px
        adda    <pr_shadow_lead
        jsr     pr_set_pos
        ldb     #PR_SHADOW_ROW
        ldx     #pr_shadow_spr
        jmp     HAL_gfx_blit_sprite_opaque

pr_shadow_spr:
        fcb     PR_SHADOW_H,PR_SHADOW_W
        fcb     $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        fcb     $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

* pr_leg_ptr — X = walk-leg sprite ptr for pr_leg (0..3).
pr_leg_ptr:
        lda     <pr_leg
        lsla
        ldx     #pr_leg_tbl
        leax    a,x
        ldx     ,x
        rts

* pr_pose_ptr — X = pose frame ptr for (pr_state, pr_leg); pr_tmp = signed X align.
pr_pose_ptr:
        lda     <pr_state
        cmpa    #STATE_BOW
        bne     pr_pp_t1
        clr     <pr_tmp                 ; BOW: single frame $1867, align 0
        ldx     #fig_1867_coco3
        rts
pr_pp_t1:
        cmpa    #STATE_TURN
        bne     pr_pp_fall
        ldx     #pr_turn_tbl
        ldy     #pr_turn_align
        bra     pr_pp_idx
pr_pp_fall:
        ldx     #pr_fall_tbl
        ldy     #pr_fall_align
pr_pp_idx:
        lda     <pr_leg
        ldb     a,y                     ; B = align[idx] (signed)
        stb     <pr_tmp
        lsla
        leax    a,x
        ldx     ,x
        rts

pr_leg_tbl:
        fdb     fig_1D36_coco3
        fdb     fig_1D5A_coco3
        fdb     fig_1D7E_coco3
        fdb     fig_1DA2_coco3
        fdb     fig_1DD7_coco3          ; idx 4 = rest legs (STAND, $39=0)
pr_leg_align:
        fcb     0,4,3,1,4               ; walk leg torso registration (+ rest $1DD7 +4px)

pr_turn_tbl:
        fdb     fig_1530_coco3          ; standing, facing right
        fdb     fig_1588_coco3          ; mid-turn (facing forward)
        fdb     fig_1611_coco3          ; turning left (hair up)
        fdb     fig_169A_coco3          ; facing left = 1611 base + 169A torso overlay
* turn registration: leftmost-white [0,6,7,7]px -> align lefts to frame 0.
* idx3 (169A) is drawn OVER a 1611 base (oracle draw_princess_frame composites
* idx$0B=1611 then 169A, both at tbl x=0 y=$24) — see pr_render_pose.
pr_turn_align:
        fcb     0,-6,-7,-7

pr_fall_tbl:
        fdb     fig_16CC_coco3          ; fall 1
        fdb     fig_175E_coco3          ; fall 2
        fdb     fig_17D3_coco3          ; fall 3
        fdb     fig_1829_coco3          ; collapsed on floor
* fall registration: leftmost-white was [6,6,1,3]px -> align lefts to frame 0
pr_fall_align:
        fcb     0,0,5,3
