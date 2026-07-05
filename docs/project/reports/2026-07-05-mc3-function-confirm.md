# MC3 (INIT0 bit 3) full-function confirmation — exec history (2026-07-05)

Read-only doc confirmation producing `docs/project/mc3-function-confirm.md`: before
the banking layout locks high placement (draw slot $C000-$FBFF spans block 7 →
MC3=1 becomes load-bearing), confirm MC3's full function. No design, no code change;
prod unchanged (17978 B).

## The answer
MC3=1 has ONE documented function — the constant-$FEXX vector page — and prod ALREADY
sets it. Banking's MC3=1 is a NO-OP.
- AC-0 function (cited): GIME-ref(26-3334) "DRAM at $FEXX held constant"; Lomont p.60
  "MC3 1=Vector RAM at FEXX enabled"; SockmasterGime "1=RAM at FExx is constant
  (secondary vectors)". Vector Page = physical $7FE00-$7FEFF, MMU-independent.
- AC-1 anything-else: all three sources attribute ONLY the constant-page role; no
  other effect, no interaction with COCO/MMUEN/IEN/FEN/MC2/MC0-MC1. The one genuine
  interaction is part of the function: MC3=1 overrides RAM-or-ROM at $FE00-$FEFF
  (Lomont) — exactly the protection high placement needs. HS-3: docs explicit on the
  constant-page role, silent on others; "no other effect" = absence-of-contrary +
  per-bit independent layout, NOT a positive doc claim.
- AC-2 cost: 256 B ($FE00-$FEFF committed as vector page, not free RAM) — irrelevant
  to us (draw slot ends $FBFF, below it). No other cost. MC3=1 is also REQUIRED for
  interrupt-safe MMU swaps (bb64b22) — a benefit, not a burden.
- AC-3 reset/prod: hal.inc KCOCO3_INIT0_COCO3=$4C (MC3=1); gfx.s:144 writes $4C,
  HAL_time_init writes $6C (MC3 still 1); sys.s interrupt dispatch ALREADY depends on
  MC3=1 locking $FExx. Reset default = CoCo1/2 mode (vector page off); prod
  establishes MC3=1 immediately. => banking MC3=1 is a NO-OP.
- AC-4 implication: MC3=1 is cheap, idiomatic ($4C standard), single-function,
  near-zero-cost, ALREADY satisfied. PROCEED high placement; low-placement alternative
  not needed on MC3 grounds. Keep draw slot <= $FBFF (already true).

## Method
In-repo GIME sources (SockmasterGime.md; GIME_Reference_Manual.pdf compiled from
26-3334; Lomont_CoCoHardware.pdf) via pdftotext; prod state from grep of src/
($FF90 writes, hal.inc INIT0 constant, sys.s interrupt-dispatch commentary).

## Files
- docs/project/mc3-function-confirm.md (the confirmation).
