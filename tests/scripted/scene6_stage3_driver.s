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

        jsr     draw_fuji_backdrop      ; Stage-1 static backdrop (Fuji + sky + floor)
        jsr     draw_climb_scenery      ; $AB cliff + $AA base/mountain band (static)
        jsr     draw_climb_startpose    ; player crawl-start pose $A3C5/$A3E9 (Y158)
        jsr     draw_hud_player         ; player-side arrow HUD only (D2; guard absent)

        jsr     HAL_gfx_present         ; reveal buffer A

hold:
        bra     hold                    ; static hold

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
