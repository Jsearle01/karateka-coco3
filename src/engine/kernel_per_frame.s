* src/engine/kernel_per_frame.s
*
* Attract-loop per-frame orchestrator — the central spine.
*
* ORIGIN: karateka_dissasembly_claude src/kernel_per_frame.s
*         Apple II $0200-$02FF (per_frame_poll, input_poll_loop,
*         blit_helper, ptr_setup; dispatch table at $0200-$020B)
*
* Purpose:
*   CoCo3 per-frame dispatch loop. On each iteration:
*     1. Check scene-transition condition (replaces L0300 call).
*     2. Copy frame_done to frame_countdown (L022C state copy).
*     3. Poll input (replaces 65536-iter input_poll_loop).
*     4. Dispatch to per-frame continuation (replaces jmp $BFFA).
*   Loops indefinitely until scene_transition_check triggers (P2.4+).
*
* REDESIGN NOTE: kernel_per_frame.s cannot be literally translated.
*   Apple II-specific mechanisms not ported:
*     (a) Sync signature check at $BFFD-$BFFF — copy-protection; skip.
*     (b) jsr L0300 (disk_load_trigger) — conditional disk-load restart;
*         mapped to scene_transition_check stub (always returns in P2.2).
*     (c) jmp $BFFA → $B760 — per-frame continuation chain into intro.s;
*         mapped to per_frame_continuation stub (rts in P2.2).
*     (d) input_poll_loop (65536-iter poll) — Apple II timing; replaced
*         by single jsr HAL_input_poll per frame.
*     (e) blit_helper — calls L1900/L7609 (not yet ported); stub in P2.2.
*
* DP variables (frame-coherent band $50-$5F per conventions.md §2):
*   frame_done      DP $52 — frame sync reference value
*                            [ref: kernel_per_frame.s ZP$D0 —
*                             "frame sync value, expected 0 at steady state"]
*   frame_countdown DP $53 — frame down-counter (copy of frame_done)
*                            [ref: kernel_per_frame.s ZP$D2 —
*                             "frame countdown timer; DEC $D2 at $0249"]
*   frame_sync_dc   DP $54 — frame sync state flag
*                            [ref: kernel_per_frame.s ZP$DC —
*                             "set $DC = $01 at input-detected paths"]
*
* HAL calls:
*   HAL_input_poll — replaces 65536-iter keyboard/button poll loop
*                    [ref: input_poll_loop — lda KBD; bmi input_detected]
*   HAL_time_vbl_wait — frame timing (via per_frame_continuation; P2.1)
*
* Cross-subsystem stubs (replace unported callee subsystems):
*   scene_transition_check — replaces L0300 disk_load_trigger call
*   per_frame_continuation — replaces jmp $BFFA→$B760 continuation chain
*   video_dispatch_stub    — replaces L1900 (video.s; P2.3)
*
* Verification scope:
*   Per-frame orchestrator structure verified. scene_transition_check and
*   per_frame_continuation are no-op stubs whose work is deferred to P2.4
*   (scene management port). HAL_input_poll always returns "no input" in
*   P2.2 (STUB-P2.x).
*
* Reference citations:
*   [ref: kernel_per_frame.s per_frame_poll — $0200-$020B dispatch table,
*    $020C-$0236 per-frame poll loop, $0250-$025D init/reset path]
*   [ref: kernel_per_frame.s input_poll_loop — $025E-$0290 input scan]
*   [ref: kernel_per_frame.s blit_helper — $02CB-$02E6]
*   [ref: data-areas-catalog.md ZP$D0/$D2/$DC — frame sync state bytes]
*   [ref: conventions.md §2 — DP $50-$5F frame-coherent variables band]
*   [ref: hal.inc HAL_input_poll — Args: none; Returns: D=input state]
* ---------------------------------------------------------------

        setdp   0               ; DP=0; direct-page for <addr

* DP variables declared in src/engine/globals.s (P2.3a.3 migration).
* [ref: src/engine/globals.s — canonical DP home]
*
* Symbols used here (defined in globals.s):
*   frame_done      equ $52   ; frame sync reference value (ZP$D0 analog)
*   frame_countdown equ $53   ; frame down-counter (ZP$D2 analog)
*   frame_sync_dc   equ $54   ; frame sync flag (ZP$DC analog)

* ---------------------------------------------------------------
* per_frame_main_loop
*
* Central per-frame dispatch. Called at startup and loops until
* scene_transition_check indicates a scene transition is needed.
*
* ORIGIN: karateka_dissasembly_claude src/kernel_per_frame.s
*         Apple II $0200-$020B (dispatch table) + $020C-$0236
*         (per_frame_poll) + $025E-$0290 (input_poll_loop).
*
* Structure (each iteration):
*   1. Check scene transition  [ref: per_frame_poll lda $D0; jsr L0300]
*   2. Copy frame_done → frame_countdown
*                              [ref: per_frame_poll L022C: lda $D0; sta $D2]
*   3. Poll input              [ref: input_poll_loop 65536-iter scan]
*   4. Dispatch continuation   [ref: per_frame_poll jmp $BFFA→$B760]
*
* Clobbers: A, B (via HAL_input_poll), CC
* Preserves: X, Y, U (HAL contract; stubs preserve per contract)
* ---------------------------------------------------------------
per_frame_main_loop:
        lda     <frame_done             ; [ref: per_frame_poll lda $D0]
        jsr     scene_transition_check  ; [ref: per_frame_poll jsr L0300]
                                        ; stub: rts immediately (P2.2)
                                        ; P2.4+: if transition needed, no return
        lda     <frame_done             ; [ref: per_frame_poll L022C: lda $D0]
        sta     <frame_countdown        ; [ref: per_frame_poll sta $D2]
        jsr     HAL_input_poll          ; [ref: input_poll_loop — 65536-iter poll]
                                        ; stub: returns D=0 (no input), CC.C clear
        jsr     per_frame_continuation  ; [ref: per_frame_poll jmp $BFFA → $B760]
                                        ; stub: rts immediately (P2.2)
        bra     per_frame_main_loop

* ---------------------------------------------------------------
* scene_transition_check
*
* Check if a scene transition is needed. If so, load the next scene
* and do not return (transition fires). If not, return normally.
*
* ORIGIN: karateka_dissasembly_claude src/disk_loader.s L0300
*         [ref: kernel_per_frame.s — "L0300 := $0300; JSR here:
*          fills $0400-$07FF... JMPs to $4600 — NEVER RETURNS"]
*         [ref: kernel_per_frame.s per_frame_poll — "lda $D0; jsr L0300;
*          L0300 NEVER RETURNS when fired (A != 0 path)"]
*
* STUB-P2.4: always returns (no scene transitions in P2.2).
*   P2.4+: if A (= frame_done) != 0, trigger scene load and don't return.
*
* Args:  A = frame_done value ($D0 analog)
* Returns: CC.C clear (normal path; transition path never returns)
* Clobbers: CC
* ---------------------------------------------------------------
scene_transition_check:
        rts                             ; STUB: always return (no transition)

* ---------------------------------------------------------------
* per_frame_continuation
*
* Per-frame continuation dispatcher. Dispatches to the per-frame
* work for the current scene. On Apple II this is the $BFFA→$B760
* per-frame chain (intro.s jmptable_b760 → per-scene handlers).
*
* ORIGIN: karateka_dissasembly_claude src/kernel_per_frame.s
*         [ref: per_frame_poll L022C — "jmp $BFFA → per-frame
*          continuation (JMP $B760)"]
*         [ref: intro.s jmptable_b760 — 3-slot dispatch table;
*          slot 0 = intro_with_buttons_b779, slot 1 = routine_b7f5,
*          slot 2 = intro_prelude_b769]
*
* STUB-P2.4: returns immediately (scene management not yet ported).
*   P2.4+: dispatch to the current scene's per-frame handler.
*
* Clobbers: (none per stub)
* ---------------------------------------------------------------
per_frame_continuation:
        rts                             ; STUB: no-op (scene management P2.4)

* ---------------------------------------------------------------
* video_dispatch_stub
*
* Placeholder for calls to the video dispatch table (L1900).
* Called from blit_helper path (not on main per-frame path in P2.2).
*
* ORIGIN: karateka_dissasembly_claude src/video.s $1900 jmptable_1900
*         [ref: kernel_per_frame.s blit_helper — jsr L1900 (×3)]
*         [ref: kernel_per_frame.s ctrl_r_entry — jsr L1900 (×2)]
*
* STUB-P2.3: returns immediately (blit/graphics not yet ported).
*
* Clobbers: CC
* ---------------------------------------------------------------
video_dispatch_stub:
        rts                             ; STUB: no-op (blit/graphics P2.3)
