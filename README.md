# karateka-coco3

Karateka (Jordan Mechner, 1984, Apple IIe) port to the Tandy Color
Computer 3. Native 6809/6309 assembly. Faithful gameplay
reproduction.

Status: P1.0 (repository setup) in progress.

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

See `docs/karateka-coco3-design-v0.1.md` for the project design,
methodology binding, and phase plan.

Project follows Claude-Orchestrated Development Methodology v0.2.

## Building

Build infrastructure: see Phase 1 documentation (in development).
Currently P1.0 — repository structure only; no buildable artifacts
yet.

## Repository structure

See `docs/karateka-coco3-design-v0.1.md` Section 11.4 for the
canonical directory layout.

## License

[TBD]
