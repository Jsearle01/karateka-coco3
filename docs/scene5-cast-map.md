# Scene-5 cast map — found by execution trace

Scene 5 = the imprisonment cutscene. The cast was located **empirically** by
instrumenting the real Apple II program and tracing the sprite-source pointer
(`$1B/$1C`, the saved sprite START) every frame from the imprisonment scene
($3D=$01, ~frame 3909) to the start of the climbing scene (frame 6019 = $A3E9),
then mapping each traced start to its oracle bank + dimensions (frame-4200
memory dump). Tools: `tests/scripted/trace_scene5_sprites.lua` (write-tap; the
tap returned no hits in this MAME, so polling carried it) and
`diag_sprite_ptr.lua` (per-frame poll of `$03/$04` + `$1B/$1C` + snapshots).

**CORRECTION (supersedes the earlier "skeleton reuse" claim, commit 455bcdd):**
that conclusion was wrong — reasoned, not found. The princess and guard DO
exist as their own sprite records, in banks the recon had dismissed as
"gameplay blobs" ($11e8, $1c7a) and the $8300/$8c67 region. Jay's MAME
observation (princess walks across toward the door, guard stationary
left/center, Akuma center-bottom, eagle on shoulder) + the trace + Jay's
per-sprite visual ID nailed them.

## PRINCESS — 14 frames ($11e8 + $1c7a), Jay-IDed

Converted unlabeled by address (`content/fig_XXXX/`); previews in
`content/engine-previews/cast/princess/`.

| Addr | H×W (px) | Pose (Jay ID) |
|---|---|---|
| $1530 | 43×8 | standing, facing right |
| $1867 | 43×8 | facing right, head bowed |
| $1611 | 43×12 | turning left, hair in air |
| $1588 | 43×12 | facing forward, mid-turn-to-left |
| $169A | 16×12 | facing left, torso only |
| $1D00 | 26×8 | body |
| $1D36 / $1D5A / $1D7E / $1DA2 | 17×8–12 | walking legs (4-frame cycle) |
| $175E / $16CC / $17D3 | 23/36/14 | falling animation |
| $1829 | 10×24 | on cell floor (collapsed) |

## GUARD — 3 frames ($8300/$8c67), Jay-IDed

| Addr | H×W (px) | Part (Jay ID) |
|---|---|---|
| $8F2B | 10×12 | head (oracle mislabel "feet_shadow") |
| $899C | 24×8 | torso / standing |
| $8ACB | 14×8 | below-torso (lower body) |

(Composited like the player: head + torso + below-torso.)

## Rest of scene-5 draws (from the trace)

- **Akuma** — COMPLETE (Jay-confirmed 2026-06-13): head/gloat
  `sprite_988B/98D3/9908/9956`+ ($9800, 9 frames) + throne torso
  `akuma_throne_room_9EB8` + **`akuma_feet_9F8C` = bottom of Akuma's robe + his
  feet** (legs are under the robe; feet poke out — two feet spread wide, $9B00).
  Note: `$974B` (43×24, mislabeled `floor_pattern_9743+8`) reads as an
  outline/negative = a render MASK, not a needed visible sprite.
- **Eagle**: `sprite_985C` (head) + `eagle_body_9FC4` + `eagle_head_9FD8`.
- **Cell door**: `sprite_9980` (75×8). **Banner**: `sprite_9a74`.
- **Floor / background**: `floor_pattern_95E4/964A/96CE/9743` ($8c67) — the big
  $96xx/$97xx cluster is the floor, NOT characters (early mis-read corrected).
- **Scenery** (Jay-IDed): bench-on-right-wall `$12C8` (50×40); floor texture
  `$14BE`, `$1200`; wall structure `$18BF`.
- **Player**: the $9B00 walk legs/torso (Jay-IDed as player, not princess) — a
  different scene's cast; left as `player_walk`.
- Climbing scene begins at frame 6019 ($A3E9, $a400 climb chain).

## Still unidentified (Jay "not sure")

`fig_18D0` (3×8), `fig_1CC4` (2×28), `fig_1CD4` (21×8), `fig_8EC1` (8×8),
`s5_9858`, `s5_9a18`, `s5_9a2a`. Minor fragments / ambiguous; revisit at the
scene-5 port if needed.

## Conversion recipe (reproducible; content untracked per rule)

The $11e8/$1c7a/$8300 banks are single-label blobs, so figures were extracted
**by address** from `dump05_imprison.bin` (H,W header + H×W bitmap) and run
through the fixed converter (`convert_sprite_to_coco3`). start_col=0
(unverified; parity/hue only — true positions come at scene-5 orchestration).
Handles `fig_<addr>`; rename to semantic names at the port.

## Notes

- Princess + guard are **composited multi-part figures** (head/torso/legs),
  assembled at scene-5 orchestration time (out of this dispatch's scope).
- The walk/fall/turn frame sequencing is the engine's data-driven job; the
  sandbox cycles them per-set for ID.
- **Sandbox animated confirm (Jay, 2026-06-13): PASS** — 8 cast sets
  (akuma_gloat / akuma_full / princess_walk / princess_fall / princess_poses /
  guard / eagle / props) cycle cleanly, **no striping** across the whole cast
  (color-cell fix holds), characters recognizable.
- **OPEN (deferred): some colors wrong** — the sandbox loads the Brøderbund
  palette (descriptor 0), not a throne-room palette. Hue accuracy is a palette
  follow-up at the scene-5 port; the striping fix is palette-independent.
