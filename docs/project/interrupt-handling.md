# karateka-coco3 — Interrupt Handling

Version: 0.1 (P2.3a.0 deliverable, 2026-05-16)

## 1. Overview

This document covers the CoCo3 interrupt architecture as it applies to
karateka-coco3, the current P2.3a.0 initialization approach, and the
planned migration to real interrupt handlers in P3.1.

**Current state (P2.3a.0):** All interrupts are masked. Dispatch block
provides RTI stubs as a safety net. No interrupt-driven behavior exists.

**Target state (P3.1+):** VBL interrupt drives frame synchronization.
Real handler installed at IRQ dispatch slot ($010C) per Sockmaster routing.

---

## 2. CoCo3 Three-Level Interrupt Dispatch

The CoCo3 uses a three-level interrupt dispatch chain. This is a CoCo3-
specific hardware design, not present in bare 6809 systems.

`[ref: docs/ground-truth/SockmasterGime.md §1 — Interrupt Vectors table]`

```
CPU reads     ROM points to   Secondary points to   Handler stub
$FFF2 (ROM)   $FEEE           $0100                 swi3_handler
$FFF4 (ROM)   $FEF1           $0103                 swi2_handler
$FFF6 (ROM)   $FEF4           $010F                 firq_handler
$FFF8 (ROM)   $FEF7           $010C                 irq_handler
$FFFA (ROM)   $FEFA           $0106                 swi_handler
$FFFC (ROM)   $FEFD           $0109                 nmi_handler
$FFFE (ROM)   —               —                     RESET ($8C1B)
```

### Level 1 — $FFxx (ROM, unchangeable)

CPU reads interrupt vectors from $FFF2–$FFFE. These addresses are
hardware-decoded to ROM regardless of MMU settings. **Writes to $FFF2–$FFFE
are silently ignored** — they go to ROM.

### Level 2 — $FExx (secondary vectors, RAM, MC3-gated)

The ROM-level vectors contain $FExx addresses. These are mutable RAM
locations that hold JMPs/LBRAs to the actual handlers. Color BASIC installs
its own handlers here during boot.

**MC3=1 in $FF90=$4C locks $FExx as "constant"** — after this write, $FExx
cannot be overwritten. BASIC's handler routing is preserved.

`[ref: docs/ground-truth/SockmasterGime.md — $FF90 bit 3 MC3]`

### Level 3 — $01xx (handler dispatch block, RAM, writable)

The $FExx secondary vectors contain JMPs to $01xx addresses. These ARE
writable RAM (mapped to physical $70000+ via FFA0=$38). The dispatch block
at $0100–$010F is where karateka-coco3 installs its interrupt handlers.

**Current P2.3a.0 content:** RTI stubs. All six handlers execute RTI,
safely returning if an interrupt fires despite masking.

---

## 3. $FF90 and the Transition Window

Writing `$FF90=$4C` (COCO=0) unmaps ROM from $8000–$FEFF. Before this
write, interrupt vectors at $FFF2–$FFFE route through ROM to BASIC's
handlers. After the write, the $FExx routing chain remains (MC3=1 locks
$FExx), but the final destination at $01xx is now the karateka-coco3
dispatch block (RTI stubs) rather than BASIC's handlers.

**Why interrupts must be masked during the transition:**

If an interrupt fires between the start of HAL_sys_init and the completion
of $FF90=$4C write, the CPU may attempt to service it via the ROM-to-BASIC
chain, which is valid. However, after $FF90=$4C, if an interrupt fires
before the $01xx dispatch block is known to be valid, the routing through
BASIC's $FExx chain to $01xx could find uninitialized RAM.

The karateka-coco3 solution: `ORCC #$50` before $FF90 write. The RTI stubs
at $01xx are loaded by DECB before execution begins, so if masking ever
fails, the RTI stubs provide a safe no-op landing.

`[ref: src/hal/coco3-dsk/sys.s — HAL_sys_init Step 1 comment]`

---

## 4. Dispatch Block Design

**Location:** $0100–$0111 (18 bytes, six 3-byte entries)

**Physical placement:** Bottom of the stack region ($0100–$01FF per
memory-map.md §2). Stack grows downward from $01FF; with the 32-byte
per-call budget (conventions.md §4), the stack cannot reach $0100 under
normal operation.

**Format per entry (3 bytes):**
```asm
; Each entry: RTI + NOP + NOP
; RTI = $3B (1 byte), NOP = $12 (1 byte)
; The extra 2 bytes (NOP NOP) give room for future expansion:
; Replace RTI with JMP opcode ($7E) + 2-byte address to redirect
; the handler without relocating the dispatch block.
```

**P3.1 handler installation procedure:**
To install a real IRQ handler (for example):
```asm
; Replace rti at irq_handler ($010C) with jmp real_irq_handler:
lda     #$7E                    ; JMP opcode
sta     $010C
ldx     #real_irq_handler
stx     $010D
; real_irq_handler address written to $010D (hi) and $010E (lo)
```

The 3-byte slot ($010C–$010E) fits exactly one JMP instruction.

`[ref: src/hal/coco3-dsk/sys.s — dispatch block definition]`
`[ref: docs/project/open-questions.md Q001 — interrupt discipline migration plan]`

---

## 5. Handler Address Reference (Sockmaster-Confirmed)

| Handler | $01xx address | Routed from | Interrupt source |
|---------|--------------|-------------|-----------------|
| swi3_handler | $0100 | $FEEE | SWI3 instruction |
| swi2_handler | $0103 | $FEF1 | SWI2 instruction |
| swi_handler | $0106 | $FEFA | SWI instruction |
| nmi_handler | $0109 | $FEFD | NMI pin (non-maskable) |
| irq_handler | $010C | $FEF7 | IRQ pin (VBL, keyboard, etc.) |
| firq_handler | $010F | $FEF4 | FIRQ pin |

**Warning:** These addresses come from Sockmaster's reverse-engineered
CoCo3 ROM dispatch table. Do NOT infer handler addresses from sequential
assignment (SWI3/SWI2/FIRQ/IRQ/SWI/NMI in that order) — that ordering
produces wrong $01xx slots for FIRQ, IRQ, SWI, and NMI.

`[ref: docs/ground-truth/SockmasterGime.md §1 — Interrupt Vectors table]`
`[ref: 6502-6809-conversion-patterns/shared/G-methodology/G.3-coco3-platform-assumptions.md — G.3.3 exemplar]`

---

## 6. P3.1 Migration Plan (Preview)

When the VBL interrupt is needed for frame synchronization (P3.1):

1. Write a real `irq_handler` routine.
2. Install it at $010C–$010E per §4 procedure above.
3. Revisit the `ORCC #$50` global mask in `HAL_sys_init` and the test
   driver's entry mask — these must be relaxed to allow IRQ to fire.
4. Ensure `HAL_time_vbl_wait` uses the interrupt rather than polling.

The `FIRQ` and `IRQ` distinction: VBORD (bit 3) in `$FF92` routes VBL to IRQ;
VBORD in `$FF93` routes VBL to FIRQ. The project routes VBL to IRQ. Canonical
configuration: `$FF92=$08`, `$FF93=$00`, `$FF90` IEN=1. See §8 for the full
enabling sequence, acknowledgement mechanism, and MAME verification approach.
See §9 for the reference handler skeleton.

`[ref: docs/project/open-questions.md Q001 — full migration question]`
`[ref: docs/project/conventions.md — interrupt mask policy section]`

---

## 7. Cross-References

- `src/hal/coco3-dsk/sys.s` — HAL_sys_init implementation; dispatch block
- `docs/project/conventions.md §2` — DP $13 sys_init_cc_mask allocation
- `docs/project/conventions.md §16` — Interrupt mask policy section
- `docs/project/memory-map.md §2` — Dispatch block within stack region
- `docs/project/open-questions.md Q001` — Interrupt discipline migration
- `docs/ground-truth/SockmasterGime.md §1` — Authoritative $01xx address table
- `docs/ground-truth/SockmasterGime.md lines 52-67` — $FF92/$FF93 bit layout; ack mechanism
- `6502-6809-conversion-patterns/shared/G-methodology/G.3-coco3-platform-assumptions.md`
  — G.3.3 exemplar (incident report for this issue class)
- `docs/project/conventions.md §16 line 653` — note: references $FF93 for enable;
  correct register is $FF92 (IRQENR); §8 of this document is authoritative

---

## 8. GIME VBL Interrupt: Hardware Specifics

**Source:** `docs/ground-truth/SockmasterGime.md`. The Tandy CC3 Technical Reference Manual
would corroborate these findings; PDF extraction was not available at X3
research time. Findings here are single-source from the project's designated
authoritative GIME reference.

### 8.1 Enabling VBL on IRQ

Two registers must be programmed. Order matters: enable the GIME source
before unmasking the 6809 CPU.

**Step 1 — Enable GIME IRQ globally ($FF90 IEN bit)**

`[ref: docs/ground-truth/SockmasterGime.md — $FF90 Bit 5: IEN 1=GIME chip IRQ enabled]`

The current `HAL_sys_init` writes `$FF90=$4C` (IEN=0, FEN=0 — GIME interrupts
globally off). To enable GIME → IRQ propagation, IEN (bit 5) must be set:
`$FF90=$6C` (`$4C | $20`). This change is part of the Q001 interrupt-discipline
migration; see `docs/project/open-questions.md Q001`.

**Step 2 — Enable VBORD source in $FF92 IRQENR**

`[ref: docs/ground-truth/SockmasterGime.md lines 52-66 — $FF92 IRQENR bit layout]`

| Bit | Name  | Function                        |
|-----|-------|---------------------------------|
| 7-6 | —     | Unused                          |
|   5 | TMR   | Timer interrupt                 |
|   4 | HBORD | Horizontal border interrupt     |
|   3 | VBORD | Vertical border interrupt (VBL) |
|   2 | EI2   | Serial data interrupt           |
|   1 | EI1   | Keyboard interrupt              |
|   0 | EI0   | Cartridge interrupt             |

To enable VBL only:
```asm
        lda     #$08            ; VBORD bit only
        sta     $FF92           ; write IRQENR — full overwrite (not RMW)
```
All other GIME IRQ sources remain disabled.

**Step 3 — Unmask 6809 CPU IRQ**

```asm
        andcc   #$EF            ; clear CC.I (bit 4) — allows IRQ to reach CPU
```

### 8.2 Interrupt Acknowledgement

`[ref: docs/ground-truth/SockmasterGime.md line 67 — "Reading from the register tells you`
`which interrupts came in and acknowledges and resets the interrupt source."]`

**Ack = read $FF92.** A single read simultaneously:
1. Returns the pending source bitmap (bit 3 = VBORD if VBL fired)
2. Clears all pending GIME IRQ flags

No separate clear register. The handler must read `$FF92` before RTI. If the
read is skipped, the IRQ line remains asserted and the CPU re-enters the
handler immediately after RTI (infinite loop).

**Timing:** ack must occur inside the handler body. No grace window.

**Note on $FF03:** `docs/project/conventions.md §16` mentions "read $FF03 or $FF92 as
applicable." $FF03 is the legacy PIA0 data port B (CoCo 1/2 MC6847 VSYNC
path). With $FF90 COCO=0 (CoCo3 GIME mode, karateka-coco3 default), $FF92
is the correct VBL ack register.

### 8.3 IRQ vs FIRQ Routing

`[ref: docs/ground-truth/SockmasterGime.md lines 52-53 — $FF93 FIRQENR identical bit layout]`

$FF92 (IRQENR) and $FF93 (FIRQENR) share the same bit layout. VBORD (bit 3)
in $FF92 routes VBL to the 6809 IRQ pin; VBORD in $FF93 routes VBL to FIRQ.
Setting VBORD in both simultaneously asserts both pins — misconfiguration.

**Canonical VBL-on-IRQ configuration:**
```
$FF90 = $6C    (IEN=1, FEN=0 — GIME IRQ enabled, FIRQ disabled)
$FF92 = $08    (VBORD only on IRQ)
$FF93 = $00    (no FIRQ sources)
```

**MAME verification:** With interrupt-driven increment, the frame counter
advances at exactly ~60 Hz (1 count per MAME VBL tick). The Lua harness can
capture successive `hal_frame_lo` reads to verify rate vs the polling stub.

---

### 8.4 GIME Register Read-Back Behavior

`[ref: commit d687e01 — R-vbl execution; $FF90 read-back observed during verification]`

**Observed fact:** Reading `$FF90` (GIME INIT0) returns hardware status, not
the last-written value. During R-vbl verification (X6), `HAL_time_init` writes
`$FF90=$6C` (IEN=1); reading `$FF90` immediately after returns `$1B`. The
same `$1B` is observed before any HAL_time_* code runs (confirmed by
gfx_init_precheck), establishing that this is a pre-existing hardware
characteristic in MAME's CoCo3 emulation, not a write failure.

**Verification implication:** Writes to `$FF90` cannot be confirmed via
post-write read-back. Use transitive inference from observable downstream
behavior instead. In R-vbl: counter advancing at ~60 Hz in a polling-free
spin loop proves IEN=1 was written — VBL fires at the correct rate, which
requires IEN=1 to have taken effect.

**Treat GIME configuration registers as write-only by default.** Whether
this read-back limitation applies to `$FF92`, `$FF93`, or other GIME
configuration registers is not yet confirmed for this project. When designing
verification steps for any GIME register write: do not rely on post-write
read-back as primary evidence. Verify via observable consequences —
interrupt behavior or counter rates. If read-back is required as a
verification step, first confirm empirically (via a dedicated harness read
before any writes) that the specific register returns the written value
rather than hardware status.

`[ref: docs/ground-truth/SockmasterGime.md — $FF90 register definition]`
`[ref: docs/project/interrupt-handling.md §8.1 — VBL enabling sequence]`
`[ref: R-boot investigation 2026-05-21 — runtime trace confirmed $FFF8=$FEF7, $FEF7=LBRA $010C, $010C=JMP hal_vbl_handler via MAME 0.281 -debug instruction trace]`

---

## 9. Reference IRQ Handler Skeleton

Reference body for the R-vbl VBL handler. Not deployed code — see §4 for
the install procedure into the $010C dispatch slot.

**6809 entry state:** IRQ automatically stacks full machine state
(CC, A, B, DP, X, Y, U, PC — 12 bytes). CC.I set by hardware on IRQ entry.
DP = 0 (karateka-coco3 invariant; HAL scratch $00-$1F in page 0).

```asm
* IRQ handler — VBL frame sync reference skeleton
* Install at $010C per docs/project/interrupt-handling.md §4.
*
* [ref: docs/ground-truth/SockmasterGime.md line 67 — reading $FF92 = ack]
* [ref: src/hal/coco3-dsk/time.s — hal_frame_hi ($10), hal_frame_lo ($11)]

real_irq_handler:
        lda     $FF92           ; ACK: read IRQENR; get source bitmap;
                                ;      reading clears all GIME IRQ pending flags
        bita    #$08            ; test VBORD (bit 3): did VBL fire?
        beq     irq_exit        ; no: spurious or other source — exit
        inc     <hal_frame_lo   ; VBL: increment frame counter lo byte
        bne     irq_exit        ;      no wrap: done
        inc     <hal_frame_hi   ;      wrap: carry to hi byte
irq_exit:
        rti                     ; restore stacked state; CC.I restored from
                                ; stacked CC (re-enables IRQ if main context
                                ; had CC.I=0 after andcc #$EF)
```

**Handler runtime constraint:** Handler must complete in less than one VBL
period (~1.4ms at 60Hz NTSC; ~1.79MHz 6809 → ~2500 cycles) to avoid
back-to-back re-entries. The current 9-instruction skeleton uses ~30 cycles;
future extensions with larger work bodies or multi-source dispatch must keep
this budget in view.

**Source identification note:** with only VBORD enabled in $FF92, the BITA
check is defensive but correct.

**Multi-source extension constraint:** The `lda $FF92` ack-read clears ALL
pending GIME IRQ flags simultaneously, not just VBORD. If future work enables
additional GIME sources (timer, HBORD, keyboard, serial, cartridge), the
handler must save the read value and dispatch on each pending bit in sequence.
Discarding bits after `bita #$08` loses other sources' pending state and
creates silent-drop behavior. For the R-vbl single-source configuration this
is moot; for any multi-source future this is load-bearing.

**HAL-internal boundary:** Handler is entirely HAL-internal. The public
surface is `HAL_time_vbl_wait` (unchanged contract). Post-R-vbl, its body
changes from counter-increment to counter-watch spin.

`[ref: docs/project/interrupt-handling.md §4 — handler install procedure]`
`[ref: docs/project/interrupt-handling.md §8 — ack mechanism, enable sequence]`

---

## 10. Per-Driver VBL Opt-In Sequence

`[ref: docs/project/open-questions.md Q001 — design decisions recorded here]`

Q001 established that VBL-driven behavior is per-driver opt-in.
HAL_sys_init and HAL_time_init handle hardware setup; the CPU unmask is
caller responsibility. This section documents the complete opt-in pattern.

### 10.1 What HAL_time_init does post-R-vbl (EXTRA-1 / E1.c)

HAL_time_init post-R-vbl extends from "zero counter only" to:

1. Zero the frame counter (DP `$10`/`$11` = hal_frame_hi/hal_frame_lo)
2. Patch the `$010C` dispatch slot with `JMP` to the real IRQ handler
   (see §4 for the install procedure: write `$7E` then 2-byte address)
3. Set `$FF90` IEN bit: write `$6C` (`$4C | $20`)
4. Write `$FF92=$08` (VBORD enable; all other GIME IRQ sources off)
5. Return CC.C clear. Does **not** call `andcc #$EF`.

CPU unmask is caller responsibility, separated from hardware setup so that
drivers can complete their own initialization before the first VBL fires.

`[ref: docs/project/interrupt-handling.md §8.1 — full enabling sequence]`
`[ref: docs/project/interrupt-handling.md §4 — handler install procedure]`

### 10.2 Complete per-driver opt-in sequence (Q001.1 / 1.c + Q001.4 / 4.b)

Every VBL-dependent driver executes this sequence after HAL_time_init and
before entering any loop that depends on VBL timing:

```asm
* VBL opt-in: unmask IRQ so the handler installed by HAL_time_init can fire.
* Preconditions:
*   HAL_sys_init complete (MMU programmed; $FF90=$4C initially; CC.I=1)
*   HAL_time_init complete (counter zeroed; handler at $010C; $FF90=$6C;
*     $FF92=$08; CC.I still 1 — HAL_time_init does not unmask)
*   All driver state initialized (handler may fire immediately after unmask)
*
* [ref: docs/project/interrupt-handling.md §8.1 — canonical config]
* [ref: docs/project/interrupt-handling.md §9 — handler skeleton]

        andcc   #$EF            ; clear CC.I — unmask IRQ; handler now fires
```

Drivers that omit this step remain masked and use FRAME-COUNTER STUB
behavior (counter advances only when HAL_time_vbl_wait is called).
Existing test drivers are in this category intentionally.

**Opt-in checklist for VBL-dependent drivers:**
1. Call `HAL_sys_init` (all drivers)
2. Call `HAL_time_init` (installs handler + configures GIME post-R-vbl)
3. Complete all driver-specific init before step 4
4. `andcc #$EF` — the opt-in step; easy to forget, symptom is silent failure
5. (Test harness step) Verify handler is firing at expected rate — see §10.3
   for the MAME Lua verification pattern.

**Silent-failure mode:** if step 4 is omitted, the handler is installed and
GIME is configured but IRQ never reaches the CPU. The counter does not
advance. No assertion fires. Detection: §10.3.

### 10.3 Verification pattern — silent-failure detection (Q001.2 / 2.a)

`[ref: docs/project/open-questions.md Q001 — Q001.2 counter-rate verification]`

After opt-in, verify the handler is firing at the correct rate by reading
`hal_frame_lo` (DP `$11`, CPU address `$0011`) in the MAME Lua harness.

```lua
-- Pseudocode (integrate into frame notifier; verify against project
-- harness pattern in tests/scripted/*.lua for exact implementation):
local start = mem:read_u8(0x0011)
-- <let N MAME frames elapse via screen:frame_number() or elapsed counter>
local finish = mem:read_u8(0x0011)
local delta = (finish - start) & 0xFF
-- Expected (interrupt-driven): delta ~= N
-- Failing (opt-in step 4 missing or handler not firing): delta near 0
```

**Three failure modes distinguished by delta:**
- `delta ~= N` — interrupt-driven, correct
- `delta` proportional to HAL_time_vbl_wait call rate — IRQ masked
  (opt-in step 4 missing)
- `delta == 0` — counter not advancing — HAL_time_init post-R-vbl
  extension not yet applied, or handler install failed

### 10.4 HAL_time_frame_count race fix (EXTRA-2 / E2.a, Option A)

`[ref: docs/project/open-questions.md Q001 EXTRA-2 — race issue and resolution]`

When the counter is interrupt-driven, a VBL IRQ firing between the two load
instructions in `HAL_time_frame_count` produces a torn 16-bit read.

**Fix — save/restore CC around masked read:**

```asm
HAL_time_frame_count:
        pshs    cc              ; save caller's CC (preserves their mask state)
        orcc    #$10            ; mask IRQ (CC.I=1) — no handler fire during read
        lda     <hal_frame_hi   ; D hi = frame counter high byte (atomic pair start)
        ldb     <hal_frame_lo   ; D lo = frame counter low byte (atomic pair end)
        puls    cc              ; restore caller's CC exactly
        rts                     ; D = 16-bit frame count
```

**Invariant:** HAL functions do not change caller's CC beyond documented
return values. `andcc #$EF` (without save/restore) would silently unmask a
caller that entered with IRQ masked. `pshs cc` / `puls cc` preserves
whatever mask state the caller had.

**Overhead:** ~14 cycles. HAL_time_frame_count is not called in inner loops;
this is negligible.

**Future work (M3):** A named `HAL_int_vbl_enable` function wrapping
`andcc #$EF` could reduce driver boilerplate and make missing opt-in
visible at the HAL boundary. Not required for R-vbl; flagged as potential
P3.1 API hardening.

`[ref: docs/project/interrupt-handling.md §9 — handler skeleton]`
`[ref: docs/project/interrupt-handling.md §8 — ack mechanism, enable sequence]`

---

## 11. PIA Interrupt Architecture (External IRQ Sources)

`[ref: commit ee3fa08 — R-boot root-cause investigation; PIA trap documented]`
`[ref: src/hal/coco3-dsk/sys.s — HAL_sys_init Step 2; PIA IRQ disable implementation]`

### 11.1 PIA IRQ Bypass of GIME IRQENR

CoCo3 has two Peripheral Interface Adapters (PIA0 at $FF00-$FF03, PIA1 at
$FF20-$FF23). Each PIA has two control registers (CRA and CRB) with IRQ enable
bits (bit 0 = CA1/CB1 IRQ, bit 1 = CA2/CB2 IRQ).

**Critical architectural fact:** PIA0 and PIA1 IRQ output lines OR directly onto
the 6809's IRQ pin, independently of GIME's IRQENR register ($FF92). Writing
$FF92=$08 selects VBORD as the only enabled GIME IRQ source — but PIA-generated
IRQs bypass GIME entirely and reach the CPU unconditionally.

**Consequence for interrupt acknowledgement:** The hal_vbl_handler reads $FF92
(GIME ack) to dismiss pending GIME IRQ flags. If the IRQ was generated by PIA
(not GIME), reading $FF92 (GIME ack) returns a status where the VBORD bit is 0;
the handler's BITA #$08 / BEQ exits without processing. The PIA interrupt source
remains asserted. After RTI, the CPU checks the IRQ line — still asserted by PIA
— and immediately re-enters the handler. This creates an infinite IRQ loop. The
6809 is level-sensitive on IRQ: as long as the pin is asserted, the interrupt
will retrigger at every instruction boundary when CC.I=0.

### 11.2 R-boot Root Cause (2026-05-21)

CoCo3 BASIC leaves PIA0's keyboard interrupt enabled (CA1 IRQ enable, $FF01
bit 0). When `HAL_gfx_init` runs its ~129ms frame-buffer clear loops with
CC.I=1, PIA0's keyboard scan timer fires and sets PIA0's interrupt flag. By
the time `boot.s` executes `andcc #$EF` (unmask IRQ), the pending PIA IRQ is
already waiting. The CPU takes the PIA interrupt before the `jsr broderbund_
scene` at $0226 can execute. Handler reads $FF92 — VBORD bit is 0 — BEQ exits
without processing. PIA still asserting → immediate re-entry. Result: 833,172
IRQ iterations in 30 seconds; `jsr broderbund_scene` never executed.

**Why vbl_irq_test_driver did not trigger the trap:** its path from binary load
to `andcc #$EF` is ~200 cycles (< 0.1ms), faster than PIA0's keyboard scan
interval (~1.8ms). R-boot was the first integration where HAL_gfx_init's masked
init duration exceeded the scan interval.

### 11.3 HAL_sys_init Responsibility

`HAL_sys_init` disables PIA IRQ on entry to the binary (before any driver can
execute `andcc #$EF`). Implementation: read-modify-write with mask $FC on
$FF01, $FF03, $FF21, $FF23. Clears CA1/CA2/CB1/CB2 IRQ enable bits on both
PIAs; preserves all other CR state (DDR access bit 2, CA2/CB2 output config
bits 3-5).

**Invariant:** Any driver calling `HAL_sys_init` before `andcc #$EF` is
protected against the PIA IRQ trap. This is guaranteed by the init-order
contract (HAL_sys_init = step 1, always first).

### 11.4 Keyboard Input and PIA Re-enable (R-p24+)

When keyboard input is needed (R-p24+), the PIA IRQ must be selectively
re-enabled. The correct architectural place is `HAL_input_init`. Before
re-enabling, a PIA interrupt handler must be installed. Re-enabling PIA CA1
IRQ without a handler routes PIA IRQ to the GIME VBL handler, which ignores
it (BITA #$08 → BEQ exit, VBORD not set). This is benign but creates
unnecessary interrupt overhead. The correct sequence:

1. Install PIA handler at an appropriate dispatch slot
2. Re-enable PIA CA1 IRQ: `lda $FF01 / ora #$01 / sta $FF01`
3. Unmask CPU if not already unmasked
