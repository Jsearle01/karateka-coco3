# Port Post-Mortem — Volume II (Clyde's execution/trace half): 2026-07-06 → 2026-07-18

**What this is.** The execution/trace half of Volume II, continuing `port-postmortem-collection-clyde.md`
(which cuts off at the scene-6 recon). Reconstructed **independently from my own artifacts** — the commit
spine, my Form B reports, the findings docs, the idioms doc, the actual diffs/hashes — **before** reading
the Orchestrator's planning/review draft, so the reconciliation (§9) is corroboration, not transcription.

**Conventions (as the collection):** `[C]` execution/trace vantage · `[K]` Karateka-internals · `[E]`
engineering artifact. Confidence: **CONFIRMED** (trace/build-verified) / **HYP** (inferred) / **SUPERSEDED**
(overturned — kept with what replaced it) / `[thin—verify]`. Ground truth (HS-5): **live game / trace /
Jay's observation = authoritative; disassembly labels past scene 4 = hypothesis.**

**Baselines held by my record:** prod `build/karateka.bin` SHA-1 `88eba89b15cdf17c8d25e082d2d3e1f3cce57d38`
(17978 B) — **byte-identical across the ENTIRE window** (every commit re-verified it; not one touched prod).
Fallback `tests/scripted/scene6_climb_crawl_driver.s`: `7c9c57f7…` for most of the window → **`1e4b608e…`
after the hybrid-palette commit `25b431f`** (the first change that ever touched the shipped fallback).

---

## PART A — The commit spine (07-06 → 07-18), verbatim, mapped to arcs
Source: `git log --oneline --since=2026-07-06 --until=2026-07-19` (152 commits). Arcs oldest→newest:

**A.1 Scene-6 stage build + recon (07-06→07-09)** — Fuji backdrop gates `3712071 ad86c82 e4888fc 6ba9020
a432cff 56edf6b`; idioms `3c24a7d` (§9a opaque-shift black bars / §9b index-0 overload); arrow HUD stage-2
`db8dbf5 8ab7e7e a7040b0 0127e8a`; refactors `7bfb24c 7c03820` (framebuffer-diff-proven, `5f127b1` §11a);
climb recon `d500ad5 48fb14d c95c0de 5dc3788`; apple2e capture key-leak fix `f7ca214 5d22e72 7fe51fa`;
clean climb-beat `3cc877c 2c2c380 b15b76e d641283 626c8e0 a7425e8 9c7a381`.

**A.2 Wall-top arc (07-11→07-16)** — the longest saga, ~30 commits: recon `18cf9b6 9a0b05d ec837e6`;
**premise FALSIFIED `4b27dd8`** ("$AA25-$AA30 is $AA23 data, not 12 cels"); authoring `d092d7e fd2f34f
8b41733 1bc84c1 3c2f65f`; placement corrections (all Jay-gated, per-pixel) `46f5439 92fe539 2670f2e
fe427f9 07ad21e a7b8fb0 e08753f 9ac97b3`; bake `896d831`; behind-Fuji + back-wall `0d3315e 76242de feb0621
20a763e e2084da e8c4b4d 995deb8 888fc27`; **three-posts retraction `819598c`** (RETRACT "col-11 spurious").

**A.3 Churn resolution (07-18)** — `891dc63` commit the load-bearing 07-12 Stage-3 WIP (backdrop refactor
feeds the gated fallback; confirmed by `git stash` → "Undefined symbol fill_walltop/draw_fuji_cels").

**A.4 The orange saga (07-18)** — `8812399` palette study + orange-lines finding · `1259b3b` per-pose
live-sequence capture · **`14855d8` carryover hypothesis FALSIFIED** · **`16e70b1` cel sprite sheet
(falsifies the "3-4× cel-orange" claim)** · `5255838` oracle-vs-port in-scene · `f800f2e` swap preview
(two-band) · `25b431f` hybrid palette applied · `5febd5b` `$A4A4`-only swap preview.

**A.5 Pre-conversion safety + A3E9 + CLAUDE.md (07-18)** — `6826a32` protection catalog + CROSS bytes +
clean|fringed feasibility · `ffcc016` adopt gated A3E9 · `4de2309` catalog A3E9-resolved + CLAUDE.md §2B.

**A.6 MAME Monitor Type + correction (07-18)** — `394a5b8` track diagnostics + mode check (**shipped a WRONG
"no RGB toggle"**) · **`5b6df16` CORRECTION (Monitor Type config exists — Jay was right)** · `e3e70ce`
CLAUDE.md §2A.4 (exhaustive MAME-options search).

**A.7 Column-parity fix (07-18)** — `007ba28` derive origin from render position (replaces
`FLIP_OVERRIDE`).

**A.8 GIME-artifacting recon (07-18)** — `4be3acb` classify `gime:artifacting` = composite model (A), no-op.

---

## PART B — Wall-top arc: execution facts + the recon-vs-eye pattern `[C]`
CONFIRMED (commits + `walltop-render-map.md`, `wall-post-rail-geometry.md`). The wall-top was authored,
placed, and baked entirely by **Jay's per-pixel visual gate**, not by trace — because the trace was wrong
in this region **four times**:
1. **SUPERSEDED** "$AA25-$AA30 = 12 masked cels" → it is `$AA23`'s 12 data rows (`4b27dd8`).
2. **SUPERSEDED** "col-11 post spurious / two posts" → **three** posts (oracle + shipped agree, `819598c`).
3. Combatants / floor-cel misreads (per the idioms doc).
The result: **three posts at CoCo3 px 98/183/268** (pitch 85, first post mirrored), rail to logical edge
px299, black back-wall bytes 25-74 rows 112-116. **Idiom [E]:** past scene 4, a cel-ID trace can be
confidently wrong repeatedly in one region — **Jay's eye wins** (idioms 11f + apple2e "eye-wins").
**`[C]` the "CONFIRMED that never landed":** a placement report claimed "sub 1 → px 185 & 269" and was
verdicted **CONFIRMED on the CLAIM** — the value shipped was never measured (it later happened to be right
by luck). Fixed the class with **idiom 11f**: verdict on the OBSERVED framebuffer + the BUILT source, never
the claim.

---

## PART C — The orange saga: three wrong answers, then the real fix `[C][K]`
CONFIRMED (`orange-lines-finding.md`, `anim02-orange-finding.md`, `anim02-a4a4-swap-notes.md`, commits).
The single most instructive arc of the window — **the orange near the climber's lower body took THREE
wrong explanations before the converter fix:**
1. **SUPERSEDED — substrate diagnosis (`8812399`):** "orange is baked in `$AA7D`, faithful to the oracle" —
   TRUE but **answered the wrong region** (substrate rows 152-168, not Jay's carryover).
2. **SUPERSEDED — restore-carryover (`14855d8`):** falsified — computed every pose's extent vs the restore
   bbox (cols 20-32 / rows 112-167); **all 7 poses fully contained**, empirical zero out-of-body orange.
3. **SUPERSEDED — "anim_02 cels are a 3-4× orange outlier" (`16e70b1`):** the report claimed 72 vs 18-39
   (framebuffer-introduced count); the **raw cel-data sprite sheet** gave **126 vs 42-92 (~1.4×)** — orange
   is in **every** pose's cels. My own falsification test undercut my own prior finding.
4. **The real answer (`5febd5b` → `007ba28`):** it was a **column-parity converter bug**. `$A4A4` (the
   butt cel) was blue↔orange **swapped** — it passed its hue gate while inverted. Report-only swap preview
   (`5febd5b`, Jay ruled the swap correct), then the converter fix (§F) produces it natively.
**`[K]` mechanism:** Karateka's climb double-buffers; `cl_render` draws to the back buffer, so a pose's
"predecessor of record" is **two poses back**, not one — a subtlety that mattered for the carryover analysis.

---

## PART D — Palette architecture `[C][E]`
CONFIRMED (`palette-study.md`, commits `8812399`/`25b431f`/`f800f2e`/`5255838`). Measured MAME-rendered RGB:
oracle blue **(25,144,255)** / orange **(230,111,0)**; port current `$1B`→**(94,44,255) violet** (dist 121)
/ `$26`→(245,115,58). Swept all 64 GIME composite values. Candidates: hybrid `$2D`(54,179,247) d46 + `$26`;
C1 `$2D`+`$25`(221,140,1) d30; cand-3 `$1C`(16,94,233) d55 + `$16`(182,52,2) d76. **Jay ruled HYBRID**
(`$2D`+`$26` — his eye chose `$26` over the metric-nearer `$25`). **`[E]` reactive deviation:** applied it
in the **fallback** (a named `palette_sets` table + `apply_palette_hybrid` after `HAL_gfx_init`), **NOT**
`src/gfx.s` — a shared change would move prod on rebuild. Scope proof: the captured **index frame is
byte-identical pre/post** (pose_2 SHA1 `DEAD5A64…`); a MAME snapshot confirms the build renders `$2D`.

---

## PART E — Pre-conversion safety `[C][K]`
CONFIRMED (`protection-catalog.md`, `asset-storage-bytes.md`, `clean-fringed-feasibility.md`, `6826a32`).
- **Protection catalog** (re-convert + byte-diff vs oracle, determinism-verified): of 188 re-convertible
  cels **184 pure, 4 ALTERED = the Mt-Fuji stack `$A948/$A976/$A9B8/$A9E2`** (localised edge-fill-to-`$AA`,
  authored edit). **92 no-source auto-protected** + the authored wall-top. → CLAUDE.md **§2B** (mandatory
  pre-conversion check, `4de2309`).
- **Storage in BYTES** (first time quantified): total cel data **26,641 B**; CROSS doubling **42 cels →
  +3,702 B**; a **second full cel set FITS** stock 128KB (17,978 + 2×26,641 = 71,260 ≤ 131,072).
- **clean|fringed feasibility:** the converter **computes** a per-pixel category (branch) but **discards**
  it, and index 1/2 conflates edge-fringe with solid-colour body ⇒ `clean` is a **converter change**, not
  a flag. Proposed one-pass/two-output (branch-keyed); **not built** (Jay ruling pending).
- **A3E9** (`ffcc016`): the working-tree parity re-bake adopted as the gated version (HEAD == fresh convert).

---

## PART F — The column-parity fix `[C][K]` — the arc's technical payoff
CONFIRMED (`column-parity-fix-record.md`, `007ba28`). The climb PLAYER poses used `start_col=0` +
`pick_parity('orange')` heuristic + a hand `FLIP_OVERRIDE={A3C5,A4F2,A572,A3E9}` — which silently inverted
`$A4A4`. **Fix:** derive each pose's origin from its **traced Apple render column** (`byte_col*7+sub`,
`parity_flip=False`) — the model the cliff cels already used. **Verified in scratch:** the derived rule
**reproduces all 4 former overrides** (SAME) and **flips exactly `$A4A4`** (the control). Diff over 184:
**one cel changed** (`$A4A4`); framebuffer-diff pose_2 = 31 bytes confined to rows 143-164 / cols 22-25 =
`$A4A4`'s placement. No hue-gate re-run (parity fixes the index, not the look). **`[E]` the general lesson:**
fix a systematic per-cel bug by **deriving the parameter from ground truth (render position), not a hand
override list**; verify the RULE against a known control, not every asset (idiom 11m).

---

## PART G — MAME model discoveries `[C][E]` — including my own error, corrected
CONFIRMED (`5b6df16`, `gime-artifacting-classification.md`, idioms 11l/11n).
- **`[C]` MY ERROR, CORRECTED:** I shipped **"MAME coco3 has no RGB toggle"** (`394a5b8`). **Jay overruled;
  he was right.** `-listxml coco3` shows **`Monitor Type` (screen_config: Composite=0 default / RGB=1)** —
  I had used the invalid `-listconfig` and stopped at a keyword grep. RGB mode renders the digital bitpack
  (`$2D`→(255,0,255) magenta vs composite (54,179,247)). → CLAUDE.md **§2A.4** (exhaustive MAME-options
  search). **Consequence:** the RGB clean-vs-fringed gate is MAME-doable (Monitor Type=RGB), reversing my
  wrong "needs hardware" conclusion.
- **`gime:artifacting`** classified **A (composite artifact-colour model)** — and a **NO-OP for Karateka**
  (palette mode; Off/Standard/Reverse render pixel-identical). Confirmation limit stated: no MAME source
  tree local to quote the `.cpp` locus (classified by config-identity + behaviour).
- **25.3-H unchanged** by all MAME work — an emulator model is never real silicon.

---

## PART H — The one loud cross-cutting theme `[C]`
**Almost every wrong turn in this window traces to trusting an inference over ground truth**, and the
corrections all came from the same discipline: (a) the wall-top trace was wrong 4× → **Jay's eye**;
(b) the orange took 3 wrong analyses → **the raw cel data + the empirical extent computation**;
(c) "no RGB toggle" → **the exhaustive enumeration Jay demanded**; (d) the parity bug → **the traced render
column**. The recurring fix is: **verify against the artifact under test (framebuffer / cel bytes / listxml
/ render position), not a heuristic, a claim, or a plausible name.** Every CLAUDE.md rule added this window
(§2A.4 exhaustive search, §2B protection catalog) encodes one of these misses.

---

## PART I — Open gates / carried forward (HYP)
- **Jay rulings pending:** the `clean|fringed` go/no-go; the hybrid-palette global re-look (it re-colours
  every gated scene); the `$A4A4` post-fix live gate.
- **Parked:** shadows (feet/hands — untested `_opaque` **draw-path** hypothesis, likely not an art defect);
  the `$AA7D` shape/extent delta (port stripes vs oracle black, rows 157-165); the full-game cel-byte DISK
  estimate (disk ≠ RAM residency — unmeasured, possibly binding); the scroll verification plan (before the
  walk build); then scene-6's fight (needs the masked-composite primitive, `$65` decode, guard-HUD-enable).
- **25.3-H:** never run on a stock CoCo3 — HYP throughout.
