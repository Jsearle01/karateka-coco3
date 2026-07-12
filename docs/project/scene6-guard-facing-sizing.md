# Scene-6 guard facing — STATIC vs DYNAMIC (the last draw-B sizing question) `[2026-07-12]`

**Type:** SIZING TRACE (read-only; no build, no code change). **Question:** the draw-B scope pass
left one branch open — the guard's port-mirror is a **converter EXTEND (`--mirror`, bake at
convert-time)** *unless the guard flips facing dynamically mid-scene*, which would force a **runtime
`HAL_gfx_blit_sprite_mirror` primitive**. Settled by tracing the guard's actual draw-entry across
scene 6.

**Ground truth: EXECUTION** (past the scene-4 label boundary). A running-game draw-entry trace over
the guard's full scene-6 presence (f6400–f8500), tapping all four `jmptable_1900` entries
(`$1903`/`$1906` draw-A, `$1909`/`$190C` draw-B) — `harness/tools/scene6_full_descriptor.lua`, per-cel
`entry=[…]` map. Tap fired **1507×** (trampoline read-taps fire on the 6502; not a §1 false-0). Prod
`88eba89…` byte-identical.

## 1. Verdict: **STATIC** — neither combatant flips facing across the entire scene

The clean signal is each fighter's **unshared identity cel (the head)** — one per fighter, never
shared, so its draw-entry is that fighter's facing with no ambiguity:

| Cel | Draws | Entry map | Screen X | Frames | Reading |
|---|---|---|---|---|---|
| `$8E9B` player head | 131 | **`A` only** (100%) | 90–138 (left) | f6424–8412 | player faces **right**, draw-A, **never** draw-B |
| `$8ECB` guard head | 121 | **`By` only** (100%) | 146–314 (right) | f6487–8382 | guard faces **left**, draw-B, **never** draw-A |

Both heads span the **whole** scene — entry (f6424/f6487), fight, and fall (f8382/f8412) — each with a
**single** draw-entry. **Neither fighter ever changes draw-entry.** The player's fight cels
(`$93AB`, `$942A`, `$9490`, `$94E6`) are all `A`-only; the guard's walk-in (`$899C`, `$8ACB`, `$90F5`)
and fall (`$8D0A`, `$8E31`, `$8D2A`, …) cels are all `By`/`B`-only. Facing is **fixed per combatant
for the entire scene** → **STATIC**.

## 2. Why some cels show BOTH entries — shared cels, not flipping

Many **combat body cels** show `entry=[A:n By:m]` (e.g. `$8654` A:5/By:6, `$85F3`, `$86EB`, `$8592`).
This is **not** one actor flipping — it's the two fighters **sharing one cel bank**, each drawing it
in its own fixed orientation:

- `$8654` draw-A instances sit at **X 105–111** (LEFT = player, facing right); its draw-B instances
  sit at **X 158–166** (RIGHT = guard, facing left). Same cel, two actors, opposite fixed facings,
  drawn concurrently each frame.

The heads (§1) prove the actors don't flip; the shared body cels appear in both orientations only
because player and guard reuse the same source cel mirrored. (A coarse X-threshold split shows ~21+8
"crossover" draws — the fighters closing to mid-range while *keeping* facing, not flipping; the head
evidence is unambiguous and overrides the threshold noise.)

## 3. Player facing (HS-4) — also static

The player is **draw-A only** across the scene (head `$8E9B`, fight cels `$93AB`/`$942A`/`$9490`/
`$94E6` — all `A`). The player never uses draw-B. Both combatants are static; the scene has no dynamic
facing at all.

## 4. Build sizing — CONVERTER-BAKE ONLY, no runtime primitive (F1, small)

Because the guard's facing is **static (always draw-B / faces left)**, its cels can be **pre-mirrored
once at convert time** (`sprite_convert.py --mirror`) and drawn with the existing blit at the reflected
X — **no runtime `HAL_gfx_blit_sprite_mirror` primitive is needed for scene 6.**

**One wrinkle (storage, not compute):** the combat body cels are **shared** between the two fighters
in opposite orientations (§2). So the converter bakes **two variants** of each shared combat cel — a
normal copy (player) and a mirrored copy (guard). The engine selects the variant **by actor** (a data
choice), not by a runtime pixel op. This roughly **doubles the shared combat-cel storage**, but it
stays entirely in the build-time `--mirror` path. Per-combatant cels (heads, fight-specific poses)
need only their one orientation.

**Net:** the runtime pixel-mirror primitive is **NOT required for scene 6** (kept only as a
hypothetical fallback if a future scene flips a fighter mid-scene — scene 6 does not). Stage-4 mirror
work = **converter `--mirror` + engine per-actor variant selection + position-math.** The small-scope
outcome (F1).

## 5. Predictions / falsifiers

- **P2 verdict:** STATIC (neither fighter flips). ✓
- **F1 STATIC (guard always draw-B):** confirmed — converter-bake suffices, no runtime primitive. ✓
- **F2 DYNAMIC (guard flips):** refuted — guard head 100% draw-B across entry→fight→fall.
- **F3 player also flips:** refuted — player 100% draw-A; both combatants static.

*Investigation only — not a build. Sizes Stage 4's mirror work as a converter EXTEND, not a runtime
HAL primitive.*
