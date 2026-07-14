* src/engine/climb_controller.s
*
* CLIMB CRAWL CONTROLLER (R-engine) — parallels princess_controller.s: a per-
* character controller driving the ONE shared render leaf (HAL_gfx_blit_sprite),
* NOT a second engine. Plays the ratified 7-frame climb crawl (Jay-gated
* scene6_climb_anim_00-06) as a LIVE animation over the static climb substrate.
*
* FRAMES (torso+legs composite; settle = 3-part), CoCo3 registration computed by
* harness/tools/gen_climb_anim.py (place()+leading_trim(), the SAME registration
* as the draw_climb_startpose anchor — A3E9=byte21/sub3, A3C5=byte22/sub2 verified):
*   00 START  A3E9(21,3,158) A3C5(22,2,141)          dwell 21 VBL
*   01        A425(22,2,148) A40B(24,1,140)          dwell 7
*   02        A4A4(22,2,143) A45A(26,0,139)          dwell 7
*   03        A4F2(22,2,143) A4D2(24,1,137)          dwell 7
*   04        A572(22,2,141) A548(24,1,131)          dwell 7
*   05        A5DC(24,1,127) A5CC(26,0,120)          dwell 7
*   06 SETTLE 899C(25,2,138) 8ACB(25,2,124) 8E9B(26,0,116)  hold 60 -> loop
* Parts listed legs/lower FIRST (back), torso/upper/head over. Sub-byte via the
* EXISTING HAL blit (as the Jay-gated static start pose) — NOT new masked-blit.
*
* CLEAN-RESTORE: the cliff bg is non-uniform, so restore the actor bbox from a
* clean substrate copy (cl_clean) each step (scene-5 actor-composite pattern),
* NOT a flat eng_clear_box. Double-buffered: draw to back -> present -> toggle.
* ---------------------------------------------------------------

        setdp   0

cl_idx      equ $40         ; current frame 0..6
cl_dwctr    equ $41         ; dwell down-counter (VBL)
cl_pcnt     equ $42         ; part loop counter
cl_partp    equ $43         ; 16-bit current part pointer ($43/$44)

* actor bounding box (covers all 7 poses): byte cols 20..32, rows 112..167.
CL_BX0      equ 20          ; bbox left byte column
CL_BW       equ 13          ; bbox width (bytes)
CL_BY0      equ 112         ; bbox top row
CL_BH       equ 56          ; bbox height (rows)

* ===============================================================
* cl_init — snapshot the clean substrate bbox, render frame 0. The driver has
*   already drawn the static substrate into BOTH buffers; page_register = A.
* ===============================================================
cl_init:
        jsr     cl_save_clean           ; cl_clean <- buffer-A substrate bbox
        clr     <cl_idx
        jsr     cl_load_dwell
        jsr     cl_render
        rts

* ===============================================================
* cl_tick — per-VBL. Count down dwell; on expiry advance (wrap 6->0 = loop the
*   demo for the live gate) and render.
* ===============================================================
cl_tick:
        dec     <cl_dwctr
        beq     cl_advance
        rts
cl_advance:
        lda     <cl_idx
        inca
        cmpa    #7
        blo     cl_adv_store
        clra                            ; wrap to 0 (loop crawl-up for watchability)
cl_adv_store:
        sta     <cl_idx
        jsr     cl_load_dwell
        jsr     cl_render
        rts

* cl_frame_ptr — X -> frame data for cl_idx (dwell, partcount, parts...).
cl_frame_ptr:
        ldb     <cl_idx
        aslb                            ; *2 (fdb table)
        ldx     #cl_frames
        abx
        ldx     ,x                      ; X = frame data pointer
        rts

* cl_load_dwell — cl_dwctr <- frame's dwell byte.
cl_load_dwell:
        jsr     cl_frame_ptr
        lda     ,x
        sta     <cl_dwctr
        rts

* ===============================================================
* cl_render — clean-restore the bbox in the BACK buffer, blit the frame's parts
*   (back-to-front) via the shared leaf, present, toggle.
* ===============================================================
cl_render:
        jsr     cl_restore              ; substrate behind the actor
        jsr     cl_frame_ptr            ; X -> {dwell, pcnt, parts...}
        lda     1,x                     ; part count
        sta     <cl_pcnt
        leax    2,x                     ; X -> first part {fdb cel; fcb col,sub,row}
cl_r_loop:
        stx     <cl_partp
        lda     3,x                     ; sub-byte
        sta     <blit_subbyte
        lda     2,x                     ; A = byte col
        ldb     4,x                     ; B = row
        ldx     ,x                      ; X = cel pointer
        jsr     HAL_gfx_blit_sprite     ; the ONE shared render leaf
        ldx     <cl_partp
        leax    5,x                     ; next part
        dec     <cl_pcnt
        bne     cl_r_loop
        jsr     HAL_gfx_present         ; reveal the back buffer
        lda     <page_register
        eora    #$60                    ; toggle A<->B
        sta     <page_register
        rts

* ===============================================================
* cl_restore — copy cl_clean -> back-buffer bbox (removes the previous pose,
*   lands the transparency blit on the true substrate).
* ===============================================================
cl_restore:
        lda     <page_register
        cmpa    #PAGE_A_TOKEN
        bne     clr_b
        ldy     #$8000
        bra     clr_base
clr_b:
        ldy     #$C000
clr_base:
        ldd     #CL_BY0*80+CL_BX0
        leay    d,y                     ; Y = back base + bbox origin
        ldx     #cl_clean
        lda     #CL_BH
clr_row:
        pshs    a,y
        ldb     #CL_BW
clr_byte:
        lda     ,x+
        sta     ,y+
        decb
        bne     clr_byte
        puls    a,y
        leay    80,y
        deca
        bne     clr_row
        rts

* cl_save_clean — cl_clean <- buffer-A substrate bbox (both buffers identical here).
cl_save_clean:
        ldy     #$8000
        ldd     #CL_BY0*80+CL_BX0
        leay    d,y
        ldx     #cl_clean
        lda     #CL_BH
cls_row:
        pshs    a,y
        ldb     #CL_BW
cls_byte:
        lda     ,y+
        sta     ,x+
        decb
        bne     cls_byte
        puls    a,y
        leay    80,y
        deca
        bne     cls_row
        rts

* ===============================================================
* Animation data — 7 frames. cl_frames[idx] -> frame block {dwell, pcnt, parts};
* part = fdb cel_ptr ; fcb byte_col, sub, row.
* ===============================================================
cl_frames:
        fdb     cl_f0,cl_f1,cl_f2,cl_f3,cl_f4,cl_f5,cl_f6
cl_f0:  fcb     21,2
        fdb     scene6_climb_A3E9
        fcb     21,3,158
        fdb     scene6_climb_A3C5
        fcb     22,2,141
cl_f1:  fcb     7,2
        fdb     scene6_climb_A425
        fcb     22,2,148
        fdb     scene6_climb_A40B
        fcb     24,1,140
cl_f2:  fcb     7,2
        fdb     scene6_climb_A4A4
        fcb     22,2,143
        fdb     scene6_climb_A45A
        fcb     26,0,139
cl_f3:  fcb     7,2
        fdb     scene6_climb_A4F2
        fcb     22,2,143
        fdb     scene6_climb_A4D2
        fcb     24,1,137
cl_f4:  fcb     7,2
        fdb     scene6_climb_A572
        fcb     22,2,141
        fdb     scene6_climb_A548
        fcb     24,1,131
cl_f5:  fcb     7,2
        fdb     scene6_climb_A5DC
        fcb     24,1,127
        fdb     scene6_climb_A5CC
        fcb     26,0,120
cl_f6:  fcb     60,3
        fdb     scene6_player_899C
        fcb     25,2,138
        fdb     scene6_player_8ACB
        fcb     25,2,124
        fdb     scene6_player_8E9B
        fcb     26,0,116

cl_clean:
        rmb     CL_BW*CL_BH             ; 13*56 = 728 bytes: clean substrate bbox
