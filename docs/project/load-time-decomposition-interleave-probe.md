# Load-Time Decomposition + Interleave Probe

**Investigation → build** (standalone; primitive UNCHANGED, prod byte-identical).
**t0 (C-35):** 2026-07-05T23:25:01
**Question:** is the worst-case load's ~3.33 s/track (26.65 s for 8 tracks,
3b-1-redux) interleave-TUNABLE (rotational) or fixed-overhead-bound (seek/spin-up)?
**Method:** (1) DECOMPOSE the per-track time non-invasively — Lua timestamps on the
FDC command-register ($FF48) and DSKREG ($FF40) writes the primitive already issues
(HS-3, no primitive edit); (2) attempt a sector-SKEW sweep (1:1 / 2:1 / 3:1).
**HS status:** HS-1 prod `88eba89…` + primitive byte-identical (held) · HS-3
non-invasive (Lua observation only) · HS-4 spin-up isolated · HS-5 correctness held
(byte-for-byte) · HS-6 no layout commit / no render.

---

## 1. Decomposition (AC-1) — the ~3.33 s/track is 95.7% ROTATIONAL

Non-invasive: each `$FF48`/`$FF40` write timestamped with `manager.machine.time`;
the command stream (`$00` Restore · per track `$10` Seek / `$90` Read-m=1 / `$D0`
Force-Int · `$29`/`$A9` DSKREG) splits the whole operation into components.
Deterministic across ≥2 runs. Correctness `WC_MATCH=$A5` (byte-for-byte).

| component                         | value            | share of whole-op |
|-----------------------------------|------------------|------------------:|
| **m=1 read (rotational+transfer)**| **3.193 s/track** (25.51 s / 8) | **95.7%** |
| motor/`dr_spinup` (one-time)      | 0.439 s          | 1.6% |
| Seek (per track)                  | 0.0061 s (0.044 s tot) | 0.2% |
| Restore (one-time) + settle       | ~0.010 s         | ~0.0% |
| **WHOLE-OP (bracket)**            | **26.651 s**     | 100% |

- **Spin-up is a one-time 0.44 s** (the `dr_spinup` `$C000` delay loop), NOT smeared
  into the per-track average. **Steady-state marginal per-track = 3.194 s** — this is
  what scales to bigger scenes. Track 0 (3.154 s) is marginally *lighter* than tracks
  1-7 (3.193 s), so spin-up is fully outside the read (it precedes the Restore).
- **Seek is negligible** (0.006 s/track) — the 8 track-to-track seeks cost 44 ms total.
- **The entire cost is the m=1 read.** 3.193 s ÷ 18 sectors = **0.177 s/sector ≈ 0.89
  revolution** (CoCo 300 RPM = 0.200 s/rev). A clean fraction of the rotation period —
  so **MAME models real rotation**, and the read is paying **~0.89 rev of rotational
  latency per sector**.

**Interpretation.** `dr_read_track_m1` reads a whole track under ONE Read-Multiple
command in a tight byte loop (no per-sector CPU delay). The only way that costs ~0.89
rev/sector is if MAME's `coco_jvc` places consecutive logical sector IDs **~a full
revolution apart physically** — a pessimal interleave for a sequential ID read. So the
cost is **rotational/interleave, not seek or spin-up**: ~95.7% of the load is the
interleave-movable component. **Question resolved: interleave-bound, not fixed-overhead.**

---

## 2. Skew sweep (AC-2/3) — NOT EXPRESSIBLE in the JVC/imgtool path

The sweep requires re-authoring the fixture at different physical interleaves, holding
everything else constant (HS-5). This is **blocked by the fixture format**, verified:

- The fixture is a **JVC (`.dsk`) image — purely LOGICAL**: `off(T,S) = (T·18 + S−1)·256`.
  It encodes *which logical sector holds which bytes*, **not the physical angular order**.
  MAME's `coco_jvc` handler synthesizes the physical track with a **fixed** interleave;
  the image cannot vary it.
- **`imgtool` exposes no interleave option** — `createopts coco_jvc_rsdos` is empty; both
  `coco_jvc_*` and `coco_dmk_*` are *filesystem*-level (write files into a fixed layout),
  not raw-track authoring.
- Expressing a chosen interleave needs a **raw DMK track encoder** (emit IDAM/DAM/gap/CRC
  bytes in a selected physical order). That is a from-scratch, CRC-sensitive encoder
  (a wrong gap/CRC → unreadable track → confounded timing) — **disproportionate to this
  probe and outside its standalone/no-heavy-tooling scope (HS-6)**. Deferred as a
  concrete follow-up, not attempted here (avoids a scope-creep + correctness risk).

**So the sweep cannot be run in the JVC sandbox.** Per §5 off-nominal, this is the
honest finding — with the important refinement that **MAME *does* model rotation** (§1),
so interleave *is* a real lever; it simply isn't expressible in this fixture format.

---

## 3. Tunable fraction + projected tuned budget (AC-4)

- **Tunable fraction: ~95.7%** of the 26.65 s is the rotational read (25.51 s). The fixed
  remainder is ~0.5 s (spin-up 0.44 + seek 0.044 + Restore 0.006).
- **Current per-sector penalty: ~0.89 rev.** A **read-order-matched interleave** (logical
  IDs physically consecutive) collapses the inter-sector wait toward ~0, so a whole-track
  read approaches **~1 revolution + transfer**: ~0.20 s rotation + ~0.15 s DD transfer
  (4608 B at 250 kbit/s) ≈ **~0.2–0.35 s/track** vs the current 3.19 s — a **~10–16×**
  cut on the read component.
- **Projected tuned load (8 tracks):** ~8 × 0.3 s read + 0.44 s spin-up + 0.05 s seek ≈
  **~3 s** (range ~2.5–5 s), vs 26.65 s now — a **~5–10× total improvement**. The tuned
  budget would then be **spin-up + transfer dominated**, not rotational.

*(Projection — the actual tuned number requires the DMK/hardware sweep to confirm MAME
rewards the matched layout as the rotation model predicts.)*

---

## 4. Verdict + decision input (AC-5, foreground for Jay)

> **The ~3.33 s/track is rotational (interleave-bound), NOT seek/spin-up-bound —
> ~95.7% is the interleave-movable read. Interleave IS the lever and IS worth tuning
> (projected ~5–10× to ~3 s). BUT the skew sweep is not expressible in the JVC fixture
> (MAME's `coco_jvc` fixes the physical order; imgtool offers no interleave); evaluating
> and applying a matched interleave requires the DMK raw-track path — or hardware.**

Mapping to §6:
- **Rotational-dominated + skew is the lever** — CONFIRMED by decomposition (not the
  "fixed-overhead" branch).
- **Can't evaluate skew in MAME's JVC sandbox** — the sweep defers to (a) a DMK raw-track
  encoder to author 1:1/2:1/3:1 variants, or (b) hardware-in-the-loop. Until then, 3b-2
  should plan against the **current ~27 s** as the conservative worst-case, noting the
  strong **~5–10× headroom** a matched interleave (DMK/hardware) is projected to unlock.
- **MAME-vs-hardware (25.3-H(divergence))** is *sharpened*: the penalty is a clean 0.89
  rev/sector rotational cost, so real silicon with a matched-interleave disk should show
  the same tunability the model predicts — the open item is now specifically "author/verify
  a matched interleave (DMK/hardware)," not "is it interleave at all."

Do NOT commit a disk layout (Jay's call / 3b-2).

---

## 5. Gaps / follow-ups

1. **DMK skew sweep (the deferred axis):** build a raw-track DMK encoder (IDAM/DAM/gap/CRC,
   selectable interleave), author 1:1/2:1/3:1 8-track variants, re-run the decomposition
   harness on each. This is the direct way to *measure* the tuned budget in MAME.
2. **Hardware-in-the-loop (I-BOTH):** measure the same worst-case load on stock hardware
   with a matched-interleave disk — resolves 25.3-H and validates the projection.
3. **Spin-up review:** `dr_spinup` is a fixed 0.44 s `$C000` software delay — a primitive-
   side tunable (separate from interleave) if the tuned budget makes 0.44 s material.

---

## 6. Candidates / deviations

- **CANDIDATE (decisive):** load time is **95.7% rotational** (3.19 s/track ≈ 0.89
  rev/sector), seek 0.2%, spin-up 0.44 s one-time — **interleave-bound, not fixed-overhead**.
  [disk_worstcase_decomp.lua]
- **CANDIDATE (blocker):** sector skew is **not expressible in the JVC fixture** (logical
  image; MAME `coco_jvc` fixes physical order; imgtool has no interleave opt) — the sweep
  needs a **DMK raw-track encoder** or hardware.
- **CANDIDATE (budget):** projected matched-interleave load **~3 s (~5–10×)**; tuned budget
  becomes spin-up/transfer-dominated.
- **DEVIATION:** the skew-sweep axis (HS-2b) was **not executed** — blocked by fixture-format
  inexpressibility (verified), not skipped. Reported as the §5 off-nominal finding with the
  DMK/hardware follow-up named. Decomposition axis (HS-2a) delivered in full.
- **DEVIATION (fixed in-probe):** first spin-up bracket smeared the frame-150 boot offset
  (timed from a boot-time DSKREG write); corrected to bracket from the entry `$29` write
  immediately preceding the Restore → real `dr_spinup` = 0.44 s.
