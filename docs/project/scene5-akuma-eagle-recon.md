# Scene-5 Akuma + eagle — behavioral spec (RECON, trace-grounded)

Input to the later controller-build dispatches. **All findings from runtime
trace, NOT disassembly labels** (HS-2 — oracle mislabeled past scene 4).
Oracle: apple2e + `dumps/karateka.dsk` (imprisonment cutscene). Method: a Lua
write-tap on ZP `$04` (sprite src hi-byte, set last before each blit) logging
the drawn src + `$3B`/`$39` + frame per draw, then a per-FRAME actor signature
(`tools/trace_actors.lua`, `trace_actors2.lua` → `actors.log`, `actors2.log`).
Scene clock `$3B`: throne walk `$15→$22`, cell `$04→$0C` (the princess arc map).

## AKUMA — ANIMATED, **AMBIENT** (idle gesture loop, NOT $3B-coupled)

- **Where:** on his throne, RIGHT side, ~apple x`$17`–`$1B` (px≈161–193), y`$70`–`$7C`.
- **Frames (runtime srcs, multi-part composite per frame):** base body/feet
  `$9801`/`$984F`/`$9F00`/`$9F8C`; head poses `$988B`/`$98AF`/`$98C1` (look
  left/right/variant); arm/hand `$9908` (raised) / `$9956` (pointing); `$9858`/`$985C`.
  (These are the ACTUAL runtime srcs — they do NOT all match the catalog's
  `$9879…$9A62` head list; HS-2.)
- **Animation:** a continuous idle GESTURE — head turns + arm/hand poses
  (`$9956` pointing, `$9908` raised) cycle in/out.
- **Coupling — AMBIENT (decisive evidence):** the poses CHANGE while `$3B` is
  STATIC. During the pre-walk stand (`$3B=$15`, `$39=$00`, ~383 VBL) Akuma's
  signature goes from `{9801,984F,988B,98D3,9802,9902…}` (f3921) to include
  `{9908,9956}` (f4159) — new arm/hand poses appear with the clock unchanged.
  The gesture then runs uniformly through the whole walk (`$3B=$16…$21`, ~16
  signature-changes per `$3B` step). → driven by a free counter, NOT a beat.
- **Cadence:** a multi-second loop — the base pose `$9801` recurs ~235 VBL
  apart (f3918→f4153); poses turn over within that.
- **Controller implication:** an AMBIENT gesture-cycle controller (free idle
  loop on the throne, independent of `$3B`), feeding the shared leaf. Right-side
  composite, multi-part (head + torso + arm + feet).

## EAGLE — minimal, **$3B-coupled one-shot head-turn** (NOT wing-flap/fly)

- **Where:** perched on Akuma's SHOULDER — body `$9FC4` fixed at apple x`$1B`
  y`$7C`; head at x`$17` y`$70`. Never moves (no fly-across, no positional change).
- **Frames:** body `$9FC4` (constant). Head has TWO frames: `$9FD8` and `$985C`.
- **Animation/coupling — ONE head-turn, $3B-coupled:** head = `$9FD8` through
  the pre-walk stand (`$3B=$15`); switches ONCE to `$985C` exactly when the walk
  begins (`$3B=$16`, f4344) and HOLDS `$985C` for the rest of the throne phase
  (`$3B=$16…$22`). A single head-turn reacting to the walk-start beat. NO
  wing-flap, NO fly, NO loop. (Refines the dispatch's wing-flap/fly hypothesis —
  the trace shows a near-static perched eagle with one beat-triggered head-frame swap.)
- **Controller implication:** minimal — a single head-frame swap at `$3B=$16`
  (could even be modeled as two static states keyed on the clock). Far lighter
  than Akuma's ambient loop. Confirm wing/flap absence holds in the cell phase
  before committing the controller (only the throne phase was decisive here).

## GUARD — STATIC (confirms the static-composite build)

- 3 fixed parts: head `$8F2B`, torso `$899C`, below `$8ACB`; LEFT side, ~apple
  x`$06`–`$07`. Signature is always those 3 parts (the `{899C,8F2B}`/`{8ACB,8F2B}`
  alternation is the double-buffer, not animation) across the entire scene → no
  frame variation. → static set-dressing (this dispatch's build).

## Uncertainty flags
- Positions above are approximate (the tap reads `$05`/`$06` at the `$04`-write,
  which can be a draw or two stale) — fine for the behavioral spec; the guard
  BUILD uses a precise draw-program capture.
- Eagle: only the throne phase was decisively traced for flap-absence; the
  controller dispatch should re-confirm in the cell/collapse phase.
