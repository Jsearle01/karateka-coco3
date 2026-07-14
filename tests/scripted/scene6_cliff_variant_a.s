* tests/scripted/scene6_cliff_variant_a.s  — WALL-TOP DELTA variant of scene6_cliff.s.
* Hand-authored (NOT regenerated) so the fallback's scene6_cliff.s stays byte-identical.
*
* Delta vs fallback (execution-verified: identity 4b27dd8, overlap HS-1 this dispatch):
*   (1) DROP the extra col-11 post — the oracle draws only Apple bytes 23 & 35 (never col-11);
*   (2) sub-byte shift 5 -> CoCo3 sub 2 (the fallback byte-aligned to sub 0);
*   (3) MASKED (HAL_gfx_blit_sprite, transparent) not opaque, for AA23/AA31.
* Layer order UNCHANGED (HS-1: back/front composite AA31 -> Fuji -> AA23, one Fuji between):
*   AA31 back (before the Fuji, driver draws Fuji after this), AA23 front (after).
* AB rails + AA7D base + start-pose + cel includes: BYTE-IDENTICAL to scene6_cliff.s.
* CoCo3 posts (place() w/ leading-trim, sh5): AA31(L0)=byte46/67 sub2 ; AA23(L1)=byte47/68 sub2.
* ---------------------------------------------------------------

* draw_climb_scenery_back — AA31 BACK posts (masked, 2 posts, sub 2), drawn BEFORE the Fuji
*   so the mountain occludes their upper rows.
draw_climb_scenery_back:
        lda     #2
        sta     <blit_subbyte
        lda     #46                     ; Apple col 23 sh5 -> byte 46 (AA31 L=0)
        ldb     #100
        ldx     #scene6_cliff_AA31
        jsr     HAL_gfx_blit_sprite
        lda     #2
        sta     <blit_subbyte
        lda     #67                     ; Apple col 35 sh5 -> byte 67
        ldb     #100
        ldx     #scene6_cliff_AA31
        jsr     HAL_gfx_blit_sprite
        rts

* draw_climb_scenery — AA23 FRONT posts (masked, 2, sub 2) drawn AFTER the Fuji,
*   then AB rails + AA7D base (opaque, positions byte-identical to fallback).
draw_climb_scenery:
        lda     #2
        sta     <blit_subbyte
        lda     #47                     ; Apple col 23 sh5 -> byte 47 (AA23 L=1)
        ldb     #100
        ldx     #scene6_cliff_AA23
        jsr     HAL_gfx_blit_sprite
        lda     #2
        sta     <blit_subbyte
        lda     #68                     ; Apple col 35 sh5 -> byte 68
        ldb     #100
        ldx     #scene6_cliff_AA23
        jsr     HAL_gfx_blit_sprite
        ldy     #climb_scn_tbl          ; AB rails + AA7D base (opaque, unchanged)
dcs_loop:
        ldx     ,y++
        beq     dcs_done
        lda     ,y+
        sta     <blit_subbyte
        lda     ,y+
        ldb     ,y+
        pshs    y
        jsr     HAL_gfx_blit_sprite_opaque
        puls    y
        bra     dcs_loop
dcs_done:
        rts

* draw_climb_startpose — IDENTICAL to scene6_cliff.s.
draw_climb_startpose:
        lda     #3
        sta     <blit_subbyte
        lda     #21                     ; byte col
        ldb     #158                    ; row (Y=158)
        ldx     #scene6_climb_A3E9
        jsr     HAL_gfx_blit_sprite
        lda     #2
        sta     <blit_subbyte
        lda     #22                     ; byte col
        ldb     #141                    ; row (Y=141)
        ldx     #scene6_climb_A3C5
        jsr     HAL_gfx_blit_sprite
        rts

* AB rails + AA7D base ONLY (AA23/AA31 posts are the explicit masked blits above).
climb_scn_tbl:
        fdb     scene6_cliff_AB4A
        fcb     0,5,112
        fdb     scene6_cliff_AB7C
        fcb     0,22,104
        fdb     scene6_cliff_AB94
        fcb     0,22,112
        fdb     scene6_cliff_AA7D
        fcb     0,15,152
        fdb     0                       ; end

* --- cel data (single source) — same set as scene6_cliff.s ---
        include "../../content/scenery/scene6_cliff_AA23/converted.s"
        include "../../content/scenery/scene6_cliff_AA31/converted.s"
        include "../../content/scenery/scene6_cliff_AA7D/converted.s"
        include "../../content/scenery/scene6_cliff_AB4A/converted.s"
        include "../../content/scenery/scene6_cliff_AB7C/converted.s"
        include "../../content/scenery/scene6_cliff_AB94/converted.s"
        include "../../content/player/scene6_climb_A3C5/converted.s"
        include "../../content/player/scene6_climb_A3E9/converted.s"
