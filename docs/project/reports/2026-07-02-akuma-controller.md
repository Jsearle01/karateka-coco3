# Scene-5 Akuma controller — exec history (2026-07-02)

Resumes the paused Akuma controller. AC-0 (head-coupling: 5 `scene_clk` zones)
was already met (`b8f2a22`); the static composite + masked-blit feet were done +
gated (`4b8a08f`). This dispatch wires the **controller** (two behaviors) with
the **princess walk** driving the cross-actor coupling, and closes the
**masked-blit additive-safety regression**.

## Two behaviors (HS-1), separate
- **Arms — ambient free loop** (no clock): `akuma_ctrl_tick` decrements a
  cadence counter (`AKUMA_ARM_CAD`=24 VBLs) and cycles `akuma_arm_idx` 0→1→2→0,
  selecting frame_5 (98D3 hip) / frame_6 (9908 raised) / frame_7 (9956 pointing)
  via `akuma_arm_tbl`. `draw_akuma_arm` blits the current pose at byte52/row128.
- **Head — tracks the princess** (HS-2, single-source): `draw_akuma_head` reads
  `scene_clk` ($42, the canonical $3B-analog) and picks the frame per the 5-zone
  table (15-17→f1, 18-19→f2, 1A-1B→f3, 1C-1D→f4, 1E-22→f8) at byte49/row117/sub2.

## Single source of truth (HS-2)
`scene_clk` ($42) is the ONE clock. The **princess walk WRITES it** (Gate-1
mechanism: +1 per completed 4-leg walk cycle, $15→$22, capped); **Akuma's head
READS it**. No fork / re-derivation of her position.

## Compositing (HS-4, shared leaf)
`scene5_akuma.s` split: `draw_akuma_lower` (shadow, feet masked-blit, robe
outline, floor-ext, body 9EB8) + `draw_pauldron` = `draw_akuma_body` (STATIC).
`draw_akuma_arm` + `draw_akuma_head` are the DYNAMIC per-frame parts.
Driver `scene5_akuma_ctrl_driver.s`: throne stage + guard render into both
buffers and `CLEAN_BUF` (throne-only backdrop the princess restores/walks on).
Each frame the princess's `pr_post_overlay` hook (fired by `pr_render_walk`
before the flip, AFTER she is drawn) redraws Akuma OVER her so he occludes her.
She walks px140→220 completely across, IN FRONT of Akuma.

## Occlusion — the fig_974B silhouette (Jay-gated)
Akuma must occlude the princess trimmed to his EXACT figure, not a rectangle.
`fig_974B` (the recon "mask" sprite: white = not-Akuma, incl. the interior
arm/body gaps) is converted to a 2D punch stencil `akuma_stencil` (per pixel
11=figure/00=keep; col10 doubled-artifact trimmed). New additive HAL primitive
`HAL_gfx_blit_stencil_punch` (2D mask, `dest &= ~mask`) blacks his silhouette
BEFORE his transparent colors are painted → she shows only where his sprite
isn't. Head frames f4/f8 (the ones live while she's in front) get their own
filled span-fill silhouette stencils (eye + per-row notches opaque, 2px-shifted
for the sub-byte-2 head), punched after she is drawn. Arm ghost is cleared only
on a pose change (`akuma_clr_ctr`, 2 frames = both buffers).

## Scene furniture + polish (Jay-gated)
- Static left-doorway **guard** restored (`draw_scene5_guard`, `scene5_composite.s`)
  into both buffers + `CLEAN_BUF`.
- Her wide leading **shadow** cut the right-doorway post; `restore_right_doorway`
  re-lays the 2-byte post column (CLEAN_BUF bytes 68-69) over the shadow each
  frame (a narrow copy, not `draw_setdressing` whose `sc_*` temps alias
  `pr_leg`/`pr_state`/`scene_clk`; not a wide rect that would erase her shadow).
- **Walk pacing** (demo): `PR_CAD` 13→7 with glide `PR_PXDEN` 13→7 so
  2/7·7 = 2px/leg (oracle stride, ~2× faster, no slide). Both `ifndef`-guarded in
  the engine → oracle default unchanged. `AKUMA_ARM_CAD` 24→12. Start px140.
- `akuma_throne_room_9EB8` content: 4 detached blue floor-lines left of the robe
  (rows 32/34/36/38, bytes 0-1) zeroed.

## Additive-safety regression (HS-3, the MUST-CLOSE) — PROVEN
The masked blit (`HAL_gfx_blit_sprite_masked`, `4b8a08f`) is additive:
1. **git diff**: gfx.s = 175 insertions / **0 deletions** — the existing
   transparent (`HAL_gfx_blit_sprite`) and opaque (`HAL_gfx_blit_sprite_opaque`)
   routines are source-identical.
2. **framebuffer byte-diff**: princess Gate-1 (transparent figure + **opaque
   princess shadow**), rendered with current gfx.s vs parent (`4b8a08f~1`) gfx.s,
   both buffers (31744 bytes) — **byte-identical** (`cmp` clean).
So scenes 1–4 (same transparent routine) + princess shadow render unchanged.

## Memory-verified behavior (§2)
Sampled (`ctrl_probe`): arm_idx cycles 0→2→1 (ambient); scene_clk advances
15→17→1A with her walk (px40→84); head-region content shifts as the zone
crosses (f1→f3). Loop is draw-bound (runs <60Hz — a pacing tune, behavior OK).

## Files
- `tests/scripted/scene5_akuma.s` — controller split + arm/head/tick routines.
- `tests/scripted/scene5_akuma_ctrl_driver.s` — the integration driver (new).
- `build.bat` — registers the controller driver.

## Follow-ups
- Arm-cycle registration (per-pose X/Y offsets) + the loop pacing may need a
  Jay-gate refinement pass.
- Eagle controller + sound: separate dispatches.
