# karateka-coco3 — 64KB CPU-window memory audit (resident map + reclaim)

**Read-only audit.** The lifetime-reasoning the ZP map applied to the direct
page, applied to the **64KB CPU window** (code + scratch + framebuffers). Answers:
**how much can we free now** (no banking), and **how near is 512KB banking.**

> This is an ANALYSIS doc — it reports reclaim opportunities, it does NOT
> implement them (each reclaim is a separate gated dispatch with its own
> regression). Compression/dedup figures are **estimates**, flagged.
> (Naming: `docs/project/memory-map.md` already exists as the P1.6 architectural
> map; this reclaim audit is a separate file to avoid clobbering it.)

## 1. The 64KB window — resident ledger (measured from the prod listing)

| CPU range | Size | Lifetime | Contents |
|-----------|------|----------|----------|
| $0000-$01FF | 512 B | durable | DP + stack |
| $0200-$044A | 586 B | durable | boot entry + the linear scene-1..4 controller |
| **$044A-$1A88** | **5694 B** | **DEAD after scene 4** | broderbund + intro (scene 2/3) + scene 4 scroll code |
| $1A88-$483A | 11698 B | durable in scene 5 | HAL + sprite_engine + princess_controller + scene-5 stages/actors/content |
| $483A-$4A00 | 454 B | **free** | the margin |
| $4A00-$7E80 | 13440 B | scene-5 scratch | `CLEAN_BUF` (backdrop snapshot, rows 0-167) |
| $7E80-$8000 | 384 B | scene-5 scratch | `FLIP_BUF` (mirror flip) |
| $8000-$BBFF | 15360 B | durable | framebuffer A |
| $C000-$FBFF | 15360 B | durable | framebuffer B |
| $FC00-$FFFF | 1024 B | hardware | I/O + vectors |

**Resident WHEN (by phase):**
- **Throne phase:** all scene-5 code + content live; `CLEAN_BUF` = throne backdrop
  (+ guard + eagle body); framebuffers cycling. Boot code $044A-$1A88 already dead.
- **Cell phase:** same code; `CLEAN_BUF` **re-snapshotted** to the cell backdrop
  (`g2_snapshot_clean` at the transition) — the *same* buffer, reused.
- **The ceiling is the 64KB window, not 128KB:** ~62.3 KB used, **~1.7 KB free**
  total (454 B code margin + the DP/stack slack). The 454-byte code→scratch margin
  is the hard one.

## 2. Reclaim opportunities

### (A) Dead-in-boot HAL primitives — CALLER-CHECKED (AC-1, HS-2): 0 reclaim
Grepped the prod call path (booted scene 5, not the sandbox drivers):
| Primitive | Called by (prod) | Verdict |
|-----------|------------------|---------|
| `HAL_gfx_blit_sprite_opaque` | `princess_controller` (shadow), `scene5_throne_stage` (opaque set-dressing) | **LIVE** |
| `HAL_gfx_blit_sprite_masked` | `scene5_akuma` (feet, pauldron) | **LIVE** |
| `HAL_gfx_blit_stencil_punch` | `scene5_akuma` (Akuma silhouette + head punches) | **LIVE** |
All three are live in the booted scene → **none are build-excludable.** (Caller-
checked, not assumed — a stale comment ≠ a caller, per the ZP-map `$52-$54` lesson.)

### (B) Overlay-by-lifetime (AC-2, HS-3)
- **Scene-5 scratch is ALREADY phase-shared.** `CLEAN_BUF`/`FLIP_BUF` serve BOTH
  the throne and cell phases (CLEAN is re-snapshotted at the transition). So there
  is **no throne-vs-cell overlay reclaim left inside scene 5** — it already overlays.
- **The dead boot code ($044A-$1A88, 5.6 KB) is the cross-scene overlay slot.**
  Verified non-overlapping lifetime: `scene5_run` never calls
  broderbund/intro/scene4; those run only before scene 5. So that 5.6 KB is
  reusable by a FUTURE scene's code (load scene N into the dead-boot region).
  **But** scene 5's own `CLEAN_BUF` (13.4 KB) is *larger* than the dead region and
  is a single contiguous buffer, so it **cannot** move into the 5.6 KB slot. →
  The dead-boot slot buys nothing for scene 5; it is **future-scene runway.**

### (C) Snapshot width-trim (AC-3) — ~1.2 KB, ESTIMATE
`CLEAN_BUF` snapshots the **full 80-byte width** × 168 rows. The restores read a
moving dirty-rect that spans ~byte 20-72 (princess walk byte20-61, doorway post
byte61-72, eagle head byte43-52). Trimming the stored width to ~73 bytes/row saves
~7 B × 168 = **~1.2 KB**. Risk: MODERATE — `pr_copy_from_clean`'s offset math
(`row*80+col`) becomes `row*W+col`, and the cell-post restore constant changes;
off-by errors → garbage restore. (Estimate; not measured until implemented.)

### (D) Content compression / dedup (AC-3) — ~0 WINDOW reclaim
- **RLE on the ~11.6 KB static content:** the backdrops have long index-0 (black)
  and solid-color runs → RLE would shrink them on **disk**. But content must be
  **decompressed to be blitted**, so the *resident* window footprint is unchanged
  (or worse, +decompressor +buffer). **RLE helps disk size, not the 64KB window.**
- **Mirror dedup:** the port uses the runtime mirror idiom (`make_flipped` →
  `FLIP_BUF`), so mirrored sprites are stored **once** and flipped on the fly —
  **already deduped**; no double-storage to reclaim.
- **Single-buffer framebuffers** would free 15 KB but **breaks double-buffering**
  (tearing during the animation) — a **NON-OPTION** for scene 5. Listed for
  completeness.

## 3. Ranked reclaim table (AC-4, HS-5)

| # | Opportunity | Window bytes freed | Risk / effort | Needs banking? |
|---|-------------|--------------------|---------------|----------------|
| 1 | **Content banking (512KB)** — move ~11.6 KB static content to the lower 64 KB, stream via the $4000 window | **~11.6 KB** (off the window) | HIGH (banking infra) | **YES — this IS the decision** |
| 2 | **Scene-overlay of the dead-boot slot** — future scene code loads into $044A-$1A88 | up to **5.6 KB** (future scenes) | HIGH (layout/loader) | no (but same infra as banking) |
| 3 | **Snapshot width-trim** (80→~73) | **~1.2 KB** (est.) | MODERATE (offset math) | no |
| — | Single-buffer framebuffers | 15 KB | breaks animation — NON-OPTION | no |
| — | Content RLE | 0 window (disk only) | — | no |
| — | Mirror dedup | 0 (already deduped) | — | no |
| — | Dead-in-boot HAL exclude | 0 (all live) | — | no |

## 4. Banking-proximity answer

- **Current free window: ~454 B** (the code→scratch margin).
- **Low-risk in-window reclaim available now: ~1.2 KB** (snapshot width-trim). The
  5.6 KB dead-boot slot is real but high-effort and only helps *future* scene code
  (not scene 5's oversized CLEAN).
- **Scene 5 added ~10 KB (code+content) to the window.** A comparable next scene
  needs ~10 KB — which **exceeds** the 454 B margin *and* the ~1.2 KB trim *and*
  even the 5.6 KB dead-boot slot combined (~7.3 KB < ~10 KB, and that assumes the
  high-risk overlay).
- **Conclusion: banking is effectively imminent — the next comparable scene forces
  it.** In-window reclaims buy at most a fraction of one scene, not durable runway.
  The scalable path is a **scene-overlay / content-banking architecture** (load
  each scene into a shared slot + stream content from the lower 64 KB) — which is
  the 512KB decision. The dead-boot region ($044A-$1A88) already demonstrates the
  overlay model (scenes dead-after-run); formalizing it is the recommended next
  architectural step, and it is **Jay's gated call** (not an ambient default).

## Regenerate
Re-run the prod build with `--list=prod.lst`; read the segment addresses of
`broderbund_scene` / `HAL_sys_init` / `scene5_run` / code-end; the ledger is
`code_end $483A`, `CLEAN_BUF $4A00` (rows 0-167 = 13440 B), `FLIP_BUF $7E80`,
framebuffers $8000/$C000. HAL caller-check: grep the prod scene-5 files for
`jsr HAL_gfx_blit_*`.
