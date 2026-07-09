# Scene-6 Oracle Recon — the attract fight-demo (motion-layer + cast spec)

**Execution-grounded recon.** Scene 6 (the CoCo port's next scene) = the Apple oracle's
**attract "one fight" demo** (intro-cycle scene 8: hero vs one guard, scripted, hero wins).
Scene 6 is **past the scene-4 oracle wall**, so the spine is: **the running game is authority;
the oracle `.s` labels are a HYPOTHESIS source** — used here only to *name* execution-localized
sources. Every entry is tagged `[CONFIRMED]` (execution-observed) or `[HYP]` (oracle
label / bank cross-ref, pending Jay's live-MAME adjudication). Identity/color/position is
**Jay's call** (HS-4); this doc LOCALIZES (source→object→frame) and hands Jay a targeted list.
**t0:** 2026-07-06T21:35:09. Read-only (oracle repo + prod `88eba89…` untouched; no
conversion into the port, no code/build). Trace tools (untracked in the oracle repo):
`tools/scene6_layer_separate.lua` (this pass — bank-classified draw-entry tap),
`tools/attract_scene6_trace.lua`, `tools/scene6_sprite_localize.lua` (prior passes).

> **CORRECTION (this pass, from Jay's live-MAME gate).** The prior recon mislabeled the
> **scrolling background** (`$A684`-bank tiles) as "the dominant MOVER / likely the hero,"
> and hypothesized the `$0B1x` cluster as a "second combatant." Both were the "moving =
> actor" trap: per-frame `$03/$04` sampling caught the *most-drawn* thing (the scroll) and
> mid-blit ZP noise, not the cast. **This pass classifies by sprite-BANK at the actual draw
> entry `L1903` ($1903)** — which separates the three real motion layers cleanly and finds
> the characters via their oracle labels. See "Superseded findings" at the end.

---

## The three motion layers `[CONFIRMED by bank-classified draw tap]`

Method: read-tap `L1903` ($1903, the video.s sprite-draw entry — the blit reads `$03/$04`
as the source, per the ZP-tap-vs-blit-entry note). Over the fight window (f6400-7400,
deterministic single run), every draw's source `$04·256+$03` is bucketed by bank. Draw
counts are per-window totals.

### Layer 1 — LOCKED SCROLL (player-driven background) `[CONFIRMED]`
The `$A400-$ACFF` bank, drawn **hundreds-to-thousands of times per window** — a tiled layer
redrawn every frame across the play width (the signature of a scrolling floor/scenery group,
NOT a single actor):

| source | frames | draws | oracle label `[HYP]` |
|--------|--------|------:|---|
| `$A684` | f6528-7392 | **2756** | `sprite_A684` (a400 bank, "unidentified") — dominant scroll tile |
| `$A68A` | f6519-7400 | 1113 | `sprite_A68A` |
| `$A703` | f6519-7384 | 988 | `sprite_A703` |
| `$A85F` | f6519-7168 | 280 | `sprite_A85F` |
| `$AB8E` | f6421-6573 | 252 | a400 floor pattern |
| `$AA11 / $AA23 / $AA31` | f6455-7166 | 216/86/84 | a400 floor patterns |

This is the layer Jay described as one **locked group** that stays still while the player
moves through a **dead-band**, then scrolls once he passes the margin. The lock/dead-band
*mechanism* is a Stage-2 (scroll-engine) concern — not built here — but the layer is now
correctly identified as the scroll, not the hero. (27 distinct scroll sources total.)

### Layer 2 — INDEPENDENT CHARACTERS (the real cast) `[CONFIRMED sources; identity HYP]`
Combatant figures in the `$8xxx/$9xxx` sprite banks, drawn a **handful of times each** (one
figure, not a tiled fill), reconciled to oracle labels (HS-4 — by structure, not draw-count):

> **JAY VISUAL GATE — AC-6 / 25.3 — 2026-07-08 `[CONFIRMED by Jay]`** (off the trace-driven
> preview sheet `build/scene6-cast-preview/`; overrides oracle labels per §2/§4). Decisive
> reclassification of the f6000-7400 window:
> - **All the parity-STABLE (non-crossing) candidates are PLAYER sprites** — parts of the
>   player multi-part composite that **need compositing** (legs + torso + shadow + body cels
>   assembled into one figure). This **SUPERSEDES** the oracle "`enemy_head_8E9B`" /
>   "`feet_shadow_8EC1`" labels and this doc's prior GUARD hypothesis for `$8E9B`/`$8EC1`:
>   they are player parts, not the guard. `$9A2A`/`$83A8`/`$90D7`/`$81BD` + the `player_run_*`
>   cluster are all player composite parts. (Jay: this window is **AFTER the climb phase** —
>   the climb is an EARLIER window that needs its own trace. **No enemy/guard has appeared yet**
>   in f6000-7400 — that is why none was found; the guard enters a LATER window. Both are
>   separate trace dispatches.)
> - **The three parity-CROSSERS `$942A`/`$93AB`/`$9A18` "look correct"** (the F1 flag was
>   right) — **except the last, `$9A18`, is likely part of the PLAYER DEATH composite** (a
>   player-death cel, not a standalone crosser). Its parity-crossing is consistent with being
>   a composite part drawn across positions.
> **Consequence:** the scene-6 near-term cast is a PLAYER multi-part composite; the next step is
> COMPOSITING the traced parts (per-part `$05·7+$10` column + `$06` Y-row give the relative
> registration), not more per-cel conversion. Guard localization = a later-window trace.


**PLAYER — run cycle `[HYP: oracle player_run_* labels]`** (early in the window, f6423-6613):
| source | frames | oracle label |
|--------|--------|---|
| `$9B00 $9B6B $9BE5 $9C1B $9CAF $9CD7` | f6423-6612 | `player_run_legs_*` (8-frame leg cycle, `$9B00-$9D1E`) |
| `$9D68 $9D97 $9DD5 $9E05` | f6438-6613 | `player_run_torso_*` (8-frame torso cycle, `$9D68-$9EB7`) |

The player is a **composite** (legs + torso drawn as separate cels), consistent with the
oracle bank map ("separate leg sprites composited with torso below"). Companion parts
`$83A8 $81BD $90D7` draw in lockstep with the later character cluster (f6733+).

**ENEMY / GUARD `[HYP: oracle enemy_head label]`** (present throughout, right side):
| source | frames | draws | oracle label |
|--------|--------|------:|---|
| `$8E9B` | f6424-7386 | 62 | `enemy_head_8E9B` — "enemy head/body variant" |
| `$8EC1` | f6424-7386 | 62 | `feet_shadow_8EC1` (the enemy's feet-shadow) |

The enemy head+shadow persist the entire window at the right (`$51≈$FE` at first sighting),
matching Jay's "GUARD enters from the right, moves independently of the scroll."

**EFFECTS (gameplay sprites — confirm a real fight) `[HYP]`:**
`feet_shadow_930F / 9323 / 942A` (shadows under the combatants) and `hit_marker_93AB`
(impact spark, appears f7246 in the contact phase) — both hardcoded in `gameplay_7000.s`.

**AMBIGUOUS — cluster-L dominant `[HYP: oracle 'visual ambiguous']`:**
`$9A2A` (34 draws, f6733-7352, `$51≈$1B`) + `$9A18` — oracle `sprite_9a2a/9a18` (chain-2,
labeled "visual ambiguous", also used in scene 5). The most-drawn *character* source in the
contact phase; whether it's a player pose, the guard's body, or a shared prop is **Jay's call**.

> **Not characters, despite the `$9xxx` bank:** `$9524 $9550 $958E $95B8` are `floor_pattern_*`
> (scenery that lives in the `$95xx` region) — reconciled out by label, not swept in by range.

### Layer 3 — STATIC BACKDROP `[HYP]`
The Mt-Fuji stack + blue sky Jay described is a **fixed background fill**, not a per-frame
`L1903` sprite blit (it did not appear as a high-count draw source) — so it is NOT in the
draw-tap inventory above; it is drawn once/rarely as a background. Flagged for Jay to confirm
it is fixed (no scroll coupling) during the live gate.

---

## Corrections / superseded findings
- **`$A684` is the SCROLL, not the hero.** 2756 draws/window = a tiled redraw, the scroll
  layer's signature. The prior "dominant mover = hero" was the moving-object trap.
- **The `$0B1x` cluster is NOT a combatant.** `handler_0b35/0b7c` (which set `$03/$04=$0B12`
  and draw that 7×1 element `$B6`/`$B7` times) **fired 0 times** in the fight window — they
  are gameplay-state handlers, not attract. The prior "second combatant / $0B1x" was
  per-frame ZP noise. (The disassembly's "$B6 enemy / $B7 player sprite" comments are
  Hypothesis/TBD and do NOT describe the attract cast.)
- **Method fix:** classify by bank at the `L1903` draw entry, then reconcile to oracle labels
  — do not rank by per-frame `$03/$04` dwell (which is dominated by the scroll + mid-blit noise).

---

## Repeatability `[CONFIRMED]` — HS-2 gate PASSES (deterministic)
3 runs land byte-identical at the fight-demo onset (f≈6480, ~108 s). The attract cycle plays
frame-for-frame with no RNG, so the reach is fully repeatable (boot `apple2e -flop1
dumps/karateka.dsk`, wait to ~108 s) and one run's timing IS the timing.

---

## TARGETED adjudication list for Jay (HS-8)
Run the demo (boot, wait to ~108 s, watch ~108-125 s; operator-gate flags `-window -speed
0.5 -prescale 3`) and adjudicate — see `build/scene6-id-sheet/scene6-id-sheet.png` for the
rough character cels (shape-only; colors/registration not trustworthy):
1. **PLAYER** = the `player_run_legs/torso` composite (run cycle, f6423-6613): correct
   character? which side does he run in from, and which cel = which action?
2. **GUARD** = `enemy_head_8E9B` (+ its feet-shadow), right side, present throughout:
   correct? Does he move independently of the scroll (as expected)?
3. **AMBIGUOUS `$9A2A`** (dominant in the contact phase, f6733+): player pose, guard body,
   or a shared/transition sprite?
4. **SCROLL** = the `$A684` tile group — confirm it is the moving *background* (not a
   character), and describe the dead-band (player moves / scroll still → then scrolls)?
5. **BACKDROP** — is the Mt-Fuji + sky stack fixed (no scroll coupling)?
6. Any on-screen object NOT above (a prop, a UI element, a second enemy)?

---

## Guard entry + opening exchange `[CONFIRMED by all-entry trace 2026-07-09]`
Traced `harness/tools/scene6_full_descriptor.lua` (now taps ALL FOUR jmptable_1900 draw entries);
window f6450-7000; deterministic ×2; CSV `build/logs/guard.csv`.
- **CRITICAL CORRECTION — the guard is drawn via draw-B Y-offset `$190C`, NOT `$1903`.** Every
  prior scene-6 trace tapped only draw-A `$1903` and so **missed the guard entirely** (a false
  "no second figure"). The four entries fire (f6000-9500): `$1903`(A), `$1906`(Ay), `$1909`(B),
  **`$190C`(By)=832×**. Tapping all four is mandatory. (HS-1/HS-7: the tap must catch *all* draws.)
- **The guard ENTERS FROM THE RIGHT** — head `$8ECB` at X314 (f6487) approaching left steadily to
  X196 (f6715): X314→304→294→284→…→196. Exactly Jay's motion model.
- **Two actors CO-OCCUR** (the decisive multi-actor signal): frame f6487 draws BOTH — PLAYER
  (entry A, X120-132, left) and GUARD (entry By, X307-314, right) in one frame. Clean separation:
  **entry-path + X-side + head-signature all agree** (no HS-9 conflict).
- **Head-signature discriminates the actors:** both share the FLIP half `$8EC1`, but the norm half
  differs — **player = `$8E9B`, guard = `$8ECB`**. The norm-half is the identity key.
- **Guard cluster (structural):** head `$8EC1`+`$8ECB`, body `$899C` (torso) + `$8ACB`
  (below-torso) + `$9A18`, feet `$90F5` — matches the scene-5 cast-map guard body (`$899C`/`$8ACB`).
  Oracle labels mislead again (`$8ECB` = "feet_shadow" but is the guard HEAD). All Jay's call (HS-5).
- **Guard compositing model:** mostly **single-frame** (f6487 draws head+torso+below-torso+`$9A18`
  together via By) + feet `$90F5` on adjacent frames — closer to the climb's single-frame poses
  than the walk's accumulation. (Per-cluster model, HS-8.)
- **Convergence zone flagged (HS-9):** By-draws at middle X (167-203) — where the approaching guard
  and the rightward-walking player overlap — are **kept OUT of the strict guard cluster** (reported,
  not force-assigned).
- **Caveat on the prior walk/climb composites:** they used `$1903` only, so any Y-offset parts
  drawn via `$1906`/`$190C` were omitted — a possible source of the walk's "feet band needs work"
  (Y-offset feet may draw via `$190C`). Flag for the animation-sandbox refinement.
- Preview artifacts (untracked): `build/scene6-cast-preview/scene6-guard-{raw,composited}.png`.

## Player compositing model `[CONFIRMED by full-descriptor trace 2026-07-09]`

> **JAY GATE — AC-6 — 2026-07-09 `[CONFIRMED by Jay]`** (off the raw + composited sheets in
> `build/scene6-cast-preview/`): the composited reconstruction is **a good first pass — the
> compositing METHOD is validated** (band-accumulation at traced positions reads as the player).
> **Open:** the **feet band needs work** (Y153-159 — the feet/shadow cels don't sit right).
> **Refinement moves to the animation sandbox** — not another recon trace. Method green-lit to
> scale to the guard (later-window) and climb (earlier-window) traces.

From the L1903 full-descriptor trace over f6000-7400 (`tools/scene6_full_descriptor.lua`,
deterministic ×2, 352 non-scroll draws; per-draw CSV `build/logs/scene6_draws.csv`):
- **The player is drawn DIRTY-RECT, not whole-figure-per-frame.** Draws-per-frame histogram:
  110 frames ×1, 31 ×2, 52 ×3, 6 ×4 — **each frame redraws only 2-4 Y-bands**, and the parts
  **persist + accumulate** on the framebuffer. So single-frame co-occurrence gives a PARTIAL
  figure; the **full figure = short-window accumulation** (latest draw per band within ~16
  frames). This refines the prior "co-occurring cels = one figure" assumption — it's
  accumulation, not one frame.
- **Four Y-bands** (the composite structure): **head** Y116-121, **torso** Y123-129, **legs**
  Y138-143, **feet** Y153-159. Each band's cel swaps per animation frame; X co-steps to hold
  parity (movers stay one hue). 7/8 sampled anchors assemble all four bands; gaps (a band not
  redrawn in-window) are real, not missing data.
- **The head is a MIRROR PAIR:** `$8EC1` (blend=FLIP) + `$8E9B` (blend=normal) are drawn at the
  **same X,Y every time** → a symmetric head built from one cel + its h-flip. This is why the
  oracle "`feet_shadow_8EC1`"/"`enemy_head_8E9B`" labels mislead — together they are the player's
  head (consistent with Jay's gate: player parts, not enemy). Blend/flip `$0F` per cel is in the
  descriptor (`FLIP`=reversed/h-flip, `norm`, `skip`).
- **Draw order** within a frame is stable (head-pair first, then body cels); cross-frame
  accumulation paints chronologically (last drawn on top = framebuffer order). Bands barely
  overlap, so occlusion is minor.
- Preview artifacts (untracked): raw part-cel sheet + accumulated-figure sheet in
  `build/scene6-cast-preview/scene6-player-{raw,composited}.png`.

## Climb phase `[CONFIRMED by full-descriptor trace 2026-07-09]`

> **JAY GATE — AC-6 — 2026-07-09 `[CONFIRMED by Jay]`** (off the climb raw + composited sheets):
> the composite is **pretty good — method validated**. **Tweaking deferred to the animation
> sandbox.** Caveat Jay flagged: **the Y-change (ascent) can't be judged from static sheets —
> needs the background + animation** to confirm the climb motion reads right (a sandbox check, not
> a recon trace). Player-recon now closed both phases (fight + climb); **guard** is the remaining
> cast item (later-window trace).

Located + traced (`harness/tools/scene6_full_descriptor.lua`, env window + refined exclusion;
deterministic ×2; CSV `build/logs/climb.csv`):
- **Window (AC-1):** scene 5 (imprison) ends ~f5995; **CLIMB = f6019 (intro pose) + 5 active
  steps f6077/6084/6091/6098/6105**; **climb→walk boundary f6105→f6110** (the `$8xxx/$9xxx`
  walk begins f6110). This pins the phase boundary the prior verdicts left open.
- **The climber is the `$A3C5-$A649` "Climbing-animation sprite chain"** (oracle
  `sprite_data_a400.s`; 12 cels) — it lives IN the `$A400` bank but is **NOT scroll**. The prior
  f6000-7400 trace excluded `$A400-$ACFF` wholesale and so **hid the climb** — the refined
  exclusion is `$A64A-$ACFF` (scroll tiles `$A684+` / cliff `$AA7D` / floor), keeping
  `$A3C5-$A649` as the captured climber. (HS-4 trap: climber and scroll share a bank.)
- **Motion (HS-8 CONFIRMED):** the climber **translates UP** — Y 158→120 (upper) / 141→127
  (lower) over f6019-6105, at X63-84 (lower-left). Positions MOVE per pose; there are **no fixed
  Y-bands** (that model was walk-specific).
- **Compositing model — DIFFERENT from the walk:** each climb pose **redraws BOTH parts in one
  frame** (single-frame co-occurrence, blend=skip), so a pose composites directly from its frame's
  2 cels at traced positions — **no cross-frame accumulation needed** (the walk needed it; the
  climb does not). The **mirror-head pair is ABSENT** — the climb uses a compact 2-part figure
  (upper + lower), not the walk's head/torso/legs/feet band stack.
- **Cels:** 10 labeled (`sprite_A40B/A425/A45A/A4A4/A4D2/A4F2/A548/A572/A5CC/A5DC`) converted;
  the f6019 **intro pose `$A3C5`/`$A3E9` is split across `fight_engine.s` (header) + `$A400`
  (bitmap tail) with no clean label — OMITTED as a reported gap** (HS-6), not filled.
- Preview artifacts (untracked): `build/scene6-cast-preview/scene6-climb-{raw,composited}.png`
  (raw cels + 5 pose panels + ascent overlay).

## Status / open items
- **25.3-V — PARTIALLY CLOSED (2026-07-08):** Jay's visual gate (block in Layer 2) confirmed the
  f6000-7400 cast is the **PLAYER multi-part composite** (parity-stable candidates = player parts
  needing compositing; `$9A18` ≈ player-death cel). This **supersedes** the `$8E9B`/`$8EC1`
  enemy/guard hypothesis. STILL OPEN: (a) **compositing** the player parts into the assembled
  figure (next step — traced per-part column/row give registration; the current rough composite
  `build/scene6-cast-preview/scene6-player-composite.png` is a decent start but needs more work —
  Jay); (b) **CLIMB phase** — an EARLIER-window trace (before f6000; this window is post-climb);
  (c) **GUARD/enemy** — a LATER-window trace (the enemy has not appeared by f7400); (d) per-parity
  **variant ruling** for any true crosser (`$9A18` folds into the player-death composite instead).
  Items (a)/(b)/(c) are follow-up dispatches (Jay to discuss with the orchestrator).
- **25.3-V is the core gate:** Jay's live-MAME adjudication is the SOURCE of asset identity;
  the remaining `[HYP]` entries stay open until he watches the demo and answers the list above.
- **Stage 1 scope (this pass):** find + classify the motion layers and localize the cast.
  Delivered. **NOT done (later stages):** conversion into the port, the sequence-timing epic,
  the scroll-engine (dead-band/lock) build, the scene-6 CoCo hook — this recon is their spec.
- **Data-location `[HYP]`:** cast data lives in the `$8300`/`$8c67`/`$9b00`/`$A400` oracle
  banks (labels above) — mark CONFIRMED only once a conversion-time trace confirms the source
  address IS the sprite data at draw time.
