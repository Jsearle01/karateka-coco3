* tests/scripted/scene5_akuma.s
*
* SCENE-5 AKUMA — the standing villain (RIGHT side of the throne room; NO throne,
* he STANDS). A multi-part composite + a CONTROLLER (later in this file):
*   - arms/torso: AMBIENT free idle loop (98D3 hip / 9908 raised / 9956 pointing)
*   - head: TRACKS THE PRINCESS — reads the canonical scene_clk ($3B-analog she
*     drives) and selects the head frame per the traced zone table (HS-0):
*       clk 15-17 -> 988B(f1) ; 18-19 -> 989D(f2) ; 1A-1B -> 98AF(f3) ;
*       1C-1D -> 98C1(f4) ; 1E-22 -> 9A62(f8)   [docs/.../scene5-akuma-head-coupling.md]
* Reuses the throne module's shared draw_setdressing/ZP. Part positions from the
* trace (akuma_pos.log). MILESTONE A here = the STATIC figure (default head/arm)
* + ground shadow, to gate the composite; the controller (B) wires the behaviors.
* ---------------------------------------------------------------

* ===============================================================
* draw_akuma_static — the full Akuma figure with the DEFAULT head (988B) + arm
*   (98D3), for gating the composite. Replays the captured parts (apple coords):
*     shadow (opaque) ; robe 974B (26,119) ; body 9EB8 (23,121) ; elem 984F
*     (23,125) ; torso/arm 98D3 (25,124) ; feet 9F8C (30,163) ; head 988B (23,113)
* ===============================================================
AKUMA_SHADOW    equ 1                   ; shadow ON — the 2 floor lines right of his feet (Jay)

* --- CONTROLLER state + tunables (HS-1 arms-ambient / HS-2 head-tracks-princess) ---
    ifndef scene_clk
scene_clk       equ $42                 ; canonical $3B-analog (princess WRITES, Akuma READS)
    endc
akuma_arm_idx   equ $52                 ; arm pose 0/1/2 -> frame_5/6/7
akuma_arm_ctr   equ $53                 ; arm-cadence down-counter
akuma_arm_done  equ $54                 ; 0=animating (one-shot), 1=held raised
akuma_clr_ctr   equ $55                 ; frames left to clear the arm box (=2 on a pose change: both buffers)
AKUMA_ARM_CAD   equ 12                  ; VBLs per arm pose (demo: matches the faster walk)
AKUMA_ARM_RAISED equ 2                  ; last index = fully-raised (frame_7); seq f5(hip)->f6(mid)->f7
AKUMA_CLK_DEFAULT equ $15               ; static default -> head frame_1 (mid-left)

* draw_akuma_lower — the STATIC lower/base figure (shadow, feet, robe outline,
*   floor-ext, body 9EB8). The arm + head overlay this; it goes in the clean
*   snapshot so per-frame arm/head redraws land on a clean body.
draw_akuma_lower:
        ; ground shadow — opaque black bar over the TWO floor lines immediately to
        ; the RIGHT of his feet (rows 162 & 165; below 165 the floor is already
        ; black). Starts at the feet's right edge and runs right. Drawn before the
        ; parts (over the floor, under Akuma).
    ifne AKUMA_SHADOW
        lda     #54                     ; byte col — just right of the feet (px ~216)
        sta     <eng_col
        lda     #170                    ; floor lines at his feet base (was 164: 3 lines too high)
        sta     <eng_row
        lda     #18                     ; byte54..71 -> all the way to the scene's right edge
        sta     <eng_clrw
        lda     #4                      ; rows 170-173 (the two floor lines 171 & 173)
        sta     <eng_clrh
        clr     <eng_fillval            ; black shadow
        jsr     eng_clear_box
    endc
        ; feet via the POSITIONAL-MASK blit (sub-byte opacity, no format change):
        ; the WHOLE sprite is opaque (solid robe-bottom) EXCEPT a 1px transparent
        ; strip on the left edge and a 2px transparent strip on the right edge,
        ; full height (Jay). Mask per column: col0=$3F (px0 see-through),
        ; cols1-9=$FF (solid), col10=$F0 (px2-3 see-through). Byte-aligned.
        clr     <blit_subbyte
        ldu     #akuma_feet_mask
        ldx     #akuma_feet_9F8C_coco3
        lda     #45                     ; byte col (~apple x23)
        ldb     #165                    ; row (feet down 2px on screen)
        jsr     HAL_gfx_blit_sprite_masked
        ; 2px OUTLINE following up the OUTER edges of the robe (Jay): a 2px-wide
        ; opaque-black border just outside the orange robe, STAIRSTEPPING inward
        ; going up to follow the flare. Floor-visible band only (rows 153-164;
        ; above 153 the backdrop is black). Feet transparency below stays intact.
        ; Orange edges step in 3 bands: L px188/190/192, R px214/212/210 (bot->top).
        ; LEFT side — outline just left of the orange, stepping in (right) going up:
        clr     <blit_subbyte                   ; L bottom: orange px188 -> outline px186-187
        ldu     #obo_0F                         ;   byte46 px2-3
        ldx     #obo_h4w1
        lda     #46
        ldb     #161
        jsr     HAL_gfx_blit_sprite_masked
        clr     <blit_subbyte                   ; L mid: orange px190 -> outline px188-189
        ldu     #obo_F0                         ;   byte47 px0-1
        ldx     #obo_h6w1
        lda     #47
        ldb     #155
        jsr     HAL_gfx_blit_sprite_masked
        clr     <blit_subbyte                   ; L top: orange px192 -> outline px190-191
        ldu     #obo_0F                         ;   byte47 px2-3
        ldx     #obo_h2w1
        lda     #47
        ldb     #153
        jsr     HAL_gfx_blit_sprite_masked
        clr     <blit_subbyte                   ; L step-around: flare OUT to px184-185 at the
        ldu     #obo_F0                         ;   bottom (rows162-164) to blend into the feet
        ldx     #obo_h3w1                        ;   opaque (edge px184). byte46 px0-1.
        lda     #46
        ldb     #162
        jsr     HAL_gfx_blit_sprite_masked
        ; LEFT-foot gap (Jay): cut a 2px black notch into the figure's edge at
        ; px181-182 (byte45 px1-2) on each floor line by the leg, so the floor
        ; (which shows to px180 via the transparent edge) is separated from the
        ; leg/robe. Gaps cut INTO the edge (px181-182), not the floor (px179-180).
        clr     <blit_subbyte                   ; gap px181-182 (byte45 px1-2) on each floor row,
        ldu     #obo_3F                         ;   r165 is the leg's thin top (only px181-183) so
        ldx     #obo_h1w1                       ;   gap px181-183 to absorb its lone pixel (no dot)
        lda     #45                             ;   can't move further right without eating it.
        ldb     #165
        jsr     HAL_gfx_blit_sprite_masked
        clr     <blit_subbyte                   ; r167: gap px181-184 (obo_3FC0 + width-2 sprite) so
        ldu     #obo_3FC0                       ;   the foot is px185 here, matching the ankle below
        ldx     #obo_h1w2                       ;   (the px183-184 protrusion was a stray line).
        lda     #45
        ldb     #167
        jsr     HAL_gfx_blit_sprite_masked
        clr     <blit_subbyte                   ; r169
        ldu     #obo_3C
        ldx     #obo_h1w1
        lda     #45
        ldb     #169
        jsr     HAL_gfx_blit_sprite_masked
        clr     <blit_subbyte                   ; r171
        ldu     #obo_3C
        ldx     #obo_h1w1
        lda     #45
        ldb     #171
        jsr     HAL_gfx_blit_sprite_masked
        ; Extend floor lines 7/8/9 toward Akuma to per-line endpoints (Jay): draw
        ; floor blue over the gaps. 9th(r165)->px184, 8th(r167)->px183, 7th(r169)->px181.
        clr     <blit_subbyte                   ; 9th (r165): floor to px184 (blue px181-184)
        ldu     #obo_3FC0                       ;   byte45 px1-3 + byte46 px0
        ldx     #floor_ext4
        lda     #45
        ldb     #165
        jsr     HAL_gfx_blit_sprite_masked
        clr     <blit_subbyte                   ; 8th (r167): floor to px183 (blue px181-183)
        ldu     #obo_3F                         ;   byte45 px1-3
        ldx     #floor_ext3
        lda     #45
        ldb     #167
        jsr     HAL_gfx_blit_sprite_masked
        clr     <blit_subbyte                   ; 7th (r169): floor to px181 (blue px181 only)
        ldu     #obo_30                         ;   byte45 px1
        ldx     #floor_ext1
        lda     #45
        ldb     #169
        jsr     HAL_gfx_blit_sprite_masked
        ; RIGHT side — outline just right of the orange, stepping in (left) going up:
        clr     <blit_subbyte                   ; R bottom: orange px214 -> outline px215-216
        ldu     #obo_03C0                        ;   byte53 px3 + byte54 px0
        ldx     #obo_h4w2
        lda     #53
        ldb     #161
        jsr     HAL_gfx_blit_sprite_masked
        clr     <blit_subbyte                   ; R mid: orange px212 -> outline px213-214
        ldu     #obo_3C                         ;   byte53 px1-2
        ldx     #obo_h6w1
        lda     #53
        ldb     #155
        jsr     HAL_gfx_blit_sprite_masked
        clr     <blit_subbyte                   ; R top: orange px210 -> outline px211-212
        ldu     #obo_03C0                        ;   byte52 px3 + byte53 px0
        ldx     #obo_h2w2
        lda     #52
        ldb     #153
        jsr     HAL_gfx_blit_sprite_masked
        clr     <blit_subbyte                   ; R step-out (LOWER): the LOWER lines (r165-168)
        ldu     #obo_3C                         ;   step OUT to px217-218 (floor px219) to clear
        ldx     #obo_h4w1                        ;   the opaque robe-bottom edge. byte54 px1-2.
        lda     #54
        ldb     #165
        jsr     HAL_gfx_blit_sprite_masked
        ; body 9EB8 (torso/robe) — TRANSPARENT. Occlusion of the princess behind
        ; Akuma is done by punch_akuma_stencil (fig_974B silhouette) BEFORE this;
        ; here we just paint his colors over the punched-black figure.
        clr     <blit_subbyte           ; body 9EB8: px180 (byte45 sub0)
        lda     #45
        ldb     #125
        ldx     #akuma_throne_room_9EB8_coco3
        jsr     HAL_gfx_blit_sprite
        rts                             ; --- end draw_akuma_lower ---

* draw_akuma_static — STATIC full figure, default pose (arm=frame_5, head=frame_1).
*   Backward-compat entry (the static composite driver calls this). The CONTROLLER
*   driver instead calls draw_akuma_body once + draw_akuma_arm/head per frame.
draw_akuma_static:
        jsr     draw_akuma_lower
        clr     <akuma_arm_idx          ; default arm pose 0 = frame_5
        lda     #AKUMA_CLK_DEFAULT      ; default clock -> head frame_1
        sta     <scene_clk
        jsr     draw_akuma_arm
        jsr     draw_akuma_head
        jsr     draw_pauldron
        rts

* draw_akuma_body — the static composite MINUS the arm/head.
draw_akuma_body:
        jsr     draw_akuma_lower
        jsr     draw_pauldron
        rts

* draw_akuma_full — the WHOLE figure (body + current arm + head). The controller
*   draws this OVER the princess each frame so Akuma always occludes her (she
*   shows through his transparent gaps = she is behind him). The body redraw
*   covers the arm region; the head clears its own cell (no ghosts).
draw_akuma_full:
        jsr     clear_akuma_arm         ; erase the PREVIOUS arm pose (union of f5/f6/f7)
        jsr     draw_akuma_body         ;   before the body repaints its robe edge over it
        jsr     draw_akuma_arm
        jsr     draw_akuma_head
        rts

* clear_akuma_arm — zero the arm's full swept bbox to black so a retreating pose
*   (e.g. frame_6 -> frame_7) leaves no ghost. Union of the three arm frames at
*   byte52/row128: f5(17x4) f6(19x6) f7(8x9) -> byte52-60 (w=9), row128-146 (h=19).
*   Behind the arm here is black backdrop + the robe's right edge (byte52-53), which
*   draw_akuma_body repaints immediately after.
*   ONLY fires on a pose CHANGE (akuma_clr_ctr, set to 2 by the tick, one per
*   double-buffer). The arm is a ONE-SHOT that raises early (princess still far
*   left) then HOLDS frame_7 static -> no clear once held, so the black box never
*   blacks the princess where she stands under his (now-static) arm at walk's end.
clear_akuma_arm:
        tst     <akuma_clr_ctr
        beq     cka_done                ; no recent pose change -> don't black under the arm
        dec     <akuma_clr_ctr
        lda     #52
        sta     <eng_col
        lda     #128
        sta     <eng_row
        lda     #9
        sta     <eng_clrw
        lda     #19
        sta     <eng_clrh
        clr     <eng_fillval
        jsr     eng_clear_box
cka_done:
        rts

* punch_akuma_stencil — occlude whatever is BEHIND Akuma (the princess) to black,
*   trimmed to his EXACT figure via the fig_974B silhouette mask (11=figure ->
*   punch black, 00=surround/interior-gap -> keep). Call this BEFORE draw_akuma_*
*   paints his colors, so she is hidden only where his shape actually is (arms,
*   pauldrons, body) and still shows through the gaps between his arms and body.
*   Anchor derived fresh (fig_974B trace pos byte~50/row119) — Jay-gate tunable.
AKUMA_STENCIL_COL equ 45
AKUMA_STENCIL_ROW equ 125
punch_akuma_stencil:
        ldx     #akuma_stencil
        lda     #AKUMA_STENCIL_COL
        ldb     #AKUMA_STENCIL_ROW
        jsr     HAL_gfx_blit_stencil_punch
        rts

* draw_akuma_arm — AMBIENT arm pose (HS-1, free loop). akuma_arm_idx 0/1/2 ->
*   frame_5(98D3 hip)/frame_6(9908 raised)/frame_7(9956 pointing). Fixed spot
*   byte52 row128 (the gated frame_5 position).
draw_akuma_arm:
        clr     <blit_subbyte
        lda     <akuma_arm_idx
        asla                            ; word index
        ldx     #akuma_arm_tbl
        ldx     a,x                     ; X = arm frame ptr
        lda     #52
        ldb     #128
        jsr     HAL_gfx_blit_sprite     ; transparent; occlusion via punch_akuma_stencil
        rts

* draw_akuma_head — head tracks the princess (HS-2 single-source): read scene_clk
*   ($42, the $3B-analog she writes) and pick the frame per the 5-zone table
*   (15-17->f1, 18-19->f2, 1A-1B->f3, 1C-1D->f4, 1E-22->f8). Fixed byte49 row117 sub2.
draw_akuma_head:
        ; --- opaque-trim only the two HIGH frames (f4/f8): by the time scene_clk
        ;     reaches $1C+ the princess is in front of Akuma, so her body would show
        ;     through the head's black. Punch the head silhouette (span-fill stencil,
        ;     2px-shifted to match sub-byte 2) BEFORE drawing the head. f1/f2/f3 are
        ;     early (she's far left) and need no trim. ---
        lda     <scene_clk
        cmpa    #$1C
        blo     dah_nopunch
        ldx     #akuma_head4_stencil
        cmpa    #$1E
        blo     dah_dopunch
        ldx     #akuma_head8_stencil
dah_dopunch:
        lda     #49                     ; byte-aligned (shift baked into the stencil)
        ldb     #117
        jsr     HAL_gfx_blit_stencil_punch
        lda     <scene_clk              ; reload (punch clobbered A)
dah_nopunch:
        ldx     #akuma_frame_1_coco3
        cmpa    #$18
        blo     dah_go
        ldx     #akuma_frame_2_coco3
        cmpa    #$1A
        blo     dah_go
        ldx     #akuma_frame_3_coco3
        cmpa    #$1C
        blo     dah_go
        ldx     #akuma_frame_4_coco3
        cmpa    #$1E
        blo     dah_go
        ldx     #akuma_frame_8_coco3
dah_go:
        lda     #2
        sta     <blit_subbyte
        lda     #49
        ldb     #117
        jsr     HAL_gfx_blit_sprite     ; transparent; occlusion via the head stencil punch
        rts

* draw_pauldron — the right-shoulder pauldron overlay (static; masked blit).
draw_pauldron:
        clr     <blit_subbyte
        ldu     #paul_pt_mask
        ldx     #paul_pt
        lda     #53                     ; px213-218 orange + point (white px210-212 kept)
        ldb     #125
        jsr     HAL_gfx_blit_sprite_masked
        rts

* akuma_ctrl_tick — per-VBL: ONE-SHOT arm animation (Jay): step through the poses
*   (frame_5 -> 6 -> 7) once, then HOLD at the RAISED pose (frame_6) and stop.
akuma_ctrl_tick:
        tst     <akuma_arm_done
        bne     act_done                ; already held raised — stay put
        dec     <akuma_arm_ctr
        bne     act_done
        lda     #AKUMA_ARM_CAD
        sta     <akuma_arm_ctr
        lda     <akuma_arm_idx
        inca                            ; 0(hip) -> 1(raised)
        sta     <akuma_arm_idx
        ldb     #2                      ; pose CHANGED -> clear the old arm box for 2 frames
        stb     <akuma_clr_ctr          ;   (both double-buffers), then stop (no princess-blacking)
        cmpa    #AKUMA_ARM_RAISED       ; reached the raised pose (no overshoot to frame_7)?
        blo     act_done                ; not yet -> keep animating
        lda     #1
        sta     <akuma_arm_done         ; raised -> hold here (stop before frame_7)
act_done:
        rts

akuma_arm_tbl:                          ; one-shot raise (Jay: f6=mid, f7=fully raised)
        fdb     akuma_frame_5_coco3     ; 0: 98D3 hand-on-hip (start)
        fdb     akuma_frame_6_coco3     ; 1: 9908 mid arm-raise (middle)
        fdb     akuma_frame_7_coco3     ; 2: 9956 fully raised (final, held)

* entry: fdb ptr ; fcb apple_x, apple_y, mirror(0/1), opaque(0/1)
* AUTHORITATIVE positions + draw order from the blit-entry trace (akuma_trace.log,
* probe_akuma2.do — the initial src/pos before the blit walks $03/$04). All the
* body parts share apple x~$17 (byte45) so the figure stacks coherently.
* 974B dropped — Jay: it renders as a reverse/doubled image (symmetric white
* flanks) and doesn't belong. 9EB8 is the real (single) Akuma body.
* feet drawn separately via the POSITIONAL-MASK blit (above). Jay: the feet
* sprite is solid (opaque) EXCEPT a 1px-wide transparent vertical strip on the
* LEFT edge and a 2px-wide one on the RIGHT edge, full sprite height. The mask
* is one byte per column (4px, 2bpp, MSB-first): bit-pair 11 -> take source
* (opaque), 00 -> keep dest (transparent/see-through).
*   col0  $3F = 00 11 11 11  -> px0 see-through, px1-3 solid
*   col10 $F0 = 11 11 00 00  -> px0-1 solid, px2-3 see-through
*   cols1-9 $FF              -> fully solid
akuma_feet_mask:
        fcb     $3F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$F0
* akuma_stencil — the fig_974B silhouette as a 2D punch mask (generated from
* content/akuma/fig_974B: per pixel 11 where NOT white, 00 where white). White in
* fig_974B is precisely "not-Akuma" (outer surround AND the interior armpit gaps),
* so this trims the princess-occlusion to his exact figure. Used by
* punch_akuma_stencil via HAL_gfx_blit_stencil_punch.
akuma_stencil:
        fcb     43,11                ; stencil 43x11: 11=Akuma figure, 00=not-Akuma
*   (col10/byte10 forced 00 — trimmed the fig_974B doubled far-right artifact that
*    read as a spurious opaque vertical line over the princess's end position.)
        fcb     $0F,$FF,$FF,$FC,$3F,$FF,$F0,$00,$00,$00,$00  ; row 0
        fcb     $0F,$FF,$FF,$FC,$3F,$FF,$F0,$00,$00,$00,$00  ; row 1
        fcb     $FF,$0F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00  ; row 2
        fcb     $00,$0F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$F0,$00  ; row 3
        fcb     $00,$03,$FF,$FF,$FF,$FF,$FF,$FF,$F0,$00,$00  ; row 4
        fcb     $00,$0F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00  ; row 5
        fcb     $00,$3F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00  ; row 6
        fcb     $00,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00  ; row 7
        fcb     $00,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00  ; row 8
        fcb     $00,$00,$3F,$FF,$FF,$FF,$FF,$FF,$00,$03,$00  ; row 9
        fcb     $00,$00,$03,$FF,$FF,$FF,$FF,$FF,$00,$00,$00  ; row 10
        fcb     $00,$00,$03,$FF,$FF,$FF,$FF,$F0,$00,$00,$00  ; row 11
        fcb     $00,$00,$00,$3F,$FF,$FF,$FF,$F0,$00,$00,$00  ; row 12
        fcb     $00,$00,$00,$3F,$FF,$FF,$FF,$F0,$00,$00,$00  ; row 13
        fcb     $00,$00,$00,$03,$FF,$FF,$FF,$00,$00,$00,$00  ; row 14
        fcb     $00,$00,$00,$03,$FF,$FF,$FF,$00,$00,$00,$00  ; row 15
        fcb     $00,$00,$00,$00,$FF,$FF,$F0,$00,$00,$00,$00  ; row 16
        fcb     $00,$00,$00,$00,$FF,$FF,$F0,$00,$00,$00,$00  ; row 17
        fcb     $00,$00,$0F,$FF,$FF,$FF,$FF,$00,$00,$00,$00  ; row 18
        fcb     $00,$00,$0F,$FF,$FF,$FF,$FF,$00,$00,$00,$00  ; row 19
        fcb     $00,$00,$FF,$FF,$FF,$FF,$FF,$F0,$00,$00,$00  ; row 20
        fcb     $00,$03,$FF,$FF,$FF,$FF,$FF,$F0,$00,$00,$00  ; row 21
        fcb     $00,$00,$00,$3F,$FF,$FF,$FF,$F0,$00,$00,$00  ; row 22
        fcb     $00,$00,$00,$3F,$FF,$FF,$FF,$F0,$00,$00,$00  ; row 23
        fcb     $00,$00,$00,$3F,$FF,$FF,$FF,$F0,$00,$00,$00  ; row 24
        fcb     $00,$00,$00,$3F,$FF,$FF,$FF,$F0,$00,$00,$00  ; row 25
        fcb     $00,$00,$03,$FF,$FF,$FF,$FF,$FF,$00,$00,$00  ; row 26
        fcb     $00,$00,$03,$FF,$FF,$FF,$FF,$FF,$00,$00,$00  ; row 27
        fcb     $00,$00,$03,$FF,$FF,$FF,$FF,$FF,$00,$00,$00  ; row 28
        fcb     $00,$00,$03,$FF,$FF,$FF,$FF,$FF,$00,$00,$00  ; row 29
        fcb     $00,$00,$03,$FF,$FF,$FF,$FF,$FF,$00,$00,$00  ; row 30
        fcb     $00,$00,$03,$FF,$FF,$FF,$FF,$FF,$00,$00,$00  ; row 31
        fcb     $00,$00,$3F,$FF,$FF,$FF,$FF,$FF,$F0,$00,$00  ; row 32
        fcb     $00,$00,$3F,$FF,$FF,$FF,$FF,$FF,$F0,$00,$00  ; row 33
        fcb     $00,$00,$3F,$FF,$FF,$FF,$FF,$FF,$F0,$00,$00  ; row 34
        fcb     $00,$00,$3F,$FF,$FF,$FF,$FF,$FF,$F0,$00,$00  ; row 35
        fcb     $00,$00,$3F,$FF,$FF,$FF,$FF,$FF,$F0,$00,$00  ; row 36
        fcb     $00,$00,$3F,$FF,$FF,$FF,$FF,$FF,$F0,$00,$00  ; row 37
        fcb     $00,$03,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00,$00  ; row 38
        fcb     $00,$03,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00,$00  ; row 39
        fcb     $00,$03,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00,$00  ; row 40
        fcb     $00,$03,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00,$00  ; row 41
        fcb     $00,$03,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00,$00  ; row 42
* akuma_head4/head8 stencil — FILLED silhouette of the two HIGH head frames:
* opaque where (row-span OR col-span) of the non-black pixels, so the eye AND the
* per-row notches between wider rows are filled (no princess show-through there),
* while the true outer corners stay trimmed. Shifted right 2px so a byte-aligned
* punch at byte49 lands under the sub-byte-2 head blit. Punched by draw_akuma_head
* for scene_clk >= $1C, AFTER the princess is drawn -> her body can't show through.
akuma_head4_stencil:
        fcb     8,4
        fcb     $00,$0F,$F0,$00  ; row 0
        fcb     $00,$0F,$FF,$00  ; row 1
        fcb     $00,$0F,$FF,$C0  ; row 2
        fcb     $00,$3F,$FF,$C0  ; row 3
        fcb     $00,$3F,$FF,$C0  ; row 4
        fcb     $00,$3F,$FF,$C0  ; row 5
        fcb     $00,$0F,$FF,$C0  ; row 6
        fcb     $00,$0F,$FF,$C0  ; row 7
akuma_head8_stencil:
        fcb     8,4
        fcb     $00,$3F,$C0,$00  ; row 0
        fcb     $00,$3F,$FF,$00  ; row 1
        fcb     $00,$3F,$FF,$C0  ; row 2
        fcb     $00,$3F,$FF,$C0  ; row 3
        fcb     $00,$3F,$FF,$C0  ; row 4
        fcb     $00,$3F,$FF,$C0  ; row 5
        fcb     $00,$0F,$FF,$C0  ; row 6
        fcb     $00,$0F,$FF,$C0  ; row 7
* 2px robe outline (Jay): all-$00 (black) blocks, blitted via positional masks
* to stairstep a 2px border up the robe's flaring sides. Heights = band sizes
* (bottom rows161-164=4, mid 155-160=6, top 153-154=2); widths 1 or 2 bytes.
obo_h4w1:   fcb 4,1
            fcb $00,$00,$00,$00
obo_h6w1:   fcb 6,1
            fcb $00,$00,$00,$00,$00,$00
obo_h2w1:   fcb 2,1
            fcb $00,$00
obo_h3w1:   fcb 3,1
            fcb $00,$00,$00
obo_h4w2:   fcb 4,2
            fcb $00,$00,$00,$00,$00,$00,$00,$00
obo_h2w2:   fcb 2,2
            fcb $00,$00,$00,$00
obo_h1w2:   fcb 1,2
            fcb $00,$00
obo_h1w1:   fcb 1,1
            fcb $00
floor_ext1: fcb 1,1          ; floor ext, 1px : px1 = blue (-> px181)
            fcb $20
floor_ext3: fcb 1,1          ; floor ext, 3px : px1-3 = blue (-> px181-183)
            fcb $2A
floor_ext4: fcb 1,2          ; floor ext, 4px : px1-3 + next px0 = blue (-> px181-184)
            fcb $2A,$80
obo_30:     fcb $30          ; px1 only
* Right-pauldron: ORANGE (index 1) extension to px218 (rows 125-126) + a single
* orange point pixel at r124/px218. byte53 px1-3=px213-215, byte54 px0-2=px216-218.
* Orange nibble=01: byte53 px1-3 = $15 ; byte54 px0-2 = $54 ; byte54 px2 only = $04.
paul_pt:    fcb 2,2
            fcb $15,$55    ; r125 (top line): orange px213-219 (point extends RIGHT to px219)
            fcb $15,$00    ; r126 (2nd line): orange px213-215 only (shortened 3px left to px215)
paul_pt_mask: fcb $3F,$FF
obo_h8w2:   fcb 8,2
            fcb $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
obo_0F:     fcb $0F          ; right 2px of the byte
obo_F0:     fcb $F0          ; left 2px of the byte
obo_3C:     fcb $3C          ; middle 2px (px1-2)
obo_FC:     fcb $FC          ; left 3px (px0-2)
obo_3F:     fcb $3F          ; px1-3 (3px, all but the leftmost)
obo_3FC0:   fcb $3F,$C0      ; px1-3 of byte N + px0 of byte N+1 (4px, straddles boundary)
obo_03C0:   fcb $03,$C0      ; px3 of byte N + px0 of byte N+1 (straddles boundary)
obo_03F0:   fcb $03,$F0      ; px3 of byte N + px0-1 of byte N+1 (3px, straddles boundary)
* ground shadow — opaque black, same size as the princess's (2 rows x 13 bytes).
akuma_shadow_spr:
        fcb     2,13
        fcb     $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        fcb     $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

* --- akuma content ---
        include "../../content/akuma/fig_974B/converted.s"
        include "../../content/akuma/akuma_throne_room_9EB8/converted.s"
        include "../../content/akuma/akuma_elem_984F/converted.s"
        include "../../content/akuma/akuma_feet_9F8C/converted.s"
        include "../../content/akuma/akuma_frame_1/converted.s"
        include "../../content/akuma/akuma_frame_2/converted.s"
        include "../../content/akuma/akuma_frame_3/converted.s"
        include "../../content/akuma/akuma_frame_4/converted.s"
        include "../../content/akuma/akuma_frame_8/converted.s"
        include "../../content/akuma/akuma_frame_5/converted.s"
        include "../../content/akuma/akuma_frame_6/converted.s"
        include "../../content/akuma/akuma_frame_7/converted.s"
