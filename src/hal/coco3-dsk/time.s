* src/hal/coco3-dsk/time.s
*
* HAL Time subsystem — minimal-functional stubs for P2.1.
*
* Purpose:
*   Provides a real incrementing 16-bit frame counter (HAL-private)
*   and a logical frame-advance function (HAL_time_vbl_wait). These
*   stubs satisfy the HAL contract and support engine behavioral
*   verification without requiring real GIME VBL hardware timing.
*
* P3 REPLACEMENT NOTE: HAL_time_vbl_wait is a STUB.
*   Current behavior: increment frame counter and return immediately.
*   P3 replaces with: spin on GIME VBL interrupt/timer until the
*   next vertical blank. Until P3, the engine advances logically but
*   not in sync with the actual display refresh rate.
*   [no-ref: GIME VBL source (interrupt vs timer vs FIRQ) —
*     resolve from GIME-RM §8 / Sockmaster-GIME during P3]
*
* HAL contract reference: src/hal.inc (HAL_time_* definitions)
*   [ref: hal.inc HAL_time_init, HAL_time_vbl_wait,
*          HAL_time_frame_count, HAL_time_delay]
*
* DP layout (HAL scratch $00-$1F per conventions.md §2):
*   $10    hal_frame_hi  — frame counter high byte (16-bit, BE)
*   $11    hal_frame_lo  — frame counter low byte
*   [ref: conventions.md §2 — DP $00-$1F HAL scratch (reserved)]
*
* Calling convention:
*   [ref: conventions.md §3 — Args: A,B,D; Returns: D; CC.C error/success]
*   All functions return CC.C clear on success (no error paths in stubs).
* ---------------------------------------------------------------

        setdp   0

* HAL-private DP locations — declared in src/engine/globals.s (P2.3a.3)
* hal_frame_hi equ $10  / hal_frame_lo equ $11
* [ref: src/engine/globals.s — canonical DP home]

* ---------------------------------------------------------------
* HAL_time_init
*
* Zero the frame counter. Called at engine startup (init order: 2).
*
* ORIGIN: no Apple II equivalent (Apple II uses ROM-managed timing)
*
* [ref: hal.inc HAL_time_init — Args: none; Returns: CC.C clear]
* Clobbers: A, CC
* ---------------------------------------------------------------
HAL_time_init:
        clr     <hal_frame_hi           ; frame counter hi = 0
        clr     <hal_frame_lo           ; frame counter lo = 0
        andcc   #$FE                    ; CC.C clear = success
        rts

* ---------------------------------------------------------------
* HAL_time_vbl_wait  [STUB-P3]
*
* Advance the frame counter by A frames and return.
*
* P3 STUB: does NOT wait for actual VBL. Increments counter A times
* and returns immediately. P3 replaces with GIME VBL sync.
*
* ORIGIN: karateka_dissasembly_claude src/kernel.s $07D7 (routine_07d7)
*         Apple II spins on RDVBL ($C019); replaced entirely by HAL.
*         [ref: kernel.s routine_07d7 — lda ROM_VERSION; lda RDVBL; bmi spin]
*
* [ref: hal.inc HAL_time_vbl_wait — Args: A=frames; Returns: CC.C clear]
* Clobbers: A, CC
* NOTE: A=0 on entry causes 256 iterations (unsigned wraparound).
*       P2.1 callers always pass A=1; edge case benign for now.
* ---------------------------------------------------------------
HAL_time_vbl_wait:
hal_vbl_loop:
        inc     <hal_frame_lo           ; increment lo byte
        bne     hal_vbl_no_carry        ; if no wrap (lo != 0), skip carry
        inc     <hal_frame_hi           ; carry: increment hi byte
hal_vbl_no_carry:
        deca                            ; decrement frame-wait counter
        bne     hal_vbl_loop            ; loop if more frames to advance
        andcc   #$FE                    ; CC.C clear = success
        rts

* ---------------------------------------------------------------
* HAL_time_frame_count
*
* Return current 16-bit frame counter.
*
* [ref: hal.inc HAL_time_frame_count — Args: none; Returns: D=frame count]
* Clobbers: A, B (D), CC
* ---------------------------------------------------------------
HAL_time_frame_count:
        lda     <hal_frame_hi           ; D hi = frame counter high byte
        ldb     <hal_frame_lo           ; D lo = frame counter low byte
        rts                             ; D = 16-bit frame count (BE)

* ---------------------------------------------------------------
* HAL_time_delay
*
* Busy-wait N frames (delegate to HAL_time_vbl_wait).
*
* [ref: hal.inc HAL_time_delay — Args: A=frame count; Returns: CC.C clear]
* Clobbers: A, CC
* ---------------------------------------------------------------
HAL_time_delay:
        jsr     HAL_time_vbl_wait
        rts
