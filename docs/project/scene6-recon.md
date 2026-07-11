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

## Exhaustive fight-animation search — action space + seed-sweep to saturation `[CONFIRMED 2026-07-11]`
`harness/tools/scene6_full_descriptor.lua` (now with seed-poke), 12-seed sweep × all-4-entries ×
no-filter, each run full-span f6484→f9443.
- **Action space (AC-1) — N = 4 selectors:** `fight_ai_a000` picks the animation via prob-tier
  (tables `$A087`/`$A08C`/`$A091`/`$A096`, indexed by combat state `$33` 0-7): **`$9B`** (approach,
  `$70`=`$13`/`$2F` paths), **`$C5`** (tier-2), **`$D7`** (tier-3), **`$00`/idle** (tier-1/fall);
  `$29` codes `$00`/`$01`/`$FF`. The RNG is the LCG `$59=$59×5+$13`. **`$6540` (the dispatch that
  maps selector→cel-seq) is UN-DISASSEMBLED** → per-action cel attribution is blocked statically
  (a reported limitation, not a trace gap).
- **Seed-sweep SATURATED (AC-2):** poking `$59` across 12 seeds, the combat-cel union grew
  103 (one fight) → **106**, then **plateaued for 7 consecutive seeds** (added 0). Saturation
  reached. **The seed axis was necessary:** 3 cels appear ONLY under seed variation, absent from
  the baseline single fight.
- **The 3 seed-only rare cels:** **`$87B3`** (14×5, guard/By) + **`$88C5`** (14×6, guard/By, one
  seed only) + **`$8962`** (14×4, player/A) — rare strike/body variants a single-fight trace misses.
- **Both combatants covered:** entry A (player) 7640 draws / By (guard) 7272 draws across the sweep.
- **Coverage verdict (AC-4):** the reachable animation cel-space is **captured to saturation** (106
  cels); the 4 action-selectors all fire (punch/kick/approach/idle observed). A precise per-action
  X-of-N is **blocked by `$6540` being un-disassembled** — disassembling `$6540` (selector→cel-seq
  map) is the follow-up that would close per-action attribution. No unreachable-under-win-weighting
  action identified (the weighting biases *which* move, not *whether* a move-type appears).
- **HARNESS BUG CAUGHT:** the first sweep was a no-op — `scene6_full_descriptor.lua` lacked the
  seed-poke (it lived only in `scene6_fight_control.lua`), so 8 "sweep" runs were identical. Added
  the poke; re-ran; verified divergence. (The seed axis silently doing nothing = the exact axis-miss
  the exhaustive-search framing guards against.)
- Seed-sweep-additions sheet (untracked): `build/scene6-cast-preview/scene6-seed-sweep-additions.png`.

## Full-span fight THROUGH the loop-back — combat poses found `[CONFIRMED 2026-07-11]`
`harness/tools/scene6_full_descriptor.lua` (all-entry), window **f6484-9600**, run-length raised
to reach the loop. **Root cause of "missing combat poses": prior CEL captures capped at f7400** —
the fight itself was never in the cel window (a coverage gap, not an untapped path).
- **Frame-accountability (AC-1/2):** first captured **f6484**, last captured **f9443** (=loop-back
  to the Broderbund title, `$0400` font + logo). Continuous coverage f6484→f9443; the tap fired
  the whole span. **The fight is f7246-8145** (hit-markers `$93AB` fire across it); **victory /
  walk-off f8145-9443**; loop f9439-9443. Prior windows (f6000-7400) caught only the first 3
  hit-markers — the bulk (f7607-8145) was uncaptured.
- **Hit-markers `$93AB` = working control (HS-4):** ✓ fire f7246-8145 at **both** combatants
  (X104 player / X139 guard) — the tap works where it fires; **no fallback needed** (strikes come
  through the `$1903`-family tap, entries A + By, same as everything).
- **Strike poses (high-kick / high-punch) = SHARED cels:** `$876B` `$8654` `$8592` `$85F3` `$86EB`
  `$86B5` `$821E` `$804D` — each drawn via **A (player, left) AND By (guard, right, mirrored)**.
  Confirms the two karateka share pose shapes; combatant = the draw-entry (facing), not the cel.
- **Victory / walk-off (player wins):** post-f8145 — `$8DA9` + the player run cels (`$9B00-$9DD5`
  via A). Player-only resolution (guard defeated; no player death — scripted win).
- **Both heads interleave through the fight:** player `$8E9B` and guard `$8ECB` fire alternately
  f7246-8145 (both combatants present + striking).
- **Composited fight poses + Jay's IDs (AC-6) `[CONFIRMED by Jay]`** (full-figure composites,
  `build/scene6-cast-preview/scene6-fight-poses-composited.png`):
  - **PLAYER HIGH PUNCH** = the f7602-7608 pose (via A): strike cel `$8654`/`$8714` + torso `$9A2A`
    + head `$8EC1`/`$8E9B` + feet `$90D7`.
  - **GUARD PUNCH** (mid-or-high unclear) = f7604-7610 (via By, mirrored): `$876B` + `$8654` +
    head `$8ECB`.
  - **PLAYER READY/FIGHTING stance** (NOT victory) = f8304-8316 (via A) — the neutral combat stance.
  - **GUARD KICK** (likely MID KICK) = f8306-8308 (via By): `$804D` + `$821E` + head `$8ECB`.
  - **PLAYER VICTORY** = a distinct **HELD** pose held f8370-8412 (~42 frames), via A. **`$891B` is
    oracle-labeled "player torso, arm raised, VICTORY pose, no head" (NOT a mask** — Jay's
    scene-5-Akuma-stencil hypothesis refuted by the oracle label). Full figure = `$891B` (torso+arm)
    + head `$8EC1`/`$8E9B` + legs `$81BD` + feet `$90D7`. **Compositing nuance:** `$891B` is a body
    **silhouette** (every row starts `$80`=black) — black-keyed-transparent strips the torso body
    (reads mask-like); it needs **opaque-black** (the `'f'` opaque-black model, see
    [[hal-opaque-blit-mode-needed]] / opaque-black-f-refactor-plan). The earlier composite also
    wrongly included the prior-frame ready-torso `$9A2A` overlapping it. `$8244` (f8141) = the
    winning-blow pose. Rebuilt: `build/scene6-cast-preview/scene6-victory-pose.png` (transparent vs
    opaque-black variants).
  - **WINNING-BLOW** = `$8244` (21×8 body) + `$809A` + head + feet, f8141 (via A). `build/scene6-cast-preview/scene6-blow-and-fall.png`.
  - **GUARD FALL/DEATH** = `$8D0A` (oracle "player_death" cel, **reused** for the guard) + `$8E31`
    (enemy-head) + head `$8ECB`, single-frame **f8371** (via By, mirrored) — a crouched/falling pose
    at Y140-156 (no full floor-collapse). **Coincides with the player's victory hold** (guard falls
    the same frame the victory `$891B` begins).
  - Fight resolution TIMELINE: last hit-marker f8145 → **winning-blow f8141** → **guard falls +
    player victory hold f8371** (~42 frames) → player runs off (run cycle f8647+) → last actor draw
    f9148 → loop-back f9443.
  - **OPAQUE-BLACK — the HAL CAPABILITY ALREADY SHIPS (reconciliation 2026-07-11, corrects the
    "first concrete case for a refactor" framing):** the victory torso `$891B` (and the blow/fall
    body cels) are **mixed figures** — interior black (part of the silhouette → opaque) + exterior
    black (background → transparent) + colored pixels — so neither whole-sprite mode fits (opaque
    black-boxes the exterior; transparent holes the interior). **But the per-pixel path already
    exists in the HAL, regression-proven:**
    - `HAL_gfx_blit_sprite_opaque` (`$13` flag → all-`$FF` table, stores index-0 verbatim) — added
      for the **scene-5 princess shadow `$1CC4`** (100% index-0 black); **that was the first opaque
      case, and it shipped** (scenes 1-4 byte-identical).
    - `HAL_gfx_blit_sprite_masked` — **per-pixel** trans-vs-opaque *within a cel*: a caller mask
      byte per column, pair `11`=opaque / `00`=keep-dest, "a column can be opaque on some pixels
      and transparent on others." Plus `_mixed` (per-region) and `_stencil_punch` (per-pixel 2D) —
      the same masked/stencil path used for **scene-5 Akuma**.
    - The standard transparent blit already builds a per-pixel mask from the source ("11 per
      non-black pixel pair, 00 per black").
    **VERDICT:** the "opaque-black HAL refactor" is **NOT a blocking dependency and NOT a build** —
    the capability is present. The scene-6 figures render via the **existing `HAL_gfx_blit_sprite_masked`**
    with a **per-cel opacity mask authored** (a content/sandbox task, like Akuma's `$974B`), NOT a
    HAL change. The `'f'`=opaque-black 4bpp model ([[hal-opaque-blit-mode-needed]],
    opaque-black-f-refactor-plan) is a **cleaner future option** (bake opacity into the cel, drop
    the separate mask) — an optimization, deferrable, **not required** for scene 6. Item STRUCK as
    a HAL build; reframed as content-side mask authoring. (Jay to confirm the strike, AC-6.)

## Fight: control model (A2) + determinism + scroll (B) `[CONFIRMED by multi-run + seed-poke 2026-07-10]`
`harness/tools/scene6_fight_control.lua`; window f6400-9500; 5 runs + 2 seed-perturbation runs.

### Determinism / §M-RUN — the reconciliation with "it varies run-to-run"
- **5 runs from a fixed headless boot are BYTE-IDENTICAL** (control CSV). **But the fight IS
  stochastic** — the LCG seed `$59` takes **101 distinct values** over the window and the action
  code `$29` is written **only** by `fight_ai_a000`. The reconciliation: **the fight is LCG-driven
  stochastic, but DETERMINISTIC FROM A FIXED SEED.** From an identical boot the seed sequence
  repeats → identical fight. **Jay's run-to-run variance = SEED variance** (real/interactive entry
  advances `$59` a different number of times before the fight). Not a contradiction — both true.
- **Seed-perturbation PROOF:** poking `$59` at f6484 diverges the fight **~6034 CSV lines** from
  baseline (for two different poke values) → the fight is **seed(`$59`)-driven**, not a fixed
  timeline script. (F-A2b refuted: it IS the RNG, not a canned script.)
- **HS-1 tap-bypass CATCH:** read-taps on `$A000`/`$A0A2` returned **0 fires — a FALSE negative**
  (6502 opcode-fetches bypass MAME read-taps). The reliable evidence the AI runs is the **seed
  `$59` evolving + `$29` written only by fight_ai + the poke divergence**, not the (bypassed) tap.

### A2 — action-control behavioral model `[execution-confirmed, HS-8]`
- **RNG = LCG at `$A0A2` (`lcg_step_a0a2`): `$59 = $59×5 + $13 (mod 256)`, single-byte seed ZP
  `$59`.** (`combat_state_a0af` also steps the LCG and sets `$2A` = `$FF`/`$00`/`$01` via `$55`/
  `$AA` thresholds — a random direction/choice.)
- **Selector = `fight_ai_a000` ($A000)**, called from `routine_b69a` ($B6E2, scene_dispatch).
  Reads combatant state, steps the LCG (×2), compares the random byte against **4-tier probability
  tables** (`$A087`/`$A08C`/`$A091`/`$A096`, indexed by combatant state `$33` 0-7), and sets the
  **action code `$29`** (`$00`/`$01`/`$FF`, + loads a cel-sequence ptr `$9B`/`$C5`/`$D7`), then
  tail-calls the **action dispatch `$6540`**.
- **Action/state ZP map:** `$29` action code (written only by fight_ai) · `$2A` random choice ·
  `$33` combatant state (0-11) · `$59` LCG seed · `$70`/`$2F`/`$5E` combat-state flags · `$DB`
  per-combatant threshold · `$22`/`$4A`/`$72` distance/position.
- **Code path (traced):** `routine_b69a $B6E2 → fight_ai_a000 $A000 → lcg_step $A0A2 (advance $59)
  + combat_state_a0af → prob-table compare → set $29 → jmp $6540 (dispatch) → cel-seq → $1903-blit`.
- **OUT OF SCOPE (named follow-up):** the player-always-wins **enforcement weighting** — the
  stochastic model + seed map are here; *why the player wins* is a later task. No death-anim assumed.

### A1 — fight playback / animation union
- **A real scripted-by-RNG fight occurs** (not just the approach): fight cels `$8DA9`/`$8F0E`/
  `$8E83` (31× each) + `$9290` (62×), hit-marker `$93AB` (13×), feet_shadow `$942A` (13×). 103-cel
  actor union in one run.
- **UNION NUANCE (HS-7):** a fixed boot = **one seed = one fight**, so this union is one sample.
  The TRUE animation union needs **multiple SEEDS** (poke different `$59`), NOT multiple identical
  boots. (The AA/3C poke runs already surface additional cels — a seed-sweep is the way to the union.)
- Loop-back to the Broderbund title at ~f9443 (font `$0400` + logo `$BBEC`).

### B — background scroll verification `[per-frame ΔX]`
- **Midground `$A684`: SCROLLS** — X span **94** (238→332) over the window. ✓
- **"Upper background" `$A7xx` (Y<70): ALSO SCROLLS — span 94, identical to the midground.**
  `$A82B`/`$A7D1`/`$A707`/`$A763`/`$A703`/`$A857` all span 94. **F-Ba fired:** these are NOT a
  fixed layer — the `$A7xx` cels are **scrolling midground**, not the fixed backdrop. **[SEE THE
  RE-VERIFY BELOW — the fixed sky/Fuji layer WAS found, just not in the `$1903` span; F-Ba was a
  mislabel of the scrolling midground, not evidence the backdrop moves.]**

### B (re-verify) — THREE background layers, fixed backdrop FOUND `[CONFIRMED 2026-07-11]`
Jay's eye (watched scene 6 ×3): **sky + Mt-Fuji never move** — ground truth. Re-verify
(`harness/tools/scene6_bg_layers.lua`, f6000-7400): classify `$Axxx` cels by X-span + tap the
non-`$1903` `$0A00` FILL family. **The scene-6 background is THREE layers:**
1. **FIXED backdrop — Δ=0 `[CONFIRMED]`:**
   - **Mt-Fuji = a 4-sprite STACK, all Xspan=0 (fixed):** peak **`$A948` (X126, Y81)** → **`$A976`
     (X112, Y92)** → **`$A9B8` (X105, Y100)** → base **`$A9E2` (X84, Y108)**. (Jay's correction:
     the earlier pass showed only the base `$A9B8`/`$A9E2`; the **TOP/peak `$A948`/`$A976` draw
     just 2× at scene entry (f6012) and PERSIST**, so they were buried in the draw-count list —
     now surfaced by sorting fixed cels by Y.) The full stack spans Y81→Y108, does not move.
   - **Sky = `$0A00` fill `passA r0-104 c0-40 pat$D5`** — a **full-width fill of the top 104 rows,
     laid once at scene entry (f6003-6062)** and persisting; fixed vertical position.
   - **OCCLUSION-REPAIR mechanism (Q1) `[CONFIRMED — PORT REQUIREMENT]`:** the base draws 35×
     vs the peak 2× because of **occlusion, X-scoped**: at the **peak's position (X112-168,
     Y81-99) overpaint = 0** → drawn 2× at entry, persists. At the **base's position (X84-189,
     Y100-111) the scrolling FLOOR `$AA` tiles overpaint (94 draws)** → the game **repair-blits**
     the lower stack 35× to keep it visible. **The fixed backdrop is NOT draw-once** — the lower
     stack (rows overlapping the scrolling floor/midground) needs **repair-blitting after
     overpaint**; the peak (above the floor line) can be draw-once. (Confirms Jay's read.)
   - **The 4th-sprite vertical gap (Q2) = CASE B `[CONFIRMED]`:** heights `$A948`=11 / `$A976`=8
     / `$A9B8`=4 / `$A9E2`=3 leave **rows Y104-107 uncovered in the sprite stack** — a real gap.
     **Case A refuted:** all four draw via **entry A (`$1903` base, no Y-offset)** — not a
     composite Y-offset artifact. **Case B confirmed:** the gap rows Y104-107 are the **floor
     zone** — the scrolling floor `$AA11` (Y104, tiled across X) **fills them on-screen**; the
     plain Fuji-sprite composite omitted the floor, showing a gap the screen fills. Re-composite
     with the floor layered in reads continuous (`build/scene6-cast-preview/scene6-fuji-gapfill.png`);
     on-screen-vs-sheet is Jay's oracle call (HS-3).
2. **SCROLLING midground — Xspan≈88 `[CONFIRMED]`:** the `$A684`-bank tiles (`$A684`/`$A68A`/
   `$A703`/`$A85F`/`$A7xx`/…) — 24 cels, all span ≈88. This is what F-Ba measured and mislabeled.
3. **ACTORS:** `$8xxx/$9xxx` (player/guard).
- **Root of F-Ba:** the prior pass measured X-span only on the `$1903` scroll stream and never
  captured the fixed layer (constant-X sprites + the `$0A00` fill). The fixed backdrop was
  invisible to that measurement, not absent. **Corrected: there IS a fixed sky/Fuji layer** (Δ=0),
  separate from the scrolling midground — matching Jay's eye.
- Preview (untracked): `build/scene6-cast-preview/scene6-bg-layers.png`.

## Draw-entry map + facing + recovered parts `[CONFIRMED by all-entry re-trace 2026-07-09]`

> **JAY GATE — AC-6 — 2026-07-10 `[CONFIRMED by Jay]`** (off the corrected sheet): the **draw-B
> h-flip is confirmed — the guard now faces LEFT** (Case 2 validated; the facing mechanism is the
> draw-entry, port-relevant). The **lower-body composite (recovered Ay `$1906` second-tiles) is
> decent** — but the **FEET area still needs work**. As with the walk/climb/guard, **composite
> refinement moves to the animation sandbox**, not another recon trace. Trace-side findings
> (entry map, facing = draw-B mirror, Ay lower-tiles) are accepted.

All-entry re-trace of f6000-7400 (`harness/tools/scene6_full_descriptor.lua`, taps all four
jmptable entries; deterministic ×2; CSV `build/logs/allent.csv`). Resolves the guard-facing +
walk-feet-band threads — both were the same root: `$1903`-only coverage.
- **Entry map (per-entry fire counts, f6000-7400):** draw-A `$1903`=**362**, draw-A-Yoffset
  `$1906`=**22**, draw-B `$1909`=**10**, draw-B-Yoffset `$190C`=**299**. The `$1903`-only passes
  missed ~331 draws (Ay+B+By). The two draw *variants*: `$1903`/`$1906`=draw-A (`routine_1927`),
  `$1909`/`$190C`=draw-B (`routine_1af4`).
- **FACING = CASE 2 (real h-mirror mechanism the composite dropped — PORT-RELEVANT) `[CONFIRMED
  by code]`:** draw-B (`routine_1af4`) opens with `$10 = 7 - $10` + `dec $05` — a horizontal
  sub-byte MIRROR. The `$0F` flip bit is **identical per-cel** for player and guard (e.g. `$8EC1`
  is FLIP in both), so **facing is encoded by the ENTRY (draw-A vs draw-B), not `$0F`.** The guard
  draws via `$190C` (draw-B) = mirrored → faces left toward the player; the player via `$1903`
  (draw-A) = normal. My composites used the orientation-blind converter and **dropped the draw-B
  mirror** → guard faced wrong. **Port must render draw-B (`$1909`/`$190C`) sprites h-flipped.**
- **FEET-BAND = recovered Ay parts (H-parts CONFIRMED) `[CONFIRMED]`:** `$1906` (draw-A Y-offset)
  "draws a second sprite tile BELOW the first" (oracle). The player's lower body — legs (`$83DE/
  $843F/$84A0/$84DE`, Y143) + feet (`$90D7/$92DF`, Y159) — draws via **Ay `$1906`** (X154-193,
  f7153+), which the `$1903`-only walk composite **omitted** → the incomplete feet-band. (Early-walk
  feet via `$1903` were present, so registration may also contribute — but the missing Ay
  second-tiles are a real, recovered cause.)
- **Per-phase model refinement (HS-8):** the figures use **multiple entries**, not just `$1903` —
  draw-A for the primary tiles, **draw-A-Yoffset (`$1906`) for lower second-tiles**, draw-B
  (`$190C`) for the mirrored guard. A faithful composite must tap all four and honor the draw-B
  mirror. This refines the earlier `$1903`-only "walk 4-band / climb 2-part / guard single-frame".
- Corrected preview (untracked): `build/scene6-cast-preview/scene6-corrected-composited.png`
  (guard as-was vs draw-B-flipped; walk with recovered Ay lower tiles).

## Guard entry + opening exchange `[CONFIRMED by all-entry trace 2026-07-09]`

> **JAY GATE — AC-7 — 2026-07-09 `[CONFIRMED by Jay]`** (off the guard sheets): **all the
> orange sprites EXCEPT the guard's head are PLAYER RUN ANIMATION.** So the right-side (via-By)
> figure IS the guard, but its **body is reused player-run-animation cels** — only the **head
> `$8ECB` is a guard-distinct sprite**. The body cels I clustered as "guard" (`$8EC1`, `$9A18`,
> `$899C`, `$8ACB`, `$90F5` — all ODD→orange) are **shared player-run cels**, not guard-specific.
> **CEL-IDENTITY ≠ ACTOR-IDENTITY** — this is exactly the HS-9 shared-shape case: the sort by
> entry-path/X-side correctly found the guard *figure*, but cel labels/data are shared, so the
> guard's cast contribution is **just its head** ($8ECB, blue); the rest is the player's run set
> drawn at the guard's position. (Supersedes the scene-5 cast-map "$899C/$8ACB = guard body" and
> my body-cel attribution — §2/§4, Jay's visual gate is authority.)
> **Consequence:** the actor discriminator is the **head + position**, NOT the body cels (which
> the two karateka share). Guard-distinct asset to convert = the head `$8ECB` (+ any head variants);
> the body reuses the already-known player run animation.

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
