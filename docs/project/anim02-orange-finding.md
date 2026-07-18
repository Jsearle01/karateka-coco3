# anim_02 orange — mechanical diagnosis (2026-07-18) — REPORT ONLY, fix NOTHING (gate failed)

**Symptom (Jay):** orange lines appear at climb pose `anim_02` and **nowhere else**, near the player's
lower body ("butt area").
**Leading hypothesis (dispatch §1.2):** under double-buffering `cl_render` draws into the *back* buffer,
so a pose's carryover source is **two poses back** ⇒ anim_02 inherits `anim_00` (the Y158 outlier);
anim_00 draws **outside** the fixed restore bbox and its un-restored pixels surface at anim_02.
**Result: the hypothesis is FALSIFIED. The mechanism does not exist. FIX NOTHING (HS-A10).**

## AC-1 — predecessor-of-record (from `cl_render`'s toggle order) — CONFIRMED, but moot
`cl_render` (climb_controller.s:90–112) draws into the back buffer (`page_register` $50), presents,
then `eora #$60` toggles. First cycle: pose0→A, pose1→B, pose2→A, pose3→B, pose4→A, pose5→B, pose6→A.
So **anim_02 renders into buffer A, last written by anim_00** — the 2-back rule holds (P-A1). *(Note:
with 7 poses/cycle the parity flips each loop, so this holds for the first cycle — which is what we
captured.)* This is confirmed but **irrelevant**, because there is nothing to carry (below).

## AC-1 — anim_00's drawn extent vs the bbox — INSIDE (F-A2)
Restore bbox: `CL_BX0=20,CL_BW=13` → byte cols **20–32**; `CL_BY0=112,CL_BH=56` → rows **112–167**.
Computed from the pose table (`fcb col,sub,row`) + cel dims (`fcb height,width`):
| pose | parts (col,sub,row · h×w) | drawn extent rows | drawn cols | vs bbox |
|---|---|---|---|---|
| anim_00 | A3E9(21,3,158·8×6) A3C5(22,2,141·17×4) | **141–165** | 21–27 | INSIDE (bottom 165 ≤ 167) |
| anim_01 | A425(22,2,148·17×6) A40B(24,1,140·8×4) | 140–164 | 22–28 | INSIDE |
| anim_02 | A4A4(22,2,143·22×4) A45A(26,0,139·24×6) | 139–164 | 22–31 | INSIDE |
| anim_03 | A4F2(22,2,143·21×7) A4D2(24,1,137·6×9) | 137–163 | 22–32 | INSIDE |
| anim_04 | A572(22,2,141·22×7) A548(24,1,131·10×7) | 131–162 | 22–31 | INSIDE |
| anim_05 | A5DC(24,1,127·36×6) A5CC(26,0,120·7×3) | 120–162 | 24–30 | INSIDE |
| anim_06 | 899C/8ACB/8E9B (settle) | 116–161 | 25–28 | INSIDE |

**Every pose is fully contained in the restore bbox.** anim_00 is *not* an out-of-bbox outlier — its
bottom row is 165, two rows *inside* the box bottom (167). **F-A2: extent inside bbox ⇒ not
out-of-bbox.** Verified empirically: each pose's actual drawn-pixel bbox (diff vs clean substrate)
matches the computed extent exactly (row = cel top; blit descends), confirming the arithmetic.

## AC-2 — exclusivity table (E1/E2/E3) — the crux
Because the bbox **fully contains every pose**, `cl_restore` repaints each pose's entire footprint to
clean substrate before drawing, so **no pixel is ever left un-restored** — there is no carryover for
*any* pose, not just the negative cases. Empirical confirmation (diff of each captured displayed frame
vs the clean substrate, buffer B at pose0): **orange pixels outside the pose's own body extent = 0 for
all 7 poses.** ⇒ **E3: the mechanism is not out-of-bbox carryover.** The anim_00-outlier story is a
coincidence that fit one frame (HS-A1 gate: an explanation that ignores the negative cases is wrong).

## AC-3 — predicted vs observed — MISMATCH (F-A4) ⇒ what the orange actually is
The carryover mechanism predicts the leak **below row 167** (anim_00's overflow). Observed orange at
anim_02 is at **rows 143–163, inside the body** — predicted region ≠ observed ⇒ wrong mechanism (HS-A5).
Discriminator (introduced-orange = orange in the pose but not in the clean substrate, within the bbox):
| pose | orange introduced by the pose's own cels |
|---|---|
| anim_00 | 21 |
| anim_01 | 18 |
| **anim_02** | **72** |
| anim_03 | 30 |
| anim_04 | 26 |
| anim_05 | 33 |
| anim_06 | 39 |

**anim_02's own body cels (`A4A4`/`A45A`) introduce ~3–4× the orange of every other pose**, concentrated
in the lower body (row histogram peaks r143:13, r155:10, r153:7, r157:6). **So the orange is anim_02's
POSE/CEL CONTENT — pose-specific by construction — not a restore-bbox carryover.** That is exactly why
it is "anim_02 and only anim_02."

## VERDICT (report only — HS-A10: FIX NOTHING)
The out-of-bbox carryover hypothesis is falsified: **the restore bbox already contains every pose**, so
a union-of-extents bbox would change nothing (the current box IS effectively the union — max extent
rows 116–165, cols 21–32, all inside). **No variant built. Fallback byte-untouched
(`7c9c57f7…`). Prod `88eba89…` byte-identical.**

**What is NOT concluded here (deliberately — this arc has answered the wrong question before):** whether
anim_02's cel orange is *faithful to the Apple II source cel* `A4A4`/`A45A` (correct conversion) or a
conversion artifact is a **separate cel-content / recon-vs-eye question** — it needs an oracle
side-by-side of the `A4A4`/`A45A` cel, not a restore-logic change. That is the next gated question if
Jay wants it. The mechanical claim proven here is narrow and firm: **it is not carryover; the bbox
contains every pose; the orange is in anim_02's own cel data.**
