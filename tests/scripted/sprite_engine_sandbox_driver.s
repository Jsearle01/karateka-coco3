* tests/scripted/sprite_engine_sandbox_driver.s
*
* Sprite/animation ENGINE SANDBOX (R-engine) — scene-5 CAST set-select.
*
* Exercises the REAL single-source engine (src/engine/sprite_engine.s) + REAL
* HAL by INCLUDE (never a copy). Boot-excluded (AC-5): built only by
* run_sprite_engine_sandbox.bat/.sh, never on the production boot path.
*
* Cycles the scene-5 cast (found by execution trace; Jay-IDed) as N animation
* sets so each can be confirmed animated in-context. The sets are DATA; the
* engine is generic. Sprites converted UNLABELED by structural handle / address.
*
* CONTROLS (live confirm) — the current SET free-runs its frames:
*   TAP any key -> next set (wraps); buffers cleared, set reloaded at frame 0.
* Set order (tap to advance):
*   0 akuma_gloat   1 akuma_full(throne+robe/feet)   2 princess_walk(legs)
*   3 princess_fall  4 princess_poses(stand/turn/torso/body)   5 guard
*   6 eagle          7 props(cell door / banner)
*
* VBL-locked (real GIME VBL IRQ via andcc #$EF); true 60 fps at real-time.
* [ref: docs/scene5-cast-map.md — handle->identity, found by trace]
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

A_COL           equ 28
A_ROW           equ 60
CAD             equ 10              ; VBLs/frame (~6 fps) — TUNABLE
NSETS           equ 8

sb_prevkey      equ $40
sb_set          equ $42

FB_A_LO         equ $8000
FB_A_HI         equ $BC00
FB_B_LO         equ $C000
FB_B_HI         equ $FC00

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

        clr     <sb_prevkey
        clr     <sb_set
        jsr     load_current_set

sandbox_loop:
        jsr     HAL_time_vbl_wait
        jsr     HAL_input_poll
        bcc     sb_no_key
        lda     <sb_prevkey
        bne     sb_held
        lda     #$01
        sta     <sb_prevkey
        inc     <sb_set
        lda     <sb_set
        cmpa    #NSETS
        blo     sb_do_load
        clr     <sb_set
sb_do_load:
        jsr     load_current_set
        bra     sandbox_loop
sb_held:
        bra     sandbox_loop
sb_no_key:
        clr     <sb_prevkey
        jsr     eng_tick
        bra     sandbox_loop

load_current_set:
        jsr     clear_both_buffers
        lda     <sb_set
        asla
        ldx     #set_table_ptrs
        leax    a,x
        ldx     ,x
        jsr     eng_anim_init
        rts

clear_both_buffers:
        ldx     #FB_A_LO
        ldd     #$0000
cbb_a:
        std     ,x++
        cmpx    #FB_A_HI
        blo     cbb_a
        ldx     #FB_B_LO
cbb_b:
        std     ,x++
        cmpx    #FB_B_HI
        blo     cbb_b
        rts

* ===============================================================
* SET TABLES — header: count, cadence, clear_w, clear_h.
*   entry: fdb sprite_ptr ; fcb byte_col, subbyte, row.
* ===============================================================
set_table_ptrs:
        fdb     set0_akuma_gloat,set1_akuma_full,set2_princess_walk,set3_princess_fall
        fdb     set4_princess_poses,set5_guard,set6_eagle,set7_props

* --- 0: Akuma gloat (heads/torso/arm) ---
set0_akuma_gloat:
        fcb     9,CAD,10,19
        fdb     akuma_frame_0_coco3
        fcb     A_COL,0,A_ROW
        fdb     akuma_frame_1_coco3
        fcb     A_COL,0,A_ROW
        fdb     akuma_frame_2_coco3
        fcb     A_COL,0,A_ROW
        fdb     akuma_frame_3_coco3
        fcb     A_COL,0,A_ROW
        fdb     akuma_frame_4_coco3
        fcb     A_COL,0,A_ROW
        fdb     akuma_frame_5_coco3
        fcb     A_COL,0,A_ROW
        fdb     akuma_frame_6_coco3
        fcb     A_COL,0,A_ROW
        fdb     akuma_frame_7_coco3
        fcb     A_COL,0,A_ROW
        fdb     akuma_frame_8_coco3
        fcb     A_COL,0,A_ROW

* --- 1: Akuma full (throne torso + robe-bottom/feet) ---
set1_akuma_full:
        fcb     2,CAD,12,42
        fdb     akuma_throne_room_9EB8_coco3
        fcb     A_COL,0,A_ROW
        fdb     akuma_feet_9F8C_coco3
        fcb     A_COL,0,A_ROW

* --- 2: Princess walking legs ($1D36/$1D5A/$1D7E/$1DA2) ---
set2_princess_walk:
        fcb     4,CAD,7,17
        fdb     fig_1D36_coco3
        fcb     A_COL,0,A_ROW
        fdb     fig_1D5A_coco3
        fcb     A_COL,0,A_ROW
        fdb     fig_1D7E_coco3
        fcb     A_COL,0,A_ROW
        fdb     fig_1DA2_coco3
        fcb     A_COL,0,A_ROW

* --- 3: Princess falling ($175E/$16CC/$17D3/$1829) ---
set3_princess_fall:
        fcb     4,CAD,12,36
        fdb     fig_175E_coco3
        fcb     A_COL,0,A_ROW
        fdb     fig_16CC_coco3
        fcb     A_COL,0,A_ROW
        fdb     fig_17D3_coco3
        fcb     A_COL,0,A_ROW
        fdb     fig_1829_coco3
        fcb     A_COL,0,A_ROW

* --- 4: Princess poses (standing/turning, torso, body) ---
set4_princess_poses:
        fcb     6,CAD,7,43
        fdb     fig_1530_coco3
        fcb     A_COL,0,A_ROW
        fdb     fig_1867_coco3
        fcb     A_COL,0,A_ROW
        fdb     fig_1611_coco3
        fcb     A_COL,0,A_ROW
        fdb     fig_1588_coco3
        fcb     A_COL,0,A_ROW
        fdb     fig_169A_coco3
        fcb     A_COL,0,A_ROW
        fdb     fig_1D00_coco3
        fcb     A_COL,0,A_ROW

* --- 5: Guard (head / torso / below-torso) ---
set5_guard:
        fcb     3,CAD,7,24
        fdb     fig_8F2B_coco3
        fcb     A_COL,0,A_ROW
        fdb     fig_899C_coco3
        fcb     A_COL,0,A_ROW
        fdb     fig_8ACB_coco3
        fcb     A_COL,0,A_ROW

* --- 6: Eagle (head / body / head) ---
set6_eagle:
        fcb     3,CAD,5,9
        fdb     s5_985c_eagle_head_coco3
        fcb     A_COL,0,A_ROW
        fdb     eagle_body_9FC4_coco3
        fcb     A_COL,0,A_ROW
        fdb     eagle_head_9FD8_coco3
        fcb     A_COL,0,A_ROW

* --- 7: Props (cell door / "the end" banner) ---
set7_props:
        fcb     2,CAD,18,75
        fdb     s5_9980_cell_door_coco3
        fcb     A_COL,0,A_ROW
        fdb     s5_9a74_banner_coco3
        fcb     A_COL,0,A_ROW

* ===============================================================
* REAL engine + REAL HAL (single source of truth).
* ===============================================================
        include "../../src/engine/sprite_engine.s"
        include "../../src/hal/coco3-dsk/sys.s"
        include "../../src/hal/coco3-dsk/irq_vbl.s"
        include "../../src/hal/coco3-dsk/gfx.s"
        include "../../src/hal/coco3-dsk/time.s"
        include "../../src/hal/coco3-dsk/input.s"

* ===============================================================
* Cast sprite data (converted by handle/address; untracked per rule).
* ===============================================================
* Akuma gloat
        include "../../content/akuma_frame_0/converted.s"
        include "../../content/akuma_frame_1/converted.s"
        include "../../content/akuma_frame_2/converted.s"
        include "../../content/akuma_frame_3/converted.s"
        include "../../content/akuma_frame_4/converted.s"
        include "../../content/akuma_frame_5/converted.s"
        include "../../content/akuma_frame_6/converted.s"
        include "../../content/akuma_frame_7/converted.s"
        include "../../content/akuma_frame_8/converted.s"
* Akuma full (throne torso + robe/feet)
        include "../../content/akuma_throne_room_9EB8/converted.s"
        include "../../content/akuma_feet_9F8C/converted.s"
* Princess walking legs
        include "../../content/fig_1D36/converted.s"
        include "../../content/fig_1D5A/converted.s"
        include "../../content/fig_1D7E/converted.s"
        include "../../content/fig_1DA2/converted.s"
* Princess falling
        include "../../content/fig_175E/converted.s"
        include "../../content/fig_16CC/converted.s"
        include "../../content/fig_17D3/converted.s"
        include "../../content/fig_1829/converted.s"
* Princess poses
        include "../../content/fig_1530/converted.s"
        include "../../content/fig_1867/converted.s"
        include "../../content/fig_1611/converted.s"
        include "../../content/fig_1588/converted.s"
        include "../../content/fig_169A/converted.s"
        include "../../content/fig_1D00/converted.s"
* Guard
        include "../../content/fig_8F2B/converted.s"
        include "../../content/fig_899C/converted.s"
        include "../../content/fig_8ACB/converted.s"
* Eagle
        include "../../content/s5_985c_eagle_head/converted.s"
        include "../../content/eagle_body_9FC4/converted.s"
        include "../../content/eagle_head_9FD8/converted.s"
* Props
        include "../../content/s5_9980_cell_door/converted.s"
        include "../../content/s5_9a74_banner/converted.s"

        end     test_start
