# Orange-lines diagnosis — climb crawl (2026-07-18) — REPORT ONLY, nothing fixed

**Symptom (Jay):** orange lines appear during ~one frame of the climb crawl; expected blue/black only.
**Method:** the decisive test — render the SUBSTRATE ALONE (no player, no animation), then ask the
oracle. Clean recipe throughout.

## HS-C1 — substrate-alone render: ORANGE IS BAKED IN THE SUBSTRATE (hypothesis 2's premise)
Built a temp driver that draws the full substrate then **halts before `cl_init`** (no player, no
crawl) and dumped the framebuffer. **Result: orange (index 1) IS present** at cols 20–24 (px 80–99),
**EVEN rows 152–168** (blue index 2 on odd rows) — it is baked into **`$AA7D`'s base cel**, NOT a
clean-restore carryover. So **hypothesis 1 (restore carryover) is OUT**; the orange is in `cl_clean`
and is faithfully restored every step. (`build/logs/fb_sub.bin`, 85 orange px in the region.)

## HS-C3 — ask the oracle: it ALSO shows orange there, SAME PARITY ⇒ substrate is FAITHFUL
Sampled the clean oracle capture (apple2e, `scene6_climb_anim_06`, native 280) at the matching region
(Apple px 60–79, rows 151–167):
- **Oracle has orange too** — 73/300 px orange (230,111,0) + blue (25,144,255) + black — a striped
  orange/blue texture.
- **Parity MATCHES the port:** oracle orange on **even** rows (152/154/156/166), blue on **odd**
  (151/153/155/167) — identical to the port's even-orange/odd-blue. **So this is NOT the column-parity
  converter bug** (which would swap the parity). The `$AA7D` orange/blue striping is **correct**.

## HS-C2 — the exposing "frame" is the SETTLED/HELD pose
The player's clean-restore bbox is rows 112–167 (`CL_BY0=112`, `CL_BH=56`), which **includes** the
orange region. In the crawl/low poses the legs cover cols 20–24 / rows 152–166; in the **settled
`$8ACB` pose (y124)** the player sits high and does **not** cover that region, so the substrate orange
shows through (fb at fn520 = 86 orange px, same as substrate). "One frame" ≈ this held/high pose.

## VERDICT (report only — do NOT fix)
**Neither clean hypothesis is a defect:** the orange is **baked in the substrate** (not a restore bug)
**and faithful to the oracle** (same colors, same parity — not the parity bug). **The orange belongs
there** — it is the `$AA7D` cliff-base texture, and the oracle shows it too when the player is high.
Jay's "should be blue/black only" does not match the oracle, which is orange/blue striped here.

**One real discrepancy to flag (needs a fuller side-by-side before concluding):** in the sampled
column band the **oracle goes BLACK at rows 157–165** while the **port continues the orange/blue
stripes** through those rows — i.e. the port's `$AA7D` may be **over-tall / over-filled in its
lower-middle** (stripes where the oracle has a black band), a *shape/extent* question, NOT a color
(parity) question. This is one column band; a wall-top-region side-by-side across the full `$AA7D`
width is needed to confirm the exact shape delta before any change.

## HS-C5 — linked note (record, do NOT act)
The oracle does a **per-step full-tableau redraw**; the port does a **bbox clean-restore of the actor
only**. That divergence is hypothesis-1 territory — but hypothesis 1 is ruled out here (orange is
baked in the substrate, not carried over). Noted for completeness; no action.

**The fix (if any) is its own gated dispatch** — and it is a `$AA7D` shape/extent re-examination, NOT
a re-convert-for-parity (parity is correct) and NOT a restore-logic change. The wall-top recon was
confidently wrong four times; this diagnosis stops at the evidence.
