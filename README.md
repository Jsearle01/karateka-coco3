# karateka-coco3

Karateka (Jordan Mechner, 1984, Apple IIe) port to the Tandy Color
Computer 3. Native 6809/6309 assembly. Faithful gameplay
reproduction.

Status: P2 IN PROGRESS — P3.1 COMPLETE (R-vbl + R-boot); INT-1 in progress (R-p24 remaining).

## Reference oracle

Apple II source: see `../karateka_dissasembly_claude/` (sibling
directory). That repository contains the verified Apple II
disassembly that this port consumes as its source-of-truth.

Note: the upstream repo name contains a typo ("dissasembly")
preserved for git history stability.

## Pattern libraries

Shared porting patterns: `../6502-6809-conversion-patterns/`
Disassembly methodology patterns: `../apple2-disasm-patterns/`

Both consumed by path/URL reference, not git submodule.

## Methodology

See `docs/project/karateka-coco3-design-v0.1.md` for the project design,
methodology binding, and phase plan.

Project follows Claude-Orchestrated Development Methodology v0.2.

## Building

Build: `make` from repo root. Produces `build/karateka.bin`. See `docs/project/milestones.md` for phase status.

## Repository structure

See `docs/project/karateka-coco3-design-v0.1.md` Section 11.4 for the
canonical directory layout.

## License

[TBD]
