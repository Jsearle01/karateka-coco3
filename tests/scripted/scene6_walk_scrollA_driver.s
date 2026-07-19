* tests/scripted/scene6_walk_scrollA_driver.s
*
* WALK BUILD — STAGE A (cut 3): the $52-driven mid-ground scroll (FIRST build of the fight arc).
* Sandbox, boot-excluded. Technique (b) SOFTWARE STRIP-SCROLL: draw the EXACT Jay-gated static
* climb tableau (gated wall-top + cliff-face + ground + base + Fuji), then scroll the whole
* mid-ground band as a horizontal strip (shifted copy from a snapshot), so EVERYTHING in the
* band — the RMW wall-top, the hand-fill floor, the base — translates together, group-locked.
* Fuji is redrawn FIXED on top each step (it overlaps the band). NOT scene4_scroll's VOFFSET,
* NOT the raster split (a). Single engine; no scene-local blit. Prod ROM ($88eba89...) untouched.
*
* MECHANIC (scroll recon, settled): $52 = GLOBAL scene scroll; mid-ground translates at
*   col = $52 - offset. $52 is a SCRIPTED sweep 30->1B (NO player = Stage B). Port shift =
*   ($30 - $52) cols LEFT (0..21); the strip-copy reads snapshot[c+shift] -> content moves LEFT
*   (player walks right => scenery scrolls left). Right edge edge-extends the snapshot col 79.
*
* WHY AMORTIZED: the full band (rows 100-180) shifted in one frame ~= 30 ms, over the 16.68 ms
*   VBL. The scroll steps once per SA_HOLD (16) frames and HOLDS between, so the strip-copy is
*   spread: 12 frames each strip ~7 rows into the BACK buffer (invisible), 1 frame redraws Fuji
*   fixed, 1 frame flips, 2 idle. Every frame < one VBL; the visible update is one flip per step.
*
* SUBSTRATE = the gated crawl tableau (Jay-gated 2026-07-12/16), single-source modules:
*   scene6_backdrop.s (sky/Fuji) + scene6_cliff_walltop.s (gated 3-post wall-top RMW + backwall
*   + AB4A/AA7D) + scene6_cliff_face.s (striations + ground) + scene6_hud.s.
*
* Build: lwasm --decb -o tests/scripted/scene6_walk_scrollA_driver.bin \
*              tests/scripted/scene6_walk_scrollA_driver.s
* Gate: Jay live MAME (25.3-M) — the gated mid-ground (wall-top + floor + base) translates
*   group-locked, LEFT, Fuji fixed, across the 30->1B sweep, matching the oracle.
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
SA_BAND_ROWS    equ     81              ; rows 100..180 (wall-top + cliff-face + ground + base)
SA_BAND_LEN     equ     SA_BAND_ROWS*80 ; 6480 bytes per band
SA_A_BAND       equ     $8000+SA_BAND_ROW*80    ; buffer A band base ($9F40)
SA_B_BAND       equ     $C000+SA_BAND_ROW*80    ; buffer B band base ($DF40)
SA_NCHUNK       equ     12              ; strip chunks (frames) per step
SA_RPC          equ     7               ; rows per chunk (7*12=84 >= 81)
WALL_L          equ     25              ; the wall/ground block's LEFT byte at shift 0. The cliff-face
                                        ;   striations (bytes <WALL_L, incl. byte 24 = the px99 black
                                        ;   wall-edge pixel) are a FIXED backdrop; the block slides
                                        ;   left over them and overwrites them (boundary = WALL_L-shift).
SA_HOLD         equ     16              ; frames/step (12 strip + 1 Fuji + 1 flip + 2 idle)
SA_S52_HI       equ     $30             ; sweep start (climb hold value)
SA_S52_LO       equ     $1B             ; sweep end
PAGE_TOGGLE     equ     PAGE_A_TOKEN!PAGE_B_TOKEN

test_start:
        orcc    #$50
        lds     #$01FF
        clra
        tfr     a,dp

        jsr     HAL_sys_init
        jsr     HAL_time_init
        lda     #$00
        jsr     HAL_gfx_init
        lda     #PAL_SEL_DEFAULT
        sta     pal_select
        jsr     apply_palette

        lda     #PAGE_A_TOKEN
        sta     <page_register
        andcc   #$EF

        * --- the EXACT Jay-gated climb tableau -> buffer A (mirrors scene6_climb_crawl_driver) ---
        jsr     fill_sky
        jsr     fill_walltop
        jsr     draw_climb_scenery_back ; gated wall-top posts (RMW) + black backwall
        jsr     draw_climb_striations   ; cliff-face STRIATION LINES (fixed backdrop)
        lda     plc_AB4A+1              ; AB4A sub-byte (§2F table = col,sub,row). FIXED backdrop
        sta     <blit_subbyte           ;   in the band: strip holds it fixed left + slides the wall
        lda     plc_AB4A                ;   col     block over it -> stationary + overwritten.
        ldb     plc_AB4A+2              ;   row
        ldx     #scene6_cliff_AB4A
        jsr     HAL_gfx_blit_sprite_opaque
        jsr     draw_climb_ground_right ; ground segments
        jsr     draw_hud_player

        * snapshot the strip band BEFORE the cliff cels AND Fuji. The strip scrolls what IS in it
        * (sky + striation lines + wall-top + ground) with the striations held fixed; the CLIFF
        * SPRITE (AB4A/AA7D) and Fuji are NOT in the band — they are re-drawn on top each step
        * (the cliff cels at the scrolled column, Fuji fixed).
        jsr     snapshot_band           ; band WITHOUT the cliff cels, WITHOUT Fuji

        clr     scroll_shift
        jsr     draw_cliff_cels         ; AB4A + AA7D (the climbable cliff sprite) at shift 0 -> A
        jsr     draw_fuji_cels          ; Fuji -> A (fixed)
        jsr     copy_a_to_b

        * --- show A (the shift-0 tableau); loop builds B, C, ... ---
        jsr     HAL_gfx_present
        lda     <page_register
        eora    #PAGE_TOGGLE
        sta     <page_register
        lda     #SA_S52_HI
        sta     cur52
        clr     mg_phase

* ---------------------------------------------------------------
* main_loop — per-frame state machine (amortized strip-scroll across SA_HOLD frames).
* ---------------------------------------------------------------
main_loop:
        jsr     HAL_time_vbl_wait
        lda     mg_phase
        cmpa    #SA_NCHUNK
        blo     ml_strip                ; phases 0..11: strip a chunk of rows
        beq     ml_fujiu                ; phase 12: redraw the UPPER Fuji cels on top (fixed)
        cmpa    #SA_NCHUNK+1
        beq     ml_cliff                ; phase 13: re-blit the cliff sprite at the scrolled col
        cmpa    #SA_NCHUNK+2
        beq     ml_flip                 ; phase 14: present + flip
        bra     ml_next                 ; phase 15: idle

* The LOWEST Fuji cel ($A9E2) is NOT redrawn -> the strip (scrolling area, drawn "after" Fuji)
*   overwrites it while it stays stationary. The UPPER Fuji cels ARE redrawn on top so they
*   stay visible (the strip band overlaps their lower rows).

ml_strip:
        tsta
        bne     ml_sc
        jsr     step_init               ; phase 0: advance $52, shift, back_band, strip_row=0
ml_sc:
        jsr     strip_chunk
        bra     ml_next

ml_fujiu:
        jsr     draw_a9e2_behind        ; lowest Fuji cel $A9E2 — stationary, behind the scroll (occluded)
        jsr     draw_fuji_upper         ; upper Fuji cels — fixed, on top
        bra     ml_next

ml_cliff:
        jsr     draw_cliff_cels         ; the cliff sprite (AA7D) at (base_col - shift) — SCROLLS
        jsr     draw_ground_seam        ; ground column over the cliff's right edge (no black seam)
        jsr     clip_left_border        ; clip a scrolled cliff cel at the virtual left edge (px20)
        bra     ml_next

ml_flip:
        jsr     HAL_gfx_present
        lda     <page_register
        eora    #PAGE_TOGGLE
        sta     <page_register

ml_next:
        inc     mg_phase
        lda     mg_phase
        cmpa    #SA_HOLD
        blo     main_loop
        clr     mg_phase
        bra     main_loop

* ---------------------------------------------------------------
* step_init — phase 0: advance $52 (dec, wrap $1B->$30), set shift, back_band, strip_row.
* ---------------------------------------------------------------
step_init:
        dec     cur52
        lda     cur52
        cmpa    #SA_S52_LO
        bhs     si_shift
        lda     #SA_S52_HI
        sta     cur52
si_shift:
        lda     #SA_S52_HI
        suba    cur52
        sta     scroll_shift            ; shift = $30 - $52 (0..21)
        clr     strip_row
        lda     <page_register
        cmpa    #PAGE_A_TOKEN
        bne     si_useb
        ldd     #SA_A_BAND
        bra     si_dst
si_useb:
        ldd     #SA_B_BAND
si_dst:
        std     back_band
        rts

* ---------------------------------------------------------------
* strip_chunk — strip up to SA_RPC rows (from strip_row), each shifted LEFT by scroll_shift.
* ---------------------------------------------------------------
strip_chunk:
        lda     #SA_RPC
        sta     chunk_ct
sc_l:
        lda     strip_row
        cmpa    #SA_BAND_ROWS
        bhs     sc_done
        ldb     #80
        mul                             ; D = strip_row*80  (A=strip_row, B=80)
        addd    #scroll_save
        std     cur_src                 ; snapshot row
        lda     strip_row
        ldb     #80
        mul
        addd    back_band
        std     cur_dst                 ; back-buffer band row
        jsr     strip_one_row
        inc     strip_row
        dec     chunk_ct
        bne     sc_l
sc_done:
        rts

* strip_one_row — the striations (bytes < WALL_L) are a FIXED backdrop; the wall/ground block
*   (snapshot bytes WALL_L..79) slides LEFT over them and overwrites them. Boundary B = WALL_L-shift.
*   dest[0..B-1]  = snapshot[0..B-1]   (fixed striations, aligned)
*   dest[B..79-shift] = snapshot[WALL_L..79]  (the block, its left edge slid to B)
*   dest[80-shift..79] = snapshot[79]  (edge-extend the vacated right)
strip_one_row:
        * (1) fixed striations: aligned copy of B = WALL_L - shift bytes
        ldx     cur_src
        ldy     cur_dst
        lda     #WALL_L
        suba    scroll_shift            ; A = B (0..24)
        beq     sor_block               ; B=0 -> no fixed part
sor_fix:
        ldb     ,x+
        stb     ,y+
        deca
        bne     sor_fix
sor_block:
        * (2) the wall/ground block: 56 bytes from snapshot[WALL_L], placed at dest[B] (Y is there)
        ldx     cur_src
        leax    WALL_L,x                ; X = snapshot col WALL_L
        lda     79-WALL_L,x             ; A = edge byte (snapshot col 79)
        sta     edge_byte
        lda     #80-WALL_L              ; 56 bytes (WALL_L..79)
        sta     copy_ct
sor_c:
        ldb     ,x+
        stb     ,y+
        dec     copy_ct
        bne     sor_c
        * (3) edge-extend the vacated right: shift bytes of snapshot[79]
        lda     scroll_shift
        beq     sor_d
        ldb     edge_byte
sor_f:
        stb     ,y+
        deca
        bne     sor_f
sor_d:
        * clip to the VIRTUAL screen: bytes 0..4 (px0..19) are the left border -> force black so the
        *   scroll never bleeds past the logical left edge (px20 = byte 5) to the true screen edge.
        ldu     cur_dst
        clr     ,u
        clr     1,u
        clr     2,u
        clr     3,u
        clr     4,u
        rts

* ---------------------------------------------------------------
* snapshot_band — copy the clean gated band (buffer A, rows 100-180) into scroll_save.
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

* draw_a9e2_behind — redraw the lowest Fuji cel $A9E2 (byte 26, row 108) STATIONARY but BEHIND
*   the scroll: write each cel byte only where the back buffer is SKY ($AA), so the posts/rail/
*   wall already in the band (from the strip) OCCLUDE it. It does not scroll.
draw_a9e2_behind:
        lda     fuji_A9E2+2              ; row (§2F table col,sub,row; A9E2 sub=0, direct byte-write)
        ldb     #80
        mul                             ; D = row*80
        addb    fuji_A9E2                ; + col into low byte
        adca    #0                      ;   carry into high byte
        pshs    d                       ; save the byte-offset row*80+col
        lda     <page_register
        cmpa    #PAGE_A_TOKEN
        bne     dab_useb
        ldd     #$8000
        bra     dab_go
dab_useb:
        ldd     #$C000
dab_go:
        addd    ,s++                    ; base + offset -> dest ($8000/$C000 + 108*80 + 26)
        tfr     d,u
        ldx     #scene6_bg_A9E2
        lda     ,x+                     ; height
        sta     a9e2_h
        lda     ,x+                     ; width
        sta     a9e2_w
dab_row:
        pshs    u
        ldb     a9e2_w
dab_byte:
        lda     ,u                      ; dest byte in the back buffer
        cmpa    #$AA                    ; sky? (else it's wall/post -> keep = occlusion)
        bne     dab_keep
        lda     ,x                      ; cel byte -> draw behind
        sta     ,u
dab_keep:
        leax    1,x                     ; advance src even when skipped (stay aligned)
        leau    1,u
        decb
        bne     dab_byte
        puls    u
        leau    80,u
        dec     a9e2_h
        bne     dab_row
        rts

* draw_fuji_upper — the UPPER 3 Fuji cels (peak $A948, $A976, $A9B8) drawn fixed on top; the
*   LOWEST cel $A9E2 is intentionally omitted so the scroll overwrites it. (Positions mirror
*   scene6_backdrop.s draw_fuji_cels minus $A9E2.)
draw_fuji_upper:
        lda     fuji_A9B8+1              ; sub (§2F table col,sub,row)
        sta     <blit_subbyte
        lda     fuji_A9B8                ; col
        ldb     fuji_A9B8+2              ; row
        ldx     #scene6_bg_A9B8
        jsr     HAL_gfx_blit_sprite_opaque
        lda     fuji_A976+1              ; sub
        sta     <blit_subbyte
        lda     fuji_A976                ; col
        ldb     fuji_A976+2              ; row
        ldx     #scene6_bg_A976
        jsr     HAL_gfx_blit_sprite_opaque
        lda     fuji_A948+1              ; sub
        sta     <blit_subbyte
        lda     fuji_A948                ; col
        ldb     fuji_A948+2              ; row
        ldx     #scene6_bg_A948
        jsr     HAL_gfx_blit_sprite_opaque
        rts

* draw_cliff_cels — re-blit the cliff sprite cels (AB4A + AA7D, the climbable cliff) at
*   (base_col - scroll_shift) into the back buffer, so the cliff SCROLLS over the fixed
*   striation backdrop. Skips a cel once its col goes off the left edge.
draw_cliff_cels:
        lda     plc_AA7D+1              ; AA7D sub-byte (§2F table col,sub,row)
        sta     <blit_subbyte
        lda     plc_AA7D                ; AA7D base col from §2F table
        suba    scroll_shift            ; col = base - shift
        bcs     draw_a7d_clipped        ; col < 0 -> partially off-left: left-clip it
        ldb     plc_AA7D+2              ; row
        ldx     #scene6_cliff_AA7D
        jmp     HAL_gfx_blit_sprite_opaque   ; col >= 0 (clip_left_border trims bytes 0-4 after)

* draw_a7d_clipped — AA7D has scrolled partly off the left edge (col < 0). Draw only the still-
*   visible cel columns (skip the first K = shift-15) at byte 0, opaque; clip_left_border then
*   trims bytes 0-4 so it slides off smoothly to the virtual left edge (px20).
draw_a7d_clipped:
        lda     scroll_shift
        suba    plc_AA7D                ; K = shift - base col (was #15)
        sta     clip_k                  ; K = columns off the left
        lda     #11
        suba    clip_k
        ble     dac_done                ; fully off-left
        sta     clip_w                  ; visible width = 11 - K
        lda     plc_AA7D+2              ; row (§2F table col,sub,row)
        ldb     #80
        mul                             ; D = row*80
        pshs    d
        lda     <page_register
        cmpa    #PAGE_A_TOKEN
        bne     dac_useb
        ldd     #$8000
        bra     dac_go
dac_useb:
        ldd     #$C000
dac_go:
        addd    ,s++                    ; base + row*80 -> byte-0 dest ($8000/$C000 + 152*80)
        tfr     d,u
        ldx     #scene6_cliff_AA7D+2    ; cel data (skip h/w header)
        lda     clip_k
        leax    a,x                     ; X = row 0 data + K (skip clipped-off columns)
        ldb     #29                     ; 29 rows
dac_row:
        pshs    b,u,x
        lda     clip_w
dac_byte:
        ldb     ,x+
        stb     ,u+
        deca
        bne     dac_byte
        puls    b,u,x
        leax    11,x                    ; next cel row (full stride = width 11)
        leau    80,u
        decb
        bne     dac_row
dac_done:
        rts

* draw_ground_seam — redraw the ground's ONE leftmost column (byte 25-shift, the cliff cel's
*   byte 10 position) over the cliff's right edge, rows 152-180, with the ground pattern
*   (even rows orange $55 / odd rows blue $AA). In the static tableau the ground was drawn
*   AFTER the cliff and covered this column; here the cliff is on top of the strip, so its
*   black-containing right column would seam over the floor without this.
draw_ground_seam:
        lda     #25
        suba    scroll_shift            ; col = 25 - shift
        cmpa    #5                      ; clipped at the virtual left edge?
        blo     gs_done
        tfr     a,b                     ; B = col
        lda     <page_register
        cmpa    #PAGE_A_TOKEN
        bne     gs_useb
        ldx     #$8000+152*80
        bra     gs_go
gs_useb:
        ldx     #$C000+152*80
gs_go:
        abx                             ; X = back base + 152*80 + col
        lda     #$55                    ; row 152 (even) = orange
        ldb     #29                     ; rows 152..180
gs_row:
        sta     ,x
        leax    80,x
        eora    #$FF                    ; toggle $55 <-> $AA (orange even / blue odd)
        decb
        bne     gs_row
gs_done:
        rts

* clip_left_border — force bytes 0..4 (px0..19, left border) black across the band, so a
*   scrolled cliff cel can't bleed past the virtual left edge (px20 = byte 5).
clip_left_border:
        ldx     back_band
        lda     #SA_BAND_ROWS
clb_l:
        clr     ,x
        clr     1,x
        clr     2,x
        clr     3,x
        clr     4,x
        leax    80,x
        deca
        bne     clb_l
        rts

* --- Stage-A state ---
mg_phase        fcb     0
cur52           fcb     SA_S52_HI
scroll_shift    fcb     0
strip_row       fcb     0
chunk_ct        fcb     0
edge_byte       fcb     0
copy_ct         fcb     0
a9e2_h          fcb     0
a9e2_w          fcb     0
clip_k          fcb     0
clip_w          fcb     0
back_band       fdb     0
cur_src         fdb     0
cur_dst         fdb     0
scroll_save     rmb     SA_BAND_LEN     ; clean gated-band snapshot (6480 bytes)

* --- HAL + shared substrate modules (single source) ---
        include "../../src/hal/coco3-dsk/sys.s"
        include "../../src/hal/coco3-dsk/irq_vbl.s"
        include "../../src/hal/coco3-dsk/gfx.s"
        include "../../src/hal/coco3-dsk/time.s"

        include "scene6_backdrop.s"
        include "scene6_cliff_walltop.s"
        include "scene6_cliff_face.s"
        include "scene6_hud.s"
        include "scene6_placement_gen.s"  ; §2F single-home PLACEMENT table (codegen'd)

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
        fcb     $00,$26,$2D,$3F
        fcb     $00,$26,$19,$3F

        end     test_start
