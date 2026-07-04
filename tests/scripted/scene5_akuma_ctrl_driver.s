* tests/scripted/scene5_akuma_ctrl_driver.s
*
* SCENE-5 AKUMA CONTROLLER — the cross-actor gate. Akuma (arms-ambient loop +
* head-tracks-princess) composited on the gated throne stage, WITH the REAL
* princess walk driving the canonical scene clock (scene_clk $42 = the $3B-analog).
*
* TWO BEHAVIORS (HS-1), separate:
*   - ARMS: ambient free loop (akuma_ctrl_tick cycles frame_5/6/7, no clock).
*   - HEAD: tracks the princess — draw_akuma_head reads scene_clk (HS-2, the
*     single source the princess WRITES) and selects the head frame per the
*     5-zone table (15-17->f1 .. 1E-22->f8).
*
* COMPOSITING (HS-4, shared leaf): the throne stage + Akuma's STATIC base
* (draw_akuma_body: shadow, feet, robe outline, floor-ext, body 9EB8, pauldron)
* render ONCE to both buffers and into CLEAN_BUF. Each frame, the princess's
* pr_post_overlay hook restores Akuma's UPPER rect (byte49-60, rows117-146) from
* CLEAN_BUF and redraws the current arm + head over the clean body. The princess
* walks LEFT of Akuma (px40->168) so the actors don't overlap.
* Boot-excluded (built only by run_akuma_ctrl.sh / build.bat).
* ---------------------------------------------------------------

* --- princess placement (same as Gate 1: on the throne floor) ---
PR_CAD          equ 7                   ; demo: faster walk (engine oracle default = 13)
PR_PXDEN        equ 7                   ; glide 2/7 px/VBL so 2/7 * PR_CAD(7) = 2px/leg (no slide)
PR_TORSO_ROW    equ 119
PR_BASEROW      equ 145
PR_SHADOW_ROW   equ 161                 ; 5th floor line (her ground contact)
PR_STARTPX      equ 140                 ; nearer horizontal centre (80->125->135->140, Jay-gated)
PR_ENDPX        equ 220                 ; worked-out: completely across to the right doorway
PR_THRONE_RESTORE equ 1                 ; route her restore -> pr_throne_restore
* She walks px80->220 completely across, IN FRONT of Akuma: his STATIC body is in
* CLEAN_BUF so her dirty-rect restore shows it and she draws over it (like the
* gates). His arm/head redraw is upper (rows117-146) where she doesn't reach.

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

scene_clk       equ $42                 ; canonical $3B-analog (princess writes, Akuma reads)
g1_prevleg      equ $3C
g1_prevstate    equ $3D
g1_prevpx       equ $3E
thr_off         equ $40                 ; pr_throne_restore 16-bit offset ($40/$41)

CLK_PHASE1_START equ $15
CLK_PHASE1_END  equ $22
G1_STAND_VBL    equ 120                 ; short pre-walk stand (demo)
CLEAN_BUF       equ $4400               ; clean throne+akuma-body snapshot

* Akuma is drawn OPAQUE over the princess (draw_akuma_full uses the opaque blit for
* body/arm/head): his silhouette (black + colored) occludes her; she shows only
* where his sprite isn't. CLEAN_BUF = throne only (she restores/walks on it).

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

        ; Akuma one-shot arm init (draw_throne_stage doesn't touch $52-$55).
        clr     <akuma_arm_idx
        clr     <akuma_arm_done
        clr     <akuma_clr_ctr
        lda     #AKUMA_ARM_CAD
        sta     <akuma_arm_ctr

        ; --- buffer A: throne -> snapshot (THRONE ONLY) -> full Akuma over it ---
        jsr     HAL_time_vbl_wait
        jsr     draw_throne_stage       ; NOTE: this writes sc_mir ($42) = scene_clk
        jsr     draw_scene5_guard       ; STATIC guard at the left doorway (into CLEAN_BUF too)
        jsr     draw_scene5_eagle_body  ; STATIC eagle body on Akuma's shoulder (into CLEAN_BUF too)
        ldx     #$8000                  ; snapshot the PRISTINE THRONE+GUARD+EAGLE-BODY -> CLEAN_BUF
        ldy     #CLEAN_BUF              ;   (throne only: she restores to it, walks
ak_snapcpy:                             ;    the floor; Akuma is drawn OVER her each
        ldd     ,x++                    ;    frame so he always occludes her)
        std     ,y++
        cmpx    #$BC00
        blo     ak_snapcpy
        lda     #CLK_PHASE1_START       ; set scene_clk AFTER draw_throne_stage
        sta     <scene_clk
        jsr     draw_akuma_full         ; A += full Akuma (over throne)
        jsr     HAL_gfx_present
        lda     <page_register
        eora    #$60
        sta     <page_register
        ; --- buffer B: throne + full Akuma ---
        jsr     HAL_time_vbl_wait
        jsr     draw_throne_stage
        jsr     draw_scene5_guard       ; STATIC guard at the left doorway (buffer B)
        jsr     draw_scene5_eagle_body  ; STATIC eagle body (buffer B)
        lda     #CLK_PHASE1_START       ; re-set (throne render clobbered $42)
        sta     <scene_clk
        jsr     draw_akuma_full
        jsr     HAL_gfx_present
        lda     <page_register
        eora    #$60
        sta     <page_register

        ; --- init princess STAND inline (NOT pr_set_state: it clears buffers) ---
        lda     #STATE_STAND
        sta     <pr_state
        lda     #4
        sta     <pr_seqlen
        lda     #4
        sta     <pr_leg
        clr     <pr_frac
        clr     <pr_fullseq             ; walk-loop
        ldd     #G1_STAND_VBL
        std     <pr_holdctr
        lda     #PR_CAD
        sta     <pr_cadrel
        sta     <pr_cadctr
        clr     <pr_shadow_lead
        lda     #PR_STARTPX
        sta     <pr_px
        sta     <g1_prevpx
        jsr     pr_render_walk          ; frame 0 (restore + princess + akuma hook + flip)

akc_loop:
        jsr     HAL_time_vbl_wait
        lda     <pr_leg
        sta     <g1_prevleg
        lda     <pr_state
        sta     <g1_prevstate
        lda     <pr_px
        sta     <g1_prevpx
        jsr     pr_tick                 ; princess step (draws her + akuma via hook + flip)
        jsr     akuma_ctrl_tick         ; advance the ambient arm cycle
        ; --- drive scene_clk: a completed WALK leg-cycle (leg 3->0) = +1 (cap $22) ---
        lda     <g1_prevstate
        bne     akc_wrapchk
        lda     <g1_prevleg
        cmpa    #3
        bne     akc_wrapchk
        tst     <pr_leg
        bne     akc_wrapchk
        lda     <scene_clk
        cmpa    #CLK_PHASE1_END
        bhs     akc_wrapchk
        inca
        sta     <scene_clk
akc_wrapchk:
        ; on walk wrap (pr_px jumped back left), re-arm the clock so each pass re-tracks
        lda     <pr_px
        cmpa    <g1_prevpx
        bhs     akc_loop
        lda     #CLK_PHASE1_START
        sta     <scene_clk
        bra     akc_loop

* ===============================================================
* pr_post_overlay — the princess's post-draw hook (called by pr_render_walk before
*   the flip). Here it DRAWS AKUMA: restore his upper rect from CLEAN_BUF (clean
*   body), then the current arm + head. (She walks left of Akuma; no doorway-post
*   occlusion needed at this range.)
* ===============================================================
pr_post_overlay:
        jsr     restore_right_doorway   ; redraw the doorway posts OVER her leading shadow
        jsr     punch_akuma_stencil     ; occlude her behind Akuma's EXACT figure (fig_974B
        jsr     draw_akuma_full         ;   silhouette), THEN paint his colors over it. She
        jsr     draw_scene5_eagle_body  ; eagle OVER the princess (she was overwriting the static body)
        jsr     draw_scene5_eagle_head  ; perched eagle: one-shot head-swap 9FD8->985C
        rts                             ;   shows through his gaps; not a rectangle.

* restore_right_doorway — her wide leading shadow (opaque black, rows 161-162)
* cuts the vertical right-doorway post (CLEAN_BUF bytes 68-69, present every row).
* The dirty-rect restore runs BEFORE the shadow, so re-lay the post AFTER it. Copy
* ONLY the 2-byte post column back from CLEAN_BUF (NOT draw_setdressing — its sc_*
* temps alias pr_leg $43 / pr_state $49 / scene_clk $42 and would corrupt the walk;
* NOT a wide rect — that repaints the floor and erases her shadow). The shadow
* stays intact everywhere left of the post; the post is redrawn over it.
restore_right_doorway:
        lda     #68
        sta     <eng_col
        lda     #160
        sta     <eng_row
        lda     #2                      ; bytes 68-69 (the post column only)
        sta     <eng_clrw
        lda     #5                      ; rows 160-164 (covers the 161-162 shadow)
        sta     <eng_clrh
        jmp     pr_copy_from_clean      ; tail-call (rts)

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

* --- REAL engine + controller + HAL (single source, by include) ---
        include "../../src/engine/sprite_engine.s"
        include "../../src/engine/princess_controller.s"
        include "../../src/hal/coco3-dsk/sys.s"
        include "../../src/hal/coco3-dsk/irq_vbl.s"
        include "../../src/hal/coco3-dsk/gfx.s"
        include "../../src/hal/coco3-dsk/time.s"
        include "../../src/hal/coco3-dsk/input.s"

* --- the gated throne stage + Akuma controller ---
        include "scene5_throne_stage.s"
        include "scene5_akuma.s"
        include "scene5_composite.s"    ; the STATIC left-doorway guard (draw_scene5_guard)

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
