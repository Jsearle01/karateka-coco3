* src/engine/scene4_scroll.s
*
* R-p26 (B): scene-4 scrolling-narrative port — full FAITHFUL scroll via a
* tall pre-rendered buffer in the LOWER MEMORY BANK + pure GIME VOFFSET scroll.
* 6809; stock 128 KB.
*
* ORIGIN: Apple II routine_b833 (intro.s) — scroll of the 18 narrative
*   line-slots (text_strings.s idx 4..21; 16 text + 2 blank paragraph breaks).
*
* WHY (after v1-v4): the faithful scroll (line scrolls IN from the bottom,
*   OFF the top) needs ~636 contiguous rows (entry 192 + content 252 + exit
*   192) — more than the ~398-row display buffers. The lower bank ($60000-
*   $6FFFF, 64 KB, real RAM on 128 K) holds it. The GIME displays it via
*   VOFFSET=$C000 (verified by probe). Runtime is pure VOFFSET = perfectly
*   smooth (v4-proven). The CoCo3 8 KB-page vs 80-byte-row misalignment is
*   sidestepped: render lines in the display region (blit works there), then
*   BULK-COPY into the lower bank in MMU-window chunks (byte-aligned).
*
* BUILD (once, at scene-4 entry):
*   1. clear the lower-bank buffer ($60000-$6DFFF) via the $4000 MMU window.
*   2. render the 18 lines into the display region (rows 0..251) with the blit.
*   3. bulk-copy those 252 rows (20160 B) to lower-bank row 192 ($63C00),
*      chunked across MMU pages via the $4000 window.
*   => lower bank = blank[0,191] + content[192,443] + blank[444,635].
* SCROLL: VOFFSET = $C000 + 10*top, top 0..444, K frames/step, poll input.
*
* [ref: docs/conventions.md §19; §22.4b]  [ref: gfx.s HAL_gfx_blit_scroll]
* [ref: docs/memory-map.md §3 — 128K MMU / lower bank pages $30-$37]
* ---------------------------------------------------------------

        setdp   0

* --- constants ---
S4_LINE_H       equ     14              ; line spacing (scanlines)
S4_WINDOW       equ     192             ; visible window height
S4_ENTRY        equ     192             ; blank rows above content (scroll-in margin)
S4_SMAX         equ     444             ; final VOFFSET top row (content fully off top)
S4_STEP         equ     1               ; scanlines per step (1 = smooth)
S4_KFRAMES      equ     3               ; VBL frames per step (scroll rate; tunable)
S4_LB_VOFF      equ     $C000           ; VOFFSET for lower-bank row 0 ($60000/8)

* lower-bank scroll buffer geometry
S4_COPY_LEN     equ     20160           ; 252 content rows * 80 bytes
S4_COPY_PAGE    equ     $31             ; dest start page ($62000); $63C00 = page $31 + $1C00
S4_COPY_OFF     equ     $1C00           ; dest start offset within page $31

* MMU default page values (128K task 0) for restore
MMU_HAL_PAGE    equ     $3A             ; FFA2 default ($4000-$5FFF = HAL)

* DP scratch (build-time; free during the pure-VOFFSET scroll which uses only s4_top)
s4_top          equ     s4_scroll_s     ; $62/$63 — VOFFSET display row
s4_cpage        equ     s4_ctmp         ; $6E      — copy dest page (8-bit)
s4_coff         equ     s4_base         ; $6C/$6D  — copy dest offset within window
s4_clen         equ     s4_copy_i       ; $6A/$6B  — copy bytes remaining
s4_chunk        equ     s4_next_top      ; $64/$65 — copy chunk size

* ===============================================================
* scene4_scroll — build the lower-bank buffer, then VOFFSET-scroll it.
* Returns: CC.C set = input (caller -> pressed); CC.C clear = completed.
* ===============================================================
scene4_scroll:
        jsr     s4_clear_lb             ; clear lower-bank buffer
        jsr     s4_render_content       ; render 18 lines into display rows 0..251
        jsr     s4_copy_lb              ; bulk-copy content -> lower bank row 192

        ldd     #$0000
        std     <s4_top
        ldd     #S4_LB_VOFF
        std     $FF9D                   ; VOFFSET = lower-bank row 0 (entry blank)

s4_loop:
        lda     #S4_KFRAMES
        sta     <s4_kcount
s4_frame:
        jsr     HAL_time_vbl_wait
        jsr     HAL_input_poll
        bcs     s4_input
        dec     <s4_kcount
        bne     s4_frame

        ldd     <s4_top
        addd    #S4_STEP
        std     <s4_top
        cmpd    #S4_SMAX
        bhs     s4_done

        jsr     s4_set_voffset_lb
        bra     s4_loop

s4_done:
        andcc   #$FE
        rts
s4_input:
        orcc    #$01
        rts

* ===============================================================
* s4_clear_lb — zero lower-bank pages $30..$36 ($60000-$6DFFF) via the
*   $4000-$5FFF MMU window (8 KB at a time; below $FF00, fully writable).
* ===============================================================
s4_clear_lb:
        lda     #$30                    ; first lower-bank page
s4_clb_page:
        sta     $FFA2                   ; map $4000-$5FFF -> this page
        pshs    a
        ldx     #$4000
        ldd     #$0000
s4_clb_fill:
        std     ,x++
        cmpx    #$6000
        blo     s4_clb_fill
        puls    a
        inca
        cmpa    #$37                    ; pages $30..$36
        bls     s4_clb_page
        lda     #MMU_HAL_PAGE
        sta     $FFA2                   ; restore HAL window
        rts

* ===============================================================
* s4_render_content — clear display region, render all 18 line-slots into
*   display rows slot*14 (0..238) via the blit (display region; blit works).
* ===============================================================
s4_render_content:
        ; clear display $8000-$FE00 (render scratch)
        ldx     #$8000
        ldd     #$0000
s4_rc_clr:
        std     ,x++
        cmpx    #$FE00
        blo     s4_rc_clr
        ; render each text slot at display row slot*14
        clr     <s4_next_slot
s4_rc_loop:
        ldb     <s4_next_slot
        lda     #S4_LINE_H
        mul                             ; D = slot*14 = display row
        std     <s4_dest_row
        ldb     <s4_next_slot
        lda     #3
        mul                             ; slot*3
        ldx     #s4_slots
        leax    d,x
        ldb     2,x                     ; count
        beq     s4_rc_next              ; blank slot
        ldu     ,x
        jsr     s4_blit_line
s4_rc_next:
        inc     <s4_next_slot
        lda     <s4_next_slot
        cmpa    #S4_SLOT_COUNT
        blo     s4_rc_loop
        rts

* ===============================================================
* s4_copy_lb — bulk-copy S4_COPY_LEN bytes from display $8000 to the lower
*   bank starting at page S4_COPY_PAGE offset S4_COPY_OFF, chunked across
*   8 KB MMU pages via the $4000-$5FFF window. Byte copy (page/row-agnostic).
*   Source (display) stays mapped via FFA4-FFA7 (untouched); dest via FFA2.
* ===============================================================
s4_copy_lb:
        ldx     #$8000                  ; X = source (display), persists across chunks
        lda     #S4_COPY_PAGE
        sta     <s4_cpage
        ldd     #S4_COPY_OFF
        std     <s4_coff
        ldd     #S4_COPY_LEN
        std     <s4_clen
s4_cl_loop:
        ldd     <s4_clen
        beq     s4_cl_done
        ; chunk = min(clen, $2000 - coff)
        ldd     #$2000
        subd    <s4_coff                ; D = space remaining in this page
        ; if clen < D, chunk = clen else chunk = D
        cmpd    <s4_clen
        bls     s4_cl_havechunk         ; D <= clen -> chunk = D
        ldd     <s4_clen                ; else chunk = clen
s4_cl_havechunk:
        std     <s4_chunk
        ; map FFA2 = cpage ; dest window addr = $4000 + coff -> Y
        lda     <s4_cpage
        sta     $FFA2
        ldy     #$4000
        ldd     <s4_coff
        leay    d,y                     ; Y = $4000 + coff (dest in window)
        ; copy s4_chunk bytes from X (src) to Y (dest)
        ldd     <s4_chunk
s4_cl_copy:
        ; copy one byte (chunk may be odd; byte-granular)
        pshs    d
        lda     ,x+
        sta     ,y+
        puls    d
        subd    #1
        bne     s4_cl_copy
        ; advance: clen -= chunk ; cpage++ ; coff = 0 (next page starts at 0)
        ldd     <s4_clen
        subd    <s4_chunk
        std     <s4_clen
        inc     <s4_cpage
        ldd     #$0000
        std     <s4_coff
        bra     s4_cl_loop
s4_cl_done:
        lda     #MMU_HAL_PAGE
        sta     $FFA2                   ; restore HAL window
        rts

* ===============================================================
* s4_blit_line — blit a packed line table at row s4_dest_row (display region).
*   U = table {fdb addr; fcb byte_col, subbyte} ; B = glyph count.
* ===============================================================
s4_blit_line:
s4_bl_loop:
        pshs    b
        ldx     ,u++
        lda     ,u+
        ldb     ,u+
        stb     <blit_subbyte
        jsr     HAL_gfx_blit_scroll     ; X=addr A=col dest=s4_dest_row; preserves U
        puls    b
        decb
        bne     s4_bl_loop
        rts

* ===============================================================
* s4_set_voffset_lb — VOFFSET = $C000 + 10 * top.
* ===============================================================
s4_set_voffset_lb:
        ldd     <s4_top
        lslb
        rola                            ; top*2
        pshs    d
        lslb
        rola
        lslb
        rola                            ; top*8
        addd    ,s++                    ; + top*2 = top*10
        addd    #S4_LB_VOFF
        std     $FF9D
        rts

* ---------------------------------------------------------------
* Scene-4 text tables (GENERATED) + Wave-3 glyph content includes.
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
