# Oracle Disk-Access Timing — the fidelity bar

**Investigation** (cross-repo: measures the ORACLE — Apple II Karateka under MAME apple2e —
not karateka-coco3). **t0 (C-35):** 2026-07-06T02:18:51. karateka-coco3 prod `88eba89…`
untouched; nothing in either repo's shipped artifacts changed.
**Tool:** `../karateka_dissasembly_claude/tools/disk_access_timing.lua` — a read/write tap on
the Disk II slot-6 soft switches (`$C0E0-$C0EF`), aggregating per-frame stepper/data activity
(comprehension-independent hardware signal). **Disk:** `dumps/karateka.dsk` (the project's
input-of-record). **HS status:** HS-1 oracle+CoCo artifacts unchanged · HS-2 soft-switch trap
(slot 6 CONFIRMED — trap fired) · HS-3 activity-span measure (motor-window note below) ·
HS-4 three accesses captured; access-3 nuance reported honestly · HS-5 screen state per access ·
HS-6 deterministic ≥2 runs · HS-7 NO CoCo comparison computed (flagged as follow-up).

---

## Method note (HS-3) — why activity-burst, not motor-window

Karateka **toggles the drive motor continuously** during a load (160+ on/off touches inside a
single load — protection/RWTS timing), so the clean "motor-on → motor-off window" model
fragments into meaningless slivers. The robust measure is **data-read activity**: bin `$C0EC`
nibble reads per frame; a burst = contiguous frames reading >200 nibbles/frame, merging gaps
<0.25 s. **The burst duration IS the tight activity span** (first-to-last dense read). The
~1 s motor spin-down tail does not apply as a separate load component — after each burst the
disk goes fully idle (the game runs from RAM), so there is no post-load activity to strip.

---

## The fidelity bar (AC-5) — deterministic across runs

| Access | Activity burst (= load time) | Screen at load | Seeks | Nibbles |
|--------|---:|---|---:|---:|
| **1. Boot → game start** | **6.467 s** (f101-488, 92% duty) | **BLACK** (hires1 nz=0/512) | 50 | 361,063 |
| **2. Post-SPACE scene load** | **3.767 s** (f808-1033) | content shown (nz=128/512, **NOT black**) | 66 | 215,080 |
| **3. Next scene load** | **3.783 s** (f1354-1580) | content shown (nz=128/512, **NOT black**) | 78 | 210,210 |

- **Boot** identical across 3 runs (30 s / 60 s / 120 s / 180 s). **Scene loads** identical
  across 2 runs (120 s / 180 s). All deterministic.
- **Access 3 (the "castle"):** Karateka's story sequence loads scenes B2, B3, … as the game
  advances; **one of these ~3.78 s loads is the castle scene**. The exact identity needs visual
  confirmation (Jay's gate — CLAUDE.md §3; not interpreted here). Notably **both scene loads are
  ~3.77-3.78 s** — the graphics-heavy scene does NOT load dramatically longer (consistent with
  Karateka having no full-screen bitmap imagery — see `content-expansion-capacity-projection.md`).

---

## Two refinements to the premise (important)

1. **The oracle loads everything UP FRONT, then plays from RAM — it does NOT stream per scene.**
   After the 6.467 s boot load the disk is **fully idle** (a passive 60 s no-SPACE run showed
   ONLY the boot burst — zero further access). Scene loads (B2/B3) appear **only after SPACE
   starts the game** (they are absent in the passive intro). So disk accesses are discrete
   events at game-start / scene-advance, not continuous streaming.

2. **Only the BOOT is on a black screen. Scene loads are NOT black — the prior scene stays on
   screen during the load** (nz=128 vs boot's nz=0). This partly contradicts the dispatch's
   "loads on a black screen / no masking" framing: the oracle effectively **freezes the prior
   frame** during a scene load (a form of masking). The CoCo fidelity target therefore differs
   by access type — see below. (Exact on-screen content during a scene load — frozen prior
   scene vs a transition graphic — is Jay's visual gate; the DATA only says non-black.)

---

## Decision input (§6, foreground for Jay) — the bar, NOT the CoCo comparison (HS-7)

**Oracle fidelity bar:** boot ≈ **6.5 s (black)**; scene load ≈ **3.8 s (prior scene shown,
not black)**.

CoCo-side comparison is the **follow-up** (HS-7 — not computed here), but the bar is now
concrete for it:
- The CoCo boot-equivalent is judged against **~6.5 s black**.
- The CoCo scene-transition load is judged against **~3.8 s with the prior scene frozen** — and
  the CoCo's measured worst-case scene load (10.66 s, `interleave-realization-mame.md`) is
  **~2.8× the oracle's ~3.8 s**. That gap — and whether the CoCo should freeze the prior frame
  (as the oracle does) rather than black-screen scene loads — is the fidelity question the
  follow-up resolves. (Flagged, not concluded — HS-7.)
- The uniform ~3.8 s oracle scene load (no graphics-heavy outlier) means the CoCo's ~1.62×
  graphics expansion headwind is spread evenly, not concentrated on one "castle" load.

---

## Gaps / follow-ups

1. **CoCo-side comparison** (HS-7) — compute the CoCo per-access expected times against this
   bar (boot vs 6.5 s; scene vs 3.8 s); resolve the ~2.8× scene-load gap. The next step.
2. **Screen content during scene loads** — the DATA says non-black (nz=128); WHAT is shown
   (frozen prior scene?) is Jay's visual gate. This decides whether the CoCo black-screens or
   freezes-prior-frame on scene loads.
3. **Deeper gameplay loads** — only boot + 2 story-scene loads captured (the game runs from RAM
   after); deeper level loads would need gameplay input to reach (not automated here).

---

## Candidates / deviations

- **CANDIDATE (the bar):** oracle boot = **6.467 s (black)**; scene loads = **3.767 / 3.783 s
  (prior scene shown, not black)** — deterministic. [disk_access_timing.lua]
- **CANDIDATE (premise refinement):** the oracle loads UP FRONT then plays from RAM (no
  streaming); scene loads are SPACE/advance-triggered discrete events.
- **CANDIDATE (premise refinement):** only boot is black; scene loads keep the prior scene on
  screen (the oracle freezes-the-frame — a form of masking the dispatch's "black screen"
  premise didn't anticipate).
- **CANDIDATE (uniformity):** both scene loads ~3.78 s — no graphics-heavy castle outlier
  (matches "no full-screen imagery class").
- **CANDIDATE (the gap, flagged not concluded):** CoCo worst-case scene load 10.66 s vs oracle
  ~3.8 s ≈ 2.8× — the fidelity gap for the follow-up.
- **DEVIATION (HS-3):** motor-window measure abandoned (Karateka toggles the motor
  continuously → fragmented); used the robust data-activity burst = the tight span. Reported.
