* tests/scripted/scene6_walk_scrollA_driver.s
*
* WALK BUILD — STAGE A: the $52-driven mid-ground scroll (FIRST build of the fight arc).
* Sandbox, boot-excluded. Technique (b) SOFTWARE PARTIAL RE-BLIT of the mid-ground band —
* NOT scene4_scroll's VOFFSET (that is vertical/whole-screen; a layered horizontal scroll
* with Fuji FIXED needs the band re-blit). Single engine (HAL_gfx_blit_sprite_opaque); no
* scene-local blit. Prod ROM ($88eba89...) untouched (src production paths unchanged).
*
* MECHANIC (scroll recon, settled): $52 is the GLOBAL scene scroll; the mid-ground translates
*   at col = $52 - offset. Here $52 is driven by a SCRIPTED sweep 30->1B (NO player yet =
*   Stage B). Port shift = ($30 - $52) columns LEFT (0..21); each mid-ground cel is re-blitted
*   at (base_col - shift), GROUP-LOCKED. Fuji ($A9) is in the FIXED substrate and is NOT
*   re-blitted -> stays put (layered for free). $52+xadj fight scenery = Stage C (blocked).
*
* PER-STEP (b): restore the mid-ground band (rows 100-111) from a clean snapshot (which
*   INCLUDES Fuji's pixels, so Fuji is preserved), re-blit the mid-ground posts at the shifted
*   col, present, flip. Slow cadence (HOLD frames/step) -> the costly composite fires once per
*   HOLD frames; hold frames are a bare VBL wait (no redraw/flip).
*   MEASURED (coco3 @1.78MHz, scrollA_measure.lua): 11.29 ms/step worst-case -> FITS one 16.68 ms
*   VBL (~5.4 ms margin). The 24-row band (posts + AB structure) measured 21.9 ms => EXCEEDED
*   VBL, so cut 1 scopes the band to the 12 post rows; extending it needs the amortized/bbox
*   restore (spread the composite across the HOLD frames, or restore only the thin post bboxes).
*
* SCOPE (cut 1, documented): scrolls the 6 wall-top posts (AA31 back x3 + AA23 front x3),
*   GROUP-LOCKED, over a FIXED sky+Fuji substrate. The AB structure (AB4A/AB7C/AB94), the
*   cliff-FACE hand-fill striations, and the AA7D base are DEFERRED (budget: they extend the
*   band past the 12-row VBL-fit; add them with the amortized/bbox restore). The back posts
*   (AA31) draw on top of Fuji (minor overlap) rather than behind it (correct layering needs a
*   Fuji redraw between the post layers — deferred with the budget refinement).
*
* Build: lwasm --decb -o tests/scripted/scene6_walk_scrollA_driver.bin \
*              tests/scripted/scene6_walk_scrollA_driver.s
* Gate: Jay live MAME (25.3-M) — the mid-ground translates per col=$52-offset, group-locked,
*   Fuji fixed, across the 30->1B sweep, matching the oracle's sweep.
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
        rti                             ; $010C IRQ -> hal_vbl_handler
        nop
        nop
        rti
        nop
        nop

        org     $0200
        setdp   0
        include "../../src/engine/globals.s"

* --- Stage-A constants ---
SA_BAND_ROW     equ     100             ; mid-ground band top row
SA_BAND_ROWS    equ     12              ; rows 100..111 (wall-top posts) — budget-scoped (see report)
SA_BAND_LEN     equ     SA_BAND_ROWS*80 ; 960 bytes (12 rows) per band
SA_A_BAND       equ     $8000+SA_BAND_ROW*80    ; buffer A band base ($9F40)
SA_B_BAND       equ     $C000+SA_BAND_ROW*80    ; buffer B band base ($DF40)
SA_S52_HI       equ     $30             ; sweep start (climb hold value)
SA_S52_LO       equ     $1B             ; sweep end
SA_HOLD         equ     16              ; VBL frames per $52 step (~oracle 1 col / 16 frames)
PAGE_TOGGLE     equ     PAGE_A_TOKEN!PAGE_B_TOKEN   ; $20 xor $40 = $60 (toggles A<->B)

test_start:
        orcc    #$50
        lds     #$01FF
        clra
        tfr     a,dp

        jsr     HAL_sys_init
        jsr     HAL_time_init
        lda     #$00
        jsr     HAL_gfx_init            ; GIME 320x192x4
        lda     #PAL_SEL_DEFAULT
        sta     pal_select
        jsr     apply_palette

        lda     #PAGE_A_TOKEN
        sta     <page_register
        andcc   #$EF                    ; enable IRQ (VBL frame sync)

        * --- FIXED substrate -> buffer A: sky + wall-top band + Fuji (NO mid-ground) ---
        jsr     fill_sky
        jsr     fill_walltop
        jsr     draw_fuji_cels
        jsr     draw_hud_player
        jsr     copy_a_to_b             ; both buffers carry the clean substrate

        * --- snapshot the CLEAN band (from A; includes Fuji pixels) ---
        jsr     snapshot_band

sweep_restart:
        lda     #SA_S52_HI
        sta     cur52
sweep_loop:
        lda     #SA_S52_HI
        suba    cur52
        sta     scroll_shift            ; shift = $30 - $52 (0..21, cols LEFT)

        jsr     restore_band            ; back-buffer band <- clean snapshot (Fuji preserved)
        jsr     draw_mg_shifted         ; re-blit mid-ground at (col - shift), group-locked
        jsr     HAL_gfx_present         ; reveal the back buffer
        lda     <page_register          ; toggle draw target for the next step
        eora    #PAGE_TOGGLE
        sta     <page_register

        ldx     #SA_HOLD                ; hold this $52 for SA_HOLD VBL frames (no redraw/flip)
sa_hold:
        jsr     HAL_time_vbl_wait
        leax    -1,x
        bne     sa_hold

        dec     cur52
        lda     cur52
        cmpa    #SA_S52_LO
        bhs     sweep_loop              ; while $52 >= $1B
        bra     sweep_restart           ; loop the sweep (continuous viewing)

* ---------------------------------------------------------------
* snapshot_band — copy the clean band (buffer A, rows 100-111) into scroll_save.
* ---------------------------------------------------------------
snapshot_band:
        ldx     #SA_A_BAND
        ldy     #scroll_save
snb_l:
        ldd     ,x++
        std     ,y++
        cmpx    #SA_A_BAND+SA_BAND_LEN
        blo     snb_l
        rts

* ---------------------------------------------------------------
* restore_band — copy scroll_save into the BACK buffer's band (page_register selects A/B).
* ---------------------------------------------------------------
restore_band:
        ldx     #scroll_save
        lda     <page_register
        cmpa    #PAGE_A_TOKEN
        bne     rb_useb
        ldu     #SA_A_BAND
        bra     rb_l
rb_useb:
        ldu     #SA_B_BAND
rb_l:
        ldd     ,x++
        std     ,u++
        cmpx    #scroll_save+SA_BAND_LEN
        blo     rb_l
        rts

* ---------------------------------------------------------------
* draw_mg_shifted — re-blit each mid-ground cel at (base_col - scroll_shift).
*   Skips a cel whose col goes off the left edge (col < shift). Opaque blit (black solid).
* ---------------------------------------------------------------
draw_mg_shifted:
        ldy     #mg_tbl
dmg_l:
        ldx     ,y++                    ; X = cel ptr (0 = end)
        beq     dmg_done
        lda     ,y+                     ; sub-byte
        sta     <blit_subbyte
        lda     ,y+                     ; base byte col
        ldb     ,y+                     ; row (B for blit)
        suba    scroll_shift            ; A = col - shift
        bcs     dmg_l                   ; borrow -> off left edge, skip
        pshs    y
        jsr     HAL_gfx_blit_sprite_opaque
        puls    y
        bra     dmg_l
dmg_done:
        rts

* copy buffer A ($8000-$BBFF) -> buffer B ($C000-...) so both carry the substrate.
copy_a_to_b:
        ldx     #$8000
        ldy     #$C000
cab_l:
        ldd     ,x++
        std     ,y++
        cmpx    #$BC00
        blo     cab_l
        rts

* mid-ground cel table (scrolls as a group): back posts (AA31) + front posts (AA23) + AB
*   structure. Format per row: fdb cel ; fcb subbyte, base_col, row. (0 = end.)
mg_tbl:
        fdb     scene6_cliff_AA31
        fcb     0,24,100
        fdb     scene6_cliff_AA31
        fcb     0,45,100
        fdb     scene6_cliff_AA31
        fcb     0,66,100
        fdb     scene6_cliff_AA23
        fcb     0,25,100
        fdb     scene6_cliff_AA23
        fcb     0,46,100
        fdb     scene6_cliff_AA23
        fcb     0,67,100
        fdb     0                       ; end
* NOTE (cut 1): AB4A/AB7C/AB94 structure + cliff-face + AA7D base deferred — they extend
*   below the 12-row post band; adding them needs the amortized/bbox restore (see report).

* --- Stage-A state ---
cur52           fcb     SA_S52_HI       ; current scripted $52 (sweep 30->1B)
scroll_shift    fcb     0               ; $30 - $52 (columns to shift LEFT)
scroll_save     rmb     SA_BAND_LEN     ; clean band snapshot (1920 bytes)

* --- HAL + shared substrate + cliff cels (single source) ---
        include "../../src/hal/coco3-dsk/sys.s"
        include "../../src/hal/coco3-dsk/irq_vbl.s"
        include "../../src/hal/coco3-dsk/gfx.s"
        include "../../src/hal/coco3-dsk/time.s"

        include "scene6_backdrop.s"
        include "scene6_cliff.s"
        include "scene6_hud.s"

* palette (Jay-gated index-selected; overrides prod default WITHOUT touching gfx.s prod) ---
        ifndef  PAL_SEL_DEFAULT
PAL_SEL_DEFAULT equ 1
        endc
apply_palette:
        lda     pal_select
        ldb     #4
        mul
        ldx     #palette_sets
        leax    d,x
        ldy     #$FFB0
        ldb     #4
aph_loop:
        lda     ,x+
        sta     ,y+
        decb
        bne     aph_loop
        rts
pal_select:
        fcb     PAL_SEL_DEFAULT
palette_sets:
        fcb     $00,$26,$2D,$3F         ; set 0 = COMPOSITE
        fcb     $00,$26,$19,$3F         ; set 1 = RGB

        end     test_start
