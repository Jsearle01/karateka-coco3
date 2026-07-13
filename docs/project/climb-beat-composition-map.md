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
- What IS genuinely not-in-the-clean-climb: the **`$A3` bank** (`scene6_climb_A3C5`, `A3E9`) —
  absent from the clean climb (they're the princess→climb transition / fight poses), and the
  fight-midground `$A684` (absent, 0 draws).
**Interpretation:** the earlier "climb = fight" retraction over-generalized. The climb and the
subsequent guard-fight happen on the SAME cliff, so they legitimately SHARE the `$AB` cliff +
Fuji + `$AA11` floor banks. The pose set differs: climb = `$A4`/`$A5` + `$8ACB`; the `$A3C5/A3E9`
start-pose the Stage-3 build used is transition/fight, not the climb crawl. So the Stage-3
backdrop+cliff+HUD were substantially RIGHT; its errors were (a) using `$A3C5` as the pose and
(b) a static tableau instead of the crawl animation. **Jay to confirm this reframing.**

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

## D3 — Crawl animation (the 7 displayed poses)
Pose cels: `$A4`/`$A5` chain (`A400/A40B/A425/A45A/A4A4/A4D2/A4F2/A500/A502/A548/A572/A5CC/A5DC`)
+ `$8Axx` figure (`8ACB` settle, `899C/8E9B/8EC1`), at col 0A–0C (X40–48), rows Y120–148,
ascending. **No `$A3` bank.** Displayed animation = 7 frames (`scene6_climb_anim_00–06`):
**21 VBL start-hold, then 5 crawl poses at a steady 7 VBL each, then settle on `$8ACB` (y124)**
(held ~294 VBL). anim_00 start (y158) is transition-adjacent (manifest drawptr `$A3E9`); the
crawl proper (anim_01–05) is `$A4`/`$A5`.

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
| **`$A3C5`/`$A3E9`** | `content/player/scene6_climb_A3C5`, `A3E9` | **MISLABELED** — absent from clean climb (transition/fight); flag for rename, don't delete (Jay) |
Most climb cels are already converted + correctly named. The only mislabels: `scene6_climb_A3C5/A3E9`
(not climb) and `fig_8ACB` (under guard/, is the climb settle). No unconverted climb cel found.

## Port consequence
Stage-3 target = Fuji+floor backdrop (same as fight) + the `$AB/$AA` cliff scenery + the
**`$A4/$A5/$8ACB` crawl ANIMATION** (21+5×7-VBL) + player-side `$0B12` HUD. The existing
converted cels are reusable as-is (they are climb, not fight). Do NOT build the `$A3C5` static
tableau — replace it with the crawl animation.
