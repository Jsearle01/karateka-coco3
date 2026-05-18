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

`[ref: docs/SockmasterGime.md §1 — Interrupt Vectors table]`

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

`[ref: docs/SockmasterGime.md — $FF90 bit 3 MC3]`

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
`[ref: docs/open-questions.md Q001 — interrupt discipline migration plan]`

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

`[ref: docs/SockmasterGime.md §1 — Interrupt Vectors table]`
`[ref: 6502-6809-conversion-patterns/shared/G-methodology/G.3-coco3-platform-assumptions.md — G.3.3 exemplar]`

---

## 6. P3.1 Migration Plan (Preview)

When the VBL interrupt is needed for frame synchronization (P3.1):

1. Write a real `irq_handler` routine.
2. Install it at $010C–$010E per §4 procedure above.
3. Revisit the `ORCC #$50` global mask in `HAL_sys_init` and the test
   driver's entry mask — these must be relaxed to allow IRQ to fire.
4. Ensure `HAL_time_vbl_wait` uses the interrupt rather than polling.

The `FIRQ` and `IRQ` distinction: the CoCo3 GIME's VSYNC can be routed
to either FIRQ or IRQ via $FF93 (FIRQENR). Current plan routes VBL to IRQ
(conventional CoCo3 programming). Verify against $FF93 documentation when
implementing.

`[ref: docs/open-questions.md Q001 — full migration question]`
`[ref: docs/conventions.md — interrupt mask policy section]`

---

## 7. Cross-References

- `src/hal/coco3-dsk/sys.s` — HAL_sys_init implementation; dispatch block
- `docs/conventions.md §2` — DP $13 sys_init_cc_mask allocation
- `docs/conventions.md` — Interrupt mask policy section
- `docs/memory-map.md §2` — Dispatch block within stack region
- `docs/open-questions.md Q001` — Interrupt discipline migration
- `docs/SockmasterGime.md §1` — Authoritative $01xx address table
- `6502-6809-conversion-patterns/shared/G-methodology/G.3-coco3-platform-assumptions.md`
  — G.3.3 exemplar (incident report for this issue class)
