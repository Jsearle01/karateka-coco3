# Session: 2026-05-13 — design doc Section 6.6 (Reference Discipline)

## What landed

karateka-coco3-design-v0.1.md updated:
- Section 6.6 added: Reference Discipline
  - 6.6.1 Reference document inventory (11 docs)
  - 6.6.2 Citation format ([ref: short-tag section])
  - 6.6.3 Absent-reference surfacing ([no-ref: ...])
  - 6.6.4 Conflict resolution protocol
  - 6.6.5 Calibration phase emphasis
  - 6.6.6 Cross-references to pattern repos
- Gate K.1.11 added (Section 5.12): Reference Discipline for
  CoCo3 / 6809 content

Pattern definition lives in
6502-6809-conversion-patterns/shared/G-methodology/
G.1-reference-discipline.md (consumed by path/URL reference
per Gate K.1.10).

## Reference inventory

Eleven authoritative documents in docs/:
- 6809 / 6309 CPU: MC6809 manual, 6809 Assembly Language
  Programming (Leventhal)
- CoCo3 hardware: CC3-TR, CC3-SM, Lomont, GIME-RM,
  Sockmaster-GIME
- BASIC ROMs (boot environment context): CB/EB/SEB/DB
  Unravelled

Actual filenames in docs/:
- 6809_Assembly_Language_Programming_by_Lance_Leventhal.pdf
- Color Computer 3 Service Manual (Tandy) (1).pdf
- Color Computer Technical Reference Manual (Tandy).pdf
- GIME_Reference_Manual.pdf
- Lomont_CoCoHardware.pdf
- MC6809-MC6809E 8-Bit Microprocessor Programming Manual (Motorola Inc.) 1981.pdf
- SockmasterGime.md
- color-basic-unravelled.pdf
- disk-basic-unravelled.pdf
- extended-basic-unravelled.pdf
- super-extended-basic-unravelled.pdf

## Calibration tracking

Task 5 of calibration phase complete.

## Next session

P1.3 (HAL contract) — now bound by reference discipline.
First HAL contract decisions need citations per Section 6.6.
