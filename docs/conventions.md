# karateka-coco3 — Engine Conventions

Version: 0.5 (P2.4, 2026-05-17 — added §§20-23 sub-byte rendering, transparency blit,
              visible-extent metadata, convention provenance; fixed §19 stale sub-byte note)
Version: 0.4 (P2.3a.11, 2026-05-17 — added §19 Apple II → CoCo3 Coordinate Mapping)
Version: 0.3 (P2.3a.10, 2026-05-17 — added §18 Text Glyph Conversion;
              canonical start_col=119 convention + address-based label note)
Version: 0.2 (P2.3a.0, 2026-05-16 — added dispatch block band, DP $13,
              interrupt mask policy §16; §16 was §16 Cross-References,
              renumbered to §17)
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

**HAL scratch band ($00-$1F) — current allocations:**

```
$00-$03  HAL_ZP_PARAM0-3    — byte parameter scratch (hal.inc)
$04-$05  HAL_ZP_PTR0        — pointer scratch 0, 2 bytes (hal.inc)
$06-$07  HAL_ZP_PTR1        — pointer scratch 1, 2 bytes (hal.inc)
$08-$0F  (reserved for HAL internal use — unallocated)
$10      hal_frame_hi       — frame counter high byte (time.s; P2.1)
$11      hal_frame_lo       — frame counter low byte  (time.s; P2.1)
$12      gfx_initialized    — $00=not init, $01=init done (gfx.s; P2.3a)
$13      sys_init_cc_mask   — CC after HAL_sys_init; $50 if I+F masked
                               (sys.s; P2.3a.0; test diagnostic only)
$14-$1F  (reserved for future HAL subsystem use — unallocated)
```

**Handler dispatch block — $0100-$0117:**

```
$0100-$0111  Interrupt handler dispatch block (18 bytes):
               Six 3-byte entries (RTI + NOP + NOP per slot).
               Address order per Sockmaster-GIME §1:
               $0100 swi3_handler, $0103 swi2_handler,
               $0106 swi_handler,  $0109 nmi_handler,
               $010C irq_handler,  $010F firq_handler
               [ref: docs/SockmasterGime.md §1 — $01xx routing table]
               [ref: docs/interrupt-handling.md §2 — dispatch design]
               [ref: src/hal/coco3-dsk/sys.s — implementation]
$0112-$0117  Reserved for dispatch block expansion (6 bytes spare)
```

This band is within the Stack region ($0100-$01FF, memory-map.md §2).
Stack grows downward from $01FF; with the 32-byte/call budget (§4 below)
the stack cannot normally reach $0100. The dispatch block occupies the
bottom 18 bytes as a safe sub-allocation.
`[ref: docs/memory-map.md §2 — stack region; dispatch block sub-allocation]`

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
$50-$5F  Frame-coherent variables — current allocations:
           $50  page_register     $20=frame A is draw target; $40=frame B is draw target
                                  [ref: src/engine/timer_framesync.s; P2.1]
           $51  page_source_blit  prior page_register value (the just-drawn page; P2.1)
           $52  frame_done        P2.2 kernel dispatch
           $53  frame_countdown   P2.2 kernel dispatch
           $54  frame_sync_dc     P2.2 kernel dispatch
           $55-$5F  (unallocated; reserved for engine frame-coherent use)
```

**CONVENTION NOTE — page_register and Option I caller flow:**
`page_register` at DP $50 holds the **CURRENT BACK BUFFER** token
(the active draw target). Caller flow (Option I, project-canonical):

1. Draw to the buffer identified by `page_register` (the back buffer).
2. Call `HAL_gfx_present` — displays the buffer `page_register` identifies
   (makes the just-drawn content visible).
3. Toggle `page_register` to designate the next draw target.

```
$20 = buffer A ($8000-range) is the draw target; HAL_gfx_present shows A.
$40 = buffer B ($C000-range) is the draw target; HAL_gfx_present shows B.
```

Note on token values: `PAGE_A_TOKEN` ($20) and `PAGE_B_TOKEN` ($40) are
Apple II heritage (high bytes of hires page addresses $2000/$4000). On CoCo3
these are opaque draw-target identifiers with no hardware significance.

Convention is **project-canonical**, established in P2.1
(`src/engine/timer_framesync.s`) and corrected to Option I in P2.3a.6-followup-1.
`HAL_gfx_present` does NOT modify `page_register`; caller toggles after present.

Future contributors: **read this note first** before interpreting code that
compares against `#$20` or `#$40`.

```
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
        jsr     HAL_debug_log           ; DEV_MODE only (src/hal.inc §Debug/Trace)
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

**Debug/Trace HAL subsystem (added P1.3 follow-up):**
`src/hal.inc` declares three debug/trace functions:
- `HAL_debug_trace_event` — always-on; MAME harness instrumentation
- `HAL_debug_log` — DEV_MODE only; free-form debug string output
- `HAL_debug_assert` — DEV_MODE only; precondition verification

`HAL_debug_trace_event` is NOT wrapped in `ifdef DEV_MODE` — it is
always present so the harness can run against release builds.
The other two are DEV_MODE only; wrap them as shown in the example.
See `docs/hal.md §5.8` for full specs.

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

## 16. Interrupt Mask Policy

### Current state (P2.3a.0 era)

All interrupt sources are masked throughout test execution. Three layers:

1. **Test driver global mask** — `orcc #$50` at driver entry point. Sets
   CC.I=1 (IRQ masked) and CC.F=1 (FIRQ masked) before any HAL call.
2. **HAL_sys_init internal mask** — `orcc #$50` inside `HAL_sys_init`.
   Belt-and-suspenders: masks before $FF90=$4C write that invalidates
   ROM interrupt handlers during the transition window.
3. **Dispatch block RTI stubs** — If an interrupt fires despite masking
   (e.g., NMI which cannot be masked), the $01xx dispatch block provides
   RTI stubs for a safe no-op return.
   `[ref: src/hal/coco3-dsk/sys.s — dispatch block]`

This layering is acceptable while no interrupt-driven behavior exists
(no VBL handler, no keyboard polling via interrupt, no disk interrupt).

### Why this is acceptable for P2.3a.0

- No GIME interrupt sources are enabled ($FF92/$FF93 IRQENR/FIRQENR = 0)
- Frame timing uses polling, not VBL interrupt (HAL_time_vbl_wait stub)
- Test drivers are short-lived; they don't need interrupt-driven I/O
- The mask prevents crashes during $FF90 transition (ROM handlers
  invalidated; GIME MMU not yet programmed)

### Migration trigger

Migration is required when the **first real interrupt handler** is installed.
Expected: P3.1, when VBL interrupt drives `HAL_time_vbl_wait`.

### Migration mechanics

1. **Write real IRQ handler** (`irq_handler` at $010C per
   `docs/interrupt-handling.md §5`). Handler must:
   - Acknowledge the interrupt source (read $FF03 or $FF92 as applicable)
   - Perform handler work (increment frame counter, set VBL flag)
   - RTI
2. **Remove test driver global ORCC #$50** (or replace with per-critical-
   section masking if needed). Production boot sequence does not use a
   driver-level global mask.
3. **Revisit `HAL_sys_init` mask policy**: if HAL_sys_init is called from
   a context where interrupts are already masked (production boot), the
   internal `orcc #$50` is redundant but harmless. If it's called with
   interrupts enabled, the mask is required during transition.
4. **Enable VBL source**: write `$FF92` (IRQENR) to enable GIME VBORD
   interrupt on IRQ. (`$FF93` is FIRQENR — the FIRQ enable register; for
   the IRQ path, `$FF92` is correct.) See `docs/interrupt-handling.md §8`
   for the full enabling sequence (canonical: `$FF90=$6C`, `$FF92=$08`,
   `$FF93=$00`) and §9 for the reference handler skeleton.
   PIA0 VBL path is the legacy CoCo 1/2 mechanism; not applicable in
   karateka-coco3 (which uses GIME mode, `$FF90` COCO=0). See
   `docs/interrupt-handling.md §8.2` on the `$FF03` ack register's
   non-applicability in the default configuration.
5. **Verify handler fires**: MAME deferred-read capture should show the
   frame counter advancing per interrupt, not per polling loop.

### Failure mode if migration is forgotten

Real interrupt handler installed at $010C, but `ORCC #$50` (global mask)
still active from test driver entry. Handler exists but never fires.
Behavior appears correct (frame timer advances via polling fallback) but
real interrupt path is untested. Silent failure of the interrupt mechanism.

Detection: frame counter should advance FASTER when interrupt-driven (exact
VBL interval) vs polling (approximate). MAME deferred-read capture of
frame rate reveals the discrepancy.

`[ref: docs/open-questions.md Q001 — full migration question and criteria]`
`[ref: docs/interrupt-handling.md §6 — P3.1 migration procedure]`
`[ref: 6502-6809-conversion-patterns/shared/G-methodology/G.3-coco3-platform-assumptions.md]`

---

## 17. Cross-References

- HAL contract: `src/hal.inc` and `docs/hal.md`
- Design doc §6.4: `docs/karateka-coco3-design-v0.1.md`
- 6502→6809 patterns: `../6502-6809-conversion-patterns/shared/`
- Methodology patterns: `../apple2-disasm-patterns/`
- Reference oracle: `../karateka_dissasembly_claude/`
- Pop-coco3 conventions (model): `docs/pop-coco3-design-v0_7.pdf`
  Section 6.12

---

## 18. Text Glyph Conversion

### Canonical start column: 119

All text glyph conversions for splash sequences, cutscenes, and other
text rendering use canonical `--start-col 119` (odd column parity)
when invoking `tools/sprite_convert.py`.

This matches the column used for Brøderbund Logo 1 (P2.3a.6).

#### Rationale

Per `sprite_convert.py`'s chroma model, the start column determines
NTSC artifacting behavior for isolated and edge pixels (which palette
index is assigned to chromatic fringing pixels). Per-position
conversion (converting each letter at its actual rendered column in a
string) maximises Apple II fidelity but doubles or triples sprite count
for repeated letters and requires per-string position-vs-conversion-column
coordination.

Project-wide canonical column trades per-position chroma fidelity for:
- Memory efficiency (fewer sprite objects per string)
- Simpler dispatch (one sprite per unique letter)
- Visually consistent text appearance across scenes
- No per-string position-vs-conversion-column coordination

The visual difference between canonical-column chroma and per-position
chroma is fringing pixels at stroke edges. At splash duration and
typical viewing distance, the difference is not perceptible.

#### Convention statement

**All future text glyph conversions** (alphabet, punctuation, numerals,
special characters) MUST use `--start-col 119`. This applies whether
the glyph is being converted for the first time or re-converted for any
reason.

#### Tool invocation pattern

```bash
python3 tools/sprite_convert.py \
  --source karateka_dissasembly_claude/src/sprite_data_0400.s \
  --label sprite_XXXX \           # use address-based label (see §13 note below)
  --output content/glyph_X/converted.s \
  --coco-label glyph_X_coco3 \
  --start-col 119
```

**Label note (lwasm label stacking):** Each glyph in `sprite_data_0400.s`
has two labels — a named label (`sprite_letter_p:`) immediately followed
by an address-based alias (`sprite_0534:`). The named label must NOT be
used with `sprite_convert.py` because the alias label triggers the
extractor's "next label = stop" condition before collecting bytes. Use
the address-based label exclusively.

Label map for "presents" letters:

| Letter | Label | Address |
|--------|-------|---------|
| p | `sprite_0534` | $0534 |
| r | `sprite_0568` | $0568 |
| e | `sprite_0458` | $0458 |
| s | `sprite_057e` | $057E |
| n | `sprite_0508` | $0508 |
| t | `sprite_0594` | $0594 |

#### Output structure

Each converted glyph lives in `content/glyph_{letter}/`:
- `apple2.png` — Apple II source rendering (visual gate reference)
- `coco3.png` — CoCo3 converter output prediction (visual gate)
- `converted.s` — lwasm-compatible FCB data for inclusion in drivers

#### Origin

Established post-P2.3a.9 following font glyph inspection.
Applied first to "presents" splash text in P2.3a.10.

`[ref: docs/methodology.md Rule 1 — color identification requires Jay's observation]`
`[ref: tools/sprite_convert.py — chroma model implementation]`

---

## 19. Apple II → CoCo3 Coordinate Mapping

### Border offset convention

All sprite and graphics positioning translates Apple II hires (280px
wide) source coordinates to CoCo3 GIME (320px wide) framebuffer
coordinates using a **+5 byte-column border offset**.

#### Math

| Property | Apple II | CoCo3 | Notes |
|----------|----------|-------|-------|
| Width | 280 pixels | 320 pixels | +40 pixels |
| Width in bytes | 40 bytes (7 px/byte) | 80 bytes (4 px/byte) | — |
| Border width | n/a | 40 pixels (5 bytes each side) | Centers Apple II content |
| Height | 192 rows | 192 rows | 1:1 vertical mapping |

The 40-pixel extra width splits into 5 bytes of left border + 5 bytes of
right border, centering the Apple II 280-pixel content within the CoCo3
320-pixel framebuffer.

#### Mapping formula

For any sprite or content positioned at Apple II pixel column X:

```
coco3_byte_col = floor(apple2_pixel_col / 4) + 5
```

Examples:

- Apple II pixel col 0 → CoCo3 byte col 5 (left edge)
- Apple II pixel col 84 → CoCo3 byte col 26 (exact: 84/4=21, +5=26)
- Apple II pixel col 119 → CoCo3 byte col 35 (floor: 119/4=29, +5=34... corrected to 35 per Logo 1 round-up)
- Apple II pixel col 279 → CoCo3 byte col 74 (floor: 279/4=69, +5=74)

Vertical mapping is 1:1; no Y offset applies (both displays are 192 rows).

#### Sub-byte rounding (see §20.3)

When `apple2_pixel_col / 4` produces a non-integer result, the Apple II pixel
column maps to a sub-byte position within the CoCo3 byte. Sub-byte pixel
rendering is implemented (§20); the rounding rule is floor() per §20.3. The
(byte_col, subbyte) pair is derived as:
- `coco3_byte_col = floor(coco3_pixel_col / 4)`
- `coco3_subbyte = coco3_pixel_col mod 4`

#### Applies to

- All sprite blits via `HAL_gfx_blit_sprite`
- All text glyph positions (see §18)
- Any other graphics content derived from Apple II source coordinates

#### Origin

First applied in P2.3a.6 for Brøderbund Logo 1 (Apple II col 119 →
CoCo3 byte col 30, rounded from 119/4+5=34.75; note: Logo 1 used
start_col=119 for chroma and byte col 35 for position). Documented
formally in P2.3a.11.

`[ref: content/broderbund_logo_sprite_1/ — first application]`
`[ref: font glyph inspection report R-c — "presents" position table]`

---

## 20. Sub-byte rendering

Sprite rendering on CoCo3 operates at pixel precision via runtime sub-byte
shifting, matching Apple II Karateka Classification (A) rendering (verified
by inspection in the `dispatch/p2-4` plan chain). Sprites position at any
CoCo3 pixel column 0-319, not just byte boundaries.

### 20.1 Position parameter convention

Sprite blits accept position as a (byte_col, subbyte) pair:
- **byte_col**: 0-79 (CoCo3 graphics byte column)
- **subbyte**: 0-3 (sub-byte pixel offset within the leftmost byte)
- absolute pixel column = byte_col × 4 + subbyte

This parallels Apple II Karateka's ($05, $10) ZP location pair (byte column
+ sub-byte shift) verified in `karateka_dissasembly_claude/src/video.s`.

### 20.2 HAL contract

`HAL_gfx_blit_sprite` accepts:
- A = byte_col (0-79)
- B = pixel_row (0-191)
- ZP $0C `blit_subbyte` = sub_byte_offset (0-3); **caller must set before call**
- X = sprite data pointer

Sprite output extends one byte beyond sprite_width when subbyte > 0 (overflow
byte carries shifted-out bits). Caller does not need to track the overflow byte
position; HAL handles it internally.

### 20.3 Rounding rule

When converting an Apple II pixel column or any fractional pixel column to
CoCo3 (byte, subbyte), use **floor()** not round-nearest. Established in
P2.3a.11-followup-3; confirmed by Apple II inspection that the original game's
position tracking accumulates byte+subbyte deltas with explicit carry rather
than rounding.

Formula:
```
coco3_byte_col = floor(coco3_pixel_col / 4)
coco3_subbyte  = coco3_pixel_col mod 4
```

### 20.4 Border offset (cross-reference §19)

For Apple II → CoCo3 coordinate mapping, the canvas-scale formula remains:

```
coco3_pixel_col = (apple2_pixel_col × 8 / 7) + 20
```

where +20 (= 5 bytes × 4 pixels/byte) is the border offset for centering
Apple II 280-px content within CoCo3 320-px canvas.

### 20.5 Sub-byte rendering applies to all sprites

Not just text. Character animation, scenery, logos — all sprite content uses
the same primitive. Background sprites typically pass subbyte=0 for
byte-aligned placement (current behavior); content with pixel-precise position
uses sub-byte values.

---

## 21. Transparency-aware blit

Sprite blits implement key-color transparency with "most-recent-wins"
semantics. This is required for sprite layering, letter hangover preservation,
and correct rendering of overlapping content.

### 21.1 Semantics

For each destination pixel position:
- Source pixel = index 0 (black, 2bpp value 00): **destination preserved** (transparent)
- Source pixel = index 1, 2, or 3 (non-black): **destination replaced** with source pixel value

Compared to alternatives:
- STA (store): black source pixels CLEAR dest → wrong (erases prior content)
- OR (Apple II style at 1bpp): preserves but at 2bpp OR mixes pixel colors (orange | blue = white) → wrong for color content
- Transparency (key-color, most-recent-wins): the rule above → correct

### 21.2 Implementation

Per-byte transparency uses a 256-byte mask lookup table
(`blit_transparency_mask_table`) declared in the HAL data section.
For each source byte:

1. mask = lookup(source_byte) — 11 at each 2-bit position where source has
   any non-zero bits; 00 elsewhere
2. result = (dest AND ~mask) OR source
3. Store result to dest

Mask table generation (256 entries, computed at assembly time): for each byte
value 0-255, for each of 4 pixel positions (bits 7:6, 5:4, 3:2, 1:0): if
either bit is set in source, set 11 in mask at that position; else 00.

Lookup uses signed-B offset trick: U points to table midpoint
(`blit_trans_table_mid`), and `lda b,u` correctly indexes all 256 values
including the $80-$FF range via signed offset arithmetic.

### 21.3 HAL contract change

Transparency applies to all 5 blit cases (subbyte=0/1/2/3 plus overflow byte).
All blits read destination before writing.

### 21.4 Cycle cost

Adds ~36 cycles per source byte vs STA-only blit. Per sub-byte case:
- sb0: ~43 cy/byte
- sb1: ~83 cy/byte
- sb2: ~94 cy/byte
- sb3: ~102 cy/byte

Adequate for splash content; tight for full-rate character animation. Flagged
for future optimization phase.

---

## 22. Visible-extent sprite metadata

Sprites have visible-extent properties that determine their actual rendered
footprint independently of their byte-aligned data boundaries. This metadata
is required for correct sprite positioning and inter-sprite spacing.

### 22.1 Concept

Each sprite has 2 horizontal extent values:

- **wlead** — pixel offset from nominal blit position (byte_col × 4 + subbyte)
  to the first **white** (index 3) pixel in the rendered output. Range: 0+.
- **trail** — pixel offset from nominal blit position to the last non-black
  pixel anywhere in the rendered output, including the overflow byte when
  subbyte > 0.

**Key verified property: wlead and trail are subbyte-invariant** for any given
sprite. The runtime shift repositions content within the byte grid but does not
change the pixel offset from nominal_px to first/last visible pixel. This was
verified empirically via per-glyph per-subbyte inspection of all 6 "presents"
glyphs traced through the HAL shift logic.

Future extensible metadata: **top** and **bottom** (first/last row with
content) for 2D extent; not yet measured for current glyphs.

### 22.2 Position formula for horizontal sprite layout

```
nominal(N+1) = nominal(N) + trail(N) + 1 + DESIRED_GAP - wlead(N+1)
```

Where:
- nominal(N) = absolute CoCo3 pixel column of sprite N's blit position
- trail(N) = visible-extent trail value for sprite N
- wlead(N+1) = visible-extent wlead value for sprite N+1
- DESIRED_GAP = intended visible space between sprites (in CoCo3 pixels)

After computing nominal(N+1), convert to (byte, subbyte) using §20.3.

### 22.3 DESIRED_GAP convention

Inter-letter spacing for text rendering uses **DESIRED_GAP = 1** CoCo3 pixel.
Verified empirically via Jay's visual gate in P2.4.2-followup-3.

For other sprite layout contexts (UI, character-to-character, etc.),
DESIRED_GAP is the per-context intended visible space.

### 22.4 Per-glyph constants for "presents"

Empirically verified constants for the 6 letters in the "presents" splash text:

| Letter | trail | wlead | visible_width |
|--------|-------|-------|----------------|
| p | 10 | 1 | 11 |
| r | 10 | 1 | 11 |
| e | 8 | 1 | 9 |
| s | 7 | 2 | 6 |
| n | 9 | 1 | 10 |
| t | 9 | 1 | 10 |

### 22.4a Per-glyph constants for scene-2 / "pressed" (R-p25)

Computed from the converted bitmaps by `tools/glyph_extent.py` (first-white
column = wlead, last-non-black column = trail), **validated** by reproducing
§22.4's hand-measured p,r,e,s,n,t exactly. (visible_width here = trail−wlead+1,
the tool's consistent definition; may differ ±1 from §22.4's hand values — the
formula uses trail/wlead, which match.)

| Letter | trail | wlead | visible_width |
|--------|-------|-------|----------------|
| a | 8 | 1 | 8 |
| b | 9 | 1 | 9 |
| c | 8 | 1 | 8 |
| d | 8 | 1 | 8 |
| g | 8 | 1 | 8 |
| h | 9 | 1 | 9 |
| j | 5 | 1 | 5 |
| m | 13 | 1 | 13 |
| o | 9 | 1 | 9 |
| y | 10 | 1 | 10 |

**Inter-word gap (§2-F):** 16 CoCo3 pixels = glyph-`m` data width (`fcb 10,4`
→ 4 bytes × 4 px). Applied between words in scene-2 strings; inter-letter gap
stays DESIRED_GAP=1 (§22.3). Bake tool: `tools/bake_text.py` (route i).

Source: `content/glyph_{letter}/converted.s`. Original 6 (above): per-glyph
per-subbyte inspection traced through HAL shift logic (2026-05-17).
Anchor: 'p' at nominal pixel 135 (byte 33, subbyte 3).

Per-sprite metadata in sprite headers (deferred future converter work) will
make these values authoritative from data rather than hand-tabulated.

### 22.5 Generalization to all sprites

Visible-extent metadata is not glyph-specific. It applies to character
animation frames, scenery sprites, logo and UI sprites, and background
elements. Use cases beyond text spacing include sprite-to-sprite collision
detection, pixel-precise character motion, z-order rendering correctness, and
per-frame animation step granularity.

---

## 23. Convention provenance

Conventions in §20, §21, §22 are empirically grounded:

- §20 Sub-byte rendering: p2-4-1-verdict-v1 (CONFIRMED) + Apple II
  Classification (A) inspection
- §21 Transparency-aware blit: p2-4-1-followup-1-verdict-v1 (CONFIRMED)
  + HAL blitter inspection
- §22 Visible-extent metadata: p2-4-2-closure-verdict-v1 (CONFIRMED)
  + per-glyph per-subbyte inspection (2026-05-17)
- §20.3 Rounding rule: P2.3a.11-followup-3 closure + Apple II
  render_string trace
- §19 Border offset: P2.3a.11 plan establishment

## 24. Input acquisition/consume frame ordering

Within any per-frame loop that consumes input (attract holds, scene
controllers, combat), the input poll (`HAL_input_poll`) must occur in
the **same frame iteration as — and before — the logic that consumes
its result.** Poll-then-consume within one iteration.

**Rationale:** the polled input model's acquisition latency is one
frame *only if* poll and consume sit adjacent in the same iteration. A
poll at the top of frame N whose result is consumed at the bottom of
frame N+1 becomes **two** frames of latency, silently degrading input
feel with no visible code smell. This matches the oracle's per-frame
input cadence (`routine_b7f5` runs inside the frame loop, consumed the
same frame).

**Applies to:** R-p24 (enforced as AC-11) and every subsequent
input-consuming loop. Load-bearing for the polled model's one-frame
best case; directly relevant to the `Q-input-model` latency gate.
