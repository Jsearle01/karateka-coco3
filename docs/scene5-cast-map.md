# Scene-5 cast — structural handle → identity map

Scene 5 = the imprisonment cutscene. Sprites converted **unlabeled by
structural handle** (R cast scale-out); **identity attaches at Jay's sandbox
visual ID** (AC-4) and is recorded here for the scene-5 port.

Found **by content** (not by label): the differential analysis pins scene-5's
sprite-source pointer to the **$9800–$9FFF region** (d05=$9858, d06=$9980
cell-door; `$3D`="sprite-engine active" set scene-5-onward). Jay's MAME
observation of the real Apple II imprisonment scene: **Akuma center-bottom,
princess walks across toward the door (middle), guard stays left/center, eagle
on Akuma's shoulder.** That maps onto a leg+torso walk cycle + a big throne
Akuma + eagle parts in the **$9B00 bank** (whose recon "player" label was
tentative — corrected here by content).

Sandbox set order (tap = next set): 0 akuma_gloat · 1 walk_legs · 2 walk_torso
· 3 akuma_throne · 4 eagle · 5 figures · 6 props.

| Set | Structural handle | Addr | H×W (CoCo3 px) | Frames | Identity — **Jay AC-4 (2026-06-13)** |
|---|---|---|---|---|---|
| 0 | akuma_frame_0..8 | $9879–$9a62 | up to 36×19 | 9 | **Akuma** gloat (heads/torso/arm) — CONFIRMED (R-engine). *Note: shoulder shouldn't animate — compositing concern, see below.* |
| 1 | player_run_legs_9B00..9D1E | $9B00–$9D1E | up to 40×24 | 8 | **PLAYER** legs (not princess) — Jay-confirmed |
| 2 | player_run_torso_9D68..9E92 | $9D68–$9E92 | up to 24×23 | 8 | **PLAYER** torso (not princess) — Jay-confirmed |
| 3 | akuma_throne_room_9EB8 / akuma_feet_9F8C | $9EB8 / $9F8C | 36×42 / 44×9 | 2 | **Akuma** throne body + feet — consistent w/ "this is akuma" |
| 4 | s5_985c_eagle_head / eagle_body_9FC4 / eagle_head_9FD8 | $985c/$9FC4/$9FD8 | ≤16×9 | 3 | **eagle** parts — Jay-confirmed |
| 5 | s5_9a18 / s5_9a2a / s5_9858 | $9a18/$9a2a/$9858 | ≤24×18 | 3 | ambiguous figures — **unresolved** (guard candidate; Jay "not sure") |
| 6 | s5_9980_cell_door / s5_9a74_banner | $9980 / $9a74 | 16×75 / 68×10 | 2 | **cell door + "the end" banner** (props) — Jay-confirmed |

**Render correctness (AC-4/AC-5): no striping reported on any set** — the
color-cell fix holds across the whole cast; no blit-equivalence (wrong-blend)
failures observed.

## Princess / guard — find result (all banks walked by content)

**No dedicated princess or guard sprite set exists in the data.** Every
character bank is labeled player / enemy / akuma:

| Bank | Content | Princess/guard? |
|---|---|---|
| $0400 | font letters | no |
| $11e8 / $1c7a | gameplay hires bitmap blobs (bg/char, single-blob) | no (gameplay, INT-3) |
| $1E00 | scene 1–3 per-scene sprites | no |
| $8300 | **player** full anim (walk/punch/kick/block/side) — all player | no |
| $8c67 | player / **enemy**(combat) / death / pillars / floor | combat enemy only (gameplay) |
| $9800 | Akuma + eagle-head + cell-door + banner + 3 ambiguous figures | (figures = guard candidate) |
| $9B00 | **player** walk/run (Jay-confirmed) + Akuma throne/feet + eagle | no (player) |
| $a400 | attract **fight/climb demo** bank (climbing chain + fight-scene sprites via attract_dispatch.s) | no — different attract scene (scene 6 cast) |

**Conclusion — skeleton reuse.** Scene 5's sprite-source pointer (d05=$9858,
d06=$9980) stays in the $9800-region, and the only walk cycle there/adjacent is
the **player** skeleton ($9B00). The princess (Jay saw her walk across) is
almost certainly drawn with the **shared player walk frames**, and the guard
likewise reuses a skeleton (or is one of the $9800 ambiguous figures) —
differentiated at runtime by **state block** (position/palette), exactly the
data-driven engine model (characters = state-block + shared sprite sets, one
engine). There is no separate princess/guard *sprite set* to convert; their
identity is an **orchestration-time** distinction (which state block drives
which shared set in scene 5), deferred to the scene-5 port.

**Out-of-scope notes (scene-5 orchestration):**
- "Akuma's left shoulder shouldn't animate" — the real scene overlays a STATIC
  body + moving head/arm + a separate eagle on the shoulder; the sandbox cycles
  raw frames in place. A compositing concern, not a conversion bug.
- $a400 (attract fight/climb demo) is the next attract scene's cast — convert
  in a later dispatch when that scene is ported.

35 sprites total (9 already converted in R-engine; 26 this task). All through
the **fixed converter** (color-cell fill — solid fills, no striping; validated
on the throne Akuma + cell door). Converted content is **untracked** per the
standing content rule; previews under `content/engine-previews/scene5/`
(gitignored).

## Conversion recipe (reproducible; content untracked per rule)

- $9800 figures/props: `sprite_convert.py --source <oracle>/src/sprite_data.s
  --label sprite_<addr> --start-col 120` (address-form labels: 985c, 9980,
  9a74, 9858, 9a18, 9a2a).
- $9B00 bank: `--source <oracle>/src/sprite_data_9b00.s --label <name>
  --start-col 0` for every label in the bank.
- Akuma 9-frame: converted in R-engine (sprite_9879..9a62, start-col 120).
- start_col is unverified for $9B00 (true screen positions come at scene-5
  orchestration); affects only orange/blue parity, not the striping fix or ID.
