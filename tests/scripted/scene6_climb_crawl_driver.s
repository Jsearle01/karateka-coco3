* tests/scripted/scene6_climb_crawl_driver.s
*
* CLIMB CRAWL SANDBOX — the port's FIRST animation: the ratified 7-frame climb
* crawl (src/engine/climb_controller.s) played LIVE over the static climb
* substrate, on the EXISTING sprite engine leaf (HAL_gfx_blit_sprite). Boot-
* excluded (built only by build.bat sandbox line, never on prod boot).
*
* Substrate (static): scene6_backdrop.s (sky + Fuji) + scene6_cliff_walltop.s (the
* JAY-GATED wall-top: 3 posts px 98/183/268 (first mirrored) + rail to the logical
* right edge px299, drawn as table-driven RMW; old AA23/AA31 posts + AA11 ledge +
* AB rails PULLED, AA7D base kept) + scene6_hud.s player-side $0B12 HUD. Drawn once
* into buffer A, mirrored to B; the crawl composites over it via clean-restore.
* [wall-top baked in from the gated variant 2026-07-16.]
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
*       jsr     draw_climb_ledge        ; AA11 ledge — PULLED (baked wall-top, Jay 2026-07-16)
        jsr     draw_climb_striations   ; blue cliff-face lines
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

* --- climb cliff-face detail (mirrors scene6_stage3_driver.s, Jay-gated 2026-07-12):
*     hand fills direct to buffer-A logical base $8000, drawn as part of the static
*     substrate so the clean-restore behind the crawler carries them. ---
draw_climb_striations:
        * black back wall rows 112..116 (bytes 5..24) — extend the cliff face UP to the lower
        * white rail (row 111) so it is not a gap; blue striations then run 113..179 [Jay 2026-07-16].
        ldb     #112
dcbw_cf:
        pshs    b
        tfr     b,a
        ldb     #80
        mul
        addd    #$8005
        tfr     d,x
        ldd     #$0000                  ; black (back wall)
        ldy     #10                     ; bytes 5..24
dcbw_ff:
        std     ,x++
        leay    -1,y
        bne     dcbw_ff
        puls    b
        incb
        cmpb    #117
        blo     dcbw_cf
        ldb     #113                    ; BLUE odd rows 113..179, bytes 5..24 (cliff face)
dcst_cf:
        pshs    b
        tfr     b,a
        ldb     #80
        mul
        addd    #$8005
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
        include "scene6_cliff_walltop.s"
        include "scene6_hud.s"

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
