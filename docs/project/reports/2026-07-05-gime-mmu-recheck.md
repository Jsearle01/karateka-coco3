# GIME MMU model re-check — banking stage-2 gate (2026-07-05)

Resolves the one open gate from the video-banking recon (`cc63f39`): can the CPU
reach the lower physical blocks on a **stock 128K** CoCo3? The recon flagged the
GIME doc's "56-63 on 128K" as inconsistent and said MAME didn't settle it. This
re-read answers it **from the doc alone**. **Verdict: the gate CLOSES — banking's
lower-bank mapping is a STOCK-128K feature. No 512K-forcing, no real-hardware
sourcing needed.** Read-only; prod unchanged (17978 B).

## The complete MMU model (AC-0, from SockmasterGime.md)
- **Two register sets (the two-task hypothesis — CONFIRMED):** `$FFA0-$FFA7` =
  MMU bank registers **Task 0**; `$FFA8-$FFAF` = **Task 1**. `$FF91` bit 0 **TR**
  selects which set is active (TR=0 → task 0, TR=1 → task 1). "The task register
  select which set of MMU bank registers to assign to the CPU's 64K workspace."
- **Each task assigns 8 × 8KB blocks to the CPU's 64K window.** Both draw from the
  same pool of physically-present blocks.
- **Physical block ranges:** the MMU section says "Valid bank ranges are **56-63 on
  128K**, 0-63 on 512K, 0-127 on 1Meg, 0-255 on 2Meg."

## The reconciliation — "56-63 on 128K" is a doc error (AC-2)
Three independent doc/arithmetic facts override the "56-63" statement:
1. **The doc's OWN VOFFSET section** ($FF9D/$FF9E): "On a 128K machine, the memory
   range is **$60000-$7FFFF**." $60000/8192 = page **48 ($30)**; $7FFFF/8192 = page
   **63 ($3F)**. So the doc itself places 128K RAM at **pages $30-$3F (48-63) =
   128KB.** This directly contradicts the MMU section's "56-63" ($38-$3F = 8 pages =
   **64KB**).
2. **Arithmetic:** 512K = 0-63 (64 pages). 128K is the top quarter = **16 pages =
   48-63 ($30-$3F)**, not 8 pages (56-63).
3. **The recon spike** (secondary): page $30 mapped + written at forced-128K.
→ The correct 128K valid range is **$30-$3F (48-63)**; "56-63" is an internal
typo in the MMU section, refuted by the same doc's VOFFSET section.

## The gate answer — physical reachability, not window-flexibility (AC-1, HS-2)
- **The gate needs physical reachability:** are the lower blocks ($30-$37)
  addressable by the CPU on 128K? **YES** — they ARE part of the 128K RAM (the
  doc's VOFFSET section puts 128K RAM at $60000-$7FFFF = pages $30-$3F), and a
  **single** MMU task ($FFA0-$FFA7) can map any physically-present block. So the
  CPU can map $30-$37 into a window block and draw there.
- **What the two-task feature actually provides — window-flexibility, NOT reach.**
  Tasks 0/1 are two *views* of the SAME physical RAM (both limited to the present
  blocks); toggling TR swaps the whole 64K window map in one register write. That's
  useful for banking *choreography* (a fast context-switch of the window), but it
  does **not** extend which physical blocks exist/are reachable. So Jay's two-task
  hypothesis is real and useful for stage-2, but it is **not** what closes the
  gate — the VOFFSET-stated 128K physical range is.

## Doc-vs-MAME (AC-2, HS-3)
The **doc closes the gate** (its authoritative VOFFSET section places 128K RAM at
$30-$3F). So the recon's MAME spike was **correct, not merely permissive** — it
agrees with the doc-derived range. A hardware-restriction question is normally
answered by hardware, but here the doc's own VOFFSET statement is the authority and
is unambiguous, so **no real-hardware second-sourcing is required.**

## Stage-2 gate resolution (AC-3)
**STOCK-128K FEATURE — gate CLOSES.** Framebuffer (or code/content) banking's
map-in-to-draw works on a stock 128K machine: the lower bank $30-$3F is CPU-
mappable by either MMU task, and VOFFSET can display from any of $60000-$7FFFF.
The ~30KB window reclaim is available without requiring 512K. The two-task
registers are an available tool for stage-2's map-switch choreography.

## Files
- None committed to prod (read-only doc re-check). No spike this stage (the doc
  resolved it).

## Candidate (report-noted, `seeds/` not established)
"GIME 128K MMU range: the doc's VOFFSET '$60000-$7FFFF on 128K' (= pages $30-$3F)
overrides the MMU section's inconsistent '56-63'; two tasks = window-flexibility
not physical reach; banking is a stock-128K feature."
