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

* --- guard content ---
        include "../../content/guard/fig_8F2B/converted.s"
        include "../../content/guard/fig_8ACB/converted.s"
        include "../../content/guard/fig_899C/converted.s"
