# 64KB window — real MMU block map (banking stage-2 input)

**Read-only inspection.** The verified block-by-block (0-7) map of the current
prod build, the two pinned ends, the framebuffer/block-7 coexistence (the piece
the from-memory accounting couldn't close), and the movable/fixed budget. All
numbers are from the current build (`karateka.bin` 17978 B, loads $0200) + the
GIME ground-truth — NOT carried estimates. **No design, no code change.**

## The block map (8 × 8KB MMU blocks)
| Blk | CPU range | Contents (real) | Status |
|-----|-----------|-----------------|--------|
| **0** | $0000-$1FFF | ZP/DP `$0000-$00FF` + stack `$0100-$01FF` (SP init $01FF) + code start `$0200-$1FFF` | **PINNED** (CPU touches ZP+stack every instruction) |
| 1 | $2000-$3FFF | code (engine + HAL + scene-5) | fixed (code) |
| 2 | $4000-$5FFF | code end `$483A` · margin · `CLEAN_BUF` start `$4A00-$5FFF` | fixed code + movable scratch |
| 3 | $6000-$7FFF | `CLEAN_BUF` `$6000-$7E80` · `FLIP_BUF` `$7E80-$7FD7` · slack | movable scratch |
| 4 | $8000-$9FFF | **framebuffer A** first half | fb (bankable) |
| 5 | $A000-$BFFF | framebuffer A second half `$A000-$BBFF` + pad `$BC00-$BFFF` (1KB) | fb (bankable) |
| 6 | $C000-$DFFF | **framebuffer B** first half | fb (bankable) |
| **7** | $E000-$FFFF | framebuffer B tail `$E000-$FBFF` (7KB RAM) + **I/O `$FC00-$FFFF`** (1KB) | **PARTIAL** — fb RAM below, I/O pinned above |

Code = `$0200-$483A` (17978 B). Framebuffers = **$3C00 = 15360 B each** (not 16KB).

## The pinned ends (HS-3)
- **Block 0 — PINNED.** ZP ($00-$FF, direct-page) + stack ($0100-$01FF) are
  touched constantly; unmapping block 0 loses the CPU's working state. (Code also
  starts here, but the pin reason is ZP/stack.)
- **Block 7 — PARTIALLY pinned.** Per the GIME doc, the CoCo3 **hardware-decodes
  `$FF00-$FFFF`** (GIME/PIA/MMU registers + the 6809 vectors) "regardless of the
  MMU," and `$FC00-$FEFF` is peripheral I/O — so **`$FC00-$FFFF` (1KB) is pinned
  I/O**, unclobberable. The rest of block 7, **`$E000-$FBFF` (7KB), is ordinary
  RAM** (it currently holds framebuffer B's tail).

## The framebuffer / block-7 reconciliation (HS-2 — the fit contradiction)
The from-memory accounting hit "the pieces don't fit" because it assumed **2×16KB
framebuffers** (four full blocks 4-7) **and** a **fully-pinned block 7** — which
collide (fb B needs block 7; I/O owns block 7). **Both assumptions are wrong:**
1. The framebuffers are **$3C00 = 15360 B each**, not 16KB. fb A = `$8000-$BBFF`
   (leaves a 1KB pad `$BC00-$BFFF`); fb B = `$C000-$FBFF` (stops at `$FBFF`).
2. The GIME overrides **only `$FC00-$FFFF`** (1KB). fb B's tail `$E000-$FBFF`
   (7KB) is real RAM sitting **below** the I/O in block 7.
So fb B and the I/O **coexist in block 7** (fb below `$FC00`, I/O at/above it) —
the layout fits with no contradiction once the real 15360-B fb size and the
1KB-only block-7 pin are used. `[memory-map §4.9; GIME-RM §18; SockmasterGime $FF9x/$FFAx]`

## CLEAN_BUF profile (AC-3)
- **Size/position:** 13440 B (rows 0-167), `$4A00-$7E80` (blocks 2-3). Placed
  there (below `$8000`) so scene 5 coexists with the prod boot code.
- **Usage:** read **only during the dirty-rect RESTORE step** of each frame
  (`pr_copy_from_clean` / the `restore_right_doorway` + cell-post reads), NOT
  continuously — it is dead during the blit/present/flip. Written once per stage
  switch (`g2_snapshot_clean`).
- **Movability:** fully **repositionable** — it's a scratch buffer at a chosen
  `equ` address, pinned by nothing (the relocation from `$4400`→`$4A00` in the
  boot integration already proved it moves freely). Because it's restore-only, it
  is also a candidate to be **banked itself** (mapped in only for the restore step).

## Banking budget — blocks 1-6 (+ block-7 RAM)
- **Fixed (must stay mapped):** code+HAL `$0200-$483A` (block 0 + block 1 + block 2
  low); ZP/stack (block 0); the I/O `$FC00-$FFFF` (block 7 top).
- **Movable scratch:** `CLEAN_BUF` (blocks 2-3, restore-only) + `FLIP_BUF` (block 3).
- **The banking target (~30KB):** framebuffers = blocks 4, 5, 6 **plus** block 7's
  RAM `$E000-$FBFF` = **`$8000-$FBFF` = one contiguous 31KB region** (minus the
  1KB block-5 pad), displayed via VOFFSET, mapped in only to draw (stage-1 recon).
- **Where a reclaimed hole falls (Jay's contiguity goal):** the freed framebuffer
  region `$8000-$FBFF` sits **immediately above the code/scratch region** (which
  ends by `$8000`). So banking the framebuffers opens a **contiguous** hole from
  the code's `$483A` (or from `$8000`) up to `$FBFF` — the code/scratch can grow
  straight up into it. The only interruption is the pinned I/O at `$FC00-$FFFF`
  (already the top edge), so the contiguous run is `$8000-$FBFF` (31KB) with the
  1KB I/O beyond it. **Contiguity with the code is feasible.**

## Read-only confirm
No code change; `build/karateka.bin` unchanged (17978 B). The layout DESIGN
(how many fb blocks to bank, the map-swap choreography, whether to also bank
CLEAN_BUF) is the stage-2 step that consumes this map — not done here.
