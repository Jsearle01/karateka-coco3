* src/hal/coco3-dsk/sys.s
*
* HAL System subsystem — stubs for P2.2.
*
* Purpose:
*   Provides HAL_sys_panic, required by handler stubs in
*   src/engine/kernel_dispatch.s. If a handler fires during attract,
*   HAL_sys_panic halts MAME (infinite loop); the harness sees a
*   timeout-failure instead of a PASS sentinel, surfacing the
*   safety violation immediately.
*
* HAL contract reference: src/hal.inc
*   [ref: hal.inc HAL_sys_panic — Args: X=msg ptr; does not return]
*   [ref: docs/hal.md §5.7 System — HAL_sys_panic spec]
*   [ref: conventions.md §9 — DEV_MODE; panic is always active]
*
* Calling convention:
*   [ref: conventions.md §3 — DP preserved; Args: X (message ptr)]
* ---------------------------------------------------------------

        setdp   0

* ---------------------------------------------------------------
* HAL_sys_panic
*
* Unrecoverable error handler. Halts the CPU (infinite loop).
* Called by handler stubs in kernel_dispatch.s when a stub fires.
*
* Args:  X = pointer to null-terminated message (or 0)
* Returns: does not return
*
* [ref: hal.inc HAL_sys_panic — "Unrecoverable error handler.
*  Display message, halt."]
*
* P2.x BEHAVIOR: infinite loop (bra *). The MAME harness detects
*   this as a timeout-failure because the PASS sentinel is never
*   written to the output directory. In a real system this would
*   write the message (X) to a display or serial port before halting.
*   [no-ref: display/serial output destination — deferred to P3+]
*
* Clobbers: (never returns)
* ---------------------------------------------------------------
HAL_sys_panic:
        bra     HAL_sys_panic           ; infinite loop — MAME timeout failure
