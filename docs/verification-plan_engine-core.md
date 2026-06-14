# Verification plan + results — sprite/animation engine core (R-engine)

Engine: `src/engine/sprite_engine.s` (single-source animation core).
Sandbox: `tests/scripted/sprite_engine_sandbox_driver.s` (+ `.lua`, `.bat`, `.sh`).
Proven on: Akuma 9-frame set (`content/akuma/akuma_frame_0..8`).

The sandbox **includes the real engine + real HAL + real globals verbatim**
(never a copy), so a sandbox pass is a production-code pass. The sandbox is
**boot-excluded** — `boot.s` never references it; the production link list does
not assemble it (AC-5/AC-6 verified: prod boot builds to 7359 bytes unchanged).

---

## P2 — static render correctness (agent snapshot) — **PASS** (2026-06-13)

A single animation frame renders cleanly at the anchor (byte col 34 / px 136,
row 80) with **no garbage, no corruption, no stray writes** (contrast the
R-p26 garbage-band regression). MAME snapshots `snap/coco3/0046.png`,
`0047.png`. The lit Akuma pixels appear at the correct anchor against a clean
black field. (The displayed frame lags the sampled `eng_idx` by one render due
to the double-buffer toggle — expected, not a defect.)

## P3 — state cadence + cycle + flip (agent memory trace) — **PASS** (2026-06-13)

`build/sprite_engine_sandbox.log`. Memory reads (reliable under `-nothrottle`,
unlike pixel motion):

- **Cadence**: every steady-state advance delta = **8 VBLs** = `AKUMA_CADENCE`.
  (First delta 24 = load/init transient; ignore.)
- **Cycle**: `eng_idx` walks `0,1,…,8` then wraps to `0`, repeatedly — 9 frames.
- **Flip**: `page_register` toggles `$20`↔`$40` on **every** advance (Option-I).

31 advances over 260 VBLs, all consistent.

## P4 — live motion fidelity (Jay, real-time) — **PENDING GATE**

Snapshots misrepresent MOTION (established lesson); P4 is the human gate.
Run real-time (no `-nothrottle`):

```
cd /d C:\karateka-capture
C:\mame\mame.exe coco3 -rompath C:\mame\roms -window -autoboot_script tools\sprite_engine_sandbox.lua
```

Expected: the Akuma sprite set cycles in place at the anchor, ~7.5 fps
(cadence 8). Free-run by default; **tap any key to single-step** one frame
(then release). Jay confirms: smooth cycling, no flicker/tearing, frames land
at the anchor, no stale-frame ghosting between flips.

NOTE: the 9 frames are distinct body parts (heads / torsos / arm) at a shared
anchor — this proves the engine *cycles a frame sequence*; coherent character
*compositing* (assembling parts into a posed figure) is scene-5 orchestration,
out of scope here. If the cycling "reads" unsatisfactorily, the fix is the
animation table (DATA) — e.g. restrict to the head poses — not the engine.

---

## HS-1 — cycle budget (AC-1): render + flip fits one VBL period — **PASS** (static analysis)

One emulated frame (NTSC 60 Hz @ 1.7898 MHz) = **~29 830 CPU cycles**. The
engine does a full render only on a cadence advance; non-advance ticks cost
~12 cy (`dec`/`bne`/`rts`).

Worst-case render = frame 6 (19 rows × 6 bytes, sub-byte 0):

| Stage | Detail | Cycles |
|-------|--------|--------|
| `eng_clear_box` | 10×19 union box: 51 + 19·(34 + 11·10) | ~2 790 |
| `HAL_gfx_blit_sprite` (sub0) | 114 bytes·~10 + setup + 19 row-ovh | ~1 520 |
| index math + present + toggle | | ~120 |
| **total render+flip** | | **~4 430** |

Headroom: **~4 430 / 29 830 ≈ 15 %** of one frame — fits with ~6.7× margin
**even if redrawn every single VBL**. With the real 1-in-8 cadence, per-frame
cost averages ~560 cy.

### Scaling baseline

At ~4 430 cy/worst-case-render, one frame period holds **~6 simultaneous
worst-case full redraws**; with realistic cadence and smaller frames the
practical simultaneous-character ceiling far exceeds intro/cutscene needs
(1–2 characters). The clear box dominates (~63 %): a future optimization is a
per-frame tight bbox (clear = max(this, prev) frame extent) instead of the
set-union box — deferred; current cost fits comfortably.

Cadence itself is **not oracle-extractable** (the per-frame timing lives in
un-disassembled code); `AKUMA_CADENCE=8` is a tunable default, Jay-gated at P4.
