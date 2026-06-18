* tests/scripted/scene5_stage_driver.s
*
* SCENE-5 STATIC STAGE SANDBOX (pass 1a) — the imprisonment backdrop, EMPTY of
* actors. A proto-scene scaffold (NOT an engine test): renders the $0A00 fill
* backgrounds (floor + walls) at real bounds + all set-dressing sprites
* (cell door / bench / wall / floor patterns + textures) at REAL positions,
* composited as the MIX (fill + shared sprite leaf). Boot-excluded.
*
* Layout read: docs/project/scene5-static-stage-spec.md (oracle display_7700.s
* draw_fight_scene_0/2/3 + tbl_sprite_*_a + render_frame_0a00.s).
* Coord model: Apple byte-col c -> px c*7 -> CoCo3 byte (c*7)>>2, sub (c*7)&3
* (1:1 pixels, per sprite_convert.py). Mirror col = $26-c (= 38-c).
*
* STATIC: redraws the stage each frame + flips (proven double-buffer pattern),
* but the content never changes -> a held empty stage to gate vs the Apple II
* imprisonment reference. No actors, no $3B clock (that is pass 1b).
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

FB_A_LO         equ $8000
FB_B_LO         equ $C000

* --- fill bounds (CoCo3 bytes/rows) ---
* Coord model (design premise): Apple 280px window kept SAME SIZE on CoCo3,
* CENTERED with 20px borders L/R. So CoCo3 px = Apple px + 20 (1:1 pixels);
* Apple byte-col c -> CoCo3 px (c*7 + 20) -> byte ((c*7+20)>>2). Rows 1:1.
RENDER_CELL     equ 1           ; 1 = scene-5 stage TWO (cell, 1a-2); 0 = throne (1a)
SCENE_XOFF      equ 20          ; left border (px) to center the 280px window in 320
FLOOR_COL       equ 12          ; Apple $04*7+20=48 -> byte 12
FLOOR_W         equ 56          ; Apple $24*7+20=272 -> byte 68; width 68-12
FLOOR_ROW       equ 153         ; Apple $99
FLOOR_H         equ 30          ; Apple $99..$B6 = 153..182
FLOOR_STRIPE    equ $AA         ; PLACEHOLDER floor stripe (index-2 blue) on alt rows
FLOOR_FILL      equ $AA         ; PLACEHOLDER floor-ground fill (solid blue; dark
                                ;   dither needs the dual-pattern fill — follow-up)

* scratch ZP (avoid eng $30-3B, blit $08-13)
sc_tmpx         equ $40
sc_y            equ $41
sc_mir          equ $42         ; current entry mirror flag
sc_col          equ $43         ; computed CoCo3 byte-col
mf_h            equ $44         ; make_flipped: height
mf_w            equ $45         ; make_flipped: width
mf_wctr         equ $46         ; make_flipped: per-row byte counter
sc_ax           equ $47         ; current entry apple_x
sc_npx          equ $48         ; 16-bit: normal CoCo3 px (for mirror reflection)
sc_opq          equ $4F         ; per-entry opaque flag (0=transparent,1=opaque)
sc_pad          equ $51         ; leading transparent pad bytes on this sprite (964A=1)
                                ; NOTE: $50 is the HAL page_register — do NOT use it here.
hl_row          equ $4A         ; draw_hline: row
hl_lcol         equ $4B         ; draw_hline: left byte-col
hl_lsub         equ $4C         ; draw_hline: left sub-pixel (0-3)
hl_rcol         equ $4D         ; draw_hline: right byte-col
hl_rsub         equ $4E         ; draw_hline: right sub-pixel (0-3)
FLIP_BUF        equ $4000       ; scratch for horizontally-flipped sprite (mirror)

test_start:
        orcc    #$50
        lds     #$01FF
        clra
        tfr     a,dp

        jsr     HAL_sys_init
        jsr     HAL_time_init
        lda     #$00
        jsr     HAL_gfx_init
        jsr     HAL_input_init

        lda     #PAGE_A_TOKEN
        sta     <page_register
        andcc   #$EF

        ; Static stage: paint BOTH buffers once, then hold. (Redrawing every
        ; frame exceeded the frame budget once 964A grew, so the page flip caught
        ; a half-drawn buffer -> whole-image flicker. Nothing animates here.)
        jsr     HAL_time_vbl_wait
        jsr     draw_stage
        jsr     HAL_gfx_present
        lda     <page_register
        eora    #$60
        sta     <page_register
        jsr     HAL_time_vbl_wait
        jsr     draw_stage
        jsr     HAL_gfx_present
        lda     <page_register
        eora    #$60
        sta     <page_register
hold_loop:
        jsr     HAL_time_vbl_wait
        bra     hold_loop

* ===============================================================
* draw_stage — paint the static imprisonment stage to the back buffer.
* ===============================================================
draw_stage:
        ; (1) clear back buffer to black
        clr     <eng_col
        clr     <eng_row
        lda     #80
        sta     <eng_clrw
        lda     #192
        sta     <eng_clrh
        clr     <eng_fillval            ; black background
        jsr     eng_clear_box
        ; (2) floor + (3) set-dressing — cell (stage two, 1a-2) or throne (1a)
    ifne RENDER_CELL
        jsr     draw_cell_floor
        ldu     #cell_stage_tbl
    else
        jsr     draw_floor_lines
        ldu     #stage_tbl
    endc
        jsr     draw_setdressing
        rts

* ===============================================================
* draw_doorframe_masks — black rectangles over the doorframe openings (the gaps
*   between each gate's two posts) so the floor stripes don't show inside.
* ===============================================================
draw_doorframe_masks:
        clr     <eng_fillval            ; black
        lda     #30
        sta     <eng_clrh               ; floor rows 153..182
        lda     #FLOOR_ROW
        sta     <eng_row
        ; left opening (between 96CE byte10-11 and 964A byte13-16) = byte 12
        lda     #12
        sta     <eng_col
        lda     #1
        sta     <eng_clrw
        jsr     eng_clear_box
        ; right opening (between 964A byte62-65 and 96CE byte68-69) = byte 66-67
        lda     #66
        sta     <eng_col
        lda     #2
        sta     <eng_clrw
        lda     #FLOOR_ROW
        sta     <eng_row
        jsr     eng_clear_box
        rts

* ===============================================================
* draw_floor_lines — the floor as a perspective TRAPEZOID of evenly-spaced
*   horizontal lines (stride 2). Each line is drawn with PIXEL-PRECISE endpoints
*   (sub-byte edge masks) so the trapezoid sides form SMOOTH diagonals (not
*   byte-jagged). Table: row, lcol, lsub, rcol, rsub ; $FF terminator.
* ===============================================================
* $0A00 dual-pattern fill (L0A03), faithful: a blue line on each ODD row across
* the floor rectangle (Apple cols $04..$24 = CoCo3 byte 12..68; rows 153..181).
* The perspective/taper is NOT here — it is carried by the floor sprites
* (fig_1200/fig_14BE/floor_971D/floor_9743), exactly as the Apple II composites.
draw_floor_lines:
        ; byte10..68 — symmetric about the gate centre (byte39). The captured
        ; fill is apple cols4-36 (=byte12-68), whose RIGHT edge (byte68) reaches
        ; under the right gate posts (byte62-68) but whose LEFT edge (byte12)
        ; stops short of the left posts (byte8-12), so the floor lines were
        ; missing under the LEFT doorway. byte68 mirrored about byte39 = byte10,
        ; so the left edge now reaches under the left doorway exactly as the
        ; right edge does the right. (Posts blit on top; only the under-doorway
        ; floor band is affected — not the v34 over-extension into the wall.)
        lda     #10
        sta     <eng_col
        lda     #59
        sta     <eng_clrw
        lda     #1
        sta     <eng_clrh
        lda     #$AA
        sta     <eng_fillval
        lda     #153
dfl_loop:
        sta     <eng_row
        pshs    a
        jsr     eng_clear_box
        puls    a
        adda    #2
        cmpa    #183
        blo     dfl_loop
        rts

* ===============================================================
* draw_setdressing — walk the placement table, blit each at its real position.
*   Table entry: fdb sprite_ptr ; fcb apple_x ; fcb apple_y ; fcb mirror(0/1)
*   px = (mirror ? 38-x : x) * 7 ; col = px>>2 ; sub = px&3.
*   (Mirror sprites are placed at the mirror column but NOT yet h-flipped —
*    flip is a HAL follow-up; flagged for the gate.)
* ===============================================================
draw_setdressing:                       ; U = placement table (set by caller)
ds_loop:
        ldx     ,u++                    ; X = sprite ptr (-> height,width,bitmap)
        cmpx    #0
        beq     ds_done
        ; floor_964A carries 1 leading transparent pad byte (left-line extension);
        ; compensate its draw position so the post stays put.
        clr     <sc_pad
        cmpx    #floor_964A_coco3
        bne     ds_nopad
        ldb     #1
        stb     <sc_pad
ds_nopad:
        lda     ,u+                     ; apple_x
        sta     <sc_ax
        lda     ,u+                     ; apple_y
        sta     <sc_y
        lda     ,u+                     ; mirror flag
        sta     <sc_mir
        lda     ,u+                     ; opaque flag (0=transparent,1=opaque)
        sta     <sc_opq
        ; normal_px = apple_x*7 + border
        lda     <sc_ax
        ldb     #7
        mul                             ; D = apple_x*7
        addd    #SCENE_XOFF             ; D = normal_px (A=high, B=low)
        std     <sc_npx
        tst     <sc_mir
        bne     ds_mirror
        ; --- NORMAL: px = normal_px - sc_pad*4. The sprite's leading pad bytes
        ;   are transparent left padding; draw that many bytes further left so
        ;   the real content lands at normal_px. ---
        ldb     <sc_pad
        lslb
        lslb                            ; B = sc_pad*4
        clra                            ; D = sc_pad*4
        coma
        comb
        addd    #1                      ; D = -(sc_pad*4)
        addd    <sc_npx                 ; D = normal_px - sc_pad*4
        bra     ds_setpx
ds_mirror:
        ; --- MIRROR: the oracle draws $05=$26-x via the L190C FLIP, which
        ;   extends the sprite LEFTWARD from that anchor. Faithful replay =
        ;   reflect the CONTENT extent about the oracle axis: mirror_left =
        ;   312 - normal_px - (width - sc_pad)*4. The +6 (vs 306) is the oracle's
        ;   $10=6 sub-byte offset on every mirror. sc_pad is excluded from the
        ;   width so the leading pad (which becomes a trailing pad after the flip)
        ;   doesn't shift the content off the anchor. ---
        lda     #0
        ldb     1,x                     ; coco3_width
        subb    <sc_pad                 ; content width = width - sc_pad
        aslb
        rola
        aslb
        rola                            ; D = content_width*4
        addd    <sc_npx                 ; D = content_width*4 + normal_px
        coma
        comb
        addd    #313                    ; D = 312 - (content_width*4 + normal_px)
ds_setpx:
        ; D = px ; col = px>>2 ; sub = px&3
        pshs    b                       ; save px low byte
        lsra
        rorb
        lsra
        rorb                            ; D = px>>2 (A intact), col in B
        stb     <sc_col
        puls    a                       ; px low byte
        anda    #$03
        sta     <blit_subbyte           ; sub-byte = px & 3
        ; mirror -> build horizontally-flipped copy, blit that instead
        tst     <sc_mir
        beq     ds_blit
        pshs    u                       ; X still = src sprite ptr
        jsr     make_flipped            ; -> Y = FLIP_BUF (flipped sprite)
        puls    u
        tfr     y,x                     ; X = flipped sprite
ds_blit:
        lda     <sc_col                 ; A = byte col
        ldb     <sc_y                   ; B = row
        pshs    u
        ; per-entry blend: opaque (writes black) vs transparent (index-0 keyed).
        tst     <sc_opq
        beq     ds_blit_tr
        jsr     HAL_gfx_blit_sprite_opaque
        puls    u
        lbra    ds_loop
ds_blit_tr:
        jsr     HAL_gfx_blit_sprite
        puls    u
        lbra    ds_loop
ds_done:
        rts

* ===============================================================
* make_flipped — X = source sprite (height,width,bitmap). Builds a
*   HORIZONTALLY-FLIPPED copy at FLIP_BUF: reverse byte order per row +
*   reverse the 4 2-bit pixels within each byte (rev2 table). All scene-5
*   mirror sprites have exact byte-width (no sub-byte padding) -> clean flip.
*   Returns Y = FLIP_BUF. Preserves U (caller's table ptr). Clobbers A,B,X.
* ===============================================================
make_flipped:
        pshs    u
        lda     ,x+                     ; height
        sta     <mf_h
        lda     ,x+                     ; width
        sta     <mf_w
        ; write header to FLIP_BUF
        ldy     #FLIP_BUF
        lda     <mf_h
        sta     ,y+
        lda     <mf_w
        sta     ,y+                     ; Y = dst data start
        ldu     #rev2                   ; reverse table
mf_row:
        ldb     <mf_w
        stb     <mf_wctr                ; per-row byte counter (B reused for table lookup)
        pshs    y                       ; save row start
        leay    b,y                     ; Y = rowstart + w
        leay    -1,y                    ; Y = rowstart + w - 1 (descending dst)
mf_byte:
        ldb     ,x+                     ; B = src byte (0..255)
        clra                            ; D = src (UNSIGNED 16-bit offset; avoids signed a,u bug)
        lda     d,u                     ; A = rev2[src]
        sta     ,y                      ; dst[w-1-i]
        leay    -1,y
        dec     <mf_wctr
        bne     mf_byte
        puls    y                       ; Y = row start
        ldb     <mf_w
        leay    b,y                     ; Y = next row start
        dec     <mf_h
        bne     mf_row
        ldy     #FLIP_BUF               ; return flipped sprite ptr
        puls    u
        rts

rev2:
        fcb     $00,$40,$80,$C0,$10,$50,$90,$D0,$20,$60,$A0,$E0,$30,$70,$B0,$F0
        fcb     $04,$44,$84,$C4,$14,$54,$94,$D4,$24,$64,$A4,$E4,$34,$74,$B4,$F4
        fcb     $08,$48,$88,$C8,$18,$58,$98,$D8,$28,$68,$A8,$E8,$38,$78,$B8,$F8
        fcb     $0C,$4C,$8C,$CC,$1C,$5C,$9C,$DC,$2C,$6C,$AC,$EC,$3C,$7C,$BC,$FC
        fcb     $01,$41,$81,$C1,$11,$51,$91,$D1,$21,$61,$A1,$E1,$31,$71,$B1,$F1
        fcb     $05,$45,$85,$C5,$15,$55,$95,$D5,$25,$65,$A5,$E5,$35,$75,$B5,$F5
        fcb     $09,$49,$89,$C9,$19,$59,$99,$D9,$29,$69,$A9,$E9,$39,$79,$B9,$F9
        fcb     $0D,$4D,$8D,$CD,$1D,$5D,$9D,$DD,$2D,$6D,$AD,$ED,$3D,$7D,$BD,$FD
        fcb     $02,$42,$82,$C2,$12,$52,$92,$D2,$22,$62,$A2,$E2,$32,$72,$B2,$F2
        fcb     $06,$46,$86,$C6,$16,$56,$96,$D6,$26,$66,$A6,$E6,$36,$76,$B6,$F6
        fcb     $0A,$4A,$8A,$CA,$1A,$5A,$9A,$DA,$2A,$6A,$AA,$EA,$3A,$7A,$BA,$FA
        fcb     $0E,$4E,$8E,$CE,$1E,$5E,$9E,$DE,$2E,$6E,$AE,$EE,$3E,$7E,$BE,$FE
        fcb     $03,$43,$83,$C3,$13,$53,$93,$D3,$23,$63,$A3,$E3,$33,$73,$B3,$F3
        fcb     $07,$47,$87,$C7,$17,$57,$97,$D7,$27,$67,$A7,$E7,$37,$77,$B7,$F7
        fcb     $0B,$4B,$8B,$CB,$1B,$5B,$9B,$DB,$2B,$6B,$AB,$EB,$3B,$7B,$BB,$FB
        fcb     $0F,$4F,$8F,$CF,$1F,$5F,$9F,$DF,$2F,$6F,$AF,$EF,$3F,$7F,$BF,$FF

* ---------------------------------------------------------------
* Placement table — the 11 set-dressing sprites, drawn as the oracle
* draw_fight_scene_0/2/3 do (normal at x, mirror at 38-x). Floor patterns
* (idx0-4) are drawn BOTH N and M (symmetric posts). $84-driven cell door
* (idx5) drawn N (scene_1) + M (scene_3). Terminated by fdb 0.
* ---------------------------------------------------------------
* Captured draw program (probe7 trace): set-dressing = ONLY idx0-4 ($96xx),
* each normal (x) + mirror ($26-x). Exact positions from the trace. No cell
* door/bench/$18BF/$1200/$14BE — those were static-read mis-attributions.
* ORDER IS THE CAPTURED ORDER (critical now that draws are OPAQUE — later
* overwrites earlier). Oracle scene_0 draws fill, then idx0,idx3,idx1,idx4
* (each draw_combatant_normal THEN _mirror); scene_1 draws idx2 LAST as
* _mirror THEN _normal. So: idx0(N,M) idx3(N,M) idx1(N,M) idx4(N,M) idx2(M,N).
* entry: fdb ptr ; fcb apple_x, apple_y, mirror(0/1), opaque(0/1)
* TRYING: only floor_971D (idx3) + floor_9743 (idx4) opaque; rest transparent.
stage_tbl:
        fdb     floor_9600_coco3        ; idx0 rail   N x$20 y$53 ; M x$06  (transparent)
        fcb     $20,$53,0,0
        fdb     floor_9600_coco3
        fcb     $20,$53,1,0
        fdb     floor_971D_coco3        ; idx3 floor  N x$24 y$AD ; M x$02  (OPAQUE)
        fcb     $24,$AD,0,1
        fdb     floor_971D_coco3
        fcb     $24,$AD,1,1
        fdb     floor_9743_coco3        ; idx4 floor  N x$20 y$99 ; M x$06  (OPAQUE)
        fcb     $20,$99,0,1             ; drawn BEFORE 964A so the post repaints on
        fdb     floor_9743_coco3        ; top and its leg isn't eaten by 9743's
        fcb     $20,$99,1,1             ; opaque right-edge black column
        fdb     floor_964A_coco3        ; idx1 post   N x$21 y$5F ; M x$05  (transparent)
        fcb     $21,$5F,0,0
        fdb     floor_964A_coco3
        fcb     $21,$5F,1,0
        fdb     floor_96CE_coco3        ; idx2 post (LAST) M x$02 ; N x$24 y$5F  (transparent)
        fcb     $24,$5F,1,0
        fdb     floor_96CE_coco3
        fcb     $24,$5F,0,0
        fdb     0                       ; terminator

* ===============================================================
* CELL stage (scene-5 stage TWO, 1a-2) — from the captured d06 program
* (docs/project/scene5-cell-draw-program.md). Distinct from the throne.
* ===============================================================
* draw_cell_floor — the cell floor STRIP: 0A03 cols4-30 rows159-168 (apple)
*   = CoCo3 byte12..57, blue ($AA) on alternating rows. (Floor textures
*   fig_1200/fig_14BE in cell_stage_tbl add the rest.)
draw_cell_floor:
        lda     #8                      ; extend left to byte8 to MEET the left doorframe
        sta     <eng_col                ;   (left post $96CE M); was byte12, leaving the
        lda     #50                     ;   doorway-base black. byte 8..57.
        sta     <eng_clrw
        lda     #1
        sta     <eng_clrh
        lda     #$AA
        sta     <eng_fillval
        lda     #159
dcf_loop:
        sta     <eng_row
        pshs    a
        jsr     eng_clear_box
        puls    a
        adda    #2
        cmpa    #169
        blo     dcf_loop
        rts

* cell_stage_tbl — captured ORDER (opaque, so order matters), actor excluded.
* entry: fdb ptr ; fcb apple_x, apple_y, mirror(0/1), opaque(0/1)
* $96xx are MIRROR (apple_x = the NORMAL x; code reflects to $26-x); the
* figs are NORMAL at their real x (converted at true-column parity, AC-3).
cell_stage_tbl:
        fdb     floor_9600_coco3        ; doorway lintel  M (x$20->$06) y$53
        fcb     $20,$53,1,1
        fdb     floor_964A_cell_coco3   ; doorway post    M (x$21->$05) y$5F (clean, no 1a pad)
        fcb     $21,$5F,1,1
        fdb     fig_1200_coco3          ; floor texture   N x$08 y$A9  (transparent: opaque
        fcb     $08,$A9,0,0             ;   black/empty cols would gap the floor on CoCo3)
        fdb     fig_12C8_coco3          ; bench (right)   N x$1E y$84  (transparent: opaque
        fcb     $1E,$84,0,0             ;   black left-edge gapped the floor near the bench)
        fdb     fig_14BE_coco3          ; floor texture   N x$0A y$99  (transparent)
        fcb     $0A,$99,0,0
* fig_18BF (wall structure, x$04 y$99) REMOVED — present in the collapse-phase
* capture but NOT in the Apple II static cell reference (Jay gate 2026-06-18);
* a collapse-transient, not part of the static backdrop.
        fdb     floor_96CE_coco3        ; doorway post    M (x$24->$02) y$5F
        fcb     $24,$5F,1,1
        fdb     fig_18D0_coco3          ; small element   N x$02 y$A9
        fcb     $02,$A9,0,1
* CELL DOOR — a 1b ANIMATION element ($84=5 @ f5235, after walk-in / before
* turn-around), previewed here in the static stage for Jay's visual check.
* Drawn LAST (closes the doorway). M (x$22->$04), y$5B, transparent ($0F=00).
        fdb     door_9980_coco3
        fcb     $22,$5B,1,0
        fdb     0                       ; terminator

* --- REAL engine + HAL (single source, by include) ---
        include "../../src/engine/sprite_engine.s"
        include "../../src/hal/coco3-dsk/sys.s"
        include "../../src/hal/coco3-dsk/irq_vbl.s"
        include "../../src/hal/coco3-dsk/gfx.s"
        include "../../src/hal/coco3-dsk/time.s"
        include "../../src/hal/coco3-dsk/input.s"

* --- set-dressing content ---
        include "../../content/floor/floor_9600/converted.s"
        include "../../content/floor/floor_964A/converted.s"
        include "../../content/floor/floor_96CE/converted.s"
        include "../../content/floor/floor_971D/converted.s"
        include "../../content/floor/floor_9743/converted.s"
* --- cell (1a-2) set-dressing: floor textures, bench, wall, element ---
        include "../../content/floor/fig_1200/converted.s"
        include "../../content/scenery/fig_12C8/converted.s"
        include "../../content/floor/fig_14BE/converted.s"
        include "../../content/unsorted/fig_18D0/converted.s"
        include "../../content/scenery/s5_9980_cell_door/converted.s"
        include "../../content/floor/floor_964A_cell/converted.s"

        end     test_start
