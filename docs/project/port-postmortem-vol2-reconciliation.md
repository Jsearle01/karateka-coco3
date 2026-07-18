# Port Post-Mortem Vol II — Reconciliation (execution record vs the Orchestrator's planning half)

## ⚠ ACCESS BLOCKER — the direct diff could not be run (HS-7: reported, not faked)
The Orchestrator's Volume II (`/mnt/user-data/outputs/port-postmortem-vol2.md`) is **not accessible from
this execution environment** — that is a sandbox/Linux path; it does not exist on this Windows host, and a
broad search of both working directories + temp found nothing. **I did not read it, so I cannot produce the
row-by-row agree/disagree table against it** (AC-3 as specified). Per HS-1/HS-7 I will **not** transcribe or
guess its contents.

**What I provide instead (the honest substitute):** the execution-side inputs to that table — the specific
claims where my trace/build record is most likely to **corroborate or CONTRADICT** a planning-side
narrative, each with my evidence, framed as a **check** for whoever holds both halves (Jay/Orchestrator) to
complete. These are exactly the high-value rows: this window had one claim verdicted CONFIRMED that never
built, plus **six** superseded/corrected conclusions — a reconciliation must confirm the other half carries
the CORRECTION, not the original.

## The discrepancy-candidates my record flags (check each against the Orchestrator's Vol II)

| # | Claim to check | My execution evidence (the ground truth) | What to verify in the other half |
|---|---|---|---|
| R1 | Wall-top placement "sub 1 → px 185/269" verdicted **CONFIRMED** | The value **never built**; it was verdicted on the CLAIM, not the framebuffer (idiom 11f). It later matched by luck. | Does the planning half still log this as a clean CONFIRMED, or as the near-miss it was? **Conflict if it reads as verified.** |
| R2 | Wall-top "col-11 post spurious" / two posts | **SUPERSEDED `819598c`** — THREE posts (oracle + shipped agree). | Does the other half carry "two posts" or the three-post retraction? |
| R3 | Wall-top premise "$AA25-$AA30 = 12 cels" | **SUPERSEDED `4b27dd8`** — it is `$AA23`'s data rows. | Original premise vs the falsification? |
| R4 | Orange = substrate diagnosis (faithful `$AA7D`) | **SUPERSEDED `8812399`→`14855d8`** — TRUE but wrong region; not Jay's carryover. | Does it record the substrate answer as the resolution, or as answered-the-wrong-question? |
| R5 | Orange = restore-carryover | **FALSIFIED `14855d8`** — all 7 poses inside the restore bbox; zero out-of-body orange. | Carried as a live hypothesis, or falsified? |
| R6 | Orange = "anim_02 cels are a 3-4× outlier" (72 vs 18-39) | **UNDERCUT `16e70b1`** — raw cel data 126 vs 42-92 (~1.4×); orange in every pose. | Does it still cite 72-vs-18-39 as the finding? |
| R7 | Orange ROOT CAUSE | **column-parity converter bug** — `$A4A4` blue↔orange swapped (`5febd5b`→`007ba28`, derived-origin fix). | Does the planning half land on parity, or one of R4-R6? |
| R8 | "MAME coco3 has no RGB toggle" | **CORRECTED `5b6df16`** — `Monitor Type` config exists (Composite/RGB); Jay overruled me and was right. | Does it carry my wrong claim or the correction? **This is the loudest one.** |
| R9 | `gime:artifacting` | Classified **A (composite model), NO-OP for Karateka**; caveat: no MAME source local to quote the `.cpp` locus. | Does the other half over-state it as decision-relevant? |
| R10 | Palette applied to `src/gfx.s` | **NO** — applied to the **fallback** (to keep prod byte-identical on rebuild); reactive deviation `25b431f`. | Does the planning half assume gfx.s? |

## Coverage-gaps my record holds that a planning half likely lacks (HS-7: "one covers what the other doesn't")
- **Exact hashes:** prod `88eba89…` byte-identical across all 152 commits; fallback `7c9c57f7…`→`1e4b608e…`
  at `25b431f`; hybrid scope-proof pose_2 `DEAD5A64…`.
- **Byte counts:** total cel data 26,641 B; CROSS +3,702 B; second-set fit 71,260 ≤ 131,072.
- **Framebuffer measurements:** parity-fix pose_2 diff = 31 bytes, rows 143-164/cols 22-25; orange extent
  computations (all poses inside cols 20-32/rows 112-167); MAME RGB per mode (`$2D` composite (54,179,247)
  vs RGB (255,0,255)).
- **The `-listxml` findings:** `Monitor Type` (screen_config) + `gime:artifacting` raw XML.
These are execution-only precision; if the planning half states them, verify they were sourced, not echoed.

## What is NOT in my record (honest blanks)
- Anything the Orchestrator's chat/verdict record holds that did not leave a commit/doc/framebuffer trace on
  my side — I cannot confirm or deny it. Marked here as unknown, not disputed.
- The reconciliation OUTCOME: **Jay is the tiebreak** on every R-row above; I do not resolve them.

## Next step (AC-5, PENDING JAY)
Whoever has both documents runs R1-R10 against the Orchestrator's Vol II; Jay's ground truth breaks any
conflict; Jay rules whether the two halves **merge** or stay as two reconciled halves (as the original
post-mortem did).
