# Contamination Footprint Ledger — key-leak audit of prior oracle work

**Dispatch:** Contamination footprint audit · **Date:** 2026-07-13 · **Type:** READ-ONLY audit
**Prod ROM:** `88eba89b15cdf17c8d25e082d2d3e1f3cce57d38` (untouched).

## The contamination line (established `5d22e72`)
The oracle **snapshot** recipe leaked a host keystroke into the emulation and Karateka
disk-loaded the **actual game (fight)** instead of playing the **attract**. The defect is the
**run-mode**, so it partitions cleanly:

| Run-mode | Recipe | Key leak? | Verdict |
|---|---|---|---|
| **Trace / memory-dump** | `-video none` (no window; the stray `-window` in the recipe is a no-op under `-video none`) | none possible | **CLEAN** — stays in the attract |
| **Old snapshot (pre-`f7ca214`)** | `-window -nomax`, **no** `-video none` | host key → disk-load | **CONTAMINATED** — actual game |
| **New snapshot (post-`f7ca214`)** | `-keyboardprovider none` (+ `-video none` where no bitmap needed) | none possible | **CLEAN** |

Recipe-fix commits: `f7ca214` (root cause + `-keyboardprovider none`), `5d22e72` (real-climb
identity). **A clean tell:** seed `$59`=00 holds through the deterministic attract pre-fight;
`$59` ACTIVE (B9/AF) = RNG-live combat (attract-demo fight or actual game).

## Findings ledger
| # | Finding | Source type | Class | Clean re-verify (this audit) | Status | Action |
|---|---|---|---|---|---|---|
| 1 | Oracle ref set `scene6_climb_*` (climb tableau) | windowed snapshot | **CONTAMINATED** (actual-game fight) | real climb re-captured `5d22e72` → `scene6_climb_anim_00–06` | **REDONE** | keep anim set; originals retired to `_CONTAMINATED_KEY_LEAK/` |
| 2 | Ref set `scene6_summit_*` (f6108–6118) | windowed snapshot | **CONTAMINATED** (actual-game) | not separately re-shot; clean climb held-top = `anim_06` ($8ACB y124) | **NEEDS-REDO** (low) | re-capture clean only if a distinct summit beat is needed |
| 3 | Ref set `scene6_after_*` (f6150–7800) | windowed snapshot | **CONTAMINATED** (actual-game) | underlying walk/guard BEATS clean-verified via trace (row 4) | **IMAGES REDO / MECHANISM VALID** | re-capture clean if a visual ref is needed; the mechanism stands |
| 4 | Guard-entry treadmill `$B29D cmp #$0f` on player `$62` (`7fe25b6`) | code trace | **CLEAN** | **REPRODUCES in attract:** f6455 `$62`=11>`$0F`, `$72` 30→2F, treadmill `$62`~0F–13 / `$72`→20, `$33` 25→0D, `$59`=00 | **STILL VALID** | keep; annotate "clean-re-verified 2026-07-13" |
| 5 | HUD pitch = 10 Apple px/arrow (`sub_0b69`: `$10+=3` AND `$05+=1`) | code trace (+ `f7400` PNG cross-check) | **CLEAN mechanism** / contaminated cross-check | mechanism is code-invariant (same `$0B35`/`sub_0b69` in attract-demo & game); the `f7400` PNG citation is actual-game | **STILL VALID** | keep the pitch; flag the `f7400` pixel citation as contaminated but non-load-bearing |
| 6 | Stage-0 `dump05_imprison.bin` sprite provenance (princess `1D00–1DA2`, `fig_1DD7`) | binary MEMORY DUMP | **CLEAN** (RAM read, not a windowed capture) | n/a — no key-leak vector | **VALID** | keep (low-impact) |
| 7 | Other code traces (damage `$0BC1/$0BD2`, regen `$5B/$5C`, fight-control, bg-layers, cast-columns) | code trace (`-video none`) | **CLEAN** (code-invariant) | not individually re-run this pass (HS-4) | **NOT-YET-RE-VERIFIED** (low) | code-derived; re-run clean only if a specific one is challenged |

## Bottom line
- **Contaminated = the PNG snapshot sets only** (`scene6_climb_*/summit_*/after_*`) — they are
  actual-game footage. The climb is already redone; summit/after images need a clean re-shot
  *only if* a visual reference is required (their mechanisms are separately valid).
- **All CODE traces and the memory dump are CLEAN** — snapshots leaked keys, headless traces
  could not. The two high-impact code findings (guard-entry treadmill, HUD 10px pitch) both
  hold: the treadmill was clean-re-verified in the attract this pass; the pitch is code-invariant.
- **The `$A3C5/$AB`-is-fight retraction stands** (that was a contaminated-snapshot label).

## Provenance
Clean re-verify: `-video none -keyboardprovider none`, `guard_clean.lua`, my-boot f6400–6620,
seed `$59`=00 throughout (frames boot-relative — provenance only). Prod ROM byte-identical.
