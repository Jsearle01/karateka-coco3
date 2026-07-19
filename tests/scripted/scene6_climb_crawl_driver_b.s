* tests/scripted/scene6_climb_crawl_driver_b.s  — VARIANT (b): WALL-TOP DELTA + AB8E CLIFF-FACE.
* Identical to variant (a) (same scene6_cliff_variant_a.s wall-top delta) EXCEPT the cliff-face:
* the blue-fill striations (draw_climb_striations) are replaced by the oracle's $AB8E cel-stack
* (opaque blit, col $0A byte 22 sub 2, rows 117..151 step 2 = 18 blits — the real oracle cliff-
* face technique, with its opaque sub-byte-shift seam). Everything else (crawl controller, ground,
* HUD, wall-top) BYTE-IDENTICAL to variant (a). Three-up live gate vs fallback + (a).
*
* CLIMB CRAWL SANDBOX — the port's FIRST animation: the ratified 7-frame climb
* crawl (src/engine/climb_controller.s) played LIVE over the static climb
* substrate, on the EXISTING sprite engine leaf (HAL_gfx_blit_sprite). Boot-
* excluded (built only by build.bat sandbox line, never on prod boot).
*
* Substrate (static, reused AS-IS): scene6_backdrop.s (sky + Fuji + full-width
* $AA11 floor) + scene6_cliff.s ($AB/$AA cliff scenery) + scene6_hud.s player-
* side $0B12 HUD. Drawn once into buffer A, mirrored to B; the crawl composites
* over it via clean-restore. Composite order: backdrop -> cliff -> player -> HUD.
*
* VBL-locked (real GIME VBL IRQ via andcc #$EF); dwell 21 / 7x5 / 60(loop).
* GATE: 25.3-M = Jay watching this run the crawl LIVE vs scene6_climb_anim_*.
* ---------------------------------------------------------------

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

test_start:
        orcc    #$50
        lds     #$01FF
        clra
        tfr     a,dp

        jsr     HAL_sys_init
        jsr     HAL_time_init
        lda     #$00
        jsr     HAL_gfx_init

        lda     #PAGE_A_TOKEN
        sta     <page_register
        andcc   #$EF                    ; enable IRQ (VBL frame sync)

        * --- static substrate -> buffer A (mirrors the Jay-gated scene6_stage3 tableau) ---
        jsr     fill_sky                ; sky rows 0-103
        jsr     fill_walltop            ; wall-top sky band rows 104-116
        jsr     draw_climb_scenery_back ; posts BEHIND the Fuji
        jsr     draw_fuji_cels          ; Fuji cels
        jsr     draw_climb_ledge        ; AA11 ledge
        jsr     draw_climb_cliffface_ab8e ; AB8E cel-stack cliff-face (oracle technique)
        jsr     draw_climb_scenery      ; posts + rails + AA7D base
        jsr     draw_climb_ground_right ; ground lines right of the base
        jsr     draw_hud_player         ; player-side arrow HUD

        * --- mirror buffer A -> buffer B (both carry the substrate) ---
        jsr     copy_a_to_b

        * --- crawl: snapshot clean bbox + render frame 0 ---
        jsr     cl_init

crawl_loop:
        jsr     HAL_time_vbl_wait
        jsr     cl_tick
        bra     crawl_loop

* copy buffer A ($8000-$BBFF) -> buffer B ($C000-...) so both hold the substrate.
copy_a_to_b:
        ldx     #$8000
        ldy     #$C000
cab_l:
        ldd     ,x++
        std     ,y++
        cmpx    #$BC00
        blo     cab_l
        rts

* --- climb cliff-face: the ORACLE technique — $AB8E cel stacked (opaque std blit) at col $0A
*     (CoCo3 byte 22 sub 2), rows 117..151 step 2 (18 blits). Replaces variant (a)'s blue-fill
*     approximation; carries the opaque sub-byte-shift seam the fills were built to avoid. ---
draw_climb_cliffface_ab8e:
        ldb     #117                    ; B = row (also loop counter): 117,119,..,151
dccf_l:
        pshs    b
        lda     #2
        sta     <blit_subbyte
        lda     #22                     ; byte col ($0A -> CoCo3 byte 22)
        ldx     #scene6_cliff_AB8E
        jsr     HAL_gfx_blit_sprite_opaque   ; A=byte col, B=row, X=cel ptr
        puls    b
        addb    #2
        cmpb    #152                    ; through row 151 inclusive
        blo     dccf_l
        rts

draw_climb_ground_right:
        ldb     #153                    ; BLUE odd ground rows 153..179, bytes 25..74
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
        ldb     #152                    ; ORANGE even ground rows 152..180
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

* --- REAL engine controller + HAL + shared substrate modules (single source) ---
        include "../../src/engine/climb_controller.s"
        include "../../src/hal/coco3-dsk/sys.s"
        include "../../src/hal/coco3-dsk/irq_vbl.s"
        include "../../src/hal/coco3-dsk/gfx.s"
        include "../../src/hal/coco3-dsk/time.s"

        include "scene6_backdrop.s"
        include "scene6_cliff_variant_a.s"
        include "scene6_hud.s"
        include "scene6_climb_anim_gen.s"  ; §2F single-home: climb crawl animation table (cl_frames)

* --- variant (b) cliff-face cel: $AB8E (not included by scene6_cliff_variant_a.s) ---
        include "../../content/scenery/scene6_cliff_AB8E/converted.s"

* --- additional crawl pose cels (A3C5/A3E9 come via scene6_cliff.s) ---
        include "../../content/player/scene6_climb_A40B/converted.s"
        include "../../content/player/scene6_climb_A425/converted.s"
        include "../../content/player/scene6_climb_A45A/converted.s"
        include "../../content/player/scene6_climb_A4A4/converted.s"
        include "../../content/player/scene6_climb_A4D2/converted.s"
        include "../../content/player/scene6_climb_A4F2/converted.s"
        include "../../content/player/scene6_climb_A548/converted.s"
        include "../../content/player/scene6_climb_A572/converted.s"
        include "../../content/player/scene6_climb_A5CC/converted.s"
        include "../../content/player/scene6_climb_A5DC/converted.s"
        include "../../content/player/scene6_player_899C/converted.s"
        include "../../content/player/scene6_player_8ACB/converted.s"
        include "../../content/player/scene6_player_8E9B/converted.s"

        end     test_start
