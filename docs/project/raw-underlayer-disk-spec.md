# Raw-Underlayer Disk Spec (3b-2) — format, interleave, distribution

**Status:** consolidation of the VERIFIED disk-loader thread (capacity → expansion →
interleave → distribution). Sections marked **[ESTABLISHED]** are settled by measurement;
**[OPEN]** are still Jay's-decision / to-build in 3b-2. Prod byte-identical; the primitive
(`disk_read.s`) is unchanged.

**Source docs:** `content-expansion-capacity-projection.md`,
`gameplay-graphics-fraction-firming.md`, `interleave-realization-mame.md`,
`load-time-decomposition-interleave-probe.md`, `interleave-distribution-preservation.md`,
`mame-backup-escape-measured.md`, `disk-read-primitive-design.md`.

---

## 1. Capacity [ESTABLISHED]

- Apple content ≈ **124 KB** on `karateka.dsk` (35×16×256 DOS 3.3). No full-screen imagery
  class (hi-res pages are render buffers) — content is **sprites (~1.62×/1.68× expansion) +
  code (~1×)**.
- Projected CoCo image **~155-161 KB, center ~158 KB** (refined resident-image graphics
  fraction ~44%) → **single 35-track disk, OVER the 153 KB DECB-usable line**, at/over the
  157.5 KB raw-35 limit. **Two-disk ruled out.**
- **Implication:** the ~4.6 KB DECB directory tax is **load-bearing**. **[OPEN]** DECB-vs-raw
  container for the DIRECTORY/BOOT surface, and whether a ~3-8 KB trim / 40-track is needed —
  turns on the uncaptured gameplay-level content mix (needs new dump capture to firm).

## 2. Container format [ESTABLISHED for the raw scene tracks]

- **Ship the raw scene tracks as a 1:1-SEQUENTIAL DMK image.** DMK preserves the authored
  physical sector order; MAME and the CoCo SDC both read DMK natively.
- **Do NOT ship JVC** — MAME's JVC path imposes a pessimal default interleave (the slow
  ~27 s case). JVC is logical-only (can't express the 1:1 layout).
- Geometry: 35 tracks × 18 sectors × 256 B, DD. The raw scene tracks are read whole-track by
  ID (`disk_read_range`, m=1); interleave affects only their read SPEED, not correctness.
- **[OPEN]** the DECB boot/directory surface container (DMK-with-RSDOS-filesystem vs raw) —
  §1's DECB-vs-raw decision. The directory/boot is read by ID, so its interleave is
  correctness-neutral; only the whole-track scene reads care about 1:1.

## 3. Interleave [ESTABLISHED]

- **1:1 SEQUENTIAL is optimal** for our HALT-paced m=1 whole-track Read-Multiple (it wants
  physically-consecutive sectors — the OPPOSITE of the RS-DOS convention). Any spread
  interleave monotonically worsens the read (measured: il=0/17 seq = 10.66 s → il=13 =
  31.5 s). Author the scene tracks at **imgtool `--interleave=0`** (verified sequential
  `[1..18]`).
- **Do NOT format the scene tracks with DECB DSKINI.** Measured: DECB's *sequential* format
  (skip 0) writes gaps too tight for our aggressive m=1 read → **Lost-Data (unreadable)**;
  DECB *default* (skip 4) reads clean-but-slow (16.6 s). The authored imgtool-DMK gaps are
  what make the 1:1 layout READ CLEAN (10.66 s byte-correct). Gap margin is
  layout-critical — see §6 hardware flag.

## 4. Load-time budget [ESTABLISHED]

- **Worst-case scene (36 KB / 8 whole tracks): ~10.66 s** at 1:1 sequential DMK (2.5× better
  than JVC's 26.65 s). Per-track marginal **~1.19 s** + one-time **0.44 s** spin-up +
  negligible seek.
- The residual ~6 rev/track is a **MAME wd_fdc per-sector floor** interleave can't remove
  (the ~3 s projection was optimistic). Smaller scenes scale down (1.33 s/track + 0.44 s).
- **[OPEN]** **Load-masking is REQUIRED** for shippable perceived time — overlap the ~10.66 s
  worst-case behind a scene transition/fade. 3b-2 design item.

## 5. Distribution [ESTABLISHED — corrected, image-only]

**The 1:1 fast layout survives IMAGE distribution only. There is NO stock-tool fast-copy
path** (the DECB `BACKUP`/`DSKINI drive,0` escape is REFUTED — it produces an unreadable
disk). Distribute the authored DMK image:

| Path | Fast (1:1 preserved)? | How |
|------|:---:|-----|
| **Copy the DMK file** (MAME / SDC) | **YES** | byte-copy the image; MAME + SDC read DMK natively (10.66 s, validated) |
| **Flux-write** (Greaseweazle / KryoFlux / SCP) | **YES** (by construction) | raw-track write preserves order + gaps; **hardware-confirm gap margin** (§6) |
| DECB `BACKUP` to default disk | NO — correct-but-**slow** (~16.6 s) | sector-by-ID into skip-4 format |
| DECB `DSKINI drive,0` + BACKUP (the ex-"escape") | **NO — UNREADABLE** (Lost-Data) | tight DECB sequential gaps; REFUTED |

**Guidance to document for users:** "Duplicate this disk by copying the IMAGE (or flux-writing
it), NOT with CoCo `BACKUP` — a BACKUP'd copy is slower (or unreadable). The speed lives in the
disk's physical layout, which stock DECB tools do not reproduce."

## 6. Hardware verification flag [OPEN — 25.3-H]

The 1:1 layout reads clean **in MAME** (10.66 s byte-correct), but the Lost-Data seen on
DECB's tight-sequential format is a warning: **the shipped image's inter-sector gap margin at
1:1 order must be confirmed on real hardware** (a real WD1773 + drive may tolerate tighter or
looser gaps than MAME models). See `hardware-gap-margin-check.md` for the test procedure.

## 7. Open decisions for 3b-2 (Jay's call / to-build)

- DECB-vs-raw container for the boot/directory surface (§1, the 153 KB straddle).
- Whether a content trim / 40-track is needed (needs gameplay-level dump capture to firm §1).
- Load-masking design (§4).
- Real-hardware gap-margin confirmation (§6).
- The raw scene-track layout (which scenes → which tracks; the loader's track map).
