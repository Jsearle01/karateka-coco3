## Recon Report — the oracle fight action-code stream (selection axis, measured)

**Class:** PURE RECON (debugger trace). NO build. `wip`. Prod `88eba89…` byte-identical.

### §0  Receipt / status
t0=`2026-07-24T20:45:39-04:00` (HEAD `5fca84d`, `wip`). git status clean (pre-existing untracked only).
Prod `build/karateka.bin` sha1 `88eba89b15cd…` untouched.

### §1  Capture method
The action code lives in the **A register across `jmp L6540`** (compared, never stored — `L6540: ldx $2F;
bne …; cmp #$D1; …`), so it is untappable via a ZP write-tap, and 6502 read-taps false-0 on opcode fetch.
Used a **debugger breakpoint** at `$6540` (per apple2e idiom 4a/4e): `-debug`, `execution_state="run"` to
unpause, `cpu.debug:bpset(0x6540, nil, 'tracelog "<<<D A=%02X 33=%02X 59=%02X 2F=%02X 20=%02X 5E=%02X>>>",
a,b@0x33,…; go')` over the fight window (f6700–8600, `,noloop`). **231 action-code fires** captured. Tool:
`harness/tools/oracle_capture_6540_action.lua`; extract `build/logs/fires.txt`.

### §2  The measured selection map (the deliverable)

**(a) Reachable action codes at `$2F`==0 (win path), A distribution over 231 fires:**
| A | meaning | n | % |
|---|---|---|---|
| `$00` | idle | 117 | **50%** |
| `$C5` | (attack) | 47 | 20% |
| `$D7` | (attack) | 34 | 14% |
| `$01` | strike | 20 | 8% |
| `$D1` | | 6 | 2% |
| `$FF` | | 5 | 2% |
| `$C6` | | 1 | <1% |
| `$9B` | approach | 1 | <1% |
| **`$C2`** | | **0** | **UNREACHABLE — confirms verdict** |

Reachable win-path set = **{`$00`,`$C5`,`$D7`,`$01`,`$D1`,`$FF`,`$C6`,`$9B`}**. `$C2`→L66FE never fires at
`$2F`==0 (do not build it for the demo, per stage-2 §4). The dispatch's 5 handler codes (`$D1`/`$D7`/`$C5`/
`$C6`/`$9B`) are all present; `$01` and `$FF` (the tier-1/`$20`==6 paths) also fire.

**(b) `$33` (tier index) → action-code map — the un-reconstructable axis, now MEASURED:**
| `$33` | n | action distribution |
|---|---|---|
| **07** (in-range) | 87 | D7:32 · idle:31 · C5:14 · D1:6 · FF:2 · C6:1 · 9B:1 — the RICHEST tier (all codes) |
| 08 (out) | 7 | 01:3 · FF:2 · C5:1 · idle:1 |
| **09** (out) | 56 | C5:30 · idle:22 · D7:2 · FF:1 · 01:1 — C5-dominant |
| 0A (out) | 4 | C5:2 · idle:2 |
| **0B** (out) | 63 | idle:55 · 01:8 — mostly idle + strike |
| 0C (out) | 2 | 01:1 · idle:1 |
| 0D (out) | 12 | 01:7 · idle:5 — strike + idle |

**KEY FINDING:** the out-of-range `$33` (08–0D — the dominant states, 144 of 231 fires) produce **coherent,
stable action distributions**, NOT garbage — even though they index past the 8-entry tables into the
overlapping-instruction bytes + padding. So the selector's behavior at 08–0D is real and measurable; the
build drives selection from THIS map, not from reconstructing the tables (which is unsafe — verdict §3).

**(c) action-code → `$20` (the anim cel `L6811` draws) — feeds stage-2 draw + stage-4 choreography:**
- `$00` idle → `$20` {06 (base), 18, 17, 01, 05, 20} — idle cycles a few frames.
- `$C5` → `$20` {06, **21**, **16**, 01, 20, 1F}
- `$D7` → `$20` {06, **16**, **14**, 17, 21, 20}
- `$01` → `$20` {06, **13**, 01, 03, 21, 1F}
- `$D1` → `$20` {06}  ·  `$C6` → `$20` {1F}  ·  `$9B` → `$20` {06}
- `$FF` → `$20` {06, 0A, 09, 08, 07}
Each action plays over several `$20` frames (a sequence, not 1:1); `$20`=06 is the shared neutral/base;
the distinctive per-action frames are `$21`/`$16`/`$14`/`$13`/`$1F` etc.

### §3  Stage-2 build implication (measure-then-port)
Drive action selection from the **measured `$33`→action-code probability map (§2b)**, rolled by the ported
LCG (`$59×5+$13`) — a small per-state table (states 07–0D) of action-code weights, NOT a reverse-engineered
copy of the `$A087/$A08C/$A091/$A096` tables (whose out-of-range indexing into overlapping code makes static
reconstruction unsafe). Draw via the `A→$20` map (§2c) into `L6811`-equivalent action cels. `$C2` and the
losing paths stay unbuilt (unreachable). This is the safe, faithful selector for the demo win-path.

### §4  Out of scope / untouched
No build. Stage-2 engine consumes this map. Hit/health = stage 3; choreography polish = stage 4. Prod
`88eba89…` byte-identical.

### §5  Uncertainty flags
- **Run-to-run variance:** one fight window (231 fires); the attract LCG is seed-deterministic but the
  window sampled is one run. The map is **qualitatively robust** (the reachable set, the `$C2`-unreachable
  result, the per-`$33` action-mix shape) — exact frequencies will vary per fight; the build should treat
  the `$33`→action weights as approximate proportions, re-samplable if a specific action reads wrong at the
  gate. A multi-seed sweep can tighten the frequencies if stage-2 needs them.
- Labels provisional past scene 4; the action codes + `$20` frames are execution-observed regardless.

### §6  Candidate captured
Candidate-worthy: *"when a selector indexes a table out of range (here `$33`=8–13 past 8-entry tables into
overlapping code), don't reconstruct the table — MEASURE the selector's output distribution; the
out-of-range reads were coherent and stable in observation (144/231 fires) precisely because they're
deterministic, and the measured map is safe where the static reconstruction is not."* Ties to
[[filter-a-draw-trace-by-position-not-by-cel-id-range]].

### §7  Files
- `harness/tools/oracle_capture_6540_action.lua` (new — the `$6540` debugger-bp action capture).
- `build/logs/fires.txt` (the 231-fire extract). Raw `.tr` traces (200MB+) deleted, not committed.
- `reports/20260724-210000-recon-fight-action-stream.md` (this).
