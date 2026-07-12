# Scene-6 pre-build inventory — what exists vs. what scene 6 needs `[2026-07-12]`

**Type:** REPO-INVENTORY (read-only; no build, no code change). **Purpose:** before sequencing the
scene-6 sandbox build, establish ground truth on what the repo already provides, so the build
**reuses** what's there and targets the **actual** gap. Two believed capabilities were treated as
**hypotheses** and verified against the real code (disassembled-inward): the converter's
color/parity, and the scene-5 animation engine. Deliverable = the **REUSE / EXTEND / BUILD** table
below, with file:line evidence.

Ground-truth basis: execution-independent **code read** of the live repo (this is a static
inventory of what exists, not a behavioural claim). Prod `karateka.bin` `88eba89…` byte-identical
(read-only).

---

## 1. Converter color / parity — REUSE the mechanism; the defect is a DATA gap, not a code gap

`harness/tools/sprite_convert.py`. **What it actually does:**
- Bakes hue from **`screen_col = start_col + local_col` parity** (l175, 182, 188): `bit7=1` +
  even→Blue(2), odd→Orange(1); adjacency→White(3); plus the color-cell fill for solid regions
  (l196-227).
- **Auto-derives parity from a supplied render column** — `--render-col-byte`/`--render-shift`
  compute `start_col = byte*7 + shift` (l279-299), the traced `$05`/`$10` from the `L1903` draw
  entry. This is the **principled fix**: parity is trace-sourced by construction, not fed blind.
- `--flip-parity` is a **swap-on-demand** manual override (l288-292) — an escape hatch, color-only.

**Classification of the capability (HS-2):** it is **(b) auto-derive-from-render-column**, IMPLEMENTED
— NOT merely swap-on-demand. The converter code **addresses** the known color-swap defect.

**But "capability exists" ≠ "defect fixed."** `docs/project/known-issues.md` (l7) is titled
**"RESOLVED (converter) / OPEN (per-candidate parity)."** The converter mechanism is resolved; what
is OPEN is the **input DATA** — each scene-6 cast sprite must be re-converted feeding its **traced
per-sprite render column** (`$05`/`$10`). The prior id-sheet pass fed blind `--start-col 0`, baking
wrong parity for odd-column actors. **The converter cannot pick parity blind** — the fix is inert
without the per-sprite render column.
→ **REUSE** the converter as-is; the remaining work is **BUILD (data): trace each scene-6 actor's
`$05`/`$10` at its L1903 draw entry and re-convert.** Not a code change.

---

## 2. Scene-5 animation engine — REUSE (shared-form, single-source)

`src/engine/sprite_engine.s` — the **single-source R-engine**. **What it actually handles (HS-3):**
- **Shared, not scene-5-specific (HS-3c = YES):** header l3-6 — "Data-driven… ONE generic render
  leaf + ONE frame-sequencer drive any character. **Scene 5, scene 6, and gameplay all call
  this**." The combat layer (hit detection / round manager / two-combatant interaction) is
  explicitly **INT-3, additive on top, NOT in the engine** (l6-8, 18-22).
- **Generic sequencer:** `eng_anim_init` / `eng_tick` / `eng_step` / `eng_render` (l50-131),
  cadence-driven frame advance + wrap, data-driven from a per-character animation table.
- **Render leaf delegates to the ONE primitive** `HAL_gfx_blit_sprite` (l114-125) — same primitive
  for static (scenes 1-4) and animated sprites.
- **Per-frame X positioning is structural (HS-3b):** each frame entry is 5 bytes
  `{fdb sprite_ptr; fcb byte_col, subbyte, row}` (l34, 103-123) — every frame carries its **own**
  byte-col AND sub-byte pixel shift (`blit_subbyte`, l121-122). State block equates in
  `globals.s:92-100` (`eng_tbl…eng_sub`, ZP $30-$3F).
- **Draw model (HS-3a):** the leaf is a port of oracle **draw-A** (`$1900` draw-A, l11-12) only.
  **draw-B (horizontal mirror) is NOT ported** — see §4.
- **Single-character today:** state block is "one character — **scales to a per-character struct
  array for multi-character scene 6 / combat**" (l37-38). Scene 6 (player + guard concurrent) needs
  that scale-up → **EXTEND** (§5).

---

## 3. Per-frame X-offset problem — SOLVED as a reusable METHOD; per-actor data is new

The converter **trims leading/trailing all-zero byte columns independently per frame**
(`sprite_convert.py:315-334`, reports `lead_stripped`/`trail_stripped`) → breaks shared
registration across an actor's frames (a multi-frame body lurches). **The princess hit this and it
is SOLVED** (HS-4):
- `src/engine/princess_controller.s:18-19` states the mechanism verbatim: "converter trims each
  frame's blanks independently → **per-frame X offset tables** re-align the body so it doesn't lurch
  between frames."
- Concrete **per-frame align tables**: `pr_leg_align: fcb 0,4,3,1,4` (l594-595),
  `pr_turn_align: fcb 0,-6,-7,-7` (l605-606, **signed**), `pr_fall_align: fcb 0,0,5,3` (l614-615).
  Applied as `lda pr_px; adda pr_tmp` (l499-500), where `pr_tmp` = `align[frame]`
  (`pr_pose_ptr`, l563-586).

**Status: SOLVED (method), not merely worked-around** — but the align values are **hand-measured
per actor** ("leftmost-white [0,6,7,7]px → align lefts to frame 0", l602/613). The converter's trim
report *could* feed the align table (an available EXTEND), but today it's by-eye.
→ **REUSE the method**; **BUILD per-actor align data** for every new multi-frame actor (the scene-6
guard 3-part composite re-hits the trim and needs its own table).

---

## 4. HAL blit surface — REUSE for compositing; draw-B MIRROR is a BUILD gap

`src/hal/coco3-dsk/gfx.s`. Present primitives:
- `HAL_gfx_blit_sprite` (l448, transparent, index-0 keyed) · `_opaque` (l441) · `_mixed` (l734) ·
  `_masked` (l824, per-COLUMN positional mask) · `_stencil_punch` (l888, per-PIXEL silhouette) ·
  `_scroll` (l957) · `HAL_gfx_present` (l334).
- The guard **3-part composite** maps onto the existing `_masked`/`_mixed` path (the scene-5 actor
  compositing pattern) → **REUSE**.

**draw-B horizontal MIRROR — MISSING (BUILD).** A grep for `mirror|flip|draw-b|reverse|1909|190C`
across all of `src/` returns nothing (only the buffer-*flip* toggle and unrelated comments). The
engine leaf is draw-A only (§2). Scene 6's guard uses the oracle **draw-B mirror** (`$1909`) for the
guard-side health arrows (`$0B7C`) and, if the guard reuses mirrored player combat cels, for
left-facing combat. **Caveat:** the arrow cel `$0B12` is **palindromic** (`81 85 95 D5 95 85 81`),
so the *arrows* may need only a mirrored **position**, not a pixel-flip; whether the guard **combat
cels** are stored pre-mirrored (no primitive needed) or require a true mirror blit is a **sandbox
question**. Classify draw-B as **BUILD (or confirm-unneeded in the sandbox).**

---

## 5. The gap — what scene 6 needs that scene 5 didn't (HS-5)

| Scene-6 need | Covered by existing? |
|---|---|
| Two combatants animating **concurrently** | **New** — engine is single-character; needs the per-character struct-array scale-up (l37-38) |
| Guard **3-part composite** (per-frame X-offset case) | Method reused (§3/§4 `_masked`); **new per-actor align data + cels** |
| Specific **combat cels** (110-cel action space) | **New** — no scene-6 sprite-data in `src/engine` (only princess `fig_*`) |
| Health-arrow draw path (`$0B35`/`$1903` player + `$0B7C`/`$1909` guard-mirror) | **New code**; draw-B mirror (§4) — position-mirror may suffice (palindromic cel) |
| **Event-driven** timing ($20 per-tick advance) | **New** — engine sequencer is cadence-cycle only; event timing is the combat layer (INT-3) |
| **Referee-mediated mechanics** (hit detection, round manager, distance) | **New** — explicitly INT-3, "NOT here" (`sprite_engine.s:6-8`) |

---

## 6. REUSE / EXTEND / BUILD table (the deliverable — sequences the sandbox build)

| Component | Class | Evidence |
|---|---|---|
| Frame sequencer + generic render leaf | **REUSE** | `sprite_engine.s:3-6,50-131`; "scene 5, 6, gameplay all call this" |
| Per-frame X positioning (byte-col + sub-byte) | **REUSE** | 5-byte frame entry `{fdb ptr; fcb col,sub,row}` `sprite_engine.s:34,103-123` |
| Per-frame X-offset registration (trim-lurch fix) | **REUSE method / BUILD per-actor data** | `princess_controller.s:18-19,499-500,594-615` align tables (hand-measured per actor) |
| HAL blit surface (transparent/opaque/masked/mixed/stencil) | **REUSE** | `gfx.s:441,448,734,824,888` — guard 3-part via `_masked`/`_mixed` |
| Converter color/parity mechanism | **REUSE** | `sprite_convert.py:175-188,279-299`; known-issues "RESOLVED (converter)" |
| Per-sprite parity **data** (the OPEN defect) | **BUILD (data)** | known-issues l7 "OPEN per-candidate parity"; trace each actor's `$05`/`$10`, re-convert — not a code change |
| draw-B horizontal **mirror** primitive | **BUILD** (or confirm-unneeded) | no mirror/draw-B anywhere in `src/`; leaf is draw-A only; arrow cel palindromic (position-mirror may suffice) |
| Multi-character state (2 combatants) | **EXTEND** | `sprite_engine.s:37-38` "scales to a per-character struct array" |
| Scene-6 cel **data** (guard 3-part, combat cels, arrows) | **BUILD** | no scene-6 sprite-data in `src/engine` (only princess `fig_*`) |
| Health-arrow draw path | **BUILD** | count-driven redraw-N; new code + data |
| Event-driven timing (per-tick $20) | **BUILD (combat layer)** | engine is cadence-cycle only; INT-3 |
| Referee-mediated mechanics | **BUILD (combat layer INT-3)** | `sprite_engine.s:6-8` "NOT here" |

**Net:** the **shared engine + HAL + converter are REUSE-ready**; the real build is (a) the **combat
layer** (INT-3: two-combatant interaction, referee, event timing — new), (b) **scene-6 cel data**
(convert + per-actor align + per-sprite traced parity), and (c) **one HAL primitive gap** (draw-B
mirror — or confirm the guard cels are stored pre-mirrored). No believed capability was found
missing; both believed capabilities EXIST but are **narrower than "covers scene 6"** in a
data-shaped way (converter parity needs per-sprite render columns; the X-offset method needs
per-actor align data).

*Inventory only — not a build sequence. The sandbox-build sequence is a later dispatch this informs.*
