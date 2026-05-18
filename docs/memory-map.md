# karateka-coco3 — Memory Map

Version: 0.1 (P1.6 deliverable, 2026-05-13)

## 1. Overview

CoCo3 memory layout for karateka-coco3. Covers:
- 64KB CPU address space organization
- Physical RAM layout (128K minimum, 512K leveraged — Gate K.1.4)
- MMU page assignments (GIME 8K-page architecture)
- Per-subsystem region addresses
- Frame buffer addressing and swap mechanism
- Trace buffer location (closes P1.3 follow-up dependency)
- Address constants exported to `src/hal.inc`

Shape inherited from pop-coco3-design v0.7 (page 12 layout); two
divergences documented in §7.

References: `[ref: GIME-RM]` throughout for register addresses,
mode values, and physical address derivation.

---

## 2. CPU Address Space (64KB)

```
$0000-$00FF  Direct page (DP)              256 B
$0100-$01FF  Stack                         256 B
$0200-$1FFF  Engine code + data           ~7.5 KB
$2000-$3FFF  HAL code + data               8.0 KB
$4000-$5FFF  Content bank window           8.0 KB  (bank-switched)
$6000-$77FF  Working RAM                   6.0 KB
$7800-$7FFF  Trace ring buffer + spare     2.0 KB
$8000-$BBFF  Frame buffer A (back)        15,360 B  ($3C00)
$BC00-$BFFF  Unused (MMU alignment pad)    1.0 KB
$C000-$FBFF  Frame buffer B (front)       15,360 B  ($3C00)
$FC00-$FEFF  Hardware I/O (PIA, SAM)         768 B
$FF00-$FFFF  GIME registers + CPU vectors    256 B
             ────────────────────────────────────
             Total                         65,536 B  (64 KB)
```

DP allocation follows `docs/conventions.md §2`:
- `$00-$1F` HAL scratch
- `$20-$7F` Engine ZP (with observed clusters at `$20-$2F`, `$60-$6F`, `$70-$7F`)
- `$80-$FF` CoCo3 system reserved

---

## 3. Physical RAM Layout

### 3.1 Physical Page Architecture

The GIME MMU divides the CPU's 64KB into eight 8KB pages. Each
page is mapped independently to a 6-bit physical page register
(FFA0-FFA7 for task set 0), addressing 64 physical 8KB pages
across a 512KB physical space.

`[ref: GIME-RM §7]` MMU architecture and task register layout.

Physical page → address: `physical_addr = page_number × 8192`

For 128K CoCo3:
- Physical pages $30-$3F available (2 × 64KB = 128KB)
- Upper bank: pages $38-$3F → physical $70000-$7FFFF (default CPU mapping)
- Lower bank: pages $30-$37 → physical $60000-$6FFFF (content, via bank window)

For 512K CoCo3:
- Physical pages $00-$3F available (512KB)
- Additional pages $00-$2F for expanded content residency

### 3.2 128K Mode — MMU Task Set 0

Default task set 0, used for engine and HAL operation:

| MMU reg | Value | CPU range       | Physical range      | Purpose                        |
|---------|-------|-----------------|---------------------|--------------------------------|
| FFA0    | $38   | $0000-$1FFF     | $70000-$71FFF       | DP, stack, engine code start   |
| FFA1    | $39   | $2000-$3FFF     | $72000-$73FFF       | Engine continued               |
| FFA2    | $3A   | $4000-$5FFF     | $74000-$75FFF       | HAL code + data                |
| FFA3    | $3B   | $6000-$7FFF     | $76000-$77FFF       | Working RAM + trace buffer     |
| FFA4    | $3C   | $8000-$9FFF     | $78000-$79FFF       | Frame buffer A, first half     |
| FFA5    | $3D   | $A000-$BFFF     | $7A000-$7BFFF       | Frame buffer A, second half    |
| FFA6    | $3E   | $C000-$DFFF     | $7C000-$7DFFF       | Frame buffer B, first half     |
| FFA7    | $3F   | $E000-$FFFF     | $7E000-$7FFFF       | Frame buffer B, second half    |

FFA7 ($E000-$FFFF) contains frame buffer B's second half at
$E000-$FBFF; the GIME overrides $FF00-$FFFF with hardware
register I/O regardless of task register settings.
`[ref: GIME-RM §18]`

Content bank (128K streaming mode): FFA2 is remapped from $3A to
a lower-bank page ($30-$37) when loading a content segment, then
restored to $3A. HAL_file_load manages this remapping during P2.

### 3.3 512K Mode

Same CPU layout and default MMU as 128K. Content pages are
pre-loaded into lower physical pages ($00-$2F) at game load time
and remain resident throughout gameplay. The FFA2 content bank
window is not remapped per-access — content pointers reference
their fixed loaded addresses.

Detail of 512K resident page assignments deferred to P2 when
content loading is implemented.
`[no-ref: 512K page assignments — detailed during P2]`

---

## 4. Per-Subsystem Memory Regions

### 4.1 Direct Page (DP) — $0000-$00FF

Physical page $38, offset $0000-$00FF. See `docs/conventions.md §2`
for the full DP allocation layout (HAL scratch, engine globals,
observed ZP clusters from karateka Apple II source).

`[no-ref: CoCo3 system DP at $80-$FF — verify from CC3-TR during
P2 before writing any code that touches $80+]`

### 4.2 Stack — $0100-$01FF

256 bytes (physical page $38, offset $0100-$01FF). 6809 stack
grows downward from `$01FF`. Stack pointer initialized to `$01FF`
at boot.

Sub-allocation at bottom of stack region (P2.3a.0):

```
$0100-$0111  Handler dispatch block (18 bytes)
               Six 3-byte RTI stubs; CoCo3 $FExx chain routes here.
               Address order: swi3=$0100, swi2=$0103, swi=$0106,
               nmi=$0109, irq=$010C, firq=$010F
               [ref: docs/SockmasterGime.md §1]
               [ref: src/hal/coco3-dsk/sys.s]
$0112-$0117  Reserved for dispatch block expansion (6 bytes)
$0118-$01FF  Stack (232 bytes available for runtime use)
```

With the 32-byte per-call budget (`docs/conventions.md §4`), the
deepest stack reach is approximately `$01E0`, far above the dispatch
block. The sub-allocation is architecturally safe.

`[ref: docs/conventions.md §2 — handler dispatch block band entry]`
`[ref: docs/interrupt-handling.md §4 — dispatch block design]`

Conventional placement: `$0100-$01FF` is the standard 6809 stack
region (immediately above DP, below engine code). This is simpler
than pop-coco3's `$FE00-$FEFF` stack and keeps stack adjacent to
DP for easier debugging.

Stack overflow protection: With the 256-byte budget and the engine
convention of maximum 32 bytes per call, no recursion
(`docs/conventions.md §4`), overflow would overwrite the DP
region at `$0000-$00FF`. Convention enforcement is the structural
bound — the engine discipline prevents stack/DP collision.

`[ref: MC6809 §4.5]` PSHS/PULS stack discipline.

### 4.3 Engine Code + Data — $0200-$1FFF

~7.5KB (physical pages $38-$39). Engine source files from
`src/engine/`. Includes `src/engine/globals.s` (DP + RAM variable
declarations), `src/engine/boot.s`, `src/engine/scene.s`, and
remaining engine subsystems.

Approximate engine code budget: ~8KB. This is derived from Apple II
intro-time code (~32KB total minus ~15KB sprite data minus ~1KB
sound data minus HAL-equivalent code ≈ ~16KB engine-equivalent;
6809 port efficiency may reduce this).

`[no-ref: exact engine code size — determined during P2 engine
porting; budget is an estimate from Apple II source analysis]`

### 4.4 HAL Code + Data — $2000-$3FFF

8KB exactly (physical page $3A). HAL implementation files from
`src/hal/coco3-dsk/`. Includes gfx.s, time.s, sound.s, debug.s,
and skeletons for mem/input/file/sys.

HAL data (palette tables, tone-record state, trace ring buffer
management variables) lives within this 8KB alongside HAL code.

### 4.5 Content Bank Window — $4000-$5FFF

8KB window (physical page $3A in HAL mode; remapped to lower bank
pages $30-$37 for content access in 128K streaming mode).

Content loaded through this window:
- Sprite banks (Apple II intro-time: ~15KB of sprite data across
  multiple banks; remaining gameplay banks from P0b ongoing work)
- Converted sound data ($0E00-$0FFF = 512 bytes; timer sound data)
- Palette files (4 bytes each; trivially small)

128K streaming: single 8KB window. Bank selection managed by
HAL_file_load during P2. **Single-window decision is provisional.**
If P2 engine porting reveals streaming pressure (e.g., multiple
simultaneous active sprite banks exceed 8KB), revisit with a
second bank window in `$6000-$77FF` per plan-deviation-discipline.

`[no-ref: lower-bank physical page assignments ($30-$37) for each
content segment — determined during P2 content loading work]`

### 4.6 Working RAM — $6000-$77FF

6KB (physical page $3B, offset $6000-$77FF). Engine working state,
frame-coherent variables, subsystem working buffers. This region
maps to Apple II ZP clusters `$60-$6F` (combatant A) and `$70-$7F`
(combatant B) which are preserved in the DP layout per conventions.

Main RAM equivalents (larger structures that don't fit in DP):
- Combatant state arrays (above the ZP clusters)
- Animation sequence tables
- Per-scene working buffers

### 4.7 Trace Ring Buffer — $7800-$7FFF

Trace ring buffer at **CPU `$7800`**, physical `$77800`, **256
bytes** ($7800-$78FF). Managed by HAL_debug_trace_event
(P1.3 follow-up). Engine writes trace events; MAME harness reads
from this known address.

Ring buffer format (256 bytes):
```
$7800     head pointer (1 byte, wraps at $FF)
$7801     tail pointer (1 byte)
$7802-$78FF  event records (253 bytes of ring, ~63 x 4-byte events)
```

Event record format (4 bytes):
```
byte 0: event code (opaque byte from engine)
byte 1: event data high byte (or 0)
byte 2: event data low byte (or 0)
byte 3: reserved
```

Spare at `$7900-$7FFF` (1,792 bytes, physical $77900-$77FFF) reserved
for future use.

This resolves the P1.3 follow-up `[no-ref: trace buffer location —
deferred to P1.6]` in `docs/hal.md §5.8`. See §8 address constants.

### 4.8 Frame Buffer A — $8000-$BBFF

15,360 bytes ($3C00). Back buffer (rendered to by engine, not
currently displayed). Physical pages $3C-$3D ($78000-$7BBFF).

Frame buffer A spans the full MMU pages 4 and part of page 5:
- CPU $8000-$9FFF → physical $78000-$79FFF (page $3C, 8KB)
- CPU $A000-$BBFF → physical $7A000-$7BBFF (first 3KB of page $3D)

`$BC00-$BFFF` (1KB): unused MMU page boundary alignment overhead.
Frame buffers are $3C00 = 15,360 bytes; the nearest MMU-aligned
boundary requires 16KB ($4000) to span cleanly across two 8KB
pages. The 1KB gap ($BC00-$BFFF = $4000 - $3C00 = $0400) is an
unavoidable consequence of the 8KB MMU granularity against 15,360-
byte frames. Not wasteful — it is simply the structural cost of
using hardware-aligned memory banks.

`[ref: GIME-RM §7]` MMU 8KB page granularity.
`[ref: GIME-RM §10]` 320×192×4 buffer size: 80 bytes/row × 192 rows = $3C00.

Physical address for GIME VOFFSET registers:
Physical $78000: `$FF9D = $F0`, `$FF9E = $00`
`[ref: GIME-RM §13]` physical address derivation formula.

### 4.9 Frame Buffer B — $C000-$FBFF

15,360 bytes ($3C00). Front buffer (currently displayed by GIME).
Physical pages $3E-$3F ($7C000-$7FBFF).

Frame buffer B spans MMU pages 6 and part of page 7:
- CPU $C000-$DFFF → physical $7C000-$7DFFF (page $3E, 8KB)
- CPU $E000-$FBFF → physical $7E000-$7FBFF (first $1C00 of page $3F)

Page $3F (CPU $E000-$FFFF) also contains hardware I/O at $FF00-$FFFF
(GIME always overrides this range regardless of MMU task register
settings). Frame buffer B only uses $E000-$FBFF of page $3F; the
$FC00-$FFFF region is hardware-decoded, not RAM.

`[ref: GIME-RM §18]` CPU vectors always decoded from ROM/I/O.

Physical address for GIME VOFFSET registers:
Physical $7C000: `$FF9D = $F8`, `$FF9E = $00`

### 4.10 Frame Buffer Swap Mechanism

Double-buffering via GIME VOFFSET registers (`$FF9D`/`$FF9E`):

1. Engine renders to back buffer (currently not displayed)
2. At `HAL_gfx_present`: write `$FF9D`/`$FF9E` to point GIME at
   the just-rendered buffer, making it the new front
3. Swap roles: former front becomes new back
4. Return to step 1

No memory copy. GIME begins displaying the new buffer at the next
vertical blanking interval (via `HAL_time_vbl_wait`).

HAL maintains `gfx_front_buffer` and `gfx_back_buffer` pointers
internally. Engine code never reads these; always calls through HAL.

Initial state: GIME displays frame B (`$FF9D=$F8`); engine renders
to frame A.

`[ref: GIME-RM §6]` VOFFSET registers.

### 4.11 Hardware I/O — $FC00-$FFFF

```
$FC00-$FEFF  PIA0, PIA1, other peripheral I/O
$FF90-$FF9F  GIME initialization + video registers
$FFA0-$FFBF  GIME MMU + palette registers
$FFD8-$FFDF  SAM bit-set/clear registers
$FFE0-$FFFF  CPU interrupt vectors
```

`[no-ref: exact PIA address layout ($FC00-$FEFF) — verify from
CC3-TR during P2 before writing input/sound HAL implementations]`

`[ref: GIME-RM §3]` register map summary for $FF90-$FFBF, $FFD8-$FFDF.
`[ref: GIME-RM §18]` CPU vector table at $FFE0-$FFFF.

---

## 5. GIME Video Mode Configuration

For reference during HAL_gfx_init implementation (P3):

```asm
; 320×192×4 mode setup per [ref: GIME-RM §10]
; Verified working: $FF98=$80, $FF99=$15
;
; VMODE ($FF98) = $80:  BP=1 (graphics), all other bits 0
; VRES  ($FF99) = $15:  LPF=00 (192 lines), HRES=101 (80 B/row),
;                        CRES=01 (4 colors, 2 bpp, 4 px/byte)
;
; Initialization order per [ref: GIME-RM §14]:
;   1. ORCC #$50        disable IRQ/FIRQ
;   2. $FFD9            1.78 MHz CPU clock
;   3. Clear framebuffer (before $FF90 activates video)
;   4. $FFB0-$FFB3      load 4-color palette
;   5. $FF98=$80        VMODE = graphics
;   6. $FF99=$15        VRES = 320×192×4
;   7. $FF9D/$FF9E      screen start physical address
;   8. $FF9C=$00        VSCROL = 0 (REQUIRED — undefined at reset)
;   9. $FF9F=$00        HOFFSET = 0 (REQUIRED — undefined at reset)
;  10. $FFDF            SAM: RAM at $C000 (task 0)
;  11. $FF90=$4C        ACTIVATE CoCo3 mode — WRITE LAST
;      ($4C = COCO=0, MMUEN=1, IEN=0, FEN=0, MC3=1, MC2=1)
;  12. ANDCC #$AF       re-enable interrupts
```

Warning from `[ref: GIME-RM §14]`: Writing `$FF90` activates CoCo3
mode immediately. All video registers must be configured and the
frame buffer cleared **before** step 11, or garbage pixels will
flash on screen.

---

## 6. Address Constants

Exported to `src/hal.inc`. See §6 of that file for the actual
declarations.

| Constant | Value | Ref | Purpose |
|----------|-------|-----|---------|
| KCOCO3_FB_A_BASE | $8000 | memory-map §4.8 | Frame A CPU base |
| KCOCO3_FB_B_BASE | $C000 | memory-map §4.9 | Frame B CPU base |
| KCOCO3_FB_A_VOFF_HI | $F0 | GIME-RM §13 | Frame A $FF9D value |
| KCOCO3_FB_A_VOFF_LO | $00 | GIME-RM §13 | Frame A $FF9E value |
| KCOCO3_FB_B_VOFF_HI | $F8 | GIME-RM §13 | Frame B $FF9D value |
| KCOCO3_FB_B_VOFF_LO | $00 | GIME-RM §13 | Frame B $FF9E value |
| KCOCO3_FB_SIZE | $3C00 | GIME-RM §10 | Frame buffer byte count |
| KCOCO3_TRACE_BUFFER | $7800 | memory-map §4.7 | Trace ring buffer CPU address |
| KCOCO3_TRACE_BUF_SIZE | $100 | memory-map §4.7 | Trace ring buffer size (256 B) |
| KCOCO3_GIME_INIT0 | $FF90 | GIME-RM §3 | GIME initialization reg 0 |
| KCOCO3_GIME_INIT1 | $FF91 | GIME-RM §3 | GIME initialization reg 1 |
| KCOCO3_GIME_IRQENR | $FF92 | GIME-RM §4 | IRQ enable (VBORD = bit 3) |
| KCOCO3_GIME_FIRQENR | $FF93 | GIME-RM §4 | FIRQ enable |
| KCOCO3_GIME_VMODE | $FF98 | GIME-RM §6 | Video mode register |
| KCOCO3_GIME_VRES | $FF99 | GIME-RM §6 | Video resolution register |
| KCOCO3_GIME_VOFFSET_HI | $FF9D | GIME-RM §6 | Screen start addr high |
| KCOCO3_GIME_VOFFSET_LO | $FF9E | GIME-RM §6 | Screen start addr low |
| KCOCO3_GIME_VSCROL | $FF9C | GIME-RM §9 | Vertical scroll (init to $00) |
| KCOCO3_GIME_HOFFSET | $FF9F | GIME-RM §10 | Horizontal offset (init to $00) |
| KCOCO3_MMU_TASK0 | $FFA0 | GIME-RM §7 | MMU task set 0 base |
| KCOCO3_GIME_PALETTE_BASE | $FFB0 | GIME-RM §8 | Palette register 0 |
| KCOCO3_SAM_CLK_HI | $FFD9 | GIME-RM §9 | SAM: set 1.78 MHz clock |
| KCOCO3_SAM_RAM_C000 | $FFDF | GIME-RM §9 | SAM: RAM at $C000 |
| KCOCO3_VMODE_GRAPHICS | $80 | GIME-RM §10 | $FF98 value: graphics mode |
| KCOCO3_VRES_320x192x4 | $15 | GIME-RM §10 | $FF99 value: 320×192×4 |
| KCOCO3_INIT0_COCO3 | $4C | GIME-RM §4 | $FF90 value: CoCo3 mode |

---

## 7. Pop-coco3 Inheritance and Divergences

Shape from pop-coco3-design v0.7 (page 12 memory map summary).

**Inherited:**
- Frame buffer positions ($8000-$BBFF, $C000-$FBFF)
- Frame buffer size ($3C00 per buffer)
- Physical page assignments (pages $3C-$3F for frame buffers)
- GIME VOFFSET swap mechanism (no memory copy)
- Content bank-switching via MMU remapping

**Divergences:**

| pop-coco3 | karateka-coco3 | Reason |
|-----------|----------------|--------|
| Engine at $0200-$3FFF (~16KB) | Engine at $0200-$1FFF (~7.5KB) | Karateka is simpler; tighter engine |
| HAL at $4000-$7FFF (~16KB) | HAL at $2000-$3FFF (8KB) | Simpler HAL; fewer targets |
| Stack at $FE00-$FEFF | Stack at $0100-$01FF | Conventional 6809 placement |
| No trace buffer in P1 design | Trace buffer at $7800-$78FF (256B) | P1.3 follow-up dependency |

Freed region `$4000-$7FFF` used for content window (`$4000-$5FFF`),
working RAM (`$6000-$77FF`), and trace buffer (`$7800-$7FFF`).

---

## 8. Reference Citations

### Documented decisions

- `[ref: GIME-RM §3]` — register map summary ($FF90-$FFBF, $FFD8-$FFDF)
- `[ref: GIME-RM §4]` — VBORD interrupt in $FF92/$FF93
- `[ref: GIME-RM §6]` — VMODE, VRES, VOFFSET1, VOFFSET0 register specs
- `[ref: GIME-RM §7]` — MMU architecture, 8KB pages, FFA0-FFA7
- `[ref: GIME-RM §8]` — palette registers $FFB0-$FFBF, 6-bit RGB format
- `[ref: GIME-RM §9]` — VSCROL ($FF9C), SAM registers ($FFD8-$FFDF)
- `[ref: GIME-RM §10]` — verified working mode: $FF98=$80, $FF99=$15;
  buffer size derivation (80 B/row × 192 rows = $3C00)
- `[ref: GIME-RM §13]` — physical address derivation formula for
  VOFFSET registers; derivation of $FF9D=$F0/$F8, $FF9E=$00
- `[ref: GIME-RM §14]` — mandatory initialization sequence, $FF90
  written last
- `[ref: GIME-RM §18]` — CPU vectors always ROM/I/O-decoded regardless
  of MMU
- `[ref: MC6809 §4.5]` — stack discipline (PSHS/PULS, §4.2 above)

### Decisions without reference

- `[no-ref: CoCo3 system DP at $80-$FF]` — CC3-TR needed; carried
  from hal.inc P1.3; resolve before writing code touching $80+
- `[no-ref: PIA I/O address layout ($FC00-$FEFF)]` — CC3-TR needed
  before writing input/sound HAL in P2/P3
- `[no-ref: content bank physical page assignments ($30-$37)]` —
  convention choice; determined during P2 content loading
- `[no-ref: 512K extended layout detail]` — detailed during P2

### Reference conflicts

None. GIME-RM is internally consistent on all cited decisions.
The expected CC3-TR vs Sockmaster-GIME palette timing conflict
(noted in hal.md §6) is not surfaced by this document.

---

## 9. Compatibility

Target: `coco3-dsk` (v1.0). Same physical layout applies to all
bare-metal targets (dsk, hdb if added later). OS-9 target would
require a different memory management strategy (NitrOS-9 allocates
memory; application cannot directly program MMU).

CPU: 6809 and 6309 (Gate K.1.3). Memory layout is identical for
both; CPU detection result does not affect address assignments.

128K minimum: full layout fits within upper 64K (pages $38-$3F)
plus one content bank page from lower 64K (pages $30-$37) at a
time. No content requires simultaneous multi-bank access in the
streaming model.

---

## 10. Cross-References

- HAL contract: `src/hal.inc` (address constants), `docs/hal.md`
- Engine conventions: `docs/conventions.md §2` (DP layout), `§4` (stack)
- Design doc: `karateka-coco3-design-v0.1.md §5.5` (Gate K.1.4)
- GIME reference: `docs/GIME_Reference_Manual.pdf`
- Karateka content sizes: `../karateka_dissasembly_claude/docs/data-areas-catalog.md`
