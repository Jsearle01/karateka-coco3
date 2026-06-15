# Scene-5 static-stage spec (AC-0) — fill bounds + set-dressing positions

**Source (oracle, read-only):** `karateka_dissasembly_claude/src/display_7700.s`
(`draw_fight_scene_0/1/2/3`, `tbl_sprite_*_a`) + `render_frame_0a00.s` (the
`$0A00` region-fill primitive). Read 2026-06-14 for scene-5 pass 1a.

> **HYPOTHESIS until gated (HS-3):** these bounds/positions are read from the
> draw routines; confirmed only when the rendered stage matches the Apple II
> imprisonment reference. Mismatch → re-trace/adjust.

## The `$0A00` fill primitive (what it actually does)
Rectangular pixel-fill over hires rows `[$06..$08]` × byte-cols `[$05..$09]`
(Apple 7px/byte, cols 0–39; `$28`/`$29` clamp). Three entries:
- **L0A00 / render_pass_a** — **single-colour**: odd rows ← ZP `$11`, even rows ← ZP `$02`.
- **L0A03 / render_pass_b** — **dual-colour (2×2)**: even cols use `$02`(even row)/`$11`(odd row),
  odd cols use `$12`(even row)/`$13`(odd row). This is the floor *texture* (checker/dither).
- **L0A06 / render_clear** — AND-mask `#$BF` clear (not used for the stage paint).

`set_sprite_pattern`: `$02=$D5 $11=$AA $12=$80 $13=$80` (the floor pattern).

## Fill backgrounds (the imprisonment stage)
Apple byte-cols (×7 = px), rows are 1:1 (0–191). Drawn across scene_0 (init) +
scene_2 (per-frame floor repaint) + scene_1/scene_3 (walls):

| # | role | cols (byte / px) | rows | pattern | variant | drawn by |
|---|---|---|---|---|---|---|
| F1 | floor (full) | `$04..$24` / 28–252 | `$99..$B6` (153–182) | D5/AA/80/80 | dual (L0A03) | scene_0 |
| F2 | floor strip (repaint) | `$04..$1E` / 28–210 | `$9F..$A8` (159–168) | D5/AA/80/80 | dual (L0A03) | scene_2 |
| F3 | **left wall** | `$00..$03` / 0–21 | `$5F..$AD` (95–173) | `$80` | single (L0A00) | scene_1/3 (L78B5) |
| F4 | **right wall** | `$25..$28` / 259–280 | `$5F..$AD` (95–173) | `$80` | single (L0A00) | scene_1 (bg_6) |

F2 ⊂ F1 (per-frame strip to erase the walking princess); for the *static* stage,
F1 + F3 + F4 define the backdrop (F2 is the same texture, redundant when empty).

## Set-dressing sprites `tbl_sprite_*_a` (11 entries)
X-position is an Apple byte-col; **normal** col = `x`, **mirror** col = `$26 - x` (= 38−x).

| X | addr | x (byte) | y (row) | identity | draw (scene) | content dir |
|---|---|---|---|---|---|---|
| 0 | $9600 | $20 | $53 | floor/ground pattern | mirror+normal (0,2) | floor/floor_9600 |
| 1 | $964A | $21 | $5F | floor/ground pattern | mirror+normal (0,2) | floor/floor_964A |
| 2 | $96CE | $24 | $5F | floor/ground pattern | mirror (1,3) | floor/floor_96CE |
| 3 | $971D | $24 | $AD | floor/ground pattern | normal+mirror (0) | floor/floor_971D |
| 4 | $9743 | $20 | $99 | floor/ground pattern | normal+mirror (0) | floor/floor_9743 |
| 5 | $9980 | $22 | $5B | **jail cell door** | mirror via $84 (3) | scenery/s5_9980_cell_door |
| 6 | $1200 | $08 | $A9 | floor texture | normal (2) | floor/fig_1200 |
| 7 | $12C8 | $1E | $84 | **bench (right wall)** | normal (2) | scenery/fig_12C8 |
| 8 | $14BE | $0A | $99 | floor texture | normal (2) | floor/fig_14BE |
| 9 | $18BF | $04 | $99 | **wall structure** | normal (2) | scenery/fig_18BF |
| 10 | $18D0 | $02 | $A9 | small element | normal (3) | unsorted/fig_18D0 |

`$84`=5 at scene init → cell door (idx5) drawn **mirror** (col `$26-$22=$04`) in scene_3.

## Real-position parity (HS-2)
All set-dressing was converted at `start_col=0` (per `scene5-cast-map.md` §recipe)
— **parity unverified at real columns.** At its real X, an Apple-hires sprite's
colour interpretation can flip; a reversed sprite → re-convert at its real-column
parity. Expected to surface here for some set-dressing.

## Coordinate translation (Apple → CoCo3)
Apple hires byte-col `c` → Apple px `c×7` → CoCo3 px `c×7` (1:1 pixels) →
CoCo3 byte-col `(c×7)>>2`, sub-byte `(c×7)&3`. Rows 1:1. (Port mode 320×192×4,
80-byte stride; verify against HAL_gfx_init before building.)
