* tests/scripted/scene6_stage3_driver.s
*
* SCENE-6 STAGE 3 — static CLIMB-START tableau (the opening cliff-crawl scene, frozen).
* Renders, as a SINGLE STILL FRAME: the Fuji backdrop + the $AB cliff (climbing surface)
* + the player crawl-start pose ($A3C5/$A3E9 at Y158) + the PLAYER-side arrow HUD.
* No engine, no animation, no scroll (HS-6) — the still starting point; the crawl-to-
* standing animation is the NEXT step, built against this frozen tableau.
*
* AUTHORITY (climb-window investigation, Jay-confirmed 48fb14d + census this dispatch):
*   - Cliff/scenery = $AB bank (AB8E tiled climbing surface, rows 117-151) + AB94/AB7C/
*     AB4A structure + AA7D base + AA23/AA31 mountain band. STATIC, native color.
*     (NOT the $A684 fight midground — that is post-guard fight scenery.)
*   - Start pose = $A3C5(torso)+$A3E9(legs) at Y158 (the crawl anchor).
*   - HUD = PLAYER side only (14 arrows); the guard side is ABSENT during the climb (D2).
*
* Composite (back-to-front): backdrop -> cliff/scenery -> player start-pose -> player-HUD.
* Cels are Stage-0 Jay-hue-gated (2026-07-12); scenery native-parity, poses orange
* (A3C5/A4F2/A572 Jay-flip). Shared modules; no copying (HS-6). Prod ROM untouched.
*
* Build: lwasm --decb -o tests/scripted/scene6_stage3_driver.bin \
*              tests/scripted/scene6_stage3_driver.s
* Gate: Jay live MAME (25.3-M) vs climb frame scene6_climb_00_f6019.
* ---------------------------------------------------------------

        org     $0100
        rti                 ; $0100 swi3
        nop
        nop
        rti                 ; $0103 swi2
        nop
        nop
        rti                 ; $0106 swi
        nop
        nop
        rti                 ; $0109 nmi
        nop
        nop
        rti                 ; $010C irq
        nop
        nop
        rti                 ; $010F firq
        nop
        nop

        org     $0200
        setdp   0
        include "../../src/engine/globals.s"

* ---------------------------------------------------------------
* test_start — Stage-3 entry: boot + HAL init, composite the static climb tableau, hold.
* ---------------------------------------------------------------
test_start:
        orcc    #$50
        lds     #$01FF
        clra
        tfr     a,dp

        jsr     HAL_sys_init
        lda     #$00
        jsr     HAL_gfx_init            ; GIME 320x192x4 (mode BEFORE palette, §9)

        lda     #PAGE_A_TOKEN
        sta     <page_register

        * CLIMB backdrop: sky + wall-top sky band + Fuji cels — NO full-width floor.
        * Wall top = the posts/ledges (draw_climb_scenery). Fuji base gap shows sky for
        * now — to be addressed next [Jay: "we'll work from there"].
        jsr     fill_sky                ; sky rows 0-103
        jsr     fill_walltop            ; sky rows 104-116 (wall-top background)
        jsr     draw_climb_scenery_back ; wall-top posts BEHIND the Fuji (AA31) [oracle order]
        jsr     draw_fuji_cels          ; Fuji cels — occludes the upper posts
        jsr     draw_climb_ledge        ; AA11 ledge from above player's head -> right [Jay]
        jsr     draw_climb_striations   ; blue cliff-face lines (bytes 5..24, background)
        jsr     draw_climb_scenery      ; wall-top FRONT (AA23 + rails) + AA7D base (OPAQUE)
        jsr     draw_climb_ground_right ; ground lines RIGHT of the base, AFTER it, so the
        *                                 base's opaque right edge is covered = its right
        *                                 side reads see-through into the lines [Jay]
        jsr     draw_climb_startpose    ; player crawl-start pose $A3C5/$A3E9 (Y158)
        jsr     draw_hud_player         ; player-side arrow HUD only (D2; guard absent)

        jsr     HAL_gfx_present         ; reveal buffer A

hold:
        bra     hold                    ; static hold

* ---------------------------------------------------------------
* draw_climb_striations — the traced $AB8E cel draws only a ~9px cliff-face strip at
* col $0A; Jay's f6064 gate calls for the blue/black striation lines to run LEFT behind
* the player's head all the way to the content left edge, AND to continue DOWN the full
* cliff (into the $AB8E strips up top + the $AA7D base lines below) to the cliff bottom.
* Fill BLUE (index 2 = $AA) on the odd (striation) rows 117,119,..,179 across content
* bytes 5..22 (X20..91) — the even rows stay black/base = the single-row gaps. The base
* $AA7D (rows 152-180) already carries blue on the odd rows; this connects them to the
* left edge. Drawn BEFORE the pose, so the player legs overwrite the overlap. Direct
* buffer-A fill (fill_sky convention: buffer A logical base $8000).
* ---------------------------------------------------------------
draw_climb_striations:
        * BLUE cliff-face lines: odd rows 117..179, bytes 5..24 (the LEFT cliff column,
        * under the cliff sprites). The right-of-cliff ground lines are draw_climb_ground_right
        * (drawn AFTER the sprites). Even rows stay black = the single-row gaps.
        ldb     #117
dcst_cf:
        pshs    b
        tfr     b,a
        ldb     #80
        mul
        addd    #$8005                  ; byte 5
        tfr     d,x
        ldd     #$AAAA                  ; blue (index 2)
        ldy     #10                     ; bytes 5..24 (cliff-face width)
dcst_cff:
        std     ,x++
        leay    -1,y
        bne     dcst_cff
        puls    b
        addb    #2
        cmpb    #180
        blo     dcst_cf
        rts

* ---------------------------------------------------------------
* draw_climb_ground_right — the GROUND lines to the RIGHT of the cliff base (bytes
* 25..74), drawn AFTER draw_climb_scenery so they paint OVER $AA7D's opaque right edge:
* the base's right side reads see-through into the lines (no seam) while its body stays
* opaque [Jay gate 2026-07-12]. Blue odd rows 153..179 / orange even rows 152..180.
* ---------------------------------------------------------------
draw_climb_ground_right:
        ldb     #153                    ; BLUE odd ground rows
dcgr_b:
        pshs    b
        tfr     b,a
        ldb     #80
        mul
        addd    #$8019                  ; byte 25
        tfr     d,x
        ldd     #$AAAA                  ; blue (index 2)
        ldy     #25                     ; bytes 25..74
dcgr_bf:
        std     ,x++
        leay    -1,y
        bne     dcgr_bf
        puls    b
        addb    #2
        cmpb    #180
        blo     dcgr_b
        ldb     #152                    ; ORANGE even ground rows
dcgr_o:
        pshs    b
        tfr     b,a
        ldb     #80
        mul
        addd    #$8019                  ; byte 25
        tfr     d,x
        ldd     #$5555                  ; orange (index 1)
        ldy     #25                     ; bytes 25..74
dcgr_of:
        std     ,x++
        leay    -1,y
        bne     dcgr_of
        puls    b
        addb    #2
        cmpb    #182
        blo     dcgr_o
        rts

* ---------------------------------------------------------------
* HAL + the SHARED modules (single source, no copying, HS-6):
*   scene6_backdrop.s — Fuji + sky + floor
*   scene6_cliff.s    — cliff/scenery + player start-pose (generated)
*   scene6_hud.s      — draw_hud_player (player-only entry; Stage-2 render preserved)
* No sprite_engine.s (STATIC).
* ---------------------------------------------------------------
        include "../../src/hal/coco3-dsk/sys.s"
        include "../../src/hal/coco3-dsk/gfx.s"

        include "scene6_backdrop.s"
        include "scene6_cliff.s"
        include "scene6_hud.s"

        end     test_start
