# Top-of-memory I/O space map — exec history (2026-07-05)

Read-only doc investigation producing `docs/project/io-space-map.md`: the exact
hardware-decode boundary at the top of the CPU address space, for the banking
layout design. Resolves the `$FF00`-vs-`$FC00` inconsistency the window-map report
(`eec7c50`) flagged. No design, no code change; prod unchanged (17978 B).

## The answer — boundary = $FF00
The hardware-decoded I/O page is the top 256 bytes, $FF00-$FFFF. RAM extends to
$FEFF. `$FC00` is NOT the boundary. Authorities (text-extractable, cited):
- Lomont (CoCo1/2/3 Hardware Programming v0.82), p.48: "All 3 CoCos have hardware
  interface registers in the 256 bytes from $FF00-$FFFF"; p.10 map row lists
  $FF00-$FFFF ("I/O, machine configuration, reset vectors") separately from
  $E000-$FEFF. PIAs at $FF00-$FF3F, disk/SCS $FF40-$FF5F, GIME $FF90-$FFBF,
  SAM $FFC0-$FFDF, vectors $FFE0-$FFFF.
- GIME_Reference_Manual.pdf (compiled from Tandy Service Manual 26-3334) §16:
  vectors $FFE0-$FFFF "always decoded by the ROM/I/O page regardless of MMU task
  register settings."
- SockmasterGime.md: GIME register + vector table; MC3 (INIT0 bit3) = "$FEXX held
  constant (secondary vectors)".

## $FF00-vs-$FC00 reconciled
The project memory-map.md ("$FC00-$FEFF Hardware I/O (PIA,SAM) 768B"; §4.11) and
the window-map report's "$FC00-$FFFF (1KB) I/O" are WRONG — a phantom 768B. The
PIAs are at $FF00-$FF3F; $FC00-$FEFF is RAM. Boundary = $FF00.

## Mode dependence
Boundary invariant. MC3 ($FF90 bit3): $FE00-$FEFF constant vector page vs MMU RAM
(RAM either way). ROM/RAM mode ($FFDE/$FFDF + MC1/MC0): $C000-$FDFF RAM vs ROM
(project = all-RAM). COCO bit ($FF90 bit7): no effect on the I/O decode.

## Banking implication
- Draw-fb safe top edge = $FDFF (leave $FE00-$FEFF for the constant vector page);
  current fb stops at $FBFF — conservative, 512B on the table.
- Block-7 usable RAM = $E000-$FDFF (7.5KB); I/O is only $FF00-$FFFF (256B), NOT
  1KB. Corrects the window-map report (block-7 RAM 7.5KB not 7KB; I/O 256B not 1KB).
- Vectors always-decoded: primary $FFF0-$FFFF hardware-decoded (GIME-ref §16) —
  always safe. Secondary $FEEE-$FEFF safe through MMU swaps IFF MC3=1 (constant
  page). Banking rule: keep MC3=1. Interrupts safe across swaps: YES.

## Tech-Ref availability finding (HS-3)
The two Tandy PDFs (Service Manual, Tech Ref Manual) are scanned images — no text
layer (pdftotext = 0 lines). Boundary fully pinned from the extractable authorities
(GIME ref = compiled from 26-3334; Lomont; SockmasterGime). No gap. Recommendation:
OCR the Tandy scans if a future task needs their raw text.

## Files
- docs/project/io-space-map.md (the map).

## Follow-up
- docs/project/memory-map.md has the $FC00-$FEFF-as-I/O error (§2 table, §4.9, §4.11)
  — correct it to $FF00-$FFFF (256B) I/O + $FC00-$FEFF RAM in a future edit.
