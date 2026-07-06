# Project state — open items, invariants, deferred decisions (disk/boot arc)

**Purpose:** The non-methodology pile — project-specific state worth preserving so
the next session inherits ground truth rather than reconstructing it. This is
DISTINCT from the `seeds/karateka/` methodology candidates (those are reusable
nuggets; these are this-project facts). Home: `docs/project/` (a project-state /
open-items doc), NOT the seed path.

**Provenance:** extracted from the current session transcript
(`2026-07-06-02-37-36-karateka-disk-read-arc.txt`) — Orchestrator prose across the
disk-read / boot-loader arc.

---

## 1. Boot path — where it stands

The full boot path runs end to end and is CONFIRMED:
- **Build #3b-2 (71f6337): the boot loader** — framebuffer-resident loader
  ($8000-$FBFF, boot-dead) raw-reads the real game (88eba89…) from 1:1-sequential
  DMK tracks into $0100-$4823, jumps to $0200, game renders scene 1 byte-identical
  to direct placement (visible fb 45470==45470). **25.3-V CONFIRMED by Jay** ("the
  render looked good"). First full cold-load render.
- **Build #3b-3 (DISPATCHED, awaiting Clyde): DECB LOADM+EXEC front-end** — the
  last piece. VERIFY-then-BUILD: three `disk-basic-unravelled.pdf` gates first (G1
  FAT reservation, G2 LOADM transfer-address/EXEC handoff, G3 whether DECB uses
  $0100-$01FF during LOADM), THEN author the raw-underlayer DECB disk. Chain:
  CoCo→BASIC→LOADM+EXEC→bootloader→game renders.

Prior builds (all standalone, prod byte-identical): #1 HALT read primitive
(dfdee93), #2 multi-sector m=1+Seek-advance (42c7804→corrected), #3a
read-and-jump (c8f3a2c), #3b-1-redux worst-case load (bd693f1).

---

## 2. Open invariants (verified-for-scope, with re-measure triggers)

### 2.1 Split-$01xx page — VERIFIED SAFE (current scope)
The $0100-$01FF page is split: low end ($0100→) initialized data/vectors (loaded,
real — why the payload starts at $0100 not $0200); high end ($01FF↓) runtime
stack. Code proper at $0200.
- Measured (stack_margin_probe.lua, ~92k stack writes over scenes 1-4): data
  high-water **$0111**, deepest stack **$01E7**, margin **214 B**.
- Safe by structure, not luck: single-level interrupts (only VBL IRQ, no nesting);
  disk NMI lands on the bootloader's $7F00 stack, NOT $01xx (scenes 1-4 run from
  RAM, no disk NMI on this page).
- **Re-measure triggers:** (1) deeper gameplay content; (2) disk-during-play
  streaming (puts the NMI on $01xx); (3) the DECB LOADM front-end (same page,
  third angle — resolve alongside the LOADM-vs-$0100-$01FF contention).
- Committed: `split-01xx-page-collision-margin.md`.

### 2.2 Disk-access stack depth — trigger-2 PRE-CLEARED
Disk-path worst-case stack depth **D=14 B** (12 B NMI frame + 2 B sync, ADD not
max — deepest NMI HALT-pinned in the read loop; 17 NMIs fired, none stacked,
handler is INC+RTI). Base-independent.
- Prediction: game 24 B (reach $01E7) + disk 14 B = 38 B vs 238 B budget
  ($01FF-$0111) → **~200 B headroom**. Streaming-during-play pre-cleared on $01xx.
- **Re-measure only if** a future streaming design nests `disk_read_range` deeper
  in the game call tree than the 24 B game worst.
- Committed: 6c2f41e; updated the split-$01xx note's trigger-2 to "pre-cleared."

### 2.3 Track-17 invariant
The DECB directory sits on track 17 mid-disk. NO raw game-track range may span
track 17 (silent corruption if the bootloader reads the directory as game data).
Build-time-enforced with loud failure. Relevant to the 3b-3 raw-underlayer layout.

### 2.4 Save-entry-before-read
`dr_dest` advances during a read, so any jump must target a SAVED pre-read entry
address (3a's invariant; applied at the real $0200 entry in 3b-2).

---

## 3. Known issues

### KI-disk-01 — m=1 in-range short-count detection gap
An in-range blank/corrupt track can't be cleanly detected under m=1+JVC. Three
MAME-model findings established this: (1) MAME fires INTRQ→NMI per sector during
m=1 (defeats INTRQ-riding early-termination schemes); (2) status-read mid-m=1
clears INTRQ and wedges the read (landmine for any mid-transfer status inspection);
(3) no native short JVC fixture (a .dsk is always 18 sectors/track — points at the
DMK-fixture path for faithful short-track testing).
- **Bounded:** the software track bound (shipped) covers the common case (reading
  past valid data). The residual (in-range blank/corrupt) is rare.
- **Two paths, both deferred to a load-time decision:** (a) sector-by-sector m=0
  reads — clean per-sector RNF, but trades m=1's whole-track speed (~7s vs ~2min
  for 128KB); (b) DMK short-track fixture — keeps m=1 speed, faithful test,
  uncertain payoff. Decision deferred until the real load-time budget is known.
- Now moot for the boot single-call (the bound prevents running off data);
  relevant if physical-media streaming is ever added.
- Committed: `known-issue-KI-disk-01-m1-shortcount.md`.

---

## 4. Bounded-but-open questions (designed-around, not pinned)

### 4.1 Capacity
Bounded **~148-161 KB**, unmeasurable-exactly. Measured sprite expansion 1.62×
blended / 1.68× large (converges on the 7/4 px-repack ceiling). No full-screen
imagery class (Apple hires is render buffer, not stored content — corroborated by
the oracle timing showing no graphics-heavy load spike). Two-disk RULED OUT (needs
>226% graphics, impossible). Whole-game graphics fraction NOT reliably measurable
(past-scene-4 comprehension wall + mixed on-disk data). Designed-around via the
raw-underlayer, not pinned.

### 4.2 Load time — NOT a blocker
- Oracle bar (measured, soft-switch trap): boot **6.47 s** (black screen); scene
  loads **~3.78 s** (frozen prior frame, nz=128 — the oracle FREEZES the frame
  during a scene load, doesn't blank). No graphics-heavy castle spike (both scene
  loads ~3.78 s). Oracle loads UP FRONT, plays from RAM (advance-triggered, not
  per-scene streaming for the measured region).
- Our worst-case: **10.66 s** (32KB/8 tracks, optimized 1:1 DMK) / ~16.6 s
  (DECB-default fallback).
- **The gap is entirely revolutions-per-track**, not data. Ours ~6.65 rev/track
  vs Apple formats ~1 (RWTS18 read-optimized) to ~2.5 (standard RWTS). A 36 KB
  load "should" be ~2-5 s on Apple-class formats; we measure 10.66 in MAME.
- **Comparison honesty:** our 10.66 is worst-case-max; the oracle's 3.78 is a
  sample of two loads, NOT the oracle's max (boot is already 6.47, so 3.78 is not
  its ceiling). The "2.8× gap" is meaningless (max vs sample). A real comparison
  needs oracle-worst-vs-our-worst or matched per-scene — neither cheaply available
  (no cheap bytes-per-load shortcut; Karateka likely custom RWTS, geometry not
  safely assumable).
- **Jay's rulings:** load-masking is OFF the table (would part from the oracle;
  the oracle loads black at boot / frozen-frame at scene loads — we reproduce
  that, no invented loading screen). Disk access is INFREQUENT (advance-triggered,
  front-loaded, frozen-frame) → even ~2× the oracle is NOT a hard fail. Load time
  is bounded/tolerable, optimization levers in reserve, **not a blocker**.

### 4.3 The ~6-rev-per-track wd_fdc floor
Is it real silicon or a MAME artifact? This is the lever that actually moves our
load number. Answered by Jay's personal-disk hardware boot. If MAME-only, our real
load may drop toward the Apple range on hardware; if real, a read-optimized format
is the lever (see 5.1).

---

## 5. Reserved levers (held, not pursued)

### 5.1 Read-optimized sector format (RWTS18-style)
If the ~6-rev floor proves real on hardware AND load time genuinely needs cutting:
a read-optimized sector format (bigger sectors, fewer inter-sector gaps, matched
to our whole-track m=1 read) is the lever the original PoP/Karateka may have used
to get ~1 rev/track. Not chased now (speculative, bigger disk-format change);
parked as the load-time lever of last resort.

### 5.2 Interleave (realized, in hand)
imgtool `coco_dmk --interleave=0` (sequential) is optimal for whole-track m=1;
interleave spread WORSENS it (inverts RS-DOS convention). 1:1 sequential DMK is
the ship format. Residual ~1.19 s/track floor even sequential = the ~6-rev floor
(5.3 above).

---

## 6. Distribution (settled)

- **Ship the authored 1:1 DMK image** (file copy or flux-write) — the only
  clean-and-fast path (10.66 s, validated). Image-primary (SDC/DriveWire reads DMK
  natively — no SDF conversion). Physical distribution optional (collectors/self).
- **No stock-tool fast-copy path** exists — but the fallback is mild:
  - DECB-default (skip-4) BACKUP → **16.6 s, ~1.55×** — works, mildly slow. A
    perfectly serviceable copy; the "no fast-copy" finding is a minor footnote,
    not a real loss (Jay's point: 16.6 is much closer to 10 than the old 27 scare
    number).
  - DSKINI-0 (the "escape hatch") → **UNREADABLE** (Lost-Data track 0; DECB's
    sequential-format gaps too tight for our aggressive m=1 read). The one landmine
    to document around — don't do this.
- **Degradation ladder, all shippable:** 1:1 DMK (10.66) / DECB-default-compatible
  (~16.6, ~1.55×, the format most likely to read on any real drive) — both masked
  by nothing (loads are black/frozen per the oracle). No failure mode that doesn't
  ship.
- Committed: `interleave-distribution-preservation.md`; MAME-BACKUP proxy dbcb252.

---

## 7. Hardware-in-the-loop milestone (Jay's personal disk)

Jay wants one personal disk (flux-write the 1:1 DMK). It doubles as the
first real-hardware validation, clearing the 25.3-H stack in one shot:
- **The shipped-image gap margin** (25.3-H): our read is aggressive enough to
  Lost-Data on tight gaps; imgtool DMK gaps tolerate it IN MAME. Does real
  hardware's WD1773 gap tolerance match, or does the shipped disk Lost-Data on real
  silicon the way the DECB-formatted one did in MAME? **The specific acceptance
  criterion:** does the shipped 1:1 DMK read clean on an actual CoCo3.
- **The ~6-rev floor** (4.3): real silicon or MAME artifact — decides whether load
  time is already fine (~4-5 s if floor is MAME) or wants the read-optimized lever.
- HALT timing, refresh margin, DMK/SDC/flux preservation, load-time-on-silicon.

The gap-margin check is demoted from BLOCKER to format-selector: even its worst
outcome (fast format doesn't survive hardware) falls back to DECB-default-
compatible formatting (~1.55×, guaranteed-readable). No non-shipping branch.

---

## 8. Housekeeping / working-tree (Jay's to reconcile, non-blocking)

- **`seeds/karateka/` does not exist** — the root cause of the candidate-push
  failure. Every dispatch's §0.4 candidate-self-capture pointed at a non-existent
  path, so candidates only ever lived as CANDIDATE text in Form B reports (Clyde's)
  and transcript prose (Orchestrator's). FIX: create the directory + back-fill both
  piles (the Part-3 Clyde dispatch, gated on 3b-3 clean).
- **window-block-map.md stale line:** still carries "$FC00-$FFFF I/O 1KB";
  io-space-map (bb64b22) corrected it — $FE00-$FEFF is RAM vector page, only
  $FF00-$FFFF is I/O. CLOSED: window-block-map.md corrected to match (ff75e5e).
- **Working-tree churn:** tools/ dir deletions/recreations, tools/→harness/tools/
  move, ground-truth PDFs (two image-only — WD177x-00, WD179X — need OCR if ever
  cited verbatim). Jay's to reconcile.
- **Operator-gate MAME convention (corrects the stale "disk_sandbox_view.lua"
  note):** NO `disk_sandbox_view.lua` file exists or ever existed — it was a
  misremembered artifact. The disk-arc visual gate was a *windowed MAME run with
  display flags*, not a dedicated lua. Standing convention: runs meant for Jay's
  eyes (the 25.3-V visual gates) are **windowed + slowed + scaled** for easy
  viewing; headless/automated ([E]/[T]) gate runs need no display. All run scripts
  already pass `-window`; the operator-gate viewing adds a *slow* speed + a window
  scale on top. Proposed standard (values pending Jay's confirm): `-window
  -speed 0.5 -prescale 3` (`-speed 0.5` = half-speed so animation is watchable —
  NOT `-speed 8`, which is 8x FAST; `-prescale 3` enlarges the window 3x).

---

## 9. Frozen-frame design input (for the scene-transition step, later)

The oracle FREEZES the prior scene during a scene load (not black — only boot is
black). So when the port reaches scene transitions, the fidelity target is
freeze-outgoing-scene / load / resume, NOT black-screen and NOT a mask. This does
NOT apply to the current boot stage (boot loads black; the game blanks/draws
post-jump). Carry it to the scene-streaming step, and note: as long as the port
matches the oracle's load-up-front model, the disk NMI stays off the $01xx page
(keeps the 2.1/2.2 margin safe — the fidelity choice and the stack-safety choice
coincide).
