# Port Post-Mortem — Collection (Clyde's half: execution / trace / disassembly vantage)

**What this is.** Raw, provenance-tagged material for a narrative-history post-mortem of the
Karateka (1984, Apple IIe) → Tandy CoCo3 6809 port, gathered from MY vantage: the commit
record, my Form B report history, the candidate pool, and the trace/disassembly findings I
recovered. It is COLLECTION, not the finished document — structure is PROVISIONAL (loose bins).
It is the counterpart to the Orchestrator's `port-history-collection.md` (the reasoning/verdict
record); the two plus Jay's ground truth become the post-mortem. Two co-equal capture goals:
**transferable port lessons** and **Karateka's inner workings `[K]`** (game archaeology — first-class).

**Provenance + confidence conventions (on every item).**
`[C]` = my execution/trace vantage · `[K]` = Karateka-internals finding · `[E]` = engineering
artifact. Confidence: **CONFIRMED** (trace/build-verified) / **HYP** (inferred) / **SUPERSEDED**
(later overturned — kept, with what replaced it) / `[thin—verify]` (reconstructed from memory).
Sources cite a commit hash, a doc, a pool slug, a trace log, or an oracle `.s` file:line.

**t0:** 2026-07-06T22:27:04 · **prod baseline:** `build/karateka.bin` SHA-1
`88eba89b15cdf17c8d25e082d2d3e1f3cce57d38` (17978 B) — unchanged by this gather (read-only).
Two repos: **coco3** (`karateka-coco3`, the port) and **oracle** (`karateka_dissasembly_claude`,
the read-only disassembly). Pool: `methodology-candidate-pool/seeds/karateka/`.

> **A note on my vantage vs. the Orchestrator's.** I was IN the diagnostic loop — I ran the
> traces, hit the walls, wrote the CANDIDATE notes. The Orchestrator has the chat/verdict record
> but not my full report history, the pool contents, the commit detail, or the Karateka internals.
> Where our accounts differ is the most valuable material; I have not smoothed mine to match a
> top-down narrative. The single loudest cross-cutting theme from my side: **almost every wrong
> turn in this port traces to one trap — trusting a static read or a frequency-ranked sample over
> an execution trace at the actual draw entry.** It recurs from scene 4 to scene 6. See Part E.

---

# PART A — The commit timeline (the spine)

Two overlapping timelines. The oracle disassembly (Apr 26 → May 11+) ran first/alongside and is
the authority the port consumes; the port (May 13 →) is built against it.

## A.1 — Oracle (disassembly) arc — `karateka_dissasembly_claude`
`[E]` CONFIRMED — SOURCE: `git -C ../karateka_dissasembly_claude log --reverse`
- **2026-04-26** `d58dba5` genesis (v0.6 bundle + v0.7 refs); capture/coverage Lua tooling.
- **2026-04-28** `2a219e5` first Karateka RAM dump (dump01_intro); `3aa4560` first disassembly
  ($B7F5 cluster) — the intro controller is the entry thread.
- **2026-04-29** `ac80216` **`routine_1900` disassembled — the video dispatch table** (first
  cross-region routine; the `$1900` jmptable that all sprite draws go through, incl. `L1903`).
- **2026-05-01/02** `24ebd0a` central per-frame dispatcher `$0200-$02FF`; `2ec79ea`/`85fa6f9`
  **`$0D00` speaker tone + PCM sound engine**; `f489746` `$0300` restart/disk-loader pipeline.
- **2026-05-02→08** differential-analysis push: multi-capture sessions, 7-dump set + extended
  trace (`d14a937`), scene-transition + attract→scene-1 loop-back mechanisms (`2b6967d`/`788e577`),
  sprite banks catalogued (`$9800-$9AFF`, `$0400` font, `$1E00` chain).
- **2026-05-09** `242c079` **`$A000-$A3FF` — fight AI, entity copiers, sprite loader**;
  `53991fa`/`8b79d40` copy-protection triangulated; `ffc8d80` **project pivots to
  reassemble-cracked + CoCo3 port**.
- **2026-05-10/11** `94e3b29` **`$A400-$AFFF` sprite bank + attract dispatch** (the scenery bank);
  `1a1288f` **`$7000-$7FFF` gameplay mechanics + display/sync** (the combat/render core).

## A.2 — Port arc — `karateka-coco3`
`[E]` CONFIRMED — SOURCE: `git log --reverse`. Load-bearing commits, dated:

**Foundations (P1) — 2026-05-13/14.** `c4b06ec` repo setup → `71c6894` MAME harness →
`88ffb27` **asset-conversion tooling (the converter)** → `b319e42` HAL contract design →
`ba88652` engine conventions → `e921889` memory map → `cc3940f` P1 closure.

**Engine subsystems (P2) — 2026-05-14/17.** `e7a1e6b` timer/frame-sync → `671b48a` kernel/dispatch
→ `9c628a7` **P2.3a/P2.4: HAL infra + sub-byte rendering + Brøderbund present scene** (first pixels).

**Real-hardware bring-up (R-vbl / R-boot) — 2026-05-19/21.** `d687e01` **real GIME VBL IRQ** →
`ee3fa08` **R-boot Brøderbund splash (the PIA-IRQ-trap fix, see D/Part E)**.

**Intro scenes (R-p24/25/26) — 2026-06-12/13.** `5c7b7b4` scene-1 controller + real input_poll →
`9884a3e`/`aa58ddc` scene-2/3 glyph+title conversion → `a37bb4b` scene-4 scroll glyphs →
`70ef771` **scene-4 128K ring-fit hard-stop** → `aca625b` **memmove-on-wrap (SUPERSEDED)** →
`659da88` **Option B: lower-bank pre-render + pure VOFFSET scroll (shipped)**.

**Sprite/animation engine + scene 5 (R-engine) — 2026-06-13 → 07-04.** `debbd3e` **R-engine core
+ sandbox + converter color-cell fix** → `b586546` **scene-5 cast located by execution (princess +
guard FOUND — corrects "skeleton reuse")** → `6b71e9d` princess composite + **new HAL opaque-blit**
→ `b7a3677` **static stage rebuilt from a captured draw-call PROGRAM (wpset trace; supersedes
static read)** → `f0b3eae`/`e4cfc19` princess walk drives the real scene clock (gate 1) →
`dffd7db`/`f2bc990` throne→cell transition + collapse (gate 2, Jay PASS) → `b6284dd` **Akuma
controller (arms-ambient + head-tracks-princess)** → `9bf7f8b` eagle controller → `07f3617`
scene-5 end-to-end → `bee90b0` boot-integrated.

**Banking recon — 2026-07-04/05.** `da56db1` ZP map → `70cc954` 64KB-window audit → `cc63f39`
video-buffer banking recon → `d72bb6c` GIME MMU re-check → `eec7c50` window block-map → `bb64b22`
$FF00 I/O-space map → `69abab8` MC3 confirm.

**Disk / boot arc — 2026-07-05/06.** `f59d944` **DECB-boot crash TRACE (M1 overlap)** →
`ab02228` FDC read-primitive recon → `011863c` **HALT read primitive design** → `dfdee93` HALT
primitive + sandbox → `42c7804` **m=1 multi-sector read** → `c8f3a2c` read-and-jump → `a4e439b`/
`bd693f1` worst-case single-call scene load → `8664de2` load-time decomposition (95.7% rotational)
→ `00d8d16` **interleave via DMK: 1:1 = 2.5× (26.65s→10.66s)** → `dbcb252` BACKUP escape REFUTED →
`71f6337` **boot loader (3b-2): raw-loads game from DMK, renders BYTE-IDENTICAL** → `3613daf`
split-$01xx margin (214B) → `6c2f41e` worst-case stack depth (14B) → `0d5a41d` **DECB LOADM+EXEC
front-end (3b-3): boots from BASIC, byte-identical**.

**Scene 6 (current) — 2026-07-06.** `832ea30` scene-6 attract-demo recon → `003cdec` **motion-layer
separation Stage 1 (correct cast found; corrects the tbl_ADF7-as-actor mislabel)**.

---

# PART B — Execution-vantage diagnostic + methodology material

My reasoning about the hard problems, distilled as candidate-pool notes (52 live + 8 incorporated
karateka seeds) plus report reasoning. Grouped by kind; SUPERSEDED wrong-turns collected in Part E.
Every item cites its pool slug (`pool/live|incorporated/<slug>`).

## B.1 — Trace / diagnostic technique (how I actually found things)
- `[C]` **The draw-entry-tap-by-bank technique** (the port's most important diagnostic result):
  to see what a scene draws, read-tap the single blit ENTRY (`L1903`=$1903) and bucket each draw's
  source by data-bank; draw-count per bank is itself a motion-layer signature (tiled high-count =
  background/scroll, few-draws = discrete actor). Ranking by per-frame pointer dwell instead makes
  the most-redrawn thing (the background) masquerade as "the hero." CONFIRMED — SOURCE:
  pool/live/draw-entry-tap-by-bank-beats-pointer-dwell; commit `003cdec`.
- `[C]` **A scene render is an ordered draw-call PROGRAM** (calls+args+order) that must be captured
  by breakpoint-trace at the draw entries (`bp 0A03/1903 trace`, extracting ZP args per draw), NOT
  reconstructed by static read or by eye — static reconstruction invented phantom sprites.
  CONFIRMED — SOURCE: scene5-draw-program.md; commit `b7a3677`.
- `[C]` **MAME 6502 opcode fetches bypass AS_PROGRAM read-taps** (they work on the 6809) — on the
  Apple side, execution detection needs a time-sweep+PC-verify, a write-tap, or a debugger bp; a
  read-tap on a render-entry address silently never fires. CONFIRMED — SOURCE:
  pool/live/mame-6502-opcode-fetch-bypasses-read-tap.
- `[C]` **A blit source pointer is WALKED** (the blit increments $03/$04 as it reads rows), so a
  per-frame ZP sample aliases mid-blit intermediate values as if they were distinct objects;
  reconcile samples against the source's declared structure (labels/part-tables) before acting.
  SUPERSEDED-as-primary-method by the draw-entry tap — SOURCE:
  pool/live/per-frame-pointer-sampling-catches-midblit-noise.
- `[C]` **After static exhaustion, switch to instruction-level tracing** — when rounds of
  hypothesis-test eliminate all statically-checkable suspects without converging, the remaining
  class is dynamic; don't extend static analysis past diminishing returns (R-boot: 9 static rounds
  failed, round-10 `-debugscript` trace found the PIA IRQ trap in one pass). CONFIRMED — SOURCE:
  pool/incorporated/instruction-level-tracing-after-static-exhaustion.
- `[C]` **A negative label-grep can't prove an asset absent** — enumerate the table/pointers by
  content, defer identity to runtime ("no princess sprite" was wrong; she was unlabeled as
  "$9A18 visual ambiguous"). CONFIRMED — SOURCE: pool/live/negative-label-grep-cannot-prove-asset-absence.
- `[C]` **A scrolling reference is a tiling set sized from the MEASURED window** — sweep the scroll
  counter to see the visible window before guessing N frames (scene-4: ~12-line window → only 2
  frames cover all 16, not the estimated 5+). CONFIRMED — SOURCE:
  pool/live/scrolling-reference-is-a-tiling-set-sized-from-measured-window.

## B.2 — Verification discipline
- `[C]` **Verify-before-fix; the trace is authority, priors are hypothesis** — and its second-order
  value is *dissolving* phantom bugs you'd otherwise build a (risk-carrying) fix around (the "$0100
  collision very likely real" was refuted by trace before any fix). CONFIRMED — SOURCE:
  pool/live/verify-before-fix-trace-is-authority, -dissolves-phantom-bugs.
- `[C]` **Green proves mechanism, not completeness** — name what a pass did/didn't cover; disk-read
  Build #1 green hid a harness carry-clobber, Build #2 green while the off-end path silently
  returned zeros. Distinguish pass-correct from pass-untested. CONFIRMED — SOURCE:
  pool/live/green-proves-mechanism-not-completeness, distinguish-pass-correct-from-pass-untested.
- `[C]` **Prove an error path by DRIVING it** — an implemented-but-undriven error check is a fail;
  drive a deliberately off-end read and observe carry-set (CC=$01 vs $00). CONFIRMED — SOURCE:
  pool/live/prove-error-path-by-driving-it.
- `[C]` **A regression that passes only on prior-test contamination is invalid** — the bad-sector
  RNF regression passed only on leftover FDC state from the preceding edge test; reorder after the
  clean read. CONFIRMED — SOURCE: pool/live/regression-depending-on-prior-contamination-is-invalid.
- `[C]` **Killing your own fix is success** — a recon that returns "the fix as conceived can't be
  validated here" and reverts a green-but-unproven fix is the discipline holding, not a failure.
  CONFIRMED — SOURCE: pool/live/establishment-step-killing-a-fix-is-success.
- `[C]` **State the alternative reading first, then rule it out** — "framebuffer-match could be a
  stale buffer" (ruled out by live-PC + visible-page isolation); "carry-set could be leftover"
  (ruled out by $00→$01 contrast). CONFIRMED — SOURCE: pool/live/state-alternative-reading-first-then-evaluate.
- `[C]` **When arithmetic and verdict disagree, name which carries** — the FDC recon marked
  DD-at-0.89MHz "FAILS" though 27<32µs says it makes the window; the FAIL was carried by
  margin-distrust + DECB's testimony, not the numbers. CONFIRMED — SOURCE:
  pool/live/arithmetic-and-verdict-can-disagree-name-which-carries.
- `[C]` **The human visual gate outranks automated checks** — Jay's repeated visual rejections were
  correct through 6+/8 passing automated iterations; automated checks can be 100%-self-consistent
  yet wrong about spec. Validate from captured ground truth, not rule-derived predictions
  (tautology risk). CONFIRMED — SOURCE: pool/incorporated/human-visual-gate-overrides-automated,
  empirical-validation-ground-truth-first.
- `[C]` **Bound the worst case; smaller is covered by construction** — one 8-track single-call read
  retired the capacity AND load-time questions together. CONFIRMED — SOURCE:
  pool/live/bound-the-worst-case-smaller-covered-by-construction.

## B.3 — Emulator / harness gotchas
- `[C]` **`-nothrottle` snapshots are unreliable for motion** — they catch mid-update frames and
  manufacture phantom smears/stuck frames; verify motion at the live human gate, reserve snapshots
  for static frames (a scene-4 "smear" drove an expensive hunt for a non-existent bug; Jay's live
  view was clean). CONFIRMED — SOURCE: pool/live/nothrottle-snapshots-unreliable-trust-live-gate.
- `[C]` **Emulator + real hardware are co-equal ship targets** — a defect on either is a shipping
  bug (MAME's pessimal 27s JVC-default load was fixed, not deferred to silicon). But an emulator
  PASS proves the *model* does something, not that silicon tolerates it — the shipped-DMK gap
  margin reads clean in MAME yet the electrical tolerance is the open gate 25.3-H. CONFIRMED —
  SOURCE: pool/live/i-both-emulator-failure-is-a-shipping-bug, emulator-models-behavior-not-hardware-tolerance.
- `[C]` **Hijack the CPU in-session when write-back is blocked** — MAME can't serialize DMK/SDF
  writes back and JVC discards physical order; to measure a guest-formatted disk, load a read+timing
  harness via `write_u8` and set PC after DSKINI to time the in-memory floppy — validated against a
  pristine il=0 control first. CONFIRMED — SOURCE: pool/live/hijack-cpu-in-session-when-writeback-blocked,
  proxy-validate-against-known-control.
- `[C]` **GIME config registers are effectively write-only in MAME** — reading `$FF90` returns
  hardware status (`$1B`), not the last write; verify writes by downstream behavior (IRQ/counter
  rates), not read-back. CONFIRMED — SOURCE: interrupt-handling.md.
- `[C]` **A repeatability gate can REVEAL determinism** — the Apple attract loop was assumed
  stochastic (≥3 runs); the 3 runs came back byte-identical, so the demo is scripted and single-run
  timing is authoritative — which simplified all of scene 5/6 downstream. CONFIRMED — SOURCE:
  pool/live/repeatability-gate-can-reveal-determinism.

## B.4 — Port-strategy / scope
- `[C]` **Port the VISUAL via the target's native idiom when it has one; port the MECHANISM when the
  oracle defines the behavior** — the paired inverse. Scene-4's 6502 software-render scroll maps to
  GIME hardware VOFFSET (2px step = exactly +20 units — granularity integer-divides, so viable); but
  inter-word text spacing must be READ from the oracle's per-glyph xstep pen (7px space), not set by
  an orchestrator proxy (16px = glyph-m width was ~2× too wide). CONFIRMED — SOURCE:
  pool/live/port-the-visual-not-the-mechanism-when-target-has-native-idiom, port-the-oracle-mechanism-not-a-proxy.
- `[C]` **A scene's true scope is gated by ASSET readiness, not code** — scenes 2/3 mirror scene 1
  in code but need ~10 unconverted glyphs + title/copyright sprites; a code-only estimate undercounts.
  And "we already do X" may mean X was baked as design-time DATA (scene-1's 8 hand-computed position
  literals), not a runtime routine. CONFIRMED — SOURCE: pool/live/asset-readiness-gates-port-scope,
  offline-formula-vs-runtime-routine, formula-present-but-per-instance-data-absent.
- `[C]` **Verify the structure map before counting the remainder** — an inherited map called scene 4
  "combat, ~one scene from close"; source showed scene 4 is a text scroll and combat is scene 6 —
  the remainder is scenes 4+5+6 (phase-sized). CONFIRMED — SOURCE: pool/live/verify-structure-map-before-counting-remainder.
- `[C]` **Crossing from the self-contained intro into the shared game engine is a SCOPE CLIFF** —
  scene 5 is the first to JMP into game-phase code ($B400), init the anim engine, need the first
  double-buffer, and fall into the infinite attract loop with no clean end marker. CONFIRMED —
  SOURCE: pool/live/scene-crossing-into-shared-game-engine-is-a-scope-cliff.
- `[C]` **Re-gate a feasibility verdict against the ACTUAL budget** — the GIME-scroll recon returned
  "viable" for a 51KB buffer computed against 512KB, but the target is stock 128KB where it doesn't
  fit (the task halted at AC-0). A "viable" scoped to the wrong budget is a latent hard-stop.
  CONFIRMED — SOURCE: pool/live/regate-feasibility-verdict-against-real-resource-budget.
- `[C]` **Separate one-time pipeline BUILD cost from per-run cost** when banding repeat conversion —
  content-wave-1 took ~8 iterations building the pipeline; wave-2 ran it over 18 assets sub-band
  ~11.5min. CONFIRMED — SOURCE: pool/live/separate-pipeline-build-from-run-cost.

## B.5 — Process / capture meta
- `[C]` **The capture target is a separate REPO, not a bare path** — an entire arc's worth of
  candidate self-captures silently no-op'd because `seeds/karateka/` didn't resolve cross-repo (the
  agent ran in coco3, the pool is separate); they existed only as report text until a back-fill.
  Fix: explicit `../methodology-candidate-pool/seeds/karateka/`. CONFIRMED — SOURCE:
  pool/live/capture-target-is-a-separate-repo-not-a-bare-path.
- `[C]` **A tool's correct invocation is often in a prior output's provenance header** — the
  converter failed on 11 scene-4 dual-labeled glyphs; a prior `converted.s` header recorded the
  address-form label (`sprite_0534`), giving the right invocation with no tool patch. CONFIRMED —
  SOURCE: pool/live/tool-failure-answer-encoded-in-prior-output-provenance.
- `[C]` **Verify forward-looking doc guidance against source** — `hal.md` said "R-p24+ should
  re-enable PIA IRQ"; source showed the opposite (poll, leave IRQ disabled) — obeying the doc would
  have reintroduced the R-boot keyboard-IRQ trap. CONFIRMED — SOURCE: pool/live/verify-forward-guidance-against-source.
- `[C]` **Re-verify HEAD before a destructive checkout** — `conventions.md` was silently overwritten
  in the working tree by another project's copy while HEAD stayed intact; a blind `git checkout HEAD
  -- file` was safe only after re-verifying HEAD's identity. CONFIRMED — SOURCE: pool/live/reverify-head-before-restore-checkout.
- `[C]` **Reports must label each claim structural (executor-verifiable) vs visual (human-only)**,
  and reviewer sign-off needs a verbatim diff, not a directional summary — the two are separate
  gates. CONFIRMED — SOURCE: pool/incorporated/structural-vs-visual-claim-labeling, gate-discipline-diffs-not-summaries.

---

# PART C — Technical-artifact reference (what we built + how it works)

Port-attempter depth. All `[C]`/`[E]`.

## C.1 — The converter (`harness/tools/sprite_convert.py`)
- **Architecture:** Apple II hi-res sprite record → CoCo3 4-color packed bytes. Input = a ca65
  `.byte` record extracted from the oracle `src/*.s` by label; output = an lwasm `.s` (`fcb`).
  Record in: byte0 height, byte1 width (bytes/row, 7px/byte, bit7 = color-set selector), bytes2+
  row-major bitmap. Record out: byte0 height, byte1 `ceil(px/4)`, bytes2+ packed 4px/byte 2bpp
  MSB-first. The 7px→4px remap is done at the PIXEL level (decode row → per-pixel index array →
  reclassify → re-pack), not byte-level; the granularity mismatch yields ≤2px right-edge padding.
  CONFIRMED — SOURCE: sprite_convert.py:1-16,163-234.
- **Color model (the heart):** Apple II hi-res has NO palette — hue is an NTSC artifact of pixel
  adjacency + screen-COLUMN parity + the byte's bit7 color-set. The converter BAKES that artifact
  into fixed CoCo3 indices (0=black,1=orange,2=blue,3=white) at conversion time. 4-category
  per-pixel rule keyed on run-adjacency + `screen_col = start_col + col`: OFF→black; isolated/
  leading-with-gap==1 → chroma by parity (even col→blue, odd→orange for pal_bit=1); leading-with-
  gap≥2 or interior/trailing → white. Chroma is painted at **col-1** (a -1 sub-pixel render offset).
  Empirically calibrated 113/113 + 110/110 against MAME apple2e snaps 0082-0085. CONFIRMED —
  SOURCE: sprite_convert.py:17-53,141-193.
- **Color-cell fill pass:** an Apple solid-color region is a 1010… alternating-dot pattern NTSC
  merges to a solid bar; the raw dot map leaves interior OFF dots black → vertical striping. The
  pass fills any black dot flanked by non-zero neighbours both sides with the neighbour's chroma,
  INTERIOR-ONLY (preserves exterior transparency). This fixed the scene-3 Karateka-logo striping.
  CONFIRMED — SOURCE: sprite_convert.py:37-43,196-227; known-issues.md.
- **Trim / visible-extent:** final pass strips leading+trailing all-zero byte-columns
  (`lead_stripped`/`trail_stripped`), shrinking width. **This is the root of the multi-frame
  registration bug** (see C.2). CONFIRMED — SOURCE: sprite_convert.py:300-319.
- **C#-oracle lineage:** the palette/index scheme descends from a C# reference converter
  (`MainForm.cs coco3Palette4`); the visualize + palette_derive tools cite it as authority.
  CONFIRMED — SOURCE: sprite_visualize.py:11-16, palette_derive.py:6-11.
- **Companion tools:** `sprite_visualize.py` (independent CoCo3-side `.s`/`.bin`→PNG decoder for
  visual verification; red output flags an encoding error); `flip_parity_inplace.py` (swaps 2-bit
  fields 01↔10 on already-converted `.s`, for cast with no clean source); `sound_convert.py`
  (PCM $0E00 Apple-8-bit→CoCo-6-bit by >>2; tone $0F00 pass-through); `palette_derive.py`.

## C.2 — Converter KNOWN BUGS (+ fixes) — the teaching cases
- **Blue/orange column-parity reversal** (RESOLVED): because hue derives from `start_col+col`
  parity, any cast sprite converted at a column origin whose parity differs from its true on-screen
  column gets every blue/orange swapped — and because CoCo3 is palette-INDEXED (not parity-derived
  like Apple), the reversal is baked PERMANENTLY into the data, not a runtime artifact. FIX:
  `--flip-parity` XORs the parity test (color-only, no shape change); `flip_parity_inplace.py` for
  cast lacking a clean source `.s`. CONFIRMED — SOURCE: known-issues.md:7-33; commit `b80b6ed`.
- **Independent-blank-trim / multi-frame registration** (mechanism, live): the trim pass strips
  blank byte-columns PER SPRITE independently, so each frame of a multi-frame actor can strip a
  different number of leading columns → the frames no longer share a common origin → cross-frame
  horizontal mis-registration unless per-sprite position compensation (+7px per stripped leading
  column) is applied. The scene-4 glyphs happened to have `lead_stripped=0` (no comp needed); the
  title case did NOT (uniform +20 skewed "karateka"). CONFIRMED — SOURCE: sprite_convert.py:300-319;
  pool/live/converter-trim-needs-position-compensation.
- **Label-stacking silent truncation** (workaround): `extract_sprite_bytes` treats a stacked
  co-located label as the next-block boundary → extracts only the 2-byte header. Workaround: use
  the address-form label. CONFIRMED — SOURCE: tooling-notes.md:9-51.

## C.3 — The HAL (`src/hal/coco3-dsk/`)
- **Why + strategy:** the boundary between platform-neutral engine and platform-specific code (one
  engine, `coco3-dsk` target for v1.0); shape inherited from pop-coco3-design v0.7 §6.11. **Stub-
  first:** 4 subsystems detailed at contract time (Graphics/Time/Sound/Debug), 4 skeletoned
  (Memory/Input/File/System), each fleshed out only when its consuming engine subsystem is ported.
  8 subsystems / ~21 functions; uniform convention (args A/B/D/X/Y; CC.C=error, A=code); init order
  mem→time→gfx→input→sound→file. CONFIRMED — SOURCE: hal.md.
- **`HAL_sys_init`:** the bare-metal transition — masks IRQ/FIRQ (`orcc #$50`), `$FF90=$4C`
  (COCO=0,MMUEN=1,MC3=1,MC2=1), maps MMU task0 `$FFA0-A7=$38-$3F`, and **RMW-disables PIA0/PIA1
  CA/CB IRQ** (`$FF01/03/21/23` mask $FC). That PIA disable is load-bearing (see Part E, R-boot).
- **`HAL_gfx_init`:** GIME 320×192×4 double-buffered, EMPIRICALLY-ordered (from Jay's MAME-verified
  GFXMODE3.ASM): `$FF90=$6C` FIRST (buffers at $8000-$FBFF are in ROM territory — must switch to
  all-RAM first; also IEN=1) → clear buffers → mode `$FF98=$80/$FF99=$15` → VOFFSET → SAM →
  **palette `$FFB0-$FFB3` LAST** (doesn't latch until the mode is final 4-color, else indices 1-2
  render black). CONFIRMED — SOURCE: gfx.s:100-236.
- **`HAL_gfx_present`:** page flip = a VOFFSET write (`$FF9D/$9E` = physical/8); Frame A phys
  $78000→$F000, Frame B $7C000→$F800. No memory copy — the flip IS the banking primitive. (No VBL
  gating in the P2.3a impl.) CONFIRMED — SOURCE: gfx.s:280-353.
- **`HAL_gfx_blit_sprite` + the opacity family** (GIME has NO hardware sprites — all software blit,
  80-byte stride, runtime 2-bit sub-byte shift ported from Apple's `L1A84`):
  - *transparent* (default): key-color, most-recent-wins via a 256-byte mask LUT — `result=(dest &
    ~mask)|source`; chosen over STA (black source erases) and OR (2bpp orange|blue=white).
  - *opaque* (`HAL_gfx_blit_sprite_opaque`, flag ZP $13): all-$FF mask — stores every pixel incl.
    index-0 black. Added for the princess composite (`6b71e9d`).
  - *mixed* (per-REGION rectangle descriptor), *masked* (per-COLUMN mask, sub-pixel edge trim),
    *stencil_punch* (per-PIXEL 2D silhouette occlusion — occlude a moving actor behind Akuma's exact
    figure incl. armpit gaps), *scroll* (16-bit physical row 0-391 across both buffers as one ~392-
    row ring, for the scene-4 VOFFSET scroll). CONFIRMED — SOURCE: gfx.s:360-957.
  - **PLANNED refactor (HYP, not done):** replace the whole opacity family with ONE blit reading a
    per-pixel sentinel `f`=opaque-black (0=always-transparent, f=always-opaque-black, 1/2/3=colors).
    Requires widening SPRITE storage to **4bpp** (nibble/pixel) because all four 2bpp codes are
    already used (index3=white, so `f` can't reuse it); framebuffer stays 2bpp, blit maps nibble→
    2bpp. Deletes the opaque variant + $13 flag. SOURCE: opaque-black-f-refactor-plan.md.
- **`HAL_time_*`:** VBL-synced; installs the real IRQ handler at the `$010C` dispatch slot, `$FF90=
  $6C`/`$FF92=$08` (VBORD on IRQ), 16-bit frame counter DP $10/$11; replaces Apple `vbl_sync`
  (@$779A, the hottest routine, 327k fires). **`HAL_input_poll`:** POLLED (PIA0 matrix $FF00/$FF02
  + joy fire); must NOT re-enable PIA IRQ. Memory/Sound/File are still STUBS (mem returns 128K
  assumed). Debug-trace is always-on (ring buffer $7800) so the MAME harness can verify behavior.
  CONFIRMED — SOURCE: time.s, input.s, mem.s, sound.s, file.s, hal.md.
- **Shipped palette (composite, MAME-verified):** $00 black / $26 orange / $1B blue-cyan / $3F
  white → `$FFB0-$FFB3`. NOTE MAME emulates CoCo3 in COMPOSITE monitor mode (bits5:4 intensity,
  3:0 hue), not RGB; `palette_derive.py`'s RGB-style codes ($2C/$03/$3F) are SUPERSEDED by these
  composite values. Display fidelity: +5 byte-column (40px) border centers Apple 280px in CoCo3
  320px; `coco3_px = apple_px*8/7 + 20`, vertical 1:1. CONFIRMED — SOURCE: gfx.s:201-228,
  conventions.md:777-895.

## C.4 — Display / memory / banking architecture
- **GIME MMU model:** 64KB window = eight 8KB blocks; `$FFA0-A7`=Task-0 bank regs, `$FFA8-AF`=
  Task-1, `$FF91` bit0 selects the active set (two tasks = two VIEWS of the same RAM, not extra
  reach); default map `$38..$3F` = physical `$70000-$7FFFF`. CONFIRMED — SOURCE: memory-map.md,
  reports/2026-07-05-gime-mmu-recheck.md.
- **128K is enough — no 512K forcing:** physical 128K = pages `$30-$3F`; the lower bank `$30-$37`
  IS CPU-mappable on stock 128K, so banking is a stock feature. (The memory-map "56-63 on 128K"
  line is an internal typo — 8 pages = 64KB.) CONFIRMED — SOURCE: reports/2026-07-05-video-banking-recon.md.
- **Double-buffer → banking via GIME VOFFSET:** the video scanner fetches from a PHYSICAL address
  independent of the CPU MMU, so a buffer can be DISPLAYED without being CPU-mapped (spike: byte
  persists in phys $78000 after CPU unmap). Evolution: the framebuffers ($8000-$FBFF, ~30KB) are
  CPU-mapped ONLY so the blit can reach them; banking displays them via VOFFSET from their physical
  pages, unmaps them from the window, and maps a content page in only during a blit → ~30KB window
  reclaim. **The 64KB WINDOW (not the 128KB store) is the real ceiling** (~62.3KB used, ~454B
  margin) — banking is imminent (the next ~10KB scene forces it). CONFIRMED — SOURCE:
  memory-window-audit.md, window-block-map.md.
- **Framebuffer geometry:** each fb = `$3C00` = 15,360 B (NOT 16KB): fb A `$8000-$BBFF` (1KB pad
  from 8KB MMU granularity), fb B `$C000-$FBFF`. Window blocks 0-7: block 0 PINNED (ZP/stack/code),
  block 7 PARTIAL — only `$FF00-$FFFF` (256B) is pinned I/O, `$E000-$FDFF` RAM coexists below it.
  CLEAN_BUF = 13440B `$4A00-$7E80` (read only during the dirty-rect restore, fully repositionable).
  CONFIRMED — SOURCE: window-block-map.md.
- **The I/O ceiling is `$FF00`, NOT `$FC00`:** the hardware-decoded I/O page is the top 256 bytes
  `$FF00-$FFFF` (PIA0 $FF00, PIA1 $FF20, disk/SCS $FF40, GIME $FF90, SAM $FFC0, vectors $FFF2); RAM
  extends to `$FEFF`. The memory-map's "$FC00-$FEFF Hardware I/O" invents a phantom 768B — that
  range is RAM (incl. the vector page). This 512B correction (`$FC00-$FDFF` usable) matters for
  banking headroom. CONFIRMED (Lomont p.48) — SOURCE: io-space-map.md.
- **MC3 (INIT0 bit3) = the constant vector page:** makes `$FE00-$FEFF` a CONSTANT page (physical
  `$7FE00-$7FEFF` secondary vectors) regardless of the MMU. It's a load-bearing NO-OP for banking:
  prod already sets it, its only cost is committing 256B, and it's REQUIRED for interrupt-safe MMU
  swaps (the secondary-vector chain survives a block-7 remap). Keep MC3=1, keep the draw slot ≤
  `$FBFF`. CONFIRMED (3 sources) — SOURCE: mc3-function-confirm.md.
- **Interrupts:** three-level dispatch `$FFxx`(ROM)→`$FExx`(secondary, MC3-locked)→`$01xx`(writable
  stubs): NMI $FFFC→$FEFD→$0109, IRQ $FFF8→$FEF7→$010C, FIRQ →$010F; `$0100-$0111` = six 3-byte RTI
  stubs (Sockmaster-confirmed order — do NOT infer from sequential assignment). GIME VBL IRQ: IEN=1
  + `$FF92=$08` + `andcc #$EF`; ACK = READ `$FF92` (returns source AND clears all GIME IRQ flags —
  skipping it → infinite re-entry). CONFIRMED — SOURCE: interrupt-handling.md.

## C.5 — The disk subsystem
- **The DECB-boot crash (M1, TRACE-confirmed):** a naive `LOADM"KARATEKA"` HANGS — LOADM loads
  segment 1 (`$0100-$0111`) FIRST, overwriting DECB's IRQ vector at `$010C`; DECB's interrupt-driven
  reader's next IRQ (`$FFF8→$FEF7→$010C`) lands on the RTI stub → the read never completes → PC
  spins `$C60F↔$FEF7`; `$0200`/`$4000` never populate. Root cause: the load footprint `$0100-$4823`
  subsumes DECB's live low-RAM (vectors $0100, disk working set $0600-$0Exx). This is WHY CoCo
  software boots via a raw-sector loader, not LOADM into low RAM. CONFIRMED — SOURCE:
  disk-boot-decb-overlap.md; commit `f59d944`.
- **WD1773 FDC:** memory-mapped `$FF40` DSKREG (b3 motor, b5 density, b7 HALT-enable) + `$FF48-4B`
  Status/Track/Sector/Data. NO Motor-On pin (motor is only the DSKREG b3 latch). Commands: Read=$80
  (m=0)/$90 (m=1), Restore=$00, Seek=$10, Force-Interrupt=$D0. DRQ window MFM = 32µs/byte = 28.6
  cyc at 0.89MHz; a minimal polled loop = 24-26 cyc → paper-PASS but thin (+9-16%). CONFIRMED —
  SOURCE: fdc-read-primitive.md.
- **The HALT read primitive (the key mechanism):** DSKREG b7=1 wires the WD1773 DRQ to the 6809
  HALT line — the CPU is HARDWARE-STALLED between bytes and released when DRQ asserts, so it
  physically cannot outrun the disk → Lost-Data from CPU-slowness is impossible BY CONSTRUCTION
  (this is why the thin polled margin didn't matter — HALT was chosen over the polled branch).
  Command-complete: INTRQ→6809 NMI, which auto-clears HALT b7. **Own-vector trick:** install
  `JMP $FE20` at `$FEFD` + a 4-byte `INC/RTI` handler at `$FE20`, both in the MC3-constant vector
  page (pinned physical `$7FE00`), ABOVE the game load ($4823) and the framebuffer loader — so no
  load can overwrite it (the M1 lesson: own your vector, not DECB's `$0109`). Refinement: HALT b7
  armed only for the Type-II Read transfer, not Type-I Restore/Seek (which generate no DRQ).
  CONFIRMED — SOURCE: disk-read-primitive-design.md, disk_read.s; commits `011863c`,`dfdee93`.
- **Single-density ruled out:** SD ~87.5KB < ~128KB content AND stock DECB reads DD-only (an SD boot
  disk is unbootstrappable). DD = ~157.5KB raw. CONFIRMED — SOURCE: fdc-read-primitive.md.
- **m=1 whole-track read:** `dr_read_track_m1` reads 18 sectors (4608B) under ONE Read-Multiple
  `$90`, HALT-paced, terminated by Force-Interrupt `$D0` to avoid a 5-rev RNF search stall; error
  mask `$0C` (CRC/Lost-Data only; trailing RNF is the benign end-of-track terminator). Shared source
  (no PIC), included by sandbox/bootloader/game each at its own load address, 7 param bytes at
  `DR_VARBASE`. CONFIRMED — SOURCE: disk_read.s; commit `42c7804`.
- **Boot chain (3b-2/3b-3):** the loader runs from framebuffer $8000 (boot-dead space), masks IRQ/
  FIRQ, own stack $7F00, replicates the game's MMU map, raw m=1-reads 4 whole tracks (72 sectors)
  into `$0100-$48FF`, `jmp $0200` (never returns to BASIC; the game self-inits). DECB LOADM+EXEC
  front-end: three gates PASS — G1 FAT reservation (mark granules $C9 with NO dir entry; the
  allocator honors the table, the lister ignores unowned regions), G2 handoff (`LOADM"BOOT":EXEC` —
  LOADM stores the transfer addr in EXECJP $009D, bare EXEC jumps through it), G3 the $01xx page is
  Class-B safe (LOADM reads into an FCB buffer ≥$0940, the clobbered $01xx vectors are inert once
  the loader masks IRQ + never returns). Split-$01xx margin = 214B (measured); worst-case disk
  stack depth = 14B. CONFIRMED — SOURCE: decb-loadm-boot-gates.md, split-01xx-page-collision-margin.md.
- **Load-time / interleave:** worst-case ~3.33s/track is 95.7% ROTATIONAL. **1:1 SEQUENTIAL is
  OPTIMAL for the HALT-paced whole-track read — the INVERSE of the RS-DOS interleave convention**
  (which spreads sectors for per-sector CPU access). MAME's JVC container imposes a pessimal default
  spread (26.65s); an imgtool DMK authored `--interleave=0` preserves order → 10.66s for 8 tracks =
  **2.5× speedup**, byte-identical. The 1:1 layout survives IMAGE distribution only (copy the DMK,
  or flux-write) — DECB BACKUP (a logical-ID copy) reverts it to the destination's format (skip-4 →
  16.59s). The DSKINI-0 "escape hatch" was REFUTED (produces an UNREADABLE disk: DECB's tight gaps
  Lost-Data the aggressive m=1 read; validated via the CPU-hijack proxy against a pristine control).
  Oracle fidelity bar: Apple boot ≈6.5s black-screen, scene loads ≈3.8s masked; CoCo worst-case
  10.66s ≈ 2.8× → load-masking still needed for perceived time. CONFIRMED — SOURCE:
  load-time-decomposition-interleave-probe.md, interleave-realization-mame.md, raw-underlayer-disk-spec.md,
  mame-backup-escape-measured.md; commit `00d8d16`.
- **Open hardware gate (25.3-H, HYP):** the 1:1 gap margin reads clean in MAME but a real WD1773 may
  tolerate different gaps — needs a flux-write + self-reporting test on a real CoCo3. SOURCE:
  hardware-gap-margin-check.md.

## C.6 — The sprite/animation engine (R-engine)
- The engine drives scenes as ordered draw programs through the Apple video dispatch (`$1900`
  jmptable); the CoCo3 R-engine (`debbd3e`) replicates that with the HAL blit family. **Body-part
  composition lives in the ENGINE** (`src/engine/sprite.s`), which emits `(sprite_ptr, col, row)`
  tuples; the HAL only renders each tuple — keeping hardware detail out of animation logic and
  making composition testable without a display. A 16-frame run = 8 leg + 8 torso sprites composited
  per frame. CONFIRMED — SOURCE: conventions.md:525-539; commit `debbd3e`. (Draw-entry + render-path
  internals in Part D.)

---

# PART D — Karateka internals `[K]` (game archaeology)

What my traces + the oracle disassembly recovered about how the 1984 game actually works. First-
class findings. All `[K]`; sources are oracle `src/*.s` and the scene recon docs.

## D.1 — Rendering / draw engine
- `[K]` **The video subsystem is a 5-entry JMP trampoline `jmptable_1900` at `$1900-$190E`** (5×
  3-byte JMPs). Slots: `$1900`→hires page-fill, **`$1903`→draw-A no-offset (THE canonical sprite
  draw)**, `$1906`→draw-A Y-offset, `$1909`→draw-B no-offset, `$190C`→draw-B Y-offset. The blit
  reads its source pointer from ZP `$03/$04` at draw time — which is exactly why bank-classifying at
  `L1903` (not per-frame ZP polling) separates real cast from scroll/noise. CONFIRMED — SOURCE:
  video.s:44-71, scene6-recon.md.
- `[K]` **Blend mode is SELF-MODIFYING CODE keyed on ZP `$0F`** (flip/direction): `$0F==0`→
  `sta ($00),y` normal; `$0F<0`→reversed draw; `$0F>0`→NOP-store (transparent skip). The blend
  opcode+operand bytes are overwritten per call. `routine_1927` also unconditionally ORs `#$80`
  (bit7) onto every output byte (forces the high-bit Apple palette). Draw-B ($1909/$190C) differs by
  using a screen-address LUT at `$0900` for vertical scaling/clipping. CONFIRMED — SOURCE:
  video.s:19-24,106-177.
- `[K]` **Sprite record format:** byte0 height (→ZP $0D), byte1 width bytes/row 7px/byte (→$0E),
  bytes2+ row-major bitmap; size = 2+H×W. Screen rows come from Karateka-INSTALLED hires-row LUTs
  (`hires_row_lo/hi` at raw ZP $0800/$08C0, not ROM). CONFIRMED — SOURCE: sprite_data.s:72-79,
  video.s:118-124.
- `[K]` **A separate rectangle-FILL family lives at `$0A00`** and coexists with the sprite blitter:
  `render_pass_a`/`L0A00` = single-color rect (odd rows←$11, even←$02), `render_pass_b`/`L0A03` =
  dual-color 2×2 pattern (floor texture), `render_clear`/`L0A06` = AND-mask clear. Scenery is a MIX
  — floor/walls via `$0A00` fills, set-dressing + characters via `$1900` blits (the earlier
  "scenery = sprites only" model was incomplete). The floor pattern is `$02=$D5 $11=$AA $12/$13=$80`
  via the dual fill. CONFIRMED — SOURCE: 2026-06-14-scene5-recon.md, scene5-static-stage-spec.md.

## D.2 — Scene orchestration
- `[K]` **The attract cycle is one deterministic engine loop**, not separate programs — the "intro"
  IS the game engine running scripted. Scene transitions are driven by state, and the whole cycle
  loops back to scene 1 via the attract-end gate. CONFIRMED — SOURCE: scene dispatch commits
  (`2c55cde`,`788e577`), scene6-recon.md.
- `[K]` **Scene 5 (imprisonment) is a two-phase `$3B` scene clock.** Gated `$3D=$01`, init `$3B:=$15`.
  PHASE 1 (throne walk-in) holds `$15→$22`, sets midpoint flag `$56:=$10` at `$3B=$16`; at `$22`
  RESETS to `$04` = the throne→cell backdrop CHANGE. PHASE 2 (cell) counts `$04→$0D`; at `$3B≥$0D
  AND $39==$01` (walk-complete) triggers the FALL (`dec $3B`, `$39:=$13`). The clock is advanced by
  the PRINCESS walk cadence (one step per 4-frame leg cycle via `advance_princess_anim`). CONFIRMED
  — SOURCE: 2026-06-14-scene5-recon.md, scene5-1b-gate2-recon.md.
- `[K]` **The throne→cell transition trigger is `$3B=$04`, NOT the door.** The cell door `$9980` is
  a TIMED ANIMATION (`$84` flips 00→05 at frame 5235, AFTER the cell walk-in exits, BEFORE the
  pose), drawn mirrored. The princess turn (`$39:=8`) and the door (`$84:=5`) are CO-TRIGGERS in the
  same atomic block, not causal — visually "door appears, she turns to it," mechanically
  simultaneous. CONFIRMED — SOURCE: scene5-cell-draw-program.md, scene5-1b-gate2-recon.md.
- `[K]` **Scene 5 has NO clean terminal** — `fight_round_main` returns after the fall, but the outer
  `scene5_main_loop` ($B4DB) holds the collapsed tableau indefinitely and exits only via the
  attract-end gate (`LB260` arms PRGEND → `jmp $B766`), restarting the whole cycle. (This is the
  "scope cliff" of B.4 made concrete.) CONFIRMED — SOURCE: 2026-06-14-scene5-recon.md.
- `[K]` **Scene 6 = the attract "one fight" demo** (intro-cycle scene 8: hero vs one guard,
  scripted, hero wins), reached ~108s into the deterministic cycle; the climb begins at frame 6019
  ($A3E9 climb chain). THREE motion layers (separated by bank at L1903): (1) a locked/dead-band
  scrolling background (`$A400-$ACFF` tiles, drawn hundreds-thousands×/window), (2) independent
  character combatants ($8xxx/$9xxx, a handful of draws each), (3) a static Mt-Fuji/sky backdrop
  (drawn once/rarely, not a per-frame blit). CONFIRMED (layers)/HYP (identity) — SOURCE: scene6-recon.md.

## D.3 — Sprite / animation engine (actors are multi-part composites)
- `[K]` **Actors are assembled per frame from separate cels.** The player run cycle = 8 leg frames
  (`$9B00-$9D1E`) composited with 8 torso frames (`$9D68-$9EB7`) drawn as separate cels. CONFIRMED —
  SOURCE: sprite_data_9b00.s.
- `[K]` **The guard is a static 3-part composite:** head `$8F2B` (oracle-mislabeled "feet_shadow") +
  torso `$899C` + below-torso `$8ACB`, left side; the `{899C,8F2B}`/`{8ACB,8F2B}` alternation is
  DOUBLE-BUFFERING, not animation. CONFIRMED — SOURCE: scene5-cast-map.md; commit `b586546`.
- `[K]` **Akuma is a STANDING multi-part composite with TWO independent behaviors:** ARMS = a free
  AMBIENT gesture loop with NO clock coupling (poses cycle even while `$3B` is frozen — proven by a
  frozen-clock test), and HEAD = princess-position-coupled, tracking her DISCRETELY across 5 `$3B`
  zones (`$15-17`→`988B` … `$1E-22`→`9A62`, monotonic left→right follow, throne-phase only). A
  `$974B` "outline" sprite is actually a render MASK/stencil for his silhouette, not a visible
  sprite. ("Throne room" is only a scene name — he stands.) CONFIRMED — SOURCE:
  scene5-akuma-head-coupling.md; commit `b6284dd`.
- `[K]` **The eagle is minimal:** body `$9FC4` STATIC (perched on Akuma's left shoulder), head = a
  single one-shot swap `$9FD8`→`$985C` when the walk begins (`$3B≥$16`) and HOLDS. NO wing-flap, NO
  fly. CONFIRMED — SOURCE: scene5-akuma-eagle-recon.md; commit `9bf7f8b`.
- `[K]` **The princess is a 14-frame multi-part figure** across banks `$11e8`/`$1c7a`: standing
  `$1530`, bowed `$1867`, turn `$1611/$1588`, 4-frame walking-legs `$1D36/$1D5A/$1D7E/$1DA2`,
  falling `$175E/$16CC/$17D3`, collapsed `$1829`. Pose DWELL times are the load-bearing timing
  (oracle collapse: turn-hold 173 VBL, facing-left 173 VBL, bow ~9 VBL; throne walk 13 VBL/leg).
  CONFIRMED (Jay-IDed) — SOURCE: scene5-cast-map.md, scene5-1b-gate2-recon.md.

## D.4 — Sprite-bank + memory organization
- `[K]` Six fixed sprite banks (differential analysis). **`$0400-$0673`** = the mixed-case Karateka
  font (26 letters + 4 punctuation). **`$9800-$9AFF`** = scene-5 content in self-validating CHAINS
  (`$9879→…→$9956` ends exactly at `$9980`; `$9A18→$9A2A→$9A62` ends at `$9A74`=the "the end"
  banner) + eagle head `$985C` + cell door `$9980`. **`$9B00-$9FFF`** = player legs+torso, Akuma
  throne pose `$9EB8`/feet `$9F8C`, eagle body `$9FC4`. **`$8300`** = player animation set.
  **`$95xx-$97xx`** = floor/ground patterns (NOT characters). **`$A400-$ACFF`** = the SCROLLING
  scenery/floor group (scene 6). **`$BBEC-$BFE7`** = the large KARATEKA title logo. `$9B00+` sprites
  have no explicit callers — they're indexed from the `gameplay_6000.s` animation tables `$6000-
  $63FF` (HI bytes $90-$9F). CONFIRMED — SOURCE: sprite_data.s, sprite_data_9b00.s, scene5-cast-map.md.
- `[K]` **The mirror mechanism is a simple `$26−x` byte reflection** + `$10=6` + h-flip (NOT a
  width-aware reflection — a superseded reconstruction). Set-dressing table `tbl_sprite_*_a` has 11
  entries; normal col = x, mirror col = 38−x. CONFIRMED — SOURCE: scene5-draw-program.md.

## D.5 — ZP usage (Apple side)
- `[K]` **`$3B` = the scene clock** (imprisonment progression). Blit-param cluster: `$03/$04`
  sprite-source pointer (set last before each blit; the blit WALKS it → mid-blit ZP taps unreliable
  vs the L1903 entry trace), `$05` X, `$06` X-base, `$07` Y-page, `$0D` height, `$0E` width, `$0F`
  flip/blend, `$10` shift/sub-byte. Anim/pose counters: `$39` princess pose state, `$26` mirror
  base, `$56` midpoint flag, `$84` door trigger. Fill-family: `$05/$09` col start/end (clamp $28),
  `$06/$08` row start/end, `$02/$11/$12/$13` pattern bytes, `$0F` blend. CONFIRMED — SOURCE:
  video.s:120-128, scene5 recons.
- `[K]` **The gameplay-state ZP cluster (`gameplay_state_0b00.s`):** `$B6` enemy sprite count/index
  (handler_0b35 draws right→left advancing `$10` +3 mod 7), `$B7` player count/index (handler_0b7c
  left→right). IMPORTANT: these `$0B1x` handlers fired **0×** in the scene-6 attract window — the
  "$B6 enemy/$B7 player" comments describe the GAMEPLAY engine, NOT the attract cast (see Part E, the
  $0B1x wrong turn). CONFIRMED — SOURCE: gameplay_state_0b00.s.
- `[K]` (Port-side re-mapping, reference) the CoCo3 scene-clock analog is `scene_clk` at `$42` (NOT
  `$3B`, which in the port is `eng_fillval`); princess controller $43-$4F, `page_register` $50, VBL
  counter $10/$11. Princess WRITES scene_clk, Akuma READS it (single source of truth). CONFIRMED —
  SOURCE: zp-map.md.

## D.6 — Sound
- `[K]` **The sound engine is at `$0D00`** — speaker square-wave tones via `$C030` toggles; a
  sound-record pointer is loaded into `$F7/$F8` before jumping in. PCM data $0E00 (256B), tone data
  $0F00. Triggered via the `$1000` jmptable: each entry loads the record ptr and JMPs `$0D00` ONLY
  IF `($4F AND $86)!=0` — so trigger call sites are always present but CONDITIONALLY voiced (scene 5
  has 9 trigger sites: setup/walk-begin/fall-start/fall/land). CONFIRMED — SOURCE:
  2026-06-14-scene5-recon.md, oracle `$0D00` disasm (commit `2ec79ea`).

## D.7 — Determinism
- `[K]` **The attract cycle is fully deterministic (no RNG)** — 3 boot runs land byte-identical at
  the scene-6 fight onset (f≈6480, ~108s). One run's timing IS the timing; the reach is repeatable
  by `apple2e -flop1 dumps/karateka.dsk` + wait. Scene-5 reach is likewise deterministic (`$3D 60→
  01` at frame 3902); boot transients (garbage `$3B`/`$99` before frame ~2000) must be gated out.
  CONFIRMED — SOURCE: scene6-recon.md, 2026-06-14-scene5-recon.md.

---

# PART E — Superseded wrong-turns (the teaching material)

Kept deliberately — the corrected mistakes are the best resource for a port-attempter. Each is
tagged SUPERSEDED with what replaced it.

1. **`tbl_ADF7`/`$A684` mislabeled as "the hero"** (scene 6). Ranking sprite sources by per-frame
   `$03/$04` dwell made the most-redrawn thing — the scrolling BACKGROUND — look like the dominant
   actor; the recon "found the actor" and never found the characters. REPLACED BY the draw-entry-
   tap-by-bank method (commit `003cdec`): tap L1903, bucket by data-bank, and read draw-count as a
   layer signature. Lesson: "busiest/most-moving == the actor" is a trap; it's usually the
   background. SOURCE: scene6-recon.md, pool/draw-entry-tap-by-bank-beats-pointer-dwell.
2. **The `$0B1x`-second-combatant** (scene 6). Per-frame ZP sampling reported a `$0B1x` cluster as
   "the second combatant"; it was mid-blit pointer NOISE + gameplay-state RAM. The `handler_0b35/
   0b7c` that touch `$0B12` fired 0× in the attract window. REPLACED BY reconciling samples against
   structure/labels. SOURCE: scene6-recon.md, pool/per-frame-pointer-sampling-catches-midblit-noise.
3. **The scene-4 scroll `memmove-on-wrap`** (`aca625b`). A copy-down approach to the ring wrap — and
   the copy loop used `ldb #40` as its `decb` counter while `ldd ,y++` CLOBBERED B every iteration →
   an unbounded data-dependent loop that marched Y into GIME I/O near `$FFFF` (garbage band). Fixed
   the counter (count in a DP byte `ldd` can't touch), but the whole approach LOST to **Option B**
   (`659da88`): faithful scroll via lower-bank pre-render + pure GIME VOFFSET — port the visual via
   the native idiom. SOURCE: pool/ldd-clobbers-loop-counter-runaway-pointer, port-the-visual-....
4. **The "skeleton reuse" scene-5 cast theory.** The princess/guard were reasoned to be reused
   skeleton sprites; execution trace FOUND them as real distinct cast (`b586546`) — the princess was
   unlabeled ("$9A18 visual ambiguous"), which a negative label-grep had wrongly called "absent."
   REPLACED BY enumerate-by-content + defer identity to runtime. SOURCE: pool/negative-label-grep-....
5. **The Akuma "fully ambient" over-generalization.** A frozen-clock test proved the ARMS are
   ambient — and I generalized that to the whole actor; the HEAD actually tracks the princess across
   5 `$3B` zones (`scene5-akuma-head-coupling.md`, HS-0 decisive). Lesson: a coupling test on ONE
   part of a multi-part actor doesn't prove the whole. SOURCE: pool/actor-recon-test-scope (report),
   scene5-akuma-head-coupling.md.
6. **The eagle "wing-flap/fly" hypothesis** — refuted; it's a single one-shot head-swap, static body
   (`9bf7f8b`). SOURCE: scene5-akuma-eagle-recon.md.
7. **Static-read scene reconstruction** invented phantom sprites (`$9980`/`$9A74`/`$12C8` mis-
   attributions). REPLACED BY capturing the ordered draw-call PROGRAM via wpset/bp trace at the draw
   entries (`b7a3677`). SOURCE: scene5-draw-program.md.
8. **Disk-read Build #2 RNF-masking** was mechanism-correct (trailing RNF is the m=1 terminator) but
   silently REGRESSED off-end detection — a read past data returned zeros-as-success. Caught by
   DRIVING the error path (CC=$01 vs $00). A later verify-based short-count fix was green + logically
   sound but REVERTED because its core never fired on the proxy. SOURCE: pool/local-fix-can-regress-
   a-higher-capability, prove-error-path-by-driving-it, establishment-step-killing-a-fix-is-success.
9. **The DSKINI-0 BACKUP "escape hatch"** for fast-copy — REFUTED: it produces an UNREADABLE disk
   (DECB's tight gaps Lost-Data the aggressive m=1 read). And "no tool produces interleaved DMK" was
   a MIS-INVOCATION (`imgtool coco_dmk --interleave` exists; the prior check used a non-existent
   subcommand + tested only JVC). REPLACED BY the imgtool DMK path + a CPU-hijack proxy validated
   against a pristine control. SOURCE: pool/recheck-invocation-before-believing-no-capability,
   copy-by-logical-id-preserves-content-not-layout, mame-backup-escape-measured.md.
10. **content-wave-1 chroma "109/109 auto-pass"** was TAUTOLOGICAL — it validated positions derived
    from the same chroma rule, against tool renders mislabeled "diagnostic TRUE" (pixel (0,0,255) vs
    MAME's (25,144,255)). Jay's visual gate overrode it; re-done MAME-pixel-first vs snap 0083.
    SOURCE: pool/empirical-validation-ground-truth-first, reference-provenance-explicit-paths.
11. **The GIME hardware-scroll RING** — after option-1 (51KB pre-render) was rejected on the 128K
    re-gate, option-2 (seamless duplicate-zone ring) was proven GEOMETRICALLY IMPOSSIBLE (2L≤405
    below `$FF00` AND L≥206 → 412>405 contradiction). Survivor: memmove-on-wrap (→ see #3) or Option
    B pre-render. SOURCE: pool/hardware-scroll-ring-needs-2x-window-plus-line-footprint.
12. **Process wrong-turn: the bare capture path.** An entire arc's candidate self-captures silently
    no-op'd (`seeds/karateka/` didn't resolve cross-repo) — the pool is a SEPARATE repo. The lessons
    existed only as report prose until a back-fill. SOURCE: pool/capture-target-is-a-separate-repo-not-a-bare-path.

---

# PART F — Handoff / where this wants more room / cross-check with the Orchestrator

- **[thin—verify] items** (reconstructed, flag for Jay): none of the above is memory-only — every
  item cites a commit/doc/pool/trace. Where an oracle label is the source, it is `[K]…HYP` because
  labels past scene 4 are hypothesis (HS-5). The scene-6 CAST IDENTITY is HYP pending Jay's live gate.
- **Wants more room in the final doc:** (a) the draw-entry-tap technique deserves a standalone
  "method" chapter — it's the port's central diagnostic result and recurs; (b) the HAL opacity
  family → planned 4bpp `f`-model refactor is mid-flight and should be told as an arc, not a
  snapshot; (c) the disk arc (HALT primitive + interleave inversion) is self-contained and
  publishable almost as-is.
- **Where my account may DIFFER from the Orchestrator's** (per the dispatch — surface, don't smooth):
  (a) I attribute several "corrections" to the SAME root trap (static/frequency over trace); the
  chat record may log them as independent bugs — my commit+pool evidence says they're one lesson
  recurring. (b) The Orchestrator assumed the early record was unreachable; it is fully reachable
  (both repos' `git log --reverse`, Part A) — the genesis is Apr 26, not the port's May 13 start.
  (c) Some dispatch HYPs I later REFUTED by execution (eagle fly, Akuma fully-ambient, $0B1x
  combatant, DSKINI-0 escape) — the verdict record may still carry the original hypothesis; the
  execution vantage is the correction.
- **Open gates carried forward:** 25.3-H (real-hardware disk gap margin, HYP); scene-6 cast identity
  (Jay live-MAME); the 4bpp `f`-refactor (planned, not done); banking (imminent — next ~10KB scene
  forces the window reclaim).
- **AC-7 / next step:** Jay reviews this collection; it merges with the Orchestrator's
  `port-history-collection.md` + Jay's ground truth into the post-mortem.
