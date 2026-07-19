# The attract scroll mechanic — TRACE finding (2026-07-18) — REPORT ONLY, no build

> **⚠ CORRECTED (2026-07-19) — see `walk-scroll-mechanic-finding.md` for the reconciled conclusion.**
> Two claims below are superseded by the follow-up trace + Jay's eye:
> - **`$AB8E` (cliff) is NOT fixed — it scrolls: `col = $52 − $26`.** It only *appeared* fixed here
>   because this trace observed it during the `$52`=`$30` hold (the climb), where `col` is constant at
>   `$0A`; when `$52` sweeps, the cliff translates 1:1. Only **Fuji (`$A9`, hardcoded)** is genuinely
>   `$52`-independent. (So "the scroll is the scene-sprite group only, not the backdrop" below is wrong:
>   the mid-ground scrolls too, at `$52 − offset`.)
> - **The `$52`=`$30` hold is the CLIMB, not a walk dead-band.** Jay's eye confirms there is **no walk
>   dead-band** — the scroll starts with the player's forward move (the `$52` sweep).
> **Settled:** `$52` is the **GLOBAL scene scroll** (mid-ground `$52 − offset` + scene-sprite `$52 + xadj`;
> Fuji fixed). The sweep starts f6455, ~32 frames **before** the guard draws (f6487) — scroll-before-guard,
> matching Jay's eye. The mism=0 locked-group table + the causal-pin result below stand; the layer
> classification and the "dead-band" framing are corrected as above.

**Classification: TRUE — `$52` is the WALK-DRIVEN scroll driver.** A locked-group translation
(`X = $52 ± xadj[i]`, verified mism=0), with a **dead-band** (`$52` held at `$30` through the
climb until `$62` crosses `$0F`), the **upper backdrop fixed**, and the walk **causally drives
it** (pin `$62` ⇒ `$52` freezes, scroll never starts). Established by execution on the oracle
apple2e attract, reproduced ×2 byte-identically (seed-deterministic). **STOP at the
classification; nothing built.**

## Mechanism (attract_dispatch.s `load_scene_sprite_ae3f` — provisional labels, past scene 4)
Four 18-entry parallel tables (dumped from **live memory** `$ADF7–$AE3E`, authority over the `.s`):
```
lo  ($ADF7): 84 8A 7B A6 C0 D4 EF 03 07 63 D1 2B 57 5F 65 1A 00 77
hi  ($AE09): A6 A6 A8 A6 A6 A6 A6 A7 A7 A7 A7 A8 A8 A8 A8 AC 80 A8
xadj($AE1B): 07 02 01 03 04 06 09 09 07 01 02 04 06 02 02 09 00 02
y   ($AE2D): 42 6F 99 9F A5 AB 99 42 1E 42 37 30 2A 54 68 68 00 6F
```
Per sprite X: addr = hi:lo, row `$06 = y[X]`, and **col `$05 = ($52 ≥ $14) ? $52 + xadj[X]  (normal L1903)
: $52 − xadj[X]  (mirror L190C)`**. `draw_scene_ae7a` guards `$52` to the `$14..$28` band (≥$29 ⇒
out-of-range, draw suppressed). *(NB the dispatch's "`xadj $ADF7–$AE3E`" is the whole 4-table block;
the xadj sub-table specifically is `$AE1B–$AE2C`.)*

## Baseline (clean recipe `-video none -sound none`, reproduced ×2 — identical, seed-deterministic)
`scroll_trace.lua` (frame-notifier ZP reads + `$1903/06/09/0C` trampoline read-taps — these DO fire, §7b):

**(1) `$52` changes + (3) dead-band.** `$52 = $30` held from **f3897 through f6448** while `$62`
climbed `0B→0C→0D→0F` — the player advances the whole climb and **the scroll holds** (dead-band,
~2550 frames). `$52` releases only when `$62` crosses `$0F`: at **f6455** `$52` `30→2F` (`$62`=11),
then **sweeps `30→1B`** (f6455–6786), tracking `$72` (52==72 f6455–6657). A plain 1:1 scroll would
have no such hold — the dead-band is the distinctive signature.

**(2) Locked-group `X = $52 ± xadj[i]` — CONFIRMED, all 16 scene-sprite cels, mism=0 over ~5000 draws.**
Spot-check (≥3 required; all 16 verified):

| cel | X | xadj | observed col range | `$52` range | check |
|---|---|---|---|---|---|
| `$A684` | 0 | 07 | 22–2F | 1B–28 | 1B+7=22 ✓, 28+7=2F ✓ |
| `$A68A` | 1 | 02 | 1D–2A | 1B–28 | 1B+2=1D ✓, 28+2=2A ✓ |
| `$A703` | 7 | 09 | 24–31 | 1B–28 | 1B+9=24 ✓, 28+9=31 ✓ |
| `$A857` | 12 | 06 | 21–2E | 1B–28 | 1B+6=21 ✓, 28+6=2E ✓ |

**Zero mismatches** across every table cel — the lower scenery translates as one locked group, each
element at its own `xadj`.

**(4) Upper backdrop fixed — CONFIRMED by contrast.** Non-table cels stay **col-fixed** while the
group scrolls: `$A9B8` col=`0F`, `$A9E2` col=`0C`, `$AB4A` col=`00` — all constant across `$52`
`1B–30` (they render via a different path, never reading `$52`). The climb cliff (`$AB8E`) is
likewise fixed. So the scroll is the scene-sprite group only, not the backdrop.

## (5) Causal — the walk drives it (per-frame FORCE `$62`=05, reproduced ×2)
Pinning `$62` below `$0F` (per-frame force, so the walk never completes — a write-tap re-clamp fails,
§4f):
- `$52` **held at `$30` the entire window** (f3897–7200); `$72` frozen at `$30`.
- The scene-sprite scroll group **NEVER draws** (`X=…` draws = **0**; `$52`=$30 ≥ $29 ⇒
  `draw_scene_ae7a` suppressed) — vs baseline's ~5000 group draws sweeping col with `$52`.

⇒ **Suppressing the walk freezes the scroll.** `$52` is walk-driven through the `$62 → $72 → $52`
chain: the walk reaching `$0F` releases the dead-band and drives `$72`'s approach, and the scroll
`$52` is locked to `$72`. Pinning `$62` freezes `$72` (walk-guard finding) **and** `$52`.
**TRUE — walk-driven, locked-group, with a dead-band, upper fixed.**

## Provenance / caveats (past scene 4)
- Labels (`$52`=scroll, `$62`=walk, `$72`=guard-pos, the `xadj` table) are **provisional**; the
  **results hold regardless of label**: the ZP the scene-sprite loader reads (`$52`), pinned via the
  `$62` chain, deterministically freezes the scenery group, and the locked-group compute
  (`col = $52 ± xadj`, mism=0) is execution-verified.
- Immediate driver of the scroll is `$72` (52 tracks 72 in the sweep); the **walk (`$62`) is the
  upstream cause** — the causal pin (freeze `$62` ⇒ freeze `$52`) is what makes it walk-driven, not
  the correlation.
- **Jay's model overrides the trace** if they disagree — this matches his Part II.7 (player walk drives
  a locked-group scroll with a dead-band, upper fixed).

## The fork (this dispatch's whole output)
**TRUE ⇒ the walk build (fight-order step 2) reproduces exactly this mechanic:** a `$52` scroll byte,
the scene-sprite group at `col = $52 ± xadj[i]` (17-entry table + the `$14`/`$28` band + mirror-below-`$14`),
a dead-band holding `$52` through the climb until the walk crosses the release point, and a fixed
backdrop. **Report only — STOPPED at the classification; nothing built.**

*Evidence logs (reproducible byte-identically from `scroll_trace.lua` at seed-fixed boot):
`scratchpad/scroll/scroll_baseline.txt`, `scroll_pin05.txt` (+ `/rep` replays).*
