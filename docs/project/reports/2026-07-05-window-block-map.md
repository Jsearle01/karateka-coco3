# Real window block-map — exec history (2026-07-05)

Read-only inspection producing `docs/project/window-block-map.md`: the verified
MMU block-by-block (0-7) map for the banking stage-2 layout design, resolving the
from-memory fit-contradiction. No design, no code change; prod unchanged (17978 B).

## The reconciliation (the point of the dispatch)
The from-memory accounting said the pieces don't fit, yet the build works. Two
wrong assumptions:
1. Framebuffers assumed 2×16KB (4 full blocks). REAL = $3C00 = 15360 B each:
   fb A $8000-$BBFF (1KB pad after), fb B $C000-$FBFF (stops at $FBFF).
2. Block 7 assumed fully pinned. REAL: the GIME hardware-decodes only $FC00-$FFFF
   (1KB I/O + vectors); $E000-$FBFF (7KB) is RAM = fb B's tail. fb B and I/O
   COEXIST in block 7 (fb below, I/O above). No contradiction.

## Pinned ends (Jay's catches, verified)
- Block 0 ($0000-$1FFF): ZP $00-$FF + stack $0100-$01FF (+code start). PINNED.
- Block 7 ($E000-$FFFF): only $FC00-$FFFF (1KB) pinned (hardware I/O + vectors);
  $E000-$FBFF is RAM.

## CLEAN_BUF profile
$4A00-$7E80 (13440 B, rows 0-167), read RESTORE-step-only (not whole-frame),
fully repositionable (proven by the $4400->$4A00 move), a candidate to bank itself.

## Budget
Fixed: code+HAL $0200-$483A, ZP/stack, I/O $FC00-$FFFF. Movable: CLEAN_BUF/FLIP_BUF.
Banking target: framebuffers = $8000-$FBFF (31KB contiguous, blocks 4-6 + block-7
RAM). A reclaimed hole falls $8000-$FBFF, CONTIGUOUS with the code below (ends by
$8000) — the code/scratch can grow straight up into it (Jay's contiguity goal met).

## Method
Real numbers from the build (karateka.bin 17978 -> code $0200-$483A), the source
(GFX_FB_A/B_BASE $8000/$C000, fb size $3C00, CLEAN_BUF $4A00, FLIP_BUF $7E80), and
the GIME ground-truth (memory-map §4.9 + SockmasterGime: GIME overrides $FF00-$FFFF;
$FC00-$FFFF hardware-decoded).

## Files
- docs/project/window-block-map.md (the map).
