* src/engine/scene4_scroll.s
*
* R-p26 (v3): scene-4 scrolling-narrative port — GIME VOFFSET sliding-window
* scroll with AMORTIZED memmove-on-wrap (Jay's option-1 ruling; 6809 only).
* Fits stock 128 KB.
*
* ORIGIN: Apple II routine_b833 (intro.s) — scroll of the 18 narrative
*   line-slots (text_strings.s idx 4..21; 16 text + 2 blank paragraph
*   breaks). Recon parameters (UNCHANGED): VOFFSET += 20/step (= 2
*   scanlines; 10 units/scanline), 14-scanline line spacing, VSCROL=0.
*
* MECHANISM (single-zone buffer + continuous copy-down — replaces v2's
* duplicate-zone ring, which needed ~2L and collided with the $FF00 GIME
* I/O ceiling):
*   Buffer region $8000-$FBFF+ (physical $78000+), row p at $8000+p*80,
*   VOFFSET(p) = $F000 + 10*p. The window (W=192) scrolls DOWN by raising
*   VOFFSET top 0 -> SHIFT(=192); lines render just below the window as they
*   approach (s4_base = logical row of buffer row 0). When top reaches
*   SHIFT the displayed strip [SHIFT, SHIFT+W) has ALREADY been copied to
*   [0, W) — done incrementally, 2 rows per step into the just-scrolled-off
*   region [0, top) (never touching displayed rows) — so resetting top->0
*   (base += SHIFT) is pixel-identical and seamless. Max row touched ~395
*   ($FB30) — clears the $FF00 ceiling.
*   Copy cost: 2 rows = 160 bytes ~= 880 cycles/step (<5% of a frame). No
*   single-frame stall (the v2 HS-1 requirement).
*
* REFILL: a line-slot is due when its logical top <= base + top + W; it is
*   cleared+rendered at buffer row (logical_top - base). T0 places slot 0 at
*   the window bottom at start (enters from below). Blank slots / the tail
*   are just cleared.
*
* [ref: docs/conventions.md §19 coord map; §22.4b extents/xstep]
* [ref: docs/project-state.md §R-p26 — v2 hard-stop + this v3 design]
* [ref: src/hal/coco3-dsk/gfx.s HAL_gfx_blit_scroll — full-region blit]
* [ref: src/engine/scene4_text.s — GENERATED per-line glyph tables]
* ---------------------------------------------------------------

        setdp   0

* --- scroll constants ---
S4_LINE_H       equ     14              ; line spacing (scanlines)
S4_WINDOW       equ     192             ; visible window height (rows)
S4_SHIFT        equ     192             ; wrap shift = window (top range 0..SHIFT)
S4_T0           equ     178             ; logical top of slot 0 (enters at window bottom)
S4_SMAX         equ     400             ; scroll-complete logical pos (base+top); tunable @ gate
S4_KFRAMES      equ     3               ; VBL frames per 2px step (scroll rate; tunable)
S4_VOFF_BASE    equ     $F000           ; VOFFSET for buffer row 0 ($78000/8)
S4_SRC_OFF      equ     $3C00           ; copy source offset = SHIFT*80 = 192*80 bytes

* s4_scroll_s ($62/$63) is reused as s4_top (the VOFFSET display row, 0..SHIFT).
s4_top          equ     s4_scroll_s

* ===============================================================
* scene4_scroll — scene-4 narrative scroll (amortized memmove-on-wrap).
* Returns: CC.C set  = input detected (caller -> pressed early-break);
*          CC.C clear = scroll completed (caller -> scene-4->5 cut halt).
* Clobbers: A,B,X,Y,U,CC and the s4_* DP scratch.
* ===============================================================
scene4_scroll:
        ; --- clear the whole buffer region $8000-$FC00 ---
        ldx     #$8000
        ldd     #$0000
s4_clr:
        std     ,x++
        cmpx    #$FC00
        blo     s4_clr

        ; --- init state ---
        ldd     #$0000
        std     <s4_top                 ; top = 0
        std     <s4_base                ; base = 0
        std     <s4_copy_i              ; copy_i = 0
        ldd     #S4_T0
        std     <s4_next_top            ; next line logical top = T0
        clr     <s4_next_slot           ; next slot = 0

        ldd     #S4_VOFF_BASE
        std     $FF9D                   ; VOFFSET = row 0

        jsr     s4_refill               ; pre-render the slot(s) due at start

* --- main scroll loop ---
s4_loop:
        lda     #S4_KFRAMES
        sta     <s4_kcount
s4_frame:
        jsr     HAL_time_vbl_wait
        jsr     HAL_input_poll
        bcs     s4_input
        dec     <s4_kcount
        bne     s4_frame

        ; advance: top += 2
        ldd     <s4_top
        addd    #2
        std     <s4_top

        ; wrap? top reached SHIFT -> strip already copied; rebase
        cmpd    #S4_SHIFT
        blo     s4_no_wrap
        jsr     s4_finish_copy          ; ensure copy_i == SHIFT (strip relocated)
        ldd     <s4_top
        subd    #S4_SHIFT
        std     <s4_top                 ; top -= SHIFT (-> 0)
        ldd     <s4_base
        addd    #S4_SHIFT
        std     <s4_base                ; base += SHIFT
        ldd     #$0000
        std     <s4_copy_i              ; restart copy for the new cycle
s4_no_wrap:

        ; done? base + top >= SMAX
        ldd     <s4_base
        addd    <s4_top
        cmpd    #S4_SMAX
        bhs     s4_done

        jsr     s4_set_voffset          ; VOFFSET = base_off + 10*top
        jsr     s4_refill               ; render newly-due lines below the window
        jsr     s4_copy_step            ; copy-down freed rows (catch copy_i up to top)
        bra     s4_loop

s4_done:
        andcc   #$FE                    ; CC.C clear = completed
        rts
s4_input:
        orcc    #$01                    ; CC.C set = input during scroll
        rts

* ===============================================================
* s4_refill — render every line-slot now due (logical top <= base+top+W),
*   at buffer row (logical_top - base). Past the 18 slots, clears tail bands.
* ===============================================================
s4_refill:
s4_rf_loop:
        ; stop if next_top > SMAX + W
        ldd     <s4_next_top
        cmpd    #(S4_SMAX+S4_WINDOW)
        bhi     s4_rf_done
        ; due test: next_top <= base + top + W
        ldd     <s4_base
        addd    <s4_top
        addd    #S4_WINDOW              ; D = base+top+W (threshold)
        cmpd    <s4_next_top
        blo     s4_rf_done              ; threshold < next_top -> not due
        ; buffer row = next_top - base
        ldd     <s4_next_top
        subd    <s4_base
        std     <s4_dest_row            ; buffer row for this line
        jsr     s4_render_band
        ldd     <s4_next_top
        addd    #S4_LINE_H
        std     <s4_next_top
        inc     <s4_next_slot
        bra     s4_rf_loop
s4_rf_done:
        rts

* ===============================================================
* s4_render_band — clear the 14-row band at s4_dest_row, then (if next_slot
*   is a real text slot) blit that slot's glyph line there.
* ===============================================================
s4_render_band:
        jsr     s4_clear_band           ; clear 14 rows at s4_dest_row
        lda     <s4_next_slot
        cmpa    #S4_SLOT_COUNT          ; 18
        bhs     s4_band_done            ; tail -> blank only
        ldb     <s4_next_slot
        lda     #3
        mul                             ; D = slot*3
        ldx     #s4_slots
        leax    d,x                     ; X -> {fdb ptr; fcb count}
        ldb     2,x                     ; B = count
        beq     s4_band_done            ; blank paragraph-break slot
        ldu     ,x                      ; U = line table ptr
        jsr     s4_blit_line            ; renders at s4_dest_row
s4_band_done:
        rts

* ===============================================================
* s4_blit_line — blit a packed line table at row s4_dest_row.
*   U = table {fdb addr; fcb byte_col, subbyte} ; B = glyph count.
* ===============================================================
s4_blit_line:
s4_bl_loop:
        pshs    b
        ldx     ,u++                    ; glyph addr
        lda     ,u+                     ; byte column
        ldb     ,u+                     ; sub-byte
        stb     <blit_subbyte
        jsr     HAL_gfx_blit_scroll     ; X=addr A=col, dest=s4_dest_row; preserves U
        puls    b
        decb
        bne     s4_bl_loop
        rts

* ===============================================================
* s4_clear_band — zero S4_LINE_H (14) rows * 80 bytes at s4_dest_row.
* ===============================================================
s4_clear_band:
        lda     #80
        ldb     <s4_dest_row+1
        mul                             ; D = row_lo * 80
        ldx     <s4_dest_row
        cmpx    #256
        blo     s4_cb_base
        addd    #$5000                  ; row_hi(=1) * 80 << 8
s4_cb_base:
        addd    #$8000
        tfr     d,x
        ldy     #(S4_LINE_H*80/2)       ; 560 word stores = 14 rows
        ldd     #$0000
s4_cb_loop:
        std     ,x++
        leay    -1,y
        bne     s4_cb_loop
        rts

* ===============================================================
* s4_copy_step — copy freed rows down: while copy_i < top, copy buffer row
*   (SHIFT+copy_i) -> row (copy_i). Each row is 80 bytes; src = dst+SHIFT*80.
*   Rows [0,top) are scrolled off (above the window) so writing them is
*   invisible; the source rows are rendered+stable. Amortized (2 rows/step).
* ===============================================================
s4_copy_step:
s4_cs_loop:
        ldd     <s4_copy_i
        cmpd    <s4_top
        bhs     s4_cs_done              ; copy_i >= top -> caught up
        jsr     s4_copy_one_row
        ldd     <s4_copy_i
        addd    #1
        std     <s4_copy_i
        bra     s4_cs_loop
s4_cs_done:
        rts

* s4_finish_copy — copy any remaining rows up to SHIFT (called at wrap).
s4_finish_copy:
s4_fc_loop:
        ldd     <s4_copy_i
        cmpd    #S4_SHIFT
        bhs     s4_fc_done
        jsr     s4_copy_one_row
        ldd     <s4_copy_i
        addd    #1
        std     <s4_copy_i
        bra     s4_fc_loop
s4_fc_done:
        rts

* s4_copy_one_row — copy row s4_copy_i: dst=$8000+copy_i*80, src=dst+SHIFT*80.
* copy_i <= SHIFT (192) < 256, so copy_i*80 via 8x8 mul. 80 bytes = 40 words.
s4_copy_one_row:
        lda     #80
        ldb     <s4_copy_i+1            ; copy_i low byte (copy_i < 256)
        mul                             ; D = copy_i * 80
        addd    #$8000
        tfr     d,x                     ; X = dst row addr
        leay    S4_SRC_OFF,x            ; Y = src = dst + 192*80
        lda     #40                     ; 40 words = 80 bytes
        sta     <s4_ctmp                ; count in MEMORY — ldd ,y++ clobbers B
s4_cor_loop:
        ldd     ,y++
        std     ,x++
        dec     <s4_ctmp
        bne     s4_cor_loop
        rts

* ===============================================================
* s4_set_voffset — VOFFSET = $F000 + 10 * top  (top = 0..SHIFT).
* ===============================================================
s4_set_voffset:
        ldd     <s4_top                 ; top (0..192)
        ; D*10 = D*2 + D*8
        lslb
        rola                            ; top*2
        pshs    d
        lslb
        rola                            ; top*4
        lslb
        rola                            ; top*8
        addd    ,s++                    ; + top*2 = top*10
        addd    #S4_VOFF_BASE
        std     $FF9D
        rts

* ---------------------------------------------------------------
* Scene-4 text tables (GENERATED) + Wave-3 glyph content includes.
* (Other 16 letters included by broderbund_scene.s / intro_scenes.s.)
* ---------------------------------------------------------------
        include "scene4_text.s"

        include "../../content/glyph_f/converted.s"
        include "../../content/glyph_i/converted.s"
        include "../../content/glyph_k/converted.s"
        include "../../content/glyph_l/converted.s"
        include "../../content/glyph_u/converted.s"
        include "../../content/glyph_v/converted.s"
        include "../../content/glyph_w/converted.s"
        include "../../content/glyph_period/converted.s"
        include "../../content/glyph_comma/converted.s"
        include "../../content/glyph_colon/converted.s"
        include "../../content/glyph_hyphen/converted.s"
