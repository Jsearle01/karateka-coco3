## Report — Fight Stage 2: combat engine — pipeline verified, selection-axis ambiguity → STOP+report (§7)

**Class:** build stage 2 (the biggest in the arc). `wip`. Prod `88eba89…` byte-identical. **Status:
STOPPED at §7's sanctioned breakpoint — the action-selection (seed/state axes) is genuinely ambiguous to
port by static reading; measured the target streams + resolved the correct axes; recommend measure-then-port.
No driver change (didn't push a half-verified engine into the gated scene).**

### §0  Receipt / status
t0=`2026-07-24T17:16:21-04:00` (HEAD `b003b87`, `wip`). git status clean (pre-existing untracked only).
Prod `build/karateka.bin` sha1 `88eba89b15cd…` untouched.

### §1  Pipeline verified from the code (the chain to build)
`fight_ai_a000` ($A000, win-path `LA030` at `$2F`==0): gate on `$5E`; clamp `$33`; `combat_state_a0af` +
**LCG `lcg_step_a0a2` = `$59×5+$13`** roll; compare against **four probability tiers** indexed by `X=$33`
→ emit action code in **A** (`$9B`/`$C5`/`$D7`/`$01`/`$FF`/`$00`), `jmp L6540`. → `L6540` dispatch (`$2F`-
gated) routes A → per-frame anim update (`$7081`/`$709D` + `$645B`/`$6493`) writes **`$20`** → `L6811`
draws the `$20`-indexed action cel. Position: `check_position_a/b` (`$7091`/`$7075`) + servo baseline (from
the position recon). This matches the dispatch's §1 chain.

### §2  The blocking ambiguity (§7's "seed/state-axis" case — CONFIRMED, not assumed)
Reading the selection tables to port them statically is not safe:
- **The action code is the A register at `jmp L6540`, NOT a ZP.** My first tap on `$29` caught a *flag*
  (measured 82% `$00`, 15% `$01`, 1% `$FF`) — not the action code. The real codes (`$9B`/`$C5`/`$D7`) never
  touch a tappable ZP; they live only in A across the `jmp`. So the action stream can't be write-tapped;
  it needs a breakpoint at `L6540` reading A (read-taps false-0 on 6502 opcode fetch — §apple2e idioms).
- **`$33` spans `01–0D`** (measured: 07=36%, 0B=28%, 09=21%, plus 0D/08/0A/01/0C/06/04) — **wider than the
  `{7,9,11}` the dispatch assumed.** The four tiers have only **8 entries (X=0..7)**; X=8..13 index PAST the
  table into the **overlapping-instruction bytes** (`$A087`: `$A9,$01,$85,$29,$4C…` are simultaneously code
  and tier-1 data) and padding. Reverse-engineering what X=9/11/13 actually read is exactly the guess §7
  forbids — and it drives the whole action distribution.
- So static porting of the selection would be a guess on the dominant axis. Per §7 ("if the action→cel
  mapping is ambiguous on the seed/state axes, STOP and report rather than guess"), I stopped.

### §3  The measured targets (so the build has ground truth, not a guess)
Over the fight window (f6650–8720, `oracle_fight_actions.lua`):
- **Render axis `$20`** (what `L6811` draws) = **~36 distinct anim states** (`01–28`): `$20=06` dominant
  (26% — the ready/idle stance), then a long action-anim tail (17,18,01,20,15,16,05,13,1F,14,21,…). This is
  the fight's choreography — richer than "a few actions."
- **Position** (from `verdict_recon-fight-position-driver.md`): `$62`/`$72` = 71% combat engine
  (`check_position_a/b`) + 29% servo baseline; `$62` small oscillation ~`$0F`, `$72` closes 30→0E.
- **Gates:** `$2F`==0 (win-path) 94%; `$5E`==1 (AI active) 86%.
These three streams (`$20` anim, `$62`/`$72` position, the action-code A) ARE the build's verification
target — matching them is how "the fight plays correctly" is proven, independent of the intricate tables.

### §4  Recommendation — measure-then-port (the safe build path)
1. **Capture the oracle's action-code stream at `L6540`** via a debugger breakpoint reading A (read-taps
   false-0 there) across several fight windows — get the A-code distribution keyed by (`$33`, LCG state).
   This RESOLVES the out-of-range-table ambiguity by observation instead of reverse-engineering `$A087+X`.
2. **Port the LCG (`$59×5+$13`) + `combat_state_a0af` verbatim** (unambiguous), and drive action selection
   from the **measured (`$33`,LCG)→A map** (a captured table), not the reconstructed 8-entry tiers.
3. **Port `L6540`'s `$2F`==0 routes** (the 5 reachable codes + idle tail) and the `$20` anim update, then
   `L6811` `$20`→cel. Gate against the §3 `$20`/position targets; 0-overrun + Jay 25.3 as specified.
This keeps the faithful mechanism (LCG, dispatch, anim) while sourcing the one ambiguous piece (the
selection tables under out-of-range `$33`) from the oracle's actual output — no guess on the dominant axis.

### §5  Why no build this pass
The engine is large and its selection core is the §7-flagged ambiguity. Porting it statically would bake a
guess on the dominant `$33` axis into the working, Jay-gated run-in scene; the dispatch explicitly prefers a
breakpoint report over a half-verified engine. The pipeline is now fully mapped, the correct axes identified
(action code = A@L6540, not `$29`; `$33` = 01–0D), and the render/position targets measured — so the build
(§4) is de-risked and ready to execute with the L6540 action-code capture in hand.

### §6  Out of scope
Hit-detection/health/outcome = stage 3. Choreography polish = stage 4. Losing paths (unreachable) = not the
demo. Arch-occlusion/clip-cull/budget = stage 5–6. Traverse = B3. Glide — deferred. Prod untouched.

### §7  Uncertainty flags
- The action-code A-stream is UNMEASURED (needs the L6540 breakpoint — §4.1); it is the missing target for
  the selection port. Everything else (`$20`, position, LCG, dispatch routes) is in hand.
- `$33` out-of-range table reads (X=8..13) are the specific unknown; measure, don't reconstruct.

### §8  Files
- `harness/tools/oracle_fight_actions.lua` (new — `$29`/`$33`/`$20`/`$2F`/`$59` stream).
- `reports/20260724-172000-fight-stage2-combat-engine.md` (this).

### §9  Candidate captured
Candidate-worthy: *"before porting a table-driven selector, confirm the OUTPUT axis is tappable and the
INDEX stays in range — here the action code lived only in A (untappable via ZP) and `$33` indexed 8-entry
tables at 9/11/13 (into overlapping code); both mean 'measure the selector's I/O at the boundary', not
'reconstruct the table'."*
