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
* CENTERING (Jay gate): the Apple scene is 280px wide; centered in the 320px GIME
* field with a 20px black border each side. 20px = exactly 5 bytes, so every X is
* offset +20px (+5 bytes): CoCo3_X = Apple_X + 20; content region = bytes 5..74
* (X 20..299); borders = bytes 0..4 (X 0..19) and 75..79 (X 300..319).
*
* Per-cel placement (CoCo3 byte col = (Apple_X+20)>>2, sub-byte = (Apple_X+20)&3, row = Y):
*   $A9E2 base  AppleX84  ->X104 Y108 -> byte 26 sub 0
*   $A9B8       AppleX105 ->X125 Y100 -> byte 31 sub 1
*   $A976       AppleX112 ->X132 Y92  -> byte 33 sub 0
*   $A948 peak  AppleX126 ->X146 Y81  -> byte 36 sub 2   (drawn last = on top, §3)
*   $AA11 floor tiled across the content region (bytes 5..74), overpaints lower Fuji (§3)
*
* Cels are the Stage-0 Jay-hue-gated content/background/ assets — rendered AS-IS,
* no re-flip (HS-8). SKY = BLUE (index 2), the oracle-faithful $0A00 fill ($11=$AA
* pattern = index-2 on the CoCo3); Jay's gate ruling 2026-07-12. Filled rows 0-103
* (above the floor line) before the Fuji blits so the Fuji's transparent (index-0)
* pixels show blue sky and the white snow caps stand out.
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
        * GIME border left BLACK (default) — the black top/bottom band is the
        * hardware display border, intentionally not filled. [Jay gate]

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
        * sky fill FIRST: rows 0-103, content region bytes 5-74 (X20-299) = blue
        jsr     fill_sky
        * base $A9E2  X104 (Apple84+20)  Y108  byte 26 sub 0
        clr     <blit_subbyte
        lda     #26
        ldb     #108
        ldx     #scene6_bg_A9E2
        jsr     HAL_gfx_blit_sprite
        * $A9B8  X125 (Apple105+20)  Y100  byte 31 sub 1
        lda     #1
        sta     <blit_subbyte
        lda     #31
        ldb     #100
        ldx     #scene6_bg_A9B8
        jsr     HAL_gfx_blit_sprite
        * $A976  X132 (Apple112+20)  Y92  byte 33 sub 0
        clr     <blit_subbyte
        lda     #33
        ldb     #92
        ldx     #scene6_bg_A976
        jsr     HAL_gfx_blit_sprite
        * peak $A948  X146 (Apple126+20)  Y81  byte 36 sub 2  (last = on top)
        lda     #2
        sta     <blit_subbyte
        lda     #36
        ldb     #81
        ldx     #scene6_bg_A948
        jsr     HAL_gfx_blit_sprite
        * floor line: tile $AA11 (4 bytes wide) across at Y104
        jsr     draw_floor_line
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
