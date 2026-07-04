# karateka-coco3 — Zero-Page (Direct-Page) Map

**Grep-derived · exhaustive · regenerable.** Every direct-page reference in the
source, organized by **lifetime-scope** so ZP can be chosen and safely reused
without collisions as the port continues.

> **Regenerate (re-grep = re-complete):** extract every `NAME equ $XX` (XX ≤ FF)
> and split by usage — `<NAME` (DP addressing) = a **ZP variable**; `#NAME`
> (immediate) = a **constant** that merely has a value ≤ $FF (NOT zero page,
> excluded). Then classify each variable's lifetime. Method + script are in the
> exec-history report (2026-07-04-zp-map.md). Coverage this pass: **44 source
> files** (engine + HAL + all controllers + boot path + all scene drivers/
> stages), **~60 distinct ZP addresses** in use.

> **⚠ STANDING RULE:** any dispatch that allocates, relocates, or renames a ZP
> byte MUST update this map (re-grep). A silent gap here gives a false "it's
> free" signal — which is exactly what has caused every ZP collision so far.

## Lifetime legend (the load-bearing field for reuse)

| Scope | Meaning | Reuse rule |
|-------|---------|-----------|
| **DURABLE** | Lives the whole run (set once / updated continuously). | Never reuse. |
| **SCENE-SCOPED** | Lives across a scene's frames; dead outside that scene. | Reusable by a *different* scene that never overlaps in time. |
| **SCRATCH** | Transient within one routine/op; no value survives the call. | Freely reusable between routines that don't nest. |

**Safe reuse = non-overlapping lifetimes.** Two names may share an address iff
their live ranges never overlap (temporal separation) — several do so
deliberately below (marked ALIAS), and each such alias states *why* it is safe.

---

## DURABLE ($10-$12, $50)

| Addr | Name | Owner | Purpose |
|------|------|-------|---------|
| $10 | `hal_frame_hi` | HAL time / VBL | 16-bit VBL frame counter (hi). Written by `hal_vbl_handler` (IRQ) — the ONLY ZP the VBL handler touches. |
| $11 | `hal_frame_lo` | HAL time / VBL | frame counter (lo). |
| $12 | `gfx_initialized` | HAL gfx | set $01 once by `HAL_gfx_init`; read as a guard. |
| $50 | `page_register` | engine/HAL | active draw-buffer token ($20=A / $40=B). Live the whole run; every present/flip touches it. |

---

## SCENE-SCOPED

### Intro / scenes 1-3 ($60-$61)
| Addr | Name | Owner | Purpose |
|------|------|-------|---------|
| $60 | `intro_input_flag` | boot / intro | game-start flag ($86 analog); set on input during a hold. |
| $61 | `intro_inputaux_flag` | boot / intro | companion ($4F analog). |

### Scene 4 — scrolling narrative ($62-$6E)
| Addr | Name | Owner | Purpose |
|------|------|-------|---------|
| $62 | `s4_scroll_s` | scene4_scroll | scroll state. |
| $64 | `s4_next_top` | scene4_scroll | next top row. |
| $66 | `s4_dest_row` | scene4_scroll | 16-bit dest physical row (scroll blit). |
| $68 | `s4_next_slot` | scene4_scroll | next slot. |
| $69 | `s4_kcount` | scene4_scroll | line counter. |
| $6A | `s4_copy_i` | scene4_scroll | memmove index. |
| $6C | `s4_base` | scene4_scroll | base ptr. |
| $6E | `s4_ctmp` | scene4_scroll | copy temp. |

### Scene 5 — driver loop locals ($3C-$3E)
| Addr | Name | Owner | Purpose |
|------|------|-------|---------|
| $3C | `g1_prevleg` | scene5 driver | previous-frame leg (walk-cycle edge detect). |
| $3D | `g1_prevstate` | scene5 driver | previous-frame pr_state. |
| $3E | `g2_phase` | scene5 driver | 0=throne / 1=cell (the transition hand-off flag). ALIAS: `g1_prevpx` in the older `scene5_akuma_ctrl_driver.s` (that driver has no phase; isolated binary). |

### Scene 5 — clock + princess controller ($42-$4F)
| Addr | Name | Owner | Purpose | Alias / hazard |
|------|------|-------|---------|----------------|
| $42 | `scene_clk` | scene5 (princess writes, Akuma reads) | the canonical `$3B`-analog scene clock. | **ALIAS** `sc_mir` (throne/cell stage scratch). SAFE: `draw_throne_stage`/`draw_cell_stage` write `sc_mir` at $42; the driver sets `scene_clk` AFTER every stage render — the clobber is always overwritten. |
| $43 | `pr_leg` | princess_controller | walk-leg / pose index. | **ALIAS** `sc_col` (stage scratch). |
| $44 | `pr_x` | princess_controller | derived byte col. | **ALIAS** `mf_h` (make_flipped). |
| $45 | `pr_cadctr` | princess_controller | cadence down-counter. | **ALIAS** `mf_w`. |
| $46 | `pr_px` | princess_controller | **master pixel position**. | **ALIAS** `mf_wctr`. |
| $47 | `pr_frac` | princess_controller | sub-pixel glide accumulator. | **ALIAS** `sc_ax`. |
| $48 | `pr_tmp` | princess_controller | scratch (registration align). | **ALIAS** `sc_npx` (16-bit). |
| $49 | `pr_state` | princess_controller | 0=walk 1=turn 2=fall 3=floor 4=stand 5=bow. | — |
| $4A | `pr_seqlen` | princess_controller | frames in current pose. | — |
| $4B | `pr_cadrel` | princess_controller | cadence reload. | — |
| $4C | `pr_shadow_lead` | princess_controller | shadow lead px. | — |
| $4D | `pr_holdctr` | princess_controller | 16-bit hold counter ($4D/$4E). | — |
| $4F | `pr_fullseq` | princess_controller | 1=full chain / 0=walk-loop. | **ALIAS** `sc_opq` (stage scratch). |

**$43-$4F princess ↔ stage-scratch overlap — SAFE (verified).** The
throne/cell stages' `draw_setdressing` scratch (`sc_col`/`mf_*`/`sc_ax`/
`sc_npx`/`sc_opq`, $43-$4F) overlaps the princess state. The stages render (a)
ONCE at init before the princess loop owns $43-$4F, and (b) mid-scene inside
`do_transition`/`g2_do_collapse`, which **save/restore $43-$4F** (13 bytes) around
the `draw_cell_stage`/door render. So the princess state survives every stage
render. [scene5_throne_stage.s ZP NOTE; scene5_e2e_driver.s do_transition/g2_do_collapse]

### Scene 5 — Akuma arm ($52-$55)
| Addr | Name | Owner | Purpose | Alias / hazard |
|------|------|-------|---------|----------------|
| $52 | `akuma_arm_idx` | scene5_akuma | arm pose 0/1/2. | **ALIAS** `frame_done` (kernel_per_frame). |
| $53 | `akuma_arm_ctr` | scene5_akuma | arm cadence counter. | **ALIAS** `frame_countdown`. |
| $54 | `akuma_arm_done` | scene5_akuma | one-shot done flag. | **ALIAS** `frame_sync_dc`. |
| $55 | `akuma_clr_ctr` | scene5_akuma | arm-box clear counter (2 frames on a pose change). | — |

**$52-$54 Akuma ↔ kernel_per_frame — CONFIRMED SAFE (stronger than dormant).**
`frame_done/countdown/sync_dc` are used ONLY by `per_frame_main_loop`
(kernel_per_frame.s). Grep confirms **`per_frame_main_loop` is NEVER called in
the prod boot** — `boot.s` runs the linear scene-1-4 controller then
`jmp scene5_run`; the "enters per_frame_main_loop" in boot.s is a **stale
comment, not code**. `frame_sync_dc ($54)` is never `<`-used in the prod engine
at all. So there is **zero runtime contention**: Akuma's $52-$55 is the sole
runtime user. (See LATENT COLLISIONS for the future risk.)

---

## SCRATCH (transient per-op)

### Blit engine ($08-$1F) — gfx.s, per-blit
| Addr | Name | Purpose |
|------|------|---------|
| $08 | `blit_height` | sprite height (per blit). |
| $09 | `blit_width` | sprite width. |
| $0A | `blit_col` | dest byte col. |
| $0B | `blit_row` | dest row. |
| $0C | `blit_subbyte` | sub-byte pixel offset 0-3. |
| $0D | `blit_ovf_new` | sub-byte overflow (new). |
| $0E | `blit_ovf_prev` | sub-byte overflow (prev). |
| $0F | `blit_tmp` | blit temp. |
| $13 | `blit_opaque` | opaque-mode flag (transparent vs opaque blit). |
| $14-$1F | `mix_col/row/desc/data/w/sc/rw/sr/nr/op` | mixed/masked-blit scratch. **$18 `mix_data` = `emask_ptr`** (the masked/stencil blit's mask base). |

### Sprite engine ($30-$3B) — globals.s, per-render / eng_clear_box
| Addr | Name | Purpose |
|------|------|---------|
| $30 | `eng_tbl` | animation table ptr. |
| $32-$35 | `eng_idx/cnt/cad/cadctr` | sequence index / count / cadence. |
| $36 | `eng_clrw` | clear-box width (also the dirty-rect width the scene5 restores use). |
| $37 | `eng_clrh` | clear-box height. |
| $38 | `eng_col` | col. |
| $39 | `eng_sub` | sub-byte. |
| $3A | `eng_row` | row. ALIAS `MMU_HAL_PAGE` is a CONSTANT ($3A) in scene4_scroll (not ZP). |
| $3B | `eng_fillval` | fill byte (0=clear, or a floor color). NOTE: `$3B` is the **Apple II scene-clock address**; here it is `eng_fillval`, and the port's scene-clock analog is `scene_clk` at **$42** (not $3B). |

### Throne/cell stage draw_setdressing ($40-$51) — init + save/restored mid-scene
| Addr | Name | Purpose | Overlap |
|------|------|---------|---------|
| $40 | `thr_off` / `sc_tmpx` | pr_copy_from_clean 16-bit offset ($40/$41) / stage tmp. | `thr_off` is **transient** (re-`std`'d before each use), so the stage's `sc_tmpx` clobber is harmless. |
| $41 | `sc_y` | stage row scratch. | = `thr_off` hi byte (transient). |
| $43-$48,$4F | `sc_col`,`mf_h/w/wctr`,`sc_ax`,`sc_npx`,`sc_opq` | draw_setdressing / make_flipped scratch. | overlaps princess $43-$4F — save/restored (see SCENE-SCOPED above). |
| $51 | `sc_pad` | leading transparent pad (964A). | **ALIAS** `page_source_blit` (durable blit-source, but only `<`-used by `timer_framesync.s`, which is NOT in the active prod path — so `sc_pad`'s use during scene 5 is harmless *now*; LATENT otherwise). |

---

## LATENT COLLISIONS (reported, NOT fixed — doc audit, HS-4)

These are SAFE in the current prod build but would collide if the noted
currently-absent code is wired in. A future dispatch must reconcile before enabling.

1. **$52-$54 — Akuma arm vs kernel_per_frame frame-sync.** If
   `per_frame_main_loop` (frame_done/countdown/sync_dc) is ever entered in prod
   (the boot.s comment implies an intended per-frame loop that is not currently
   wired), it collides with `akuma_arm_idx/ctr/done` ($52-$54) during scene 5.
   Reconcile: relocate the Akuma arm block, or gate the per-frame loop off during
   scene 5. **Currently safe** (per_frame_main_loop never called).
2. **$51 — sc_pad vs page_source_blit.** `page_source_blit` (the P2.1 blit-source
   token) is `<`-used only by `timer_framesync.s`. If frame-sync/present via
   `timer_framesync` is enabled while a scene-5 `draw_setdressing` runs,
   `sc_pad` ($51) clobbers it. **Currently safe** (timer_framesync not in the
   active path).
3. **$40/$41 — thr_off vs sc_tmpx/sc_y.** Safe only because `thr_off` is
   re-written before every use; if a future caller reads `thr_off` across a
   `draw_setdressing` call without re-setting it, it breaks. (Documentation of a
   discipline, not a live bug.)

---

## UNRESOLVED
None. Every DP reference resolved to a named owner + lifetime by grep + read.

## Notes on scope
- **Standalone test drivers** (`broderbund_*_driver`, `presents_test`,
  `sub_byte_shifter`, `sys_init_driver`, `kernel_dispatch_driver`,
  `princess_gate1/2_driver`, `scene5_akuma_ctrl_driver`, `scene5_stage_driver`,
  `sprite_engine_*_driver`, …) each build as their OWN binary with inline ZP
  copies (e.g. `blit_height_d $08`, `mmu_pre_0-7 $14-$1B`, `hl_row/lcol/… $4A-$4E`,
  `pk_/sb_ $40-$42`). Their ZP is **isolated** (never co-resident with prod), so
  it cannot collide with the prod path — listed here only for completeness.
- **Constants excluded** (value ≤ $FF but `#`-immediate, not ZP): `PAGE_A_TOKEN`
  $20, `PAGE_B_TOKEN` $40, `CLK_*` $04/$0D/$15/$22, `EAGLE_SWAP_CLK` $16,
  `AKUMA_CLK_DEFAULT` $15, `PR_FLOOR_FILL` $AA, `MMU_HAL_PAGE`/`S4_COPY_PAGE`.
- **Non-ZP regions the ZP map must avoid** (not DP, but noted so ZP choice stays
  clear): stack $0100-$01FF; scene-5 scratch buffers `FLIP_BUF $7E80` /
  `CLEAN_BUF $4A00` (below the framebuffers); framebuffers $8000-$FBFF.
