# Does the walk trigger the guard entry? — TRACE finding (2026-07-18) — REPORT ONLY, no build

**Classification: TRUE — the guard entry is WALK-TRIGGERED.** Established by EXECUTION INTERVENTION on
the running attract (oracle apple2e), reproduced across runs — not correlation. **STOP at the
classification; nothing built.**

## Mechanism (from the disassembly — provisional labels, past scene 4)
`$B29D` is a position servo (`attract_state.s`): routes on **`$62` vs `$0F`** — `>$0F`→backward step
(`routine_b30f`), `<$0F`→forward step (`routine_b381`), `==$0F`→idle (clear `$53`). `routine_b3df` adds a
±26 delta to `$62/$72/$91`. So **`$62` = the walking combatant's position, servo'd toward `$0F` = the
fighting distance**; `$72` = the guard's position; `$33 = $72−$62` = the closing distance.

## Baseline trace (clean recipe `-video none -keyboardprovider none`, reproduced ×2 — identical, seed-deterministic)
`walk_guard_trace.lua` (write-taps on `$62`/`$59`; `$1903/06/09/0C` blit trampolines for the guard head
`$8ECB` — these DO fire on 6502, §7b):
- **The walk:** `$62` climbs monotonically **0B→0C→0D→0F** (f6418→f6454) as the player advances; `$33`
  distance closes 25→21; `$72` (guard) still 30.
- At **`$62`=`0F`** (f6454), `$53` flips (`$FE`) — the walk-complete transition.
- **GUARD ENTERS:** guard head `$8ECB` first draws at **f6487** (`$62`=`0F`).
- **FIGHT goes live:** LCG seed `$59` first non-zero at **f6698** (as `$72` closes 30→20).

Correlation only — NOT sufficient on its own (a timer could co-fire). The intervention is the discriminator.

## Intervention — the discriminator (reproduced ×2)
**Pin `$62` below `$0F` (per-frame force `$62=05`, so the walk can never reach the fighting distance)**
over f6000–7200:
- `$62` **held at 05** the whole window (proven: f6000/6200/6400/6600/7200 all `$62=05`); **`$72` stayed
  30** — the guard's approach never even started.
- **Guard head `$8ECB` NEVER draws** (`guard_draw=nil`); **fight seed `$59` NEVER activates**
  (`fight_seed=nil`) — through the full window, both runs.

⇒ **Suppressing the walk (holding `$62` off `$0F`) suppresses the guard entry AND the fight entirely.**
The guard/fight are **caused by the walk reaching the fighting distance**, not by a timer or scene index.
**TRUE — walk-triggered.**

*(Method note: a write-tap re-clamp did NOT pin `$62` — the triggering write commits AFTER the tap
callback, overwriting it. A per-frame FORCE in the frame notifier is what actually pins a servo'd byte.)*

## Provenance / caveats (past scene 4)
- The disassembly LABELS (`$62`=walk position, `$8ECB`=guard head, `$59`=fight seed) are **provisional**;
  the **causal result is execution-confirmed regardless of label**: this ZP the servo drives to `$0F`,
  and pinning it off `$0F` deterministically suppresses the guard-draw + the fight.
- **Jay's memory of the game sequence is ground truth** and overrides the trace if they disagree — this
  matches the known Karateka flow (walk toward the palace ⇒ the guard confronts you).

## The fork (this dispatch's whole output)
**TRUE ⇒ fight-build order = walk build → concurrency model → guard.** Nothing downstream is built until
Jay reviews this. **Report only — STOPPED at the classification.**
