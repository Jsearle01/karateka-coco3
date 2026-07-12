# Scene-6 draw-B mirror — scope determination `[2026-07-12]`

**Type:** SCOPE-DETERMINATION (read-only; no build, no code change). **Question:** the pre-build
inventory flagged draw-B (the guard's left-facing half of the 2×2 draw model) as the one BUILD gap
— **how big is it?** (a) a runtime pixel-mirror primitive, (b) position-math only (pre-mirrored /
palindromic cels), or (c) mixed. Determined by reading the oracle draw code + the mirror table.

**Ground truth:** oracle disassembly (`video.s`, `display_7700.s`, `gameplay_state_0b00.s`) +
**data-file authority** (`hires_rows.s`) — the load-bearing fact (the `$0900` table's contents)
was taken from the data file, NOT the video.s comment (which mislabeled it; see §1). Prod
`88eba89…` byte-identical (read-only).

---

## 1. The oracle mirror is a genuine RUNTIME PIXEL operation — possibility (a)

**draw-B = `$1909`/`$190C` → `routine_1af4`** (`video.s:69-71,536`). Three code facts settle it:

1. **Per-byte bit-reversal via the `$0900` table.** draw-B runs each sprite byte through
   `ora #$80 / tax / lda $0900,x` (`video.s:651-654,665-666,699-702`). The video.s header calls
   `$0900` a "screen-address lookup table" (l16,519) — **this comment is WRONG.** `hires_rows.s:18-21,
   122-123` (the data file that DEFINES it) states: **"pixel_flip ($0980-$09FF): 7-bit pixel
   bit-reversal table … lda $0900,x with X in $80-$FF … Entry at offset N: bit-reversal of (N & $7F),
   with bit 7 set."** So `$0900,x` bit-reverses the 7 pixel bits of a byte. *(CLAUDE.md §2: data-file
   authority over the comment — verified, not assumed.)*
2. **The caller reflects X + sets the sub-byte shift.** `draw_combatant_mirror` (`display_7700.s:322`):
   `lda #$26; sbc tbl_sprite_x_a,x; sta $05` (**X reflected around `$26`**) then `lda #$06; sta $10`
   (sub-byte shift; draw-B then computes `7-6 = 1`, `video.s:542-545`) then `jmp L190C` (draw-B).
   Contrast `draw_combatant_normal` (`:312`): `$10 = 0`, `jmp L1903` (draw-A).
3. **It applies to BOTH guard actors.** Guard **combat** cels: `draw_fight_scene_2` calls
   `draw_combatant_mirror` for the guard indices (`display_7700.s:360-362`). Guard **health arrows**:
   `gameplay_state_0b00.s:40,277` — the `$B7` (guard) count draws via `L1909` (draw-B), while the
   `$B6` (player) count draws via `L1903` (draw-A, `:204`).

**Verdict: (a).** The oracle mirror is a real per-pixel bit-reversal at draw time — NOT pre-mirrored
stored cels, NOT position-math only. draw-A vs draw-B is not "normal vs Y-offset"; draw-B additionally
**bit-reverses pixels** (plus a Y-scaling/clip path via the same `$0900` page).

## 2. Cel storage — ONE orientation, mirrored at runtime

Because the mirror is produced at runtime (§1), the oracle stores each actor in **one orientation**
and reflects the guard on the fly. There is no pre-mirrored guard cel to convert. So on the CoCo3
the pixel-reversal must be produced **somewhere in the port pipeline** — it is not free.

## 3. The arrow is NOT horizontally symmetric — corrects the inventory's "palindromic" claim

Arrow cel `$0B12` = `81 85 95 D5 95 85 81` (7 rows × 1 byte). That byte sequence is **vertically**
symmetric (row 0 = row 6, …) — NOT horizontally. Under the 7-bit pixel reversal (§1), only the
middle row is symmetric: `$81→$C0`, `$85→$D0`, `$95→$D4`, `$D5→$D5`. So a horizontal mirror **changes
the arrow's shape**, and the guard arrow (drawn via `$1909`, §1.3) **is pixel-mirrored** in the
oracle. → The prior inventory's "palindromic ⇒ position-math may suffice" was a misread (vertical vs
horizontal symmetry). The arrow needs the same treatment as the other guard actors.

## 4. Per-actor mirror-need table

| Actor | Oracle draw | Needs pixel-reversal? |
|---|---|---|
| Player body / combat cels | draw-A `$1903` (normal, `$10=0`) | **No** |
| Player health arrows (`$B6`) | draw-A `$1903` (`gameplay_state_0b00.s:204`) | **No** |
| Guard body / combat cels | draw-B `$190C` (`draw_combatant_mirror`, `$0900` flip + `$26−x`) | **Yes (a)** |
| Guard health arrows (`$B7`) | draw-B `$1909` (`gameplay_state_0b00.s:277`) | **Yes (a)** |

The scope = **every guard-side actor** (body, combat cels, arrows). Uniform, not mixed — all draw-B
users need the reversal; no draw-B user is horizontally symmetric enough to skip it.

## 5. Sizing — pixel-reversal is required, but it's a CONVERTER EXTEND, not a runtime HAL primitive

Pixel-reversal is genuinely needed (§1-4, so F2 "position-math only" is refuted). **But it need not be
a runtime HAL primitive** — the oracle mirrors at runtime only because the Apple II pipeline is online
(mirror on the fly, don't store both orientations in scarce RAM). **The CoCo3 port has an OFFLINE
converter**, so the mirror can be **baked at build time**:

- **RECOMMENDED — converter EXTEND (small).** Add `--mirror` to `harness/tools/sprite_convert.py`:
  reverse `row_indices` (the per-row pixel list) across the sprite width before the pack loop, emitting
  a **pre-mirrored CoCo3 cel**. The engine then draws it with the existing `HAL_gfx_blit_sprite` at the
  reflected X (`screen_ref − x`, the `$26−x` analog) — pure position-math, no runtime cost, no HAL
  change. Each guard actor gets a mirrored cel variant at convert time. *(The CoCo3 is 4 px/byte /
  2 bits per pixel, so the reversal is a pixel-field reorder across the row — done naturally by
  reversing `row_indices`, before packing, in Python.)*
- **ALTERNATIVE — runtime HAL primitive (larger).** `HAL_gfx_blit_sprite_mirror`: reverse the byte
  order across each row AND reverse the four 2-bit pixel fields within each byte (`p0↔p3, p1↔p2`) via
  a 256-byte pixel-reverse LUT (the CoCo3 analog of `$0900`) + sub-byte re-registration. Only worth it
  if the guard is ever mirrored **dynamically** at runtime (e.g. turning mid-fight). **Note:** this is
  NOT a plain bit-reverse — the CoCo3 packs 2-bit pixels, so the LUT reorders pixel fields, not bits.

**Whether the guard ever flips at RUNTIME (turns to face the other way mid-scene) decides between the
two** — a sandbox question. If the guard's facing is fixed for the scene (opponent always faces the
player), the converter pre-mirror (build-time) is sufficient and is the smaller scope.

## 6. Scope verdict (sequences Stage 4)

- The draw-B gap is **(a) a real pixel-reversal**, not position-math (F2 refuted) and not a per-actor
  mix (F3 refuted — uniform across guard-side).
- **BUT the build is a CONVERTER EXTEND (`--mirror`, bake at convert time) + engine position-math**,
  NOT a runtime HAL primitive — *provided* the guard's facing is static per scene (sandbox to
  confirm). A runtime `HAL_gfx_blit_sprite_mirror` is the fallback only if dynamic mid-scene flipping
  is required.
- This **downsizes** the inventory's "one BUILD gap (draw-B primitive)": the mechanism (pixel
  reversal) is real, but its cheapest correct home is the offline converter, not the HAL.

*Investigation only — not a build. The `--mirror` implementation is a later build dispatch this sizes.*
