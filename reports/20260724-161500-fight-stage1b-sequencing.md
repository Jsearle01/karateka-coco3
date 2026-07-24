## Report — Fight Stage 1.5: servo/gate resolved from code (port-correcting) + 3-phase plan

**Class:** build stage 1.5. `wip`. Prod `88eba89…` byte-identical. **Status: §1 (the dispatch's stated
crux — "resolve the `$52`-gate from code, don't assume") RESOLVED from execution, and it CORRECTS the port
design; the re-sequencing build follows from it (§4).** No driver change yet.

### §0  Receipt / status
t0=`2026-07-24T16:09:54-04:00` (HEAD `2a96f55`, `wip`). git status clean (pre-existing untracked only).
Prod `build/karateka.bin` sha1 `88eba89b15cd…` untouched.

### §1  The `$52`-gate / walk-in vs fight split — RESOLVED (not assumed)
Read the forward primitive `routine_b381` ($B381): it moves velocity `$53` toward `$04`, adds it to the
sub-byte `$50`, and **only on the mod-7 carry (`$50`≥7)** does it inc the cluster **`$62/$72/$52/$91`
together** (+ `$51` column-wrap). So the `$B29D` servo, when running, **locksteps `$52` with `$62`**.

That contradicts the observed walk-in (`$62` advances, `$52` fixed) — so I traced `$50/$51`
(`oracle_walkin_detail.lua`, f6000–6470):

| | `$50` (sub-byte) | `$51` (column) | `$52` | `$62` |
|---|---|---|---|---|
| **WALK-IN** f6000–6448 | **01 (FROZEN)** | **FE (FROZEN)** | 30 fixed | 0B→0F |
| **FIGHT** f6455+ | 01,06 (moving) | FD,FC (moving) | 30→1B | ~0F |

**Resolution: the `$B29D` servo is NOT running during the walk-in** — `$50/$51` are frozen, so the
cluster-inc never fires, so `$52` stays fixed. `$62` advances 0B→0F by a **separate walk mechanism** (a
`$62`-only advance, not the cluster). The servo **engages only at `$62`=`$0F` (f6455)**, where `$50/$51`
unfreeze and its combat corrections cluster-lockstep `$52/$62/$72/$91` — i.e. **the scroll is a side-effect
of the fight-phase servo correcting the player back to `$0F`.**

**Port-correcting consequence:** the dispatch's §1 ("port the servo" as the walk-in driver) is off — **the
servo is the FIGHT mechanism, not the walk-in.** The walk-in must be a **simple `$62`-only walk with the
servo idle** (`$52` held), and the servo (cluster lockstep, route vs `$0F`) belongs to the fight phase (and
its combat is stage 2). Porting the servo to drive the walk-in would wrongly scroll `$52` during it.

### §2  Composition (carried from stage 1, re-confirmed here)
WALK-IN (`$52`=30 fixed, `$62` 0B→0F, run) → HANDOFF at `$62`=`$0F` (`$53` flip `$FE`, guard entry armed) →
FIGHT (`$52` 30→1B via the engaged servo, `$62` held ~`$0F`, arch enters, guard `$72` 30→~0E) → TRAVERSE
(`$62` 0F→2A, B3). The player **RUNs in the walk-in**, **HOLDS `$0F` in the fight** (fights in place).

### §3  §6-caution items surfaced
- **Fight-phase pose:** NOT yet captured which cel the oracle draws at `$62`=`$0F` pre-combat — the build
  must grab it (a standing/ready pose) and NOT blindly reuse the run `st` frame (flagged, not resolved).
- **Compression:** confirmed to retire — run→walk-in, hold-`$0F`→fight; "run during scroll" must not remain.

### §4  Corrected 3-phase build plan (the execution step)
1. **WALK-IN:** a simple `$62` walk counter 0B→0F (servo IDLE), `$52` held at 30 (no scroll), run animation,
   arch off-screen, guard far. NOT the `$B29D` servo (§1).
2. **HANDOFF at `$62`=`$0F`:** flip `$53` (`$FE`); begin the fight phase; arm the guard entry (`$8ECB`).
3. **FIGHT (shell, no combat):** reuse B2''s scroll (`$52` 30→1B) + arch-enter + guard-approach, with the
   player **holding a ready pose at `$0F`** (not the run cycle). The `$B29D` servo proper (combat
   corrections) is stage 2; here the fight phase is the scroll+hold shell.
4. **TRAVERSE:** minimal/scripted `$62`→`$2A` hand-off; B3 owns it.
Gate: `SUBBYTE_ENABLE=0` unaffected; 0 overruns (servo/walk = a few compares over B2''s measured scroll);
Jay 25.3 on the SHAPE (three phases in order).

### §5  Why I stopped at the resolution
The dispatch made §1 the crux ("resolve from code, don't assume … a wrong assumption mis-sequences the
whole fight arc") and told me to port the servo as the walk-in driver. The code+trace show that would be
**wrong** — the servo is the fight mechanism; the walk-in is a separate `$62`-walk. Building the walk-in on
the servo would scroll `$52` during it (re-introducing the very compression this stage exists to retire). So
I surfaced the correction before building on it, per "don't proceed on assumption." The corrected plan (§4)
is unambiguous and ready to execute.

### §6  Out of scope / untouched
Combat AI = stage 2. Traverse to `$2A` = B3. No driver change. Prod `88eba89…` byte-identical.

### §7  Uncertainty flags
- The walk-in's exact `$62`-only advance routine (the non-servo walk) wasn't pinpointed in the disassembly —
  but the OBSERVED behavior (servo idle, `$62` 0B→0F, `$52` held) is sufficient and authoritative for the
  faithful port; the port replicates the observed walk, not a specific oracle routine.
- Fight-phase hold pose uncaptured (§3) — the build must grab it.

### §8  Candidate captured
Candidate-worthy: *"trace the sub-state (`$50/$51`) to tell whether a servo is even RUNNING before crediting
it with a movement — the cluster primitive locksteps `$52+$62`, but `$50/$51` frozen proved the servo was
idle during the walk-in, so `$62`'s walk-in advance is a DIFFERENT mechanism. The primitive's existence ≠
the primitive is what moved the byte."*

### §9  Files
- `harness/tools/oracle_walkin_detail.lua` (new — the `$50/$51` engagement trace).
- `reports/20260724-161500-fight-stage1b-sequencing.md` (this).
