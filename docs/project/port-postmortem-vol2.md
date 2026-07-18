# Karateka on the CoCo3 — Post-Mortem, Volume II (Scene 6: build, colour, and the sprite-set architecture)

*Merged & reconciled edition (2026-07-18). This volume was assembled from two
independently-built halves — the Orchestrator's planning/review record and Clyde's
execution/trace record — cross-checked (R1–R10) and reconciled against Jay's ground truth;
see Appendix F. Where they conflicted (R7, the parity mechanism), the code-citing record won.
Execution-record precision (hashes, framebuffer measurements, the `$52` scroll) is folded in
at Appendix E.*

*A continuation of* Karateka on the Tandy CoCo3 — A Port Post-Mortem. *Volume I closed
at the scene-6 recon (2026-07-06). This volume covers **2026-07-06 → 2026-07-18**: the
scene-6 climb tableau built from recon to a Jay-gated static image, the colour-defect
saga that took five attempts and confirmed a tracked converter bug, the palette work,
and an extended architecture arc that mapped the whole RGB-vs-composite / clean-vs-fringed
decision space. It is written to the same standard: `[K]` marks recovered facts about how
*Karateka* works; ground-truth claims are separated from hypotheses; open questions are
called out rather than smoothed.*

*The three roles are unchanged — **Jay** (owner, visual authority, gates every decision),
**Orchestrator** (plans before, reviews after, never codes), **Clyde** (executes in-repo,
reports). The invariant that governs this whole volume is the one Volume I earned: **past
scene 4 the disassembly's labels are unreliable, so the running game is authority and the
`.s` is a hypothesis — and above the trace, Jay's eye overrides.** This volume is largely
the story of that invariant being right over and over.*

---

# PART II (cont.) — The narrative history

## II.8 The wall-top — four wrong identifications and a strategy change

Scene 6's climb needed a wall-top: the posts and rail the player crawls beneath. The
recon set out to identify which oracle cels drew it, and got it **wrong four times in one
region** — the cleanest demonstration in the project of why the past-scene-4 rule exists.

1. *"`$AA23`/`$AA31` are off-screen combatants; the runner is `$AA27–$AA30`."* Wrong.
2. *"`$AA25–$AA30` is a 12-cel runner."* **A phantom.** Those were the **12 data rows of a
   single cel (`$AA23`)** misread as separate cels. The tell that killed it: `extract_cel`
   on the suspected address returns garbage — because it *is* garbage, it's the interior of
   the cel above. This one caught a build that would have **deleted the actual wall-top**.
3. *"`$96`/`$99` are the wall-top."* They were floor cels.
4. *"There are only two posts; the port's third (column-11) post is spurious — drop it."*
   Wrong: **the oracle has three posts.** The port had it right; the recon nearly deleted a
   correct element.

Each error had a competent-looking trace behind it. The decisive move was Jay's: **stop
reverse-engineering the wall-top and hand-author it, placed by eye against the oracle.**
This is a strategy the project now has a name for — **static-cosmetic elements can be
authored and gated visually; only dynamic/behavioural elements must be mechanism-faithful.**

Jay authored an 11×7 post grid with the rail as a code-enforced single source (rail =
post column 6, so it can't drift from the posts). The decomposition removed a piece of
anticipated work: the post body has no transparency, so it draws as an **opaque block +
direct row-fills** — no per-pixel masked-composite blit needed *here* (that primitive is
**deferred, not cancelled**; the combatants will still need it). Placement iterated by eye
to three posts at px 98/183/268, leftmost mirrored, rail to px 299, drawn *behind* the
Fuji. Jay gated it: *"the way it looks now is good."* Baked into the fallback driver.

Then — the correction that matters for the record — Jay confirmed **the oracle has three
posts too.** So the shipped build isn't a by-eye *divergence* from the oracle; **the recon
was simply wrong and the build matches the oracle.** The recon docs were corrected with
retraction banners (not silent edits — the retraction is the artifact), the four-error
table recorded, and the wall-top trace flagged unreliable-in-region. A one-line hypothesis
was preserved but explicitly **not investigated**: the oracle's separate **mirror blit
`$190C`** would explain why a trace scoped to the normal path never saw the third
(mirrored) post.

**Transferable lesson:** when a trace and the operator's eye disagree past scene 4, the eye
wins *and the trace gets flagged* — you do not "correct" a gated render toward the trace.
And a cel's data rows can masquerade as separate cels; `extract_cel` is the discriminator.

## II.9 The orange lines — five attempts to diagnose one artifact

A single frame of the climb showed stray orange lines near the player's lower body. It took
**five attempts** to diagnose, and the sequence is a catalogue of diagnostic failure modes:

1. **Substrate diagnosis** — found orange in the substrate at rows 152–168, faithful to the
   oracle. True, but the **wrong region** — not the orange Jay meant.
2. **Restore-carryover** — hypothesised the orange was leftover pixels from a previous pose
   surviving a too-small restore box. **Falsified**: every pose's drawn extent was inside
   the restore bbox (cols 20–32 / rows 112–167); empirical zero carryover across all seven
   poses. *(This required the double-buffer insight: a pose's carryover source is **two poses
   back**, not one, because `cl_render` alternates buffers.)*
3. **"anim_02 is a 3–4× orange outlier"** — undercut by Clyde's own sprite sheet: raw
   index-1 counts were **126 for anim_02 vs 42–92 for the others** (~1.4×, not 3–4×), and
   orange was in *every* pose's cels. The earlier ratio was a framebuffer-basis artifact.
4. **Global colour swap** — a blue↔orange swap applied to the whole frame. **Void**: the
   spec (Orchestrator's) was global, so it flipped the *substrate* too, conflated sprite
   with substrate, and never tested the actual hypothesis.
5. **`$A4A4`-only swap** — scoped to the single accused cel. **Correct** (Jay, fused 1:1
   read). `$A45A` (the pose's other cel) as an untouched control still matched; substrate
   untouched.

The attribution is a **tracked converter bug, now first-confirmed** — and the precise
mechanism was corrected by the execution/trace record during post-mortem reconciliation
(R7; see Appendix F). The climb converter recipe (`stage3_convert_climb.py`, per
`git show 007ba28~1`) used **`start_col=0`** plus a **`pick_parity('orange')` heuristic** and
a hand-maintained `FLIP_OVERRIDE` list — *not* a fixed ~133 origin. `$A4A4` came out inverted
because **`pick_parity` silently chose the wrong parity for it**. The fix derives
`start_col = byte_col*7 + sub` from the **traced render byte-column** — so parity is correct
per-cel, automatically, and the `FLIP_OVERRIDE` list becomes derivations rather than
exceptions. *(An earlier planning-side draft mis-described this as a "fixed ~133 origin" with
"`$A4A4` sub 2 vs `$A45A` sub 0" as the discriminator; that was wrong — both cels trace to
**osub=0**, and the "sub 2" was `$A4A4`'s CoCo3 placement sub after the +20 centering, not the
converter's Apple-column parity input. The record that quotes the converter code is
authoritative over the record that reconstructed from placement fields.)* The fix is a
**converter change** (derive origin from render position), not a hand-edit — validated in
miniature the same session by the `$A3E9` adoption, a one-line `FLIP_OVERRIDE += 0xA3E9`
matching three prior white-dominant cels (`A3C5`/`A4F2`/`A572`).

**Transferable lessons, several:** *(a)* the substrate-alone render is the decisive test for
"carryover vs baked-in" — but only if aimed at the region the operator actually means; *(b)*
a colour/swap test must be **scoped to the artefact**, never the whole frame, or it conflates
sources and voids itself; *(c)* under double-buffering the carryover predecessor is two poses
back; *(d)* **report-only means report-only** — three of the five attempts went wrong partly
by concluding instead of stopping.

## II.10 The palette — "too vibrant," and the fused-read rule

Jay's eye caught that the port's colours were too vibrant against the oracle. This is
*expected* and it has a measurable cause: the oracle's colours are **Apple II HGR artifact
colours**, which are inherently unsaturated (HGR "blue" is a light cyan; "orange" is a
salmon-coral). The port had picked saturated GIME entries — the port blue `$1B` renders
**violet** (94,44,255) against the oracle's sampled (25,144,255).

Sampling the oracle's *actually-rendered* pixels and finding nearest GIME entries produced
candidates; Jay chose a **hybrid** — C1's blue `$2D` (54,179,247) with the *current* orange
`$26` (245,115,58) — picking `$26` over the metric-nearer `$25` (d=60 vs d=30). **The eye is
authority; distance is a shortlisting tool, not a decision.**

Two techniques crystallised here and are now standing rules:

- **The fused read (1:1) is the colour gate; ×8 is countable detail only.** HGR artifact
  colour physically blends on a composite display; discrete GIME indices don't. So a frame
  can be **per-pixel correct and read wrong, or per-pixel wrong and read right** on striped
  content. Judging alternating 1px lines at ×8 is misleading in both directions.
- **Hue gates are a sanity check, not a correctness gate.** `$A4A4` **passed its hue gate
  while fully colour-inverted** — because "inverted" is a plausible hue. Every real colour
  defect in the project was found by comparing against the oracle *in scene*, never by a
  metric or a gate.

The hybrid was applied globally — as a **named, index-selected table**, and (Clyde's correct
deviation) placed in the fallback driver rather than `src/gfx.s`, because prod builds from
`gfx.s` and a shared change would move prod on rebuild. The scope proof was the right one:
the **index frame is byte-identical pre/post** (a palette change is a pure index→RGB remap;
no index may move), while the RGB framebuffer diff — being global — proves nothing.

## II.11 The colour-architecture arc — mapping a decision space without a machine

The palette work opened a much larger question that occupied a long stretch of the session
and produced a standalone **decision record**: *what does the port's colour output actually
target, and does it need more than one set of sprites?* No code came out of it — it was
architecture — but it mapped the space so the eventual decisions can be made cheaply. The
substance is in Part III.2; the narrative point is that **the entire arc was conducted
against an emulator, with a co-equal delivery target (real CoCo3 hardware) that has never
once been run** — a fact that turned out to be decision-relevant five separate times.

## II.12 Pre-conversion safety, and the first hard number

Before any bulk re-conversion (needed for the parity fix), three prerequisites were run,
all report-only:

- **A protection catalog** built the right way — not from git history but **behaviourally**:
  re-convert each cel fresh from the oracle, byte-diff against the committed asset. Identical
  ⇒ pure converter output ⇒ safe. Any diff ⇒ protected. This catches the dangerous
  *converted-then-edited* class that history would miss. Result: **184/188 pure; 4 altered**
  (the Mt-Fuji backdrop — a themed authored edit, protected); **92 no-source auto-protected**;
  plus the authored wall-top. **Determinism was verified first** (a fresh convert of an
  untouched asset reproduces its bytes), without which the diff test would be meaningless.
- **Storage in bytes** — the CROSS figure that had been "decision-relevant four times and
  never existed" finally got measured: **26,641 B per set; code + one set = 44,619 B; two
  sets = 71,260 B, ~60KB of slack under 128KB.** Two full cel sets fit stock 128KB
  comfortably. And **clean sprites save zero storage** (transparency is a stored index-0).
- **A feasibility gate** for a clean/fringed converter mode came back on the safe-but-costlier
  side: the converter **computes** body-vs-fringe classification but **discards it at pack
  time**, and the same colour index is produced by both edge fringe and solid coloured bodies
  (Akuma's robe). So a "clean" set **cannot be an output filter** — it's a **bounded converter
  change**, keyed on the branch, not the index.

## II.13 "MAME has no RGB toggle" — the sixth time the eye beat the tool

A small dispatch to pin which MAME monitor mode all the gating had used produced a **wrong
conclusion**: Clyde reported the `coco3` driver had no composite/RGB switch. Jay was *"nearly
positive"* it existed and pushed back. An exhaustive `-listxml` enumeration found it: the
**Monitor Type** ioport (`screen_config`, mask 1, **Composite=0 default / RGB=1**), settable
from Lua. All gating to date was **Composite**; **RGB is available in MAME** — which means the
eventual RGB clean-vs-fringed comparison needs no hardware.

Root cause: an invalid `-listconfig` command plus a shallow keyword grep instead of full
enumeration. The structural fix is now codified — **CLAUDE.md §2A.4: exhaustive MAME-options
search before concluding a feature is absent.** This was the sixth time in the volume that
Jay's memory or eye overruled an analysis and was right (wall-top ×4 collapses to one theme,
plus the orange, plus this) — the pattern is not incidental; it is *why the role separation
exists.*

---

# PART III (cont.) — Deep dives

## III.5 The colour/output model and the sprite-set architecture `[K]` `[port]`

This is the arc's intellectual core, captured in full in `decision-record_colour-output-
sprite-sets.md`. The reasoning, condensed:

**How Apple colour actually works `[K]`.** HGR memory is **monochrome bits** plus a high-bit
palette-select; **colour is a render-time NTSC artifact** — the dot clock is locked to the
colour subcarrier, so an NTSC decoder reads bit patterns as chroma. **On the Apple the fringe
colour *is* the pixel; there is no clean layer underneath.** The converter *transcribes* that
artifact colour into explicit GIME palette indices — which was a **choice** (to get the
oracle look), not something inherent to conversion.

**Consequence:** a "clean" sprite set (no transcribed fringing) is **derivable from the same
source bits** — it's a converter mode, not authoring. Both sets are 4-colour; only the
artifact-derived fringe pixels differ. *(An early claim that clean ⇒ monochrome was wrong and
is corrected on the record.)*

**Why artifacting isn't Apple-only but can't be exploited here.** The CoCo does it too (PMODE
4 fringing; both machines derive timing from 14.31818 MHz). But: the GIME already generates
real chroma in composite (the palette registers *are* luma+chroma phase — which is why the
same value differs RGB vs composite); the phase geometry likely differs from the Apple's
(half-dot shift, dot clock), so you'd get *different* hues, not Apple's *(inferred)*; and RGB
has no subcarrier, so **no artifacting at all** on RGB.

**The stacking concern, and its counter.** Composite output would apply *live* artifacting on
top of *already-transcribed* colours — fringe on fringe, worst on the fine alternating lines
that are exactly the problem areas. **But** the oracle on a composite Apple II already
includes composite bleed — so composite + transcribed may land *closer* to the authentic
experience than clean RGB does. Neither target is "wrong," which is precisely why a **startup
RGB/composite selector** is the right design.

**The clean/fringed rule (Jay ruled).** For a clean set: **strip edge fringe** (the boundary
artifact) but **keep body fringe** (the colour-cell fill that makes interiors read *solid*
instead of striped — remove it and Akuma's robe becomes stripes). Because the converter can
distinguish these by *branch*, clean is a **bounded, buildable rule**, not a per-asset
judgment — provisional, to be verified at first conversion.

**The converter design constraint.** Clean and fringed must be **one pass, two outputs** —
never two passes. A second clean pass would recompute extents; a fringe pixel at column 1
would leave the clean body starting at column 1, **shifting the sprite one column left inside
an identically-sized box**: same dims, wrong registration. This is the tracked
*"trims-each-frame-independently"* defect (the one that broke the princess's registration) on
a new axis. Geometry is derived in **fringed** mode; **clean inherits it** (fringed ⊇ clean).
Invariant: `clean[x][y]` transparent ⟺ `fringed[x][y]` fringe-derived; dims/origin identical
by construction.

**Storage vs addressability — a distinction that reads as "solved" but isn't.** The
measurement says two sets *fit* 128KB. It does **not** say the running code can *reach* a
second set: the 6809 sees only 64KB, and a second resident set lives in a GIME-mapped bank,
so the blit path would have to become **bank-aware** — an engine change that interacts with
the crawl's double-buffer. Storage is solved; addressability is a separate, unmeasured cost
that comes due only on the both-sets-in-one-build path.

**The three both-looks paths** (all fit 128KB): *both-resident* (needs the bank-aware blit
engine change, one disk); *load-on-selection* (one set resident, needs a new runtime loader,
one disk); *flippy disk* (one set per side, owes nothing — no banking, no loader, no
selector-for-look). **Disk capacity is a separate, unmeasured, possibly-binding limit** — the
26,641 B measured is *demo content only*; the full game (princess, palace, guards, eagle,
akuma, ending) is most of the unconverted cel bank. **Correction (2026-07-18): the full-game
total is NOT a cheap up-front de-risk.** The game streams content in **chunks (per disk load)**,
so on-disk bytes past scene 6 cannot be segmented (asset vs code vs garbage) without tracing each
load — the same present-but-unidentified wall the oracle hits past scene 4, on the raw disk. Only
**demo-through-scene-6 is countable now** (those loads are traced); the full-game footprint
**accrues per-scene** as each load is traced during its port, never as a standalone estimate. (Full
correction: `project-state-open-items-disk-boot-arc.md` §4.1.)

**The through-line:** every composite question is unanswerable without a CoCo3, and MAME's
composite fidelity is itself unverified — so the pragmatic path is **target RGB (verifiable
now), observe composite when hardware exists**, and don't compensate for an effect you can't
measure.

## III.6 The oracle-to-port sprite pipeline `[port]`

The mechanical pipeline — identification, registration, dims, animation — is now captured as
a standalone methodology (`methodology_oracle-to-port-sprite-pipeline.md`). Its load-bearing
points:

- **Identification:** tap the blit trampolines (`$1903/06/09/0C`, masked `$1BF4`) on a
  clean-recipe run; **`$190C` is the mirror path** a normal tap misses; **phantom cels** are
  killed with `extract_cel`; the **pose table** is the source of truth for what composes a
  frame. Clean recipe (`-video none` / `-keyboardprovider none`) is mandatory or the capture
  boots the actual game (the "key-leak contamination").
- **Registration:** each cel carries **byte-col / sub (0–3) / row**; the mapping
  `CoCo3_px = Apple_px + 20` is **closed and correct** (Jay-confirmed). **Report the built
  value, not the intended** — quote the source line *and* the observed framebuffer position.
- **Dims & the multi-frame hazard:** the converter's independent blank-trimming breaks shared
  registration across an actor's frames (the princess needed per-frame X-offset tables; the
  guard is next). Same defect underlies the clean/fringed one-pass rule.
- **Animation:** honour the pose table's dwell/sequence; **verify on the live engine** (a
  per-pose render can't reproduce transition artifacts); the double-buffer predecessor is
  **two poses back**; the restore bbox must be the **union of all pose extents**; bulk copies
  on the per-frame path must be **sliced across frames** (one VBL ≈ 16.7ms at ~0.89MHz).

---

# PART IV (cont.) — How Karateka works `[K]`

Additions recovered or confirmed this volume:

- **The wall-top** is three posts (the oracle draws three), the leftmost **mirror-blitted**
  (`$190C`) — which is why a normal-path trace under-counts it. Rail geometry and post
  structure were reconstructed by eye after the trace proved unreliable in the region.
- **The climb crawl** is a 7-pose (+settle) sequence; each pose is `(dwell, N parts,
  {cel, byte-col, sub, row}×N)`. anim_02 composes `$A4A4` (lower/back, drawn first) + `$A45A`
  (upper, drawn over), overlapping across the torso.
- **The double-buffer** alternates render pages per pose, so a frame renders into the buffer
  last written **two poses earlier** — a fact with direct consequences for reasoning about
  visual carryover.
- **Colour is a render-time artifact**, not stored data (Part III.5) — the single most
  important `[K]` fact for anyone porting the visuals.

*Open `[K]` items carried forward:* the attract **scroll mechanic** (`$52` is the scroll
register — `X = $52 ± xadj[i]`, 18-entry table `$ADF7–$AE3E` — but it has **never been
observed changing**; the "no pre-guard midground scroll" conclusion is **retracted** because
that trace predated `$52`'s identification); the `$AA7D` base cel's shape/extent (port stripes
vs oracle black, rows 157–165) — possibly a recon-vs-eye case where the port is right; the
missing feet/hand **shadows** (likely a **draw-path** omission — `HAL_gfx_blit_sprite_opaque`
exists for exactly this — not an art defect).

---

# PART V (cont.) — Lessons for a port-attempter

Additions from this volume, in the same spirit as Volume I's:

## V.3 Diagnostic discipline (colour and motion)

- **Aim the decisive test at the region the operator actually means.** Three of the five
  orange attempts failed by answering an adjacent question precisely.
- **Scope a colour/swap test to the artefact, never the whole frame.** A global re-colour
  conflates sprite and substrate and voids the result. Use a known **control** (an untouched
  neighbour that must *not* change; an accused element that *must*).
- **Motion artifacts need the live sequence.** Per-item renders on a clean substrate cannot
  reproduce carryover/restore artifacts and will falsely exonerate.
- **The fused (1:1) read is the colour gate on striped content**; per-pixel matching misleads
  in both directions because artifact colour blends and palette indices don't.
- **Hue/metric gates are sanity checks, not correctness gates.** Correctness is comparison to
  the oracle *in scene*.
- **Verify the rule, not every asset.** For systematic bugs (parity, trimming): re-convert →
  diff → spot-check the flipped *renderable* cels with a control → the rest rides on the rule,
  verified when its scene is gated. A per-asset oracle side-by-side is intractable.

## V.4 Process discipline

- **Report the built value, not the intended** — quote the source line and the observed
  framebuffer position. (A "sub 1" placement was once verdicted CONFIRMED without ever landing
  in the build; the fix is to make placement produce *evidence*, the way an art-hash does.)
- **A "don't commit until X" hold needs an explicit release trigger and scope** — or
  load-bearing work strands in the working tree and every "byte-identical" claim afterward is
  quietly ambiguous. (A backdrop refactor sat uncommitted for five days; the gated build was
  not reproducible from HEAD until it was found.)
- **Correct with retraction banners, not silent edits** — the retraction *is* the artifact; it
  records that a trace is unreliable in a region. Silent edits destroy that evidence.
- **Exhaustive tool enumeration before concluding a feature is absent** — the "no RGB toggle"
  error, now codified as a rule.
- **When the operator's eye disagrees with the analysis, the analysis is the thing on trial.**
  Six times this volume, the eye was right.

## V.5 The wall you build on purpose

**Prod has been byte-identical for the entire project** — every scene-6 advance lives in
sandbox drivers, and "prod byte-identical" has been both the safety rail and, increasingly, a
**wall**. The palette landing in the fallback rather than `gfx.s` (to preserve prod) is the
first time the wall visibly bit. There is an **integration arc** ahead that has to be crossed
deliberately, and a port-attempter should plan for it rather than discover it: a safety
invariant that is never released becomes a merge cliff.

---

# APPENDICES (cont.)

## Appendix D — State at 2026-07-18

- **Prod:** `karateka.bin` `88eba89…`, 17978 B — byte-identical throughout. Fallback driver
  `1e4b608e…` (hybrid palette landed).
- **Applied:** hybrid palette (`$2D`+`$26`, Composite-tuned) as a named indexed table in the
  fallback.
- **Confirmed:** the column-parity bug (`$A4A4` inverted; `$A3E9` adopted). Fix = derive origin
  from render position — **in flight** as the parity-fix dispatch.
- **Measured:** two cel sets fit stock 128KB (~60KB slack); clean saves zero storage.
- **Ratified:** protection catalog (184 re-convertible; 4 Fuji + 92 no-source + wall-top
  protected).
- **Pinned:** MAME default = Composite; **RGB available** (Monitor Type ioport).
- **Awaiting Jay:** the scroll verification plan (before the walk build); clean|fringed
  go/no-go (not urgent — near-term converter work is parity-fix-only).
- **Completed** (per the execution record, `4be3acb`): the GIME-artifacting-flag investigation —
  **classified A (emulator composite-render model), no-op for palette mode.** The non-disruptive
  outcome: not a real-GIME hardware behaviour, so no architectural escalation; 25.3-H unchanged.
- **Never run:** anything on a stock CoCo3. 25.3-H is now decision-relevant 5+ times and is the
  gate on the entire composite pile.

## Appendix E — Execution-record precision (folded in from the reconciliation)

The planning/review half summarises; the execution/trace half holds the exact figures. Merged here:

- **Hashes:** prod `88eba89…` byte-identical across **all 152 commits** in the window; fallback
  `7c9c57f7…` → `1e4b608e…` at `25b431f` (hybrid palette); hybrid scope-proof pose_2 index frame
  `DEAD5A64…`.
- **Framebuffer measurements:** parity-fix pose_2 diff = **31 bytes** (rows 143–164 / cols 22–25);
  MAME per Monitor Type — `$2D` composite (54,179,247) vs RGB (255,0,255); the swept 64-value palette
  distances (blue `$1B` d=121 → `$2D` d=46; orange `$26` d=60 / `$25` d=30 / `$16` d=76).
- **The `$52` scroll register `[K]`** (recovered): `X = $52 ± xadj[i]`, 18-entry table `$ADF7–$AE3E`;
  **never observed changing** (climb pins it at `$30`). The "no pre-guard midground scroll" conclusion
  is **retracted** — that trace predated `$52`'s identification. This is the open scroll thread the
  verification plan targets, and it belongs before the walk build.
- **The gime-artifacting classification** (`4be3acb`): **A (emulator composite-render model), no-op**
  — with the raw `-listxml` Monitor Type / config evidence in the execution record.

## Appendix F — The two-record reconciliation (how this volume was verified)

This volume is the **merge** of two independently-built halves — the Orchestrator's planning/review
record and Clyde's execution/trace record — reconciled against Jay's ground truth, exactly as the
original post-mortem was assembled. The execution half was drafted **before** reading the planning
half (independence preserved), then diffed against it. Ten discrepancy-candidates (R1–R10) were
resolved:

- **R1–R6, R8, R10 — AGREE.** The CONFIRMED-that-never-built wall-top placement (R1, both records
  treat it as a mis-verdict), three posts (R2), the `$AA23`-data phantom (R3), the three wrong orange
  answers (R4–R6, with the exact 126-vs-42–92 counts matching), the "no RGB toggle" correction (R8),
  the palette-in-fallback deviation (R10). Two independent reconstructions landing this close is real
  corroboration.
- **R7 — CONFLICT, resolved for the execution record (Jay's tiebreak).** Both halves agreed the
  *conclusion* (column-parity converter bug, fixed by deriving origin from render position) but
  conflicted on the *mechanism*. The planning draft's "fixed ~133 origin / sub-2-vs-sub-0" was **wrong**
  — the climb recipe used `start_col=0` + `pick_parity`, both cels trace to osub=0, and the "sub 2" was
  a CoCo3 placement sub after +20 centering, not the converter's parity input. **The code-citing record
  won over the field-reconstructing record.** II.9 and III.5 above carry the corrected mechanism. *(This
  is itself the volume's thesis in miniature: the artifact-under-test beats the inference about it —
  even when the inference is the reviewer's own.)*
- **R9 — COVERAGE GAP, now merged.** The execution record's completed gime-artifacting classification
  (A / no-op) folded into Appendix D.

**Coverage folded both ways:** the planning half contributed the colour-architecture depth
(storage-vs-addressability, the three both-looks paths), the decision record, and the methodology doc;
the execution half contributed the hashes, framebuffer measurements, the `$52` scroll identification,
and the completed gime result (Appendix E). Where a claim sat in only one record it's marked; no
planning-side number was upgraded to fact without an execution-side confirmation.

## Appendix G — The commit spine (this volume, 07-06 → 07-18)

**Wall-top:** identify → premise-falsified correction → decompose → authoring → render-fix →
11×7 grid → bake → recon-correction (retraction banners, three posts, trace flagged).
**Churn resolution:** the uncommitted Stage-3 backdrop refactor confirmed load-bearing and
committed; the gated build made reproducible from HEAD again.
**Orange saga:** substrate → carryover → outlier → global-swap (void) → `$A4A4`-only (correct)
→ parity attribution; `$A3E9` adopted.
**Palette:** oracle sampling → candidates → hybrid chosen → applied globally (index-frame
identical proof).
**Pre-conversion safety:** protection catalog + storage bytes + clean/fringed feasibility;
`$A3E9` adoption; CLAUDE.md §2B (catalog-before-convert).
**MAME mode:** default-vs-RGB comparison; the Monitor Type finding (after Jay's correction);
CLAUDE.md §2A.4 (exhaustive-search rule); idiom 11l corrected.

---

*End of Volume II. This volume covers the project from the scene-6 recon through the
colour-architecture arc and the pre-conversion safety trio; the parity fix is in flight and
the scene-6 fight proper is the next major arc. Standing open thread: nothing has yet run on
the second co-equal delivery target — a stock CoCo3 — and a growing pile of composite/colour
decisions waits on it. Assembled from the planning/review record and the execution/trace
record, reconciled against Jay's ground truth.*
