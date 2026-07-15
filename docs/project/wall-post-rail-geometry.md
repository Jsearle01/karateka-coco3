# Scene-6 wall post + rail — captured positions, geometry, flags (2026-07-15)

**Type:** authoring-pass record (art + geometry; NO placement — next dispatch). Prod `88eba89…`
untouched; authored content `content/scenery/scene6_wall_{post,rail}/` stays UNTRACKED until Jay's
visual gate. Generator: `harness/tools/gen_wall_post_rail.py` (rail derived from post col 3).

## Captured reference positions (HS-2 — the geometry reference; do NOT delete)
From the fallback `tests/scripted/scene6_cliff.s` wall-top tables (git-tracked → any future
removal is reversible via git):
| post | back layer (AA31) byte | front layer (AA23) byte | sub | row | front px (byte*4) |
|---|---|---|---|---|---|
| 1 | 24 | 25 | 0 | 100 | 100 |
| 2 | 45 | 46 | 0 | 100 | 184 |
| 3 | 66 | 67 | 0 | 100 | 268 |
Uniform pitch = **21 bytes = 84 px**. All three byte-aligned (sub 0).

## HS-3 — `sub` IS the sub-byte offset (arbitrary pixel X; no HAL change)
`gfx.s` §P2.4.1 `HAL_gfx_blit_sprite`: `blit_subbyte` 0–3 → 0/2/4/6-bit right shift = **0–3 px**
sub-byte placement. So the engine already places at any pixel X. **F1 not triggered.**

## HS-4 — post-1 X diagnosis (report, not fix) → **F3: no post-1-specific source**
All three posts derive **identically** from `gen_scene6_cliff.py` `SCENERY` (AA23/AA31 at Apple
cols `0x0B,0x17,0x23`, `sh=2`, byte-aligned via `place()`+`leading_trim`). There is **no distinct
source or error for post 1** vs posts 2/3 — they share one formula, one `sub` (0), one cel, uniform
21-byte pitch. So the reported "post 1 ~2px left of oracle" is **not** a per-post data error. What
the recon (`walltop-render-map.md`) actually shows: the **oracle draws only TWO posts** (Apple cols
23 & 35, sub-byte shift 5 → CoCo3 **sub 2**); the port's **col-11 post (post 1) is SPURIOUS** (not
in the oracle at all), and **all three** port posts are byte-aligned (sub 0) = a **uniform ~2 px**
left of the oracle's sub-2 positions — not a post-1 singleton. **Implication for placement:** the
fix is (a) drop the spurious post-1 and (b) apply sub 2 to the real posts — a uniform correction,
not a per-post hunt. (This matches the earlier `4b27dd8` wall-top delta finding.)

## HS-5/HS-6 — the gap geometry (for Jay's W choice)
Computed from **posts 2 & 3 only** (post 1 excluded per HS-4). Post width = 4 px.
- **G = X3 − (X2 + 4) = 268 − (184 + 4) = 80 px = 20 bytes.** (Invariant to the sub-align question:
  pitch is 84 px whether byte-aligned or oracle-sub-2, so G = 84 − 4 = 80 either way.)
- **Divisors of 80 (candidate rail-tile widths W):** 1, 2, 4, 5, 8, 10, 16, 20, 40, 80.
- **Byte-aligned (W % 4 == 0, no per-blit shift cost):** 4, 8, 16, 20, 40, 80.
- **Multi-segment byte-aligned (exclude W=80 = single span, HS-6):** **4, 8, 16, 20, 40**
  (→ 20 / 10 / 5 / 4 / 2 segments respectively).
- **F2 not triggered** — 80 is highly composite.
- **W is Jay's choice** (scroll-reveal granularity vs blit count). Sub-byte options (5,10 = 2/1 bytes
  + shift; 1,2 = fine but many blits) available if he wants finer reveal.

## HS-7 — the gap is `[I]` (single sample)
Only **one** complete post-to-post span exists in the data (posts 2→3). "Uniform 84-px pitch /
G=80" is an **assumption from one sample** (posts 2/3 matching the oracle is the best evidence
available — accepted, but not a measurement of universality). **Verify the pitch holds when
scrolling reveals more posts;** if it drifts, rail sizing revisits.

## HS-8 — mask path: existing `_masked` is PER-COLUMN; the post needs PER-PIXEL ⚠ FLAG
The post's col 3 is `t,t,w,b,b,t,t,w` — transparency **varies by row**. `HAL_gfx_blit_sprite_masked`
reloads its mask pointer **every row** (`gfx.s:857 ldu <emask_ptr` at `emask_row`) → it is a
**per-COLUMN** mask (same mask byte every row), which **cannot** express per-row-varying
transparency. And the palette trick (b=nonzero-black index, t=0, plain transparent blit) fails: all
4 indices are already used (0 blk / 1 orange / 2 blue / 3 white), so there's no free index to make
"opaque black" distinct from "transparent black." **So a per-PIXEL 2D mask is genuinely required.**
The authored masks here ARE per-pixel/2D (like `HAL_gfx_blit_stencil_punch`'s format, width×height,
advancing continuously) — but `stencil_punch` *punches to black*, it doesn't *composite* a colored
source. **PLACEMENT-DISPATCH ITEM:** a per-pixel masked COMPOSITE blit is needed (either a small new
leaf `(dest AND ~mask) OR source` walking a 2D mask, or reuse `stencil_punch` to clear then a
transparent blit to fill — TBD). **Authoring is unaffected**; this only affects how the next
(placement) dispatch renders it. Flagged, not silently refactored (no HAL change this pass).

## Authored art (single-sourced)
`POST` grid is the single source of truth in the generator; **`RAIL = [row[3] for row in POST]`**
(asserted) — the rail is post col 3, never authored twice (HS-1). Color plane: w=3 b=0 t=0;
per-pixel mask: 11=opaque (w,b), 00=transparent (t). Emitted:
`content/scenery/scene6_wall_{post,rail}/authored.s` (color plane + `_mask` plane).

Gate artifacts (external, for Jay): `build/wall_ref/wall_post_rail_sheet.png` (post + rail, magenta
= transparent) and `build/wall_ref/wall_composite_true_spacing.png` (two posts + rail at the TRUE
computed G=80, on sky bg so transparency reads as background-shows).
