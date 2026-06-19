# Scene-5 Akuma — head-coupling re-trace (HS-0 GATE, trace-grounded)

The earlier recon (scene5-akuma-eagle-recon.md) proved Akuma's ARMS are a free
ambient loop (frozen-clock test) but **over-generalized to "Akuma is ambient"**
— it never isolated the HEAD. Re-trace (this dispatch) isolates the head:
Akuma's head TRACKS THE PRINCESS. Method: the actor draw-program tap
(tools/trace_actors.lua → actors.log); Akuma head srcs vs `$3B` (the scene
clock the princess DRIVES by walking, i.e. her position proxy through the
throne phase `$15→$22`).

## Finding — head TRACKS the princess (princess-keyed, DISCRETE, var = $3B)

As the princess walks left→right (`$3B` `$15→$22`), Akuma's head frame turns
left→right to follow her (monotonic with her position, independent of the
ambient arm poses 9908/9956 which loop regardless):

| `$3B` (her position) | head src (frame) | facing |
|---|---|---|
| 15–17 | `988B` (frame_1) | mid-left |
| 18–19 | `989D` (frame_2) | short-left |
| 1A–1B | `98AF` (frame_3) | short-right |
| 1C–1D | `98C1` (frame_4) | right |
| 1E–22 | `9A62` (frame_8) | full-right |

- **Princess-keyed:** YES. The head turns to follow her walk; the change is
  monotonic with `$3B` (her position) and separate from the arm loop. (The
  recon's frozen-clock test passed on the ARMS regardless of the head, so it
  never ruled head-coupling out — corrected here.)
- **Continuous vs discrete:** DISCRETE — ~5 head-pose zones keyed to `$3B`
  ranges (not a smooth per-pixel follow).
- **Coupling variable:** `$3B` — the scene clock the princess drives by
  walking (her position proxy). In the port that is the canonical `scene_clk`
  (the `$3B`-analog established in Gate 1/2). Akuma's head reads `scene_clk`
  (single-source, HS-2) and selects the head frame per the zone table above.

## Two behaviors, separate (HS-1)
- **Arms/hands — AMBIENT free loop** (no clock): the torso-arm poses cycle
  (`98D3` hand-on-hip / `9908` hand-raised / `9956` pointing). Proven ambient
  by the recon (poses change at frozen `$3B=15`).
- **Head — PRINCESS-POSITION-COUPLED** (the table above), reading `scene_clk`.

## Shadow (oracle check, don't fabricate) — CORRECTED (Jay): Akuma STANDS
Akuma is a STANDING figure (NOT seated; there is no throne sprite — "throne
room" is just the scene name). Body = `974B` (43×11 black robe) + `9EB8` blue
figure, layered, @ apple x`$1A`/`$17`, with feet `9F8C` (@ x`$1E` y`$A3`=163).
Oracle draw program shows NO dedicated Akuma shadow sprite in the captured
banks. Per the guard precedent (Jay added a princess-matching shadow to a
standing figure even without an oracle one), a ground shadow is wired for the
standing Akuma and confirmed at the gate.

## Phase scope
Throne actor: arms-loop + head-tracking run during the THRONE phase (her
walk-in, `$3B=$15→$22`). After the transition (`$3B`→`$04`, she's in the cell)
Akuma is off-scene. Head-tracking is throne-phase only.

## Part positions (apple, trace-captured akuma_pos.log) — for the build
- robe/body `974B` (43×11): x`$1A`(byte~50) y`$77`(119)
- feet/robe-bottom `9F8C` (9×11): x`$1E`(byte~57) y`$A3`(163)
- head (8 rows): x`$17`(byte~45) y`$71`(113) — swaps frame, fixed position
- torso-arm `98D3`/`9908`/`9956`: x`$19`(byte~48) y`$7C`(124) — ambient cycle
- throne elem `9EB8` x`$17` y`$79`; elem `984F` x`$17` y`$7D`
- (eagle `9FC4`/`9FD8` x`$1B`/`$17` y`$70`/`$6A` — separate dispatch)
