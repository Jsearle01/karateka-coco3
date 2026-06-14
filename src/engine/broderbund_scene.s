* src/engine/broderbund_scene.s
*
* Brøderbund splash scene: Logo 1 + Logo 2 + "presents" text.
* One-frame static render: draw all elements, present, return.
*
* Called by boot.s after HAL_gfx_init and page_register init.
*
* ORIGIN: Apple II outer_caller_b77c scene 1:
*   routine_b898 (logos) + routine_b8c2 (presents text)
*   karateka_dissasembly_claude/src/intro.s lines 592-632
*
* [ref: tests/scripted/broderbund_presents_scene_driver.s —
*       proof-of-concept; WB1 confirmed behavior-equivalent to
*       inline driver copy (2026-05-20)]
* [ref: docs/project/conventions.md §19 — DOCUMENTED TRANSFORM coordinates]
* [ref: docs/project/conventions.md §20 — sub-byte rendering]
* [ref: docs/project/conventions.md §21 — transparency semantics]
* [ref: docs/project/conventions.md §22 — visible-extent position formula]
* ---------------------------------------------------------------

        setdp   0

* Logo positions (Apple II → CoCo3, §19 border formula):
*   Logo 1 (badge, sprite_1 at $A126):    Apple II col=119 → byte=35, row=72
*   Logo 2 (wordmark, sprite_2 at $A16E): Apple II col=84  → byte=26, row=88
LOGO1_COL   equ 35
LOGO1_ROW   equ 72
LOGO2_COL   equ 26
LOGO2_ROW   equ 88

* "presents" row (Apple II row=$6E → CoCo3 row=110 per §19)
PRESENTS_ROW    equ 110

* ---------------------------------------------------------------
* broderbund_scene
*
* Render all scene elements onto the back buffer
* (page_register-selected), then present. Returns CC.C clear.
*
* Preconditions:
*   page_register = PAGE_A_TOKEN (boot.s sets this before call)
*   HAL_gfx_init complete; blit DP symbols ($08-$0F) available
*   from src/hal/coco3-dsk/gfx.s (multi-file build)
*
* Clobbers: A, B, X, Y, CC, ZP $08-$0F (blit scratch)
* ---------------------------------------------------------------
broderbund_scene:

        * --- Logo 1 (badge — narrower, upper) ---
        * Apple II routine_b898 first JSR L1903 (sprite_1 at $A126)
        * [ref: karateka_dissasembly_claude/src/intro.s:592-605]
        clr     <blit_subbyte
        ldx     #broderbund_logo_sprite_1_coco3
        lda     #LOGO1_COL
        ldb     #LOGO1_ROW
        jsr     HAL_gfx_blit_sprite

        * --- Logo 2 (wordmark — wider, lower) ---
        * Apple II routine_b898 second JMP L1903 (sprite_2 at $A16E)
        * [ref: karateka_dissasembly_claude/src/intro.s:606-612]
        clr     <blit_subbyte
        ldx     #broderbund_logo_sprite_2_coco3
        lda     #LOGO2_COL
        ldb     #LOGO2_ROW
        jsr     HAL_gfx_blit_sprite

        * --- "presents" glyphs ---
        * Apple II routine_b8c2 → L0700 per-glyph blit
        * [ref: karateka_dissasembly_claude/src/intro.s:627-632]
        * Positions: P2.4.2-followup-3 visible-extent formula, GAP=1;
        * 'p' anchors visible center at CoCo3 pixel 160 (screen center).

        * 'p' byte=30 sub=3 (pixel 123)
        lda     #3
        sta     <blit_subbyte
        ldx     #glyph_p_coco3
        lda     #30
        ldb     #PRESENTS_ROW
        jsr     HAL_gfx_blit_sprite

        * 'r' byte=33 sub=2 (pixel 134)
        lda     #2
        sta     <blit_subbyte
        ldx     #glyph_r_coco3
        lda     #33
        ldb     #PRESENTS_ROW
        jsr     HAL_gfx_blit_sprite

        * 'e' byte=36 sub=1 (pixel 145)
        lda     #1
        sta     <blit_subbyte
        ldx     #glyph_e_coco3
        lda     #36
        ldb     #PRESENTS_ROW
        jsr     HAL_gfx_blit_sprite

        * 's' byte=38 sub=1 (pixel 153)
        lda     #1
        sta     <blit_subbyte
        ldx     #glyph_s_coco3
        lda     #38
        ldb     #PRESENTS_ROW
        jsr     HAL_gfx_blit_sprite

        * 'e' byte=40 sub=1 (pixel 161)
        lda     #1
        sta     <blit_subbyte
        ldx     #glyph_e_coco3
        lda     #40
        ldb     #PRESENTS_ROW
        jsr     HAL_gfx_blit_sprite

        * 'n' byte=42 sub=2 (pixel 170)
        lda     #2
        sta     <blit_subbyte
        ldx     #glyph_n_coco3
        lda     #42
        ldb     #PRESENTS_ROW
        jsr     HAL_gfx_blit_sprite

        * 't' byte=45 sub=0 (pixel 180)
        clr     <blit_subbyte
        ldx     #glyph_t_coco3
        lda     #45
        ldb     #PRESENTS_ROW
        jsr     HAL_gfx_blit_sprite

        * 's' byte=47 sub=1 (pixel 189)
        lda     #1
        sta     <blit_subbyte
        ldx     #glyph_s_coco3
        lda     #47
        ldb     #PRESENTS_ROW
        jsr     HAL_gfx_blit_sprite

        jsr     HAL_gfx_present         ; flip: show Frame A with logos + presents
        andcc   #$FE
        rts

* ---------------------------------------------------------------
* Sprite data (INT-1 content conversion wave 1)
* [ref: docs/project/p2-scoping-survey.md §5 — INT-1 content asset list]
* ---------------------------------------------------------------
        include "../../content/broderbund/broderbund_logo_sprite_2/converted.s"
        include "../../content/broderbund/broderbund_logo_sprite_1/converted.s"
        include "../../content/font/glyph_p/converted.s"
        include "../../content/font/glyph_r/converted.s"
        include "../../content/font/glyph_e/converted.s"
        include "../../content/font/glyph_s/converted.s"
        include "../../content/font/glyph_n/converted.s"
        include "../../content/font/glyph_t/converted.s"
