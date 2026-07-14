# Climb-beat static setup inventory — clean, execution-confirmed (2026-07-14)

**Type:** READ-ONLY identification. **Recipe:** CLEAN `-video none -keyboardprovider none`.
**Prod ROM:** `88eba89b15cdf17c8d25e082d2d3e1f3cce57d38` untouched. Frames my-boot (provenance).
**Method:** bp every render routine (`$1903` std / `$190C` mirror / `$1BF4` masked / `$0A09`
`$0A40` pattern-fill) during the clean climb, read the ordered draw program.

## D2 — Boundary (first character sprite)
The first character sprite is the player crawl pose **`$A40B`(torso)+`$A425`(legs)** (std blit,
col 0B/0A). Everything drawn before it in a redraw = static setup; the pose is where animation
begins. (anim_00 `$A3C5/$A3E9` start is drawn at the princess→climb transition and held in.)

## D3 — Once-at-setup vs per-frame
**PER-STEP full-tableau redraw.** The whole background (fills + cliff + wall-top + Fuji) is
redrawn at each crawl step (~7 VBL), then the player pose over it (wall-top masked cels observed
×2 across 2 steps; cliff `$AB8E` stack redrawn per step). Not once-and-hold, not every-VBL.

## D1 — Full static inventory (in draw order), technique per element
| # | Element | Cel(s) | Position (HGR) | Technique |
|---|---|---|---|---|
| 1 | Sky / backdrop fills | — | rows per-band | **pattern-fill** `$0A09`(1-col)/`$0A40`(2-col) ×~13 |
| 2 | Ledge | `$AA11` | row 104 (`$68`), tiled cols 0–18+ | std blit `$1903` |
| 3 | Cliff structure | `$AB4A`(row112 col0), `$AB7C`(row104 col0A), `$AB94`(row112 col0A) | col 0/0A | std blit |
| 4 | Base | `$AA7D` | col 6, row 152 (`$98`) | std blit |
| 5 | Cliff face | `$AB8E` ×19 | col `$0A`, rows 117–151 (`$75–$97` step 2) | std blit |
| 6 | **Wall-top runner** | **`$AA25`–`$AA30`** (12 cels) | **row 100, cols 23 & 35, sub-byte shift 5** | **MASKED-BLIT** `$1BF4`+`$0900` |
| 7 | Fuji | `$A948/$A976/$A9B8/$A9E2` | Fuji stack | std blit (`AD30`/`ADD1`) |
| 8 | HUD | `$0B12` | row 185 (`$B9`), player-side | std blit |
| — | (combatants `$AA23/$AA31`) | — | **x=`$FE` OFF-SCREEN** | not visible in climb |

Scene sprites (`draw_scene_ae7a`, 18-entry table) render at X = `$52`(scroll `$30`) ± `xadj[i]`.

## D4 — COMPLETENESS cross-check vs the port substrate (the deliverable)
Port `scene6_climb_crawl_driver` draws (9): fill_sky, fill_walltop, draw_climb_scenery_back,
draw_fuji_cels, draw_climb_ledge, draw_climb_striations, draw_climb_scenery, draw_climb_ground_right,
draw_hud_player.

**The wall-top is NOT the only wrong element (F1 confirmed):**
| Port routine | Oracle reality | Verdict |
|---|---|---|
| fill_sky | pattern-fills (sky band) | ✓ OK (equivalent direct fill) |
| fill_walltop | pattern-fill band | ✓ OK |
| **draw_climb_scenery_back (`$AA31`)** | `$AA31` is an OFF-SCREEN COMBATANT | **WRONG — spurious post; not oracle scenery** |
| draw_fuji_cels (`$A9xx`) | Fuji std blit | ✓ OK |
| draw_climb_ledge (`$AA11`) | `$AA11` tiled row 104 | ✓ OK (matches) |
| draw_climb_striations (blue fills) | oracle draws `$AB8E` ×19 cel-stack (std blit) | ⚠ TECHNIQUE DIFFERS — port approximates the cliff-face with fills instead of the `$AB8E` cel; Jay-gated as acceptable but not the oracle render |
| **draw_climb_scenery (`$AA23` + AB rails + `$AA7D`)** | `$AA23` is an OFF-SCREEN COMBATANT; AB rails + `$AA7D` correct | **`$AA23` WRONG — spurious post**; rails/base OK |
| draw_climb_ground_right (fills) | pattern-fills (ground band) | ✓ OK (equivalent) |
| draw_hud_player (`$0B12`) | `$0B12` std blit row 185 | ✓ OK |
| **(MISSING) wall-top runner `$AA25–$AA30`** | masked-blit, row 100, cols 23 & 35, shift 5 | **MISSING — the wall-top itself** |

### Summary of what the build must fix (NOT wall-top only)
1. **ADD the wall-top runner** `$AA25–$AA30` via masked sub-byte-shift blit (unconverted — convert first).
2. **REMOVE the spurious `$AA23`/`$AA31` posts** (draw_climb_scenery / draw_climb_scenery_back) — they are off-screen fight combatants, not climb scenery.
3. **Cliff-face technique:** the oracle draws the `$AB8E` cel stack (std blit); the port uses blue striation fills. Jay-gated OK, but flag the divergence (the build could switch to the `$AB8E` cel if fidelity requires).
CORRECT as-is: fill_sky, fill_walltop, draw_fuji_cels, draw_climb_ledge, the AB rails + `$AA7D` base in draw_climb_scenery, draw_climb_ground_right, draw_hud_player.

## Port consequence
The wall-top build is bigger than "add the runner": also **remove the two spurious combatant
posts** (`$AA23`/`$AA31`) the port currently draws as scenery, and (optionally) reconsider the
cliff-face fills vs the `$AB8E` cel. Convert `$AA25–$AA30`; build the masked sub-byte-shift blit
(shared with Stage-4 combatants); framebuffer-diff the untouched pieces to prove no regression.
