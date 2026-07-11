# MAME idioms & quirks — Apple IIe target (the Karateka oracle)

**Purpose:** a standing, self-contained reference so instrumentation quirks on the
`apple2e` target (the `karateka_dissasembly_claude` oracle) are **looked up, not
rediscovered each dispatch.** Every entry is traced to the pass that established it and,
where one exists, to the **harness tool** that exercises it and the **exact command/Lua
syntax** that works. Read this before instrumenting the oracle.

**Target:** `mame apple2e`, Karateka disk (`.dsk`/`.woz`), 6502 CPU, ~1.023 MHz.
**Run cwd:** MAME runs from the **oracle repo** (`karateka_dissasembly_claude`); `-script
tools/foo.lua` resolves **relative to that cwd**, not the tracked repo — see §11.
**Authority reminder:** the oracle is verified-authoritative **through scene 4 only**; past
that, running-game **execution** is the sole authority (labels are hypotheses). None of the
idioms below override that — they are *how* to get reliable execution evidence, which is
exactly what the past-scene-4 discipline requires.

> This file **incorporates** the earlier `mame-idioms-addendum.md` items B and C (arm-before-
> boot watchpoints; boot-time-static bytes) and D (pixel-colour provenance), plus the
> debugger/Lua discoveries from the `$6540` dispatch-closure pass (2026-07-11).

---

## 1. The load-bearing one: **6502 opcode-fetch bypasses read-taps**

**A scripted read-tap on an execution address silently never fires.** The 6502's opcode
fetches bypass the program-space read-tap that works on the 6809 side. A tap that "should"
fire on a routine's address returns **zero hits** — and zero hits reads as "the code never
ran" when it actually ran fine. **This is a hazard, not a finding. Empty ≠ absent.**

**Fixes, in order of preference:**
- **Watch the data, not the routine.** To confirm a routine ran, watch the **ZP byte it
  writes** evolve (a write-tap / watchpoint on the *result*), not a read-tap on the *code*.
  (How the LCG was confirmed: the `$A000`/`$A0A2` read-tap false-0'd; watching seed `$59`
  evolve was the reliable signal.) → corollary `watch-the-seed-not-the-rng-tap`.
- **Debugger breakpoint** at the instruction — fires on execution, reads registers/ZP at
  the break (§4). This is the reliable execution-point detector on 6502.
- **Write-tap** on a ZP location the code writes (works headless — §2).
- **Time-sweep + PC-verify** (run to a frame, check `cpu.state["CURPC"].value`).

*Established:* scene-6 full-fight (LCG `$59`/`$29` control model); reinforced in the `$6540`
attribution retrieval. **Contrast:** on coco3/6809 **read-taps DO work** — this hazard is
Apple-only (see the coco3 file §10).

---

## 2. Taps: install late, keep the return **referenced**, work **headless**

- **Read-taps work only if installed *after* boot transients settle** (not at `t=0`) — e.g.
  after the first ~2000 frames for attract instrumentation, or it silently no-ops.
- **GC GOTCHA (bit me repeatedly):** `install_read_tap`/`install_write_tap` **and**
  `emu.add_machine_frame_notifier` return an object you **must keep referenced** or it is
  garbage-collected and **silently stops firing** — you get an empty log that reads as "the
  game never writes that / the loop never runs." Keep it in a global:
  ```lua
  _G._tap = mem:install_write_tap(0x59,0x59,"seed",cb)   -- read/write tap
  _G._n   = emu.add_machine_frame_notifier(function() ... end)  -- frame notifier — SAME gotcha
  ```
  (The `$6540` pass lost several runs to an un-referenced frame notifier before this.)
- **Write-taps work HEADLESS** (no `-debug`) — they are a memory-system API, not the
  debugger. Cleanest runtime draw-program capture: tap the sprite-src ZP (`$04` hi set last
  before the blit), read the other draw args + clock + `scr:frame_number()` in the callback.
- **Draw order differs per sprite** (some set src-then-pos, some pos-then-src) — a position
  read at the src-write may be stale; cross-check by tapping the position byte too.
- **Preferred for PC/controller/position:** native interactive `wpset` (§4) — it fires where
  scripted taps false-0.

*Established:* standing MAME-instrumentation note; GC gotcha re-confirmed for frame notifiers
in the `$6540` pass. Tool: `harness/tools/scene6_full_descriptor.lua` (the `_G._tap_*` /
`_G._n` pattern).

---

## 3. The attract loop is **non-deterministic run-to-run** — but **seed-deterministic**

Two facts that sound contradictory and are both true:
- **Run-to-run the attract fight VARIES** — a single trace window is **one sample of a
  distribution, not the truth.** Do not treat one fight window as "the fight."
- **It is LCG-seed-driven, so deterministic *from a fixed seed*.** A fixed boot repeats the
  seed sequence → repeats the fight **byte-identical**. Run-to-run variance is **seed
  variance** (interactive entry advances the seed differently).

**Consequences:**
- **Identical runs prove nothing about determinism.** N identical fixed-boot runs is equally
  consistent with "PRNG replayed from a fixed seed" *and* "no RNG at all." **Prove
  stochasticity by perturbing the seed** (poke `$59`), not by counting identical runs.
  Completeness of an animation search = **union-plateau over varied seeds** (a seed-sweep to
  saturation), not repeated boots.
- **Determinism is phase-dependent.** The pre-fight intro (climb/walk/guard-approach) is
  deterministic (traced byte-identical ×2); the **fight past guard-entry is not.** Establish
  the boundary; don't assume the whole loop is one or the other.
- **A sweep axis can silently no-op.** Poking a value the game overwrites (or an ineffective
  seed poke) yields identical fights that *look* like a plateau. **Verify an axis actually
  varies the output before trusting saturation** (the first scene-6 seed-sweep was 8
  byte-identical no-op runs).

*Candidates:* `deterministic-from-fixed-seed-is-not-non-stochastic`,
`verify-a-sweep-axis-actually-varies-before-trusting-a-plateau`. *Established:* scene-6
full-fight multitrack + exhaustive animation search. Tool:
`harness/tools/scene6_full_descriptor.lua` (`FD_SEEDPOKE` at `FD_POKEF`).

---

## 4. The debugger toolkit (the big one) — headless breakpoints, forcing, and capture

This is the reliable route on 6502 (read-taps false-0, §1). Almost all of this was nailed
down in the `$6540` dispatch-closure pass; the exact working syntax is below.

### 4a. `-debug` launches **PAUSED** — and **headless it HANGS** unless you unpause from Lua
`mame apple2e -debug …` opens the debugger **halted at the first instruction**. Interactive,
you set watchpoints then `go` (§4b). **Headless (`-video none`), it just hangs → 0-byte
output.** Unpause from the autoboot script at load:
```lua
pcall(function() manager.machine.debugger.execution_state = "run" end)
```
Without this line a `-debug` headless run produces an empty file and looks like a silent
failure. *Established:* `$6540` pass (repeated 0-byte runs until the unpause was added).

### 4b. Arm `wpset` **before** releasing boot — catch boot-time writes
To catch a byte written **once during disk load** (before runtime code), arm the watchpoint
while paused, then `go`:
```
wpset bffd,1,w        # addr, length(bytes), access(w=write / r / rw)
wplist                # verify armed
go                    # release; breaks when it fires
```
`wpset`/`bpset` syntax varies slightly across MAME versions — if it errors, `help wpset`.
The `addr,length,access` form is stable across many versions but not guaranteed.
*Established:* the `$BFFD-$BFFF` sync-byte experiment (Q010).

### 4c. Breakpoint / watchpoint from **Lua** (headless), with actions
```lua
local cpu = manager.machine.devices[":maincpu"]
-- breakpoint: bpset(addr, condition|nil, action_string)
cpu.debug:bpset(0x6540, nil, 'tracelog "<<<D A=%02X 2F=%02X 20=%02X>>>",a,b@0x2f,b@0x20; go')
-- watchpoint: wpset(space, "r|w|rw", addr, len, condition|nil, action_string)
cpu.debug:wpset(cpu.spaces["program"], "w", 0x20, 1, nil,
                'tracelog "<<<W20 pc=%04X val=%02X>>>",pc,b@0x20; go')
```
**Expression syntax inside actions/conditions:** registers `a x y s pc` (and `curpc`);
byte read `b@0xADDR`; word `w@0xADDR`; **poke byte** `pb@0xADDR=val`; set a register by
assignment `a=0xD1`. Read/**write** a register from plain Lua too:
`cpu.state["A"].value = 0xD1`, `cpu.state["CURPC"].value`.

### 4d. **Force** a value the game overwrites (`FD_STATEFORCE`, generalized to registers)
A read-tap can't override (opcode-fetch bypass); a **bp at the read** can. Override the
register/ZP at the exact read, then continue:
```lua
-- force AI prob-table row $33 at the AI read $A03D (state the demo never selects):
cpu.debug:bpset(0xA03D, nil, string.format("pb@0x33=0x%X; go", ROW))
-- force the action code A (and clear a gate $2F) at a dispatcher entry, to observe a branch:
cpu.debug:bpset(0x6540, nil, 'a=0xC2; b@0x2f=0x01; tracelog "<<<F A=%02X 2F=%02X>>>",a,b@0x2f; go')
```
This is the key to **win-suppressed / unreachable content**: forcing `$33` revealed the
entire losing outcome (player-lose / guard-win cels); forcing A at `$6540` observed the
`$C2→$66FE` branch the player-always-wins demo never fires. *Candidate:*
`debugger-bp-force-to-exercise-a-value-the-game-overwrites`. Tool:
`harness/tools/scene6_dispatch_trace.lua` (`DT_FORCEA`/`DT_FORCE2F`),
`scene6_full_descriptor.lua` (`FD_STATEFORCE`).

### 4e. Capturing per-fire values — **printf is NOT captured headless; use trace + `tracelog`**
Debugger `printf` writes to the **debugger console**, which is **not** on stdout headless —
a bp-action `printf` produces nothing capturable. Instead open a **trace file** and
`tracelog` into it:
```lua
local dbg = manager.machine.debugger
dbg:command("trace C:/…/out.tr,0")            -- traces the full instruction stream of cpu 0
-- per-line register append on the trace (BRACES REQUIRED here):
dbg:command('trace C:/…/out.tr,0,,{tracelog " ;20=%02X 2F=%02X",b@0x20,b@0x2f}')
dbg:command("trace off")                       -- stop
```
**The brace gotcha (cost real time):** a **bp-action** `tracelog` must be **brace-FREE**
(`tracelog "…",a; go`); the **trace-command** action must be **BRACED** (`{tracelog "…",a}`).
Mixing them fails silently. `manager.machine.debugger:command(str)` runs **any** debugger
command from Lua — the general escape hatch. The full instruction trace shows the **branch
actually taken** at a dispatcher: after the bp mark, the executed `cmp/bne/jmp` sequence is
right there — grep the PC region. Add `,noloop` to skip repeated loops.

*Candidate:* `mame-debug-launches-paused-arm-watchpoints-before-go`. *Established:* Q010
(4a/4b) + `$6540` dispatch closure (4a/4c/4d/4e), commit `634e0c3`.

---

## 5. Boot-time-static bytes — written once from disk load, never by runtime code
Some bytes are **set once from the disk image at load time and never refreshed.** A grep of
`src/` for an instruction that writes them finds **nothing** — because no runtime instruction
does. "No instruction writes `$XXXX`" is **not** proof the value is dynamic/protected — it
can be static-from-load. **How to tell:** a write-watchpoint armed **before boot** (§4b)
fires **at boot** (during load), not in the attract/runtime loop → static-from-disk.
(The `$BFFD-$BFFF` EOR-sync bytes `$00/$3B/$49` were static-from-load, which resolved whether
they were copy-protection.) *Candidate:*
`boot-time-static-bytes-arent-written-by-runtime-code`. *Established:* Q010.

---

## 6. `-nothrottle` snapshots **lie for motion**; `-seconds_to_run` is **emulated** seconds
- `-nothrottle` is **fine for ZP-poll traces** (full trace fast). But **`-nothrottle`
  still-frame snapshots manufacture phantom motion artifacts** — a mid-frame no-throttle grab
  ≠ the live rendered frame. Colour/position from a snapshot is not authoritative regardless
  (§10, visual = Jay).
- **`-seconds_to_run N` is EMULATED seconds, not wall-clock.** Under a working `-nothrottle`,
  real time is a small fraction of it. If a `-nothrottle` run drags for minutes real-time,
  **throttle is not actually in effect** — fix the invocation, don't wait it out. Write trace
  output via `io.open` inside the Lua; **`print()` to MAME's console is NOT captured** by a
  stdout redirect.

*Established:* the nothrottle/motion caveat + `mame-trace-window-scoping`.

---

## 7. To see what a scene draws: instrument the **draw entry**, and tap **every** entry
Watch the blit/draw entry (capturing its arguments) — not the frame buffer, not source
labels. **The draw jmptable has multiple entries** (scene 6: `$1903` draw-A / `$1906`
draw-A Y-offset / `$1909` draw-B mirror / `$190C` draw-B Y-offset). **Tapping only the first
silently hides an actor** (the guard drew via `$190C`; a `$1903`-only tap nearly produced a
false "no guard"). **Tap EVERY entry**; where a dispatch fans out, capture at the fork.
Capture the **full per-draw descriptor** at the entry: source ptr, dims, X (`$05·7+$10`),
Y (`$06`), blend/flip (`$0F`), **draw-order index**, **per-frame co-occurrence** — all fall
out of the same tap. *Candidates:* `tap-every-draw-entry-not-just-the-first`,
`y-offset-entry-draws-the-second-tile`, `facing-lives-in-the-draw-entry-not-the-sprite`
(facing = which entry mirrors, not a cel attribute). Tool:
`harness/tools/scene6_full_descriptor.lua` (ENT map, per-draw CSV).

---

## 8. Trace **THROUGH** a boundary, not **TO** it; size the run correctly
"Located the transition" ≠ "captured through it." A window capped early (at f7400) hid the
**entire late fight + victory pose** — never in the window, which read as "the poses don't
exist." **Capture through the boundary** (guard-entry → loop-back f9443 → into the Broderbund
title) and **report frame-accountability**: first captured, last captured, every un-captured
stretch. A pose missing from a **covered** stretch is a finding; from an **un-covered**
stretch it's a truncated trace.
- **Sizing gotcha (measured):** the attract runs at **~56 fps** (not 60). To reach frame F,
  `-seconds_to_run ≈ F/56` **rounded up + margin**; undersizing means the run never reaches
  your arm frame → 0-byte output that looks like a script failure. (`$6540` pass: 128 s
  reached only ~7168 frames, missing the f7240 arm; 150 s reached it.)

*Candidate:* `trace-through-a-boundary-not-to-it`. *Established:* scene-6 full-span combat
search. Tool: `harness/tools/scene6_full_descriptor.lua` (`FD_FSTART`/`FD_FEND`).

---

## 9. Enumeration / filter traps (bite in MAME traces)
- **Low-draw-count ≠ absent.** A cel drawn once and persisting (Mt-Fuji peak `$A948`, 2× at
  entry; the STATIC guard; the eagle one-shot at `$3B=16`) drops off a count-sorted list.
  **Sort by position/Y as well as count; report low-count cels.** → `low-draw-count-not-absent`.
- **Wholesale bank exclusion hides actors sharing the bank.** The climb actor lives in the
  `$A400` bank alongside scroll/cliff; a `$A400-$ACFF` wholesale exclude hid it. **Exclude by
  the sub-range the trace reveals** (EXLO=`$A64A` kept the climb chain). →
  `actor-and-scenery-share-a-bank`.
- **A span on one draw stream can't see a layer in another.** ΔX on the `$1903` blit stream
  missed the fixed backdrop drawn via the `$0A00` fill. **Classify layers across all draw
  paths.** → `span-on-one-stream-cant-see-a-layer-in-another`.
- **X-scope overpaint counts, not Y-band.** A Y-band count blends regimes (Fuji peak
  overpaint 0 vs base 94). Scope to the element's actual (X,Y). →
  `overpaint-count-needs-x-scoping-not-just-y-band`.

*Established:* scene-6 climb / background re-verify / Fuji resolve. Tool:
`harness/tools/scene6_bg_layers.lua`, `scene6_full_descriptor.lua`.

---

## 10. Visual authority is **Jay's live MAME**, never a Clyde snapshot
Every colour / position / motion / on-screen claim is **Jay's** to gate off a live MAME run
(or his reference snaps). A `wpset` PC-confirm establishes *that code ran*, not *what it
looks like*. The eye is also the tie-breaker when a trace and the on-screen result seem to
conflict (the Fuji "does it scroll" question) — don't overrule the visual with a partial
trace; report the gap. 25.3 = Jay's MAME observation.

**Pixel-colour provenance (the concrete tell — addendum D).** Files labelled
"TRUE"/"reference"/"ground truth" were tool renders, not MAME captures, and were used as
ground truth for multiple iterations (tool-vs-tool, never tool-vs-MAME).
- **The tell is the pixel colour:** MAME blue ≈ **`(25,144,255)`** vs the tool constant
  **`(0,0,255)`** (confirmed present in `harness/tools/palette_derive.py`). A "ground truth"
  file containing `(0,0,255)` is a **tool render**, not a MAME capture.
- **Filename labels establish nothing** — content + creation method + timestamp do. Spot-check
  pixel colour; check the file timestamp against the claimed capture session; check whether
  `sprite_render_apple2.py` produced it.
- **Authoritative captures:** `C:\karateka-capture\snap\apple2e\` — snaps 0082-0085,
  560×192 px, **snap 0083 = record of record**. Derive rules against those.
- **Automated-check tautology:** "109/109 pixels match the rule" is tautological if the rule
  generated the predictions. Validate against **independently-grounded** raw pixel coords from
  the MAME snap. *Candidates:* `tool-render-is-not-a-mame-capture-verify-by-pixel-colour`,
  `automated-check-tautology-validate-against-ground-truth-not-rule-predictions`.

*Established:* standing; sharpened in scene-6 background/Fuji; provenance trap from Content
Wave 1 (commit `0b5825b`).

---

## 11. Quick command idioms (apple2e)
```bash
# Fast headless trace (no watching) — full trace fast; NOT for motion snapshots (§6):
mame apple2e -rompath <roms> -flop1 <disk> -nothrottle -video none -sound none \
     -seconds_to_run <N> -script tools/<lua>.lua -window -nomax
# Headless DEBUGGER run (bpset/wpset/trace from Lua) — add -debug AND unpause in Lua (§4a):
mame apple2e ... -debug -script tools/<lua>.lua        # lua sets execution_state="run"
# Operator live-watch (Jay's gate): -speed 8 -prescale 3 -resolution 1920x1152 -window -nomax
#   (viewing-only; does not touch cadence. -nothrottle for max host speed.)
```
- **Windows-path-in-Lua gotcha:** `"C:\k…"` is an **invalid Lua escape** — a bad path
  **silently fails the script**; MAME then runs the full `-seconds_to_run` with **no tap and
  no error**. Use **forward slashes** (`C:/…`) or `\\`.
- **Script must be at MAME's cwd:** `-script tools/foo.lua` resolves from the **oracle repo**
  cwd. A tool authored in the tracked repo must be **copied to the run repo's `tools/`** (a
  "file not found → fatal" if not). Keep the canonical copy in `harness/tools/`.
- **`-seconds_to_run` is emulated seconds** (§6/§8); size to `frame/56` + margin.
- **Interactive `wpset`** is preferred for PC/controller/position (fires where scripted taps
  false-0).

---

## 12. Tool index — which harness tool exercises each idiom
| Idiom | Tool | Knobs |
|---|---|---|
| draw-entry tap / full descriptor / seed-sweep | `harness/tools/scene6_full_descriptor.lua` | `FD_FSTART/FEND`, `FD_SEEDPOKE/POKEF`, `FD_EXLO/EXHI`, `FD_STATEFORCE` |
| bp at a dispatcher, register/`$2F` force, trace+tracelog capture | `harness/tools/scene6_dispatch_trace.lua` | `DT_FSTART/FEND`, `DT_FORCEA`, `DT_FORCE2F`, `DT_LINE20`, `DT_STATEFORCE` |
| background layer / fill-stream classification | `harness/tools/scene6_bg_layers.lua` | — |
| LCG seed / action-code control-model trace | `harness/tools/scene6_fight_control.lua` | seed poke |
| actor position / draw-program recon | `harness/tools/trace_actors.lua`, `trace_actors2.lua`, `akuma_drawprog.lua` | — |
| sprite convert / render / provenance colour check | `harness/tools/sprite_convert.py`, `sprite_render_apple2.py`, `sprite_visualize.py`, `palette_derive.py` | — |

---

## Appendix — candidate names (MAME-behaviour cluster, apple2e)
Sourced to specific scene-5/6 + Q010 passes; **all already pushed to
`methodology-candidate-pool/seeds/karateka/live/`** except the two marked NEW (push next):
- `mame-6502-opcode-fetch-bypasses-read-tap` · `watch-the-seed-not-the-rng-tap`
- `deterministic-from-fixed-seed-is-not-non-stochastic` (present-adjacent to
  `repeatability-gate-can-reveal-determinism`)
- `verify-a-sweep-axis-actually-varies-before-trusting-a-plateau`
- `debugger-bp-force-to-exercise-a-value-the-game-overwrites` (`FD_STATEFORCE`)
- `mame-debug-launches-paused-arm-watchpoints-before-go`
- `tap-every-draw-entry-not-just-the-first` · `y-offset-entry-draws-the-second-tile`
  · `facing-lives-in-the-draw-entry-not-the-sprite`
- `trace-through-a-boundary-not-to-it` · `low-draw-count-not-absent`
  · `actor-and-scenery-share-a-bank` · `span-on-one-stream-cant-see-a-layer-in-another`
  · `overpaint-count-needs-x-scoping-not-just-y-band`
- `boot-time-static-bytes-arent-written-by-runtime-code`
- `tool-render-is-not-a-mame-capture-verify-by-pixel-colour`
  · `automated-check-tautology-validate-against-ground-truth-not-rule-predictions`
- **NEW (not yet a candidate):** `mame-frame-notifier-return-must-be-referenced-or-gcd`
  (the `_G._n=` gotcha, §2) · `mame-debugger-printf-not-captured-headless-use-tracelog`
  (§4e) · `mame-bp-action-tracelog-is-brace-free-trace-action-is-braced` (§4e).

*Cross-target note:* the debugger/Lua mechanics in §4 (`execution_state="run"`, `bpset`/
`wpset`, `b@`/`pb@`, `debugger:command`, trace+`tracelog`) are **MAME-general** and apply to
coco3 too; only **§1 (read-tap bypass)** is 6502-specific. See `mame-idioms-coco3-port.md`.
