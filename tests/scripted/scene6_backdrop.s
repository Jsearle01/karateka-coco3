* tests/scripted/scene6_backdrop.s
*
* SHARED scene-6 static backdrop module — the SINGLE SOURCE of backdrop truth,
* `include`d by scene6_stage1_driver.s and scene6_stage2_driver.s (and Stage 3+).
* Extracted verbatim from the Stage-1/Stage-2 drivers (de-dup refactor) — no
* geometry/palette/centering change; the framebuffer is pixel-identical before/after.
*
* Entry: draw_fuji_backdrop — Fuji 4-stack (base->peak, OPAQUE) + $0A00 sky fill
*   (blue, content region bytes 5-74 = X20-299, the +20px-centered 280px) + floor
*   $AA11 tile line (Y104, transparent). Geometry from repo consolidation §3 + the
*   bg manifest; A9B8/A948 byte-aligned (opaque sub-byte-shift-bar fix, coco3 §9a);
*   Fuji cels flood-filled (coco3 §9b).
*
* The including driver provides: globals.s + the HAL (sys.s/gfx.s) + page_register
* set + the org/entry/end. This module is include-only (no org/end).
* ---------------------------------------------------------------

* ---------------------------------------------------------------
* draw_fuji_backdrop — Fuji 4-stack (base->peak) then the floor line.
*   Back-to-front so the peak lands on top (§3); floor last so it overpaints the
*   lower Fuji (§3). blit_subbyte set per cel; A = byte col, B = row.
*   Fuji cels blit OPAQUE — index-0 detail black is solid; safe because the cel
*   PADDING is $AA (blue), not black. Floor stays transparent.
* ---------------------------------------------------------------
draw_fuji_backdrop:
        * Stage 1/2 (fight): sky + Fuji cels + full-width floor. Render UNCHANGED (the
        * cels are just extracted into draw_fuji_cels so the climb can reuse them without
        * the fight floor).
        jsr     fill_sky
        bsr     draw_fuji_cels
        * floor line: tile $AA11 (4 bytes wide) across at Y104
        jsr     draw_floor_line
        rts

* draw_fuji_cels — the 4 Fuji opaque blits (base->peak), no sky/floor. Shared by the
*   fight backdrop and the climb (which draws its own sky band + no full-width floor).
* Fuji placement (col,sub,row) is single-homed in [fuji] -> scene6_fuji_gen.s (below); the shared
*   draw_fuji_cels AND Stage-A both read fuji_<id>. Sub-byte carried (all sub=0 = byte-aligned here;
*   an opaque sub-byte shift writes the shifted-in edge zeros as BLACK bars, so these stay aligned).
draw_fuji_cels:
        lda     fuji_A9E2+1             ; base $A9E2 sub
        sta     <blit_subbyte
        lda     fuji_A9E2               ; col
        ldb     fuji_A9E2+2             ; row
        ldx     #scene6_bg_A9E2
        jsr     HAL_gfx_blit_sprite_opaque
        lda     fuji_A9B8+1             ; $A9B8 sub
        sta     <blit_subbyte
        lda     fuji_A9B8               ; col
        ldb     fuji_A9B8+2             ; row
        ldx     #scene6_bg_A9B8
        jsr     HAL_gfx_blit_sprite_opaque
        lda     fuji_A976+1             ; $A976 sub
        sta     <blit_subbyte
        lda     fuji_A976               ; col
        ldb     fuji_A976+2             ; row
        ldx     #scene6_bg_A976
        jsr     HAL_gfx_blit_sprite_opaque
        lda     fuji_A948+1             ; peak $A948 sub (drawn last = on top)
        sta     <blit_subbyte
        lda     fuji_A948               ; col
        ldb     fuji_A948+2             ; row
        ldx     #scene6_bg_A948
        jsr     HAL_gfx_blit_sprite_opaque
        rts

* fill_walltop — extend the sky BLUE over the wall-top rows 104-116 (bytes 5-74). The
*   climb has NO full-width fight floor there; the wall-top posts/ledges + Fuji draw on
*   top of this blue. (rows 104..116 = 13 rows.)
fill_walltop:
        ldy     #13                     ; rows 104..116
        ldx     #$8000+104*80+5         ; row 104, byte 5
fwt_row:
        pshs    x,y
        ldd     #$AAAA
        ldy     #35                     ; 70 content bytes
fwt_byte:
        std     ,x++
        leay    -1,y
        bne     fwt_byte
        puls    x,y
        leax    80,x
        leay    -1,y
        bne     fwt_row
        rts

* fill_sky — fill the CONTENT region (bytes 5-74 = X20-299, the centered 280px)
*   of buffer A rows 0-103 with BLUE (index 2, byte $AA). Left/right 20px (bytes
*   0-4, 75-79) left BLACK = the side borders. Per-row (70 bytes = 35 words/row).
fill_sky:
        ldy     #104                    ; Y = row counter (rows 0-103)
        ldx     #$8005                  ; row 0, col 5 (X=20px, content left edge)
fs_row:
        pshs    x,y                     ; save row start + row counter
        ldd     #$AAAA                  ; blue (index 2) x8 px
        ldy     #35                     ; 70 content bytes = 35 words
fs_byte:
        std     ,x++
        leay    -1,y
        bne     fs_byte
        puls    x,y                     ; restore
        leax    80,x                    ; next row start
        leay    -1,y
        bne     fs_row
        rts

* draw_floor_line — tile the $AA11 floor cel (4 bytes wide) across the CONTENT
*   region at Y104: byte cols 5..69 (X20..292), staying inside the 280px area
*   (last tile ends at byte 72; 70 not divisible by 4, so ~7px shy of the right
*   content edge — left as sky rather than spill into the 20px border).
draw_floor_line:
        ldb     #5                      ; B = byte col (content left edge)
fl_tile:
        pshs    b
        clr     <blit_subbyte
        tfr     b,a                     ; A = byte col
        ldb     #104                    ; B = row
        ldx     #scene6_bg_AA11
        jsr     HAL_gfx_blit_sprite
        puls    b
        addb    #4                      ; next tile (AA11 width = 4)
        cmpb    #73                     ; stop before the right border (byte 75)
        blo     fl_tile
        rts

* draw_climb_ledge — CLIMB wall-top ledge: tile $AA11 from ABOVE THE PLAYER'S HEAD
*   (byte 22 = pose $A3C5 column) rightward, NOT full-width [Jay 2026-07-12]. Rows 104-111.
draw_climb_ledge:
        ldb     #22                     ; start above the player's head (not byte 5)
cl_tile:
        pshs    b
        clr     <blit_subbyte
        tfr     b,a
        ldb     #104
        ldx     #scene6_bg_AA11
        jsr     HAL_gfx_blit_sprite
        puls    b
        addb    #4
        cmpb    #73
        blo     cl_tile
        rts

* --- backdrop cel data (single source) ---
        include "scene6_fuji_gen.s"     ; §2F single-home Fuji placement (fuji_<id>); shared by all backdrop-users
        include "../../content/background/scene6_bg_A948/converted.s"
        include "../../content/background/scene6_bg_A976/converted.s"
        include "../../content/background/scene6_bg_A9B8/converted.s"
        include "../../content/background/scene6_bg_A9E2/converted.s"
        include "../../content/background/scene6_bg_AA11/converted.s"
