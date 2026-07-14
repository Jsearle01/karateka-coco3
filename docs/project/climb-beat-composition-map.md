# Climb-beat composition map — clean, execution-confirmed (2026-07-13)

**Type:** READ-ONLY identification. **Recipe:** CLEAN `-video none -keyboardprovider none`
(no key-leak). **Prod ROM:** `88eba89b15cdf17c8d25e082d2d3e1f3cce57d38` untouched. Frames
my-boot (provenance). **Evidence:** clean draw-program trace of the climb beat f6050–6160
(`build/logs/climbbeat.txt`), grounded against Jay-gated `scene6_climb_anim_00–06`.

## ⚠ DISPATCH-PREMISE CONFLICT — surfaced per HS-1 / F3 (needs Jay)
The dispatch states the `$A3C5/$AB` climb identity is RETRACTED as fight, and that
`content/player/scene6_climb_*` + `content/scenery/scene6_cliff_*` are "FIGHT cels — do not
reuse." **The clean climb-beat trace refutes this for most of them:**
- The clean climb DRAWS the `$AB` cliff (`AB8E` etc), the `$A4`/`$A5` crawl poses, the `$AA11`
  floor, Fuji (`$A9B8/$A948`), and the player HUD (`$0B12`). These are the REAL climb content.
- `content/player/scene6_climb_A425…A5DC` and `content/scenery/scene6_cliff_AB8E/AB94/AB7C/AB4A/AA*`
  are **correctly named + already converted** — they match the clean climb cels at the right
  positions. They are NOT fight cels.
- **CORRECTION 2026-07-13 (Jay-confirmed):** `$A3C5`(torso)+`$A3E9`(legs) ARE the climb — the
  **anim_00 START pose** (Y158), drawn at the princess→climb transition and HELD through anim_00
  (so they don't RE-draw inside f6058–6118, but they ARE the displayed start frame). The real
  climb-vs-fight discriminator is the fight-midground **`$A684`** (absent from the climb, 0 draws).
**Interpretation:** the earlier "climb = fight" retraction was an over-generalization of a
PIXEL contamination (windowed runs booted the actual game — Jay's "that's fight" was right for
those pixels). The climb and the later guard-fight happen on the SAME cliff, so they SHARE the
`$AB`/Fuji/`$AA11` banks. The full climb pose set = `$A3C5/A3E9` start → `$A4`/`$A5` crawl →
`$8ACB` settle. So the Stage-3 backdrop+cliff+HUD AND the `$A3C5` start pose were RIGHT; its only
error was a **static tableau instead of the 7-frame crawl animation**. **Jay confirmed this reframing.**

## D1 — Backdrop (D-4 resolved: core SAME as the fight backdrop)
| Cel | Position | Role |
|---|---|---|
| `$A948` | col 12 / Y81 | Fuji peak |
| `$A9B8` | col 0F / Y100 | Fuji |
| `$AA11` | cols 00→26 / **Y104** | **full-width floor line** (identical to `scene6_backdrop.s` `draw_floor_line`) |
**D-4 verdict:** the climb backdrop CORE = Fuji + full-width `$AA11` floor at Y104 = **SAME as
the fight backdrop** (`scene6_backdrop.s`). Difference: the climb has **no `$A684` fight
midground** (0 draws) and adds the cliff scenery (D2). So: same backdrop core, climb-specific
cliff on top, no fight midground.

## D2 — Scenery (the cliff the player climbs)
| Cel | Position | Role |
|---|---|---|
| `$AB8E` | col 0A, rows Y104–Y151+ (×114) | vertical cliff climbing-surface strip |
| `$AB94/$AB7C/$AB4A` | col ~0A | cliff structure |
| `$AA7D` | base | cliff base |
| `$AA31/$AA23/$AA03/$AB03` | — | scenery band |
Static (redrawn each step). Shared `$AA/$AB` banks with the fight, arranged as the climb cliff.

## D3 — Crawl animation (7 frames, each a torso+legs composite — clean blit-entry positions)
| Frame | Torso | Legs | Dwell |
|---|---|---|---|
| anim_00 START (Y158) | `$A3C5` | `$A3E9` | 21 VBL |
| anim_01 | `$A40B` (0B,Y140) | `$A425` (0A,Y148) | 7 |
| anim_02 | `$A45A` (0C,Y139) | `$A4A4` (0A,Y143) | 7 |
| anim_03 | `$A4D2` (0B,Y137) | `$A4F2` (0A,Y143) | 7 |
| anim_04 | `$A548` (0B,Y131) | `$A572` (0A,Y141) | 7 |
| anim_05 | `$A5CC` (0C,Y120) | `$A5DC` (0B,Y127) | 7 |
| anim_06 SETTLE | `$8ACB` (0B,Y124) + `899C/8E9B/8EC1` | — | hold (~294 VBL) |
Cadence: **21 VBL start, 5×7 VBL crawl, settle**. anim_00 (start) is drawn at the transition and
held; the crawl proper (anim_01–05) is `$A4`/`$A5`, all ascending to the `$8ACB` settle.

## D4 — HUD: PRESENT (re-opened finding resolved)
`$0B12` drawn ×90 during the clean climb, at cols 00–18, **row Y185 = player-side (LEFT), bottom**.
So the arrow HUD IS drawn during the climb, player-side. (The earlier "contaminated" worry does
not apply — this is the clean trace.)

## D5 — Convert status + labeling
| Element | content/ path | status |
|---|---|---|
| crawl poses `$A4/$A5` | `content/player/scene6_climb_A425…A5DC` | **converted, correctly named** (climb) |
| settle `$8ACB` | `content/guard/fig_8ACB` | converted; **mislabeled "guard"** → climb settle figure |
| cliff `$AB*` | `content/scenery/scene6_cliff_AB8E/AB94/AB7C/AB4A` | **converted, correctly named** (climb) |
| base/band `$AA*` | `content/scenery/scene6_cliff_AA*`, `content/background/scene6_bg_AA*` | converted |
| floor `$AA11` / Fuji `$A9*` | `content/background/scene6_bg_AA11/A9B8/A948/A9E2/A976` | converted (shared backdrop) |
| HUD `$0B12` | `content/hud/arrow_0B12` | converted |
| `$A3C5`/`$A3E9` START | `content/player/scene6_climb_A3C5`, `A3E9` | **converted, correctly named** (climb anim_00 start pose) |
All climb cels are already converted + correctly named (`scene6_climb_A3C5…A5DC` are the crawl,
`scene6_cliff_*` the cliff). Only labeling note: `fig_8ACB` sits under `content/guard/` but is the
climb settle figure. No unconverted climb cel found. **No cel needs renaming** (the earlier
"rename `$A3C5/A3E9` as fight" was withdrawn — they are the climb start).

## Port consequence
Stage-3 target = Fuji+floor backdrop (same as fight) + the `$AB/$AA` cliff scenery + the
**`$A4/$A5/$8ACB` crawl ANIMATION** (21+5×7-VBL) + player-side `$0B12` HUD. The existing
converted cels are reusable as-is (they are climb, not fight). Do NOT build the `$A3C5` static
tableau — replace it with the crawl animation.
