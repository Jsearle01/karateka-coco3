# Wall-top render map — clean, execution-confirmed (2026-07-14)

**Type:** READ-ONLY identification. **Recipe:** CLEAN `-video none -keyboardprovider none`.
**Prod ROM:** `88eba89b15cdf17c8d25e082d2d3e1f3cce57d38` untouched. Frames my-boot (provenance).
**Method:** bp the oracle render routines during the clean climb (f6068–6120) + read the
attract scene-renderer code (`attract_dispatch.s`) — the actual draw program, not labels.

## ⚠ PRIOR IDENTIFICATION CORRECTED (the arc's root error)
- **`$AA23`/`$AA31` are NOT the wall-top posts — they are the fight COMBATANTS.** In the oracle
  (`attract_dispatch.s`), `draw_combatant_ad56` draws combatant A = `sprite_AA23` (pos `$51/$50`),
  `draw_combatant_ad75` draws combatant B = `sprite_AA31` (pos `$AC/$AE`), dirty-flag cached,
  174×/cycle. During the CLEAN climb they fire but at **x=`$FE` (OFF-SCREEN)** — not visible.
- **The `$96/$99` cels (`9600/964A/96CE`) are FLOOR cels (scene-5)** — converted in
  `content/floor/`, appear in the princess-fall, NOT the climb wall-top.

## The REAL wall-top (post + runners) — MASKED-BLIT
| Property | Value (execution-confirmed) |
|---|---|
| Cels | **`$AA27`–`$AA30`** (10-cel run) |
| Render mechanism | **masked-blit `$1BF4`** (SMC blend + `$0900` screen-address/shift table) |
| Sub-byte shift | **5** (`$10`=5 — Apple 7px/byte; needs 7→4px conversion for CoCo3) |
| Position | row **100** (`$64`), two X instances at cols **`$17`(23)** and **`$23`(35)** |
| Convert status | **ALL 10 UNCONVERTED** (`content/` has none of `$AA27–$AA30`) |
This is why coordinate-placement failed ~20×: the wall-top is a **masked, sub-byte-shifted blit**,
not a cel placed at `$05` — and `$05` is the scroll-relative compute, not the render column.

## The rest of the climb scenery (for completeness)
- **Cliff face** (standard blit `$1903`): `$AB8E` stacked at col `$0A`, rows 117–151 (`$75–$97`,
  step 2, ~19 blits); `$AB94` col `$0A` row 112; `$AB7C` col `$0A` row 104; `$AB4A` structure.
- **Fill lines** (pattern-fill): `$0A09` (render_pass_a, single-colour) + `$0A40` (render_pass_b,
  dual-colour), ×17 each — the port already replicates these with direct buffer fills
  (`draw_climb_striations`/`draw_climb_ground_right`).
- **Fuji** (`AD30_two_sprites` + `ADD1_background`): standard blits, `$A9xx` bank.
- **Scene sprites** (`draw_scene_ae7a`/`load_scene_sprite_ae3f`, 18-entry table `$ADF7–$AE3E`,
  `$A6xx–$ACxx` bank): X = **`$52`(scroll) ± `xadj[i]`**, Y = `Y[i]`; `$1903` normal / `$190C`
  mirror. During the climb `$52`=`$30`, `$4C`=`$00`.

## Attract-vs-fight (D-resolved)
**SAME renderer.** The climb uses the fight scene renderer (`attract_dispatch.s` / `draw_scene_ae7a`
+ combatants + Fuji + pattern-fills); the scene is driven by `$52` scroll. Difference at the climb:
combatants parked off-screen (`x=$FE`), `$52`=`$30`. So the wall-top render **technique** is common;
the port build can share it across climb and fight.

## Layering (draw order, execution-confirmed)
Fuji (`AD30`) → pattern-fills → background (`ADD1`) → `draw_scene_ae7a` (scene sprites incl. the
masked `$AA2x` wall-top) interleaved with pattern-fills, repeated. Wall-top runner composites via
the masked-blit within the scene draw.

## D5 — Primitive-gap (FLAG for the build; do NOT build here)
- **Masked-blit with sub-byte shift** (`$1BF4` + `$0900` shift table, shift 5) — REQUIRED for the
  `$AA27–$AA30` wall-top runner. The HAL has an `_masked`/`_stencil` path (from scene-5); the build
  must verify it reproduces the shift-5 masked blit (7→4px sub-byte conversion), else extend it.
  **This is also the deferred Stage-4 combatant masked-blit primitive — the wall-top is a good
  first case for it.**
- **Pattern-fill** (`$0A09`/`$0A40`) — NO new primitive; the port's direct fills already cover it.
- **Convert-first:** `$AA27–$AA30` (10 cels) must be converted (clean, Stage-0 style) before the build.

## Port consequence
Wall-top build target = the `$AA27–$AA30` runner via a masked sub-byte-shifted blit at row 100,
cols 23 & 35, shift 5 — NOT AA23/AA31 (combatants) and NOT `$96/$99` (floor). Build the masked-blit
primitive first (shared with the fight combatants), convert `$AA27–$AA30`, then place via the
masked blit — not by static coordinates.
