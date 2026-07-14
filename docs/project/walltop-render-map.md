# Wall-top render map — clean, execution-confirmed (2026-07-14)

**Type:** READ-ONLY identification. **Recipe:** CLEAN `-video none -keyboardprovider none`.
**Prod ROM:** `88eba89b15cdf17c8d25e082d2d3e1f3cce57d38` untouched. Frames my-boot (provenance).
**Method:** bp the oracle render routines during the clean climb (f6068–6120) + read the
attract scene-renderer code (`attract_dispatch.s`) — the actual draw program, not labels.

## ⚠⚠ THE "$AA25–$AA30 RUNNER" IS A PHANTOM — it is cel `$AA23`'s DATA (RESOLVED 2026-07-13)
The raw dump settles the whole arc. `$AA23` header = `0C 01` → **h=12, w=1** (a 1-byte-wide ×
12-row vertical post); its 12 data bytes live at **`$AA25`–`$AA30`**. Likewise `$AA31` header =
`0C 01`, data **`$AA33`–`$AA3E`**. The write-pointer trace that read "cel = `$AA25`…`$AA30`" was
capturing the masked-blit's **source pointer `$03` walking `$AA23`'s 12 row-bytes** (one byte per
row → rows 100–111) — **NOT 12 separate cels.** There are **no cels to convert**; `$AA23` and
`$AA31` are **already converted** (`content/scenery/scene6_cliff_{AA23,AA31}`).

## ⚠⚠ AND `$AA23`/`$AA31` ARE THE WALL-TOP, not spurious combatants (PRIOR "CORRECTION" INVERTED)
Direct execution evidence (`tools/walltop_masked_inventory.lua`, bp `$1BF4`, `b@$04==0xAA`,
clean climb f5900–6300): the masked-blit draws **cel `$AA23` (data `$AA25`–`$AA30`) AND cel
`$AA31` (data `$AA33`–`$AA3E`) ON-SCREEN**, each at **exactly two X posts — Apple bytes 23 & 35**
(no col-11 instance ever), **rows 100–111**, sub-byte shift 5. So `$AA23`/`$AA31` are the wall-top
runner rendered on-screen — the commit-`18cf9b6` claim that they are "off-screen fight combatants
to remove" was **wrong** (that finding saw a *different* draw path — `draw_combatant_ad56/ad75`
parked off-screen — and missed that the same shared-bank cels are drawn on-screen as the wall-top
via the scene-sprite masked path; shared bank, two draw sites). **The port's original instinct to
draw `$AA23`/`$AA31` as wall-top scenery was correct.**
- **The `$96/$99` cels (`9600/964A/96CE`) are FLOOR cels (scene-5)** — unchanged; not the wall-top.

## The REAL wall-top — cels `$AA23` + `$AA31`, MASKED-BLIT, TWO posts, rows 100–111
| Property | Value (execution-confirmed) |
|---|---|
| Cels | **`$AA23`** (data `$AA25`–`$AA30`) **and `$AA31`** (data `$AA33`–`$AA3E`) — each h=12 w=1, ALREADY converted |
| Render mechanism | **masked-blit `$1BF4`** (SMC AND-mask blend + `$0900` shift table), sub-byte shift **5** |
| Position (X) | **TWO posts only: Apple bytes 23 & 35** (`$05`=`$17`/`$23`, the real byte col here). **No col-11 post.** |
| Position (Y) | **rows 100–111** (`$06`=`$64`=100 top; each cel is 12 rows tall, one source byte per row) |
| CoCo3 placement | byte 23 → `px=23*7+5+20=186` → **byte 46, sub 2**; byte 35 → `px=270` → **byte 67, sub 2**; rows 100–111 |
| Convert status | **NONE needed** — `$AA23`/`$AA31` already in `content/scenery/` |

## PORT vs ORACLE — the ACTUAL wall-top delta (small; premise was inverted)
The port ALREADY draws `$AA23` (`draw_climb_scenery`) and `$AA31` (`draw_climb_scenery_back`).
Three real differences, none involving new cels or removing `$AA23`/`$AA31`:
1. **Extra col-11 post** — the port draws each at cols **11, 23, 35**; the oracle draws only **23 & 35**. → drop the col-11 (`$0B`) instances.
2. **Sub-byte shift** — oracle shift 5 → CoCo3 **sub 2** (bytes 46 & 67); the port byte-aligns (sub 0 forced). → the two posts sit a few px off.
3. **Opaque vs masked** — port uses `HAL_gfx_blit_sprite_opaque`; oracle is masked/transparent. For a 1px-wide post the visible difference is the sub-byte black seam. `HAL_gfx_blit_sprite` (transparent, sub 0–3) reproduces it — **NO new primitive** (that conclusion still holds).

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
