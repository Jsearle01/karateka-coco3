* src/hal/coco3-dsk/gfx.s
*
* HAL Graphics subsystem — STUBS for P2.x.
*
* Purpose:
*   Placeholder stubs for HAL_gfx_* functions required by the engine
*   but not yet implemented. Real implementations are P3 work (GIME
*   320x192x4 mode, frame buffer management, VBL-gated present).
*
* P3 REPLACEMENT NOTE: All functions here are stubs.
*   HAL_gfx_present: P3 will write the GIME VOFFSET register to swap
*   the displayed frame buffer.
*   [no-ref: GIME VOFFSET / buffer-base register for page flip —
*     resolve from GIME-RM §7 / Sockmaster-GIME during P3]
*
* [ref: hal.inc HAL_gfx_present — swap front/back buffers]
* [ref: conventions.md §3 — calling conventions: CC.C clear on success]
* ---------------------------------------------------------------

        setdp   0

* ---------------------------------------------------------------
* HAL_gfx_present  [STUB-P3]
*
* Swap front/back frame buffers (display the back buffer).
* Stub: returns immediately. P3 writes GIME VOFFSET register.
*
* Called from timer_framesync.s page_flip after VBL wait.
* [ref: kernel.s routine_0799 lda TXTPAGE1 / routine_07ac lda TXTPAGE2]
* In P2.x, the display gate is a no-op; frame buffer is not switched.
*
* [ref: hal.inc HAL_gfx_present — Args: none; Returns: CC.C clear]
* Clobbers: CC
* ---------------------------------------------------------------
HAL_gfx_present:
        andcc   #$FE                    ; CC.C clear = success (stub)
        rts
