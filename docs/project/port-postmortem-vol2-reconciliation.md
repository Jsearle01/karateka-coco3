# Port Post-Mortem Vol II — Reconciliation (execution record vs the Orchestrator's planning half)

**Status:** COMPLETED. The Orchestrator's Vol II (`docs/project/port-postmortem-vol2.md`, placed by Jay)
was read **after** the execution half was drafted (`port-postmortem-vol2-execution.md`), so this is a true
cross-check. **Result: strong corroboration** — the two independently-built records agree on every major
arc — **with one real mechanism-conflict (R7)** and coverage gaps both ways. Conflicts are surfaced for
Jay (the tiebreak), not resolved here.

## The R1–R10 discrepancy-candidates, resolved against the Orchestrator draft

| # | Claim | Verdict | Evidence / note |
|---|---|---|---|
| R1 | Wall-top "sub 1 → px 185/269" CONFIRMED-that-never-built | **AGREE** | Orchestrator V.4 carries it as a *process lesson* ("verdicted CONFIRMED without ever landing in the build"), not a clean CONFIRMED. Both records treat it as a mis-verdict. |
| R2 | Three posts (not "col-11 spurious") | **AGREE** | Orch II.8 pt 4 + "Jay confirmed the oracle has three posts too." |
| R3 | "$AA25-$AA30 = 12 cels" phantom = $AA23 data | **AGREE** | Orch II.8 pt 2, same `extract_cel`-is-the-discriminator tell. |
| R4 | Substrate diagnosis = wrong region | **AGREE** | Orch II.9 pt 1 (true but wrong region). |
| R5 | Restore-carryover falsified | **AGREE** | Orch II.9 pt 2, same bbox (cols 20-32/rows 112-167) + two-poses-back double-buffer insight. |
| R6 | "3-4× outlier" undercut (126 vs 42-92) | **AGREE** | Orch II.9 pt 3 — **exact numbers match**. |
| R7 | Orange root cause = column-parity converter bug | **AGREE on conclusion; CONFLICT on mechanism** | See below — the load-bearing finding. |
| R8 | "MAME no RGB toggle" corrected (Monitor Type exists) | **AGREE** | Orch II.13 — "the sixth time the eye beat the tool," credits Jay. |
| R9 | `gime:artifacting` classified A / no-op | **COVERAGE GAP (I cover more)** | Orch Appendix D lists it only as "**drafted, queued**" — the Orchestrator draft predates my completed classification (`4be3acb`, A + no-op for palette mode). |
| R10 | Palette in the fallback, not `gfx.s` | **AGREE** | Orch II.10 — "(Clyde's correct deviation)," same prod-rebuild reasoning + index-frame-identical scope proof. |

## R7 — the one real CONFLICT (mechanism detail) — surfaced for Jay
**Both records agree the conclusion:** the orange was a column-parity **converter bug**, fixed by deriving
the origin from the actual render position (not a hand-edit). **They conflict on the mechanism:**

- **Orchestrator (II.9):** "the converter computes a cel's colour from a **fixed assumed origin column
  (~133, odd)**; `$A4A4` sits at **sub 2**, `$A45A` at **sub 0** — different parity, so the fixed-origin
  assumption was right for one and wrong for the other."
- **My execution record (committed code + verification, `007ba28`):** the climb-player recipe used
  **`start_col=0`** (NOT ~133) + a `pick_parity('orange')` heuristic + a hand `FLIP_OVERRIDE`; `$A4A4`
  flipped because **`pick_parity` silently chose the wrong parity for it**, and the fix derives
  `start_col = byte_col*7 + sub` from the **traced render BYTE-column**. Per the trace, `$A4A4`'s oracle
  render is **byte 0x0A, osub=0** and `$A45A` is byte 0x0C, **osub=0** — **both osub=0**, so "sub 2 vs
  sub 0" is not the parity driver (the sub-2 is `$A4A4`'s *CoCo3* placement sub, shifted by the +20
  centering, not the converter's Apple-column parity input).

**Two factual mismatches for Jay's tiebreak:** (a) the fixed origin in the climb recipe was **0, not
~133** (`git show 007ba28~1:harness/tools/stage3_convert_climb.py` — "start_col=0 + pick_parity"; no 133
anywhere in the recipe); (b) the discriminator was the **render byte-column parity + the pick_parity
heuristic's miss**, not "`$A4A4` sub 2 vs `$A45A` sub 0." My evidence is the committed converter + the
scratch verification table (A4A4 render col 70, flips; the 4 overrides reproduce). *(The "~133 odd" also
appeared in the dispatch text, so it may be a shared planning-side reconstruction that never matched the
climb code — possibly a real value in a DIFFERENT converter path, but not this bug.)* **Not resolved
unilaterally — Jay rules.**

## Coverage gaps — where each half covers what the other doesn't (HS-7)

**Orchestrator covers more (not in my execution record):**
- **The colour-architecture depth (III.5):** storage-vs-**addressability** — two sets *fit* 128KB but the
  6809 sees only 64KB, so a resident second set needs a **bank-aware blit** (an engine change touching the
  crawl double-buffer); the **three both-looks paths** (both-resident / load-on-selection / flippy disk);
  the composite-stacking argument. My record has the storage bytes + the clean|fringed feasibility but
  **not** the addressability distinction or the paths.
- **Two standalone docs I do not hold:** `decision-record_colour-output-sprite-sets.md` and
  `methodology_oracle-to-port-sprite-pipeline.md` — **not in my repo** (Orchestrator-side artifacts).
- **The `$52` scroll register `[K]`** (Part IV): `X = $52 ± xadj[i]`, 18-entry table `$ADF7-$AE3E`, never
  observed changing; the "no pre-guard-scroll" retraction. My record has only the *parked scroll plan*, not
  this identification.
- **The "clean ⇒ monochrome was wrong, corrected" note** (III.5) — **not in my record**; I cannot confirm
  or deny I made that claim (honest blank).

**I cover more (execution precision the planning half summarises but doesn't hold):**
- Exact hashes: prod `88eba89…` byte-identical across all 152 commits; fallback `7c9c57f7…`→`1e4b608e…` at
  `25b431f`; hybrid scope-proof pose_2 `DEAD5A64…`.
- The **completed** gime-artifacting classification (Orch has it queued) + the raw `-listxml` XML.
- Framebuffer measurements: parity-fix pose_2 diff = 31 bytes (rows 143-164/cols 22-25); MAME RGB per
  Monitor Type (`$2D` composite (54,179,247) vs RGB (255,0,255)); the swept 64-value palette distances.

## Agreements worth noting as strong corroboration
The two records were built independently and **land on the same five-attempt orange sequence** (substrate
→ carryover → outlier → global-swap-void → `$A4A4`-only-correct → parity attribution), the same
four-wrong-wall-top → eye-wins theme, the same "six times the eye beat the tool" pattern, the same palette
hybrid + fused-read rule, and the same prod-byte-identical-as-a-growing-wall observation (Orch V.5). Where
two independent reconstructions agree this closely, the agreement is real corroboration — and it makes the
**single R7 mechanism-conflict** stand out as the one thing to pin.

## Next step (AC-5, PENDING JAY)
Jay breaks R7 (mechanism: `start_col=0`+pick_parity+render-byte-col — my code — vs ~133 + sub-2-vs-sub-0 —
Orch narrative), reconciles the coverage gaps (pull the `$52` scroll + architecture-arc depth into the
merged doc; fold in my completed gime-artifacting result + hashes), and rules whether the two halves
**merge** or stay as two reconciled halves.
