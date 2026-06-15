# Scene-5 static-stage RENDER PROGRAM (captured by wpset trace — the authority)

Captured by executing the imprisonment scene (apple2e + `dumps/karateka.dsk`)
and breaking on the draw entries with a MAME debugger `trace` (probe7.do):
`bp 0A03,b@0x3b==0x15` starts a trace logging ZP args at every instruction;
the draw entries (`$0A00`/`$0A03` fills, `$1903`/`$190C` blits) are extracted.
**This SUPERSEDES** the prior reused state-trace (`trace_scene5_pos.lua`, a
per-frame ZP poll — no draw calls) and the static draw-routine read
(past-scene-4 hypothesis). Scene 5 is `$3D=$01,$3B=$15` from frame 3902.

## Ordered draw-call program (static stage = actors excluded)
Fills: `$05`=col-start, `$09`=col-end, `$06`=row-start, `$08`=row-end,
pattern `$02/$11/$12/$13`. Blits: src=`$04$03`, x=`$05`, y=`$06`, `$10`=sub/flip.

| # | call | args | role |
|---|---|---|---|
| 1 | 0A00 | cols 26–32, rows 124–143, $80 | black clear (invisible) |
| 2 | 0A00 | cols 25–27, rows 113–119, $80 | black clear (invisible) |
| 3 | **0A03** | **cols 4–36, rows 153–182, D5/AA/80/80** | **FLOOR (dual pattern)** |
| 4 | 1903 | $9600 @ x32,y83 | floor pattern idx0 (rail) N |
| 5 | 190C | $9600 @ x6,y83, sub6 | idx0 mirror |
| 6 | 1903 | $971D @ x36,y173 | floor pattern idx3 N |
| 7 | 190C | $971D @ x2,y173, sub6 | idx3 mirror |
| 8 | 1903 | $964A @ x33,y95 | post idx1 N |
| 9 | 190C | $964A @ x5,y95, sub6 | idx1 mirror |
| 10 | 1903 | $9743 @ x32,y153 | floor pattern idx4 N |
| 11 | 190C | $9743 @ x6,y153, sub6 | idx4 mirror |
| 12 | 0A00 | cols 8–15, rows 161–162, $80 | black clear |
| — | (actors: guard $899C/$8F2B/$8ACB; princess $1D00/$1DD7/$1CC4/$1CD4; $9A18/$8EC1) | | OUT OF SCOPE |
| 13 | 190C | $96CE @ x2,y95, sub6 | post idx2 mirror |
| 14 | 1903 | $96CE @ x36,y95 | post idx2 N |
| 15 | **0A00** | **cols 0–3, rows 95–173, $80** | **left wall (black)** |
| 16 | **0A00** | **cols 37–40, rows 95–173, $80** | **right wall (black)** |
| 17 | 0A00 | cols 26–38, rows 169–172, $80 | black clear |
| — | (actors: Akuma $9EB8 + gloat $988B/$98D3, feet $9F8C, mask $974B, $984F; eagle $9FC4/$9FD8/$9858) | | OUT OF SCOPE |

## Key corrections vs the prior (wrong) reconstruction
- Set-dressing = **only idx0–4** (`$96xx` floor patterns/posts). NO cell door
  `$9980`, NO bench `$12C8`, NO `$18BF`, NO `$1200`/`$14BE` — those were
  static-read mis-attributions / other scenes.
- Mirror = **simple `$26−x`** byte + `$10=6` + h-flip — NOT a width-aware
  reflection.
- Only the **floor `0A03` dual-fill is visible**; all `0A00` fills (walls +
  clears) are `$80` = black (invisible on the black backdrop).
- CoCo3 map: apple px = byte×7; CoCo3 px = apple px + 20 (centred 280 window).

Trace evidence: `build/logs/scenes/scene5_drawtrace.log` (probe7.do).
