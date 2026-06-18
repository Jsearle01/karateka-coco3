# Scene-5 stage TWO — the CELL — RENDER PROGRAM (captured by trace — the authority)

Captured by executing the imprisonment scene (apple2e + `dumps/karateka.dsk`)
to the **cell/collapse phase** and tracing the draw entries (`tools/probe_cell.do`):
`bp 0A03,b@0x3b<0x0d&&b@0x3d==1` — triggers on the first cell-phase floor fill,
then `trace`s ZP args at every instruction; the draw entries
(`$0A00`/`$0A03` fills, `$1903`/`$190C` blits) are extracted.

**Phase / how reached (poll3d.lua):** scene 5 `$3D=$01`. `$3B` counts the
inner clock: throne room `$3B=$15` (f3902, captured in 1a) → walk-in counts
`$16..$22` (f4324-4895) → **at `$3B=$22` it RESETS to `$04` (f4905) = the
d05→d06 backdrop CHANGE** → cell/collapse phase counts `$04..$0C` (f4905-5183)
→ held. The cell loop (`display_7700.s` L7B6D) runs `scene_2`+`scene_3` while
`$3B < $0D`. Cell state confirmed by `dump06_imprison_late.bin`
(`$3B=$0C,$84=$05,$8F=$06`). **Distinct from the 1a throne-room program**
(`scene5-draw-program.md`, `$3B=$15`).

## Ordered cell backdrop draw-call program (static stage = collapse actor excluded)
One cell-loop frame; constant across frames. `$0F`=blend (01=opaque),
src=`$04$03`, x=`$05`, y=`$06`, `$10`=sub/flip; fills `$05/$09`=cols, `$06/$08`=rows.

| # | call | args | $0F | role |
|---|---|---|---|---|
| 1 | **0A03** | cols 4–30, rows 159–168, D5/AA/80/80 | 01 | **FLOOR strip (dual)** |
| 2 | 190C | $9600 @ x6,y$53, sub6 | 01 | doorway lintel/rail (mirror) |
| 3 | 190C | $964A @ x5,y$5F, sub6 | 01 | doorway post (mirror) |
| 4 | 1903 | $1200 @ x8,y$A9 | 01 | floor texture |
| 5 | 1903 | $12C8 @ x30,y$84 | 01 | **bench (right)** |
| 6 | 1903 | $14BE @ x10,y$99 | 01 | floor texture |
| 7 | 1903 | $18BF @ x4,y$99 | 01 | **wall structure (left)** |
| — | (actors: princess collapse $1CD4 sub3 $0F=FF, $1CC4 sub3 $0F=FF, $1D00 $0F=00, $1D5A) | | | OUT OF SCOPE (1b) |
| 8 | 190C | $96CE @ x2,y$5F, sub6 | 01 | doorway post (mirror) |
| 9 | 1903 | $18D0 @ x2,y$A9 | 01 | small element |
| 10 | **0A00** | cols 0–3, rows 95–173, $80 | 00 | left wall (black) |
| — | (per-frame actor-erase: 0A00 cols 3-8/4-9/6-B/7-C rows 119-163 — track the falling princess) | | | OUT OF SCOPE (1b) |

## Capture-corrected facts (vs static read / 1a)
- **NO cell door `$9980`, NO banner `$9A74`** — absent from the entire capture
  (no `04=99`/`04=9A` blit). The static read's idx5-door attribution is WRONG
  (same trap 1a caught). The cell "doorway" is the **floor-pattern gate**
  (`$9600/964A/96CE` mirror) + `$18BF` wall — NOT a door sprite.
- Cell set-dressing = `$96xx` (floor-pattern gate, LEFT/mirror only — not both
  gates like the throne) + `$1200/$14BE` (floor textures) + `$12C8` (bench,
  RIGHT) + `$18BF/$18D0` (wall/element). The bench + wall 1a correctly
  excluded from the throne — they live HERE.
- ALL cell set-dressing is **opaque** (`$0F=01`); floor strip opaque; left wall
  `$80` (black). The per-frame variable-col `0A00` clears = collapse-actor
  erase, NOT backdrop.
- Cell floor = `0A03 cols4-30 rows159-168` (a STRIP — narrower/shorter than the
  throne's full `cols4-36 rows153-182`).
- CoCo3 map (1a): apple px = byte×7; CoCo3 px = apple px + 20.

## The CELL DOOR `$9980` is an ANIMATION event (1b), not static backdrop
Confirmed by trace (tools/poll_door.lua + tools/probe_door.do, Jay-directed
2026-06-18). `$84` (the door trigger) is **00 through the entire walk-in and
the cell walk-in loop** (`$3B`=15→22 throne, then the `$3B`=04→0C cell loop
where the princess walks in on legs `$1D5A`). It flips to **`$84=05` at frame
5235** — *after* the princess finishes walking into the cell (`$3B` loop exits
~f5222) and *before* her turn/pose sequence (`$39`=08→12, f5235+). The door is
then drawn by scene_3's `draw_combatant_mirror`:
- **`$9980` mirror**, `$05=$26-$22=$04`, `y=$5B`(91), `$10`=6, **`$0F=00`
  (transparent)**, at `$84=05 $3B=0C $39=08`.

So the door belongs to the **collapse/imprison ANIMATION (pass 1b)** — it does
NOT appear in the static cell backdrop. Excluding it here is correct (Jay gate).
This draw call is recorded for 1b. (Earlier mis-attributions putting `$9980`
in the static stage — static-read in 1a — are wrong: it's a timed event.)

Trace evidence: `C:\karateka-capture\cell.log` (probe_cell.do, f≈4905);
`poll_door.log` + `doordraw.log` (the door event, f5235).
Reference image: `build/logs/snapshots/scene5_ref/apple_cell_page1.png`
(dump06_imprison_late, rendered via tools/ref_cell.lua).
