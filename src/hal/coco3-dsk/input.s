* src/hal/coco3-dsk/input.s
*
* HAL Input subsystem — stubs for P2.2.
*
* Purpose:
*   Provides minimal-functional stubs for HAL_input_init and
*   HAL_input_poll. These stubs satisfy the HAL contract and
*   allow the kernel per-frame loop to call HAL_input_poll without
*   requiring real CoCo3 keyboard hardware access.
*
* STUB-P2.x: both functions are stubs.
*   HAL_input_poll current behavior: return D=0 (no input detected),
*   CC.C clear. Adequate for P2.2 attract verification — the attract
*   sequence runs without user input.
*   P2.x (input port) replaces with: read CoCo3 keyboard row/column
*   matrix; translate to action/directional bit fields.
*   [no-ref: CoCo3 keyboard matrix address — resolve from CC3-TR §input
*    during input.s port]
*
* Apple II equivalent:
*   [ref: kernel_per_frame.s input_poll_loop — 65536-iter poll of
*    KBD ($C000), KBDSTRB ($C010), RDBTN0 ($C061), RDBTN1 ($C062)]
*   [ref: input.s L7603-$774A — keyboard handler subsystem]
*
* HAL contract reference: src/hal.inc (HAL_input_* definitions)
*   [ref: hal.inc HAL_input_init — Args: none; Returns: CC.C clear]
*   [ref: hal.inc HAL_input_poll — Args: none; Returns: D=input state]
*   [ref: docs/hal.md §5.5 Input — skeleton subsystem]
*
* Calling convention:
*   [ref: conventions.md §3 — CC.C clear on success]
* ---------------------------------------------------------------

        setdp   0

* ---------------------------------------------------------------
* HAL_input_init
*
* Initialize input subsystem.
*
* ORIGIN: no Apple II equivalent (Apple II polls hardware directly)
*
* [ref: hal.inc HAL_input_init — Args: none; Returns: CC.C clear]
* [ref: docs/hal.md §7 Init Order — init order 4]
* Clobbers: CC
* ---------------------------------------------------------------
HAL_input_init:
        andcc   #$FE                    ; CC.C clear = success (stub)
        rts

* ---------------------------------------------------------------
* HAL_input_poll  [STUB-P2.x]
*
* Sample keyboard and joystick; return packed input state in D.
*
* P2.x STUB: always returns D=0 (no input), CC.C clear.
*   Adequate for attract-mode verification (no user input).
*   Future: read CoCo3 keyboard matrix; pack into D.
*     A = action bits (punch, kick, etc. — TBD during port)
*     B = directional bits (left, right, etc. — TBD during port)
*
* ORIGIN: karateka_dissasembly_claude src/kernel_per_frame.s
*         Apple II input_poll_loop at $025E-$0290:
*         [ref: input_poll_loop — lda KBD; bmi input_detected]
*         [ref: input_poll_loop — lda RDBTN0/RDBTN1; bmi input_detected]
*         This stub replaces the entire 65536-iteration poll.
*
* [ref: hal.inc HAL_input_poll — Args: none; Returns: D=input state]
* Clobbers: A, B, CC
* ---------------------------------------------------------------
HAL_input_poll:
        clra                            ; A = 0 (no action input)
        clrb                            ; B = 0 (no directional input)
        andcc   #$FE                    ; CC.C clear = success
        rts
