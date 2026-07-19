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
        lda     #PAL_SEL_DEFAULT        ; boot-time palette selection (0=composite set, 1=RGB set)
        sta     pal_select
        jsr     apply_palette           ; load the selected palette set into $FFB0..$FFB3

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

* ===============================================================
* apply_palette — Jay-gated (2026-07-18) INDEX-SELECTED palette. Written AFTER
*   HAL_gfx_init so it OVERRIDES the shared prod default without touching gfx.s
*   (prod's source) — keeps prod byte-identical. Two sets, one-entry difference:
*     set 0 = COMPOSITE (blue $2D->54,179,247 / orange $26->245,115,58) — MAME composite decode
*     set 1 = RGB       (blue $19->0,170,255  / orange $26->255,85,0)   — MAME Monitor Type=RGB (bitpack)
*   Only index 2 (blue) differs ($2D vs $19); index 0/1/3 identical ($00/$26/$3F).
*   pal_select (boot-time selection variable, a runtime byte a future boot menu can
*   write) picks the active set. The CoCo3's GIME emits composite AND RGB at once and
*   the 6809 cannot read the monitor, so the set is a BOOT-TIME CHOICE per monitor, NOT
*   auto-detected. Applied globally: this one write re-colours EVERY scene this build
*   renders. The startup RGB/composite selector is a DELIBERATE oracle divergence
*   (Apple II boots straight to attract) — do NOT remove it later as infidelity.
* ===============================================================
        ifndef  PAL_SEL_DEFAULT
PAL_SEL_DEFAULT equ 1                   ; boot default: 1=RGB set (dominant delivery target), 0=composite.
        endc                            ;   composite variant built with: lwasm -DPAL_SEL_DEFAULT=0
apply_palette:
        lda     pal_select              ; boot-time selection (menu-writable runtime byte)
        ldb     #4                      ; 4 bytes per palette_sets row
        mul                             ; D = pal_select * 4 = row byte offset
        ldx     #palette_sets
        leax    d,x                     ; X -> selected row
        ldy     #$FFB0                  ; $FFB0..$FFB3 are 4 consecutive palette regs
        ldb     #4
aph_loop:
        lda     ,x+
        sta     ,y+
        decb
        bne     aph_loop
        rts
pal_select:
        fcb     PAL_SEL_DEFAULT         ; active-set index; set at boot from PAL_SEL_DEFAULT
palette_sets:
        fcb     $00,$26,$2D,$3F ; set 0 = COMPOSITE  blk / orange $26 / blue $2D / white
        fcb     $00,$26,$19,$3F ; set 1 = RGB        blk / orange $26 / blue $19 / white

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
        include "scene6_cliff_face.s"

* --- REAL engine controller + HAL + shared substrate modules (single source) ---
        include "../../src/engine/climb_controller.s"
        include "../../src/hal/coco3-dsk/sys.s"
        include "../../src/hal/coco3-dsk/irq_vbl.s"
        include "../../src/hal/coco3-dsk/gfx.s"
        include "../../src/hal/coco3-dsk/time.s"

        include "scene6_backdrop.s"
        include "scene6_cliff_walltop.s"
        include "scene6_hud.s"
        include "scene6_climb_anim_gen.s"  ; §2F single-home: climb crawl animation table (cl_frames)

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
