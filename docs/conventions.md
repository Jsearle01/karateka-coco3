# karateka-coco3 — Engine Conventions

Version: 0.1 (P1.4 deliverable, 2026-05-13)

## 1. Overview

Rules engine code follows for consistent style, predictable behavior,
and clean separation from the HAL.

**Scope:** applies to `src/engine/*.s` and engine-side data files.
HAL implementation conventions live in `docs/hal.md`. Toolchain
conventions (lwasm syntax differences from ca65) noted in §13.

**Shape inherited from pop-coco3-design v0.7 Section 6.12.** Nine
subsections inherited (§§6.12.3, .5, .6, .8, .9, .10, .11, .12,
.16). Karateka-specific divergences documented inline.

**Pop-coco3 subsections NOT inherited:**
- §6.12.1–.2 (conventions purpose and what-needs-conventions):
  absorbed into this overview; not separately enumerated
- §6.12.4 (POP-specific DP bands `$00-$3F`): replaced by karateka
  DP layout (§2 below); karateka's P1.3 HAL contract establishes a
  different split (`$00-$1F` HAL, `$20-$7F` engine)
- §6.12.7 (POP memory layout patterns: streaming, shape-cache,
  level data): not applicable to karateka's simpler load model
- §6.12.13–.15 (linter design, deliverable, integration): linter
  deferred to P2; see §14

**Design qualities these conventions aim for:** consistency-producing,
memorable, enforceable, stable, minimal. A convention that doesn't
solve a real problem adds cognitive load without value.

---

## 2. Direct Page (DP) Allocation

HAL contract (P1.3) establishes the top-level split:

```
$00-$1F  HAL scratch (reserved; see src/hal.inc)
$20-$7F  Engine region (this document governs)
$80-$FF  CoCo3 system reserved — do not touch
```

Engine region sub-divided into functional bands:

```
$20-$2F  Engine globals — active combat state
           Preserves karateka_dissasembly_claude ZP cluster $20-$2F
           (observed: active combat, action code $20, animation
           frame $26 — per design doc §6.4 and Apple II source)
$30-$5F  Engine working state — see note below
$60-$6F  Combatant A state cluster
           Preserves karateka_dissasembly_claude ZP cluster $60-$6F
           (observed from Apple II source)
$70-$7F  Combatant B state cluster
           Preserves karateka_dissasembly_claude ZP cluster $70-$7F
           (observed from Apple II source)
```

**Note on `$30-$5F`:** The `$20-$2F`, `$60-$6F`, and `$70-$7F`
clusters are observed from `karateka_dissasembly_claude` Apple II
source. The `$30-$5F` region has no documented ZP usage in the
Apple II source and is therefore a design allocation. The following
sub-division is **predicted** from expected engine subsystem
complexity and is subject to revision during P2 if observation or
porting pressure surfaces different requirements:

```
$30-$3F  Engine scratch — routine-local temporaries
           No persistence guarantee across routine boundaries.
           Routines document their usage in their header comment.
$40-$4F  Subsystem-specific working state
           (sound trigger, collision, animation working state)
$50-$5F  Frame-coherent variables
           Set at frame start; used throughout the frame.
           Examples: frame_counter, input_state snapshot
```

The authoritative current assignments live in `src/engine/globals.s`
(created during P2 as the engine takes shape).

`[no-ref: CoCo3 system DP usage at $80-$FF — verify from CC3-TR
during P2 before any code touches $80+]`

---

## 3. Calling Conventions

Engine-to-engine calls use the same conventions as HAL calls, giving
one mental model across all routine calls.

```
Arguments:  A, B, D (scalar), X (pointer in), Y (secondary)
Returns:    D (scalar), X (pointer out), CC.C (error flag)
On error:   CC.C set, A = error code
On success: CC.C clear
Preserved:  U (engine frame pointer), DP (direct page)
Scratch:    A, B, X, Y, CC bits except .C
```

Routines may document additional preservation guarantees in their
headers (e.g., "this routine also preserves Y") — local extensions,
not deviations from the base convention.

The 6309 registers (E, F, W, Q, MD, V) never appear in routine
interfaces. They may appear in optimization-layer implementations
(`src/opt/6309/`) but are invisible at the engine calling surface
(Gate K.1.5 / Anti-pattern F.1).

---

## 4. Stack Discipline

Stack budget: **256 bytes total**. Engine routines use no more than
**32 bytes per call** including nested calls. Deep recursion is
forbidden — karateka's logic does not require it.

Stack frame pattern (for routines needing more than DP provides):

```asm
complex_routine:
        pshs    u,x,y,a,b,cc    ; preserve caller state
        leas    -FRAME_SIZE,s   ; allocate frame
        leau    0,s             ; U = frame pointer
        ; body uses 0,u / 1,u / ... for frame-local variables
        leas    FRAME_SIZE,s    ; deallocate frame
        puls    cc,b,a,y,x,u,pc ; restore and return
```

Stack frames are for complex routines only. Simple routines use
registers and DP directly.

`[ref: MC6809 §4.5]` PSHS/PULS instruction semantics and cycle
counts.

---

## 5. Error Handling

Engine routines follow the same error reporting convention as HAL:
CC.C set on error, A = error code.

**Engine error codes** (offset above HAL to avoid collision):

```asm
; HAL error codes occupy 0-8 (ERR_OK through ERR_INTERNAL).
; HAL extensions reserved 9-63.
; Engine errors start at 64.
ENGINE_ERR_INVALID_SCENE    equ 64
ENGINE_ERR_INVALID_SPRITE   equ 65
ENGINE_ERR_INVALID_STATE    equ 66
ENGINE_ERR_ANIM_OOR         equ 67  ; animation index out of range
ENGINE_ERR_STATE_CORRUPTED  equ 68
; 69-127 reserved for engine additions during P2
; 128-255 reserved for future use
```

Error propagation: propagate via CC.C and A unchanged. Routines
that handle an error locally clear CC.C and proceed; routines that
can't handle it leave CC.C set.

```asm
        jsr     HAL_file_load
        bcs     load_failed         ; HAL set CC.C, A = error code
        ; ... work ...
load_failed:
        ; CC.C set, A = ERR_IO (or similar) — propagate to caller
        rts
```

**Fatal errors** call `HAL_sys_panic` directly. No recovery, no
propagation. Used for: state machine in impossible state, data
structure invariants violated, unrecoverable corruption.

**Recoverable errors** return via CC.C and A. Caller decides.

---

## 6. Naming Conventions

**Routine names:** `snake_case`. Descriptive of what the routine
does, not how.

```asm
scene_dispatch          ; good
L7C43                   ; acceptable during early porting; replace before P3
do_the_scene_thing_v2   ; bad
```

**Constant names:** `UPPER_SNAKE_CASE`, grouped by prefix:

```asm
SCENE_INTRO             equ 0
SCENE_FIGHT             equ 1
ANIM_RUN_FRAME_COUNT    equ 16
SOUND_KICK              equ 1
SOUND_IMPACT            equ 2
```

**Local labels within routines:** lowercase, descriptive, standard
suffixes `_loop`, `_done`, `_skip`, `_error`. lwasm `@` prefix for
local labels within long routines is permitted but discouraged for
short routines.

**Engine globals** (DP and RAM): short names for DP (used in inner
loops); longer descriptive names for main RAM globals.

```asm
; DP (short — inner loop access)
scene_id
player_x
player_y
anim_frame

; Main RAM (longer — less frequent access)
fight_state_machine
sprite_table_ptr
```

---

## 7. Comment Conventions

### File header

```asm
* ============================================================
* Module: scene_dispatch.s
* Purpose: Scene state machine and dispatch table.
*
* Drives karateka's scene transitions (intro → fight → ending).
* Maps scene_id to per-scene update and render routines.
*
* Ported from: karateka_dissasembly_claude src/kernel_dispatch.s
*              (scene dispatch pattern per Apple II source)
*
* Dependencies:
*   src/hal.inc        (HAL contract)
*   src/engine/globals.s  (DP allocation)
* ============================================================
```

### Routine header

Every ported routine includes an ORIGIN field referencing its Apple
II source (see §12.1 for rationale):

```asm
* ------------------------------------------------------------
* scene_dispatch
*
* Route to the current scene's per-frame update routine.
*
* ORIGIN: karateka_dissasembly_claude src/kernel_dispatch.s
*         Apple II $7C43 (per_frame_dispatch)
*
* Input:
*   scene_id (DP) — current scene identifier
* Output:
*   (none) — calls scene-specific handler which updates state
* Clobbers: A, B, X, Y, CC
* Preserves: U, DP
* ------------------------------------------------------------
```

Required fields: purpose, ORIGIN (if ported from Apple II),
inputs, outputs, clobbers/preserves. Unknowns explicit (`TBD`),
never silently omitted.

### Inline comments

Only where intent isn't obvious from reading the code. Don't repeat
what the code says; explain why.

```asm
; Bad:
        lda     scene_id        ; load scene_id

; Good:
        lda     scene_id        ; gate: intro stays until vbl_count > 180
        cmpa    #SCENE_INTRO
        beq     intro_hold
```

---

## 8. File Organization

File-per-subsystem pattern. Engine files in `src/engine/`:

```
src/engine/
├── globals.s       global variable declarations (DP + RAM)
├── boot.s          boot and initialization sequence
├── scene.s         scene state machine and dispatch
├── fight.s         fight-round logic and state
├── anim.s          animation table indexing
├── sprite.s        sprite composition (body-part assembly)
├── input.s         input state processing
├── sound.s         sound event routing
├── text.s          text rendering via glyph sprites
└── tables.s        static lookup tables
```

**File size guideline:** 500–1500 lines. Files >2000 lines should be
split. Files <100 lines should be merged with related files. Guidance,
not a hard rule.

CPU-specific optimizations in `src/opt/6809/` and `src/opt/6309/`.
Engine code never directly references opt/ files; build-time
selection routes calls.

---

## 9. DEV_MODE Conventions

Conditional compilation via lwasm `ifdef`/`endif`:

```asm
        ifdef   DEV_MODE
        ; Debug-only code — indented one extra level to distinguish
        ; from production code paths
        ldx     #msg_entering_scene
        jsr     hal_debug_log_string    ; (P1.3 follow-up: see below)
        endif
```

DEV_MODE blocks are indented one level beyond surrounding code.

Per E-devmode patterns:

- **E.1 Assertions:** `DEV_MODE_ASSERT` at routine entry for
  precondition checks (macro assembles to nothing in production)
- **E.2 Trace events:** emit at significant state transitions; not
  in inner loops. Used by MAME harness for scripted-test verification
- **E.3 Logging:** string/byte/hex logging during development
- **E.4 Shortcuts:** skip cinematics in dev builds

**P1.3 follow-up — debug/trace HAL subsystem:**
`src/hal.inc` (P1.3) does not include a debug/trace subsystem.
Pop-coco3 includes `hal_debug_trace_event` as an always-on function
for harness instrumentation. Karateka-coco3 should add an equivalent
debug subsystem to `hal.inc` before P2 scripted-test harness work
begins. This is a P1.3 contract revision deferred to avoid blocking
P1.4; it should be filed as a P1.3 follow-up task before P2.

---

## 10. Source Formatting

**Indentation:** tabs, displayed as 8 columns.

```
Column 0:   labels
Column 8:   mnemonics
Column 14:  operands
Column 32+: comments
```

Example:

```asm
scene_dispatch:
        lda     scene_id        ; current scene ID
        lsla                    ; × 2 for word-table index
        ldx     #scene_table
        ldd     a,x             ; D = handler address
        jmp     [,x++]          ; dispatch
```

**Blank lines:** one between routines; two between logical groups
within a file. No blank line between label and first instruction.
No trailing whitespace.

**Line length:** soft limit 100 columns; hard limit 120.

---

## 11. Endianness

The engine is **6809-native big-endian throughout**.

1. Use 16-bit instructions (`ldd`, `std`, `ldx`, `stx`, `ldu`,
   `stu`) for 16-bit values. Sequential 8-bit ops on conceptually
   16-bit values are a code smell flagged for review.

2. Static data tables use `fdb` (lwasm big-endian word directive)
   for 16-bit values. Never manually construct 16-bit values as
   6502-style little-endian `fcb` byte pairs.

3. Asset byte-order conversion is the conversion tool's
   responsibility (`tools/sprite_convert.py`, `tools/sound_convert.py`).
   The engine reads converted assets natively.

4. Engine code never reads raw Apple II source-format data directly.

See patterns B.9 (endianness translation) and B.10 (static data
tables) in `6502-6809-conversion-patterns/shared/B-idioms/`.

---

## 12. Karateka Architectural Patterns to Preserve

### 12.1 Multi-dump tagging (ORIGIN convention)

Every routine ported from `karateka_dissasembly_claude` carries an
ORIGIN field in its header referencing the Apple II source file and
address range. This creates an audit trail from CoCo3 port back to
Apple II oracle.

```asm
* ORIGIN: karateka_dissasembly_claude src/display_7700.s
*         Apple II $774B (blit_hires_page)
```

Rationale: when a porting bug surfaces, the ORIGIN tag identifies
the exact Apple II source to re-examine. Without it, debugging
requires re-searching the oracle.

Pattern source: `karateka_dissasembly_claude/docs/instructions.md`
§4 (Tagging conventions).

### 12.2 Scene-driven dispatch

Karateka uses two dispatch styles from the Apple II source:

**Linear flow** (intro sequence): sequential routine calls, no
dispatch table. Used for fixed-order cinematics.

**State-machine dispatch** (fight scene): jump table indexed by
scene ID or state variable. Translate using 6809 pattern:

```asm
        lda     scene_id
        lsla                    ; word index
        ldx     #scene_table    ; base of handler table
        ldd     a,x
        jmp     [,x++]
```

Pattern: B.4 (lookup-dispatch) in `6502-6809-conversion-patterns/
shared/B-idioms/`.

### 12.3 Sprite composition (body-part assembly)

Karateka's animation uses body-part composition: the 16-frame run
cycle is 8 leg sprites + 8 torso sprites (`$9B00-$9EB7`); the Akuma
throne-room pose is composed from multiple independently-positioned
sprites.

Convention: **composition logic lives in the engine** (`src/engine/
sprite.s`); **byte-level rendering calls `HAL_gfx_blit_sprite`**.
The engine assembles the list of (sprite_ptr, col, row) tuples for
a given pose; HAL renders each tuple.

This keeps hardware details out of animation logic and makes the
composition testable without a display.

---

## 13. Toolchain Conventions (lwasm vs ca65)

karateka-coco3 uses `lwasm`; `karateka_dissasembly_claude` uses
`ca65`. Ported code requires translation of assembler directives:

| ca65 (Apple II) | lwasm (CoCo3) | Notes |
|-----------------|---------------|-------|
| `.byte` | `fcb` | byte data |
| `.word` | `fdb` | 16-bit word, big-endian |
| `.org` | `org` | location counter |
| `.segment "X"` | `section X` or `org` | segment/section model differs |
| `.include "f"` | `include "f"` | |
| `;` comment | `*` or `;` | both work in lwasm |
| `.ifdef` / `.endif` | `ifdef` / `endif` | no leading dot |
| label `= value` | `label equ value` | equate syntax |

`[no-ref: lwasm conditional assembly and macro syntax — lwasm
documentation not present in docs/; verify exact directive syntax
from lwasm manual during P2 before writing engine code]`

`[ref: MC6809 §4]` for instruction mnemonics (lwasm follows standard
6809 assembler conventions for mnemonics).

---

## 14. Linter

Deferred to P2. No engine code exists yet to lint against.
Conventions in this document define the future linter's rules.

Pop-coco3 linter (Section 6.12.13 / P1.4.2) is the implementation
model. When authoring karateka-coco3's linter in P2, consult that
design for: rule selection, Python implementation pattern, harness
integration, and false-positive discipline.

Linter target rules (from §§3–13 above):
- Routine clobbering U or DP without restoring
- Missing file or routine header
- Missing ORIGIN field in ported routines
- Naming convention violations (snake_case / UPPER_CASE)
- Direct page usage outside allocated bands (per §2)
- DEV_MODE block indentation violations
- Endianness violations (sequential 8-bit ops on 16-bit values)
- Tab/space inconsistencies; trailing whitespace
- Operand/comment column violations

---

## 15. Reference Citations

### Documented decisions

- `[ref: MC6809 §4.5]` — PSHS/PULS cycle counts and stack semantics
  (§4 stack discipline)
- `[ref: MC6809 §4]` — instruction mnemonics for lwasm (§13)

### Decisions without reference

- `[no-ref: CoCo3 system DP at $80-$FF]` — resolve from CC3-TR
  during P2 (carried from hal.inc P1.3)
- `[no-ref: lwasm conditional assembly and macro syntax]` — verify
  from lwasm manual during P2

---

## 16. Cross-References

- HAL contract: `src/hal.inc` and `docs/hal.md`
- Design doc §6.4: `docs/karateka-coco3-design-v0.1.md`
- 6502→6809 patterns: `../6502-6809-conversion-patterns/shared/`
- Methodology patterns: `../apple2-disasm-patterns/`
- Reference oracle: `../karateka_dissasembly_claude/`
- Pop-coco3 conventions (model): `docs/pop-coco3-design-v0_7.pdf`
  Section 6.12
