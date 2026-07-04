# Scene-5 eagle controller — exec history (2026-07-04)

The last and lightest scene-5 actor. Perched on Akuma's shoulder, throne-phase
only. Recon (`scene5-akuma-eagle-recon.md`): NOT a wing-flap/fly — a static
body plus ONE clock-keyed head-swap.

## Behaviour
- **Body `9FC4`** (9×4) — STATIC. Drawn into both buffers + `CLEAN_BUF` at init,
  AND redrawn each frame in the composite hook (see occlusion below).
- **Head** — initial `9FD8` (6×4) through the pre-walk stand (`scene_clk=$15`);
  swaps ONCE to `985C` (4×3) when the walk begins (`scene_clk>=$16`), then HOLDS
  for the rest of the throne phase. A single beat-triggered frame change — no
  loop, no fly. Dirty-rect restore from `CLEAN_BUF` under the head box so the
  smaller `985C` leaves no `9FD8` ghost (verified by memory dump: `9FD8` = 6 rows
  110–115, `985C` = 4 rows 110–113 after swap with rows below cleared).
- **Tail** — NOT drawn here (it is part of the Akuma sprite). Body + head only
  (`content/bird/` holds exactly body + 2 heads — no tail sprite).

## Occlusion (dispatch said none; Jay corrected at the gate)
The dispatch assumed the eagle drew clear. At the gate the princess (walking
px140→220, passing Akuma's left shoulder at byte44–48) was drawing OVER the
static eagle body. Fix: the eagle body + head are both redrawn in
`pr_post_overlay` AFTER the princess (and Akuma), so the eagle sits in front of
her. Plain transparent redraw-on-top — no stencil/masked machinery (her only
overlap is the body silhouette, no black-gap show-through observed at the gate).

## Wiring (HS-5, shared leaf)
`scene5_composite.s`: `draw_scene5_eagle_body` (static blit) +
`draw_scene5_eagle_head` (reads canonical `scene_clk`, picks `9FD8`/`985C`,
dirty-rect head box from `CLEAN_BUF`). Driver `scene5_akuma_ctrl_driver.s`: body
into both buffers + `CLEAN_BUF` at init; body+head in the princess's
`pr_post_overlay` hook (the shared leaf — no new render path).

## Position (Jay-gated, EQU tunables)
Akuma's LEFT shoulder (recon apple-x was misleading — right; corrected to left).
Final: body byte45/row116; head `9FD8` byte43-sub3/row110; head `985C`
byte45-sub3/row112 (its own position — the two frames sit differently). Restore
box byte43–48 / rows110–115 covers both head frames.

## Throne-only (cell carry closed)
Throne-phase only; no cell presence. The recon's cell-phase flap-absence carry
is closed by "solo princess in the cell" (Jay) — nothing else is on screen there.

## Files
- `tests/scripted/scene5_composite.s` — eagle routines + constants + bird content.
- `tests/scripted/scene5_akuma_ctrl_driver.s` — eagle wired into init + the hook.

## Out of scope / follow-ups
- Sound stubs; the final end-to-end assembly (throne-all-actors → transition →
  solo cell) — separate passes.
