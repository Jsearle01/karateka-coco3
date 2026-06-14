* src/engine/sprite_engine.s
*
* SINGLE-SOURCE sprite/animation engine core (R-engine).
* Data-driven: characters are DATA (an animation table + a sprite set);
* ONE generic render leaf + ONE frame-sequencer drive any character.
* Scene 5, scene 6, and gameplay all call this (the combat LAYER —
* hit detection / round manager / two-combatant interaction — is INT-3,
* additive on top; NOT here).
*
* ORACLE BASIS (faithful, E5):
*   - render leaf = port of video.s $1900 draw-A (routine_1a42 + the
*     routine_1927 mask/eor/AND/OR blend). On the CoCo3 that blend IS the
*     existing HAL_gfx_blit_sprite transparency blit (mask -> coma -> anda
*     bg -> ora sprite), so the leaf DELEGATES to HAL_gfx_blit_sprite — the
*     single render primitive for static (scenes 1-4) AND animated sprites.
*     No self-modifying blend is ported: the CoCo3's transparency blit is
*     the behavioural equivalent (port the visual, not the Apple mechanism).
*   - sequencer = the data-driven frame advance (state -> frame -> render),
*     the animation-core subset of the oracle per-frame loop. The oracle's
*     combat action-class branches (tbl_action_class, the cpx #$01/#$02/#$03
*     position cases) are the COMBAT LAYER (INT-3); the animation core just
*     cycles a character's frame sequence at a cadence.
*   - double-buffer = the PROVEN Option-I flip (visual_smoke): draw to the
*     hidden back buffer -> HAL_gfx_present -> toggle page_register.
*
* DATA MODEL — animation table (per character set):
*   <set>_anim:
*       fcb  frame_count          ; number of frames in the cycle
*       fcb  cadence              ; VBL frames held per animation frame
*       fcb  clear_w, clear_h     ; bounding box (bytes, rows) cleared each
*                                 ;   frame before the blit (covers all frames
*                                 ;   at the shared position)
*       ; frame_count entries, each 5 bytes:
*       fdb  sprite_ptr ; fcb byte_col, subbyte, row
*   This table + the sprite set ARE the character; the engine is generic.
*
* STATE BLOCK (ZP $30-$3F; one character — scales to a per-character struct
*   array for multi-character scene 6 / combat):
* [ref: src/engine/globals.s declares the eng_* equates]
* [ref: src/hal/coco3-dsk/gfx.s HAL_gfx_blit_sprite / HAL_gfx_present]
* [ref: docs/project/verification-plan_engine-core.md P2/P3/P4]
* ---------------------------------------------------------------

        setdp   0

* ===============================================================
* eng_anim_init  — load an animation table into the state block + render
*   frame 0. X = animation table pointer.
* ===============================================================
eng_anim_init:
        stx     <eng_tbl                ; save table ptr
        lda     ,x                      ; frame_count
        sta     <eng_cnt
        lda     1,x                     ; cadence
        sta     <eng_cad
        sta     <eng_cadctr
        lda     2,x                     ; clear_w
        sta     <eng_clrw
        lda     3,x                     ; clear_h
        sta     <eng_clrh
        clr     <eng_idx                ; frame 0
        jsr     eng_render              ; draw frame 0 + present + toggle
        rts

* ===============================================================
* eng_tick  — per-VBL cadence tick. Counts down; on expiry advances one
*   frame (wrap) and renders. Call once per VBL frame from the run loop.
* ===============================================================
eng_tick:
        dec     <eng_cadctr
        bne     eng_tick_done
        ; cadence expired -> advance + render
        lda     <eng_cad
        sta     <eng_cadctr             ; reload
        ; fall through to step
eng_step:
        ; advance frame index (wrap at count)
        lda     <eng_idx
        inca
        cmpa    <eng_cnt
        blo     eng_step_store
        clra                            ; wrap to 0
eng_step_store:
        sta     <eng_idx
        jsr     eng_render
eng_tick_done:
        rts

* ===============================================================
* eng_render  — render the current frame to the BACK buffer, then flip.
*   (1) point X at the current frame's 5-byte entry,
*   (2) clear the bounding box at the frame's position (remove the stale
*       frame in this back buffer), (3) blit via the render leaf,
*   (4) HAL_gfx_present (reveal it), (5) toggle page_register.
* ===============================================================
eng_render:
        ; X = eng_tbl + 4 (header) + eng_idx*5
        lda     <eng_idx
        ldb     #5
        mul                             ; D = idx*5
        addd    #4                      ; + header
        addd    <eng_tbl                ; + table base
        tfr     d,x                     ; X -> frame entry {fdb ptr; fcb col,sub,row}
        ; stash the entry fields (col/sub/row) for clear + blit
        ldd     2,x                     ; A=col, B=sub
        sta     <eng_col
        stb     <eng_sub
        lda     4,x                     ; row
        sta     <eng_row
        pshs    x                       ; save entry ptr across the box clear
        ; (1) clear the bounding box at (eng_col, eng_row) in the back buffer
        clr     <eng_fillval            ; cast path: clear to 0 (black) as before
        jsr     eng_clear_box
        ; (2) blit the frame sprite via the render leaf = HAL_gfx_blit_sprite.
        ;     HAL_gfx_blit_sprite IS the render leaf: it selects the back
        ;     buffer (page_register), bounds-checks, and runs the sub-byte
        ;     transparency blend (= oracle routine_1927). X=sprite, A=col,
        ;     B=row, blit_subbyte set.
        puls    x                       ; X -> frame entry
        ldx     ,x                      ; X = sprite ptr (the leading fdb)
        lda     <eng_sub
        sta     <blit_subbyte
        lda     <eng_col                ; A = byte col
        ldb     <eng_row                ; B = row
        jsr     HAL_gfx_blit_sprite     ; render leaf (single render primitive)
        ; (3) flip: reveal the just-drawn back buffer, toggle for next draw
        jsr     HAL_gfx_present
        lda     <page_register
        eora    #$60                    ; $20<->$40 (Option I A/B toggle)
        sta     <page_register
        rts

* ===============================================================
* eng_clear_box  — zero an (eng_clrw x eng_clrh) byte box at (eng_col,
*   eng_row) in the back buffer (page_register-selected). Removes the
*   stale frame so the transparency blit lands on black.
* ===============================================================
eng_clear_box:
        ; back-buffer base -> Y
        lda     <page_register
        cmpa    #PAGE_A_TOKEN
        beq     eng_cb_a
        ldy     #$C000                  ; buffer B
        bra     eng_cb_base
eng_cb_a:
        ldy     #$8000                  ; buffer A
eng_cb_base:
        ; Y += eng_row*80 + eng_col
        lda     #80
        ldb     <eng_row
        mul                             ; D = row*80
        leay    d,y
        ldb     <eng_col
        leay    b,y                     ; Y = base + row*80 + col
        ; clear eng_clrh rows of eng_clrw bytes (stride 80)
        lda     <eng_clrh               ; row counter
eng_cb_row:
        pshs    a,y
        ldb     <eng_clrw               ; bytes/row
        lda     <eng_fillval            ; fill byte (0=clear, or floor color for restores)
eng_cb_byte:
        sta     ,y+
        decb
        bne     eng_cb_byte
        puls    a,y
        leay    80,y                    ; next row
        deca
        bne     eng_cb_row
        rts
