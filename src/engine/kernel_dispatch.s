* src/engine/kernel_dispatch.s
*
* Kernel cross-subsystem dispatch table + handler stubs.
*
* ORIGIN: karateka_dissasembly_claude src/kernel_dispatch.s
*         Apple II $0C40-$0C54 (7-entry JMP trampoline table)
*         karateka_dissasembly_claude src/kernel_dispatch_handlers.s
*         Apple II $0C55-$0CBD (7 handler bodies)
*
* Purpose:
*   Houses the CoCo3 equivalent of the $0C4x cross-subsystem dispatch
*   table. Callers (input.s, when ported) use this table to reach
*   handlers for timer-expiry events and keyboard-dispatch exits.
*
*   All seven handlers are ASSERT-FIRE STUBS in P2.2 because:
*     (a) 0 trace fires during attract (full-cycle trace, ~78M lines).
*         [ref: kernel_dispatch_handlers.s — "NONE of these handlers
*          were reached in dump01_intro's trace"]
*     (b) The callers (input.s L763C timer-expiry; L7697 keyboard handler)
*         are not reached during attract-mode unattended operation.
*
*   Each handler stub calls HAL_sys_panic if reached, halting MAME.
*   This provides runtime verification: the P2.2 attract run produces
*   0 stub invocations, confirming the safety analysis at runtime.
*
* DEV_MODE dependency: HAL_sys_panic halts MAME (bra *). If a handler
*   fires during attract, MAME hangs instead of reaching the PASS
*   sentinel — the harness reports timeout-failure, surfacing the
*   violation immediately. Verification depends on DEV_MODE being active.
*   [ref: docs/project/conventions.md §9 — DEV_MODE build configuration]
*
* Handler semantics (Apple II): all 7 handlers produce speaker effects
*   (SPKR toggle + ROM_WAIT timing loops). On CoCo3 they will map to
*   HAL_sound_* calls when sound is ported. Not ported in P2.2.
*   [ref: kernel_dispatch_handlers.s — "All seven handlers reference
*    SPKR ($C030) and JSR ROM_WAIT ($FCA8)"]
*
* Reference citations:
*   [ref: kernel_dispatch.s — $0C40-$0C54; callers: input.s L763C, L7697]
*   [ref: kernel_dispatch_handlers.s — $0C55-$0CBD; 7 handlers; 0 traces]
*   [ref: p2-scoping-survey.md §3 kernel/dispatch — handler safety analysis]
*   [ref: hal.inc HAL_sys_panic — Args: X=msg; does not return]
* ---------------------------------------------------------------

        setdp   0

* ---------------------------------------------------------------
* DISPATCH TABLE: kd_table_0c40
*
* 7-entry dispatch table. Callers JSR to the corresponding entry
* address. Each entry jumps to the handler stub.
*
* ORIGIN: karateka_dissasembly_claude src/kernel_dispatch.s $0C40-$0C54
*   [ref: kernel_dispatch.s — "3-byte JMP trampoline table forming a
*    public dispatch interface used by multiple subsystems"]
*
* Callers (once input.s is ported):
*   L763C (input.s): frame-state update / timer-expiry events
*   L7697 (input.s): keyboard handler common exit via slot 4
* ---------------------------------------------------------------
kd_slot_0:      lbra    handler_stub_0c55       ; -> slot 0 handler stub
kd_slot_1:      lbra    handler_stub_0c64       ; -> slot 1 handler stub
kd_slot_2:      lbra    handler_stub_0c74       ; -> slot 2 handler stub
kd_slot_3:      lbra    handler_stub_0c84       ; -> slot 3 handler stub
kd_slot_4:      lbra    handler_stub_0c92       ; -> slot 4 (keyboard common exit)
kd_slot_5:      lbra    handler_stub_0ca0       ; -> slot 5 handler stub
kd_slot_6:      lbra    handler_stub_0cb0       ; -> slot 6 handler stub

* ---------------------------------------------------------------
* HANDLER STUBS — assert-fire if called during attract
*
* Each stub calls HAL_sys_panic with an identifying message.
* If any fires during the P2.2 attract run, MAME halts and the
* harness reports failure — the safety assumption is violated.
*
* APPLE II BEHAVIOR (for reference when porting):
*   handler_0c55 (slot 0): Group A speaker effect. Y=2 to $28,
*     INY×1, TYA as delay, lda SPKR; jsr ROM_WAIT. 38 iters.
*     [ref: kernel_dispatch_handlers.s handler_0c55]
*   handler_0c64 (slot 1): Group A. Y=2 to $3A, INY×2. 28 iters.
*     Caller: L763C after ZP$42 timer expires.
*   handler_0c74 (slot 2): Group A. Y=2 to $24, INY×2. 17 iters.
*     Caller: L763C after ZP$43 timer expires + ZP$41=1.
*   handler_0c84 (slot 3): Group B. Y=$0A↓0, fixed delay=$05.
*     Caller: L763C after ZP$45 timer expires.
*   handler_0c92 (slot 4): Group B. Y=$10↓0, fixed delay=$0A.
*     Caller: L7697 jmp L0C4C (common exit ALL matched system keys).
*   handler_0ca0 (slot 5): Group C. Halving delay, 5 iters.
*     Caller: L763C blit-trigger branch (ZP$36 != 0).
*   handler_0cb0 (slot 6): Group B. Y=$03↓0, fixed delay=$10.
*     Caller: L763C blit-trigger (ZP$36 = 0).
* CoCo3 port (future): each will map to HAL_sound_* DAC output.
* ---------------------------------------------------------------

handler_stub_0c55:
        ldx     #kd_msg_0c55
        jsr     HAL_sys_panic           ; does not return
        rts                             ; unreachable
kd_msg_0c55:
        fcc     "STUB: handler_0c55 fired during attract"
        fcb     0

handler_stub_0c64:
        ldx     #kd_msg_0c64
        jsr     HAL_sys_panic
        rts
kd_msg_0c64:
        fcc     "STUB: handler_0c64 fired during attract"
        fcb     0

handler_stub_0c74:
        ldx     #kd_msg_0c74
        jsr     HAL_sys_panic
        rts
kd_msg_0c74:
        fcc     "STUB: handler_0c74 fired during attract"
        fcb     0

handler_stub_0c84:
        ldx     #kd_msg_0c84
        jsr     HAL_sys_panic
        rts
kd_msg_0c84:
        fcc     "STUB: handler_0c84 fired during attract"
        fcb     0

handler_stub_0c92:
        ldx     #kd_msg_0c92
        jsr     HAL_sys_panic
        rts
kd_msg_0c92:
        fcc     "STUB: handler_0c92 fired during attract"
        fcb     0

handler_stub_0ca0:
        ldx     #kd_msg_0ca0
        jsr     HAL_sys_panic
        rts
kd_msg_0ca0:
        fcc     "STUB: handler_0ca0 fired during attract"
        fcb     0

handler_stub_0cb0:
        ldx     #kd_msg_0cb0
        jsr     HAL_sys_panic
        rts
kd_msg_0cb0:
        fcc     "STUB: handler_0cb0 fired during attract"
        fcb     0
