# Disk-boot / DECB-overlap — exec history (2026-07-05)

Two-phase read-only investigation producing docs/project/disk-boot-decb-overlap.md.
The harness direct-loads karateka.bin (bypassing DECB); this maps the risk and
PROVES it by booting through DECB in MAME. No fix; prod unchanged (17978 B).

## Verdict: M1 CONFIRMED by trace
A naive `LOADM"KARATEKA"` through real DECB HANGS during load; the code never loads.

## Phase 1 (doc/static)
- Boot mechanism: lwasm --decb => DECB-format (LOADM-compatible) binary, segments
  $0100+18/$0200+8238/$223E+9702, EXEC=$0200. Intended path = RSDOS floppy LOADM/EXEC
  (design doc), but the bootable .dsk is an UNBUILT M4 deliverable; no .dsk build /
  disk tooling in-repo. Currently harness-direct-load only.
- DECB map (disk/color-basic-unravelled, SockmasterGime): DP $00-$FF; RAM IRQ vectors
  $0100-$01xx (IRQ $FFF8->$FEF7->$010C; disk reader is interrupt-driven); screen
  $0400-$05FF; DBUF0 $0600 (main disk I/O buffer) + DBUF1 $0700 + FAT buffers + vars +
  FCBs ($0600-$0Exx); stack S=$7F2B (top of RAM, NOT in our footprint).
- M1 static: load image $0100-$4823 subsumes DECB's $0100 vectors + $0600-$0Exx buffers.

## Phase 2 (trace; authority)
- Reachable: disk11.rom in coco3.zip; imgtool builds the .dsk; `mame coco3 -ext fdc
  -flop1` boots DECB to OK ($A7D5, S=$7F2B, DP=$00, MMU 38-3F, TR=1).
- Instrumentation (HS-6): -autoboot_command and -autoboot_script are mutually
  exclusive; working method = Lua posts keys via manager.machine.natkeyboard:post()
  AND observes (verified POKE lands). [Jay's steer resolved the format.]
- Result: post LOADM"KARATEKA" -> disk I/O starts (DBUF0=directory entry
  "KARATEKABIN\x02", dbufW=512) -> PC FREEZES at $C60F (Disk BASIC ROM); code never
  loads ($0200=$00, $4000=$FF). PC loop $010C/$FEF7/$C60F.
- Mechanism (exact): segment 1 ($0100-$0111) loads FIRST, overwriting DECB's IRQ
  vector at $010C with our RTI stub; DECB's interrupt-driven disk reader's next IRQ
  ($FFF8->$FEF7->$010C) hits our stub -> read never completes -> hang, before $0200+
  ever loads. Trace confirms + refines static (fatal point = $0100 vectors, hit first).
- M2: UNREACHABLE via LOADM (M1 blocks the load). DECB-vs-harness state divergence
  captured (DP/S/MMU/TR) for when a real loader exists.

## Banking implication
M1 is about the LOAD footprint ($0100-$4823), which banking doesn't change
(framebuffers $8000-$FBFF are runtime BSS, not loaded) -> banking neither causes nor
worsens M1. But the whole placement (code + banking) is harness-only-validated; the
real boot path is unbuilt (M4). The M4 loader must avoid DECB low-RAM structures
during load, and the banking placement must be re-validated under it.

## Files
- docs/project/disk-boot-decb-overlap.md (the map + trace). Test .dsk/Lua throwaway
  (in C:\karateka-capture, outside repo, removed).
