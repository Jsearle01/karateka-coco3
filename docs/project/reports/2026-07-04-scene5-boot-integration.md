# Scene-5 boot integration — exec history (2026-07-04)

Append the proven continuous scene 5 to the working boot chain so
**Broderbund → title → credits → scroll → scene 5 (throne → transition → cell →
collapse → halt)** plays as ONE continuous, demo-paced boot. Integration pass
(HS-3, no rebuild) confronting the three things the sandbox was insulated from:
the budget, the launch seam, and ZP/memory coexistence.

## Budget (AC-0, the gated first step) — FITS, no escalation
- Total content, all 108 sprites, all scenes: **11.6 KB**.
- Boot chain `karateka.bin` (pre): 7928 B. Scene-5 sandbox: 11711 B.
- Integrated prod (HAL dedup): **17978 B**. vs 128KB → **~110 KB free (86%)**.
- The real constraint is the **64KB CPU address space**, not 128KB (see HS-4).

## Launch hook (AC-1, HS-2) — CONFIRMED ABSENT
Jay's read ("a prod hook likely exists, just needs a buffer clear") was
**refuted** by reading prod: `src/engine/boot.s` is a linear controller
(broderbund → holds → scenes 2/3/4) ending at the scene-4→scene-5 cut with a
`bra boot_halt` placeholder ("Scene 5 = R-p27+"). No hook — scene 5 is appended
at that marked seam: `jmp scene5_run`.

## The seam + the callable (AC-2)
`scene5_e2e_driver.s` refactored: the arc body is now `scene5_run` (callable),
and the standalone scaffolding (org/IRQ/globals/HAL-init/`end`) is
`ifdef SCENE5_STANDALONE`-guarded. Sandbox builds with `-D SCENE5_STANDALONE`
(unchanged behaviour, +3 B for a jmp-to-next); PROD includes the same file
(no `-D`) in the build.bat prod line before `mem.s`, giving `scene5_run` +
sprite_engine + princess_controller + the scene-5 modules/content.
**Buffer clear:** `draw_throne_stage` already opens with a full-screen
clear-to-black, so the seam needs no extra clear (AC-2 satisfied by existing code).

## ZP coexistence (AC-3, HS-4)
scene 5's ZP (scene_clk $42, princess $43-$4F, akuma $52-$55, sc_* $41-$51)
overlaps globals' `frame_done/countdown/sync_dc $52-$54` and `page_source_blit
$51`. BENIGN: the VBL handler (`hal_vbl_handler`) touches ONLY `hal_frame_lo/hi
$10/$11`; `$52-$54` are used by `kernel_per_frame` (a *called* routine, not the
interrupt) which scene 5 never calls; scene 5 self-inits its ZP. Temporal
separation (scene 5 is terminal) → no runtime clash. Verified: the prod boot
trace runs scene 5 correctly after scenes 1-4.

## Memory hazard (HS-4, the real work) — RESOLVED
Prod code grew to `$0200-$483A` (18 KB). Scene 5's scratch `FLIP_BUF=$4000` and
`CLEAN_BUF=$4400` (15 KB full-framebuffer snapshot) now **collided** with the
code — at runtime the scratch writes would overwrite the code. Since it FITS in
128KB (HS-1 escalation is for *over* 128KB), resolved within 128KB by relocating
the scratch BELOW the framebuffers: `CLEAN_BUF=$4A00`, `FLIP_BUF=$7E80`, and
trimming the snapshot to the actor band **rows 0-167** (13440 B; max restore row
= 166 = PR_POSE_ROW 113 + PR_POSE_H 54; biggest mirrored sprite 327 B).
Code-to-scratch margin: **454 B**. Sandbox re-verified unregressed (557→0→0,
collapse reached). NOTE: the 64KB CPU space is now fairly full (18K code + 13K
scratch + 30K framebuffers) — future scenes may want 512KB banking (Jay's call).

## Verification (prod boot trace, prod_boot_trace.log)
Full prod image booted from `$0200`: scenes 1-4 → seam at +2890 (`scene_clk=$15`)
→ throne `$16..$22` → transition `$04`/g2_phase=1 → cell `$04..$0C` → COLLAPSE
(`pr_state=FALL`). **HS-1 leak check at the cell = 0 px** (throne actors dropped
clean in the prod layout too). Jay gate: the continuous boot plays clean to the
collapse.

## Files
- `src/engine/boot.s` — the seam (`jmp scene5_run`).
- `tests/scripted/scene5_e2e_driver.s` — ifdef refactor + scratch relocation.
- `tests/scripted/scene5_throne_stage.s` — FLIP_BUF relocation.
- `build.bat` — prod line appends the driver; sandbox line gets `-D SCENE5_STANDALONE`.

## Out of scope / follow-ups
- Sound stubs; the oracle-timed boot (demo-paced here, oracle guarded).
- 512KB banking for headroom if later scenes need it (Jay's architectural call).
