* src/engine/scene4_scroll.s
*
* R-p26: scene-4 scrolling-narrative port — GIME VOFFSET sliding-window
* scroll (option 2: ring buffer + per-line off-screen refill).
*
* *** HELD — NOT IN THE PRODUCTION BUILD (boot.s halts at the scene-3->4
*     cut). This duplicate-zone ring does NOT fit stock 128 KB: a seamless
*     ring needs period L >= window + line_height = 192+14 = 206 (so the
*     entering line's wrapped real-copy clears the window top — otherwise
*     it spills in, the corruption observed at S~60), and the duplicate
*     zone doubles the footprint to ~2L rows whose top band-clear must stay
*     below the GIME I/O at $FF00 (~row 405). 2L<=405 AND L>=206 is a
*     contradiction (412>405) — the combined buffers (392 rows) are ~10-14
*     rows too small, and enlarging the ring collides with $FF00.
*     The bake (scene4_text.s), the full-region blit (HAL_gfx_blit_scroll),
*     the refill/voffset/clear-band structure below, and the legible text
*     output are all VALIDATED; only the duplicate-zone ring geometry is
*     infeasible here. Awaiting an orchestrator ruling on the buffer
*     architecture (memmove-on-wrap variant = ~L footprint at a per-wrap
*     copy cost; or lower-bank buffer; or 512 KB). See R-p26 v2 report. ***
*
* Original intent: uses the two combined display buffers ($8000-$FBFF =
* ~392 rows; legal because the display is single-buffered per R-p25).
*
* ORIGIN: Apple II routine_b833 (intro.s) — 224-pass scroll of the 18
*   narrative line-slots (text_strings.s idx 4..21; 16 text + 2 blank
*   paragraph breaks). Per the GIME-scroll feasibility verdict + Jay's
*   case-(2) ruling. Recon parameters (UNCHANGED): VOFFSET += 20/step
*   (= 2 scanlines; 10 units/scanline), 14-scanline line spacing, VSCROL=0.
*
* RING MODEL (the option-2 mechanism):
*   Buffer region = $8000-$FBFF (physical $78000-$7FBFF), row p at
*   $8000+p*80, VOFFSET(p) = $F000 + 10*p.  Ring period L = 196 (= 14*14,
*   line-aligned so lines never straddle the seam); window W = 192;
*   duplicate zone [196,392) mirrors [0,196).  Logical scroll row r lives
*   at physical (r mod 196); whenever a band is written at phys<196 it is
*   ALSO written at phys+196, so the window stays continuous across the
*   wrap and a VOFFSET reset (top L->0) shows identical pixels.
*   Each 14-row band is CLEARED before (re)render, which both blanks the
*   2 paragraph-break slots and the scroll tail, and prevents stale ring
*   content reappearing as rows recycle.
*
* REFILL: a new line-slot is due when its logical top <= S + W; it is
*   rendered into physical (top mod 196) (+ duplicate) just before it
*   enters the window bottom. T0=182 places slot 0 at the window bottom at
*   S=0 (enters from below, oracle-faithful). Refill continues past the 18
*   slots with blank-clears (the tail).
*
* [ref: docs/conventions.md §19 coord map; §22.4b extents/xstep]
* [ref: docs/memory-map.md §3.2 128K MMU — combined buffers $78000-$7FBFF]
* [ref: src/hal/coco3-dsk/gfx.s HAL_gfx_blit_scroll — full-region blit]
* [ref: src/engine/scene4_text.s — GENERATED per-line glyph tables]
* ---------------------------------------------------------------

        setdp   0

* --- scroll constants ---
S4_LINE_H       equ     14              ; line spacing (scanlines)
S4_WINDOW       equ     192             ; visible window height (rows)
S4_RING         equ     196             ; ring period (= 14*14, line-aligned)
S4_DUP          equ     196             ; duplicate-zone offset (= ring period)
S4_T0           equ     182             ; logical top of slot 0 (enters at window bottom)
S4_SMAX         equ     400             ; scroll-complete position (rows); tunable @ gate
S4_KFRAMES      equ     3               ; VBL frames per 2px step (scroll rate; tunable)
S4_VOFF_BASE    equ     $F000           ; VOFFSET for physical row 0 ($78000/8)

* ===============================================================
* scene4_scroll — the scene-4 narrative scroll.
*   Clears the ring region, pre-renders the first slot, then scrolls
*   VOFFSET upward (+20/step) under real VBL, refilling lines off-screen
*   and polling input each frame.
* Returns: CC.C set  = input detected (caller -> pressed early-break);
*          CC.C clear = scroll completed (caller -> scene-4->5 cut halt).
* Clobbers: A,B,X,Y,U,CC and the s4_* DP scratch.
* ===============================================================
scene4_scroll:
        ; --- clear the whole ring region $8000-$FBFF ---
        ldx     #$8000
        ldd     #$0000
s4_clr:
        std     ,x++
        cmpx    #$FC00
        blo     s4_clr

        ; --- init scroll state ---
        ldd     #$0000
        std     <s4_scroll_s            ; S = 0
        ldd     #S4_T0
        std     <s4_next_top            ; next line top = T0 (182)
        clr     <s4_next_slot           ; next slot = 0

        ; --- VOFFSET = physical row 0 ---
        ldd     #S4_VOFF_BASE
        std     $FF9D                   ; $FF9D=hi, $FF9E=lo

        ; --- pre-render the slot(s) already due at S=0 ---
        jsr     s4_refill

* --- main scroll loop ---
s4_loop:
        lda     #S4_KFRAMES
        sta     <s4_kcount
s4_frame:
        jsr     HAL_time_vbl_wait       ; 1 real-VBL frame
        jsr     HAL_input_poll          ; CC.C = input present
        bcs     s4_input                ; press -> early break
        dec     <s4_kcount
        bne     s4_frame

        ; advance scroll S += 2 (= 2 scanlines)
        ldd     <s4_scroll_s
        addd    #2
        std     <s4_scroll_s
        cmpd    #S4_SMAX
        bhs     s4_done                 ; reached scroll end

        jsr     s4_set_voffset          ; VOFFSET = base + 10*(S mod 196)
        jsr     s4_refill               ; render any newly-due lines off-screen
        bra     s4_loop

s4_done:
        andcc   #$FE                    ; CC.C clear = completed, no input
        rts
s4_input:
        orcc    #$01                    ; CC.C set = input during scroll
        rts

* ===============================================================
* s4_refill — render every line-slot now due (logical top <= S + W) into
*   the ring (+ duplicate), advancing next_slot/next_top. Past the 18
*   real slots, renders blank-clears (the scroll tail).
* ===============================================================
s4_refill:
s4_rf_loop:
        ; stop if next_top > SMAX + W (nothing more will ever show)
        ldd     <s4_next_top
        cmpd    #(S4_SMAX+S4_WINDOW)
        bhi     s4_rf_done
        ; due test: render while next_top <= S + W
        ldd     <s4_scroll_s
        addd    #S4_WINDOW              ; D = threshold (S + W)
        cmpd    <s4_next_top            ; threshold - next_top
        blo     s4_rf_done              ; threshold < next_top -> not yet due
        jsr     s4_render_band
        ldd     <s4_next_top
        addd    #S4_LINE_H
        std     <s4_next_top
        inc     <s4_next_slot
        bra     s4_rf_loop
s4_rf_done:
        rts

* ===============================================================
* s4_render_band — clear the 14-row band at (next_top mod 196) and its
*   duplicate at +196, then (if next_slot is a real text slot) blit that
*   slot's glyph line at both rows.
* ===============================================================
s4_render_band:
        ; phys = next_top mod 196
        ldd     <s4_next_top
s4_rb_mod:
        cmpd    #S4_RING
        blo     s4_rb_modd
        subd    #S4_RING
        bra     s4_rb_mod
s4_rb_modd:
        std     <s4_phys                ; phys (0..195)

        ; clear band at phys
        std     <s4_dest_row
        jsr     s4_clear_band
        ; clear duplicate band at phys+196
        ldd     <s4_phys
        addd    #S4_DUP
        std     <s4_dest_row
        jsr     s4_clear_band

        ; tail (no real slot left) -> blank only
        lda     <s4_next_slot
        cmpa    #S4_SLOT_COUNT          ; 18
        bhs     s4_rb_done

        ; look up slot entry: s4_slots + next_slot*3  -> {fdb ptr; fcb count}
        ldb     <s4_next_slot
        lda     #3
        mul                             ; D = next_slot*3
        ldx     #s4_slots
        leax    d,x
        ldb     2,x                     ; B = glyph count
        beq     s4_rb_done              ; blank paragraph-break slot

        ; pass 1 — render line at phys
        ldu     ,x                      ; U = line table ptr
        ldd     <s4_phys
        std     <s4_dest_row
        jsr     s4_blit_line            ; consumes U, B

        ; pass 2 — render line at phys + 196 (duplicate)
        ldb     <s4_next_slot
        lda     #3
        mul
        ldx     #s4_slots
        leax    d,x
        ldb     2,x
        ldu     ,x
        ldd     <s4_phys
        addd    #S4_DUP
        std     <s4_dest_row
        jsr     s4_blit_line
s4_rb_done:
        rts

* ===============================================================
* s4_blit_line — blit a packed line table at row s4_dest_row.
*   U = table {fdb addr; fcb byte_col, subbyte} ; B = glyph count.
*   HAL_gfx_blit_scroll preserves U, so the table walks cleanly.
* ===============================================================
s4_blit_line:
s4_bl_loop:
        pshs    b                       ; save count
        ldx     ,u++                    ; X = glyph addr
        lda     ,u+                     ; A = byte column
        ldb     ,u+                     ; B = sub-byte
        stb     <blit_subbyte
        jsr     HAL_gfx_blit_scroll     ; X=addr A=col, dest=s4_dest_row; preserves U
        puls    b                       ; restore count
        decb
        bne     s4_bl_loop
        rts

* ===============================================================
* s4_clear_band — zero S4_LINE_H (14) rows * 80 bytes at s4_dest_row.
*   dest = $8000 + s4_dest_row*80.
* ===============================================================
s4_clear_band:
        lda     #80
        ldb     <s4_dest_row+1          ; row low byte
        mul                             ; D = row_lo * 80
        ldx     <s4_dest_row            ; full 16-bit row
        cmpx    #256
        blo     s4_cb_base
        addd    #$5000                  ; row_hi(=1) * 80 << 8
s4_cb_base:
        addd    #$8000
        tfr     d,x                     ; X = dest addr
        ldy     #(S4_LINE_H*80/2)       ; 560 word stores = 1120 bytes (14 rows)
        ldd     #$0000
s4_cb_loop:
        std     ,x++
        leay    -1,y
        bne     s4_cb_loop
        rts

* ===============================================================
* s4_set_voffset — VOFFSET = $F000 + 10 * (S mod 196).
*   10 VOFFSET units = 1 scanline (80-byte row / 8).
* ===============================================================
s4_set_voffset:
        ldd     <s4_scroll_s
s4_sv_mod:
        cmpd    #S4_RING
        blo     s4_sv_modd
        subd    #S4_RING
        bra     s4_sv_mod
s4_sv_modd:
        ; D = S mod 196 (0..195). compute D*10 = D*2 + D*8.
        lslb
        rola                            ; D = row*2
        pshs    d                       ; tmp = row*2
        lslb
        rola                            ; row*4
        lslb
        rola                            ; row*8
        addd    ,s++                    ; + row*2 = row*10
        addd    #S4_VOFF_BASE           ; + base VOFFSET
        std     $FF9D                   ; write VOFFSET
        rts

* ---------------------------------------------------------------
* Scene-4 text tables (GENERATED) + Wave-3 glyph content includes.
* The other 16 letters are included by broderbund_scene.s (e,n,r,p,s,t)
* and intro_scenes.s (a,b,c,d,g,h,j,m,o,y); these 11 are Wave-3-only.
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
