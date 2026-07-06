# Interleave Realization in MAME — tool → prove → measure (gated A/B/C)

**Investigation → conditional build** (standalone; primitive UNCHANGED, prod byte-identical).
**t0 (C-35):** 2026-07-05T23:56:21
**Question (I-BOTH):** can a read-matched sector interleave bring the worst-case load
time down **in MAME** — the 27 s MAME number being a shipping defect on a first-class
target, not deferrable to hardware?
**HS status:** HS-1 prod `88eba89…` + primitive byte-identical (held) · HS-2 phases gated
(A→B→C, none skipped) · HS-3 I-BOTH — the MAME number is the target (no hardware
deferral) · HS-4 Phase B minimal + honest · HS-5 correctness held under every interleave ·
HS-6 no layout/mechanism commit, no render · HS-7 physical order verified before trusting
deltas.

---

## Phase A — tooling (AC-A): DMK exposes interleave; no encoder needed

`imgtool create coco_dmk_rsdos <img> --tracks=35 --sectors=18 --sectorlength=256
--interleave=<0-17>` produces a MAME-readable DMK with a **chosen physical interleave**.
- The prior probe's "imgtool exposes no interleave" was a **mis-invocation** — it used the
  non-existent `createopts` subcommand (which prints usage) and checked only the JVC
  format (no interleave option). The correct query is `listdriveroptions coco_dmk_rsdos`,
  which lists `--interleave 0-17`. **No from-scratch CRC encoder is required** (F-A1 avoided).
- Payload placed by logical sector ID via `writesector`, so the m=1 read (IDs 1..18/track)
  and its byte-for-byte verify are identical across interleaves — only physical placement
  changes. Generator: `tools/make_dmk_skew.sh <interleave> [out.dmk]`.
- **HS-7 verified** — parsing the DMK IDAM table confirms the physical order came out as
  requested: il=0/17 → `[1,2,3,…,18]` sequential; il=1 → `[1,10,2,11,…]` (step-2); il=9 →
  `[1,10,3,12,…]` (wide spread). The tool does not silently normalize.

---

## Phase B — the gate (AC-B): MAME REWARDS physical interleave (PASS)

Same 8-track / 144-sector / 36 KB payload, two physical layouts, same harness
(`disk_worstcase_decomp.lua`), `manager.machine.time` bracket. Byte-for-byte correct both.

| fixture | physical order | load time | ms/track |
|---|---|---:|---:|
| JVC baseline (prior probe) | MAME default | 26.65 s | 3331 |
| DMK il=1 (step-2) | `[1,10,2,…]` | 12.27 s | 1533 |
| **DMK il=0/17 (sequential)** | `[1,2,3,…]` | **10.66 s** | **1333** |

**Delta is large and real → MAME's read path models physical angular order → interleave IS
the MAME lever (P-B1).** The dominant effect is the **JVC→DMK switch: ~2.5×** (26.65→10.66 s)
— MAME's JVC container imposes a pessimal default interleave (≈ the il=9 spread, see Phase C),
while DMK preserves the authored order. **This resolves the 27 s under I-BOTH without a
hardware appeal** — the fix (author the disk 1:1 / ship DMK-preserving order) lands in MAME
and on hardware alike.

---

## Phase C — sweep + tuned budget (AC-C): sequential (1:1) is optimal, 10.66 s

Full interleave sweep, decomposed timing, ≥2 runs (il=0 identical across runs — C-14 held),
byte-for-byte correct at **every** interleave (HS-5):

| il | phys order (first 6) | load s | ms/trk |
|--:|---|---:|---:|
| **0 / 17** | `[1,2,3,4,5,6]` sequential | **10.66** | **1333** |
| 1 | `[1,10,2,11,3,12]` | 12.27 | 1533 |
| 2 | `[1,7,13,2,8,14]` | 13.85 | 1731 |
| 4 | `[1,12,5,16,9,2]` | 17.06 | 2132 |
| 6 | `[1,14,9,4,17,12]` | 20.26 | 2532 |
| 9 | `[1,10,3,12,5,14]` | 25.07 | 3133 |
| 13 | `[1,10,5,14,9,18]` | 31.46 | 3932 |

- **Best skew = SEQUENTIAL (1:1, il=0/17) = 10.66 s** (2.50× vs JVC's 26.65 s). Interleave
  **monotonically worsens** the time (il=13 = 31.5 s, *worse* than JVC). The classic "spread
  sectors to give the CPU breathing room" is **inverted here**: our HALT-paced m=1
  Read-Multiple reads a whole track in one command and keeps pace within it, so it wants
  sectors **physically consecutive**. The JVC default's ~il=9-equivalent spread (25 s) is
  exactly the pessimal case.
- **Residual floor:** even sequential is **1.19 s/track marginal ≈ ~6 rev/track**, not the
  ~1 rev/track the prior probe's ~3 s projection assumed. Decomposition: 99.5% is still the
  read (rotational/transfer), seek 0.5%, spin-up 0.44 s one-time. So ~5 rev/track of
  per-sector overhead remains that interleave **cannot** remove — a MAME wd_fdc Read-Multiple
  floor. **The ~3 s projection was optimistic; the achievable tuned budget is ~10.66 s.**

---

## Verdict + decision input (§6, foreground for Jay)

> **Interleave IS the MAME lever and the fix lands in MAME (I-BOTH satisfied): shipping the
> disk with SEQUENTIAL (1:1) physical order — via DMK, which preserves it — cuts the
> worst-case 36 KB load from 26.65 s to 10.66 s (2.5×), byte-for-byte correct. But it does
> NOT reach the projected ~3 s: a ~6 rev/track MAME wd_fdc per-sector floor remains that
> interleave can't touch. This is the §6 "B passes, C partial" outcome — interleave helps
> but does not fully fix; 3b-2 needs 1:1 interleave PLUS load-masking for shippable perceived
> time.**

Concrete, actionable inputs (not commitments — HS-6):
- **Ship format:** DMK (or any container preserving authored order); **do NOT ship the
  default JVC** — it costs 2.5× (pessimal interleave).
- **Disk interleave:** **1:1 / sequential** — which *inverts* the normal RS-DOS interleave
  convention (BASIC's sector-at-a-time access wants a spread; our whole-track m=1 loader
  wants sequential). A non-obvious authoring requirement.
- **Residual masking:** the worst-case 10.66 s (36 KB) still needs masking behind a scene
  transition/fade; typical smaller scenes (<36 KB) scale down proportionally (1.33 s/track +
  0.44 s spin-up).

No hardware deferral was used (HS-3): the JVC 27 s was a MAME-container artifact, fixed by
DMK+1:1 in MAME; the residual 10.66 s is a real FDC read cost on both targets → masking, not
excusing.

---

## Gaps / follow-ups

1. **The ~6 rev/track sequential floor** — why MAME's wd_fdc Read-Multiple costs ~0.3
   rev/sector even sequential (vs the ~1 rev/track ideal) is unexplained; a future probe
   (Read-Multiple vs per-sector m=0, or the wd_fdc gap model) could find whether a different
   read mechanism beats it. This is the residual lever the tuned budget still leaves.
2. **Load-masking design** (3b-2): overlap the 10.66 s worst-case with a transition.
3. Interleave layout is not committed (HS-6) — 3b-2 / Jay's call.

---

## Candidates / deviations

- **CANDIDATE (Phase A):** `imgtool coco_dmk_rsdos --interleave 0-17` gives chosen-interleave
  MAME-readable images; the prior "no tool" was a `createopts` mis-invocation. No encoder needed.
- **CANDIDATE (Phase B, the gate):** MAME rewards physical interleave — JVC 26.65 s → DMK
  sequential 10.66 s = **2.5×**, byte-for-byte correct.
- **CANDIDATE (Phase C):** **sequential (1:1) is optimal**; interleave monotonically worsens
  (m=1 whole-track read wants consecutive sectors — inverts RS-DOS convention). Tuned worst-
  case budget **10.66 s**.
- **CANDIDATE (residual):** a ~6 rev/track MAME wd_fdc floor remains interleave can't reduce
  → the ~3 s projection was optimistic; masking still needed (F-C1 partial).
- **DEVIATION:** none from the gated method. Phases A→B→C ran in order; B's gate passed so C
  proceeded. The ~3 s projection from the prior probe is corrected to ~10.66 s here.
