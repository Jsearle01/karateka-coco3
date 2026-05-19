# karateka-coco3 — Open Questions

This file tracks design questions and methodology uncertainties that
are acknowledged but not yet resolved. Format follows the karateka-
disasm Appendix A template.

---

## Q001 — Interrupt discipline migration

**Status:** CLOSED (2026-05-19; X4)  
**Priority:** Medium  
**Opened:** 2026-05-16

**Context:**

P2.3a.0 establishes a three-layer interrupt mask approach for the
CoCo3 bare-metal transition:

1. Test driver global `ORCC #$50` at entry
2. `HAL_sys_init` internal `ORCC #$50` (belt-and-suspenders)
3. Dispatch block RTI stubs at $01xx (safe no-op landing)

This is acceptable for P2.3a.0 because no interrupt-driven behavior
exists. The VBL interrupt (needed for frame sync in P3.1) is not yet
implemented; GIME IRQ/FIRQ sources are not yet enabled.

**Refs consulted:**

- P2.3a.0-plan-v3 §11 — interrupt mask policy design
- `docs/conventions.md` — "Interrupt mask policy" section
- `docs/interrupt-handling.md` — full dispatch documentation
- `docs/SockmasterGime.md §1` — three-level dispatch; $01xx address table
- `6502-6809-conversion-patterns/shared/G-methodology/G.3-coco3-platform-assumptions.md`
  G.3.3 exemplar — vector install incident

**Question:**

When real interrupt handlers (P3.1 VBL at minimum; future disk and
keyboard) are implemented, the global mask discipline must transition
to per-routine mask/unmask. Specifically:

1. What is the precise migration sequence for installing a real IRQ
   handler at the Sockmaster-correct $010C slot without disrupting
   existing behavior?
2. How is silent-failure avoided (real handler installed at $010C but
   `ORCC #$50` still active, so IRQ never fires)?
3. Should `HAL_sys_init` stop masking on return once a real handler
   exists, or keep masking and let the caller un-mask?
4. The test driver's `ORCC #$50` at entry — should it be removed when
   real interrupt behavior is tested, or does it remain for test
   isolation?

**Tried:**

Layered mask + dispatch block RTI stubs prevent firing in test context.
Not a long-term solution.

**Resolution criteria:**

All of the following:
- Test driver's entry `ORCC #$50` removed (or justified if kept)
- `HAL_sys_init` mask policy revisited for the interrupt-enabled era
- First real handler installed at Sockmaster-correct $01xx address
  (e.g., IRQ handler at $010C per `docs/interrupt-handling.md §5`)
- `ANDCC #$AF` (unmask) verified to allow that handler to fire in MAME
- VBL interrupt confirmed working (frame counter advances per interrupt,
  not per polling)

**Resolution (closed 2026-05-19 — X4 / D4.a):**

Decisions per sub-question:

**Q001.1 — Migration sequence: per-driver opt-in (1.c).**
Existing drivers unchanged. Drivers that need real-VBL call the explicit
three-step enable sequence after HAL_time_init. No global mask change.
`[ref: docs/interrupt-handling.md §10 — per-driver opt-in sequence]`

**Q001.2 — Silent-failure avoidance: counter-rate verification (2.a).**
Capture `hal_frame_lo` via MAME Lua harness over N frames; verify counter
advances at ~60 Hz independent of HAL_time_vbl_wait calls.
`[ref: docs/interrupt-handling.md §10.3 — verification pattern]`

**Q001.3 — HAL_sys_init mask policy: keep ORCC #$50 in HAL_sys_init (3.b).**
Rationale: HAL init functions preserve caller's mask state by convention —
they do not change CC beyond documented return values. Explicit unmask is
per-driver responsibility. HAL_sys_init behavior is unchanged post-R-vbl.

**Q001.4 — Test driver entry mask: existing drivers as-is (4.c); R-vbl
driver uses explicit andcc #$EF (4.b).**
Existing test drivers retain ORCC #$50 at entry. VBL-dependent drivers
follow the opt-in sequence per §10.

Additional design decisions surfaced by X2/X3:

**EXTRA-1 — VBL-source configuration in HAL_time_init (E1.c).**
HAL_time_init extended to: zero counter, patch $010C with JMP to real
handler, write $FF90=$6C (IEN=1), write $FF92=$08 (VBORD). Does NOT
unmask CPU; that is caller responsibility.
`[ref: docs/interrupt-handling.md §10.1]`

**EXTRA-2 — HAL_time_frame_count race fix (E2.a, Option A).**
`pshs cc` / `orcc #$10` / load both bytes / `puls cc`. Preserves caller's
prior mask state. ~14-cycle overhead; not in inner loops.
`[ref: docs/interrupt-handling.md §10.4]`

**EXTRA-3 — Multi-source future readiness: single-source per §9 (E3.a).**
§9 multi-source-extension constraint note covers what to watch for when
a second GIME IRQ source is enabled.
