# karateka-coco3 HAL Contract

Version: 0.1 (P1.3 deliverable, 2026-05-13)

## 1. Overview

The Hardware Abstraction Layer (HAL) is the boundary between
platform-neutral engine code and platform-specific implementation.
Engine code calls HAL functions by name; HAL implementations handle
actual hardware. This separation allows a single engine codebase to
run on multiple targets (Gate K.1.2: coco3-dsk for v1.0).

This document is the human-readable companion to `src/hal.inc`,
which contains the assembly-syntactic contract.

**Scope:**
- Three subsystems are detailed: Graphics, Time, Sound
- Four subsystems are skeletoned: Memory, Input, File, System
  (detailed in P2 when consuming engine subsystem is ported)

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

4 bytes, one per palette entry, each a 6-bit GIME color code (0-63):

```
byte 0: palette index 0 (background)
byte 1: palette index 1 (foreground)
byte 2: reserved
byte 3: reserved
```

v1.0 global palette: `[0, 63, 21, 42]` (black, white, mid-gray ×2).
Produced by `tools/palette_derive.py`. Stored in
`content/palettes/global.bin`.

`[no-ref: GIME color encoding (6-bit value → actual RGB) — verify
in GIME-RM §3.x during P2]`

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
assignments, resolved during P1.6 memory map work]`

#### HAL_gfx_blit_sprite

Render a CoCo3 packed sprite into the back buffer at a given
column and row position.

| | |
|---|---|
| Args | X = sprite pointer (P1.2 format); A = byte column (0-79); B = pixel row (0-191) |
| Returns | CC.C clear on success |
| Errors | ERR_INVALID if sprite extends beyond frame buffer |
| Preserves | U |
| Clobbers | A, B, X, Y, CC |

Column unit: byte (4 pixels). At 320px wide, 80 bytes per row.
The blit algorithm is engine-internal; GIME has no sprite hardware.

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
| Frame buffer MMU slot assignments | Frame buffer address / size | GIME-RM, P1.6 |
| DAC register address | CoCo3 DAC register address | CC3-TR |
| CoCo3 keyboard matrix registers | CoCo3 keyboard matrix registers | CC3-TR |
| CoCo3 system DP usage at $80-$FF | CoCo3 system DP usage at $80-$FF | CC3-TR |
| GIME color 6-bit encoding | GIME color encoding | GIME-RM §3.x |

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
