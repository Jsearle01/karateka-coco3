# Scene-6 Stage-0 — asset enumeration + three STOP blockers (for Jay) `[2026-07-12]`

**Type:** Stage-0 receipt + **HS-4/F3/HS-2 STOP**. The mass-convert did **not** proceed: three
issues in the dispatch's model need Jay's ruling before ~50–100 assets are converted into a new tree.
No folder created, no asset converted, prod ROM `88eba89…` byte-identical. This doc is the decision
artifact; the conversion resumes once Jay rules.

---

## A. Enumeration (AC-1) — the scene-6 fight cast (from the f6400–8500 draw trace)

- **103 distinct cels** drawn in the fight window; **50 recurring** (draws ≥ 4), the rest transient
  (1–3 draws, fall/impact one-shots).
- By combatant/type (draw-entry + X from the facing trace, `ae2502e`):
  - **Player** (draw-A): head `$8E9B`; fight cels `$93AB`/`$942A`/`$9490`/`$94E6`; run cels
    `$9B00`–`$9E92` (already in `content/player/`, blind).
  - **Guard** (draw-B): head `$8ECB`; walk-in `$899C`/`$8ACB`/`$90F5` (some in `content/guard/`,
    blind); fall cels `$8D0A`/`$8E31`/… (transient).
  - **Shared combat body** (drawn draw-A for player AND draw-B for guard): the `$8xxx` bank
    (`$83A8`,`$81BD`,`$8654`,`$85F3`,`$86EB`,`$8557`,`$8592`,`$8372`,`$816B`,`$876B`,`$82EE`,…) +
    `$9xxx` legs (`$90D7`,`$92DF`,`$9059`,`$9337`,`$90C1`,…) and the shared head-connector `$8EC1`
    (`content/unsorted/`, blind).
  - **Scenery / floor / HUD**: `$9A2A`/`$9A18` (`content/scenery/`, blind), `$96xx`/`$97xx` floor
    (`content/floor/`, blind), `$12xx`/`$14xx`/`$18xx` HUD.
- **Existing vs new:** ~**45 of the 50** recurring fight-combat cels have **no existing `content/`
  dir** (never converted). Only ~5–8 peripheral assets exist — and **all of those are
  `start_col=0` (BLIND)** and **tracked/committed** (`content/player/*`, `content/guard/fig_899C`,
  `content/unsorted/fig_8EC1`, `content/scenery/s5_9a2a`, `content/floor/*`).

---

## B. Three blockers (each triggers a dispatch hard-stop)

### B1. Folder scheme conflicts with the established convention (HS-4 / F3)
The dispatch specifies **`content/scene6_assets/<TYPE>/`** (player/guard/background/midground/
scenery). But the **existing tracked convention is `content/<category>/<asset>/converted.s`**, and
`content/player/`, `content/guard/`, `content/scenery/`, `content/floor/` **already exist as
top-level categories** populated with scene-6 assets. Creating `content/scene6_assets/` would build
a **parallel, differently-organized tree that duplicates** those categories. → **Jay's ruling
needed on the folder scheme** (see options).

### B2. Existing scene-6 assets are BLIND (`start_col=0`) AND tracked (HS-6 tension)
The few already-converted scene-6 assets carry `start_col=0` — the **exact color-swap defect** Stage
0 exists to fix. They are also **tracked/committed**. So "re-convert at the traced column" means
**modifying tracked content**, which conflicts with the dispatch's "scene-6 content untracked until
Jay gates" (HS-6). → **Jay's ruling needed:** re-convert **in place** (modifying tracked files) vs a
**new untracked tree** vs deprecate-and-replace.

### B3. No single "render column" for a MOVING actor — 74% of the cast (HS-2 / F1) — the big one
The dispatch's premise is "trace its render column → convert at it → **color correct by
construction**." But **37 of the 50** recurring cels are **`par=CROSS`** — drawn across **both** even
and odd screen columns as the actors move (e.g. head `$8EC1`: 131 even / 121 odd; X 90→307). On the
Apple the artifact hue **flickers** as the sprite crosses column parities; on the CoCo3 palette
display the color is **baked once** — so there is **no single traced column** whose parity is "the
correct hue." Converting "at the traced column" is under-determined for the moving majority. →
**Jay's ruling needed on a parity-selection RULE** (which column/parity to bake per moving cel),
because it sets the baked hue — and hue is Jay's gate (HS-5/HS-8). HS-2 says "if a column can't be
traced for an asset, STOP and flag it" — here it isn't singular for 74% of assets.

---

## C. Options for Jay (folder + parity)

**Folder (B1/B2):**
- **Opt-F1 — re-convert IN PLACE** under existing `content/<category>/<asset>/` at traced columns
  (+ guard `--mirror`); no new tree, matches convention, fixes the blind assets. *Cost:* modifies
  tracked files (so "untracked-until-gated" becomes "gate the diff before commit").
- **Opt-F2 — new `content/scene6_assets/<TYPE>/` tree** as the dispatch specifies; fresh
  color-correct set, old blind dirs deprecated later. *Cost:* duplicates categories, two schemes.
- **Opt-F3 — new tree as the canonical replacement**, then remove the superseded blind dirs in the
  same or a follow-up pass.

**Parity for moving cels (B3):**
- **Opt-P1 — bake at the fight-window DOMINANT column** (majority of draws) per cel; Jay hue-gates.
- **Opt-P2 — bake at a fixed reference column** (e.g. each combatant's fight-center X); consistent
  rule, Jay hue-gates.
- **Opt-P3 — Jay specifies the parity** per combatant (player-hue vs guard-hue) as an authored
  choice, since the "correct" Apple hue is itself position-dependent (no ground-truth single answer).

*Recommendation (for Jay to confirm):* **Opt-F1** (in-place, convention-matching, no duplication) +
**Opt-P2/P3** (a fixed per-combatant reference column, since the mover's hue is an authored choice,
not a single traceable fact). But this is Jay's call — surfaced, not assumed.

---

## D. What did NOT happen (correctly, pending Jay)
No `content/scene6_assets/` folder created; no asset converted; no preview sheet built; nothing
committed except this decision artifact. Prod ROM `88eba89…` byte-identical. Resumes on Jay's folder
+ parity rulings.
