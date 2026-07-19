# The walk-phase (mid-ground) scroll observable — TRACE finding (2026-07-19) — REPORT ONLY

**Classification: the mid-ground DOES translate during the walk — but the trace says it is driven by
`$52`, the SAME global scene-scroll register as the guard/fight cels, at a different per-layer offset.
No separate non-`$52` register drives it.** This **contradicts the dispatch premise** (`$52` excluded /
a distinct mid-ground driver). Per CLAUDE.md, the trace is surfaced, not forced to fit; **Jay's eye is
the gate** and reconciles this. **Report-only — STOPPED at the classification; nothing built.**

## What was asked vs what the render shows
The dispatch was built on Jay's model: the mid-ground (ground/wall/wall-top) scrolls with the player
while **`$52` stays `$30`** (excluded), so the driver `S` must be a **non-`$52`** register found from the
mid-ground render. The instrumentation found `S` from the render — and it is **`$52`**.

## Method (clean recipe, read-only; find S from the render, not assumed)
1. **ZP panel** (`zp_panel_trace.lua`, `$40–$7F` change-log, f2500–9500): in the **pure climb**
   (`$52=$30`, f3897–6418) the ONLY changing registers are `$46/$47` toggling (render parity) — **nothing
   ramps**. `$5B/$5C` (the one smooth ramp) **start at f6418**, the walk/approach onset.
2. **Mid-ground render tap** (`midground_trace.lua`, `$1903/06/09/0C` + masked `$1BF4`; banks
   `$A9`/`$AA`/`$AB`): captured each mid-ground cel's col with the candidate registers.

## Finding (execution-confirmed)
**The mid-ground translates, and col tracks `$52` exactly** — cliff `$AB8E`:

| `$52` | 30 | 2F | 2E | 2C | 2B | 29 | 28 | 27 | 25 | 24 |
|---|---|---|---|---|---|---|---|---|---|---|
| `$AB8E` col | 0A | 09 | 08 | 06 | 05 | 03 | 02 | 01 | FF | FE |

`col = $52 − $26`, exact. Held at `0A` while `$52=$30` (climb) → **fixed**, then translating 1:1 as `$52`
sweeps. The wall-top posts (`$AA23`/`$AA31`, 4 instances `$0C` apart) translate **together**, all `−2` as
`$52` steps down — same `$52`-tracking. **Ratio ≈ 1:1 with `$52`** (Δcol/Δ`$52` ≈ 1).

**`$5B` is a red herring.** It ramps continuously from the walk onset, but the mid-ground does **not**
track it: col held `0A` while `$5B` ran `01→05`, and (causal pin below) the mid-ground stays fixed while
`$5B` keeps ramping. `$5B` is a walk/approach counter, not the render's X-source.

**Onset / dead-band.** The mid-ground translation begins exactly when `$52` leaves `$30` (f6455), which is
when `$62` crosses `$0F` — the walk onset. During the pure climb (`$52=$30` held) the mid-ground is
**fixed** at `col=0A`. So "no clear dead-band" holds for the walk proper (once `$52` moves it tracks 1:1);
the climb itself is the held region.

**Causal (per-frame force `$62`=05, walk never completes).** The mid-ground **freezes**: `$AB8E`/`$AB7C`/
`$AB94`/`$AA7D` all stay col-fixed (`0A`/`06`) — while `$5B` still ramps `01→06`. Pinning the walk freezes
`$52` at `$30` (the earlier scroll finding) and the mid-ground with it. **Walk-driven, via `$62 → $52 →
mid-ground col (= $52 − offset)`** — not `$5B`.

**Layer contrast (three layers, execution-confirmed).**
- **Fuji backdrop** (`$A9` bank, `draw_background_ladd1`): **hardcoded** X (`lda #$0F`/`#$0C`) — **FIXED**.
- **Mid-ground** (`$AA` wall-top, `$AB` cliff): `col = $52 − offset` — **translates with `$52`**.
- **Scene-sprite group** (`$A6–$AC` table, `load_scene_sprite_ae3f`): `col = $52 ± xadj[i]` — **translates
  with `$52`**, draws only while `$52 ∈ $14..$28`.

## Render-path evidence (why it's `$52`)
The whole scene render is `$52`-relative: `load_scene_sprite_ae3f` (`$05 = $52 ± xadj`, attract_dispatch.s
417/428), `draw_scene_elem_5` (`$05 = tbl_x − $E0 + $52`, display_7700.s 303-308), and `lda $52` X-computes
in `draw_scene_ae7a`/`draw_scene_af4d`/castle (attract_dispatch.s 464/496/582/620). The mid-ground
`col = $52 − offset` is one of these `$52`-relative computes. **The `$AA/$AB` cels are NOT in the `$52`
scene-sprite table** (table hi bytes are `A6/A7/A8/AC/80`), so they use a **different offset** off the
**same `$52`** — which is exactly why they read as a "separate layer" while sharing the driver.

## The conflict to reconcile (Jay's eye is authority)
The dispatch's premise — `$52=$30` **through the whole walk**, mid-ground driven by a non-`$52` register —
is **not what the trace shows**: `$52` sweeps `30→1B` during the walk, and that sweep is exactly what
translates the mid-ground (`col = $52 − offset`). The earlier `$52` finding was therefore **not an adjacent
answer** — `$52` is the **global scene scroll** driving both the guard cels (`+xadj`) and the mid-ground
(`−offset`); only Fuji is `$52`-independent. **If Jay's eye holds that the mid-ground scrolls while `$52`
is genuinely `$30`, there is a phase the trace has not captured — surface it; do not override.** But every
window traced shows: mid-ground translation ⟺ `$52` moves; `$52` held ⇒ mid-ground fixed.

## The fork (this dispatch's whole output)
The observable the walk build needs is **`$52` (the shared scene-scroll) with the mid-ground layer's own
offset (`col = $52 − offset`)** — the same register the guard/fight build uses, not a second one. **Report
only — STOPPED. Jay reconciles this with his eye before any build.**

*Logs: `scratchpad/scroll/zp_panel.txt`, `midground.txt`, `pinmg/midground.txt` (reproducible, seed-fixed).*

## RESOLUTION (Jay's eye, 2026-07-19) — CONFIRMED, scroll recon CLOSED
Jay confirms the visible walk-scroll IS the **`$52` sweep** (the large forward-move translation), not an
earlier `$52`=`$30` motion. The open question closes in `$52`'s favour:
- **`$52` is the global scene scroll** — mid-ground (`col = $52 − offset`) + scene-sprite/guard cels
  (`col = $52 + xadj`); Fuji (`$A9`) hardcoded/independent. **No separate walk-scroll register.**
- **Scroll-before-guard holds:** the `$52` sweep starts f6455; the guard draws f6487 (~32 frames later) —
  the scroll begins before the guard is visible, as Jay sees.
- **The earlier `$52`=guard-phase reclassification (Orchestrator) is REVERTED** — `$52` was always the
  global scroll; that reclassification over-read the sweep-onset timing.
- **Walk-build scroll spec:** reproduce `$52`-relative scene rendering (mid-ground at `$52 − offset`) —
  the same register the guard/fight build uses; no second mechanism to find.
Closes the scroll recon (fight-order step 2). Verdict: `verdict_walk-scroll-mechanic.md`.
