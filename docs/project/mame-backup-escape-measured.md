# MAME-BACKUP Proxy — the escape hatch MEASURED (and REFUTED)

**Verification** (MAME-executed DECB DSKINI + in-session load-time re-measure).
**t0 (C-35):** 2026-07-06T00:56:14
**Supersedes** the *inferred* escape hatch in `interleave-distribution-preservation.md`
(§Path-4-escape: "`DSKINI drive,0` before BACKUP → sequential → fast"). That inference is
**REFUTED by measurement** here.
**HS status:** HS-1 prod `88eba89…` + primitive byte-identical (held) · HS-2 source is the
1:1 DMK (10.66 s) · HS-3 both DSKINI skips run · HS-4 load-time re-measured (the dispositive
axis; order-inspection was blocked — see Method) · HS-5 correctness separate from speed ·
HS-6 feasibility honestly bounded · HS-7 no format commitment.

---

## Method — and what was blocked (HS-6, honest)

The dispatch's ideal (image each BACKUP'd disk, inspect physical order, re-measure) hit two
hard MAME limits:
1. **MAME cannot write DMK back** — DSKINI ran (738 FDC cmds) but the `.dmk` was byte-
   unchanged on disk (DMK/SDF are read-only in MAME's format layer; only JVC/rawdsk save,
   and JVC discards physical order). So a DSKINI'd/BACKUP'd disk **cannot be imaged** to
   inspect its order.
2. **MAME Lua exposes no floppy track-data accessor** — the floppy devices enumerate but
   expose no readable track buffer.

**Sidestep (validated):** run DECB `DSKINI 0[,skip]` under MAME (formats DRIVE 0's *in-memory*
floppy with DECB's real skip-N interleave), then **hijack the CPU in-session** — load the
WORSTCASE m=1 read harness and time an 8-track read of that just-formatted disk. No write-back
needed; the load TIME reflects DECB's actual physical order. **Proxy validated by a control:**
hijack-reading the pristine imgtool il0 reproduces the known-good **10.66 s, `WC_MATCH=$A5`
byte-correct** read exactly — so the hijack is sound and the results below are trustworthy.

---

## Results (all deterministic, ≥2 runs where surprising)

| MAME run | load time (8 trk) | read outcome | meaning |
|---|---:|---|---|
| **Control — imgtool il0 (our ship path)** | **10.6637 s** | clean, 25 FDC cmds, `WC_MATCH=$A5` byte-correct | proxy validated; ship path is fast + correct |
| **DECB default (`DSKINI 0`, skip 4)** | **16.5880 s** | clean, 25 FDC cmds, RNF-benign, `$5A` (empty) | correct-but-**slow** (~1.55× the optimum) |
| **DECB `DSKINI 0,0` (skip 0 — the "escape")** | — (bail @ trk 0) | **Lost-Data** (`WC_STATUS=$14`), 4 FDC cmds, deterministic ×2 | **UNREADABLE** by our m=1 loader |

---

## Findings

1. **Degradation CONFIRMED (milder than estimated).** A DECB-**default** (skip-4) disk reads
   cleanly but at **16.59 s** — ~1.55× the 10.66 s optimum (not the ~2.5× the imgtool-sweep
   extrapolation guessed; DECB skip-4's actual order is a *moderate* spread). A `BACKUP` to a
   default-formatted destination copies data by ID into this skip-4 layout → the copy reads
   **~16.6 s (correct-but-slow)**. The risk is real, magnitude now measured.

2. **The escape hatch is REFUTED — worse than "doesn't help": it produces an UNREADABLE disk.**
   `DSKINI drive,0` (skip 0) yields a disk our whole-track m=1 read hits **Lost-Data** on and
   bails at track 0 (deterministic). Lost-Data = data arriving faster than serviced — the
   classic tight-sequential symptom: DECB's DSKINI writes **tighter inter-sector gaps** than
   imgtool's DMK, and at sequential (0-skip) order the m=1 continuous read overruns. imgtool
   il0 (also sequential) reads clean *because its DMK gaps are more generous*; DECB's are not.
   So the inferred escape (`DSKINI drive,0` → fast copy) **does not deliver a working disk**.

3. **Neither DECB stock-format setting gives clean-AND-fast for our loader:** default skip-4 =
   clean-but-slow (16.6 s); skip-0 = fast-order-but-unreadable (Lost-Data). Only the authored
   imgtool DMK (or a flux-write of it) is clean-and-fast (10.66 s).

---

## Verdict + decision input (foreground for Jay)

> **The BACKUP escape hatch is REFUTED under MAME. `DSKINI drive,0` produces a disk our m=1
> loader cannot read (Lost-Data); `BACKUP` to a default disk is correct-but-slow (16.6 s).
> DECB stock tools (DSKINI/BACKUP) are NOT a viable fast-copy path. Distribute the authored
> 1:1 DMK IMAGE (copy the file / flux-write) — that is the only clean-and-fast path (validated
> at 10.66 s byte-correct in MAME).**

This **strengthens and corrects** the prior distribution matrix:
- Prior (inferred): "BACKUP degrades unless you `DSKINI drive,0` first (the escape)."
- Now (measured): "`DSKINI drive,0` makes it **unreadable**; there is **no** stock-tool escape —
  ship/redistribute the image."
- Image paths (copy the DMK, flux-write) unchanged: preserve 10.66 s.

**I-BOTH:** measured on MAME (the shipping target) — dispositive there. Whether DECB skip-0's
tight gaps also Lost-Data on real hardware, or whether real gap timing differs, is **25.3-H**
(the same tight-sequential-gap question applies to our authored disk on real silicon — flag
for hardware: confirm the shipped 1:1 image's gaps read clean on a real drive).

---

## Gaps

1. **Physical-order inspection** — blocked (DMK write-back read-only; no Lua track access).
   The validated load-time proxy is the dispositive substitute (HS-4).
2. **BACKUP correctness** — not directly run (the proxy used DSKINI-only, empty disk);
   correctness is source-proven (data moved by ID). The NEW result is about *order/speed*.
3. **Real-hardware gap timing** — the skip-0 Lost-Data (and the shipped image's gap margin)
   is MAME-measured; hardware behavior is 25.3-H.

---

## Candidates / deviations

- **CANDIDATE (inverts the prior inference):** the `DSKINI drive,0` escape is REFUTED — it
  produces a disk our m=1 loader Lost-Datas on (tight DECB sequential gaps). No stock-tool
  fast-copy path exists. [decb_dskini_timing.lua]
- **CANDIDATE (measured):** DECB default (skip-4) disk reads clean at **16.59 s** (~1.55×
  the 10.66 s optimum) — BACKUP-to-default is correct-but-slow, magnitude now measured.
- **CANDIDATE (proxy validated):** hijack-read of pristine il0 = 10.66 s `$A5` byte-correct,
  identical to the normal run → the in-session measurement is trustworthy.
- **CANDIDATE (new hardware flag):** tight-sequential DECB gaps Lost-Data our aggressive
  whole-track m=1 read; imgtool DMK gaps tolerate it → verify the shipped image's gap margin
  on real hardware (25.3-H).
- **DEVIATION (HS-6):** order-inspection via write-back was infeasible (DMK read-only in
  MAME); resolved via the validated in-session load-time proxy instead of fabricating an
  order dump. BACKUP itself not executed (DSKINI-order proxy sufficient + BACKUP correctness
  is source-proven).
