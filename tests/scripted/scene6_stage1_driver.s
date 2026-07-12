* tests/scripted/scene6_stage1_driver.s
*
* SCENE-6 STAGE 1 — static fixed backdrop (first pixels on screen).
* Renders the Mt-Fuji 4-sprite stack + floor line as a SINGLE STILL FRAME.
* No engine, no animation, no input, no scroll (HS-3) — the engine is Stage 4.
*
* GEOMETRY AUTHORITY (HS-1): repo consolidation scene6-recon-consolidated.md §3
*   (Fixed backdrop = Mt-Fuji 4-sprite stack $A948 peak Y81 -> $A976 -> $A9B8 ->
*    $A9E2 base Y108 + $0A00 sky fill; lower Fuji repair-blitted where floor $AA11
*    overpaints it) + docs/project/scene6-stage0-bg-manifest.csv (traced start_col
*    = screen pixel column $05*7+$10). Y rows from the background trace scene6_bg.log.
*   §3 and the bg manifest AGREE (no HS-1 conflict): manifest start_col == the
*   trace X for each Fuji cel.
*
* Per-cel placement (byte col = X>>2, sub-byte = X&3, row = Y):
*   $A9E2 base  X84  Y108 -> byte 21 sub 0
*   $A9B8       X105 Y100 -> byte 26 sub 1
*   $A976       X112 Y92  -> byte 28 sub 0
*   $A948 peak  X126 Y81  -> byte 31 sub 2   (drawn last = on top, §3 "peak un-occluded")
*   $AA11 floor X0   Y104 -> tiled across (4 bytes wide), overpaints the lower Fuji (§3)
*
* Cels are the Stage-0 Jay-hue-gated content/background/ assets — rendered AS-IS,
* no re-flip (HS-8). Sky = the cleared-black framebuffer (HAL_gfx_init clears to 0);
* the $0A00 sky-fill COLOR is a Jay-gate refinement (not pinned here).
*
* SEE-THROUGH REGIONS (HS-4, from §3) established for Stages 2-3:
*   - FLOOR BAND rows ~104-111 (the $AA11 tile line) — Stage 2 scrolling midground
*     ($A684-bank) composites here; the lower Fuji is repair-blitted under it.
*   - ACTOR STAGE — the fight floor above the seam where the Stage-4 combatants
*     composite (§1 actors, Y ~114-160 per the combatant trace).
*   Static Stage 1 draws the backdrop only; these regions are documented, not
*   occluded (no scroll/actors yet).
*
* Build: lwasm --decb -o tests/scripted/scene6_stage1_driver.bin \
*              tests/scripted/scene6_stage1_driver.s
* Gate: Jay live MAME (25.3-M). Prod ROM untouched.
* ---------------------------------------------------------------

* IRQ/reset dispatch block (inline, like visual_smoke_driver.s) — IRQ masked, so
* these just need to be valid vectors.
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
* test_start — Stage-1 entry: boot + HAL init, draw the static backdrop, hold.
* ---------------------------------------------------------------
test_start:
        orcc    #$50                    ; mask IRQ/FIRQ (no interrupts this stage)
        lds     #$01FF                  ; stack above the dispatch block
        clra
        tfr     a,dp                    ; DP = 0

        jsr     HAL_sys_init            ; MMU/task, $FF90 CoCo3 mode
        lda     #$00                    ; palette set 0 (0=blk 1=org 2=blu 3=wht)
        jsr     HAL_gfx_init            ; GIME 320x192x4 (mode BEFORE palette, §9)

        lda     #PAGE_A_TOKEN           ; draw target = buffer A ($8000)
        sta     <page_register

        jsr     draw_fuji_backdrop      ; the static fixed backdrop

        jsr     HAL_gfx_present         ; reveal buffer A

hold:
        bra     hold                    ; static — hold the frame forever

* ---------------------------------------------------------------
* draw_fuji_backdrop — Fuji 4-stack (base->peak) then the floor line.
*   Back-to-front so the peak lands on top (§3); floor last so it overpaints the
*   lower Fuji (§3). blit_subbyte set per cel; A = byte col, B = row.
* ---------------------------------------------------------------
draw_fuji_backdrop:
        * base $A9E2  X84  Y108  byte 21 sub 0
        clr     <blit_subbyte
        lda     #21
        ldb     #108
        ldx     #scene6_bg_A9E2
        jsr     HAL_gfx_blit_sprite
        * $A9B8  X105 Y100  byte 26 sub 1
        lda     #1
        sta     <blit_subbyte
        lda     #26
        ldb     #100
        ldx     #scene6_bg_A9B8
        jsr     HAL_gfx_blit_sprite
        * $A976  X112 Y92  byte 28 sub 0
        clr     <blit_subbyte
        lda     #28
        ldb     #92
        ldx     #scene6_bg_A976
        jsr     HAL_gfx_blit_sprite
        * peak $A948  X126 Y81  byte 31 sub 2  (last = on top)
        lda     #2
        sta     <blit_subbyte
        lda     #31
        ldb     #81
        ldx     #scene6_bg_A948
        jsr     HAL_gfx_blit_sprite
        * floor line: tile $AA11 (4 bytes wide) across at Y104
        jsr     draw_floor_line
        rts

* draw_floor_line — tile the $AA11 floor cel across the row at Y104.
draw_floor_line:
        ldb     #0                      ; B = byte col
fl_tile:
        pshs    b
        clr     <blit_subbyte
        tfr     b,a                     ; A = byte col
        ldb     #104                    ; B = row
        ldx     #scene6_bg_AA11
        jsr     HAL_gfx_blit_sprite
        puls    b
        addb    #4                      ; next tile (AA11 width = 4)
        cmpb    #80
        blo     fl_tile
        rts

* ---------------------------------------------------------------
* HAL + background cel data (build INTO the existing HAL — no new harness, HS-2).
* No sprite_engine.s (STATIC, HS-3).
* ---------------------------------------------------------------
        include "../../src/hal/coco3-dsk/sys.s"
        include "../../src/hal/coco3-dsk/gfx.s"

        include "../../content/background/scene6_bg_A948/converted.s"
        include "../../content/background/scene6_bg_A976/converted.s"
        include "../../content/background/scene6_bg_A9B8/converted.s"
        include "../../content/background/scene6_bg_A9E2/converted.s"
        include "../../content/background/scene6_bg_AA11/converted.s"

        end     test_start
