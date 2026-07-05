# Video-buffer banking recon — stage 1 (2026-07-05)

Stage 1 of the banking arc (recon → design → sandbox HAL → real HAL). This stage
**verifies the mechanism CAN work** (GIME doc + throwaway spike) and gathers code
observations as INPUT to the stage-2 design. It could have come back NO. **Verdict:
YES — the mechanism works; ~30KB window reclaim is real. No hard wall; one flag
(a GIME-doc vs execution conflict) for stage-2.** Read/throwaway only; prod
HAL + `karateka.bin` unchanged (17978 B). All suggestions below are design INPUT,
not decisions (HS-3).

## 1. Mechanism — from the GIME ground-truth (AC-0, HS-1)
Authority: `docs/ground-truth/SockmasterGime.md` (John Kowalski / Sock Master).
- **`$FF9D`/`$FF9E` — VOFFSET (video start).** "$FF9D MSB = video location × 2048;
  $FF9E LSB = video location × 8. Y15-Y0 sets the video to start in **any memory
  location in 512K by steps of 8 bytes**; on a 128K machine the range is
  **$60000-$7FFFF**." → the video scanner fetches from a **physical** address,
  **independent of the CPU MMU**. This is the crux: a buffer can be *displayed*
  without being CPU-mapped.
- **`$FFA0-$FFA7` — MMU (task 0), 8KB blocks.** "Valid bank ranges are **56-63 on
  128K**, 0-63 on 512K." (Note: 56-63 = 8 pages = 64KB, which is internally
  inconsistent with "128K"; the project memory-map uses $30-$3F = 48-63 = 128KB.
  See the spike, which resolves this by execution.)
- **The flip is ALREADY this mechanism:** `HAL_gfx_present` writes VOFFSET
  (`= physical/8`) to display the just-drawn buffer. So "display from a physical
  location + flip" (P1+P2) is already **live and Jay-gated in prod** (every scene's
  double-buffer). The recon only had to prove the *reclaim-specific* parts.

## 2. Throwaway spike — execution proof (AC-1, HS-2)
`spike_vbank_THROWAWAY.s` (removed after; runs at $0200, never remaps its own
blocks). Two tests, read headless via `spike_vbank.lua`:
- **TEST A — lower-bank CPU-mappability:** map page $30 ($60000) into $4000, write
  `$A5`, read back → **`$A5` at BOTH forced `-ramsize 131072` (128K) and `524288`
  (512K)**. The lower bank IS CPU-mappable RAM (map-in-to-draw works).
- **TEST B — VOFFSET display-independence:** write `$5A` to fb A (phys $78000) via a
  mapped block, then **remap $8000 away** — `$8000` then reads `$FF` (the byte is
  NOT visible via the away-page), but **phys $78000 still holds `$5A`**. The byte
  lives in physical RAM; VOFFSET would display it regardless of the CPU mapping.
- **Regen:** the spike sets INIT0=$4C (MMUEN), identity-maps $FFA0-$FFA7 to $38-$3F,
  then the two tests above; the lua reads $70/$71/$8000 after ~30 frames.

**Execution overrides the doc (CLAUDE.md §2):** the doc's "56-63 on 128K" is
contradicted by the spike ($30 mappable) and the project memory-map ($30-$3F). But
MAME is an emulator — see the flag in §5.

## 3. Net window reclaim (AC-2)
The framebuffers occupy **$8000-$FBFF = ~30KB** of the 64KB window, permanently
CPU-mapped only so the blit can reach them. Under banking: keep them displayed via
VOFFSET (from their physical pages), **unmap them from the window**, and map a
framebuffer page into a scratch window block **only during a blit**. Freed:
**~30KB of CPU window** — by far the biggest reclaim (vs the 5.6KB dead-boot slot /
1.2KB snapshot trim from the prior audit). That turns the ~454-byte margin into
~30KB of headroom — several scenes of runway.

## 4. Code observations + suggestions (AC-3 — design INPUT, HS-3)
- `HAL_gfx_present` (`gfx.s`) **already writes VOFFSET** — the flip is the banking
  primitive; banking reuses it unchanged.
- The blit picks its base by `page_register`: `GFX_FB_A_BASE $8000` / `GFX_FB_B_BASE
  $C000`. To draw a *banked* framebuffer, the leaf must instead **map the fb's
  physical page into a scratch window block and target that** — the one code change
  the design needs (a "map-in fb, blit, [leave mapped or map-out]" wrapper around
  the blit leaf).
- **Must-stay-mapped set** (can't be banked out during a draw): the code+HAL
  ($0200-$7FFF), `CLEAN_BUF` ($4A00-$7E80), and the fb-being-drawn (in its scratch
  window block). The dirty-rect restore reads `CLEAN_BUF` and writes the fb — both
  must be mapped for that op.
- **Suggestions (INPUT, not decisions):** (a) simplest — keep BOTH framebuffers
  mapped during a scene's active render and bank them out only between scenes (frees
  window for the *next* scene's code, less per-blit MMU churn); (b) full — map the
  back fb into one scratch block per frame (frees ~15KB continuously, one MMU write
  per flip); (c) since the lower bank is mappable, an alternative is to bank
  CODE/CONTENT (not framebuffers) into the lower bank — same infra, avoids touching
  the blit base. Stage 2 (Jay + Orchestrator) chooses.

## 5. Verdict-input (AC-4, HS-5) — falsification criteria
| Criterion | Result |
|-----------|--------|
| Video can display from a usable bank | **PASS** — doc (VOFFSET physical) + spike (phys persists) + prod (flip live) |
| Flip can re-point | **PASS** — `HAL_gfx_present` VOFFSET write, already prod-gated |
| Draw can tolerate map-in/out | **PASS** — spike: lower bank mappable, write lands; standard MMU use |
| Net reclaim exists | **PASS** — ~30KB window freed |
**No hard wall.** **Verdict: YES** (with the design work of §4).

**FLAG for stage 2 (uncertainty, not a wall):** the GIME doc says MMU valid = "56-63
on 128K"; the spike shows $30 mappable, but **MAME is an emulator** and may not model
a real 128K MMU restriction. If real 128K hardware truly limits the CPU to $38-$3F,
the reclaim would need 512K. Recommend a real-hardware (or a second-source) check
before the design commits to 128K. (On 512K it is unambiguous — works.)

## Files
- None committed to prod (read/throwaway). Spike removed; results captured here.

## Candidate (report-noted, `seeds/` not established)
"video-banking recon: VOFFSET display is physical/MMU-independent (spike: phys
survives CPU unmap); the flip already IS the primitive; ~30KB reclaim; doc's
'56-63 on 128K' overridden by execution but flagged for real-hardware."
