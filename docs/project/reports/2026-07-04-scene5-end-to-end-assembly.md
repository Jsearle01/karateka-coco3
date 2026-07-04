# Scene-5 end-to-end assembly — exec history (2026-07-04)

The culmination: scene 5 as ONE continuous run on a single `scene_clk` timeline —
throne (all 4 actors) → transition (`$3B=$04`) → SOLO cell (princess) → collapse
→ halt. An INTEGRATION pass (HS-3, no rebuild): assembles the proven pieces.

## What was assembled
New driver `tests/scripted/scene5_e2e_driver.s` = the **gate-2 scaffold**
(`princess_gate2_driver.s`: `do_transition` + cell walk-in + `g2_do_collapse`)
+ the **4-actor throne composite** (`scene5_akuma.s` + `scene5_composite.s`,
Jay-gated) + the **cell stage** (`scene5_cell_stage.s`). All via includes — the
actor/stage logic is untouched (HS-3).

## The transition hand-off (HS-1, the core)
At `$3B=$04`, `do_transition` calls `draw_cell_stage`, whose first act is a
**full-screen clear-to-black** — this DROPS the throne backdrop + the STATIC
actors (guard, Akuma body, eagle body) from both buffers + CLEAN_BUF. The
per-frame throne draws (Akuma arm/head, eagle) are gated OFF by `g2_phase` in
`pr_post_overlay` (throne branch vs cell branch). Result: the cell is
**princess-only, zero leak** — proven by memory dump: the Akuma/eagle region
(byte43-55, rows110-140) = **557 nonzero px in the throne → 0 px the first cell
frame → 0 px through the collapse**.

## Timeline (trace e2e_trace.log, final binary)
`$15`(stand) → throne walk `$16..$22` (13 increments) → TRANSITION `$22→$04`,
`g2_phase=1` → cell walk-in `$04..$0C` → `$0D` COLLAPSE (`pr_state=FALL`). One
continuous `scene_clk`. Collapse reached at +2289 frames.

## Pacing (Jay gate overrode strict HS-2 — documented)
The dispatch's HS-2 wanted strict ORACLE holds (383/173/173) end-to-end. At the
gate Jay judged that too slow and the oracle throne start (px80) too far left —
he asked for the gated demo throne feel carried through, and the cell sped to
match. Applied (all DELIBERATE, engine oracle defaults preserved behind the
`ifndef` guards):
- Walk `PR_CAD` 13→7 + glide `PR_PXDEN` 13→7 (2px/leg preserved — no slide, ~2x).
- Princess start px140 (oracle 80); `PR_ENDPX` 252 (140 + 13cyc*8px = 244 at `$22`).
- Pre-walk stand 383→60.
- Collapse turn/facing holds 173→87 (~2x); BOW 9 (unchanged).
This is a HS-2 deviation, made on Jay's explicit visual-gate authority (25.3).

## Door flash (gate-surfaced fix)
`g2_do_collapse` originally re-rendered `draw_cell_door` (full-clear + cell +
door) to both buffers and PRESENTED them — 2 princess-less frames = a flash when
the door appeared. Fix: draw ONLY the door sprite (`cell_door_tbl` via
`draw_setdressing`) over the existing buffers — the princess is never wiped;
present/flip stay paired (un-pairing them desyncs page_register from the VOFFSET
display — that made it worse). CLEAN stays = cell (she collapses ~byte27; the
left-doorway door ~byte9 is outside her dirty rect, so it's never restored away).

## ZP / page-register (HS-4)
Reuses the proven maps: princess `$43-$4F`, scene_clk `$42`, locals `$3C-$3E`,
`thr_off $40-$41`, Akuma arm `$52-$55`. No frame_sync (polled `HAL_time_vbl_wait`)
so the `$52-$54` frame-band collision is dormant, as in the gated drivers.

## Files
- `tests/scripted/scene5_e2e_driver.s` — the continuous-run driver (new).
- `build.bat` — registers it.

## Out of scope / follow-ups
- Sound stubs; prod-boot integration (wiring scene 5 into the game flow) — both
  separate passes. Prod `karateka.bin` unchanged (7928) — this is the SANDBOX run.
- Strict-oracle timing remains available (engine guards) for the eventual
  oracle-faithful build.
