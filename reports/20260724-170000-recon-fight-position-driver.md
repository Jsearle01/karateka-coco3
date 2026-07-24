## Recon Report — what drives POSITION during the fight (servo vs actions)

**Class:** PURE RECON (trace + read). NO build. `wip`. Prod `88eba89…` byte-identical.

### §0  Receipt / status
t0=`2026-07-24T16:56:09-04:00` (HEAD `af24c96`, `wip`). git status clean (pre-existing untracked only).
Prod `build/karateka.bin` sha1 `88eba89b15cd…` untouched.

### §1  The discriminator — write-tap `$62`/`$72`, attribute by writer PC
Write-tapped `$62`/`$72` over the fight window (`$59` live → guard-down, f6650–8720); logged the writer PC
(`CURPC`). **383 position writes**, split cleanly by writer:

| writer PC | routine | writes | % |
|---|---|---|---|
| **`$7091` (→`$62`), `$7075` (→`$72`)** | **combat engine** (`gameplay_7000`: `check_position_a/b`) | **271** | **71%** |
| **`$B3AB`/`$B359` (→`$62`), `$B357`/`$B3AD` (→`$72`)** | **servo** (`routine_b381`/`b30f` cluster inc/dec) | **112** | **29%** |

Both write. `$62`=combatant-A (player) pos, `$72`=combatant-B (guard) pos (from `combatant_a_init` at
`$7000`: `lda #$0B / sta $62`). The `$70xx` writer is the **combat engine's jmptable_7000** (dispatches
`combatant_*_init`, `check_position_a/b`, `combat_round_manager`, `compute_action_class`, `update_range_flag`).

### §2  Findings
1. **The servo RUNS during the fight** (un-freezes): `routine_b381`/`b30f` (the cluster inc/dec at
   `$B3AB`/`$B357`) fired **112×** in the fight window — vs stage-1b's finding that `$50/$51` are frozen and
   the servo idle in the walk-in. So the servo IS a fight-time layer. **But it is a MINORITY writer (29%).**
2. **The combat engine is the DOMINANT position driver** (71%). `check_position_a` (`$7091`→`$62`, 132×) and
   `check_position_b` (`$7075`→`$72`, 139×) — the fight logic — move each combatant's position INDEPENDENTLY
   as actions play out. The action stream is live: LCG `$59` advanced `00→88` across the window (actions
   being selected while the engine writes positions).
3. **Division of labour:** the servo cluster moves `$62`/`$72` TOGETHER (lockstep toward `$0F` = the
   baseline "hold fighting distance"); the combat engine moves them SEPARATELY (independent per-combatant
   footwork from the action tables). The servo is the distance-keeping baseline; the actions are the footwork.

### §3  Verdict
**Neither pure Hyp A nor pure Hyp B — it is TWO LAYERS (Hyp B structure), but with the ACTIONS dominant and
the servo a minority baseline — which CORRECTS the Orchestrator's "servo = fight footwork" framing.**

- The servo does run in the fight (so "walk-in-only" is wrong too) — Hyp A is refuted.
- But the **footwork is the COMBAT ENGINE's actions** (`gameplay_7000`, 71%), NOT the servo. The servo
  (`$B29D`→cluster, 29%) is a light concurrent **baseline** that pulls the pair back toward `$0F` between
  action-driven moves. So the imported "servo = footwork" assumption is wrong: the servo is the *baseline*,
  the actions are the footwork.

### §4  Position-writer map (the fight)
- **`$62` (player pos):** `check_position_a` @ `$7091` (dominant, 132×) + servo `routine_b381`/`b30f`
  cluster @ `$B3AB`/`$B359` (baseline, ~56×).
- **`$72` (guard pos):** `check_position_b` @ `$7075` (dominant, 139×) + servo cluster @ `$B357`/`$B3AD`
  (baseline, ~56×).
- The servo cluster writes `$62`+`$72` in the SAME step (lockstep); the combat engine writes them at
  separate PCs (independent).

### §5  Stage-2 architecture implication
Stage 2 is **two layers, actions-primary:**
1. **PRIMARY — the combat engine** (`gameplay_7000` model: `combat_round_manager` → `compute_action_class`
   / `update_range_flag` / `check_position_a/b`, action selection via LCG `$59` + `$33`-indexed tables).
   This carries the footwork — it writes `$62`/`$72` as the actions play. Build this first; position falls
   out of the fight logic (the Hyp-A intuition holds for the MAJORITY of movement).
2. **SECONDARY — the `$B29D` servo baseline** (route toward `$0F`, cluster-step `$62`/`$72` together). A
   light concurrent controller that keeps the fighting distance between actions. ~29% of the movement.
Do not model the servo AS the footwork; model it as the distance-keeping baseline under the action layer.

### §6  Out of scope
No build. The combat state machine itself = stage 2 (this scopes its position architecture only). Run-in
(B2', confirmed) / traverse (B3) / glide — untouched. Prod `88eba89…` byte-identical.

### §7  Uncertainty flags
- Labels provisional past scene 4, but the writer-PC attribution is execution-confirmed regardless of label:
  two distinct code regions (`$70xx` combat engine, `$B3xx` servo) both write the position ZPs, in the
  measured 71/29 split.
- Attract has run-to-run variance in action selection (LCG); the 71/29 split is one full fight window — the
  QUALITATIVE result (both layers write; engine dominant; servo baseline) is robust, the exact ratio may
  vary per fight.

### §8  Candidate captured
Candidate-worthy: *"attribute a shared variable's writes by WRITER PC, not by correlation — `$62`/`$72` are
co-moved by two routines (combat engine + servo); only the PC split (71/29) reveals that the servo runs in
the fight but is the minority baseline, correcting the 'servo = footwork' assumption imported from a
different phase."*
