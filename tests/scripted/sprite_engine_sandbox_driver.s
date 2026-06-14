* tests/scripted/sprite_engine_sandbox_driver.s
*
* Sprite/animation ENGINE SANDBOX (R-engine) — scene-5 cast set-select.
*
* Exercises the REAL single-source engine (src/engine/sprite_engine.s) +
* REAL HAL by INCLUDE (never a copy). Boot-excluded (AC-5): not on the
* production boot path; built only by run_sprite_engine_sandbox.bat/.sh.
*
* SCENE-5 CAST SET-SELECT (R cast scale-out): cycles N animation sets so
* Jay can visually ID each (princess / guard / Akuma / eagle / props). The
* sets are DATA (per-set tables below); the engine is generic. Identities
* attach at Jay's sandbox visual ID — sprites are converted UNLABELED by
* structural handle.
*
* CONTROLS (P4/AC-4 live gate) — the current set FREE-RUNS its frames:
*   - TAP any key:  advance to the NEXT set (wraps); buffers cleared, set
*                   reloaded at frame 0, then free-runs.
*   Set order (so Jay can name what he sees): see SET TABLE comments below.
*   (Frame-level single-step was the R-engine proof; cast ID wants set-level
*    selection + auto frame cycling — proven separately by the trace driver.)
*
* TIMING: VBL-locked (real GIME VBL IRQ via andcc #$EF after HAL_time_init);
*   true 60 fps at real-time.
*
* [ref: src/engine/sprite_engine.s — the engine under test]
* [ref: docs/scene5-cast-map.md — handle->identity mapping]
* ---------------------------------------------------------------

        org     $0100
        rti                             ; $0100 SWI3
        nop
        nop
        rti                             ; $0103 SWI2
        nop
        nop
        rti                             ; $0106 SWI
        nop
        nop
        rti                             ; $0109 NMI
        nop
        nop
        rti                             ; $010C IRQ  (patched -> hal_vbl_handler)
        nop
        nop
        rti                             ; $010F FIRQ
        nop
        nop

        org     $0200
        setdp   0

        include "../../src/engine/globals.s"

* Common anchor (all sets render here; sized for the largest = akuma throne).
A_COL           equ 28
A_ROW           equ 60
CAD             equ 10              ; VBLs/frame (~6 fps) — TUNABLE, Jay-gated
NSETS           equ 7

* Sandbox-local state ($40-$42; clear of eng_* $30-$3A).
sb_prevkey      equ $40             ; nonzero = key was down on previous poll (edge det)
sb_set          equ $42             ; current set index 0..NSETS-1

* Frame-buffer extents (clear-both bound; stop below $FF00 GIME I/O).
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
        andcc   #$EF                ; opt in to real VBL IRQ

        clr     <sb_prevkey
        clr     <sb_set
        jsr     load_current_set    ; set 0 -> render frame 0, free-run

* ---------------------------------------------------------------
* Run loop: free-run the current set's frames; TAP = next set.
* ---------------------------------------------------------------
sandbox_loop:
        jsr     HAL_time_vbl_wait
        jsr     HAL_input_poll      ; CC.C set = key down
        bcc     sb_no_key

        lda     <sb_prevkey
        bne     sb_held             ; was down: ignore until release
        * rising edge -> advance to next set (wrap)
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
        jsr     eng_tick            ; free-run current set's frame cycle
        bra     sandbox_loop

* ---------------------------------------------------------------
* load_current_set — clear both buffers, then eng_anim_init(table[sb_set]).
* Full clear avoids cross-set residue (sets vary widely in size/position).
* ---------------------------------------------------------------
load_current_set:
        jsr     clear_both_buffers
        lda     <sb_set
        asla                        ; *2 (16-bit table-pointer slots)
        ldx     #set_table_ptrs
        leax    a,x
        ldx     ,x                  ; X = this set's anim-table pointer
        jsr     eng_anim_init
        rts

* clear_both_buffers — zero $8000-$BBFF and $C000-$FBFF (not into $FFxx GIME).
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
*   entry (xN): fdb sprite_ptr ; fcb byte_col, subbyte, row.
* All frames anchored at (A_COL, A_ROW), sub 0. clear_w/h cover each set's
* largest frame. SET ORDER (what Jay sees, tap to advance):
*   0 akuma_gloat   1 walk_legs   2 walk_torso   3 akuma_throne
*   4 eagle         5 figures     6 props
* ===============================================================
set_table_ptrs:
        fdb     set0_akuma_gloat,set1_walk_legs,set2_walk_torso
        fdb     set3_akuma_throne,set4_eagle,set5_figures,set6_props

* --- SET 0: Akuma gloat (heads/torso/arm, $9879-$9a62) — 9 frames ---
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

* --- SET 1: walk legs ($9B00-$9D1E) — 8 frames (princess-walk candidate) ---
set1_walk_legs:
        fcb     8,CAD,11,24
        fdb     player_run_legs_9B00_coco3
        fcb     A_COL,0,A_ROW
        fdb     player_run_legs_9B6B_coco3
        fcb     A_COL,0,A_ROW
        fdb     player_run_legs_9BE5_coco3
        fcb     A_COL,0,A_ROW
        fdb     player_run_legs_9C1B_coco3
        fcb     A_COL,0,A_ROW
        fdb     player_run_legs_9C65_coco3
        fcb     A_COL,0,A_ROW
        fdb     player_run_legs_9CAF_coco3
        fcb     A_COL,0,A_ROW
        fdb     player_run_legs_9CD7_coco3
        fcb     A_COL,0,A_ROW
        fdb     player_run_legs_9D1E_coco3
        fcb     A_COL,0,A_ROW

* --- SET 2: walk torso ($9D68-$9E92) — 8 frames ---
set2_walk_torso:
        fcb     8,CAD,7,23
        fdb     player_run_torso_9D68_coco3
        fcb     A_COL,0,A_ROW
        fdb     player_run_torso_9D97_coco3
        fcb     A_COL,0,A_ROW
        fdb     player_run_torso_9DD5_coco3
        fcb     A_COL,0,A_ROW
        fdb     player_run_torso_9E05_coco3
        fcb     A_COL,0,A_ROW
        fdb     player_run_torso_9E2E_coco3
        fcb     A_COL,0,A_ROW
        fdb     player_run_torso_9E4A_coco3
        fcb     A_COL,0,A_ROW
        fdb     player_run_torso_9E74_coco3
        fcb     A_COL,0,A_ROW
        fdb     player_run_torso_9E92_coco3
        fcb     A_COL,0,A_ROW

* --- SET 3: Akuma throne-room full body + feet ($9EB8/$9F8C) — 2 frames ---
set3_akuma_throne:
        fcb     2,CAD,12,42
        fdb     akuma_throne_room_9EB8_coco3
        fcb     A_COL,0,A_ROW
        fdb     akuma_feet_9F8C_coco3
        fcb     A_COL,0,A_ROW

* --- SET 4: eagle (head $985c, body $9FC4, head $9FD8) — 3 frames ---
set4_eagle:
        fcb     3,CAD,5,9
        fdb     s5_985c_eagle_head_coco3
        fcb     A_COL,0,A_ROW
        fdb     eagle_body_9FC4_coco3
        fcb     A_COL,0,A_ROW
        fdb     eagle_head_9FD8_coco3
        fcb     A_COL,0,A_ROW

* --- SET 5: ambiguous figures ($9a18, $9a2a, $9858) — guard candidate ---
set5_figures:
        fcb     3,CAD,7,18
        fdb     s5_9a18_coco3
        fcb     A_COL,0,A_ROW
        fdb     s5_9a2a_coco3
        fcb     A_COL,0,A_ROW
        fdb     s5_9858_coco3
        fcb     A_COL,0,A_ROW

* --- SET 6: props (cell door $9980, "the end" banner $9a74) — 2 frames ---
set6_props:
        fcb     2,CAD,18,75
        fdb     s5_9980_cell_door_coco3
        fcb     A_COL,0,A_ROW
        fdb     s5_9a74_banner_coco3
        fcb     A_COL,0,A_ROW

* ===============================================================
* REAL engine + REAL HAL (included verbatim — single source of truth).
* ===============================================================
        include "../../src/engine/sprite_engine.s"
        include "../../src/hal/coco3-dsk/sys.s"
        include "../../src/hal/coco3-dsk/irq_vbl.s"
        include "../../src/hal/coco3-dsk/gfx.s"
        include "../../src/hal/coco3-dsk/time.s"
        include "../../src/hal/coco3-dsk/input.s"

* ===============================================================
* Cast sprite data — converted UNLABELED by structural handle.
* ===============================================================
* Akuma gloat ($9800 bank)
        include "../../content/akuma_frame_0/converted.s"
        include "../../content/akuma_frame_1/converted.s"
        include "../../content/akuma_frame_2/converted.s"
        include "../../content/akuma_frame_3/converted.s"
        include "../../content/akuma_frame_4/converted.s"
        include "../../content/akuma_frame_5/converted.s"
        include "../../content/akuma_frame_6/converted.s"
        include "../../content/akuma_frame_7/converted.s"
        include "../../content/akuma_frame_8/converted.s"
* Walk legs ($9B00 bank)
        include "../../content/player_run_legs_9B00/converted.s"
        include "../../content/player_run_legs_9B6B/converted.s"
        include "../../content/player_run_legs_9BE5/converted.s"
        include "../../content/player_run_legs_9C1B/converted.s"
        include "../../content/player_run_legs_9C65/converted.s"
        include "../../content/player_run_legs_9CAF/converted.s"
        include "../../content/player_run_legs_9CD7/converted.s"
        include "../../content/player_run_legs_9D1E/converted.s"
* Walk torso ($9B00 bank)
        include "../../content/player_run_torso_9D68/converted.s"
        include "../../content/player_run_torso_9D97/converted.s"
        include "../../content/player_run_torso_9DD5/converted.s"
        include "../../content/player_run_torso_9E05/converted.s"
        include "../../content/player_run_torso_9E2E/converted.s"
        include "../../content/player_run_torso_9E4A/converted.s"
        include "../../content/player_run_torso_9E74/converted.s"
        include "../../content/player_run_torso_9E92/converted.s"
* Akuma throne + feet, eagle body/head ($9B00 bank)
        include "../../content/akuma_throne_room_9EB8/converted.s"
        include "../../content/akuma_feet_9F8C/converted.s"
        include "../../content/eagle_body_9FC4/converted.s"
        include "../../content/eagle_head_9FD8/converted.s"
* Scene-5 bank props + figures ($9800 bank)
        include "../../content/s5_985c_eagle_head/converted.s"
        include "../../content/s5_9980_cell_door/converted.s"
        include "../../content/s5_9a74_banner/converted.s"
        include "../../content/s5_9a18/converted.s"
        include "../../content/s5_9a2a/converted.s"
        include "../../content/s5_9858/converted.s"

        end     test_start
