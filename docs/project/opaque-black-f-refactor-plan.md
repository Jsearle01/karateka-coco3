> **SUPERSEDED (2026-07-20).** This 4bpp `f`-format refactor is NOT needed. The
> existing HAL blits already do mixed per-pixel opacity with NO pixel-format change,
> 2bpp preserved:
>   - `HAL_gfx_blit_sprite_mixed`  — byte-aligned opaque/transparent rectangles.
>   - `HAL_gfx_blit_sprite_masked` — sub-byte, per-column-uniform opacity.
>   - `HAL_gfx_blit_stencil_punch` — arbitrary per-pixel 2D silhouette (Akuma-grade).
> Opacity lives in a **derived sidecar** (`opacity.s`) beside each cel, authored by the
> sprite tool (derive-by-geometry, no default, verified by re-render); `converted.s`
> stays 2bpp byte-identical; the registry three-state (`converted`/`none`/`authored`)
> + a lint (`authored`⟺sidecar) enforce determinacy. So the cross-cutting 4bpp change
> (HAL rewrite, re-encode all opaque content, re-gate everything) is avoided entirely.
> Plan retained below for provenance only — do NOT implement it.

# Opaque-black `f` refactor — plan (dedicated effort, Jay-directed 2026-06-19)

## Goal
Replace the whole-sprite opaque/transparent mechanism with ONE blit that
respects a per-pixel sentinel `f` = opaque-black:
- pixel `0` = **transparent** (always — the key)
- pixel `f` = **opaque black** (always — drawn solid)
- pixels `1`/`2`/`3` = orange/blue/white (drawn)

No opaque mode, no mask, no extra plane — just the pixel value in the sprite.

## Why a format change is required (the blocker)
The framebuffer is 2 bits/pixel and ALL four codes are used: 0=black, 1=orange,
2=blue, **3=white**. White is used by the figures (princess, guard, Akuma). So
`f` CANNOT reuse index 3 — that would turn every white pixel opaque-black. For
`f` to be a distinct value, each sprite pixel needs >2 bits →
**4bpp (one nibble per pixel: 0/1/2/3 + F)**, or 1 byte/pixel. The framebuffer
stays 2bpp; only the SPRITE storage widens, and the blit maps nibble→2bpp
(`0`→skip, `F`→write 0/black, `1/2/3`→write the 2-bit color).

Per Jay: opacity is decided per-sprite/per-pixel at PORT time (not knowable at
conversion), so the opaque pixels are HAND-marked `f` in the sprite data.

## Scope (cross-cutting — touches gated work; re-gate everything)
1. **HAL (`src/hal/coco3-dsk/gfx.s`):** rewrite the blit to read the wider
   (nibble) format and treat `f` as opaque-black; DELETE `HAL_gfx_blit_sprite_opaque`,
   the `blit_opaque` flag ($13), and the opaque mask table; change the call
   signature (drop the opaque mode).
2. **Converter:** emit the wider format (or a compat path) so existing 2bpp
   content still assembles; provide a way to mark `f`.
3. **Content:** re-encode the previously-OPAQUE sprites, setting their solid
   black `0`→`f`. Known opaque users:
   - throne stage: `floor_971D`, `floor_9743` (OPAQUE in scene5_throne_stage.s)
   - cell stage: `floor_9600`, `floor_964A_cell`, `floor_96CE`, `fig_18D0` (OPAQUE)
   - **princess shadow**: `pr_draw_shadow` uses `HAL_gfx_blit_sprite_opaque`
   - guard: shadow (opaque) — and any parts set opaque
   - Akuma: feet `9F8C` (the trigger case — needs mixed opaque/transparent)
   - door `9980` / others as found (grep `_opaque`)
4. **Callers:** replace every `HAL_gfx_blit_sprite_opaque` call with the single
   blit; update the throne/cell `draw_setdressing` opaque-flag column + the
   composite/guard/Akuma tables.
5. **Regression / re-gate:** Gate-1 (throne walk), Gate-2 (cell transition +
   collapse), the static throne+guard stage, the door — all use opaque blits and
   must be re-gated. prod 7634 must stay unregressed (prod uses no sprites? verify).

## Akuma resume (after the refactor)
This dispatch (Akuma controller) is PAUSED mid-build. On the new model:
- finish the **feet** mixed transparency (mark the foot black `f`, gaps `0`) —
  the case that motivated this refactor;
- re-enable the **shadow** (`AKUMA_SHADOW`) — Jay had it temporarily off;
- wire the **controller**: head-tracks-princess (reads `scene_clk`, 5-zone table,
  docs/project/scene5-akuma-head-coupling.md) + arms-ambient free loop;
- integrate the princess walk to gate the cross-actor coupling (AC-4).
Static composite so far (positions from the authoritative blit-entry trace,
head placed by pixel at px199): tests/scripted/scene5_akuma.s.
