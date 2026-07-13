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

### 4f. Isolate the DECISIVE write with `wpdata`; read the caller via `sp` — but beware JMP-stale returns
Two idioms from the scene-6 walk-window (guard-entry trigger) investigation:

- **`wpdata` conditions a watchpoint on the value being written**, so you can catch only
  the *one* write that matters instead of every write to a hot ZP byte. To find the write
  that first drives guard-pos `$72` below its parked `$30`:
  ```lua
  cpu.debug:wpset(cpu.spaces["program"],"w",0x72,1,"wpdata<0x30",
    'tracelog "ENTRY pc=%04X data=%02X\\n",pc,wpdata; go')
  ```
  The first `ENTRY` line's `pc` is the decisive routine. (A plain `wpset` on a byte touched
  by a block-copy + a scroll-dec + a wrap-inc gives 3+ PCs of noise; `wpdata<K` cuts to the one.)

- **Read the caller's return address off the 6502 stack** in a bp-action tracelog with the
  register token **`sp`** (lowercase; the state key is `SP` but expressions want `sp`).
  After JSR, the pushed return addr is at `$0101+sp` (lo) / `$0102+sp` (hi):
  ```lua
  cpu.debug:bpset(0xB30F,nil,'tracelog "ret lo=%02X hi=%02X\\n",b@(0x101+sp),b@(0x102+sp); go')
  ```
  **GOTCHA (cost a run):** this only works if the routine was entered by **JSR**. If it was
  reached by **JMP** (or fall-through), the top-of-stack is a *stale* return from some earlier
  JSR and points somewhere unrelated (here it pointed at a `jmp`-table vector `$1903`). **Verify
  the entry kind first:** grep the full trace for the instruction line immediately *before* the
  routine's first line (`grep -B1 "^B30F:"`) — if it's `jmp $b30f`, the stack read is bogus;
  the real caller is the branch just above that `jmp`, which you then `dasm` to read the compare.

*Established:* scene-6 walk-window investigation 2026-07-12 (guard entry = player `$62 > $0F`
at `$B29D cmp #$0f` → `jmp $b30f` scroll; decisive write `$B357 dec $72`).

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

**7b. Static-vs-dynamic facing = the per-cel `entry=[…]` map — but read it via the UNSHARED cel.**
To answer "does an actor flip facing across the scene," the descriptor tool's per-cel
`entry=[A:n By:m …]` aggregate is the direct readout — a single-entry cel never flips; a both-entries
cel *might*. **The trap:** two fixed-facing actors that **share** a cel bank make that cel show BOTH
entries (player draws it draw-A on the left, guard draw-B on the right) — which looks like flipping
but isn't. **Discriminate with each actor's UNSHARED identity cel (the head):** one head per fighter,
never shared, so its `entry` map IS that fighter's facing with no ambiguity. (Scene-6 guard: head
`$8ECB` = `By` only across f6487–8382; player head `$8E9B` = `A` only — neither flips → STATIC;
shared combat bodies show both entries only because the two fixed-facing fighters reuse them mirrored.)
Confirm the shared-cel reading by X: the draw-A instances cluster LEFT, the draw-B RIGHT. **The
trampoline read-taps at `$1903/$1906/$1909/$190C` DO fire** (1507× over a fight window) — this is a
JMP-trampoline entry, not a §1 routine-body false-0. *Candidate:*
`mirror-head-norm-half-is-the-actor-discriminator` (extended: read any per-actor property — facing,
flip, state — off the UNSHARED cel; a shared cel aggregates it across every reuser). *Established:*
scene-6 guard-facing sizing (`docs/project/scene6-guard-facing-sizing.md`).

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

### 8a. Timing: **MAME frame == one VBL**; the game's vbl-sync count is the (compute-bound) loop rate
For animation/timing traces, the **display VBL timebase is the MAME frame** — one vblank per
emulated NTSC frame, so `frame_number` (or the frame-notifier count) IS the VBL count. **Do NOT
use the game's own vbl-sync routine as the VBL count** — the Karateka fight calls `vbl_sync`
($779A: `lda $C019`/`bmi` on RDVBL bit7) only ~230× over a 960-VBL fight, because the main loop
is **compute-bound at ~14 Hz** (heavy 6502 work per frame) and double-buffers (~2 vbl-syncs per
figure redraw). So: **display-VBL dwell** (frame_number gaps) = the transferable, on-screen
timing; **vbl-sync count** = the game's internal loop tick. Measure pose dwell as VBL gaps
between figure redraws (per combatant, keyed on the head cel), `$20` read at the draw as data.
*Candidate:* `measure-dwell-against-display-vbl-not-compute-bound-loop`. *Established:* scene-6
fight-timing pass. Tool: `harness/tools/scene6_pose_timing.lua`. (Cross-cutting — the display-VBL
= emulator-frame identity holds on coco3 too.)

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

## 10a. Reference-frame capture — frame-anchored `screen:snapshot()`, seed/ptr self-verified
Building a **visual reference set** from the running oracle (to gate the port's later stages, the
role snap 0083 played for the logo):
- **Apple II AUTO-BOOTS the disk** — unlike coco3 (which needs `natkeyboard:post` LOADM/EXEC, coco3
  file §1/§2), `mame apple2e -flop1 karateka.dsk` boots straight in and plays the ATTRACT.
  No input driving needed; just run and capture at frames.
- **⚠ ZERO KEYBOARD INPUT — a focused `-window` run LEAKS host keys into the emulation (2026-07-13).**
  `apple2e.cfg` has the natural keyboard enabled; ANY keystroke after intro-start makes Karateka
  **disk-load into the ACTUAL GAME** (not the attract). A windowed snapshot run therefore silently
  jumps to real gameplay while a **headless (`-video none`) run stays in the attract** — same frames,
  different scene (verified: f5670–5990 = fight windowed / climb headless). **Capture snapshots
  headless** (`-video none` + `screen:snapshot()`, which reads the screen-device bitmap without a
  window) or disable the natural keyboard. This bug mislabeled the entire scene-6 "climb" set below.
- **Capture mechanism:** a frame-notifier + `manager.machine.screens:at(1):snapshot()` fired at the
  target frames. Snapshots write to **`<-snapshot_directory>/<system-shortname>/NNNN.png`** (MAME
  appends the system dir, e.g. `_raw/apple2e/0000.png`, auto-incrementing in capture order) — so set
  `-snapshot_directory` to a staging dir and **rename/move afterward** to the final tree/convention.
- **Frame-BOUNDARY snapshot avoids the `-nothrottle` mid-frame caveat (§6):** the notifier callback
  fires between frames, so `screen:snapshot()` grabs the last *complete* frame even under
  `-nothrottle` — the motion-artifact caveat is about mid-frame grabs, not this. (~1200% speed for a
  ~140-emulated-second arc.)
- **Anchor to SEED-DETERMINISTIC frames from the recon timeline, not wall-clock** (attract is
  seed-non-deterministic run-to-run, §3; the pre-fight intro is deterministic so its frame markers
  are stable). **Log the frame + `$59` (LCG seed) + the `$03/$04` draw-ptr at each shot** → the set
  is reproducible AND **self-verifying without reading the PNGs**: the ptr confirms the beat. PNG
  *fidelity* stays Jay's visual gate (§10); the log establishes *which beat* each frame is.
  **⚠ CORRECTION (2026-07-13):** the earlier claim that `$A3E9`/`$A4F2`/`$A3C5–$A649` are "climb"
  cels was WRONG — those (and `$838C`, `$59` ACTIVE) are the **actual-game FIGHT**, reached only
  because the windowed capture leaked a key (see the ZERO-KEYBOARD note above). The real attract
  **climb** = player-crawl poses in the **`$12`–`$18` banks** over the **`$96`–`$9A` cliff**, drawn
  right after the princess falls (scene-5 `$1CC4` shadow ends), captured HEADLESS.
- **NB `.dsk` vs `.woz`:** the repo oracle disk is `dumps/karateka.dsk` (what all traces use); if a
  dispatch names `Karateka.woz`, use the repo disk and flag it.

*Candidate:* `anchor-oracle-reference-captures-to-seed-deterministic-frames-and-self-verify-with-the-draw-ptr`.
*Established:* scene-6 oracle reference capture (20 frames → `C:\karateka-capture\snap\coco3\scene6\`,
climb/summit/after, `capture.log` manifest). Tool: `tools/scene6_oracle_capture.lua` (transient in
the oracle repo; canonical pattern here).

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
# Reference-frame capture (§10a): auto-boots; snapshot at frame-boundary target frames.
#   ⚠ HEADLESS ONLY — `-video none`, NO `-window`. A focused window leaks host keys → the disk
#   loads the ACTUAL GAME and the "attract" capture is silently wrong (§10a ZERO-KEYBOARD note).
#   screen:snapshot() reads the screen-device bitmap without a window, so it still writes PNGs.
mame apple2e -rompath <roms> -flop1 dumps/karateka.dsk -snapshot_directory <stage>/_raw \
     -nothrottle -video none -sound none -seconds_to_run <N> -script tools/scene6_oracle_capture.lua
#   -> writes <stage>/_raw/apple2e/NNNN.png (rename after); log frame+$59+ptr per shot.
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

## 10b. Enumerate a draw program by watching the cel-pointer write — read draws in FILE order
To recover *what cels a scene draws + where* when you don't know the blit entry, watch the
**cel-pointer write** rather than a specific dispatch address. On this engine the blit source
pointer is ZP **`$03/$04`** (`$1A61` copies it to `$1B/$1C`, then `lda ($03),y` reads the
cel width/height header); position is **`$05`=col, `$06`=row**. A `wpset` on `$04` (hi byte)
with a `tracelog` of `wpdata`,`$03`,`$05`,`$06`,`pc` dumps the whole draw program:
```lua
cpu.debug:wpset(cpu.spaces["program"],"w",0x04,1,nil,
  'tracelog "cel=%02X%02X col=%02X row=%02X pc=%04X\\n",wpdata,b@0x03,b@0x05,b@0x06,pc; go')
```
Three gotchas that each cost a run in the climb-window investigation:
- **The climb blits through `$1AF1`/`$1A17`/`$B1B6`, NOT the `$1903`–`$190C` fight dispatch.**
  Tapping only the known fight entry returned ~0 draws (cf. `tap-every-draw-entry-not-just-the-first`).
  Watching the *pointer* is entry-agnostic — it catches every path.
- **Watching only the HIGH byte `$04` misses same-page cels** (a `$A3C5→$A3E9` step writes only
  `$03`). It still enumerates the page structure, but to pin the *first/start* cel, **read the
  draws in FILE (execution) order** over a window that starts *before* the phase — the first
  player-bank line is the start pose. (Frame-tagging by poking the frame# into text page `$0400`
  FAILED here — 0 draws — either perturbing state or all sampled frames were static holds; the
  reliable move was the wide continuous window + file-order, not per-frame tagging.)
- **Sparse-redraw scenes trap even sampling.** The climb redraws the whole tableau only at its
  ~5–6 step transitions and holds statically between; evenly-spaced frame samples (every 9f)
  land on static holds and capture *nothing*. A single continuous window spanning a transition
  captures the program; each cel's repeat-count then reads as static-vs-scroll (identical
  col/row across redraws = static; drifting row = scroll).

*Established:* climb-window investigation 2026-07-12 (climb tableau = `$AB` cliff bank +
`$AA`/`$A9`, static; start pose `$A3C5` Y158; HUD `$0B12` present player-side).

---

## 10c. Identify a scene by draw-program CONTENT, never by frame number (frame #s are boot-relative)
Frame numbers are **not comparable across runs** — the attract phase that lands at frame N
shifts run-to-run (disk/boot timing offsets the whole timeline). A prior capture set named
`scene6_climb_00_f6019` turned out to be **scene-5 (princess in cell)**: in that boot f6019
fell inside scene-5; in a fresh boot f6019 is the climb bottom-start. **Anchor every capture
to what the draw program draws, not to a frame label.** Mechanism:
- **Per-scene bank signatures.** Sweep a wide window with a **frame-tagged write-tap** on `$04`
  (idiom §10b + the tap-GC rule) whose Lua callback reads `scr:frame_number()` and buckets the
  first/last frame each cel *bank* appears. Distinct scenes = distinct banks:
  scene-5 princess = `$1CC4` shadow + `$1Dxx` figure; scene-6 climb = `$A3–$A6` pose + `$AB`
  cliff + `$AA` scenery. The boundary is where one bank set stops and the next starts (here:
  princess ends ~f5653, climb pose `$A3C5` starts f6018, with a `$96/$99` transition between).
- **Content-verify each snapshot, not its frame #.** A frame is the climb bottom-start iff its
  window draws `$A3C5`+`$AB` with the player low (`$06`=Y158) and **no** `$1Cxx` princess cel.
  `grep -c 'cel=1C'` over the capture window = 0 is the scene-5-excluded proof.
- **Find a phase's start/hold via a per-frame ZP read in the notifier.** The player climb-Y is
  ZP `$06`; reading it each frame shows it settle+hold at 158 (bottom-start held f6019–6058)
  then decrement as the crawl ascends — pins the "lowest/first" frame without pixel reads.
- **Name captures by content, keep the frame only as provenance.** `scene6_climbstart_00_bottom_Y158_f6030`
  — the tag is the verified content; `f6030` is a boot-local provenance stamp, not an anchor.
  Never reuse a sibling boot's frame label to name a new boot's capture.

*Established:* scene-6 climb re-capture 2026-07-13. Content-anchoring alone was necessary but
NOT sufficient — the deeper defect was a key-leak that put the emulator in a different SCENE
(see §10a ZERO-KEYBOARD): the `$A3C5`/`$AB` "climb" was the actual-game fight. Real attract
climb = `$12`–`$18` crawl poses over the `$96`–`$9A` cliff, right after the princess falls;
capture HEADLESS. Anchor to bank signatures + a headless/zero-input run, never a frame label
carried from a windowed (possibly game-not-attract) boot.

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
- `anchor-oracle-reference-captures-to-seed-deterministic-frames-and-self-verify-with-the-draw-ptr`
  (§10a — frame-anchored `screen:snapshot()`, seed/ptr self-verified reference set)
- **NEW (not yet a candidate):** `identify-a-scene-by-draw-program-content-not-frame-number`
  (§10c — frame #s are boot-relative; anchor captures to bank signatures + `$06` climb-Y +
  `cel=1C`-absent proof, never to a frame label reused from a sibling boot).
- **NEW (not yet a candidate):** `mame-frame-notifier-return-must-be-referenced-or-gcd`
  (the `_G._n=` gotcha, §2) · `mame-debugger-printf-not-captured-headless-use-tracelog`
  (§4e) · `mame-bp-action-tracelog-is-brace-free-trace-action-is-braced` (§4e).

*Cross-target note:* the debugger/Lua mechanics in §4 (`execution_state="run"`, `bpset`/
`wpset`, `b@`/`pb@`, `debugger:command`, trace+`tracelog`) are **MAME-general** and apply to
coco3 too; only **§1 (read-tap bypass)** is 6502-specific. See `mame-idioms-coco3-port.md`.
