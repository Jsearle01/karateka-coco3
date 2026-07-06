# Hardware Gap-Margin Check — procedure + test-kit spec (25.3-H)

**Purpose:** confirm on REAL hardware what is so far only MAME-measured — that the shipped
**1:1-sequential DMK** reads CLEAN (no Lost-Data) with our HALT-paced whole-track m=1 loader,
and at what real load time. **Why it matters:** in MAME, DECB's tight-sequential format
Lost-Data'd our read while the authored imgtool-DMK's more generous gaps read clean (10.66 s
byte-correct). A real WD1773 + drive may tolerate tighter/looser gaps than MAME models — so
the shipped layout's **inter-sector gap margin at 1:1 order is the one unverified assumption**
under the shipped disk (`raw-underlayer-disk-spec.md` §6). This is operator-run (Jay + real
CoCo3); Clyde prepares the kit and the interpretation.

---

## 1. The falsifiable question

**Does the 1:1-sequential authored DMK, flux-written to a real floppy, read all 8 worst-case
tracks byte-for-byte with NO Lost-Data on a real CoCo3 + drive — and in ~how long?**
- **PASS:** byte-correct, no Lost-Data, time ≈ MAME's ~10.66 s (± real-timing) → the shipped
  gap margin holds on hardware; the whole optimization is hardware-validated.
- **FAIL (Lost-Data):** the 1:1 gaps are too tight for the real drive → remedy in §5 (widen
  gaps or trade a small interleave for margin) and re-test.
- **FAIL (slow / wrong data):** interleave or read-path issue → localize.

---

## 2. Artifacts

**Ready now:**
- The 1:1 test pattern DMK — regenerate with `bash tools/make_dmk_skew.sh 0
  build/fixtures/worstcase_il0.dmk` (8 tracks, `byte[g][i]=(g+i)&0xFF`, physical order
  `[1..18]` verified). This is the flux-write source for the read-timing test.

**To BUILD (the test-kit — the one remaining code item, spec below):**
- A **DECB-loadable, self-reporting** version of the WORSTCASE read test: on real hardware
  there is no Lua to read the `$2530` result block or `manager.machine.time`, so the test must
  (a) display PASS/FAIL on the CoCo screen and (b) measure its own load time via the 60 Hz
  VSYNC. Spec in §4. This is a standalone test unit (primitive UNCHANGED, prod byte-identical).

---

## 3. Procedure (operator — Jay)

1. **Flux-write** `worstcase_il0.dmk` to a fresh floppy with Greaseweazle/KryoFlux
   (raw-track write — preserves the 1:1 order + the authored gaps). Verify the write tool
   reports the track layout as written (no re-interleave).
2. **Load + run the self-reporting test** on the real CoCo3 (from the test disk, or LOADM/EXEC
   the test binary against the flux-written data disk in drive 0). It reads tracks 0-7 whole-
   track (m=1) and displays: `MATCH=A5/5A`, `STATUS=$xx` (watch for bit2 `$04` = Lost-Data,
   bit3 `$08` = CRC), and `FRAMES=nnnn` (60 Hz VSYNC count during the read).
3. **Record:** MATCH, STATUS, FRAMES. Load time (s) = FRAMES ÷ 60. Repeat ×2 (determinism).
4. **Optional A/B:** repeat with a DECB-`DSKINI`'d (default) data disk to reproduce the
   MAME-measured clean-but-slow behavior on hardware (confirms the degradation direction on
   silicon too).

---

## 4. Test-kit build spec (the remaining code item)

A `-D HWCHECK` config of `tests/scripted/disk_sandbox_driver.s` (same pattern as WORSTCASE),
standalone, primitive UNCHANGED:
- Reuse `do_worstcase` (8-track m=1 read of drive 0, verify byte-for-byte).
- **Self-timing:** before the read, zero a frame counter; enable the 60 Hz VSYNC IRQ (GIME/PIA
  vertical-sync) and INC the counter per VSYNC; stop at read end. (Or poll the PIA VSYNC flag /
  a GIME timer — no reference clock needed, 60 Hz is the on-hardware time base.)
- **On-screen report:** write to the DECB text screen (`$0400`): the MATCH byte (`A5`/`5A`),
  the STATUS byte (highlight if `$04`/`$08` set), and the frame count (→ seconds). Plain
  VDG-char pokes; no ROM calls needed.
- **DECB-loadable:** assemble to a `.bin` and place it on the test disk as a `LOADM`-able file
  (` machine-code, EXEC entry), OR provide a tiny BASIC loader. Keep the DATA pattern on tracks
  0-7 and the PROGRAM clear of them (load the program high, e.g. $3F00, read buffer $4000+ or
  reuse the existing $3000 dest clear of the program).
- Emit both the MAME-runnable path (Lua reads `$2530`, as today) and the on-screen path from
  one source (`ifdef HWCHECK`), so MAME and hardware run the identical read.

*(This kit is a standalone test unit — no prod/primitive change. It is the concrete "next
build" if Jay authorizes the hardware run.)*

---

## 5. If it FAILS on hardware (Lost-Data) — remedies, in order

1. **Widen the authored inter-sector gaps.** imgtool's DMK gap length is fixed; use a DMK/flux
   tool that exposes GAP3 (post-data gap) and author larger gaps at 1:1 order — the direct fix
   (keeps sequential speed, adds DRQ-service margin). Re-test.
2. **Trade a minimal interleave for margin.** If widening gaps isn't available, a 2:1 interleave
   (il=1, measured 12.27 s in MAME) buys inter-sector time at ~15 % speed cost — a fallback if
   1:1 is unshippable on real drives.
3. **Soften the read cadence** — LAST resort, and a PRIMITIVE change (out of the current
   no-primitive-edit scope): a small per-sector settle in `dr_read_track_m1`. Avoid unless 1+2
   fail; it costs speed and touches the shared primitive.

Report which remedy (if any) was needed — it feeds the final authored-disk gap spec.

---

## 6. What to report back (closes 25.3-H)

- PASS/FAIL (MATCH + STATUS, Lost-Data present?), the FRAMES→seconds load time, ×2 for
  determinism, drive/controller used.
- If FAIL: which §5 remedy resolved it + the resulting gap/interleave.
- Outcome updates `raw-underlayer-disk-spec.md` §6 (gap margin) and, if a remedy changed the
  layout, §3 (interleave) — closing the last hardware-flagged assumption in the disk spec.
