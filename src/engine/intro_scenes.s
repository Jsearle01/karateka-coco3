* src/engine/intro_scenes.s
*
* R-p25: scene-2 (Mechner credit) + scene-3 (karateka title + copyright)
* render routines, plus the shared "pressed" early-break screen.
*
* Driven by boot.s's linear controller (which reuses R-p24's
* scene1_hold_poll runner). One-frame static renders; the controller
* clears/presents/holds around them.
*
* ORIGIN: Apple II outer_caller_b77c scenes 2-3
*   scene 2: routine_b8ce (text_b976 "a game by" + text_b982 "jordan mechner")
*   scene 3: routine_b8e6 (title_render 11-slot loop) + routine_b8f3 (copyright)
*   [ref: karateka_dissasembly_claude/src/intro.s, karateka_logo.s]
*
* POSITIONS:
*   Scene 2 text: baked offline via the §22 visible-extent formula
*     (route i; tools/bake_text.py), inter-letter GAP=1 (§22.3),
*     inter-word GAP=16 = glyph-m pixel width (§2-F), centered at CoCo3
*     pixel 160. Extents (wlead/trail) for the 10 new glyphs computed by
*     tools/glyph_extent.py and validated against §22.4's p,r,e,s,n,t.
*     Rows: Apple II $06=$55/$63 -> CoCo3 85/99 (§19 vertical 1:1).
*   Scene 3 title: the Apple II $B926-$B95C parallel position tables,
*     converted to CoCo3 coords via §19 (coco3_px = apple_px + 20;
*     byte = px/4, subbyte = px%4; row 1:1) and merged into the packed
*     render-table below. title_render's 11-slot loop is ported as the
*     shared render_glyph_run.
*
* [ref: docs/conventions.md §19 coordinate map, §20 sub-byte, §22 extent]
* ---------------------------------------------------------------

        setdp   0

* ===============================================================
* render_glyph_run  [R-p25 — port of Apple II title_render 11-slot loop]
*
* Blit a run of glyphs/sprites from a packed table through the existing
* sub-byte blit path. Generalizes the oracle title_render (which read 5
* parallel $B926-$B95C tables); here one packed table feeds all scenes.
*
* Packed entry (5 bytes): fdb sprite_addr ; fcb byte_col, subbyte, row
* Args:  B = entry count; U = table pointer.
* HAL_gfx_blit_sprite preserves U, so the table pointer survives the call.
* Clobbers: A, B, X, Y, CC, blit scratch. Preserves U on return is N/A
*           (U is consumed walking the table).
* ===============================================================
render_glyph_run:
rgr_loop:
        pshs    b                       ; save remaining entry count
        ldx     ,u++                    ; X = sprite address (advance U past fdb)
        lda     ,u+                     ; A = destination byte column
        ldb     ,u+                     ; B = sub-byte (0-3)
        stb     <blit_subbyte           ; caller-set blit sub-byte
        ldb     ,u+                     ; B = destination pixel row
        jsr     HAL_gfx_blit_sprite     ; X=addr A=col B=row; preserves U
        puls    b                       ; restore count
        decb
        bne     rgr_loop
        rts

* ===============================================================
* scene2_render — Mechner credit: "a game by" (row 85) + "jordan mechner"
* (row 99). Caller clears the back buffer first and presents after.
* = Apple II routine_b8ce (two LB960->L0700 string renders).
* ===============================================================
scene2_render:
        ldb     #7
        ldu     #scene2_str1_tbl        ; "a game by"
        jsr     render_glyph_run
        ldb     #13
        ldu     #scene2_str2_tbl        ; "jordan mechner"
        jsr     render_glyph_run
        rts

* ===============================================================
* scene3_title_render — compose the lowercase "karateka" title from the
* 11 slot entries (= Apple II routine_b8e6 / title_render).
* ===============================================================
scene3_title_render:
        ldb     #11
        ldu     #scene3_title_tbl
        jsr     render_glyph_run
        rts

* ===============================================================
* scene3_copyright — "Copyright 1984 Jordan Mechner" strip.
* = Apple II routine_b8f3 (sprite $1F09). Apple II $06=$B4 -> row 180
* (§19 1:1); centered horizontally (42-byte sprite -> byte 19).
* UNCERTAINTY: routine_b8f3's $05/$06 -> col mapping is not fully pinned;
* position confirmed at Jay's visual gate (AC-S3-3). copyright start_col
* was flagged uncertain at Wave 2 conversion.
* ===============================================================
scene3_copyright:
        clr     <blit_subbyte
        ldx     #copyright_coco3
        lda     #19                     ; centered byte column
        ldb     #180                    ; row (Apple II $06=$B4)
        jsr     HAL_gfx_blit_sprite
        rts

* ===============================================================
* pressed_screen  [R-p25 D3 — DEBUG PLACEHOLDER]
*
* Shared early-break screen: clear -> blit "pressed" -> present -> return.
* Called from boot.s scene1_input_break on a press in ANY scene's hold,
* replacing R-p24's freeze-on-content.
*
* *** DEBUG PLACEHOLDER for the still-STUBBED game-start consumer. ***
* The oracle starts gameplay on a press (LB7DE -> $0209 game-start path);
* that consumer is deferred to P3+. This "pressed" screen is scaffolding
* to make the early-break visible/testable, NOT shipped behavior — it is
* the thing a future task replaces with the real game-start hand-off.
* ($60/$61 game-start flags are still set by scene1_input_break.)
* ===============================================================
pressed_screen:
        jsr     HAL_gfx_clear
        ldb     #7
        ldu     #pressed_tbl
        jsr     render_glyph_run
        jsr     HAL_gfx_present
        rts

* ---------------------------------------------------------------
* Packed render tables (fdb addr ; fcb byte, subbyte, row)
* ---------------------------------------------------------------

* "a game by" — baked §22, centered@160, row 85
scene2_str1_tbl:
        fdb     glyph_a_coco3
        fcb     27,1,85
        fdb     glyph_g_coco3
        fcb     33,1,85
        fdb     glyph_a_coco3
        fcb     35,2,85
        fdb     glyph_m_coco3
        fcb     37,3,85
        fdb     glyph_e_coco3
        fcb     41,1,85
        fdb     glyph_b_coco3
        fcb     47,1,85
        fdb     glyph_y_coco3
        fcb     49,3,85

* "jordan mechner" — baked §22, centered@160, row 99
scene2_str2_tbl:
        fdb     glyph_j_coco3
        fcb     22,0,99
        fdb     glyph_o_coco3
        fcb     23,2,99
        fdb     glyph_r_coco3
        fcb     26,0,99
        fdb     glyph_d_coco3
        fcb     28,3,99
        fdb     glyph_a_coco3
        fcb     31,0,99
        fdb     glyph_n_coco3
        fcb     33,1,99
        fdb     glyph_m_coco3
        fcb     39,2,99
        fdb     glyph_e_coco3
        fcb     43,0,99
        fdb     glyph_c_coco3
        fcb     45,1,99
        fdb     glyph_h_coco3
        fcb     47,2,99
        fdb     glyph_n_coco3
        fcb     50,0,99
        fdb     glyph_e_coco3
        fcb     52,2,99
        fdb     glyph_r_coco3
        fcb     54,3,99

* karateka title — Apple II $B926-$B95C slots, §19-converted (px+20)
* slot order matches the oracle parallel arrays (k a r a t e k a + flourishes + accent)
scene3_title_tbl:
        fdb     title_a_coco3              ; slot 0  a  apple 35  -> px55  byte13 sub3
        fcb     13,3,79
        fdb     title_a_coco3              ; slot 1  a  apple107  -> px127 byte31 sub3
        fcb     31,3,79
        fdb     title_a_coco3              ; slot 2  a  apple241  -> px261 byte65 sub1
        fcb     65,1,79
        fdb     title_k_coco3              ; slot 3  k  apple0    -> px20  byte5  sub0
        fcb     5,0,80
        fdb     title_k_coco3              ; slot 4  k  apple206  -> px226 byte56 sub2
        fcb     56,2,80
        fdb     title_k_flourish_coco3     ; slot 5  k-flourish apple0   -> byte5  sub0
        fcb     5,0,69
        fdb     title_k_flourish_coco3     ; slot 6  k-flourish apple206 -> byte56 sub2
        fcb     56,2,69
        fdb     title_t_coco3              ; slot 7  t  apple133  -> px153 byte38 sub1
        fcb     38,1,75
        fdb     title_e_coco3              ; slot 8  e  apple168  -> px188 byte47 sub0
        fcb     47,0,79
        fdb     title_r_coco3              ; slot 9  r  apple69   -> px89  byte22 sub1
        fcb     22,1,78
        fdb     title_ra_connector_coco3   ; slot 10 accent apple104 -> px124 byte31 sub0
        fcb     31,0,112

* "pressed" — baked §22, centered@160, row 90 (debug placeholder)
pressed_tbl:
        fdb     glyph_p_coco3
        fcb     32,0,90
        fdb     glyph_r_coco3
        fcb     34,3,90
        fdb     glyph_e_coco3
        fcb     37,2,90
        fdb     glyph_s_coco3
        fcb     39,2,90
        fdb     glyph_s_coco3
        fcb     41,1,90
        fdb     glyph_e_coco3
        fcb     43,1,90
        fdb     glyph_d_coco3
        fcb     45,2,90

* ---------------------------------------------------------------
* Content (Wave 2). New glyphs/sprites only — e,n,r,p,s,t are included
* by src/engine/broderbund_scene.s and visible in this multi-file build.
* ---------------------------------------------------------------
        include "../../content/glyph_a/converted.s"
        include "../../content/glyph_b/converted.s"
        include "../../content/glyph_c/converted.s"
        include "../../content/glyph_d/converted.s"
        include "../../content/glyph_g/converted.s"
        include "../../content/glyph_h/converted.s"
        include "../../content/glyph_j/converted.s"
        include "../../content/glyph_m/converted.s"
        include "../../content/glyph_o/converted.s"
        include "../../content/glyph_y/converted.s"
        include "../../content/title_a/converted.s"
        include "../../content/title_k/converted.s"
        include "../../content/title_k_flourish/converted.s"
        include "../../content/title_t/converted.s"
        include "../../content/title_e/converted.s"
        include "../../content/title_r/converted.s"
        include "../../content/title_ra_connector/converted.s"
        include "../../content/copyright/converted.s"
