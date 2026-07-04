# 64KB-window memory audit — exec history (2026-07-04)

Produced `docs/project/memory-window-audit.md`: the resident map of the 64KB CPU
window + a ranked reclaim table + the banking-proximity answer. Read-only audit
(no code change; prod unchanged 17978 B). Same lifetime-rigor as the ZP map,
applied to code/scratch/framebuffers.

## Why now
The boot integration showed the **64KB CPU window** is the real ceiling (not
128KB): code 18K + scratch 13.8K + framebuffers 30K, **454-byte margin**. Before
the gated 512KB-banking decision, this audit measures how much is reclaimable in
the current window and how near banking actually is.

## Method
- Generated a prod listing (`lwasm --list`), read the segment addresses to build
  the resident ledger (boot code / dead-in-boot code / live code+content /
  scratch / framebuffers).
- HAL caller-check: grepped the PROD scene-5 files (not sandbox drivers) for
  `jsr HAL_gfx_blit_*` — the same call-graph rigor as the ZP-map `$52-$54`.
- Overlay-by-lifetime: verified which scratch/code is dead when.

## Findings
- **HAL primitives (opaque/masked/stencil): all LIVE in booted scene 5** (shadow,
  set-dressing, feet, Akuma/head punches) → 0 build-excludable. Caller-checked.
- **Scene-5 scratch already phase-shares** (CLEAN re-snapshotted throne→cell) → no
  intra-scene overlay reclaim.
- **Dead boot code $044A-$1A88 = 5.6 KB** (broderbund+intro+scene4), verified dead
  in scene 5 → a cross-scene overlay slot for FUTURE scene code; but scene 5's
  own CLEAN (13.4 KB) is larger, so it can't use it.
- **Snapshot width-trim ~1.2 KB** (80→~73 B/row; restores span byte20-72),
  moderate risk (offset math). ESTIMATE.
- **Content RLE helps DISK, not the resident window** (must decompress to blit);
  **mirror already deduped** (runtime make_flipped); single-buffer would free 15K
  but breaks animation (non-option).

## Banking-proximity
Current free ~454 B. Low-risk in-window reclaim ~1.2 KB. A comparable next scene
(~10 KB like scene 5) exceeds even the margin + trim + dead-boot slot (~7.3 KB
combined, high-risk). **Banking is effectively imminent — the next comparable
scene forces it.** Recommended path: a scene-overlay / content-banking
architecture (the dead-boot region already demonstrates the overlay model) — the
512KB decision, Jay's gated call.

## Files
- `docs/project/memory-window-audit.md` — the audit (new).

## Notes
- `docs/project/memory-map.md` already exists (P1.6 architectural map); the audit
  is a separate file to avoid clobbering it.
- `seeds/karateka/` not established → candidate report-noted, not written.
