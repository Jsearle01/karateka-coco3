* tests/scripted/scene6_b2prime_driver.s
*
* STAGE B2' — CORE SCROLL + ACTORS. Extends the measured on-budget Stage-A strip-scroll with the
* player RUN animation (B0 `run:` block, @loop c0..c7) and the parked guard, and halts at the
* phase-wrap $52==$1A (settles $1B) instead of looping the sweep.
*
* PHASE SCHEDULE (the acceptance spine — measured, see reports/20260721-003921):
*   phases 0..11  strip chunks           ~12,700 cyc  (42.4%)
*   phase  12     Fuji                    18,155 cyc  (60.8%)
*   phase  13     cliff + seam + clip     22,376 cyc  (74.9%)  <- busiest, keep actors OFF
*   phase  14     ACTORS then PRESENT      8,793 cyc  (29.4%)  <- player+guard land HERE
*   phase  15     idle                       137 cyc  ( 0.5%)  <- spare (arch follow-on)
* HAL_gfx_present is a 186-cycle VOFFSET write, so phase 14 is ~99% empty AND is the last phase
* before the display swap — the only slot that satisfies both budget and draw order.
*
* (derived from) WALK BUILD — STAGE A (cut 3): the $52-driven mid-ground scroll.
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
SA_NCHUNK       equ     6               ; strip chunks/step (was 7x12); frees a phase for the ARCH
SA_RPC          equ     14              ; rows per chunk (14*6=84 >= 81)
* --- PLAY AREA (Jay, 2026-07-21): the CoCo3 screen is 320 px but the game's virtual screen is
*     280 px, so x280-319 (byte cols 70-79) is a deliberate BLACK BORDER, not missing substrate.
*     Verified on the live framebuffer: cols 64-69 carry content in 38/81 band rows, cols 70+ are
*     black in all 81. The scroll must therefore treat col 69 as its right edge — the earlier
*     "right side all black" was the strip sampling and copying the BORDER:
*       - edge_byte was taken from snapshot col 79 (black) and replicated into every vacated
*         column, so the reveal painted border-black into the play area;
*       - the block copy spanned cols 25..79, dragging 10 columns of border-black leftward into
*         the play area on every step.
*     Both now stop at PLAY_R. Cols 70-79 are never written, so the border stays black. ---
PLAY_L          equ     5               ; FIRST play-area byte column = x20-23 (left virtual edge)
PLAY_R          equ     74              ; last play-area byte column = x296-299
*   CORRECTED (Jay, 2026-07-21: "it looks like you're clipping too early and not at the logical
*   screen edge on the right"). The port maps apple->coco with +20, so the 280 px virtual screen
*   occupies coco x20..299, NOT x0..279. Borders are therefore SYMMETRIC 20 px:
*       left  border cols 0..4   (x0..19)    <- already cleared by the existing clip
*       PLAY  AREA   cols 5..74  (x20..299)  <- 280 px
*       right border cols 75..79 (x300..319)
*   PLAY_R=69 clipped 5 columns (20 px) early, and the Fuji border-clear then blacked x280..299
*   permanently — the static non-scrolling black stripe from Fuji's top down to the HUD.
*   Two measurements had already said 74 and I misread both: draw_climb_ground_right fills bytes
*   25..74, and the Fuji rows painted to col 74. Both land exactly on x299.
WALL_L          equ     25              ; the wall/ground block's LEFT byte at shift 0. The cliff-face
                                        ;   striations (bytes <WALL_L, incl. byte 24 = the px99 black
                                        ;   wall-edge pixel) are a FIXED backdrop; the block slides
                                        ;   left over them and overwrites them (boundary = WALL_L-shift).
SA_HOLD         equ     SCROLL_VBLS_PER_STEP
* --- §5 NAMED CADENCE CONSTANTS — the deferred smoothed-scroll (Classic/Enhanced) toggle must be
*     a CONSTANT SWAP, not a refactor. Baseline = oracle-faithful COUPLED: position is coupled to
*     the run pose, ~5.5 steps/sec (16 VBL/step at 59.94 Hz = 3.7/s; oracle B0 = 11 VBL/pose).
*     Do NOT hand-edit cadence anywhere else in this file — change it HERE. ---
SCROLL_VBLS_PER_STEP equ 11             ; VBLs/step = the ORACLE cadence (B0: 11 VBL/run pose)
*   59.94/11 = 5.45 steps/sec — the faithful coupled baseline. Stage A used 16 (3.7/s).
*   With COLS=2 (8 px/step): 8*5.45 = 43.6 px/s vs the oracle's 38.1 px/s.
*   The 11 phases map exactly: 0 step_init, 1..7 strip (7 x 12 rows = 84 >= 81), 8 Fuji,
*   9 cliff+seam, 10 posts+actors+present.
SCROLL_COLS_PER_STEP equ 2              ; byte-cols of $52 travel per step
* --- SCROLL RATE (Jay's gate: "the player still looks like he is being held back").
*     The oracle's $52 step is ONE APPLE BYTE COLUMN = 7 px, and the port's registration is 1:1 px,
*     so a faithful step travels 7 px. The port shifts WHOLE CoCo byte columns = 4 px each, so:
*         COLS=1 -> 4 px/step = 21.8 px/s =  57% of the oracle (38.1 px/s)  <- was this: too slow
*         COLS=2 -> 8 px/step = 43.6 px/s = 114%
*     The run animation was already at the correct 5.45 poses/sec, so a world moving at 57% is
*     exactly the "running but held back" read. 7 px is not a multiple of 4, so byte-granular
*     scrolling CANNOT hit it exactly; 2 is the closest whole-column choice and errs fast rather
*     than half-speed. EXACT fidelity needs a SUB-BYTE scroll (7 px = 1 col + 3 px), which the
*     raw-byte strip copy cannot express — flagged as an architectural follow-on, not fudged here. ---
PRESENT_VBLS_PER_STEP equ 1             ; presents per step (1 = present once, at phase 14)
RUN_POSES_PER_STEP   equ 1              ; run-animation poses advanced per scroll step
* --- PLAYER FORWARD DRIFT (Jay's gate: "the player looks like he is pulled backward a bit every
*     animation cycle"). The run stride implies forward motion; with the figure pinned to a fixed
*     anchor the implied motion never happens and the feet read as slipping back. The oracle's
*     player does creep forward DURING the scroll: $62 = 0F -> 13 over ~10 poses in the walk-off
*     window (B0 trace) = ~1 byte-col per 2-3 poses. Modelled here as a step counter. ---
PLAYER_STEPS_PER_COL equ 3              ; scroll steps per +1 byte-col of player drift
* --- phase assignments (indices into the SA_HOLD phase machine) ---
PH_FUJI         equ     0               ; FIRST: the distant backdrop + step_init
PH_STRIP0       equ     1               ; strip chunks occupy 1..SA_NCHUNK
PH_CLIFF        equ     SA_NCHUNK+1     ; cliff + seam (busiest — no actors here)
PH_ACTORS       equ     SA_NCHUNK+2     ; actors THEN present
PH_IDLE         equ     SA_NCHUNK+3     ; spare
* --- halt (phase 1 ends here; phase 2 walk-through is B3) ---
SCROLL_HALT_S52 equ     $1A             ; the oracle's phase-wrap compare
SCROLL_SETTLE_S52 equ   $1B             ; $52 settles here and the scene freezes
* --- run animation frame indices (from scene6_run_anim_gen.s: s0 s1 c0..c7 e0 st) ---
RUN_IDX_E0      equ     10              ; run stop
RUN_IDX_ST      equ     11              ; standing settle (terminal, held)
* --- GUARD: the DEFEATED guard, execution-corrected (Jay's gate: "two players on screen").
*     The first cut drew $899C/$8ACB/$8E9B — those are the PLAYER (draw-A only, faces right;
*     $8E9B is the player head, $899C/$8ACB the climb settle figure), so the screen had two
*     identical players. The oracle's walk-off window draws the guard MIRRORED (entry By) from a
*     DEFEAT-specific set that never appears in the fight: $8DA9/$8E83/$8F0E/$9290, lying near
*     the ground at rows 151-154. Port cels are the pre-mirrored scene6_guard_*_mir.
*     Columns track the SCROLL (col - $72 is a per-cel constant and $72 tracks $52), so the guard
*     scrolls WITH the scene — it is parked in SCENE space, not pinned to the screen. Pinning it
*     was the "dragged along" half of the same gate finding.
*     Port registration: x = oracle_col*7 + sub + 20; col = (x>>2)+leading_trim, sub = x&3. ---
GUARD_BASE_COL  equ     45              ; 8DA9 (dx +0 from $72) at scroll shift 0
GUARD_9290_COL  equ     50
GUARD_9290_SUB  equ     3
GUARD_9290_ROW  equ     153
GUARD_8DA9_COL  equ     45
GUARD_8DA9_SUB  equ     2
GUARD_8DA9_ROW  equ     151
GUARD_8F0E_COL  equ     52
GUARD_8F0E_SUB  equ     2
GUARD_8F0E_ROW  equ     154
GUARD_8E83_COL  equ     49
GUARD_8E83_SUB  equ     0
GUARD_8E83_ROW  equ     151

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
        beq     ml_init                 ; PHASE 0: step_init only
        cmpa    #SA_NCHUNK
        bls     ml_sc                   ; phases 1..SA_NCHUNK: strip the band (sky + wall + ground)
        cmpa    #SA_NCHUNK+1
        beq     ml_fujiu                ; FUJI
        cmpa    #SA_NCHUNK+2
        beq     ml_arch                 ; ARCH ($52-relative reveal; behind cliff/actors)
        cmpa    #SA_NCHUNK+3
        beq     ml_cliff                ; cliff + seam
        cmpa    #SA_NCHUNK+4
        beq     ml_flip                 ; actors + present
        bra     ml_next

* DRAW ORDER (Jay, 2026-07-21). Two constraints that look contradictory until the layering is
* stated explicitly:
*   (a) "everything should be drawn after Fuji" — Fuji is the distant backdrop; the wall-top,
*       cliff and actors must all occlude it;
*   (b) "the Fuji parts in the scroll region still need to be blitted each frame" — because the
*       strip lays down ONE OPAQUE BITMAP (sky + wall-top + striations + ground together), anything
*       drawn BEFORE it is erased wherever the band covers it. Fuji drawn first was therefore cut
*       off at the band's top edge (rows >=100), which is the missing-Fuji symptom.
* Resolved by ordering within the step rather than by layer count:
*       step_init -> BAND (sky+wall+ground) -> FUJI -> cliff+seam -> actors -> present
* so the band's SKY is behind Fuji, and every nearer element (cliff, actors) is drawn after it.
* The wall-top posts sit at cols 24/25, 45/46, 66/67 while Fuji occupies cols 26-36, so re-blitting
* Fuji over the band does not visibly cover the posts.
* Phase budget: Fuji (~18,100 cyc) cannot share phase 0 with a strip chunk (~12,700) — together
* they overrun the 29,859-cycle window — so it keeps a phase of its own. 11-VBL cadence unchanged.

ml_init:
        jsr     step_init               ; advance $52, shift, back_band, strip_row=0
        bra     ml_next

ml_fujiu:
        jsr     draw_a9e2_behind        ; lowest Fuji cel — now genuinely behind (band paints over)
        jsr     draw_fuji_upper         ; upper Fuji cels
        jsr     clear_border_fuji       ; keep the right border (cols PLAY_R+1..79) black
        bra     ml_next

ml_arch:
        jsr     restore_arch_sky        ; wipe the arch trail above the band (flash fix)
        jsr     draw_arch
        jsr     clear_arch_rborder
        bra     ml_next

ml_sc:
        jsr     strip_chunk
        bra     ml_next

ml_cliff:
        jsr     draw_cliff_cels         ; the cliff sprite (AA7D) at (base_col - shift) — SCROLLS
        jsr     draw_ground_seam        ; ground column over the cliff's right edge (no black seam)
        jsr     clip_left_border        ; clip a scrolled cliff cel at the virtual left edge (px20)
        bra     ml_next

ml_flip:
* PHASE 14 — ACTORS THEN PRESENT. Actors must come AFTER the band+cliff are built (or the strip
* would overwrite them) and BEFORE the VOFFSET swap (or they would not be on the displayed page).
* Phase 14 is also ~99% empty (present = 186 cyc), so this is the only slot satisfying both.
* The strip rebuilds the band from the pristine snapshot each step, so the actors are erased for
* free — no clean-restore bbox needed (unlike climb_controller's cl_restore).
        jsr     draw_posts_over_fuji    ; the 3 BAKED posts, re-asserted in front of Fuji
        jsr     draw_posts_generated    ; NEW posts entering from the right at the 85 px pitch
        jsr     draw_player_run         ; 3-part run frame at the B0 anchor
        jsr     draw_guard_parked       ; 3-part guard, parked (does NOT slide with the scroll)
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
* HALT (not wrap): phase 1 ends at the oracle's phase-wrap compare $52==$1A, settling $1B. The
* Stage-A sweep looped $1B->$30 for watchability; B2' must FREEZE (phase 2 walk-through is B3).
        lda     scroll_halted
        beq     si_active               ; not halted: normal step
        jsr     run_settle              ; halted: e0 -> st, then hold; cur52/shift untouched
        bra     si_shift
si_active:
        lda     cur52
        suba    #SCROLL_COLS_PER_STEP
        cmpa    #SCROLL_HALT_S52
        bhi     si_store                ; still above the halt compare -> keep scrolling
        lda     #SCROLL_SETTLE_S52      ; reached it: settle $1B and freeze
        sta     cur52
        lda     #1
        sta     scroll_halted
        jsr     run_on_halt             ; run animation exits its cycle: -> e0 -> st (held)
        bra     si_shift
si_store:
        sta     cur52
        jsr     run_advance             ; one run pose per scroll step (RUN_POSES_PER_STEP)
        inc     player_dctr             ; forward drift: +1 col every PLAYER_STEPS_PER_COL steps
        lda     player_dctr
        cmpa    #PLAYER_STEPS_PER_COL
        blo     si_store_done
        clr     player_dctr
        inc     player_dx
si_store_done:
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
        lda     PLAY_R-WALL_L,x         ; A = edge byte from the PLAY EDGE (col 69), not the border
        sta     edge_byte
        lda     #PLAY_R+1-WALL_L        ; 45 bytes (WALL_L..PLAY_R) — never copies the border
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
        * ...and the RIGHT border, symmetrically: bytes PLAY_R+1..79 (px280..319) are outside the
        * 280 px virtual screen. Enforced as an INVARIANT rather than by trusting every writer to
        * respect the edge — the first cut of the play-area clip still showed cols 70/72 painted,
        * and a border that depends on N routines each stopping in the right place will break again
        * the moment one of them is edited. One clear here cannot be forgotten.
        leau    PLAY_R+1,u
        ldb     #79-PLAY_R              ; 10 bytes: cols 70..79
sor_rb:
        clr     ,u+
        decb
        bne     sor_rb
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
dpg_mbase       fdb     0               ; generated posts: active mask table (post_masks/gap_masks)
dpg_shift       fdb     0               ; generated posts: scroll shift in pixels
dpg_x           fdb     0               ; generated posts: current post x (signed)
dpg_currow      fcb     0               ; generated posts: current row
dpg_byte        fcb     0               ; generated posts: byte column (x>>2)
dpg_phase       fcb     0               ; generated posts: sub-byte phase (x&3)
player_dx       fcb     0               ; player forward drift (byte cols) — see PLAYER_STEPS_PER_COL
player_dctr     fcb     0               ; step counter feeding player_dx
run_idx         fcb     0               ; current run frame (0=s0); advanced once per scroll step
scroll_halted   fcb     0               ; 1 once $52 hit the halt compare -> scene frozen
rp_cnt          fcb     0               ; run render: part counter
rp_ptr          fdb     0               ; run render: current part pointer
clip_k          fcb     0
clip_w          fcb     0
back_band       fdb     0
cur_src         fdb     0
cur_dst         fdb     0
scroll_save     rmb     SA_BAND_LEN     ; clean gated-band snapshot (6480 bytes)

* ===============================================================
* clear_border_fuji — the right border (cols PLAY_R+1..79 = x280-319) is outside the 280 px
*   virtual screen and must stay black. strip_one_row enforces that for the scroll BAND, but the
*   Fuji cels live ABOVE the band (rows ~81-111) and were measured painting to col 74 (x299), so
*   the band-only invariant did not cover them. Clear the border across the Fuji rows after every
*   Fuji redraw. Rows 80..119 covers all four cels plus margin; 40 rows x 10 bytes = 400 stores.
* ===============================================================
CBF_ROW0        equ     80
CBF_ROWS        equ     40
clear_border_fuji:
        lda     #CBF_ROW0
        ldb     #80
        mul                             ; D = row0*80
        addd    #$8000
        tfr     d,x
        lda     <page_register          ; write to the BACK buffer (the one being drawn)
        cmpa    #PAGE_A_TOKEN
        beq     cbf_go
        leax    $4000,x                 ; buffer B
cbf_go:
        leax    PLAY_R+1,x              ; X -> first border byte of row CBF_ROW0
        lda     #CBF_ROWS
cbf_row:
        ldb     #79-PLAY_R              ; 10 border bytes
        pshs    x
cbf_b:
        clr     ,x+
        decb
        bne     cbf_b
        puls    x
        leax    80,x                    ; next row
        deca
        bne     cbf_row
        rts

* ===============================================================
* ARCH ($52-relative reveal content, traced by spatial region; behind cliff/actors — walked
*   through in B3). Whole composite translates by ONE common delta = (cur52-$1B)*7 px. Tiled
*   pillars clip at ARCH_FLOOR_CLIP (the band floor occludes below). Opacity via the MIXED blit
*   (rides sub-byte, so it works at every scroll sub); cels with no descriptor -> plain blit.
* ===============================================================
ARCH_SKY_L      equ     55
ARCH_ROW0       equ     30
ARCH_ROWSABV    equ     70              ; rows 30..99 (above the band; not rebuilt by the strip)
ARCH_FLOOR_CLIP equ     160             ; = A684's table row1 (oracle extent): the FRONT leg reaches
                                        ; the ground. The old 152 cap was a static-test artifact (no
                                        ; band) that shortened the front leg — Jay's scroll eye: too short.

restore_arch_sky:
        lda     #ARCH_ROW0
        ldb     #80
        mul
        addd    #$8000
        tfr     d,y
        lda     <page_register
        cmpa    #PAGE_A_TOKEN
        beq     ras_go
        leay    $4000,y
ras_go:
        leay    ARCH_SKY_L,y
        lda     #ARCH_ROWSABV
ras_row:
        ldx     #$AAAA
        ldb     #PLAY_R-ARCH_SKY_L+1
        pshs    y
ras_b:
        stx     ,y++
        decb
        decb
        bgt     ras_b
        puls    y
        leay    80,y
        deca
        bne     ras_row
        rts

clear_arch_rborder:
        lda     #ARCH_ROW0
        ldb     #80
        mul
        addd    #$8000
        tfr     d,y
        lda     <page_register
        cmpa    #PAGE_A_TOKEN
        beq     cab_go
        leay    $4000,y
cab_go:
        leay    PLAY_R+1,y
        lda     #ARCH_ROWSABV
cab_row:
        ldb     #79-PLAY_R
        pshs    y
cab_b:
        clr     ,y+
        decb
        bne     cab_b
        puls    y
        leay    80,y
        deca
        bne     cab_row
        rts

draw_arch:
        lda     cur52
        suba    #SCROLL_SETTLE_S52
        ldb     #7
        mul
        std     arch_delta
        lda     arch_count
        sta     arch_ct
        ldu     #arch_tbl
dar_cel:
        ldx     ,u++                    ; X=cel, U->col
        stx     arch_celp
        stu     arch_u                  ; save table ptr (the mixed blit clobbers U)
        lda     #4
        ldb     ,u                      ; col
        mul                             ; D = col*4
        addb    1,u                     ; + sub
        adca    #0
        addd    arch_delta              ; D = runtime_x (A=hi, B=lo)
        pshs    a                       ; preserve hi across the sub extraction
        tfr     b,a
        anda    #3
        sta     arch_subv               ; sub = runtime_x & 3
        puls    a                       ; A:B = runtime_x again (hi restored)
        lsra
        rorb
        lsra
        rorb                            ; D = runtime_x>>2 ; B = port col
        tsta
        bne     dar_skip
        cmpb    #PLAY_L
        blo     dar_skip
        cmpb    #PLAY_R
        bhi     dar_skip
        stb     arch_col
        ldx     arch_celp
        addb    1,x                     ; col + width
        cmpb    #80
        bhi     dar_skip
        * opaque-black STENCIL set for this cel (0 = none -> plain transparent blit only).
        * arch_desc = &{s0,s1,s2,s3}; draw picks the stencil pre-shifted for the runtime sub.
        clr     arch_desc
        clr     arch_desc+1
        ldy     #arch_stencil_tbl
das_f:
        ldx     ,y++                    ; cel (0 = end)
        beq     das_h
        cmpx    arch_celp
        beq     das_g
        leay    8,y                     ; skip 4 stencil ptrs
        bra     das_f
das_g:
        sty     arch_desc               ; Y points at s0 (after ldx ,y++) = base of the 4 ptrs
das_h:
        * row range; TILED pillars clip at the floor
        lda     2,u                     ; row0
        sta     arch_row
        lda     4,u                     ; step
        sta     arch_step
        lda     3,u                     ; row1
        cmpa    2,u                     ; single (row1==row0)?
        beq     dar_setend
        cmpa    #ARCH_FLOOR_CLIP
        bls     dar_setend
        lda     #ARCH_FLOOR_CLIP
dar_setend:
        sta     arch_rend
dar_row:
        * (1) plain transparent blit: colours + KEYED black (index-0 shows the sky through)
        lda     arch_subv
        sta     <blit_subbyte
        lda     arch_col
        ldb     arch_row
        ldx     arch_celp
        jsr     HAL_gfx_blit_sprite
        * (2) punch the OPAQUE black via the stencil pre-shifted for THIS sub (byte-aligned).
        *     Pixel-precise, no per-region overflow -> clean (reproduces the approved static arch).
        ldu     arch_desc
        beq     dar_adv
        lda     arch_subv
        asla                            ; *2 (fdb table of 4 stencil ptrs)
        ldx     a,u                     ; X = stencil for sub=arch_subv
        beq     dar_adv
        clr     <blit_subbyte
        lda     arch_col
        ldb     arch_row
        jsr     HAL_gfx_blit_stencil_punch
dar_adv:
        lda     arch_row
        adda    arch_step
        sta     arch_row
        cmpa    arch_rend
        bls     dar_row
dar_skip:
        ldu     arch_u                  ; restore table ptr
        leau    5,u
        dec     arch_ct
        lbne    dar_cel
        rts

arch_delta      fdb     0
arch_celp       fdb     0
arch_u          fdb     0
arch_desc       fdb     0
arch_ct         fcb     0
arch_col        fcb     0
arch_subv       fcb     0
arch_row        fcb     0
arch_rend       fcb     0
arch_step       fcb     0

* ===============================================================
* draw_posts_generated — GENERATE new wall-top posts as the scroll reveals fresh wall.
*
*   The band's edge-extend can only replicate the rightmost existing column, and there is no post
*   in it, so no new post ever appeared however far the scene scrolled (Jay's last gate item).
*
*   Post shape and pitch are DERIVED from the gated tableau's own masks, not invented:
*     shape  2 px white at x,x+1 then black at x+2..x+5, on rows 101-103 and 108-110
*            (rows 104/111 are the full-width rails and come from the band);
*     pitch  85 px — Jay: use the 2nd->3rd spacing (183->268). The first post sits at 103, which
*            is OFF-series (the regular series would put it at 98), so it is not the reference.
*   Validation: regenerating phase 3 reproduces the baked post at x=183 byte-for-byte
*   (AND $FC,$00,$3F / OR $03,$C0,$00), so the pre-baked table matches the shipped tableau.
*
*   Pre-baked per SUB-BYTE PHASE (Jay's suggestion): 85 is not a multiple of 4, so successive posts
*   land at different phases; post_masks holds all four (3 AND + 3 OR bytes each), selected by
*   x & 3 and applied at byte x >> 2.
*
*   ADDITIVE: starts the series one pitch BEYOND the last baked post (268 + 85 = 353) so the three
*   posts already in the band are left alone and only genuinely new ones are drawn.
* ===============================================================
POST_PITCH      equ     85              ; px between posts (2nd->3rd spacing)
POST_X_START    equ     353             ; first post beyond the baked three (268 + PITCH)
POST_X_LEFT     equ     20              ; play-area left edge (px)
POST_X_RIGHT    equ     300             ; play-area right edge (exclusive)

post_rows       fcb     101,102,103,108,109,110,$FF
rail_rows       fcb     104,111,$FF     ; the rails: notched by the post, not overwritten by it

* The rail rows must be NOTCHED, not left alone: the baked tableau breaks the rail's white line
* with a 4 px black gap at each post (row 104 shows OR $C0/$3F at the post bytes, never $FF).
* Without the notch the rail runs straight THROUGH a generated post — Jay: "the white lines from
* the rail [go] through it." gap_masks blacks x+2..x+5 only, leaving the rest of the rail white.
draw_posts_generated:
        lda     scroll_shift
        ldb     #4
        mul                             ; D = shift in PIXELS
        std     dpg_shift
        ldd     #post_masks
        std     dpg_mbase
        ldu     #post_rows
        jsr     dpg_rows                ; the posts themselves
        ldd     #gap_masks
        std     dpg_mbase
        ldu     #rail_rows
        jsr     dpg_rows                ; the notch through the rails
        rts

dpg_rows:
dpg_row:
        lda     ,u+
        cmpa    #$FF
        beq     dpg_done
        sta     dpg_currow
        ldd     #POST_X_START
        subd    dpg_shift
        std     dpg_x
dpg_post:
        ldd     dpg_x
        cmpd    #POST_X_RIGHT
        bge     dpg_row                 ; past the right edge -> next row
        cmpd    #POST_X_LEFT
        blt     dpg_skip                ; left of the virtual screen edge -> clip
        jsr     dpg_draw_one
dpg_skip:
        ldd     dpg_x
        addd    #POST_PITCH
        std     dpg_x
        bra     dpg_post
dpg_done:
        rts


* dpg_draw_one — apply the phase-selected mask columns at dpg_x on row dpg_currow.
dpg_draw_one:
        ldd     dpg_x
        andb    #3
        stb     dpg_phase
        ldd     dpg_x
        lsra
        rorb
        lsra
        rorb                            ; D = x >> 2 (byte column)
        stb     dpg_byte
        lda     dpg_currow
        ldb     #80
        mul
        addd    #$8000
        tfr     d,y
        lda     <page_register
        cmpa    #PAGE_A_TOKEN
        beq     dpg_pg
        leay    $4000,y                 ; back buffer B
dpg_pg:
        ldb     dpg_byte
        leay    b,y                     ; Y -> first affected byte
        lda     dpg_phase
        ldb     #6
        mul
        addd    dpg_mbase               ; post_masks or gap_masks for this pass
        tfr     d,x                     ; X -> {3 AND bytes, 3 OR bytes}
        ldb     #3
dpg_and:
        lda     ,y
        anda    ,x+
        sta     ,y+
        decb
        bne     dpg_and
        leay    -3,y
        ldb     #3
dpg_or:
        lda     ,y
        ora     ,x+
        sta     ,y+
        decb
        bne     dpg_or
        rts

* ===============================================================
* draw_posts_over_fuji — re-assert the wall-top posts IN FRONT of Fuji (Jay: "the top of the wall
*   posts are still being cut off by Fuji as they scroll past").
*
*   The scene needs THREE depths — sky, then Fuji, then the wall-top — but the strip lays sky and
*   wall-top down as ONE opaque bitmap, so Fuji can only be in front of both or behind both. Every
*   post eventually scrolls through Fuji's fixed columns (26-36), so "Fuji after the band" clips
*   each post in turn.
*
*   The wall-top is drawn as sparse RMW masks (AND/OR pairs over bytes 24..74, rows 101..111) and
*   the vast majority of entries are $FF,$00 = NO-OP. So re-applying the same masks AFTER Fuji
*   writes ONLY post pixels and leaves Fuji intact everywhere between them — the third depth, for
*   free, without splitting the band or touching the gated tableau's own routine.
*
*   Two differences from draw_walltop_posts (which is init-only): this targets the BACK buffer via
*   page_register, and it applies scroll_shift so the posts land where the strip put them. Mask
*   pairs are consumed even for skipped bytes, or the table would desynchronise.
* ===============================================================
draw_posts_over_fuji:
        ldu     #wt_rmw
        lda     #101
dpf_row:
        pshs    a
        ldb     #80
        mul                             ; D = row*80
        addd    #$8000
        tfr     d,y
        lda     <page_register          ; back buffer = the one being drawn
        cmpa    #PAGE_A_TOKEN
        beq     dpf_go
        leay    $4000,y
dpf_go:
        ldx     #wt_bytes
dpf_byte:
        ldb     ,x+
        cmpb    #$FF
        beq     dpf_row_done
        subb    scroll_shift            ; the posts travel with the band
        bcs     dpf_skip                ; wrapped negative -> off-screen left
        cmpb    #PLAY_L
        blo     dpf_skip                ; left of the VIRTUAL screen edge -> clip (Jay's gate:
                                        ;   "top wall items are not properly clipped at the left
                                        ;   edge". The band's strip clips bytes 0..4, but these
                                        ;   RMW re-asserts — INCLUDING the rail rows, whose masks
                                        ;   are OR $FF across bytes 24..74 — wrote straight into
                                        ;   the border once shift pushed them below byte 5.
                                        ;   Clipping per BYTE (not per post) keeps the partial
                                        ;   post/rail correct as it leaves the screen.)
        pshs    y
        leay    b,y
        lda     ,u+
        anda    ,y
        ora     ,u+
        sta     ,y
        puls    y
        bra     dpf_byte
dpf_skip:
        leau    2,u                     ; consume the mask pair regardless
        bra     dpf_byte
dpf_row_done:
        puls    a
        inca
        cmpa    #112
        blo     dpf_row
        rts

* ===============================================================
* draw_player_run — blit the current run frame's 3 parts (legs -> head -> torso, the oracle's
*   verbatim draw order) from run_frames (codegen'd from the §2F [animation] run: block).
*   Frame block = {fcb dwell,pcnt; per part: fdb cel; fcb col,sub,row}. Columns are the B0
*   anchor: during phase 1 the oracle's player is near-stationary on screen ($62 ~ $10 while
*   $52 sweeps) and the SCENE scrolls past him, so the stored anchor columns are correct as-is.
* ===============================================================
draw_player_run:
        ldb     run_idx
        aslb                            ; *2 (fdb table)
        ldx     #run_frames
        abx
        ldx     ,x                      ; X -> {dwell, pcnt, parts...}
        lda     1,x                     ; part count
        sta     rp_cnt
        leax    2,x                     ; X -> first part
dpr_loop:
        stx     rp_ptr
        lda     3,x                     ; sub-byte (NEVER dropped — the climb lesson)
        sta     <blit_subbyte
        lda     2,x                     ; A = byte col
        adda    player_dx               ; + forward drift (the stride's implied translation)
        ldb     4,x                     ; B = row
        ldx     ,x                      ; X = cel pointer
        jsr     HAL_gfx_blit_sprite
        ldx     rp_ptr
        leax    5,x
        dec     rp_cnt
        bne     dpr_loop
        rts

* ===============================================================
* draw_guard_parked — the guard is DEFEATED/PARKED ($72=$0E, Recon 1): drawn over the scrolled
*   scene every step but at a FIXED column — it does NOT slide with the scroll. 3-part trio,
*   same composition as the run's standing frame (head sits +2 px right of the base).
* ===============================================================
draw_guard_parked:
* Draw order is the oracle's: 9290, 8DA9, 8F0E, 8E83. Every column is offset LEFT by
* scroll_shift so the guard travels with the scene (scene-space parking, not screen-space).
        lda     #GUARD_9290_SUB
        sta     <blit_subbyte
        lda     #GUARD_9290_COL
        suba    scroll_shift
        ldb     #GUARD_9290_ROW
        ldx     #scene6_guard_9290_mir
        jsr     HAL_gfx_blit_sprite
        lda     #GUARD_8DA9_SUB
        sta     <blit_subbyte
        lda     #GUARD_8DA9_COL
        suba    scroll_shift
        ldb     #GUARD_8DA9_ROW
        ldx     #scene6_guard_8DA9_mir
        jsr     HAL_gfx_blit_sprite
        lda     #GUARD_8F0E_SUB
        sta     <blit_subbyte
        lda     #GUARD_8F0E_COL
        suba    scroll_shift
        ldb     #GUARD_8F0E_ROW
        ldx     #scene6_guard_8F0E_mir
        jsr     HAL_gfx_blit_sprite
        lda     #GUARD_8E83_SUB
        sta     <blit_subbyte
        lda     #GUARD_8E83_COL
        suba    scroll_shift
        ldb     #GUARD_8E83_ROW
        ldx     #scene6_guard_8E83_mir
        jsr     HAL_gfx_blit_sprite
        rts

* ===============================================================
* run_advance — one pose per scroll step. Honours the @loop span from the single-home table:
*   s0,s1 play in ONCE, then c0..c7 repeat (run_loop_first/last are codegen'd from `@loop c0 c7`).
* ===============================================================
run_advance:
        lda     run_idx
        cmpa    run_loop_last
        beq     ra_wrap
        inca
        cmpa    run_frame_count
        blo     ra_store
ra_wrap:
        lda     run_loop_first
ra_store:
        sta     run_idx
        rts

* run_settle — on halt the run exits its cycle: -> e0 (stop) -> st (standing), then holds.
run_settle:
        lda     run_idx
        cmpa    #RUN_IDX_ST
        beq     rs_done
        cmpa    #RUN_IDX_E0
        beq     rs_to_st
        lda     #RUN_IDX_E0
        sta     run_idx
        rts
rs_to_st:
        lda     #RUN_IDX_ST
        sta     run_idx
rs_done:
        rts

* run_on_halt — first halted step: enter the exit sequence at e0.
run_on_halt:
        lda     #RUN_IDX_E0
        sta     run_idx
        rts

* --- HAL + shared substrate modules (single source) ---
* (The arch opacity now uses byte-aligned stencil punches, which need no scratch buffer, so the
* earlier MIX_SCRATCH relocation is no longer required.)
        include "../../src/hal/coco3-dsk/sys.s"
        include "../../src/hal/coco3-dsk/irq_vbl.s"
        include "../../src/hal/coco3-dsk/gfx.s"
        include "../../src/hal/coco3-dsk/time.s"

        include "scene6_backdrop.s"
        include "scene6_cliff_walltop.s"
        include "scene6_cliff_face.s"
        include "scene6_hud.s"
        include "scene6_placement_gen.s"  ; §2F single-home PLACEMENT table (codegen'd)
        include "scene6_post_masks_gen.s" ; pre-baked post masks, 4 sub-byte phases
        include "scene6_run_anim_gen.s"   ; §2F single-home RUN animation table (codegen'd, B0)
        include "scene6_arch_gen.s"       ; arch composite table
        include "scene6_arch_opacity_scroll_gen.s" ; per-sub opaque stencils (pixel-precise, clean)
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

* --- run cels: 8 legs + 8 torsos ($9B00-$9E92) + the shared head/standing trio ---
        include "../../content/player/player_run_legs_9B00/converted.s"
        include "../../content/player/player_run_legs_9B6B/converted.s"
        include "../../content/player/player_run_legs_9BE5/converted.s"
        include "../../content/player/player_run_legs_9C1B/converted.s"
        include "../../content/player/player_run_legs_9C65/converted.s"
        include "../../content/player/player_run_legs_9CAF/converted.s"
        include "../../content/player/player_run_legs_9CD7/converted.s"
        include "../../content/player/player_run_legs_9D1E/converted.s"
        include "../../content/player/player_run_torso_9D68/converted.s"
        include "../../content/player/player_run_torso_9D97/converted.s"
        include "../../content/player/player_run_torso_9DD5/converted.s"
        include "../../content/player/player_run_torso_9E05/converted.s"
        include "../../content/player/player_run_torso_9E2E/converted.s"
        include "../../content/player/player_run_torso_9E4A/converted.s"
        include "../../content/player/player_run_torso_9E74/converted.s"
        include "../../content/player/player_run_torso_9E92/converted.s"
        include "../../content/player/scene6_player_8E9B/converted.s"
* --- defeated-guard cels (pre-mirrored) ---
        include "../../content/guard/scene6_guard_9290_mir/converted.s"
        include "../../content/guard/scene6_guard_8DA9_mir/converted.s"
        include "../../content/guard/scene6_guard_8F0E_mir/converted.s"
        include "../../content/guard/scene6_guard_8E83_mir/converted.s"
* --- player standing trio: still required by the run block's `st` frame ---
        include "../../content/player/scene6_player_899C/converted.s"
        include "../../content/player/scene6_player_8ACB/converted.s"

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
