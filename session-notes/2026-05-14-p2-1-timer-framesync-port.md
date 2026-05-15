# Session: 2026-05-14 — P2.1 Timer/Frame-Sync Engine Subsystem Port

## What landed

| File | Role |
|------|------|
| `src/engine/timer_framesync.s` | Ported page-flip/frame-sync engine subsystem (6809) |
| `src/hal/coco3-dsk/time.s` | Minimal-functional Time HAL stubs |
| `src/hal/coco3-dsk/gfx.s` | HAL_gfx_present stub (forward dep, P3 scope) |
| `tests/scripted/timer_framesync_driver.s` | Test driver (flat, self-contained) |
| `tests/scripted/timer_framesync_driver.bin` | Assembled test binary (91 bytes) |
| `tests/scripted/timer_framesync_test.lua` | MAME test harness script |
| `tests/scripted/run_timer_framesync_test.sh` | Test runner |
| `captures/p2_1a_coco3_pre_pageflip.json` | CoCo3 DP state before page_flip calls |
| `captures/p2_1a_coco3_post_pageflip.json` | CoCo3 DP state after 3 page_flip calls |
| `verification/mapping.json` | Updated: timer_frame_sync entries confirmed |

## 6502 Source Analysis (TASK 2)

**routine_07d7** ($07D7, VBL sync, Apple II kernel.s):
- Reads ROM_VERSION ($FBB3): checks for Apple IIe model
- Spins on RDVBL ($C019) until VBL clears
- **ZP side effects: NONE** — pure hardware timing wait
- Hardware-dependent; replaced entirely by HAL_time_vbl_wait

**routine_0799** ($0799, page-flip A):
- Reads $07; if $40 → tail-call routine_07ac (A=$40 preserved)
- Otherwise: $E4 := $07 (save old page), $07 := $40, VBL sync, TXTPAGE1
- **ZP writes: $07 (→$40), $E4 (→prior $07)**

**routine_07ac** ($07AC, page-flip B):
- $E4 := A (=$40 from tail-call), $07 := $20, VBL sync, TXTPAGE2
- **ZP writes: $07 (→$20), $E4 (→$40)**

**Scope refinement from analysis:** blit_row_dst ($E0/$E1) and blit_row_src
($E2/$E3) are set by routine_07b9 within routine_0786 (the blit loop), NOT
by the page-flip routines. Moved to subsystem `blit_graphics`, status
`unmapped` in mapping.json. P2.0a captures confirm: $E2/$E3 = $00/$00
throughout attract-loop; $E0/$E1 changed by non-page-flip code.

## Port Approach (TASK 3)

| Apple II | Translation | CoCo3 |
|----------|-------------|-------|
| `lda $07` | A.3 ZP→DP | `lda <page_register` (DP $50) |
| `sta $E4` | A.3 ZP→DP | `sta <page_source_blit` (DP $51) |
| `cmp #$40` | A.1 | `cmpa #PAGE_B` |
| `beq routine_07ac` | A.5 | `beq page_flip_to_a` |
| `jsr routine_07d7` | HAL | `lda #1; jsr HAL_time_vbl_wait` |
| `lda TXTPAGE1` strobe | HAL | `jsr HAL_gfx_present` |

DP allocation: page_register=$50, page_source_blit=$51 (frame-coherent
band $50-$5F per conventions.md §2).
`[ref: conventions.md §2 — frame-coherent variables $50-$5F]`

## HAL Forward Dependency (surfaces per plan-deviation-discipline)

timer_framesync.s calls `HAL_gfx_present` — a GFX HAL function (P3 scope,
not Time HAL). This is a forward dependency: the engine subsystem port
requires a GFX stub. Resolution: created `src/hal/coco3-dsk/gfx.s` with a
minimal `HAL_gfx_present` stub (RTS only). P3 replaces with GIME VOFFSET
register write. This is a SMALL forward dependency (one stub, ~4 bytes),
not a scope overrun. Surfaced; not worked around silently.

## Stub Adequacy (TASK 4)

HAL_time_vbl_wait adequacy: CONFIRMED ADEQUATE. routine_07d7 has NO ZP side
effects (only reads ROM_VERSION and RDVBL). The page-flip STATE ($07/$E4 →
$50/$51) is timing-independent. The stub increments the frame counter and
returns; the page-flip logic executes correctly without real VBL timing.

HAL_gfx_present stub adequacy: CONFIRMED ADEQUATE for P2.1. The display-gate
call doesn't affect the DP variables under comparison. P3 adds the real GIME
register write.

## Ratified Predictions and Comparison Results

From TASK 5 gate — predicted outcomes after 3 page_flip calls from $20:

| Prediction | Expected | Actual | Result |
|------------|----------|--------|--------|
| 1. page_register after 3 calls | DP$50=$40 | DP$50=0x40 | ✓ MATCH |
| 2. page_source_blit = prior page | DP$51=$20 | DP$51=0x20 | ✓ MATCH |
| 3. frame counter increments | DP$10/$11=$0003 | $0003 | ✓ MATCH |
| 4/5. Invariant $50+$51=$60 | $60 | $60 | ✓ MATCH |

**compare.py result:**
```
MATCH  (2)
  page_register:    apple2=$0007:0x40  coco3=$0050:0x40
  page_source_blit: apple2=$00E4:0x20  coco3=$0051:0x20
PENDING  (1): frame_countdown (scene_management, TBD)
SKIP  (2):    blit_row_dst, blit_row_src (moved to blit_graphics/unmapped)
RESULT: PASS (no mismatches)
```

Phase note: Apple II frame 700 and CoCo3 post-3rd-call both happen to have
page_register=$40. The structural invariant check ($50+$51=$60) holds
independently of phase on both platforms.

## Verification Scope Statement

**Engine-side timer/frame-sync logic verified against Apple II reference.**
The page-flip state machine (page_register ↔ page_source_blit alternation)
produces the same observable behavior as Apple II routine_0799/routine_07ac.

**Hardware VBL synchronization is STUBBED (P3).**
HAL_time_vbl_wait advances the frame counter and returns immediately.
Real GIME VBL timing is deferred to P3. The stub is adequate for P2.x
behavioral verification; the display will not actually be synchronized to
the hardware refresh rate until P3.

**HAL_gfx_present is STUBBED (P3).**
The display buffer is not actually switched in P2.x. P3 writes the GIME
VOFFSET register.

## Mapping Updates

| Entry | Before | After |
|-------|--------|-------|
| page_register | apple2-confirmed-coco3-predicted, coco3.address=null | confirmed, coco3.address=80 ($50) |
| page_source_blit | apple2-confirmed-coco3-predicted, coco3.address=null | confirmed, coco3.address=81 ($51) |
| blit_row_dst | subsystem=timer_frame_sync, predicted | subsystem=blit_graphics, unmapped |
| blit_row_src | subsystem=timer_frame_sync, predicted | subsystem=blit_graphics, unmapped |
| frame_countdown | unchanged (scene_management, predicted) | unchanged |

CoCo3 addresses match conventions.md §2 prediction ($50-$5F frame-coherent
band). No revision to conventions.md §2 needed.

## Methodology Patterns Exercised

- **reference-discipline**: all port decisions cite kernel.s source and
  data-areas-catalog.md; HAL calls cite hal.inc; DP assignments cite
  conventions.md §2; `[no-ref:]` where unverified
- **blocking-gate-discipline**: TASK 5 gate honored; predictions ratified
  before code was written; two refinements per user feedback applied
- **plan-deviation-discipline**: blit variable scope refinement surfaced;
  HAL_gfx_present forward dependency surfaced and resolved (not silently
  worked around)
- **execution-timing-discipline**: timing reported (see session timing)

## Calibration Tracking

Calibration task counter: 11 → 12. This is the first REAL engine code.
Calibration phase (first 10-20 tasks) approaching mid-point.

## Next

P2.2 — next engine subsystem port. Candidates: scene_management (frame
countdown / scene dispatch), or the per-frame loop body ($0237-$024B).
P2.2 selection depends on which subsystem unblocks the most forward
dependencies. Planning discussion before next execution prompt.
