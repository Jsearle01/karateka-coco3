;==============================================================
; karateka-coco3 HAL contract
; hal.inc — assembly-syntactic interface definition
; Version: 0.1 (P1.3 deliverable)
;
; Defines the contract between platform-neutral engine code
; and platform-specific HAL implementations.
;
; Shape inherited from pop-coco3-design v0.7 Section 6.11.
; Karateka-specific divergences documented in docs/hal.md.
;
; See docs/hal.md for the human-readable companion.
; Reference discipline per docs/karateka-coco3-design-v0.1.md
; Section 6.6 and 6502-6809-conversion-patterns/shared/
; G-methodology/G.1-reference-discipline.md.
;==============================================================

;--------------------------------------------------------------
; CALLING CONVENTION (applies to all HAL functions)
;
; Arguments:  A, B, D (scalar), X (pointer in), Y (secondary)
; Returns:    D (scalar), X (pointer out), CC.C (error flag)
; On error:   CC.C set, A = error code
; On success: CC.C clear
; Preserved:  U (engine frame pointer), DP (direct page)
; Scratch:    A, B, X, Y, CC bits except .C
;
; HAL functions are main-context only. Not safe from interrupt
; handlers.
;--------------------------------------------------------------

;--------------------------------------------------------------
; DIRECT PAGE (DP) USAGE POLICY
;
; HAL owns:    $00-$1F  (32 bytes — scratch, temp params)
; Engine owns: $20-$7F  (96 bytes — engine ZP variables)
; Reserved:    $80-$FF  (CoCo3 system use — do not touch)
;
; [no-ref: CoCo3 system DP usage at $80-$FF — resolve during
;   P2 by checking CC3-TR for system ZP conventions]
;
; The HAL/engine split within $00-$7F is a design choice, not
; a hardware constraint. Subject to revision if pressure
; surfaces during P2 engine porting.
;--------------------------------------------------------------

HAL_ZP_BASE     equ $00         ; HAL scratch region base
HAL_ZP_PARAM0   equ $00         ; Byte parameter 0
HAL_ZP_PARAM1   equ $01         ; Byte parameter 1
HAL_ZP_PARAM2   equ $02         ; Byte parameter 2
HAL_ZP_PARAM3   equ $03         ; Byte parameter 3
HAL_ZP_PTR0     equ $04         ; Pointer scratch 0 (2 bytes)
HAL_ZP_PTR1     equ $06         ; Pointer scratch 1 (2 bytes)
; $08-$1F: HAL internal use (subsystem-specific, defined in
;          each HAL implementation file)

ENGINE_ZP_BASE  equ $20         ; Engine ZP region base

;--------------------------------------------------------------
; MEMORY MAP CONSTANTS
; Per docs/memory-map.md §6.
; Physical address derivation per [ref: GIME-RM §13].
; All values subject to revision if P2/P3 implementation
; surfaces pressure (single comment update + rebuild).
;--------------------------------------------------------------

; Frame buffers (320x192x4, $3C00 bytes each)
; [ref: GIME-RM §10] buffer size derivation
KCOCO3_FB_A_BASE    equ $8000   ; Frame A CPU base (back buffer)
KCOCO3_FB_B_BASE    equ $C000   ; Frame B CPU base (front buffer)
KCOCO3_FB_SIZE      equ $3C00   ; Frame buffer byte count (80 B/row × 192 rows)

; GIME VOFFSET values for frame buffer swap
; [ref: GIME-RM §13] physical $78000: $FF9D=$F0, $FF9E=$00
;                    physical $7C000: $FF9D=$F8, $FF9E=$00
KCOCO3_FB_A_VOFF_HI equ $F0    ; $FF9D value → Frame A visible
KCOCO3_FB_A_VOFF_LO equ $00    ; $FF9E value
KCOCO3_FB_B_VOFF_HI equ $F8    ; $FF9D value → Frame B visible
KCOCO3_FB_B_VOFF_LO equ $00    ; $FF9E value

; Trace ring buffer
; [ref: memory-map §4.7]
KCOCO3_TRACE_BUFFER     equ $7800   ; trace ring buffer CPU base
KCOCO3_TRACE_BUF_SIZE   equ $0100   ; 256 bytes

; GIME hardware registers
; [ref: GIME-RM §3] register map summary
KCOCO3_GIME_INIT0       equ $FF90   ; initialization reg 0 (COCO3 mode)
KCOCO3_GIME_INIT1       equ $FF91   ; initialization reg 1 (TR, TINS)
KCOCO3_GIME_IRQENR      equ $FF92   ; IRQ enable (bit 3 = VBORD/VBL)
KCOCO3_GIME_FIRQENR     equ $FF93   ; FIRQ enable
KCOCO3_GIME_VMODE       equ $FF98   ; video mode (graphics: $80)
KCOCO3_GIME_VRES        equ $FF99   ; video resolution (320×192×4: $15)
KCOCO3_GIME_VSCROL      equ $FF9C   ; vertical scroll (init $00 required)
KCOCO3_GIME_VOFFSET_HI  equ $FF9D   ; screen start phys addr high
KCOCO3_GIME_VOFFSET_LO  equ $FF9E   ; screen start phys addr low
KCOCO3_GIME_HOFFSET     equ $FF9F   ; horizontal offset (init $00 required)
KCOCO3_MMU_TASK0        equ $FFA0   ; MMU task set 0 base (FFA0-FFA7)
KCOCO3_GIME_PALETTE_BASE equ $FFB0  ; palette register 0 (4 used in 4-color mode)
KCOCO3_SAM_CLK_HI       equ $FFD9   ; SAM: set 1.78 MHz CPU clock
KCOCO3_SAM_RAM_C000     equ $FFDF   ; SAM: RAM at $C000 (task 0)

; GIME mode values
; [ref: GIME-RM §10] verified working reference mode
KCOCO3_VMODE_GRAPHICS   equ $80     ; $FF98 = graphics (BP=1)
KCOCO3_VRES_320x192x4   equ $15     ; $FF99 = LPF=00, HRES=101, CRES=01
KCOCO3_INIT0_COCO3      equ $4C     ; $FF90 = COCO=0, MMUEN=1, MC3=1, MC2=1

;--------------------------------------------------------------
; ERROR CODES
; Inherited from pop-coco3 Section 6.11.4.2.
; Codes are stable; new codes appended; existing not renumbered.
;--------------------------------------------------------------

ERR_OK          equ 0           ; success (CC.C always clear)
ERR_NOT_FOUND   equ 1           ; resource not found
ERR_INVALID     equ 2           ; invalid argument
ERR_NOMEM       equ 3           ; insufficient memory
ERR_IO          equ 4           ; I/O failure
ERR_DEVICE      equ 5           ; hardware not present/responding
ERR_TIMEOUT     equ 6           ; operation timed out
ERR_BUSY        equ 7           ; resource busy
ERR_INTERNAL    equ 8           ; internal HAL error

;--------------------------------------------------------------
; INIT ORDER (call in this sequence at boot)
;
; 1. HAL_mem_size_detect  (memory probe first)
; 2. HAL_time_init        (timing before other init)
; 3. HAL_gfx_init         (screen up early for error display)
; 4. HAL_input_init
; 5. HAL_sound_init
; 6. HAL_file_init
; -  Debug/Trace: no init function; HAL_debug_trace_event is
;    available immediately at boot (ring buffer in static memory)
;--------------------------------------------------------------

;==============================================================
; GRAPHICS SUBSYSTEM — DETAILED
; Target: GIME 320×192×4 color mode, double-buffered.
;
; [no-ref: GIME mode setup (CRES/HRES bits for 320×192×4) —
;   resolve during P2 by reading GIME-RM for CRES bit field
;   and CC3-TR for mode register layout]
; [no-ref: GIME palette register addresses ($FFB0-$FFBF assumed
;   from Sockmaster-GIME; verify exact range in GIME-RM §3.x
;   during P2]
; [no-ref: frame buffer MMU slot assignments — resolve during
;   P2 memory map work (P1.6 deliverable)]
;==============================================================

; HAL_gfx_init
;   Initialize GIME for 320×192×4 mode with double buffering.
;   Args:  A = palette descriptor index (0 = default global palette)
;   Returns: CC.C clear on success
;   Errors:  ERR_NOMEM if frame buffers cannot be allocated
;   Preserves: U, Y
;   Clobbers: A, B, X, CC
;   Init order: 3
HAL_gfx_init        equ *       ; defined in src/hal/coco3-dsk/gfx.s

; HAL_gfx_shutdown
;   Restore screen mode (e.g. return to text for error display).
;   Args:  none
;   Returns: nothing
;   Errors:  none
;   Preserves: U, Y
;   Clobbers: A, B, X, CC
HAL_gfx_shutdown    equ *       ; defined in src/hal/coco3-dsk/gfx.s

; HAL_gfx_clear
;   Fill active back buffer with palette index 0 (background).
;   Args:  none
;   Returns: CC.C clear
;   Errors:  none
;   Preserves: U
;   Clobbers: A, B, X, Y, CC
;   Note: per D.3 back-buffer discipline; never writes to front
HAL_gfx_clear       equ *       ; defined in src/hal/coco3-dsk/gfx.s

; HAL_gfx_blit_sprite
;   Render CoCo3 packed sprite at (col, row) in back buffer.
;   Args:  X = pointer to sprite binary (height + coco3_width +
;               packed bitmap per P1.2 format)
;          A = destination byte column (0-79; 4px per byte)
;          B = destination pixel row (0-191)
;   Returns: CC.C clear on success
;   Errors:  ERR_INVALID if sprite extends beyond frame buffer
;   Preserves: U
;   Clobbers: A, B, X, Y, CC
;   [no-ref: blit algorithm is engine-internal; GIME has no
;     sprite hardware — pure packed-byte memory write]
HAL_gfx_blit_sprite equ *       ; defined in src/hal/coco3-dsk/gfx.s

; HAL_gfx_set_palette
;   Write 4-entry palette to GIME palette registers.
;   Args:  X = pointer to 4-byte palette array (one byte per
;               entry, each a 6-bit GIME color code 0-63)
;   Returns: CC.C clear
;   Errors:  none
;   Preserves: X, U, Y
;   Clobbers: A, B, CC
;   Timing: call during VBL to avoid mid-scanline artifact
;   [no-ref: GIME palette register addresses — verify in
;     GIME-RM §3.x during P2; Sockmaster-GIME empirical note:
;     writes during active scanline cause visible artifact]
HAL_gfx_set_palette equ *       ; defined in src/hal/coco3-dsk/gfx.s

; HAL_gfx_present
;   Swap front/back buffers (double-buffer flip).
;   Args:  none
;   Returns: CC.C clear
;   Errors:  none
;   Preserves: U, Y
;   Clobbers: A, B, X, CC
;   Timing: call after render complete, before or during VBL
;   [no-ref: GIME buffer-base register (VOFF or equivalent)
;     for page flip — resolve during P2 from GIME-RM]
HAL_gfx_present     equ *       ; defined in src/hal/coco3-dsk/gfx.s

;==============================================================
; TIME SUBSYSTEM — DETAILED
; Frame timing, VBL synchronization, frame counter.
;
; [no-ref: VBL detection mechanism (polling $FF03 vs interrupt
;   vs GIME vsync bit) — resolve during P2 by reading CC3-TR
;   interrupt section and GIME-RM vsync documentation]
;==============================================================

; HAL_time_init
;   Initialize VBL source and start frame counter.
;   Args:  none
;   Returns: CC.C clear on success
;   Errors:  ERR_DEVICE if VBL source unavailable
;   Preserves: U, Y
;   Clobbers: A, B, X, CC
;   Init order: 2
HAL_time_init       equ *       ; defined in src/hal/coco3-dsk/time.s

; HAL_time_vbl_wait
;   Block until next vertical blanking interval.
;   Replaces karateka_dissasembly_claude vbl_sync at $779A
;   (display_7700.s; 327,189 fires — hottest routine).
;   Args:  none
;   Returns: CC.C clear
;   Errors:  none (blocking)
;   Preserves: U, Y, X
;   Clobbers: A, B, CC
;   Side effects: increments internal frame counter
HAL_time_vbl_wait   equ *       ; defined in src/hal/coco3-dsk/time.s

; HAL_time_frame_count
;   Return current 16-bit frame counter (wraps $FFFF→$0000).
;   Args:  none
;   Returns: D = frame count
;   Errors:  none
;   Preserves: U, Y, X, CC
;   Clobbers: D
HAL_time_frame_count equ *      ; defined in src/hal/coco3-dsk/time.s

; HAL_time_delay
;   Busy-wait N frames.
;   Args:  A = frame count to wait
;   Returns: CC.C clear
;   Errors:  none
;   Preserves: U, Y, X
;   Clobbers: A, B, CC
HAL_time_delay      equ *       ; defined in src/hal/coco3-dsk/time.s

;==============================================================
; SOUND SUBSYSTEM — DETAILED
; DAC output and tone-record interpretation.
; Replaces karateka_dissasembly_claude sound_engine.s ($0D00)
; and sound.s pcm_player ($0DC0).
;
; [no-ref: CoCo3 DAC register address — resolve during P2
;   from CC3-TR sound/DAC section]
;==============================================================

; HAL_sound_init
;   Initialize sound hardware.
;   Args:  none
;   Returns: CC.C clear on success
;   Errors:  ERR_DEVICE if DAC not available
;   Preserves: U, Y
;   Clobbers: A, B, X, CC
;   Init order: 5
HAL_sound_init      equ *       ; defined in src/hal/coco3-dsk/sound.s

; HAL_sound_shutdown
;   Silence output and release sound resources.
;   Args:  none
;   Returns: nothing
;   Errors:  none
;   Preserves: U, Y, X
;   Clobbers: A, B, CC
HAL_sound_shutdown  equ *       ; defined in src/hal/coco3-dsk/sound.s

; HAL_sound_dac_sample
;   Output one 6-bit DAC sample (low-level).
;   For per-frame PCM playback. Engine typically calls
;   HAL_sound_play_event rather than this directly.
;   Args:  A = 6-bit sample value (0-63)
;   Returns: CC.C clear
;   Errors:  none
;   Preserves: U, Y, X, B
;   Clobbers: A, CC
;   [no-ref: DAC register address — resolve during P2 from
;     CC3-TR]
HAL_sound_dac_sample equ *      ; defined in src/hal/coco3-dsk/sound.s

; HAL_sound_tone_start
;   Begin playing a tone-record sequence.
;   Data format matches karateka tone-record format (pass-
;   through from tools/sound_convert.py tone section).
;   Args:  X = pointer to tone-record sequence
;   Returns: CC.C clear
;   Errors:  none
;   Preserves: U, Y
;   Clobbers: A, B, X, CC
;   Side effects: HAL maintains playback state; advance
;     via per-frame HAL_sound_play_event or explicit update
HAL_sound_tone_start equ *      ; defined in src/hal/coco3-dsk/sound.s

; HAL_sound_tone_stop
;   Silence any active tone.
;   Args:  none
;   Returns: CC.C clear
;   Errors:  none
;   Preserves: U, Y, X
;   Clobbers: A, B, CC
HAL_sound_tone_stop equ *       ; defined in src/hal/coco3-dsk/sound.s

; HAL_sound_play_event
;   High-level sound event dispatch. Engine signals event by
;   ID; HAL maps to tone-record or PCM playback.
;   Args:  A = sound event ID (enumeration TBD during P2)
;   Returns: CC.C clear on success
;   Errors:  ERR_INVALID if event ID unknown
;   Preserves: U, Y
;   Clobbers: A, B, X, CC
;   [no-ref: sound event ID → audio mapping is engine-internal;
;     table defined during P2 engine porting]
;   Note: may be removed in P2 if engine-side sound dispatch
;     makes this layer redundant. See docs/hal.md §5.3.
HAL_sound_play_event equ *      ; defined in src/hal/coco3-dsk/sound.s

;==============================================================
; MEMORY SUBSYSTEM — SKELETON
; Detailed during P2 when engine subsystem is ported.
;==============================================================

; HAL_mem_size_detect
;   Probe installed RAM at boot. Returns memory mode.
;   Args:  none
;   Returns: A = 0 if 128K, 1 if 512K
;   Errors:  none (always succeeds)
;   Preserves: U, Y
;   Clobbers: A, B, X, CC
;   Init order: 1 (first — other init may need memory info)
;   [no-ref: GIME MMU probing for 128K vs 512K — resolve
;     during P2 from CC3-TR MMU section; see D.5 pattern]
HAL_mem_size_detect equ *       ; (P2 stub)

;==============================================================
; INPUT SUBSYSTEM — SKELETON
; Detailed during P2 when engine input subsystem is ported.
;==============================================================

; HAL_input_init
;   Initialize input scanning.
;   Args:  none
;   Returns: CC.C clear
;   Errors:  none
;   Preserves: U, Y
;   Clobbers: A, B, X, CC
;   Init order: 4
HAL_input_init      equ *       ; (P2 stub)

; HAL_input_poll
;   Sample keyboard and joystick; return packed state.
;   Replaces karateka_dissasembly_claude input.s ($7603-$774A).
;   Args:  none
;   Returns: D = packed input state
;              A (hi): action bits (TBD during P2)
;              B (lo): directional bits (TBD during P2)
;   Errors:  none
;   Preserves: U, Y, X
;   Clobbers: A, B, CC
;   [no-ref: CoCo3 keyboard matrix registers — resolve during
;     P2 from CC3-TR input section]
HAL_input_poll      equ *       ; (P2 stub)

;==============================================================
; FILE SUBSYSTEM — SKELETON
; Detailed during P2 when disk loading timing is understood.
;==============================================================

; HAL_file_init
;   Initialize disk subsystem.
;   Args:  none
;   Returns: CC.C clear on success
;   Errors:  ERR_DEVICE if disk controller not available
;   Preserves: U, Y
;   Clobbers: A, B, X, CC
;   Init order: 6 (last)
HAL_file_init       equ *       ; (P2 stub)

; HAL_file_load
;   Load entire named file to a memory address.
;   Replaces karateka_dissasembly_claude disk_loader.s ($0300).
;   Args:  X = pointer to null-terminated filename
;          U = destination address
;          D = byte count (0 = load entire file)
;   Returns: D = bytes loaded, CC.C clear on success
;   Errors:  ERR_NOT_FOUND, ERR_IO, ERR_NOMEM
;   Preserves: Y
;   Clobbers: A, B, X, U, CC
HAL_file_load       equ *       ; (P2 stub)

;==============================================================
; SYSTEM SUBSYSTEM — SKELETON
; Detailed during P2.
;==============================================================

; HAL_sys_cpu
;   Return detected CPU type (cached from boot probe).
;   Args:  none
;   Returns: A = 0 (6809) or 1 (6309)
;   Errors:  none
;   Preserves: B, X, Y, U, DP
;   Clobbers: A, CC
HAL_sys_cpu         equ *       ; (P2 stub)

; HAL_sys_target
;   Return target platform identifier (constant).
;   Args:  none
;   Returns: A = 0 (coco3-dsk; only target in v1.0)
;   Errors:  none
;   Preserves: B, X, Y, U, DP
;   Clobbers: A, CC
HAL_sys_target      equ *       ; (P2 stub)

; HAL_sys_panic
;   Unrecoverable error handler. Display message, halt.
;   Args:  X = pointer to null-terminated message (or 0)
;   Returns: does not return
;   Errors:  this IS the error path
HAL_sys_panic       equ *       ; (P2 stub)

;==============================================================
; DEBUG/TRACE SUBSYSTEM — DETAILED
; Always-on trace mechanism for harness instrumentation plus
; DEV_MODE-only logging and assertions.
;
; HAL_debug_trace_event is ALWAYS present (all builds). The
; MAME scripted-test harness reads the trace ring buffer to
; verify engine behavior. Compiling it out of production builds
; would prevent harness coverage on release binaries.
;
; HAL_debug_log and HAL_debug_assert are DEV_MODE-only. Wrap
; them in ifdef DEV_MODE blocks (see docs/conventions.md §9).
;
; Engine event code enumeration is engine-internal. The HAL
; accepts event codes as opaque bytes (0-255). Engine defines
; its own enum in src/engine/trace_events.inc (materializes
; during P2 when first trace points are added).
;
; Trace buffer: a fixed-size ring buffer at a known memory
; address. Address assigned during P1.6 memory map work.
; [no-ref: trace buffer location — deferred to P1.6]
;==============================================================

; HAL_debug_trace_event
;   Record an instrumentation event in the trace ring buffer.
;   Called by engine code at state transitions, subsystem
;   entry/exit, and other significant points. MAME harness
;   reads the ring buffer to verify expected event sequences.
;   ALWAYS PRESENT — not DEV_MODE gated.
;   Args:  A = event code (0-255; engine-defined opaque byte)
;          X = event data pointer (or 0 if no data)
;   Returns: nothing (always succeeds; no error path)
;   Preserves: U, Y, X, B
;   Clobbers: A, CC
;   [no-ref: trace mechanism is engine-internal; no hardware
;     reference applies]
HAL_debug_trace_event equ *     ; defined in src/hal/coco3-dsk/debug.s

; HAL_debug_log
;   Emit a null-terminated debug string to implementation-
;   defined destination (MAME debug log, serial port, ring
;   buffer, etc.). DEV_MODE only — wrap in ifdef DEV_MODE.
;   Args:  X = pointer to null-terminated string
;   Returns: nothing (always succeeds)
;   Preserves: U, Y, X
;   Clobbers: A, B, CC
;   [no-ref: debug output destination is implementation choice;
;     no hardware reference applies]
HAL_debug_log       equ *       ; defined in src/hal/coco3-dsk/debug.s

; HAL_debug_assert
;   Verify a precondition. If condition is false, call
;   HAL_sys_panic with message and halt. DEV_MODE only —
;   wrap in ifdef DEV_MODE (or use DEV_MODE_ASSERT macro).
;   Args:  A = condition (0 = fail, non-zero = pass)
;          X = pointer to null-terminated assertion message
;   Returns: nothing on pass (CC.C clear)
;   Errors:  does not return on failure — calls HAL_sys_panic
;   Preserves: U, Y (on pass)
;   Clobbers: A, B, CC
;   Within-HAL call note: HAL_debug_assert calls HAL_sys_panic
;     on failure. This is the one permitted within-HAL call in
;     the contract; HAL functions are otherwise not safe to call
;     from other HAL functions.
;   [no-ref: assertion mechanism is engine-internal; no hardware
;     reference applies]
HAL_debug_assert    equ *       ; defined in src/hal/coco3-dsk/debug.s
