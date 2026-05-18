# karateka-coco3 HAL Contract

Version: 0.1 + P1.3 follow-up (2026-05-13)

## 1. Overview

The Hardware Abstraction Layer (HAL) is the boundary between
platform-neutral engine code and platform-specific implementation.
Engine code calls HAL functions by name; HAL implementations handle
actual hardware. This separation allows a single engine codebase to
run on multiple targets (Gate K.1.2: coco3-dsk for v1.0).

This document is the human-readable companion to `src/hal.inc`,
which contains the assembly-syntactic contract.

**Scope:**
- Four subsystems are detailed: Graphics, Time, Sound, Debug/Trace
- Four subsystems are skeletoned: Memory, Input, File, System
  (detailed in P2 when consuming engine subsystem is ported)

Debug/Trace added in P1.3 follow-up commit (closes gap surfaced
during P1.4). 8 subsystems total; 24 functions.

**Shape inherited from pop-coco3-design v0.7 Section 6.11:**
calling convention, error mechanism, init order, and subsystem
structure follow pop-coco3 directly. Karateka-specific divergences
are documented in Section 8 of this document.

---

## 2. Calling Conventions

All HAL functions follow a uniform convention:

### 2.1 Register usage

| Role | Registers | Notes |
|------|-----------|-------|
| Arguments (caller sets) | A, B, D, X, Y | Specific use per function |
| Scalar return (callee sets) | D | 8-bit results in A or B |
| Pointer return (callee sets) | X | |
| Error flag (callee sets) | CC.C | 0 = success, 1 = error |
| **Preserved** (callee must save/restore) | **U, DP** | Engine frame pointer; direct page |
| Scratch (callee may clobber freely) | A, B, X, Y, CC (except .C) | Unless documented otherwise |

The 6309 registers (E, F, W, Q, MD, V) never appear in the HAL
contract surface. They may appear internally in optimization-layer
implementations (`src/opt/6309/`) but are invisible to engine
callers.

### 2.2 Error reporting

On success: CC.C clear.
On failure: CC.C set, A = error code.

```asm
    jsr  HAL_gfx_init
    bcs  init_failed        ; CC.C set = error
    ; ... success path ...
init_failed:
    ; A = error code
```

**Error codes** (stable; new codes appended; existing not renumbered):

| Code | Value | Meaning |
|------|-------|---------|
| ERR_OK | 0 | Success (CC.C always clear with this) |
| ERR_NOT_FOUND | 1 | Resource not found |
| ERR_INVALID | 2 | Invalid argument |
| ERR_NOMEM | 3 | Insufficient memory |
| ERR_IO | 4 | I/O failure |
| ERR_DEVICE | 5 | Hardware not present or not responding |
| ERR_TIMEOUT | 6 | Operation timed out |
| ERR_BUSY | 7 | Resource busy |
| ERR_INTERNAL | 8 | Internal HAL error (should not happen) |

### 2.3 Interrupt discipline

HAL functions are main-context only. They are not safe to call from
interrupt handlers. HAL-internal interrupt handlers (e.g. a VBL
handler maintaining the frame counter) communicate with main-context
HAL code via shared variables, not via HAL calls.

---

## 3. Direct Page (DP) Usage Policy

```
$00-$1F  HAL scratch / parameter passing (32 bytes)
$20-$7F  Engine-owned ZP variables (96 bytes)
$80-$FF  CoCo3 system reserved — do not touch
```

DP is preserved across all HAL calls (callee saves/restores).
Engine code can rely on DP being constant after boot.

**Subject to revision.** The $00-$1F / $20-$7F split within the
lower page is a design choice, not a hardware constraint. If P2
engine porting reveals pressure on either region, the split point
will be adjusted. The CoCo3 system's use of $80-$FF is fixed by
hardware.

`[no-ref: CoCo3 system DP usage at $80-$FF — verify in CC3-TR
during P2 before writing any HAL code that touches $80+]`

---

## 4. Data Formats

### 4.1 Sprite format

Defined by P1.2 asset conversion. Binary layout:

```
byte 0:    height (rows)
byte 1:    coco3_width (bytes per row; 4 pixels per byte)
bytes 2+:  packed bitmap, row-major
           each byte: 4 pixels, 2 bits each, MSB-first
           pixel value 0 = palette index 0 (background)
           pixel value 1 = palette index 1 (foreground)
           values 2-3 reserved (indicate palette error if seen)
```

Produced by `tools/sprite_convert.py`. Verified visually via
`tools/sprite_render_apple2.py` and `tools/sprite_visualize.py`
(P1.2 follow-up).

### 4.2 Palette format

4 bytes, one per palette entry, each a 6-bit GIME color code (0-63) in
composite mode (bits 5:4 = intensity 0-3; bits 3:0 = hue 0-15).

```
byte 0: palette index 0 (background / black)
byte 1: palette index 1 (orange chroma)
byte 2: palette index 2 (blue/cyan chroma)
byte 3: palette index 3 (white / foreground)
```

**Verified palette (Brøderbund splash descriptor 0, MAME composite, P2.3a):**

| Index | GIME value | Composite (intensity, hue) | Color |
|-------|------------|----------------------------|-------|
| 0 | $00 | intensity 0 | black |
| 1 | $26 | intensity 2, hue 6 | orange |
| 2 | $1B | intensity 1, hue 11 | blue/cyan |
| 3 | $3F | intensity 3, hue 15 | white |

Written to GIME registers $FFB0-$FFB3 by `HAL_gfx_init` (descriptor 0).
Verified via `tests/scripted/palette_test_driver.bin` + MAME observation
(P2.3a.6-followup-2, P2.3a.7).

**Note on color encoding:** MAME emulates CoCo3 in composite monitor mode.
RGB monitor interpretation (bits 5:0 = R1 G1 B1 R0 G0 B0) is NOT used.
`[ref: docs/SockmasterGime.md lines 218-242 — composite vs RGB mode]`

**Note on 2bpp pixel values:** 2bpp pixel index 0 = transparent (black
background), index 1 = orange (chroma fringing), index 2 = blue/cyan
(chroma fringing), index 3 = white (primary content color). The orange and
blue/cyan fringing at sprite edges is intentional NTSC artifacting from the
chroma model in `tools/sprite_convert.py`.

`[ref: src/hal/coco3-dsk/gfx.s HAL_gfx_init — palette register programming]`
`[ref: docs/conventions.md §21 — transparency: index 0 = transparent key color]`

### 4.3 Sound data formats

**PCM samples:** 256 bytes, 6-bit DAC values (0-63).
Produced by `tools/sound_convert.py --section pcm`.
Consumed by `HAL_sound_dac_sample` on a per-sample basis.

**Tone records:** 256 bytes, pass-through from Apple II format.
Produced by `tools/sound_convert.py --section tone`.
Consumed by `HAL_sound_tone_start`. Format matches
`karateka_dissasembly_claude/src/sound_engine.s` record layout:
byte 0 = outer-loop count, byte 1 = speaker-page (repurposed for
CoCo3 DAC register), bytes 2+ = (duration, frequency) pairs,
$FF sentinel.

---

## 5. Subsystem Reference

### 5.1 Graphics

Target: GIME 320×192 4-color mode, double-buffered.

Karateka has no hardware sprites — all rendering is software blit
to the GIME frame buffer. The HAL owns two frame buffers; the engine
always renders to the back buffer.

Per-frame sequence (per D.3 pattern):
1. `HAL_gfx_clear` — clear back buffer
2. Render all sprites via `HAL_gfx_blit_sprite`
3. `HAL_gfx_present` — swap buffers
4. `HAL_time_vbl_wait` — sync to display

#### HAL_gfx_init

Initialize GIME for 320×192×4 mode with double buffering.

| | |
|---|---|
| Args | A = palette index (0 = default global palette) |
| Returns | CC.C clear on success |
| Errors | ERR_NOMEM if frame buffers cannot be allocated |
| Preserves | U, Y |
| Clobbers | A, B, X, CC |
| Init order | 3 |

`[no-ref: GIME 320×192×4 mode setup (CRES/HRES bit values) —
resolve during P2 from GIME-RM; confirm with CC3-TR §graphics]`

#### HAL_gfx_shutdown

Restore screen mode (e.g. for error display before panic).

| | |
|---|---|
| Args | none |
| Returns | nothing |
| Errors | none |
| Preserves | U, Y |
| Clobbers | A, B, X, CC |

#### HAL_gfx_clear

Fill active back buffer with palette index 0 (background). Never
writes to front (visible) buffer.

| | |
|---|---|
| Args | none |
| Returns | CC.C clear |
| Errors | none |
| Preserves | U |
| Clobbers | A, B, X, Y, CC |

`[no-ref: frame buffer address / size — depends on GIME MMU slot
assignments: [ref: memory-map §3.2] FFA4=$3C/$3D (Frame A), FFA6=$3E/$3F (Frame B)]`

#### HAL_gfx_blit_sprite (revised P2.4)

Render a CoCo3 packed sprite into the back buffer at a sub-byte-precise
position with transparency-aware semantics.

| | |
|---|---|
| Args | X = sprite pointer (§4.1 format); A = byte_col (0-79); B = pixel_row (0-191); ZP $0C = subbyte (0-3) **caller must set** |
| Returns | CC.C clear on success |
| Errors | ERR_INVALID if sprite extends beyond frame buffer |
| Preserves | U |
| Clobbers | A, B, X, Y, CC, ZP $0D/$0E/$0F |

**Sub-byte rendering:** `ZP $0C (blit_subbyte)` must be set by the caller
before each call. Shift amount = 2 × subbyte bits. Effective output width =
sprite_width + 1 bytes when subbyte > 0 (overflow byte extends rightward).
See `docs/conventions.md §20`.

**Transparency semantics:** source index 0 (black, 2bpp = 00) preserves
destination; non-zero source replaces destination. Applied to all 5 blit
cases (sb0/sb1/sb2/sb3 + overflow byte). See `docs/conventions.md §21`.

**Cycle cost per source byte:**
- subbyte=0: ~43 cy
- subbyte=1: ~83 cy
- subbyte=2: ~94 cy
- subbyte=3: ~102 cy

**Bounds check:** `col + width <= 78` when subbyte > 0 (overflow byte must
fit). Current implementation does not check overflow byte bounds.

Column unit: byte (4 pixels). 80 bytes per row (320px / 4px per byte).
GIME has no sprite hardware; all rendering is software blit.

`[ref: docs/conventions.md §20 — sub-byte position convention]`
`[ref: docs/conventions.md §21 — transparency semantics]`
`[ref: src/hal/coco3-dsk/gfx.s HAL_gfx_blit_sprite — P2.4.1 implementation]`
`[ref: p2-4-1-verdict-v1 — sub-byte shifter CONFIRMED]`
`[ref: p2-4-1-followup-1-verdict-v1 — transparency CONFIRMED]`

#### HAL_gfx_set_palette

Write 4-entry palette to GIME palette registers.

| | |
|---|---|
| Args | X = pointer to 4-byte palette array (see §4.2) |
| Returns | CC.C clear |
| Errors | none |
| Preserves | X, U, Y |
| Clobbers | A, B, CC |
| Timing | Should be called during VBL to avoid scanline artifact |

`[no-ref: GIME palette register addresses — expected ~$FFB0-$FFBF
per Sockmaster-GIME; verify exact range from GIME-RM §3.x in P2.
Empirical note (Sockmaster-GIME): writes during active scanline
cause visible artifact; schedule during VBL.]`

#### HAL_gfx_present

Swap front/back frame buffers.

| | |
|---|---|
| Args | none |
| Returns | CC.C clear |
| Errors | none |
| Preserves | U, Y |
| Clobbers | A, B, X, CC |
| Timing | Call after render complete |

`[no-ref: GIME buffer-base register for page flip — resolve from
GIME-RM during P2]`

---

### 5.2 Time

VBL-synchronized frame timing. `HAL_time_vbl_wait` is the CoCo3
equivalent of karateka's `vbl_sync` at `$779A` in
`karateka_dissasembly_claude/src/display_7700.s` — the hottest
routine in the Apple II project (327,189 trace fires).

#### HAL_time_init

Configure VBL source and start frame counter.

| | |
|---|---|
| Args | none |
| Returns | CC.C clear on success |
| Errors | ERR_DEVICE if VBL source unavailable |
| Preserves | U, Y |
| Clobbers | A, B, X, CC |
| Init order | 2 |

`[no-ref: VBL detection mechanism (poll $FF03 vs interrupt vs
GIME vsync bit) — resolve during P2 from CC3-TR interrupt section
and GIME-RM vsync documentation]`

#### HAL_time_vbl_wait

Block until next vertical blanking interval. Increments internal
frame counter on each call.

| | |
|---|---|
| Args | none |
| Returns | CC.C clear |
| Errors | none (blocking) |
| Preserves | U, Y, X |
| Clobbers | A, B, CC |

#### HAL_time_frame_count

Return current 16-bit frame counter. Counter wraps at $FFFF→$0000
and is incremented by `HAL_time_vbl_wait`.

| | |
|---|---|
| Args | none |
| Returns | D = frame count |
| Errors | none |
| Preserves | U, Y, X, CC |
| Clobbers | D |

#### HAL_time_delay

Busy-wait for N frames.

| | |
|---|---|
| Args | A = frame count |
| Returns | CC.C clear |
| Errors | none |
| Preserves | U, Y, X |
| Clobbers | A, B, CC |

---

### 5.3 Sound

Replaces `karateka_dissasembly_claude` sound subsystem:
- `sound_engine.s` ($0D00): tone-record interpreter → `HAL_sound_tone_start`
- `sound.s` pcm_player ($0DC0): 1-bit delta-PCM → `HAL_sound_dac_sample`

`[no-ref: CoCo3 DAC register address — resolve during P2 from
CC3-TR sound/DAC section]`

#### HAL_sound_init

| | |
|---|---|
| Args | none |
| Returns | CC.C clear on success |
| Errors | ERR_DEVICE if DAC not available |
| Init order | 5 |

#### HAL_sound_shutdown

Silence output and release sound resources.

| | |
|---|---|
| Args | none |
| Returns | nothing |
| Errors | none |

#### HAL_sound_dac_sample

Output one 6-bit DAC sample directly. Low-level; for per-frame PCM
playback loops. Engine typically uses `HAL_sound_play_event` for
higher-level dispatch.

| | |
|---|---|
| Args | A = 6-bit value (0-63) |
| Returns | CC.C clear |
| Errors | none |
| Preserves | U, Y, X, B |
| Clobbers | A, CC |

#### HAL_sound_tone_start

Begin playing a tone-record sequence. HAL maintains playback state
between frames.

| | |
|---|---|
| Args | X = pointer to tone-record sequence (P1.2 format) |
| Returns | CC.C clear |
| Errors | none |

#### HAL_sound_tone_stop

Silence any active tone.

| | |
|---|---|
| Args | none |
| Returns | CC.C clear |
| Errors | none |

#### HAL_sound_play_event

High-level sound event dispatch. Engine passes event ID; HAL maps
to specific tone-record or PCM playback.

| | |
|---|---|
| Args | A = sound event ID |
| Returns | CC.C clear on success |
| Errors | ERR_INVALID if event ID unknown |

**P2 stability note:** This function may be removed in P2 if engine-
side sound dispatch makes the HAL event-routing layer redundant.
Karateka's sound system (tone records + PCM) is simpler than POP's;
the engine may drive `HAL_sound_tone_start` and
`HAL_sound_dac_sample` directly without an event-ID indirection.
Sound event ID enumeration deferred to P2 for this reason.

---

### 5.4 Memory

Skeleton. Detailed design during P2 when memory probing and engine
memory requirements are understood.

**HAL_mem_size_detect** — probe installed RAM at boot.
Returns A = 0 (128K) or A = 1 (512K). Init order: 1 (first).
See D.5 pattern in `6502-6809-conversion-patterns/shared/D-hal/`.

---

### 5.5 Input

Skeleton. Detailed design during P2 when gameplay input subsystem
is ported. Apple II equivalent: `input.s` at `$7603-$774A` in
`karateka_dissasembly_claude`.

**HAL_input_init** — initialize input. Init order: 4.

**HAL_input_poll** — sample keyboard and joystick; return packed
state in D (A = action bits, B = directional bits; specific bit
assignments TBD during P2).

---

### 5.6 File

Skeleton. Detailed design during P2 when disk loading timing is
understood. Apple II equivalent: `disk_loader.s` ($0300) in
`karateka_dissasembly_claude`.

**HAL_file_init** — initialize disk subsystem. Init order: 6 (last).

**HAL_file_load** — load entire named file to memory address.
Args: X = filename ptr, U = destination, D = byte count (0 = all).
Returns D = bytes loaded.

Karateka's load model is simpler than POP's (no streaming, no
seek needed). Single open/load/close per asset.

---

### 5.7 System

Skeleton. Detailed design during P2.

**HAL_sys_cpu** — return 0 (6809) or 1 (6309). Cached from boot.

**HAL_sys_target** — return 0 (coco3-dsk). v1.0 has one target.

**HAL_sys_panic** — display message, halt. Args: X = message ptr
(or 0). Does not return.

---

### 5.8 Debug/Trace

Added in P1.3 follow-up. Three functions split by always-on vs
DEV_MODE:

| Function | Present in | Purpose |
|----------|-----------|---------|
| `HAL_debug_trace_event` | All builds | Harness instrumentation |
| `HAL_debug_log` | DEV_MODE only | Free-form debug string output |
| `HAL_debug_assert` | DEV_MODE only | Precondition verification |

**Why HAL_debug_trace_event is always-on:** The MAME scripted-test
harness reads the trace ring buffer to verify engine behavior.
Compiling it out of production builds would prevent harness
coverage on release binaries. Pop-coco3 made the same choice.

**Trace buffer:** a fixed-size ring buffer at a known memory
address assigned in P1.6 memory map: CPU `$7800`, 256 bytes.
`[ref: memory-map §4.7]` trace ring buffer location and format.

**Engine event code enumeration:** the HAL accepts event codes
as opaque bytes (0-255). The engine defines its own event ID
enum in `src/engine/trace_events.inc`. This file materializes
during P2 when the first trace instrumentation points are added.
It is not part of the HAL contract.

#### HAL_debug_trace_event

Record an instrumentation event in the trace ring buffer.
MAME harness reads the buffer to verify expected event sequences.

| | |
|---|---|
| Args | A = event code (0-255, engine-defined opaque); X = data ptr (or 0) |
| Returns | nothing (always succeeds) |
| Errors | none |
| Preserves | U, Y, X, B |
| Clobbers | A, CC |
| Always-on | Yes — present in all builds |

`[no-ref: trace mechanism is engine-internal; no hardware reference]`

#### HAL_debug_log

Emit a null-terminated debug string to implementation-defined
destination (MAME debug console, serial output, memory ring
buffer, etc.). **DEV_MODE only** — wrap in `ifdef DEV_MODE`.

| | |
|---|---|
| Args | X = pointer to null-terminated string |
| Returns | nothing (always succeeds) |
| Errors | none |
| Preserves | U, Y, X |
| Clobbers | A, B, CC |

`[no-ref: debug output destination is implementation choice]`

#### HAL_debug_assert

Verify a precondition. If condition is false, emits a trace
event then calls `HAL_sys_panic` with the message. **DEV_MODE
only** — use via `DEV_MODE_ASSERT` macro which assembles to
nothing in production.

| | |
|---|---|
| Args | A = condition (0 = fail, non-zero = pass); X = message ptr |
| Returns | nothing on pass |
| Errors | does not return on failure — calls HAL_sys_panic |
| Preserves | U, Y (on pass) |
| Clobbers | A, B, CC |

**Within-HAL call note:** `HAL_debug_assert` calls `HAL_sys_panic`
on failure. This is the one permitted within-HAL call in the
contract. HAL functions are otherwise main-context-only and not
safe to call from other HAL functions. The assert→panic path is
explicitly permitted because: (a) assertion failure is fatal by
definition, (b) `HAL_sys_panic` is documented to never return,
so re-entrancy is not a concern.

`[no-ref: assertion mechanism is engine-internal]`

---

## 6. Reference Citations

### Documented decisions

None yet (P1.3 is a contract skeleton; implementation citations
land during P2 when HAL bodies are written).

### Decisions without reference ([no-ref:] items)

The following decisions were made without a covering reference
during P1.3. Each will be resolved during P2 by reading the
indicated document before writing implementation code.

| Decision | [no-ref: tag] | Resolve from |
|----------|---------------|-------------|
| GIME 320×192×4 mode setup | GIME 320×192×4 mode setup — CRES/HRES bit values | GIME-RM |
| GIME palette register addresses | GIME palette register addresses | GIME-RM §3.x |
| VBL detection mechanism | VBL detection mechanism | CC3-TR, GIME-RM |
| Frame buffer MMU slot assignments | Frame buffer address / size | [ref: memory-map §4.8-4.9, GIME-RM §13] |
| DAC register address | CoCo3 DAC register address | CC3-TR |
| CoCo3 keyboard matrix registers | CoCo3 keyboard matrix registers | CC3-TR |
| CoCo3 system DP usage at $80-$FF | CoCo3 system DP usage at $80-$FF | CC3-TR |
| GIME color 6-bit encoding | GIME color encoding | GIME-RM §3.x |
| Trace mechanism (HAL_debug_trace_event) | trace mechanism is engine-internal | N/A (engine-internal) |
| Debug output destination (HAL_debug_log) | debug output destination is implementation choice | N/A (implementation choice) |
| Assertion mechanism (HAL_debug_assert) | assertion mechanism is engine-internal | N/A (engine-internal) |
| Trace buffer memory address | — resolved: [ref: memory-map §4.7] CPU $7800, 256 B | — |

### Reference conflicts

None surfaced during P1.3. (Expected location for conflicts: GIME
palette timing — CC3-TR likely says unrestricted, Sockmaster-GIME
empirical note says avoid active scanline. Will document formally
when GIME-RM is read during P2.)

---

## 7. Init Order Summary

```
1. HAL_mem_size_detect   memory probe first
2. HAL_time_init         timing before other init
3. HAL_gfx_init          screen early for error display
4. HAL_input_init
5. HAL_sound_init
6. HAL_file_init         disk last
-  Debug/Trace: no init — HAL_debug_trace_event available
   immediately at boot (ring buffer in static memory)
```

---

## 8. Pop-coco3 Inheritance and Divergences

Shape inherited from **pop-coco3-design v0.7 Section 6.11**.

**Inherited unchanged:**
- Calling convention (args, returns, CC.C error, U/DP preserved)
- Error code set and numbering
- Init order (mem → time → gfx → input → sound → file)
- Subsystem names (Graphics, Time, Sound, Memory, Input, File, System)
- Data format conventions (palette descriptor, error reporting)

**Karateka-specific divergences:**

| POP-coco3 | karateka-coco3 | Reason |
|-----------|----------------|--------|
| Shape descriptor / shape ID system | Sprite pointer passed directly | Karateka has simpler sprite model; no shape table needed |
| `hal_gfx_draw_text` | Not in contract | Karateka text uses sprite glyphs from sprite_data_0400.s |
| `hal_mem_alloc`, `hal_mem_free`, `hal_mem_query` | Not in contract; only `HAL_mem_size_detect` | Simpler memory model; no dynamic allocation needed |
| `hal_sound_play` + `hal_sound_update` | `HAL_sound_tone_start/stop` + `HAL_sound_dac_sample` | Karateka sound is tone-record + PCM, not event-only |
| `hal_file_open/read/seek/close` | Single `HAL_file_load` | Karateka loads files whole; no streaming |
| Lowercase `hal_subsystem_verb` naming | `HAL_subsystem_verb` (uppercase prefix) | Project convention |

**Function counts:** 27 (POP) → 21 (karateka).

---

## 9. Compatibility

**Target:** `coco3-dsk` only for v1.0 (Gate K.1.2). Future targets
would require contract extension or revision.

**CPU:** 6809 and 6309 (Gate K.1.3). `HAL_sys_cpu` returns detected
type. CPU-specific optimizations live in `src/opt/6809/` and
`src/opt/6309/`, not in the contract itself.
