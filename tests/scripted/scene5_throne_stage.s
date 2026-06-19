* tests/scripted/scene5_throne_stage.s
*
* SCENE-5 THRONE STAGE (pass 1a) — the throne-room backdrop render, factored
* OUT of scene5_stage_driver.s as an INCLUDABLE module (no org / no test_start /
* no end) so pass-1b drivers can composite actors over the gated 1a stage.
*   draw_throne_stage = clear-to-black + floor lines + the gate set-dressing.
* This is the SAME code (verbatim) that gated CONFIRMED in 1a; the throne path
* of scene5_stage_driver.s (RENDER_CELL=0). Coord/mirror model unchanged.
*
* ZP NOTE: this module's scratch ($40-$4F,$51) OVERLAPS the princess
* controller's state ($43-$4F). That is BENIGN here: the stage renders ONCE at
* init (caller drives draw_throne_stage to both buffers), BEFORE the princess
* loop owns $43-$4F. They never run concurrently. The caller must set its own
* clock/state ZP ($42 etc.) AFTER the stage render (sc_mir=$42 is used here).
* ---------------------------------------------------------------

SCENE_XOFF      equ 20          ; left border (px) to center the 280px window in 320

* scratch ZP (avoid eng $30-3B, blit $08-13) — init-only (see ZP NOTE)
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
sc_pad          equ $51         ; leading transparent pad bytes (964A=1); $50=page_register
FLIP_BUF        equ $4000       ; scratch for horizontally-flipped sprite (mirror)

* ===============================================================
* draw_throne_stage — paint the static throne-room stage to the back buffer.
*   (1) clear to black  (2) floor lines  (3) gate set-dressing.
* ===============================================================
draw_throne_stage:
        clr     <eng_col
        clr     <eng_row
        lda     #80
        sta     <eng_clrw
        lda     #192
        sta     <eng_clrh
        clr     <eng_fillval            ; black background
        jsr     eng_clear_box
        jsr     draw_floor_lines
        ldu     #stage_tbl
        jsr     draw_setdressing
        rts

* ===============================================================
* draw_floor_lines — blue ($AA) line on each ODD row across the floor rect
*   (byte10..68, rows 153..181). Perspective taper carried by the floor sprites.
* ===============================================================
draw_floor_lines:
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
*   entry: fdb ptr ; fcb apple_x, apple_y, mirror(0/1), opaque(0/1)
* ===============================================================
draw_setdressing:                       ; U = placement table (set by caller)
ds_loop:
        ldx     ,u++                    ; X = sprite ptr (-> height,width,bitmap)
        cmpx    #0
        beq     ds_done
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
        ; --- NORMAL: px = normal_px - sc_pad*4 ---
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
        ; --- MIRROR: mirror_left = 312 - normal_px - (width - sc_pad)*4 (+6) ---
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
* make_flipped — X = source sprite. Builds a HORIZONTALLY-FLIPPED copy at
*   FLIP_BUF (reverse byte order + reverse 4 2-bit pixels via rev2). Returns
*   Y = FLIP_BUF. Preserves U. Clobbers A,B,X.
* ===============================================================
make_flipped:
        pshs    u
        lda     ,x+                     ; height
        sta     <mf_h
        lda     ,x+                     ; width
        sta     <mf_w
        ldy     #FLIP_BUF
        lda     <mf_h
        sta     ,y+
        lda     <mf_w
        sta     ,y+                     ; Y = dst data start
        ldu     #rev2
mf_row:
        ldb     <mf_w
        stb     <mf_wctr
        pshs    y                       ; save row start
        leay    b,y                     ; Y = rowstart + w
        leay    -1,y                    ; Y = rowstart + w - 1 (descending dst)
mf_byte:
        ldb     ,x+                     ; B = src byte
        clra                            ; D = src (unsigned 16-bit offset)
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
        ldy     #FLIP_BUF
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
* stage_tbl — the throne gate set-dressing, captured ORDER (opaque => order
* matters). idx0(N,M) idx3(N,M) idx4(N,M) idx1(N,M) idx2(M,N).
* entry: fdb ptr ; fcb apple_x, apple_y, mirror(0/1), opaque(0/1)
* ---------------------------------------------------------------
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
        fcb     $20,$99,0,1
        fdb     floor_9743_coco3
        fcb     $20,$99,1,1
        fdb     floor_964A_coco3        ; idx1 post   N x$21 y$5F ; M x$05  (transparent)
        fcb     $21,$5F,0,0
        fdb     floor_964A_coco3
        fcb     $21,$5F,1,0
        fdb     floor_96CE_coco3        ; idx2 post (LAST) M x$02 ; N x$24 y$5F  (transparent)
        fcb     $24,$5F,1,0
        fdb     floor_96CE_coco3
        fcb     $24,$5F,0,0
        fdb     0                       ; terminator

* --- throne set-dressing content ---
        include "../../content/floor/floor_9600/converted.s"
        include "../../content/floor/floor_964A/converted.s"
        include "../../content/floor/floor_96CE/converted.s"
        include "../../content/floor/floor_971D/converted.s"
        include "../../content/floor/floor_9743/converted.s"
