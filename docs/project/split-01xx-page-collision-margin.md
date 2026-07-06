# Split $01xx-page collision margin — invariant VERIFIED (measured)

**Status:** RESOLVED-SAFE (measured, not assumed). Latent-corruption risk if the margin
is ever exhausted — re-measure when the content or the interrupt/disk-during-play model
changes (see Caveats). **Component:** boot memory layout, the $0100-$01FF page, as used by
the loaded game (Build #3b-2+).

## The layout
The $0100-$01FF page is used from BOTH ends:
- **Low end ($0100 up):** initialized DATA + interrupt-dispatch vectors the boot loads —
  real bytes present at entry. This is why the payload correctly starts at $0100 (anchored
  on this data), not a wasteful load of dead stack scratch.
- **High end ($01FF down):** the runtime STACK (6809 stack grows DOWN; `lds #$01FF` in
  boot.s). Faithful to the 6502 original's $01xx stack-page convention.

They grow toward each other from opposite ends of the same 256-byte page; code proper
starts at $0200. **Invariant:** safe ONLY while the low-end data and the downward stack
never meet — else SILENT corruption (stack overwrites data / a data write corrupts a
frame), no error, fails downstream.

## Measurement (verify-before-assume, per CLAUDE.md §2)
`tests/scripted/stack_margin_probe.lua` — write tap on $0100-$01FF (records the lowest
address the stack actually touches, incl. interrupt frames) + S-register sampling, over a
direct-placement run of scenes 1-4 (~35 s, ~92k stack writes):

| quantity | measured |
|---|---|
| Low-end **DATA high-water** (game seg1 = the dispatch block, from the DECB segments) | **$0111** |
| **Deepest stack WRITE** (lowest $01xx addr written, incl. IRQ frames) | **$01E7** |
| Deepest S register sampled (coarser cross-check) | $01F3 |
| Game IRQ-vector install writes at $010C-$010E (excluded — not stack) | 3 |
| **MARGIN = $01E7 − $0111** | **214 bytes → SAFE** |

Write histogram: **all** stack writes in $01E0-$01FF (89,172 in $01F0-$01FF; 3,385 in
$01E0-$01EF); **nothing below $01E7**. Data ($0100-$0111) and stack ($01E7-$01FF) are
separated by ~214 empty bytes — no near-collision.

## Why the margin is comfortable (mechanism, not luck)
- **Single-level interrupts.** The game masks all interrupts except the VBL IRQ (P3.1),
  which pushes one ~12-byte 6809 frame. No nested/stacked interrupts on the game stack →
  the stack depth is call-nesting + one IRQ frame, and that bottoms out at $01E7.
- **The disk NMI is on a DIFFERENT stack.** The "sharp one" the concern flagged — the
  disk-read NMI chain — fires during the LOAD, on the **bootloader's $7F00 stack**, NOT the
  game's $01xx stack. Scenes 1-4 run entirely from RAM (no disk reads during play), so no
  disk NMI ever lands on $01xx.

## Caveats — when to RE-MEASURE
1. **Deeper gameplay content.** This measured scenes 1-4 (the current prod image). The
   combat/throne-fight paths (not in this image) may nest deeper — re-run the probe when
   that content lands; 214 bytes is ample but not proven for unmeasured code.
2. **Disk-during-play (streaming) — PRE-CLEARED (measured 2026-07-06).** The disk-access
   path's worst-case stack DEPTH was measured base-independently (`tests/scripted/
   disk_stack_depth_probe.lua`, worst-case 8-track m=1 read, ≥2 runs): **D = 14 bytes**
   below `disk_read_range` entry = a **12-byte NMI frame + 2-byte synchronous call depth**
   (they ADD — the NMI fires HALT-frozen in the read loop, one `jsr` level deep; NMIs do
   NOT stack, each RTIs before the next). Prediction if the disk NMI+read shared the `$01xx`
   game stack: game worst (24 B, reach $01E7) + disk (14 B) = **38 B**, vs the **238 B**
   budget ($01FF−$0111) → reaches ~$01D9, **~200 B clear of the $0111 data floor**.
   **Streaming-during-play is PRE-CLEARED on this page** — no dedicated disk stack required
   (the bootloader's $7F00 pattern remains available but is unnecessary for the margin).
   Re-measure only if a future streaming design nests `disk_read_range` far deeper in the
   game's call tree than the measured 24-B game worst.
3. **DECB LOADM front-end (next build).** Resolve alongside the LOADM-vs-$0100-$01FF
   contention (whether DECB/BASIC touches this page during LOADM) — same 256-byte page.

## Disposition
Not a blocker (loader runs, renders, byte-identical). The split-$01xx layout is
**verified collision-safe for the current scope** (214-byte margin, single-level VBL IRQ,
disk NMI on the separate bootloader stack). Re-measure per the caveats before extending to
gameplay content or disk-during-play.
