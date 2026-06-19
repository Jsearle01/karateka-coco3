* tests/scripted/princess_gate1_driver.s
*
* SCENE-5 1b GATE 1 — princess walk-in COMPOSITED ON THE THRONE STAGE, driving
* the REAL scene clock. Exercises the REAL controller (princess_controller.s) +
* REAL engine + HAL + the gated 1a throne stage (scene5_throne_stage.s) by
* include. Boot-excluded (built only by run_princess_gate1.sh).
*
* MILESTONE A (committed f0b3eae) — THE PROOF (HS-1/AC-0/AC-2/AC-3): her leg-cycle
*   advances the scene clock (the oracle $3B analog) at the oracle walk cadence,
*   NOT a free-run/stand-in. STAND ($1DD7, 383 VBL, clock=$15) -> WALK: each
*   completed 4-leg cycle (52 VBL) advances the clock +1 ($16..$22), capped $22
*   (phase-1 end; the $3B=$04 transition is GATE 2). Trace: gate1.log.
* MILESTONE B (this) — AC-1/AC-4 VISUAL: she walks ON the throne floor, not a flat
*   $AA sandbox. The 1a throne stage is rendered to BOTH buffers ONCE; her
*   per-frame dirty-rect restore (pr_throne_restore) repaints the REAL backdrop
*   (black above the floor + the floor stripes on it) instead of flat fill.
*
* COORD: the controller is Y/fill/X overridden (below) to drop her onto the
*   throne floor (top row 153): feet/shadow at the floor top, body above (black).
* ZP NOTE: the throne module shares scratch with the controller ($43-$4F) — OK,
*   it renders ONCE at init, before the princess loop owns those. scene_clk
*   ($42) aliases the throne's sc_mir — set it AFTER the throne render.
* ---------------------------------------------------------------

* --- controller placement overrides (BEFORE the include) ---
* Sandbox: torso 34 / leg 60 / shadow 76 (feet ~78). Shift +77 so the shadow
* lands on the throne floor top (row 153); body above is black backdrop.
* Jay gate: feet/shadow on the 5TH floor line from the top. Floor stripes are
* rows 153,155,157,159,161 (stride 2) -> 5th line = row 161. So +85 (sandbox
* shadow 76 -> 161); body above in the black backdrop.
PR_TORSO_ROW    equ 119         ; 34 + 85   (also the dirty-rect top)
PR_BASEROW      equ 145         ; 60 + 85
PR_SHADOW_ROW   equ 161         ; 76 + 85 = 5th floor line (her ground contact)
* X range: her dirty-rect restore is a CLEAN-BUFFER COPY (pr_throne_restore
* copies the exact backdrop back from the $4400 snapshot), so the rect may
* freely overlap the gates with NO damage. She walks from the centre up to the
* RIGHT doorway (Jay gate: "get close to the right doorway").
PR_STARTPX      equ 80          ; byte20 (centre floor, clear of left gate)
PR_ENDPX        equ 220         ; byte55 — figure reaches the right doorway (~byte61)
PR_THRONE_RESTORE equ 1         ; route pr_render_walk's restore -> pr_throne_restore

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
g1_prevleg      equ $3C         ; pr_leg before pr_tick (leg-wrap detect)
g1_prevstate    equ $3D         ; pr_state before pr_tick
thr_off         equ $40         ; pr_throne_restore: 16-bit copy offset ($40/$41)

CLK_PHASE1_START equ $15        ; throne phase-1 start (stand)
CLK_PHASE1_END  equ $22         ; phase-1 end (transition boundary = GATE 2)
G1_STAND_VBL    equ 383         ; oracle pre-walk stand (replaces demo PR_STAND_HOLD)
CLEAN_BUF       equ $4400       ; clean throne snapshot (15360 bytes -> $8000); FLIP_BUF=$4000

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

        ; --- render the gated 1a throne stage to BOTH buffers ONCE (held) ---
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

        ; snapshot the rendered throne (buffer A $8000) to CLEAN_BUF ($4400),
        ; the pristine backdrop pr_throne_restore copies from each frame.
        ldx     #$8000
        ldy     #CLEAN_BUF
g1_snapcpy:
        ldd     ,x++
        std     ,y++
        cmpx    #$BC00                  ; 15360 bytes ($8000..$BC00)
        blo     g1_snapcpy

        ; scene clock starts at phase-1 ($15). Set AFTER the throne render
        ; (sc_mir aliases $42); her walk drives it to $22.
        lda     #CLK_PHASE1_START
        sta     <scene_clk

        ; --- init the princess STAND state INLINE (NOT pr_set_state: that calls
        ; pr_clear_both, which would wipe the throne). Override the demo stand
        ; with the oracle 383; fullseq=0 = walk-loop (Gate 1 = walk-only). ---
        lda     #STATE_STAND
        sta     <pr_state
        lda     #4
        sta     <pr_seqlen
        lda     #4
        sta     <pr_leg                 ; STAND legs = $1DD7
        clr     <pr_frac
        clr     <pr_fullseq             ; walk-loop, no BOW/turn
        ldd     #G1_STAND_VBL
        std     <pr_holdctr             ; oracle 383 stand
        lda     #PR_CAD
        sta     <pr_cadrel
        sta     <pr_cadctr
        clr     <pr_shadow_lead         ; stand: shadow under her
        lda     #PR_STARTPX
        sta     <pr_px
        jsr     pr_render_walk          ; frame 0 (throne restore + draw + flip)

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

* ===============================================================
* pr_throne_restore — the controller's dirty-rect restore for the THRONE stage.
*   On entry eng_col/eng_row/eng_clrw/eng_clrh = her dirty rect (set by
*   pr_render_walk). COPIES that rect from the pristine throne snapshot
*   (CLEAN_BUF=$4400) to the back buffer (page_register-selected). Reproduces
*   the EXACT backdrop — floor stripes, gates, everything — so her rect may
*   overlap a gate with no damage (she can walk up to the doorway).
* ===============================================================
pr_throne_restore:
        bra     pr_copy_from_clean      ; eng_* = her dirty rect (set by caller)

* ===============================================================
* pr_post_overlay — AFTER her shadow/figure are drawn, the wide opaque shadow
*   (rows 161-162) reaches the RIGHT doorway's OUTER post (byte68-69 = FE 80),
*   which runs all the way to the floor, and blacks a gash in it. Re-copy that
*   post's columns over the shadow rows from the clean snapshot so the OUTER
*   post occludes the shadow (correct depth). The floor-shadow to its LEFT
*   (including over the inner post's floor-gap, byte63-67) stays visible.
*   (The inner post byte63-64 ends at row159; it is NOT cut — below it is floor.)
* ===============================================================
POST_OUTER      equ 68          ; right doorway OUTER post: left byte-col (byte68-69)
SHADOW_R0       equ 161         ; = PR_SHADOW_ROW (shadow top); H=2 -> rows 161,162
pr_post_overlay:
        lda     <eng_col
        adda    <eng_clrw
        cmpa    #POST_OUTER
        blo     ppo_skip                ; shadow hasn't reached the outer post
        ldx     #$8000                  ; back-buffer base
        lda     <page_register
        cmpa    #PAGE_A_TOKEN
        beq     ppo_a
        ldx     #$C000
ppo_a:
        ldd     CLEAN_BUF+SHADOW_R0*80+POST_OUTER     ; clean outer-post bytes, row161
        std     SHADOW_R0*80+POST_OUTER,x             ; -> back buffer row161
        ldd     CLEAN_BUF+(SHADOW_R0+1)*80+POST_OUTER ; clean outer-post bytes, row162
        std     (SHADOW_R0+1)*80+POST_OUTER,x         ; -> back buffer row162
ppo_skip:
        rts

* --- shared copy core (used by pr_throne_restore): copy her dirty rect
*     (eng_col,eng_clrw,eng_row,eng_clrh) from CLEAN_BUF to the back buffer ---
pr_copy_from_clean:
        lda     #80
        ldb     <eng_row
        mul                             ; D = row*80
        addb    <eng_col
        adca    #0                      ; D = offset = row*80 + col
        std     <thr_off
        addd    #CLEAN_BUF
        tfr     d,u                     ; U = clean source = $4400 + offset
        ldx     #$8000                  ; back-buffer base
        lda     <page_register          ; (clobbers A = D high — so reload offset below)
        cmpa    #PAGE_A_TOKEN
        beq     pcc_a
        ldx     #$C000
pcc_a:
        ldd     <thr_off                ; reload offset (page check clobbered A)
        leax    d,x                     ; X = backbuf + offset (offset >0, < 32k)
        tfr     x,y                     ; Y = dst
        lda     <eng_clrh               ; row counter
pcc_row:
        pshs    a,y,u
        ldb     <eng_clrw               ; bytes/row
pcc_byte:
        lda     ,u+
        sta     ,y+
        decb
        bne     pcc_byte
        puls    a,y,u
        leay    80,y                    ; next row (both src + dst, stride 80)
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

* --- the gated 1a throne stage (draw_throne_stage + gate content) ---
        include "scene5_throne_stage.s"

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
