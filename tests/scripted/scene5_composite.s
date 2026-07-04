* tests/scripted/scene5_composite.s
*
* SCENE-5 COMPOSITE LAYER — scene-5-specific elements drawn OVER the gated
* throne-stage module (scene5_throne_stage.s), NOT in it (HS-3: the location
* module stays clean so the later cutscene can reuse it with its OWN animated
* guard). This layer currently holds the STATIC guard (capture-confirmed static:
* the same 3 parts every frame — actors.log/actors2.log; the double-buffer
* alternation is not animation). Akuma + eagle ANIMATE -> later controllers
* (see docs/project/scene5-akuma-eagle-recon.md), NOT here.
*
* Reuses the throne module's shared draw_setdressing/make_flipped/ZP (included
* before this). Coord: px = apple_x*7 + 20 (SCENE_XOFF), rows 1:1.
* ---------------------------------------------------------------

* ===============================================================
* draw_scene5_guard — the static throne-room guard, LEFT-centre. Three stacked
*   parts (oracle apple positions, trace-captured guard_pos.log):
*     head  $8F2B  apple (x6,  y114=$72)  10x6
*     upper $8ACB  apple (x7,  y124=$7C)  14x4
*     lower $899C  apple (x7,  y138=$8A)  24x4
*   Transparent (index-0 keyed) so the backdrop shows around the figure. The
*   3-part converter-trim registration is the per-part apple_x (6/7/7).
* ===============================================================
draw_scene5_guard:
        ldu     #guard_tbl
        jsr     draw_setdressing
        rts

* entry: fdb ptr ; fcb apple_x, apple_y, mirror(0/1), opaque(0/1)
* ORDER: shadow FIRST (opaque black bar on the floor at his feet, same as the
* princess) so the (transparent) feet pixels draw OVER it and read against the
* dark ground instead of vanishing into the blue floor stripes. Head nudged
* right (x6->x7) to register over the body (per-part converter-trim alignment).
guard_tbl:
        fdb     guard_shadow_spr        ; ground shadow (opaque black), led IN FRONT (right)
        fcb     8,160,0,1
        fdb     fig_8F2B_coco3          ; head
        fcb     7,114,0,0
        fdb     fig_8ACB_coco3          ; upper body
        fcb     7,124,0,0
        fdb     fig_899C_coco3          ; lower body / legs
        fcb     7,138,0,0
        fdb     0                       ; terminator

* guard ground shadow — opaque black bar (index 0), SAME size as the princess's
* pr_shadow_spr (2 rows x 13 bytes). Drawn on the floor, led in front of his feet.
guard_shadow_spr:
        fcb     2,13
        fcb     $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        fcb     $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

* ===============================================================
* SCENE-5 EAGLE — perched on Akuma's shoulder, throne-phase only. The LIGHTEST
* actor: STATIC body + a ONE-SHOT head-swap keyed on the canonical scene_clk.
*   body  9FC4 (9x4)  — STATIC, drawn once into the composite (+ CLEAN_BUF)
*   head  9FD8 (6x4)  — initial; swaps ONCE to 985C (4x3) at scene_clk >= $16
*                       (walk-start beat), then HOLDS. Recon: NOT a flap/fly.
*   tail  — NOT here (it is part of the Akuma sprite). Body + head only (HS-3).
* NO occlusion (HS-2): the eagle draws CLEAR (nothing overlaps it) — plain
* transparent blits, no stencil/masked machinery. The head-swap uses a dirty-rect
* restore from CLEAN_BUF (body/backdrop) so the smaller 985C leaves no 9FD8 ghost.
* Positions are apple-recon estimates (body x$1B/y$7C, head x$17/y$70) as EQU
* tunables — Jay-gated. Reads scene_clk (HS-5, shared leaf); no new render path.
* ===============================================================
EAGLE_BODY_COL   equ 45                  ; Akuma's LEFT shoulder (px180 = byte45 sub0; Jay: +4px total from 44/sub0)
EAGLE_BODY_SUB   equ 0                   ; (44/sub3 +1px wrapped to 45/sub0)
EAGLE_BODY_ROW   equ 116                 ; two rows lower than the initial 114 (Jay)
EAGLE_HEAD_COL   equ 43                  ; initial head 9FD8
EAGLE_HEAD_SUB   equ 3                   ; +3px right (sub-byte; Jay)
EAGLE_HEAD_ROW   equ 110                 ; down two rows (was 108; Jay)
EAGLE_HEAD2_COL  equ 45                  ; swap head 985C — px183 (byte45 sub3): +8px right of 9FD8 (Jay)
EAGLE_HEAD2_SUB  equ 3
EAGLE_HEAD2_ROW  equ 112                 ; +2 rows below 9FD8 (Jay)
EAGLE_HEAD_BOXW  equ 6                   ; restore box covers 9FD8 (byte43..47) AND 985C (byte45..48)
EAGLE_HEAD_BOXH  equ 6                   ; rows 110..115 covers 9FD8 (110-115) + 985C (112-115)
EAGLE_SWAP_CLK   equ $16                 ; walk-start beat: head 9FD8 -> 985C, then hold

draw_scene5_eagle_body:                  ; STATIC — drawn once (both buffers + CLEAN_BUF)
        lda     #EAGLE_BODY_SUB
        sta     <blit_subbyte
        lda     #EAGLE_BODY_COL
        ldb     #EAGLE_BODY_ROW
        ldx     #eagle_body_9FC4_coco3
        jmp     HAL_gfx_blit_sprite      ; transparent; nothing overlaps (HS-2)

draw_scene5_eagle_head:                  ; per-frame: restore head box, draw the clock-keyed frame
        lda     #EAGLE_HEAD_COL
        sta     <eng_col
        lda     #EAGLE_HEAD_ROW
        sta     <eng_row
        lda     #EAGLE_HEAD_BOXW
        sta     <eng_clrw
        lda     #EAGLE_HEAD_BOXH
        sta     <eng_clrh
        jsr     pr_copy_from_clean       ; body/backdrop back under the head (one-shot swap, no ghost)
        lda     <scene_clk
        cmpa    #EAGLE_SWAP_CLK
        blo     dse_9fd8
        lda     #EAGLE_HEAD2_SUB         ; >= $16: swapped head 985C (own position), held
        sta     <blit_subbyte
        lda     #EAGLE_HEAD2_COL
        ldb     #EAGLE_HEAD2_ROW
        ldx     #s5_985c_eagle_head_coco3
        jmp     HAL_gfx_blit_sprite
dse_9fd8:
        lda     #EAGLE_HEAD_SUB          ; pre-walk stand ($15): initial head 9FD8
        sta     <blit_subbyte
        lda     #EAGLE_HEAD_COL
        ldb     #EAGLE_HEAD_ROW
        ldx     #eagle_head_9FD8_coco3
        jmp     HAL_gfx_blit_sprite

* --- guard content ---
        include "../../content/guard/fig_8F2B/converted.s"
        include "../../content/guard/fig_8ACB/converted.s"
        include "../../content/guard/fig_899C/converted.s"
* --- eagle content (body + 2 head frames; tail is in the Akuma sprite) ---
        include "../../content/bird/eagle_body_9FC4/converted.s"
        include "../../content/bird/eagle_head_9FD8/converted.s"
        include "../../content/bird/s5_985c_eagle_head/converted.s"
