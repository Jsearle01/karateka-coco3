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
AKUMA_SHADOW    equ 0                   ; shadow temporarily OFF (Jay) — re-enable =1
draw_akuma_static:
        ; ground shadow — opaque black, ~3 floor-lines tall, from his feet
        ; extending all the way to the RIGHT of the scene (Jay). Drawn before the
        ; parts (over the floor, under Akuma).
    ifne AKUMA_SHADOW
        lda     #44
        sta     <eng_col
        lda     #165
        sta     <eng_row
        lda     #28                     ; byte44..72 -> right edge of the scene
        sta     <eng_clrw
        lda     #6                      ; ~3 blue floor lines
        sta     <eng_clrh
        clr     <eng_fillval            ; black
        jsr     eng_clear_box
    endc
        ldu     #akuma_static_tbl
        jsr     draw_setdressing
        ; head — placed by PIXEL (apple-col steps are 7px, too coarse to centre
        ; the head on the body). px198 = byte 49, sub 2. Drawn last (on top).
        ; (The controller swaps the head FRAME here per scene_clk; px is fixed.)
        lda     #3                      ; px199 (byte 49, sub 3) — 1px right of 198
        sta     <blit_subbyte
        lda     #49
        ldb     #117
        ldx     #akuma_frame_1_coco3
        jsr     HAL_gfx_blit_sprite
        rts

* entry: fdb ptr ; fcb apple_x, apple_y, mirror(0/1), opaque(0/1)
* AUTHORITATIVE positions + draw order from the blit-entry trace (akuma_trace.log,
* probe_akuma2.do — the initial src/pos before the blit walks $03/$04). All the
* body parts share apple x~$17 (byte45) so the figure stacks coherently.
* 974B dropped — Jay: it renders as a reverse/doubled image (symmetric white
* flanks) and doesn't belong. 9EB8 is the real (single) Akuma body.
akuma_static_tbl:
        fdb     akuma_feet_9F8C_coco3   ; feet / robe-bottom — transparent (see Jay note)
        fcb     23,163,0,0
        fdb     akuma_throne_room_9EB8_coco3 ; body (blue) — down 4 to meet feet (121->125)
        fcb     23,125,0,0
        fdb     akuma_frame_5_coco3     ; torso/arm default (98D3) — down 4 (124->128)
        fcb     27,128,0,0
        fdb     0                       ; terminator  (head drawn by pixel, after)

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
