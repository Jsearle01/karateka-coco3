* tests/scripted/scene6_arch_test.s
*
* STANDALONE ARCH COMPOSITE TEST — draw the 14-cel arch ONCE, static, at the halt reference,
* over a plain blue-sky background. NO scroll, NO double-buffer, NO strip. This isolates the
* arch-drawing geometry from the scroll/buffer machinery so the composite can be verified in
* isolation (the wired-driver attempts thrashed on the moving-target double-buffering).
*
* Reads the SAME single-home table (scene6_arch_gen.s) the tool + driver use. Draws each cel at
* its table position directly (no delta) into buffer A, tiled pillars by their row range, then
* presents A and holds. Prod ROM ($88eba89...) untouched. Sandbox, boot-excluded.
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
        rti
        nop
        nop
        rti
        nop
        nop

        org     $0200
        setdp   0
        include "../../src/engine/globals.s"

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

        * plain blue sky across the whole screen (both buffers), then the arch static on top
        jsr     fill_blue_A
        jsr     draw_arch_static
        jsr     clip_legs_floor         ; emulate the scene floor occluding leg bottoms (rows 153+)
        jsr     draw_arch_base          ; the arch feet (A87B/A6EF/A6A6) sit ON the floor -> on top
        jsr     HAL_gfx_present         ; display buffer A

hold:
        jsr     HAL_time_vbl_wait
        bra     hold

* ---------------------------------------------------------------
* fill_blue_A — blue ($AAAA) over content cols 5..74, rows 0..191, buffer A.
* ---------------------------------------------------------------
clip_legs_floor:
* The scene floor (draw_climb_ground_right, rows 152+) occludes the arch leg bottoms in the oracle;
* the standalone test has no floor, so A684 (drawn to row 160) shows ~12 rows too long. Re-cover
* rows 153..180 cols 5..74 with sky here to emulate that clip (the real driver uses the true floor).
        lda     #153
fl_row:
        pshs    a
        ldb     #80
        mul
        addd    #$8005
        tfr     d,x
        ldd     #$AAAA
        ldy     #35
fl_b:
        std     ,x++
        leay    -1,y
        bne     fl_b
        puls    a
        inca
        cmpa    #181
        blo     fl_row
        rts

draw_arch_base:
* redraw the arch base cels (A87B row153, A6EF row153, A6A6 row159) on top of the floor clip.
        ldu     #arch_base_tbl
dab_l:
        ldx     ,u++                    ; cel (0 = end)
        beq     dab_done
        lda     1,u                     ; sub
        sta     <blit_subbyte
        lda     ,u                      ; col
        ldb     2,u                     ; row
        jsr     HAL_gfx_blit_sprite
        leau    3,u
        bra     dab_l
dab_done:
        rts
arch_base_tbl:  ; fdb cel; fcb col,sub,row  (halt positions)
        fdb     scene6_bg_A87B
        fcb     55,2,153
        fdb     scene6_bg_A6EF
        fcb     69,2,153
        fdb     scene6_bg_A6A6
        fcb     59,0,159
        fdb     0

fill_blue_A:
        ldy     #192
        ldx     #$8005
fb_row:
        pshs    x,y
        ldd     #$AAAA
        ldy     #35                     ; 70 content bytes = 35 words
fb_b:
        std     ,x++
        leay    -1,y
        bne     fb_b
        puls    x,y
        leax    80,x
        leay    -1,y
        bne     fb_row
        rts

* ---------------------------------------------------------------
* draw_arch_static — draw the 14 arch cels at their TABLE (halt) positions, no delta.
*   Entry: fdb cel ; fcb col, sub, row0, row1, step  (7 bytes). Tiled pillars draw row0..row1.
*   HAL_gfx_blit_sprite preserves U; still save/restore U across the loop for safety.
* ---------------------------------------------------------------
draw_arch_static:
        lda     arch_count
        sta     at_ct
        ldu     #arch_tbl
at_cel:
        ldx     ,u++                    ; X = cel, U -> col
        stx     at_celp
        lda     1,u                     ; sub
        sta     at_sub
        lda     ,u                      ; col
        sta     at_col
        lda     2,u                     ; row0
        sta     at_row
        lda     3,u                     ; row1
        sta     at_rend
        lda     4,u                     ; step
        sta     at_step
        stu     at_u
        * find this cel's opaque STENCIL (0 = none -> plain transparent blit only, black keyed).
        clr     at_stencil
        clr     at_stencil+1
        ldy     #arch_opacity_tbl
aop_find:
        ldx     ,y++                    ; cel (0 = end)
        beq     aop_have
        cmpx    at_celp
        beq     aop_got
        leay    2,y                     ; skip stencil ptr
        bra     aop_find
aop_got:
        ldx     ,y
        stx     at_stencil
aop_have:
at_row_loop:
        * (1) plain transparent blit: colours + KEYED black (index-0 shows the background)
        lda     at_sub
        sta     <blit_subbyte
        lda     at_col
        ldb     at_row
        ldx     at_celp
        jsr     HAL_gfx_blit_sprite
        * (2) punch the OPAQUE black via the pre-shifted stencil (byte-aligned), matching the tool
        ldx     at_stencil
        beq     at_nopunch
        clr     <blit_subbyte
        lda     at_col
        ldb     at_row
        ldx     at_stencil
        jsr     HAL_gfx_blit_stencil_punch
at_nopunch:
        lda     at_row
        adda    at_step
        sta     at_row
        cmpa    at_rend
        bls     at_row_loop
        ldu     at_u
        leau    5,u
        dec     at_ct
        bne     at_cel
        rts

* --- state ---
at_ct           fcb     0
at_celp         fdb     0
at_col          fcb     0
at_sub          fcb     0
at_row          fcb     0
at_rend         fcb     0
at_step         fcb     0
at_u            fdb     0
at_stencil      fdb     0

* --- palette (Jay-gated index-selected; same as the scroll driver) ---
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

* --- HAL + the arch table + cels ---
        include "../../src/hal/coco3-dsk/sys.s"
        include "../../src/hal/coco3-dsk/irq_vbl.s"
        include "../../src/hal/coco3-dsk/gfx.s"
        include "../../src/hal/coco3-dsk/time.s"
        include "scene6_arch_gen.s"       ; §2F single-home ARCH composite table
        include "scene6_arch_opacity_gen.s" ; pre-shifted opaque stencils (matches the tool)
        include "../../content/background/scene6_bg_A707/converted.s"
        include "../../content/background/scene6_bg_A857/converted.s"
        include "../../content/background/scene6_bg_A82B/converted.s"
        include "../../content/background/scene6_bg_A7D1/converted.s"
        include "../../content/background/scene6_bg_A763/converted.s"
        include "../../content/background/scene6_bg_A703/converted.s"
        include "../../content/background/scene6_bg_A684/converted.s"
        include "../../content/background/scene6_bg_A85F/converted.s"
        include "../../content/background/scene6_bg_A865/converted.s"
        include "../../content/background/scene6_bg_A68A/converted.s"
        include "../../content/background/scene6_bg_A877/converted.s"
        include "../../content/background/scene6_bg_A87B/converted.s"
        include "../../content/background/scene6_bg_A6EF/converted.s"
        include "../../content/background/scene6_bg_A6A6/converted.s"

        end     test_start
