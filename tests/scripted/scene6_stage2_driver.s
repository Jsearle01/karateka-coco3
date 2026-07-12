* tests/scripted/scene6_stage2_driver.s
*
* SCENE-6 STAGE 2 — static bottom-screen arrow / health HUD over the Stage-1 backdrop.
* Extends the Stage-1 scaffold (GIME 320x192x4, palette, +20px centering, the Fuji
* backdrop) and adds the arrow HUD, drawn STATIC at a fixed count. No engine, no
* blink, no timer, no decrement/regen, no input, no scroll (HS-2) — a still frame.
*
* PINNED GEOMETRY (prereq / repo §7-corrected — reused, not re-derived):
*   Count = 14 ($0E) both sides (fixed constant this stage).
*   Player: cel arrow_0B12 (orange, draw-A, no mirror), Apple px 1->131 LEFT, Y=185.
*   Guard : cel arrow_0B12_mir (blue, BAKED mirror), Apple px 272->142 RIGHT, Y=185.
*   Pitch = 10 Apple px/arrow (= 10 CoCo3 px, 1:1). Centering = +20px = the Stage-1
*   convention (Apple_X + 20 -> CoCo3_X). 10px = 2 bytes + 2 sub-byte per arrow.
*
* Per-arrow CoCo3 X (byte,sub) — computed from the pinned model:
*   Player px 21,31,..151  -> (5,1)(7,3)(10,1)..(37,3)   [advance +10px = byte+2 sub+2 carry]
*   Guard  px 292,282,..162 -> (73,0)(70,2)(68,0)..(40,2) [advance -10px = byte-2 sub-2 borrow]
*   Non-overlap: player ends ~px159, guard starts px162.
*
* hud cels blit TRANSPARENT (index-0 keyed) over the black bottom region — the
* arrow's black keys to the backdrop; the sub-byte shift is safe transparent (the
* Stage-1 black-bar artifact was OPAQUE-only). The guard mirror is BAKED into
* arrow_0B12_mir (Stage 0 --mirror) — NO runtime flip bit (HS-4). Cels are
* Jay-hue-gated (2026-07-12) — rendered as-is (HS-4).
*
* Build: lwasm --decb -o tests/scripted/scene6_stage2_driver.bin tests/scripted/scene6_stage2_driver.s
* Gate: Jay live MAME (25.3-M) vs a PRE-FIGHT reference frame (summit f6108-6118,
*       before the guard enters f6484, so all 14 arrows/side are present). Prod untouched.
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

* (arrow-HUD constants + draw_hud + hud cel includes moved to the shared
*  scene6_hud.s module — included below, single-source with the Stage-3 driver.)

* ---------------------------------------------------------------
* test_start — Stage-2 entry: boot + HAL init, backdrop, HUD, hold.
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

        jsr     draw_fuji_backdrop      ; Stage-1 static backdrop
        jsr     draw_hud                ; Stage-2 static arrow HUD

        jsr     HAL_gfx_present         ; reveal buffer A

hold:
        bra     hold                    ; static hold

* ---------------------------------------------------------------
* HAL + the SHARED backdrop module (single source) + the Stage-2 hud cels.
* The backdrop routines + content/background includes live in scene6_backdrop.s,
* shared with the Stage-1 driver (de-dup refactor). No sprite_engine.s (STATIC).
* ---------------------------------------------------------------
        include "../../src/hal/coco3-dsk/sys.s"
        include "../../src/hal/coco3-dsk/gfx.s"

        include "scene6_backdrop.s"
        include "scene6_hud.s"

        end     test_start
