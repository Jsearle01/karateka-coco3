## Form B Report — Fight Stage 1.5 (build): 3-phase sequencing

### §1  Timing (C-35)
t0=`2026-07-24T16:22:48-04:00` (§0 receipt stamp, HEAD `346ebed` at dispatch).
commit-time=`2026-07-24T16:53:08-04:00` (`git show -s --format=%cI HEAD`, HEAD `a5f1f55`).
Elapsed: ~30 min. Predicted band: n/a (no band table quoted in dispatch). Classification: n/a.

### §2  Summary
Built the trace-specified three-phase sequencing (walk-in with NO scroll → `$53` handoff at `$62=$0F` →
fight-shell scroll with the player holding `st`), verified it at the shape level (0 overruns). **Jay's MAME
gate rejected it: the walk-in "runs in place."** The composition trace said "walk-in = no scroll," but Jay's
eye/memory says the **run-in scrolls** (the B2' run+scroll) — and per the working agreement Jay's memory
overrides the trace. So the three-phase split had the boundary wrong: **the scroll IS the run-in, not a
separate later phase.** Reverted the stage-1.5 change (driver restored byte-identical to the pre-1.5 B2'
run-in), then, per a follow-on Jay note, **removed the defeated guard** from the run-in. Net delivered: the
confirmed-correct B2' run-in with the defeated guard removed. Prod `88eba89…` untouched.

### §3  Files modified
- `tests/scripted/scene6_b2prime_driver.s` — stage-1.5 walk-in restructure ADDED (`f7c3ccc`), then REVERTED
  (`f576ff2`); `draw_guard_parked` call removed from the run-in (`a5f1f55`).
- `harness/tools/oracle_walkin_detail.lua`, `oracle_fight_compo.lua` — trace tools (retained).

### §4  Reasoning (what the gate corrected)
- **§1 built as specified:** walk-in = plain `$62` walk (servo idle, `$50/$51` frozen — from stage-1b),
  `$52` held at 30, run animation; handoff at `$62=$0F` (`$53`:=`$FE`, `run_idx`:=`st`); fight = `$52`
  scroll with the player holding `st`. State-trace-verified: walk_pos 0B→0F with cur52=30 & run cycling,
  then cur52 30→1B with run_idx pinned. 0 overruns (84.4%).
- **The gate's correction:** with the background static during the walk-in, the run animation reads as a
  treadmill (no world-motion cue). Confirmed against the oracle: the attract walk-in moves the player only
  **+4 cols** (player screen col = `$62`, 0B→0F) against a fixed background — faithful, but it genuinely
  reads as running-in-place. B2' sold the forward-run by scrolling the world past the runner. Jay: "the
  run-in as it was previously is correct" → **the run-in has the world scrolling.**
- **Resolution:** trace-vs-memory fork; memory wins (per `walk-guard-trigger-finding.md` provenance).
  Reverted to the B2' run+scroll run-in. The trace's phase split (walk-in no-scroll → fight scroll) is the
  ATTRACT-DEMO tail, not the run-in Jay remembers; **the scroll belongs to the run-in.** The fight (player
  holds, guard closes, combat) is the POST-settle phase — where the `$62`-servo/`$53`-handoff pieces
  actually apply.
- **Defeated guard:** `draw_guard_parked` drew a mirrored DEFEAT pose (`$8DA9/$8E83/$8F0E/$9290`) during the
  run-in; the guard is not defeated there. Removed the call (routine kept for the future fight-phase entry).

### §5  Verification (AC-by-AC)
- Three phases play in order — BUILT + state-verified, but **REJECTED at Jay's gate** (walk-in reads as
  in-place); superseded by the revert.
- No run during the scroll / hold pose — was correct in the build, but moot after revert (B2' run+scroll is
  the accepted run-in).
- 0 overruns — PASS (84.4%) for the 1.5 build; the reverted B2' is the already-gated baseline.
- `SUBBYTE_ENABLE=0` unaffected — held throughout.
- **Net accepted (Jay 25.3):** run-in looks correct (Jay: "run in looks like it did before") and the
  defeated guard is gone (Jay: "its clean now").

### §6  Verdict-time evidence (§11)
25.1: `lwasm --decb` assembles clean; load `$0100..$4F5B` (< `$8000`). Health: cur52 sweeps 30→1B, halts,
PC sane. Driver source `git diff 346ebed HEAD~2` = empty at the revert (byte-identical restore).
25.3 operator-runtime-smoke: **Jay MAME visual gate — OBSERVED**: "run in looks like it did before" +
"its clean now" (defeated guard removed).

### §7  Reactive deviations
- Reverted the entire stage-1.5 build after Jay's gate (the walk-in/fight boundary was the wrong
  interpretation of the composition); removed the defeated guard on a follow-on Jay note. Both Jay-directed.

### §8  Uncertainty flags
- The composition's phase BOUNDARIES are now Jay-corrected (scroll = run-in), but the fight itself (player
  holds post-settle, guard closes, combat) is unbuilt — the `$62`-servo/handoff findings apply there, not to
  the run-in. The stage-1/1b servo spec + composition remain valid for the post-settle fight.

### §9  Follow-up candidates
- Fight combat (stage 2+): built against the confirmed run-in — the fight is the POST-settle phase (player
  holds, guard enters/closes, `$B29D` servo corrections). Guard entry uses the real (non-defeat) cels.
- Deferred: smooth-scroll Enhanced build (erase probe done — moderate ~3-frame glide fits, arch is the cost
  driver); B3 traverse (`$62`→`$2A`).

### §10 User interaction during task
Jay: "the player runs in place at the start" → "show me the oracle" (launched oracle windowed) → "no the
run-in as it was previously is correct" (→ revert) → "you need to remove the defeated guard" (→ removed) →
"its clean now" (accepted).

### §11 Candidate(s) captured this task
Candidate-worthy (not yet filed): *"a trace's phase BOUNDARIES can be faithful yet wrong for the product —
the attract walk-in is genuinely no-scroll, but the run-in the player remembers scrolls; when the visual
gate contradicts the trace's segmentation, the memory wins and the boundary moves. Confirm the phase split
against the gate, not just the trace."* Ties to [[filter-a-draw-trace-by-position-not-by-cel-id-range]].

### §12 Commit
`a5f1f55` (guard removed) on `wip`; the stage-1.5 build `f7c3ccc` was reverted by `f576ff2`. Prod
`88eba89b15cd…` byte-identical.
