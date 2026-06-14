# C-14 RECON REPORT — scene-5 mechanism (scenery · `$3B` · halt · sound triggers)

**Type:** READ-ONLY recon (no oracle edit/build/commit) · C-35 estimate-grade
**Executor:** Clyde · **Operator/Gate:** Jay · **Date:** 2026-06-14
**Stamp:** `t0=2026-06-14T15:49:14Z`
**Sources:** oracle `karateka_dissasembly_claude` (roundtrip-verified scene-5 bytes vs
`dump05_imprison.bin`) + apple2e MAME live `$3B`/`$3D` poll (confirmed).

Answers the three pass-one-blocking questions for the scene-5 port's first increment
(scenery + Akuma), plus an operator-directed R4 (sound triggers). All findings are
grounded in the proven disassembly bytes (not the behavioral model's prose labels)
and the `$3B`/`$3D` execution trace.

---

## R1 — Scenery rendering primitive: **MIX** (corrects the model's "scenery = sprites")

Every scene-5 draw phase calls **both** primitives:

- **Region-fill — the `$0A00` family** (`render_frame_0a00.s`):
  - `render_pass_a` ($0A09) — single-colour rectangle blit
  - `render_pass_b` ($0A40) — dual-colour 2D-pattern rectangle blit
  - `render_clear` ($0ABF) — AND-mask region clear
  - **Parameterization:** `$05`=col-start, `$09`=col-end (clamp $28), `$06`=row-start,
    `$08`=row-end → `render_setup` computes `$0D`=col-span, `$0E`=row-span; pattern
    bytes `$02`/`$11` (pass_a) or `$02`/`$11`/`$12`/`$13` (pass_b, via
    `set_sprite_pattern` = `$D5/$AA/$80/$80`); page base `$07`.
  - **Call sites:** `draw_fight_scene_0` `jsr L0A03`; `draw_fight_scene_2` `jsr L0A03`;
    `draw_fight_scene_3` → `L78B5` → `jmp L0A00`. These paint the floor/background.
- **Sprite-blit — the `$1900` family** via `tbl_sprite_*_a` for set-dressing objects
  (cell door `$9980`, bench `$12C8`, wall `$18BF`, floor-detail sprites) + characters.

**The "possibly-undiscovered rectangle algorithm" the dispatch flagged EXISTS** — it is
the `$0A00` family (the same one the scene-4 scroll uses; callers: attract_render,
attract_state, intro, input). The behavioral model never traced its scene-5 use, so its
"scenery = sprites (`tbl_sprite_*_a`)" claim is **incomplete**.

**→ Port impact:** the scenery draw group is **fill-based AND sprite-based** — it needs a
region-fill primitive (the CoCo3 already has one from the scene-4 scroll) plus the
R-engine sprite leaf. This is a material input to the port design.

---

## R2 — `$3B` scene state machine: two-phase clock in `fight_round_main` ($7AF7)

`$3B` = imprisonment progression counter, advanced by the **princess walk cadence**
(one position-step per 4-frame leg cycle, per `advance_princess_anim`).

Byte-read structure, **confirmed live** by the `$3B`/`$3D` trace (frames noted):

```
init: $3D:=$01 (scene-active), $3B:=$15, $39:=0      [trace f=3902: $3D 60->01 $3B=15 $99=0B]
PHASE 1 (walk-in, loop L7B49, draws via draw_fight_scene_0):
  hold while $3B < $16 ; at $16 set $56:=$10          [trace: $56 0E->10 at $3B=$16]
  hold while $3B < $22                                 [trace: $3B 15→22 monotonic]
  at $3B >= $22  -> reset $3B:=$04, enter phase 2      [trace f=4905: $3B 22->04]
PHASE 2 (hold->fall, loop L7B6D, draws via draw_fight_scene_2 + _3):
  hold while $3B < $0D                                 [trace: $3B 04→0D]
  at $3B >= $0D AND $39==1 -> FALL: dec $3B, $39:=$13  [trace f=5226: $3B 0D->0C, $39 01->13]
  fall/collapse sequence -> scene_state_restore
exit anytime $3D==0
```

Live `$3B` sequence captured: `15 16 17 18 19 1A 1B 1D 1E 1F 20 21 22  04 05 07 08 09 0A 0B 0C 0D  0C(+$39=13)`.
The model's bare thresholds `$16/$22/$0D/$04` are now structured: `$16`=midpoint flag,
`$22`=phase-1 end, `$04`=phase-2 reset (not a threshold), `$0D`=fall trigger.

---

## R3 — Halt point: **NO clean terminal** (flagged)

`fight_round_main` runs walk-in→fall then returns, but the outer `scene5_main_loop`
($B4DB, `scene_dispatch.s`) is **infinite** — it holds the collapsed tableau and exits
**only** via the attract-end gate (`LB260` arms PRGEND `$AF` → `$B5D7: jmp $B766`), which
restarts the whole intro+attract cycle. The finite `scene5_first_loop` (`$99`:11→0) is
just the walk-in; the hold is unbounded.

**Confirmed live:** after the fall (~frame 5226) `$3D` **stays `$01`** and `$3B` stops
advancing through frame 6800 (trace cap) — the scene holds indefinitely, no terminal.

**→ Port impact:** the port needs an **artificial halt at the observed end** — fall/collapse
complete (princess on cell-floor frame `$1829`; the `$3B=$0C` / `$39=$13` collapse). Jay's
"halts at the end of the imprisonment scene" maps to stopping there rather than entering
the infinite attract hold + loop-back.

---

## R4 — Sound triggers (operator-directed; sound SYSTEM stays HAL/INT-3)

Per Jay: wire the **trigger hooks** into the scene-5 port now (no-op stubs) so later HAL
sound work just fills the leaf — the sounds need not play yet, but the framework is in place.

**Mechanism:** the `$1000` jmptable (`timer_dispatch.s`) — each entry loads a sound-record
pointer into `$F7/$F8` and JMPs to `$0D00` (sound_engine, `sound.s`, speaker square-wave
tones) **only if `($4F AND $86) != 0`**. So the trigger calls are *always present*,
conditionally voiced — the ideal shape for stub hooks.

**The 9 scene-5 trigger call sites + their sound records:**

| Call site | Entry → record | Phase / event (R2) |
|---|---|---|
| `display_7700.s:419` (scene_init_7a) | `L1000`→$114D | scene setup |
| `display_7700.s:452` (scene_init_7a) | `L100C`→$1173 | scene setup |
| `display_7700.s:585` (fight_round_main) | `L1012`→$105B | phase-1 init (walk-in begin) |
| `display_7700.s:595` (fight_round_main) | `L100C`→$1173 | phase-1 (walk-in) |
| `display_7700.s:642` (fight_round_main) | `L1000`→$114D | phase-2 **fall start** |
| `display_7700.s:650` (fight_round_main) | `L1015`→$115D | phase-2 fall (`$39==$0C`) |
| `display_7700.s:657` (fight_round_main) | `L100F`→$1130 | phase-2 **fall end / land** |
| `scene_dispatch.s:395` | `L1009`→$108C | first-loop→hold transition |
| `scene_dispatch.s:473` | `L1003`→$10D7 | alt loop-back (scene end) |

(Lower-level `$C030` speaker SFX helpers also exist in `display_7700.s` — `L77B9`/`L77C7`/
`L77D7` — but the primary trigger framework is the `$1000` jmptable.)

**→ Port wiring:** place a no-op `HAL_sound_trigger(record_id)` stub at each call site,
keyed to its R2 phase; later HAL fills the `$0D00` leaf. Nothing plays now; framework present.

---

## §3 Deviations (flagged, not acted on)

- **R1 scenery is a MIX** — both primitives needed; model's "sprites-only" incomplete.
- **R3 no clean halt** — scene bleeds into infinite attract hold + loop-back; port halt
  becomes an observed-end artificial stop (fall-complete).
- **R4 sound** is a scope addition beyond the dispatch's R1/R2/R3 (dispatch deferred sound
  to INT-3), added per operator direction to wire trigger stubs now.
- **R1/R4 "fires" not yet PC-confirmed:** the `$0A00` fill and `$1000` sound calls are
  proven in the call graph but confirming they *execute* live needs a PC breakpoint
  (interactive `wpset` — the dependable method on this target). R2/R3 ARE live-confirmed
  by ZP poll. Separable follow-up if desired.

## Instrumentation method (and a harness fix)

- Per-frame **ZP polling** via `add_machine_frame_notifier` (the method that works on this
  apple2e target — scripted write-taps + do-Lua callbacks do not fire). Gated out boot
  transients (`$3D==$01` flickers <frame 2000 with `$3B`/`$99` garbage); real scene 5 =
  `$3D 60->01` at frame 3902 (`$3B=$15`, `$99=$0B`).
- **Harness fix:** the first runs produced nothing because the Lua used single-backslash
  Windows paths (`C:\k…` → invalid Lua escape) so the autoboot script failed to compile,
  and MAME then ran the full `-seconds_to_run` with no early `exit()` (the 3-min "hangs").
  Fixed: forward-slash `io.open` paths, state-gated early exit (`$3D` 1→0). Verified
  `-nothrottle` IS effective (~1085% speed; full trace in 12.3s real).

## Candidates captured: **None** (read-only recon; output is this spec).

---

**Port pass-one drafts off:** R1 (build the scenery draw group = region-fill primitive +
sprite leaf) + R2 (the `$3B` two-phase clock, thresholds live-confirmed) + R3 (artificial
halt at fall-complete) + R4 (stub sound hooks at the 9 trigger sites). Princess + guard
per-actor internal animation remain their own later increments.
