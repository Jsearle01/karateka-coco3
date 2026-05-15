# Session note — 2026-05-15 — P2 scoping survey

## Session type

Read-only survey of karateka_dissasembly_claude src/. Produces a planning artifact
(docs/p2-scoping-survey.md) informing P2.2 subsystem selection and INT-1 content
asset wave. No commits to karateka_dissasembly_claude.

## Timing

- Started: 2026-05-15T10:59:02-04:00
- Completed: 2026-05-15T11:11:55-04:00
- Elapsed: ~12 min 53 sec

## What was surveyed

All key source-file headers in karateka_dissasembly_claude:
- kernel.s, kernel_per_frame.s, kernel_dispatch.s, kernel_dispatch_handlers.s
- video.s, render_frame_0a00.s
- scene_dispatch.s, intro.s
- display_7700.s
- sound_engine.s, sound.s
- input.s
- fight_engine.s, attract_dispatch.s, attract_render.s, attract_state.s
- karateka_logo.s, sprite_data_logo.s
- sprite_data_0400.s and other sprite banks (headers)

Reference docs consulted:
- docs/intro-sequence-structure.md (authoritative sequence)
- docs/data-areas-catalog.md (ZP pointer map)
- docs/scene-entries.md (per-scene entry points + trace evidence)
- docs/differential-analysis.md (per-dump state)
- karateka-coco3 docs/hal.md (HAL subsystem reference)

## P2.2 recommendation: kernel/dispatch

**Subsystem:** kernel.s + kernel_per_frame.s + kernel_dispatch.s + (stub)
kernel_dispatch_handlers.s

**Data basis:**
- Smallest of the INT-1-critical subsystems (~482 bytes, 1,212 lines)
- Natural continuation of P2.1 (timer_dispatch.s → per-frame dispatcher)
- kernel_dispatch handlers safely stubbed (0 trace fires in full-cycle attract trace)
- Exercises HAL_time_vbl_wait and HAL_gfx_present as callers (surfaces HAL contract
  gaps before P3 commits)
- Can verify via compare.py against existing page_register/page_source_blit
  mapping.json entries without needing sprite or scene code

**Recommended sequence after P2.2:**
- P2.3 = blit/graphics (video.s + render_frame_0a00.s, bundled with display setup)
- P2.4 = intro.s scene management (scene 1 path)
- INT-1 reachable after P2.4 + P3.x Time + Graphics HAL implementations

## INT-1 content asset list summary

Scene 1 = Brøderbund logo + "presents" text (~frame 551 in cycle 1).

**Five assets needed:**
1. Brøderbund logo sprite 1 (at $A126 in fight_engine.s uncharted block)
2. Brøderbund logo sprite 2 (at $A16E in fight_engine.s uncharted block)
3. $0400 font — 30 glyphs ($0400-$067F; confirmed visually; sprite_convert.py)
4. Font metrics tables (font_metrics.s; need CoCo3-address regeneration, not verbatim copy)
5. Initial palette (derived from scene 1 sprite bytes via palette_derive.py)

**Pre-condition for assets 1-2:** Read header bytes at $A126/$A127 and $A16E/$A16F
from dump01_intro.bin to determine sprite extents. These are currently emitted as
raw .byte in fight_engine.s with no sprite-record labels.

**String positioning:** "presents" string X-position header ($0E $03) is Apple II
7px/byte specific; CoCo3 (4px/byte) needs pixel-position recalculation.

## Findings beyond plan

1. **Brøderbund logo sprites not labeled.** fight_engine.s's $A0E7-$A305 block
   is "uncharted bitmap data." The two logo sprites at $A126/$A16E are correct in
   byte content but not labeled as named records. INT-1 wave pre-condition: extract
   by offset, read headers. Not a plan deviation — adds one small step.

2. **kernel_dispatch handlers are functionally unknown.** Safe to stub for
   INT-1/INT-3; purpose only needed for P0b gameplay paths.

3. **$7606-$7696 display helpers in input.s.** input.s header notes these may
   migrate; when porting input.s, sort these into kernel or blit/graphics
   subsystem rather than carrying them into the input port.

4. **render_frame_0a00.s called by both attract and intro subsystems.** Must be
   bundled with blit/graphics (P2.3), not intro (P2.4).

5. **Font metrics encoding is Apple II-specific.** The `font_glyph_hi_minus_4`
   encoding and Apple II 7px/byte string positions require remapping for CoCo3,
   not verbatim copy.

## Calibration counter decision

**Counter stays at 12.**

Reasoning: this survey produces a planning artifact — docs/p2-scoping-survey.md —
which is substantive research but not a port, methodology pattern, or HAL contract
advancement. It is more substantive than pure bookkeeping (P1 closure, doc update),
but its primary function is planning rather than capability delivery. The calibration
counter tracks task complexity in the context of developing methodology judgment; a
planning artifact is editorial rather than engineering. Counter stays at 12;
P2.2 will be task #13.

## Methodology patterns exercised

- **reference-discipline:** all claims in the survey cite specific karateka_dissasembly_claude
  files/sections; [no-ref:] used for three inferred items (sprite dimensions, initial
  palette, string positional mapping)
- **plan-deviation-discipline:** no stops required; all findings fit within the
  survey frame (labeled as "findings beyond plan" in the artifact rather than
  plan deviations requiring a gate)
- **execution-timing-discipline:** start/completion timestamps recorded

## Files changed (karateka-coco3 only)

- `docs/p2-scoping-survey.md` — new; the survey artifact
- `docs/project-state.md` — next-task pointer updated to P2.2 + INT-1 wave

## Next

P2.2 (kernel/dispatch port) and first content-conversion wave (INT-1 assets) can
run in parallel. P2.2 begins first; INT-1 wave begins once the Brøderbund sprite
byte extents are confirmed.
