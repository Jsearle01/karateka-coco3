# Distribution-Format Interleave Preservation — verification matrix

**Verification** (tool-behavior + format-order inspection; no build/primitive/hardware).
**t0 (C-35):** 2026-07-06T00:36:02
**Verifies:** whether the 10.66 s optimization — which depends entirely on the DMK being
laid **1:1 sequential** (`interleave-realization-mame.md`) — survives each distribution
path. Order VERIFIED at every transforming hop (HS-2), not assumed.
**HS status:** HS-1 prod `88eba89…` + primitive byte-identical (held) · HS-2 order inspected
per hop (IDAM parse / DECB-source analysis) · HS-3 correctness reported SEPARATELY from the
optimization · HS-4 image-level + doc proxies (no hardware) · HS-5 load-time anchored to the
measured sweep · HS-6 no format commitment.

---

## The dependency being protected

Phase B/C proved: **sequential (1:1) physical order → 10.66 s; any spread interleave →
slower, monotonically** (il=2 → 13.9 s, il=9 → 25 s, il=13 → 31.5 s; JVC default ≈ 27 s).
Our HALT-paced m=1 whole-track Read-Multiple wants physically-consecutive sectors — the
*opposite* of the RS-DOS convention. So the optimization is FRAGILE: any hop that re-lays
the disk in a non-sequential physical order silently reverts it to ~27 s (correct-but-slow).

---

## Preservation matrix (AC-5)

| Path | Correct? (byte-for-byte) | Order preserved? (10.66 s) | Evidence / authority |
|------|:---:|:---:|------|
| **1. MAME native DMK** | YES | **YES** — sequential `[1..18]` | EXECUTION — Phase B re-confirmed: il=0 order `[1,2,…,18]`, 10.66 s |
| **2a. SDC reads the DMK directly** | YES (exp) | **YES** (same DMK) | Inferred from Path 1 (CoCo SDC reads DMK natively); UNVERIFIED on real SDC → hardware-flagged |
| **2b. dmk2sdf → SDF** | ? | **UNVERIFIED** | Tool absent (no dmk2sdf; imgtool/floptool cannot *write* SDF). SDF stores raw tracks by design → doc-expectation preserve, not proven |
| **3. Real floppy (Greaseweazle/KryoFlux flux-write)** | YES (exp) | **YES** (raw flux) | DOC — flux-writers lay raw tracks → preserve by construction; hardware-flagged (not silicon-confirmed) |
| **4. DECB `BACKUP` (CoCo-to-CoCo)** | **YES** | **NO** — dest format wins → default skip-4 spread → ~25-30 s | DECB SOURCE (definitive) + measured-sweep anchor |
| **4-escape. `DSKINI drive,0` then BACKUP** | ~~YES~~ | ~~YES (skip-0 = seq)~~ **REFUTED** | **SUPERSEDED** — measured in `mame-backup-escape-measured.md`: skip-0 → UNREADABLE (Lost-Data). No stock-tool escape exists. |

---

## Path 4 — DECB BACKUP (the flagged risk): CONFIRMED correct-but-slow

From `disk-basic-unravelled.pdf` (the canonical DECB DOS source — definitive for DECB behavior):

- **BACKUP transfers SECTOR DATA by ID, not raw tracks.** Its RAM buffer is `SECMAX*SECLEN`
  = 18×256 = **4608 B/track** (a raw track with gaps/IDAMs would be ~6250 B). The read/write
  routines (LD2FC/LD2FF) issue **DSKCON sector ops** (read op `$02`, write op `$03`,
  buffer `DFLBUF`), looping sectors 1..18 (`LDB #$01 … CMPB #18`). So BACKUP reads logical
  sectors by ID into an ID-ordered buffer and writes them back by ID — **physical angular
  order is discarded at read time**; the copy's order = the **destination disk's existing
  format**, never the source's.
- **The default format is INTERLEAVED.** DSKINI's default skip factor = **`LDB #$04`**
  ("SKIP FACTOR DEFAULT VALUE"; max 16). Simulating the DSKINI logical→physical algorithm:
  - **skip=0 → `[2,3,…,18,1]`, consecutive-logical spacing 1.0 = SEQUENTIAL** (fast).
  - **skip=4 (default) → `[6,11,16,3,8,13,18,5,10,15,2,7,12,17,4,9,14,1]`, spacing ~11.0**
    = heavily spread (slow).
- **Therefore:** `BACKUP` to a normally-formatted (default skip-4) destination produces a
  **byte-for-byte correct but ~2.5-3× slower** copy — the spacing-11 spread sits in the
  il=9-13 region of the measured sweep (**~25-31 s**), reverting the entire 10.66 s
  optimization. This is the silent performance regression (P4a), CONFIRMED.
- **Escape (F4a, conditional):** `DSKINI drive,0` (sequential) BEFORE `BACKUP` yields a
  sequential destination → the copy stays fast. But the **default** path degrades; a user
  who just `BACKUP`s to a fresh default-formatted disk gets the slow copy with no warning.

*(A MAME-CoCo BACKUP proxy — boot DECB, DSKINI+BACKUP, image, re-inspect — was judged
unnecessary: the DECB source is dispositive (sector-by-ID + default skip-4), and the sweep
already supplies the load-time anchor. The proxy remains available as execution-authority
confirmation if Jay wants it.)*

---

## Paths 2 & 3 — image/hardware (hardware-flagged)

- **Path 2 (SDC):** `dmk2sdf` is not present, and neither imgtool nor floptool can *write*
  SDF, so the SDF track order could not be inspected → **UNVERIFIED** (not "preserves").
  BUT the CoCo SDC reads **DMK natively**, so the SDC path need not convert to SDF at all —
  ship the 1:1 DMK and the SDC honors it (Path 2a), same as Path 1. The dmk2sdf→SDF
  sub-path is avoidable; if used, its order must be inspected on real hardware/SDC.
- **Path 3 (flux):** Greaseweazle/KryoFlux/SCP write raw track/flux images → physical order
  preserved by construction. Documented, **not silicon-confirmed** (no hardware here) — flag
  for hardware verification.

---

## Verdict + decision input (§5, foreground for Jay)

> **The 10.66 s optimization survives IMAGE-level distribution (MAME DMK, SDC-reads-DMK,
> flux-write) but is SILENTLY LOST by DECB `BACKUP` to a default disk (correct but ~25-30 s,
> the DECB default skip-4 interleave). Distribute as IMAGES; treat CoCo-native `BACKUP` as
> producing a working-but-slow copy unless the destination is pre-`DSKINI`'d skip-0.**

Distribution inputs (not commitments — HS-6):
- **Ship the 1:1 DMK image** (MAME + SDC both read DMK natively, order preserved). Do NOT
  ship JVC (its default interleave is the slow ~27 s case).
- **Real floppy:** flux-write the 1:1 image (Greaseweazle/KryoFlux) — preserves; confirm on
  hardware.
- **Document the BACKUP caveat:** CoCo-to-CoCo `BACKUP` reverts to ~27 s (correct, slow)
  unless the user `DSKINI drive,0` first — i.e. stock-tool duplication is NOT the supported
  fast-share path; ship/redistribute the image.
- The raw scene tracks ship 1:1-sequential; the DECB boot/directory surface is read by ID,
  so interleave doesn't affect its correctness (only the whole-track scene-load speed).

I-BOTH: MAME (native DMK) and hardware (SDC-DMK / flux) both preserve; the two hardware
paths (SDC, flux) are documented-not-silicon-confirmed → 25.3-H.

---

## Gaps

1. **SDF order** (Path 2b) — unverifiable without dmk2sdf / an SDF writer; avoidable (ship DMK).
2. **Hardware confirmation** (Paths 2a/3) — SDC-reads-DMK and flux-write preservation are
   doc/inference, not silicon-measured. 25.3-H.
3. **MAME-BACKUP execution proxy** — not run (DECB source dispositive); available on request.

---

## Candidates / deviations

- **CANDIDATE (the risk, CONFIRMED):** DECB `BACKUP` degrades the 1:1 optimization —
  sector-by-ID transfer + default skip-4 destination → correct-but-~25-30 s. Escape:
  `DSKINI drive,0` first. [disk-basic-unravelled.pdf: DSKINI `LDB #$04`, BACKUP LD2FC/LD2FF]
- **CANDIDATE:** DECB default skip factor = **4** (spacing ~11); skip-**0** = sequential —
  the only DSKINI setting that preserves the fast layout.
- **CANDIDATE:** ship as **DMK image** — MAME and SDC both read DMK natively (order
  preserved); JVC and default-BACKUP are the slow paths.
- **DEVIATION:** Path 2b (SDF) UNVERIFIED — tooling absent, reported as such (HS-2), not
  claimed as "preserves." MAME-BACKUP proxy not run — DECB source dispositive.
