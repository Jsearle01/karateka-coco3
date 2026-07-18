# DECISION RECORD — colour, output targets, sprite sets, and how we verify them

**Status:** working record · **Last updated:** 2026-07-18
**Purpose:** capture what's **ruled**, what's **open**, and — most importantly — **why**, so the
reasoning survives when memory fades. Several of these were argued through and reversed; the
reversals matter as much as the conclusions.

---

## 1. Ruled

### 1.1 Palette — hybrid, applied
- **Hybrid = blue `$2D` (54,179,247) + orange `$26` (245,115,58).** Jay's eye, from in-scene panels.
- **Why not the metric's pick:** C1's orange `$25` is nearer by distance (d=30 vs 60) — **Jay chose
  `$26` anyway. The eye is authority; distance is only a shortlisting tool.**
- Landed as a **named, index-selected table** (`apply_palette_hybrid` / `palette_sets`, set 0 =
  `$00,$26,$2D,$3F`) — **not scattered immediates** — so a second set can drop in later.
- **It's in the fallback driver, not `src/gfx.s`** — because **prod builds from `gfx.s`**, and a
  shared change would move prod on rebuild. Migratable when prod is re-gated (§3.1).
- Tuned against **MAME composite** (⚠ *the MAME invocation has never actually been quoted — "composite"
  is a label, not evidence. Unverified.*)

### 1.2 `$A4A4` is colour-inverted — and it's the parity bug
- The **`$A4A4`-only swap is correct** (Jay, fused 1:1 read). `$A45A` (control) untouched, substrate
  untouched, and Clyde's mask self-verified by reconstructing the real frame **1404/1404 px**.
- **Attribution:** the tracked **column-parity bug** — the converter computes colour from a **fixed
  assumed origin column (~133, odd)**; cels whose real render column has opposite parity come out
  **blue↔orange swapped**. `$A4A4` is at **sub 2**, `$A45A` at **sub 0** — different parity ⇒ right for
  one, wrong for the other. **First confirmed instance.**
- **The fix is a CONVERTER fix, not a hand-edit** — *derive each cel's column origin from its actual
  render position*. **Folded into the converter work; no one-off patch.**
- **Scope is probably wider than `$A4A4`:** if the rule is wrong for sub-2 cels generally, **every
  odd-parity cel is silently wrong** and nobody has compared them to the oracle.

### 1.3 Hue gates are a sanity check, not a correctness gate
- **`$A4A4` PASSED its hue gate while being fully inverted** — because "inverted" *is* a plausible hue.
- The gate catches *"this cel is garbage"*, not *"this cel is wrong."*
- **Every real colour defect in this project was found by comparing against the oracle in scene** —
  composited, in place, vs ground truth.
- ⇒ **A parity re-convert does NOT need a hue-gate re-run.** That would be theatre.

### 1.4 Verify the RULE, not every asset
- A per-asset oracle side-by-side is **intractable** — each cel needs the oracle driven to a pose that
  renders it, and most only appear in unbuilt scenes or the fight.
- **The parity bug is systematic**: one rule. If the corrected rule is right, it's right everywhere.
- **Method:** re-convert with corrected origin → **diff every cel** (machine-generated list of what
  flipped, free) → **spot-check a few flipped cels that are already renderable** — `$A4A4` is the
  **control (it MUST flip)** — plus a couple visible in built scenes → **everything else rides on the
  rule**, verified later when its scene is built and gated anyway.
- **Not skipping verification — deferring it to when it's cheap.**
- **Caveat, accepted:** a broad re-convert can silently change cels nobody looks at for months.
  Mitigation: **record the full diff**, so a later "this looks wrong" has a paper trail.

### 1.5 Catalog before any re-conversion (hard gate)
- **Re-running the converter over hand-edited/authored assets destroys work that cannot be reproduced
  from the oracle.** Unrecoverable.
- **Jay's test:** re-convert each cel fresh from the oracle → byte-diff vs `content/`. **Identical ⇒
  pure output ⇒ re-convertible. ANY diff ⇒ PROTECTED.** Catches *converted-then-edited*, which a git
  history read would miss.
- **Diff shape matters:** **localised** (few px) = an edit; **systematic** (whole set) = **converter
  drift** (parity/`--mirror`/registration all changed during the project). **Opposite treatments** —
  so Clyde reports the shape, **Jay rules the cause**.
- **Over-inclusion is free; a wrong "safe" is not.** Err protected.
- **No-oracle-source ⇒ auto-protected** (the test can't run) — e.g. **Jay's authored wall-top
  post/rail**, now baked as **RMW fill tables in the driver**, not a `content/` cel at all.
- **Protection must be STRUCTURAL** — excluded by path in the converter — **not a note someone forgets
  at 1am.**

---

## 2. The colour/output model (the reasoning, so it isn't re-derived)

### 2.1 How Apple colour actually works — and what the converter did
- **HGR memory is monochrome bits** (+ a high-bit palette select). **Colour is a render-time NTSC
  artifact** — the dot clock is locked to the colour subcarrier, so the decoder reads bit patterns as
  chroma. **The fringe colour IS the pixel; there's no "clean layer" underneath on the Apple.**
- **The converter transcribes** that artifact colour into explicit GIME palette indices. That was a
  **choice** — made to get the authentic oracle look — **not something inherent to conversion.**
- ⇒ **A "clean" set is derivable** (the bits are right there in memory, pre-monitor). **It's a
  converter mode, not authoring.**
- **Both sets are 4-colour.** *(Corrected: an earlier claim that clean ⇒ monochrome was wrong. Shape
  and base colours come from the bits; only the artifact-derived fringe pixels differ.)*

### 2.2 Why artifacting isn't Apple-only — but can't be exploited
- **The CoCo does it too** (PMODE 4 red/blue fringing); both machines derive timing from 14.31818 MHz
  (4× subcarrier). **Not an Apple oddity.**
- **But you can't use it here:** (a) **the GIME already generates real chroma** in composite — the
  palette registers *are* luma+chroma phase (which is why the same value differs RGB vs composite); to
  artifact you'd have to throw away the palette; (b) **phase geometry likely differs** — Apple gets 4
  hues from ~7.16MHz dots **plus a half-dot shift**; the GIME has no known equivalent, so you'd likely
  get *different* hues, not Apple's **(inferred, not verified)**; (c) **RGB has no subcarrier ⇒ no
  artifacting at all** — artifact-dependent sprites would render **flat** on RGB.

### 2.3 The stacking problem (the live concern)
- The converter's fringing is **frozen data**. Composite artifacting is **live, in the display path**,
  and applies to whatever you send — **including already-transcribed pixels**. ⇒ **fringe on fringe.**
- **Worst exactly where our problem is:** alternating 1px orange/blue lines are a maximum-rate chroma
  transition. Wide flat areas barely change; **fine stripes change most** — i.e. the cliff texture and
  the anim_02 lines.
- **You cannot avoid it by choosing colours** — artifacting acts on *transitions*, not on which entry
  you picked.

### 2.4 The counter-argument (don't lose this one)
- **The oracle has the same problem, and worse.** Karateka on a composite Apple II **is** artifacting.
  So the "correct" look in Jay's visual memory **already includes composite bleed**.
- ⇒ **Composite + transcribed colours may land CLOSER to the authentic experience than clean RGB
  does.** Neither target is "wrong":
  - **RGB** = the *data* faithfully shown. Sharp, deterministic, verifiable — arguably *less* like a
    real Apple II.
  - **Composite** = extra bleed, unverifiable without hardware — plausibly nearer the original.
- **That's exactly why the startup selector is the right call.**

### 2.5 The fused-read rule (why 1:1 is the gate)
- **The oracle's stripes are HGR artifact colour that physically blends on a composite display; ours
  are discrete GIME indices that don't.**
- ⇒ **A frame can be per-pixel correct and read wrong, or per-pixel wrong and read right.**
- **The 1:1 (fused) view is the gate; ×8 is supporting detail only.** Per-pixel index matching is
  **misleading** on fine alternating content **in both directions**.
- **⚠ None of these views is a real CoCo3 on composite** — MAME's composite fidelity is unverified.
  1:1 is the closest available proxy, not a guarantee.
- **Naming:** label renders by **purpose** (`fused_1x1` / `countable_x8`), not just zoom factor.

---

## 3. Open — decided later, deliberately

### 3.1 Integration: prod has never moved
- **`karateka.bin` = `88eba89…`, 17978 B — byte-identical for the ENTIRE project** (Stages 0–3, the
  wall-top, the crawl, the palette). **None of the scene-6 work is in the game.** It all lives in
  sandbox drivers.
- **"Prod byte-identical" has been the safety rail — it is also a wall**, and it must eventually be
  **deliberately crossed**. The palette's fallback placement (§1.1) is the first concrete instance of
  the wall biting.
- **⇒ There is an unnamed integration arc ahead.** Put it on the roadmap rather than discover it.

### 3.2 Clean vs fringed — the RGB aesthetic question
> **⚠ SUPERSEDED by §7.4 (2026-07-18).** Jay ruled: **ship BOTH clean and fringed on RGB** (the
> selector picks) — no A/B gate needed. The "which look wins" question below is retired; the converter
> still must *produce* both, but the aesthetic gate is closed.

- **Answerable NOW, without hardware** (RGB is deterministic): **do you want the Apple's artifacts
  preserved as deliberate art, or a clean rendering of the same sprites?**
  - **RGB + fringed** = the oracle's composite appearance frozen — but fringe pixels are real palette
    entries, so they read as **hard-edged colour bands imitating an analogue blur**.
  - **RGB + clean** = 4-colour, no fringing — crisper, more graphic. *(Not monochrome — see §2.1.)*
- **Method:** converter emits both → **two variant builds** → Jay gates by eye. Same by-eye move that
  finally settled the wall-top.

### 3.3 Converter design constraints (settled in principle, unbuilt)
- **FEASIBILITY GATE, unverified:** does the converter **retain which pixels are artifact-derived**? If
  it decodes colour without marking it, **`clean` is a converter change, not a flag.** **Must be
  answered before anything is built.**
- **ONE PASS, TWO OUTPUTS — never two passes.** Convert once **in the fringed coordinate frame**;
  classify each pixel body/fringe; **fringed** = all colours; **clean** = body pixels **at the same
  coordinates**, **transparent** at fringe coordinates.
- **Why:** a second clean pass **recomputes extents** — a fringe pixel at column 1 would leave clean's
  body starting at column 1, **shifting the sprite one column left inside an identically-sized box**:
  same dims, **wrong registration**. This is the converter's tracked *"trims each frame's blanks
  independently"* defect (the one that broke the princess) **on a new axis**. **Remove the
  independence by construction; don't check for it afterwards.**
- **Geometry is derived in FRINGED mode; clean INHERITS it.** **Fringed ⊇ clean** (fringe exists only
  where clean has nothing). **Clean never computes an extent, never trims.** *(⚠ verify ⊇: if fringing
  **replaces** a body pixel's colour rather than **adding** an edge pixel, the geometry holds but the
  "clean = fringed minus edges" model doesn't.)*
- **Invariant:** **`clean[x][y]` transparent ⟺ `fringed[x][y]` fringe-derived**, every pixel; dims +
  origin identical **by construction**; only colour indices differ. **Stronger than a dims check** — it
  catches the column-shift a dims-only assert would sail past.
- **Clean saves NO storage** — same dims/origin, transparent where fringe was. *(Kills the hope that a
  second set is cheap.)*

### 3.3a How swapping the sets actually works (no scene-code changes)
- **NOT byte-identical — same SIZE, different BYTES.** Identical **geometry**; clean has **transparent**
  where fringed has fringe colour. *(If they were byte-identical they'd be the same set.)* **Geometry
  identity is what makes them drop-in interchangeable — that's what the invariant buys.**
- **No include rewiring.** Same **cel names**, same **paths**, same geometry ⇒ **scene code is
  untouched.** Select once, either by:
  - **two trees** — `content/` (fringed) + `content-clean/`, build's include path points at one
    *(keeps both on disk for A/B builds)*; or
  - **one tree**, **regenerated** by re-running the converter in the other mode *(cleaner; a re-convert
    to switch)*.
- **Size-parity has a real consequence:** swapping sets **changes nothing about layout, banking, or the
  memory budget**. The build doesn't shift ⇒ **the only variable is what the pixels look like** — which
  is exactly what makes it a safe A/B.
- **⚠ This all depends on the feasibility gate (§3.3).** If classification turns out unavailable and
  "clean" needs a converter **change** rather than a mode, the sets **may not be geometry-guaranteed** —
  and then it is **not** a drop-in swap.

### 3.3b Build order: FRINGED now, clean deferred (ruled)
- **Build and gate on FRINGED. Do NOT maintain clean in parallel.** Reasons:
  1. **Fringed is the only gated set that exists** — the crawl, the wall-top, every hue gate, every
     framebuffer baseline sits on it. **Clean is hypothetical until §3.3's gate answers.**
  2. **Parallel is a permanent tax for a one-time question** — every scene converts twice, every gate
     twice, every diff two baselines, **forever**, to answer a preference you answer **once**.
  3. **Decisive: clean is a pure function of the converter.** Once the mode exists, generating it is
     **a re-run, not a rebuild.** **Nothing accumulates; nothing falls behind. A parallel set buys
     literally nothing a later re-run doesn't.**
- **Cost of deferring (accepted):** the longer you wait, the more scenes exist to re-gate **if clean
  wins**. Cheaper than it sounds — the difference is **systematic** (fringe → transparent everywhere),
  so it's the same **"verify the rule, not every asset"** logic (§1.4): **if clean reads right on the
  climb, it reads right everywhere.**
- **⚠ What must NOT slip:** the **geometry invariant goes in when the mode is built**, not retrofitted.
  **Deferring the ASSETS is safe; deferring the DESIGN is not.**

### 3.4 Product scope (Jay's framing — recorded, NOT decided)
> **⚠ SUPERSEDED IN PART by §7 (2026-07-18).** Storage is now MEASURED (two sets fit stock 128KB —
> corrected below); the RGB values were selected (§7.1); clean+fringed both ship on RGB (§7.4); the
> delivery mechanism is deferred *and un-pre-measurable* (§7.7). Read §7 for current state. The
> three-both-looks-paths comparison table + the storage-vs-addressability detail live in
> `port-postmortem-vol2.md` III.5 (one home per fact — not duplicated here).

- **RGB is the target. Composite is a convenience** for those without an RGB monitor.
- Possibly ship **both RGB looks** (clean + fringed) via the selector; **composite too if it looks
  decent** on hardware.
- **Ceiling = TWO cel sets, not three** — composite reuses whichever set suits it.
- **Binding constraint: two sets in one 128KB build — MEASURED (2026-07-18).** Cel data **26,641 B/set**;
  code + one set **44,619 B**; two sets **71,260 B — ~60KB slack** under 128KB ⇒ **two sets fit stock
  128KB comfortably.** CROSS doubling (+3,702 B, ~14%) is **already spent** in `content/`. Clean saves
  **zero** storage (transparency = a stored index-0, same `2+H*W`). ⚠ **Storage ≠ addressability:** the
  both-*resident* path still owes a bank-aware blit (an engine change); one set resident owes nothing.
  **512KB struck for this question.** *(Still open, and distinct: whether one set **+ scene-6 combatants**
  fit resident — that residency number is unmeasured until the fight is built.)*
- **⭐ LEADING OPTION — the FLIPPY DISK (Jay).** One look per side. **This is the elegant answer**: it
  sidesteps the 128KB residency question entirely (each side is its own build with **one** set
  resident), needs **no RAM escalation**, needs **no selector for look** (the side already chose), and
  it's period-authentic packaging. **It converts an unmeasured budget risk into a manufacturing
  detail.**
- **Other escape hatches:** two separate disks (same idea, less elegant); or **512KB — a gated
  escalation requiring Jay's explicit ruling, never an ambient default.**

**⚠ DISK CAPACITY AND RAM ARE DIFFERENT LIMITS — don't conflate them** *(this got tangled once
already):*
- **Disk** ≈ **140KB per side** (5.25"). **A 128KB game already needs more than one side** once code +
  assets + loader are counted. **The disk was never what 512KB was about.**
- **RAM (128KB vs 512KB)** = what must be **RESIDENT AT ONCE**. It decides **which machines can run
  it** — an audience decision, not a media one.
- **Jay's point, and it holds:** if you go **512KB**, you're populating ~**4 sides' worth** of data —
  so **multi-disk is implied by that path anyway**, and a flippy is noise on top.
- **Caveat kept straight:** **512KB doesn't oblige you to fill it.** You might want it to hold **one**
  set *plus* scene 6's combatants resident — not to ship *more* assets. **Disk count follows total
  assets shipped; RAM follows residency.** They correlate; they aren't the same number.
- **⇒ The two-looks question NO LONGER FORCES the 512KB decision.** These were tangled and are now
  untangled: **the flippy delivers both looks on stock 128KB.**
- **⇒ And this makes CROSS storage-bytes MORE useful, not less:** the binding constraint is
  **residency** — does **one** set + scene 6 fit in stock 128KB? **That's the number that's still
  never been measured.**

- **Cheapest branch-killer:** the RGB gate (§3.2). If one look is obviously better, **most of this
  collapses** — there's nothing to ship two of.

### 3.5 Composite — deferred on hardware
- **Every composite question is unanswerable today:** is the added artifacting good/bad? does the GIME
  produce Apple-like hues? is MAME's composite even representative?
- **No CoCo3 available.** MAME's composite fidelity is **itself unverified**.
- **Don't compensate for an effect you can't measure** — you'd be guessing at a correction and could
  easily **double** it.
- **⇒ Target RGB (verifiable now); observe composite when hardware exists.** Costs nothing to defer:
  same cel data, and the converter mode makes it a **re-run, not a re-think**.

---

## 4. The 25.3-H pile (why this keeps mattering)

**Nothing has ever run on a stock CoCo3** — one of **two co-equal delivery targets**, untested since
day one. It has now been **decision-relevant four times**:
1. composite artifacting (is the added fringing acceptable?)
2. MAME's composite fidelity (is what we're judging representative?)
3. palette tuning (tuned to MAME's idea of composite)
4. clean-vs-fringed on composite (the whole §3.2/§3.5 fork)

**These decisions cannot close without hardware.** The pile is accumulating. **A cheap smoke test —
the gated climb on a real CoCo3, composite, photographed — would unblock all four.**

---

## 5. Corrections on the record (so they aren't re-argued)

- **"Clean cels ⇒ RGB renders monochrome"** — **WRONG.** Both sets are 4-colour; only fringe pixels
  differ (§2.1).
- **"One sprite set, two palettes"** — **incomplete.** True for RGB-vs-composite *palette* differences;
  **false** for clean-vs-fringed, where the **pixel data itself** diverges ⇒ genuinely two sets (§3.2).
- **"The global swap proves the swap isn't clean" (F-1)** — **VOID.** The spec (mine) was global; it
  flipped **substrate** too, conflated sprite with substrate, and **never tested the hypothesis**. The
  correctly-scoped `$A4A4`-only swap came back **clean and correct** (§1.2).
- **"A changed base row falsifies the swap"** — **wrong framing (mine).** Alternating stripes don't read
  as their nominal colours; **a changed pixel is data, not a verdict** (§2.5).
- **"The registration hypothesis"** for the anim_02 orange — **ruled out by Jay** (moving the butt
  forward would overwrite the black wall). It was the **parity bug** (§1.2).
- **The orange took FIVE attempts:** substrate diagnosis (wrong region) → carryover (falsified) →
  "3–4× cel outlier" (undercut by Clyde's own sprite sheet: raw counts 126 vs 42–92, ~1.4×, orange in
  **every** pose) → global swap (void, my error) → **`$A4A4`-only swap (correct)**. **Jay's eye called
  it early and held.**

---

## 6. Sequencing (as it stands)

1. **[in flight]** Protection catalog · CROSS storage-bytes · fringe-classification feasibility — **all
   report-only.** **Jay rules the protected list.**
2. **Converter work** (one pass, gated on §1.5's line + §3.3's feasibility): **parity fix** (derive
   origin from actual render position) **+ `clean|fringed` mode**.
   - Verification per §1.4: **diff everything, spot-check the flipped renderable ones, `$A4A4` is the
     control.** **No hue-gate re-run.**
3. **Two RGB variant builds** → **Jay's clean-vs-fringed gate** (§3.2). **This may collapse §3.4.**
4. **Composite** — when hardware exists (§3.5, §4).
5. **Also open, unrelated:** the **shadows** (feet/hands — check the **draw path** first;
   `HAL_gfx_blit_sprite_opaque` exists **specifically for black shadows**, and the climb uses the
   **transparent** blit where index-0 keys transparent ⇒ an all-black shadow cel would **vanish** ⇒
   likely **not** an art defect); the **`$AA7D` shape/extent delta**; the **scroll verification plan**
   (awaiting approval — **belongs before the walk build**; the *"no pre-guard midground scroll"*
   conclusion is **retracted** — that trace predated the identification of `$52` and was looking for
   scroll without knowing the observable); then **finish scene 6's fight** (concurrency is a
   **read-the-repo** task — scene 5 is done and ported; plus `$65` decode, guard-HUD-enable, the
   **masked-composite primitive** — deferred, not cancelled, since combatant art won't decompose like
   the wall-top post did — and OQ-5).

---

## 7. Session addendum (2026-07-18) — RGB selection landed + the decisions that postdate §1–§6

*These finalize or supersede open items above. This section is the authoritative
current state; where it conflicts with §1–§6, this section wins.*

### 7.1 RGB palette selected — blue `$19` / orange `$26` (resolves the §3.2/§3.4 "which values")
Jay's fused-read selection study picked, for the **RGB** monitor path:
**blue `$19` = (0,170,255)**, **orange `$26` = (255,85,0)**.
- Selected **against the oracle directly** — the composite anchor was value-verified
  (no drift) then dropped from the final panel, so RGB was tuned to **oracle ground
  truth**, not to a composite approximation of it.
- **Gamut ceiling (honest):** GIME RGB's 4-level channels cannot reach the oracle
  blue (25,144,255) exactly — no G=144, no R=25. `$19` (d36) is the nearest
  achievable, accepted by Jay. RGB is nearest-match, **not exact**.

### 7.2 Two-set values + the palette-per-monitor selector axis
- **Composite set 0:** `$00,$26,$2D,$3F` (blue `$2D`, Monitor=Composite).
- **RGB set 1:** `$00,$26,$19,$3F` (blue `$19`, Monitor=RGB).
- **They differ in exactly ONE entry — index 2 (blue).** Orange `$26`, black `$00`,
  white `$3F` are shared (orange `$26` is mode-robust: acceptable orange on both
  monitors; black/white are mode-identical).
- **The startup selector now carries {monitor → palette table}** on top of
  {clean/fringed → asset set}. Because the tables differ by one entry, the
  monitor-swap is a single-byte change.
- **The selector is a boot-time USER choice, not monitor auto-detect** — the 6809
  cannot read the attached monitor (the GIME emits composite + RGB from the same
  registers simultaneously). Interactive boot menu deferred (separable UX infra).

### 7.3 Composite re-tune RULED OUT (from MAME source, not a study)
The full 64-entry GIME composite palette (`gime.cpp` `get_composite_color`, a fixed
lookup table) was gamut-searched. `$2D` is **already the nearest composite value to
BOTH** the oracle blue (25,144,255) **and** the RGB pick `$19` — next-nearest (`$2C`)
is markedly worse on both. Orange `$26` ≈ `$25` within noise, and `$25` is the
eye-rejected orange. **No closer composite value exists**; the composite↔RGB
cross-mode blue gap (~55) is a **gamut floor**, not a tuning miss. Notable: RGB `$19`
(d36 from oracle) is **closer to the oracle than composite `$2D` (d46)** — for blue,
**RGB is the more faithful mode.** No study needed; determination is source-derived
and reproducible by inspection.

### 7.4 Clean + fringed — ship BOTH on RGB (retires the §3.2 clean-vs-fringed *gate*)
Jay: ship RGB with **both** the clean and fringed sets (selector picks), **no A/B
test needed** — shipping both answers the "which look is wanted" question that §3.2's
gate existed to decide. The converter still must **produce** both (capability
unchanged, one-pass-two-outputs per §3.3); the §3.2 *aesthetic gate* is retired. The
RGB-vs-clean/fringed comparison is no longer a blocker.

### 7.5 GIME artifacting flag — A (emulator model), a no-op here (from source)
The `gime:artifacting` flag is MAME's **MC6847 composite-artifact model**
(`INPUT_PORTS_NAME(mc6847_artifacting)`), applied only under `m_legacy_video`
(VDG-compat mode). Karateka renders in **GIME native mode** ⇒ the artifacting call is
**unreachable** ⇒ the flag is a **structural no-op** for this port, not the RGB gate.
**Fidelity consequence (25.3-H):** MAME does **no** NTSC-artifact simulation for
GIME-native modes — its composite render is the palette applied straight, likely
**cleaner than real composite** (which still fringes through NTSC). Sharpens the
"MAME composite ≠ real silicon" caution; only closes on hardware.

### 7.6 RGB is now the DEFAULT and the standing gate
- **Committed default flipped to RGB** (`PAL_SEL_DEFAULT=1`) — a plain build selects
  set 1 (RGB). Composite reachable via `-DPAL_SEL_DEFAULT=0`.
- **Standing MAME visual gate → RGB** (Monitor=RGB by default; CLAUDE.md).
- Both are **fallback-resident** ⇒ prod `88eba89…` still byte-identical. Composite
  remains a valid gate for composite-specific verification (and the hardware smoke
  test).

### 7.6a Monitor↔palette coupling — why the boot menu is DISTRIBUTION-necessary
The **palette set** (in the binary) and the **monitor mode** (in MAME / on real
hardware) are **independent and must MATCH**. A mismatch renders wrong colour:
- RGB-set build (`$19` blue) on a **composite** monitor ⇒ `$19` decodes to
  **magenta (168,20,213)**, not blue. (Symmetric: composite `$2D` on RGB ⇒ magenta
  (255,0,255).)
- **No MAME CLI flag** sets coco3 monitor type (exhaustively re-verified, v0.281 —
  `-showusage`, `-listxml`, `-rgb`/`-screen_config` → "unknown option"). It is a
  machine **configuration** (`screen_config`), set via the **TAB menu**, a **cfg
  file** (`-cfg_directory` + a preset `coco3.cfg`), or **Lua**. Distribution presets:
  `dist/mame-cfg/{rgb,composite}/coco3.cfg` + `README-monitor-cfg.md`.
- **Consequence — this sharpens §7.6.** With the default now RGB and **no boot
  menu**, a *shipped* binary renders **wrong on a composite monitor** (magenta blue).
  Neither hardcoded default is distribution-correct for *all* users — RGB-default is
  wrong for composite users, composite-default is wrong for RGB users; the flip only
  moved which population is wrong. ⇒ **The interactive boot menu is NOT a deferred
  nicety — it is the distribution-correct fix**: it lets the binary's palette set
  follow the user's monitor choice, so neither population gets magenta. Fine for
  *development* (Clyde controls the monitor); **not** for a shipped binary.

### 7.7 Delivery mechanism — deferred, and now known to be *un-pre-measurable* (updates §3.4)
The flippy / load-on-selection / both-resident choice stays deferred. **New:** the
disk-footprint half is **not measurable ahead of building the later scenes** — the
game streams content in **chunks (per disk load)**, so on-disk bytes past the traced
region can't be segmented (asset vs code vs garbage) without tracing each load. **Only
intro/demo-through-scene-6 is countable now**; the full-game footprint **accrues
per-scene** as each load is traced. This *strengthens* the defer (no early number
shortcuts it) and names the **chunked-load model past scene 6 as an unmapped
deliverable**. **Standing guard:** the single sprite engine stays
**delivery-mechanism-agnostic** (assumes one set resident at a time — the flippy /
load-on-selection assumption and the current reality); do **not** grow a bank-aware
two-set blit path until both-resident is chosen on measured numbers. (Full reasoning +
the load-model / per-load-freeze note: `project-state-open-items-disk-boot-arc.md`
§4.1.)

### 7.8 Record hygiene note
This addendum reconciles a split: §1–§6 + this section are the authoritative colour
reasoning and now live **in-repo** (they previously lived only in project knowledge).
Per the standing invariant — *nothing critical lives only in chat context; it's all on
disk (repo)* — this file is the on-disk home. Keep it here; update it here.

**Ownership (to prevent parallel-edit divergence — which happened twice):** the
**Orchestrator owns the content of this file; Clyde owns the commit.** Clyde does NOT
edit the decision-record body directly — findings surface in Clyde's reports, the
Orchestrator folds them into the authoritative text, and Clyde commits the result.
This matches the role split (Jay authors / Orchestrator drafts / Clyde renders) and
keeps the rich reasoning with the party whose environment can hold it (Clyde's cannot).
Recorded in CLAUDE.md.
