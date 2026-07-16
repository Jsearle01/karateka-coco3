# Scene-6 wall post + rail — captured positions, geometry, flags (2026-07-15)

> ## ⚑ REVISION 3 — placement correction (2026-07-16): posts sub 1→**sub 0** (px 185→**184**), row 99→**101**
> Jay's live gate: "post 1px left + structure 2px down." **Premise-check (measured, not assumed):** the
> Rev-2 build was ALREADY at **sub 1 / px 185** (source + framebuffer agreed) — the dispatch's "still at
> sub 2 / px 186" was wrong; the sub-1 had landed. So "1px left" = **px 184 (sub 0)**, "2px down" = row
> **99→101**. **Applied + VERIFIED from the framebuffer (HS-2):** left post px **184**, right post px
> **268**; white lines rows **104 & 111**; black band **105–107**; structure rows 101–111. RMW table
> recomputed for sub 0 (Python from Jay's grid). Art frozen (`e5fbcb66`/`e703565b`), RMW-fill + pulled
> ledge/AB rails retained, `$AA7D` kept, backdrop untouched. Diff band rows 100–115 (row 100 = fallback's
> OLD post top row, removed), zero leak beyond. prod `88eba89`, fallback `2a8188fc` unchanged.
> **Idiom: measure the OBSERVED framebuffer value, never verdict placement on the intended value** — this
> dispatch existed because 3c2f65f was verdicted without a framebuffer measurement.
>
> ## ⚑ REVISION 2 — Jay's 11×7, row 99, sub 1 (2026-07-16). The 9×7/row-100/sub-2 below is superseded.
> **Art (Jay-confirmed):** 11 rows × 7 cols — `wwbbbbt ×3 / wwbbbbw / bbbbbbb ×3 / wwbbbbt ×3 / wwbbbbw`
> (3 sky / white / 3 black / 3 sky / white). **RAIL = post col 6 = `t,t,t,w,b,b,b,t,t,t,w`** (asserted).
> - **Decomposition re-asserted:** cols 0–5 no `t` → 6×11 opaque block; col 6 == rail. Still fills +
>   RMW, no mask, no new primitive.
> - **PLACEMENT ROW 99** (grows upward): upper white line stays **102**, black band stays **103–105**,
>   lower white line moves **108→109** (the only reading matching Jay's "lower line down exactly one").
> - **POSTS sub 2 → sub 1 → px 185 & 269** (bytes 46 & 67 unchanged; Jay's 1px-left off the side-by-side).
> - **Rail bands:** white screen rows **102 & 109**, black **103/104/105**; else sky. Built as direct
>   fills (middle bytes 48–67) + a Python-computed **table-driven RMW** for the sub-byte post/rail-connect
>   edge bytes (46,47,67,68) across rows 99–109 — masks verified vs Jay's grid. `scene6_cliff_walltop.s`.
> - **Framebuffer-diff:** 293 bytes, all rows 99–115, **zero leak outside**. RMW/rail retained from Rev 1;
>   ledge (`$AA11`) + AB rails stay pulled; `$AA7D` stays; backdrop/fallback/prod unchanged.
> - **⚑ Exposed Fuji (ledge-removal consequence, Jay's gate):** at r108 bytes 48–49 the Fuji edge now
>   shows (it was under the pulled `$AA11` ledge) — PROVEN external (present with the wall-top draw
>   fully disabled), NOT a wall-top bug. Maskable if Jay dislikes it.
>
> ## ⚑ REGISTRATION FINDING — REPORT ONLY (+19 vs +20), NOT applied
> Jay read the post 1px left off the side-by-side. The mapping `CoCo3_px = Apple_px + 20`
> (`place(): x = col*7 + sh + 20`, `gen_scene6_cliff.py:56`) puts the oracle post (Apple col 23 sh 5 =
> Apple px 166) at **186**; Jay's eye says **185** ⇒ the centering offset may be **+19**.
> **Blast radius = the whole port:** the same `+20` `place()` registers *every* converted cel —
> `gen_scene6_cliff.py` (cliff/scenery), `gen_climb_anim.py` (crawl poses), and the deferred combatants
> would inherit it. **NOT changed here** — this build hardcodes **sub 1 for the two posts only**. A global
> +19 correction moves every gated element 1px and is its own separately-gated dispatch. **STOP-and-report.**


> ## ⚠ SUPERSEDED BY JAY'S 9×7 REVISION (2026-07-16) — see below; the 4×8 / G=80 / W=8 are void
> Jay re-authored the post to **9 rows × 7 cols** (`wwbbbbt`×2, `wwbbbbw`, `bbbbbbb`×3, `wwbbbbt`×2,
> `wwbbbbw`). **RAIL = post col 6** (`t,t,w,b,b,b,t,t,w`). This **designs out** the masked-composite
> primitive:
> - **DECOMPOSITION (asserted):** cols 0–5 contain NO `t` → a **6×9 FULLY OPAQUE block** (no mask);
>   col 6 == the rail column → **direct row-fills**, not a tiled cel. ⇒ wall-top = **5 rail fills +
>   2 opaque blocks**. **No per-pixel mask, no tiling, no W, no G — the 4×8/G=80/W=8 below are VOID.**
> - **PHASE 0 (code-quoted):** `HAL_gfx_blit_sprite_opaque` **supports sub-byte shift 0–3** — it sets
>   `blit_opaque` then falls into the SHARED `blit_have_mode`→`blit_dispatch`→`blit_do_sb0..sb3`
>   (opaque table → store the shifted byte verbatim). **No new primitive needed.**
> - **PLACEMENT (built as `scene6_cliff_walltop.s` + `scene6_climb_crawl_driver_walltop.s`):** drop the
>   spurious col-11 post; **2 opaque 6×9 blocks** (`content/scenery/scene6_wall_post`) at **byte 46 &
>   67, sub 2 (px 186 & 270), row 100** via `HAL_gfx_blit_sprite_opaque`; **rail fills** white rows
>   102 & 108, black rows 103/104/105, bytes 48–67 (px 192–271); AB rails + AA7D + start-pose
>   byte-identical. **Framebuffer-diff:** 164 bytes differ, ALL within rows 100–111, byte-cols 24–69;
>   **zero leak outside the band** (HS-8 OK).
> - **§9a NUB FIXED (2026-07-16, Jay: "render cleanly"):** replaced the opaque-shift blit with
>   **direct RMW fills** — each post's left byte is `(byte & $F0) | nibble` (nibble = `$0F` white rows
>   / `$00` black rows), preserving the upper 2px (px 184–185 = sky left of post-2; px 268–269 = rail
>   left of post-3); right byte = `$00`. NO shifted-in black nub, exact sub-2 position, correct
>   background at both partial edges (which a single pre-shifted sky-edge sprite could NOT do — post-2's
>   left neighbour is sky, post-3's is the rail). Framebuffer-diff still clean (151 bytes, all rows
>   100–111, zero leak). The post/rail are now pure fills — no sprite blit, no `scene6_wall_post`
>   include in the driver.
> - **RAIL EXTENT `[I]`:** span taken as between the placed posts (px 192–269); whether the rail
>   continues past the outer posts is a single-sample assumption — verify when scroll reveals more.


**Type:** authoring-pass record (art + geometry; NO placement — next dispatch). Prod `88eba89…`
untouched; authored content `content/scenery/scene6_wall_{post,rail}/` stays UNTRACKED until Jay's
visual gate. Generator: `harness/tools/gen_wall_post_rail.py` (rail derived from post col 3).

## Captured reference positions (HS-2 — the geometry reference; do NOT delete)
From the fallback `tests/scripted/scene6_cliff.s` wall-top tables (git-tracked → any future
removal is reversible via git):
| post | back layer (AA31) byte | front layer (AA23) byte | sub | row | front px (byte*4) |
|---|---|---|---|---|---|
| 1 | 24 | 25 | 0 | 100 | 100 |
| 2 | 45 | 46 | 0 | 100 | 184 |
| 3 | 66 | 67 | 0 | 100 | 268 |
Uniform pitch = **21 bytes = 84 px**. All three byte-aligned (sub 0).

## HS-3 — `sub` IS the sub-byte offset (arbitrary pixel X; no HAL change)
`gfx.s` §P2.4.1 `HAL_gfx_blit_sprite`: `blit_subbyte` 0–3 → 0/2/4/6-bit right shift = **0–3 px**
sub-byte placement. So the engine already places at any pixel X. **F1 not triggered.**

## HS-4 — post-1 X diagnosis (report, not fix) → **F3: no post-1-specific source**
All three posts derive **identically** from `gen_scene6_cliff.py` `SCENERY` (AA23/AA31 at Apple
cols `0x0B,0x17,0x23`, `sh=2`, byte-aligned via `place()`+`leading_trim`). There is **no distinct
source or error for post 1** vs posts 2/3 — they share one formula, one `sub` (0), one cel, uniform
21-byte pitch. So the reported "post 1 ~2px left of oracle" is **not** a per-post data error. What
the recon (`walltop-render-map.md`) actually shows: the **oracle draws only TWO posts** (Apple cols
23 & 35, sub-byte shift 5 → CoCo3 **sub 2**); the port's **col-11 post (post 1) is SPURIOUS** (not
in the oracle at all), and **all three** port posts are byte-aligned (sub 0) = a **uniform ~2 px**
left of the oracle's sub-2 positions — not a post-1 singleton. **Implication for placement:** the
fix is (a) drop the spurious post-1 and (b) apply sub 2 to the real posts — a uniform correction,
not a per-post hunt. (This matches the earlier `4b27dd8` wall-top delta finding.)

## HS-5/HS-6 — the gap geometry (for Jay's W choice)
Computed from **posts 2 & 3 only** (post 1 excluded per HS-4). Post width = 4 px.
- **G = X3 − (X2 + 4) = 268 − (184 + 4) = 80 px = 20 bytes.** (Invariant to the sub-align question:
  pitch is 84 px whether byte-aligned or oracle-sub-2, so G = 84 − 4 = 80 either way.)
- **Divisors of 80 (candidate rail-tile widths W):** 1, 2, 4, 5, 8, 10, 16, 20, 40, 80.
- **Byte-aligned (W % 4 == 0, no per-blit shift cost):** 4, 8, 16, 20, 40, 80.
- **Multi-segment byte-aligned (exclude W=80 = single span, HS-6):** **4, 8, 16, 20, 40**
  (→ 20 / 10 / 5 / 4 / 2 segments respectively).
- **F2 not triggered** — 80 is highly composite.
- **W is Jay's choice** (scroll-reveal granularity vs blit count). Sub-byte options (5,10 = 2/1 bytes
  + shift; 1,2 = fine but many blits) available if he wants finer reveal.
- **✅ JAY'S PICK (2026-07-15): W = 8 px (2 bytes) → 10 segments across G=80.** Byte-aligned (no
  sub-byte shift cost). **Recorded only — NOT built/placed here** (placement dispatch input).

## HS-7 — the gap is `[I]` (single sample)
Only **one** complete post-to-post span exists in the data (posts 2→3). "Uniform 84-px pitch /
G=80" is an **assumption from one sample** (posts 2/3 matching the oracle is the best evidence
available — accepted, but not a measurement of universality). **Verify the pitch holds when
scrolling reveals more posts;** if it drifts, rail sizing revisits.

## HS-8 — mask path: existing `_masked` is PER-COLUMN; the post needs PER-PIXEL ⚠ FLAG
The post's col 3 is `t,t,w,b,b,t,t,w` — transparency **varies by row**. `HAL_gfx_blit_sprite_masked`
reloads its mask pointer **every row** (`gfx.s:857 ldu <emask_ptr` at `emask_row`) → it is a
**per-COLUMN** mask (same mask byte every row), which **cannot** express per-row-varying
transparency. And the palette trick (b=nonzero-black index, t=0, plain transparent blit) fails: all
4 indices are already used (0 blk / 1 orange / 2 blue / 3 white), so there's no free index to make
"opaque black" distinct from "transparent black." **So a per-PIXEL 2D mask is genuinely required.**
The authored masks here ARE per-pixel/2D (like `HAL_gfx_blit_stencil_punch`'s format, width×height,
advancing continuously) — but `stencil_punch` *punches to black*, it doesn't *composite* a colored
source. **PLACEMENT-DISPATCH ITEM:** a per-pixel masked COMPOSITE blit is needed (either a small new
leaf `(dest AND ~mask) OR source` walking a 2D mask, or reuse `stencil_punch` to clear then a
transparent blit to fill — TBD). **Authoring is unaffected**; this only affects how the next
(placement) dispatch renders it. Flagged, not silently refactored (no HAL change this pass).

## PRIMITIVE RECONCILE (2026-07-16, code-quoted) — the story flipped 3×; here's the truth
The three claims are **different capabilities on different code paths, NOT contradictions**:
- **(ii) `HAL_gfx_blit_sprite`** — transparency is **INDEX-0-KEYED**: per output byte the mask comes
  from `blit_trans_table[source_byte]` (`gfx.s:532/566/614 lda b,u`; comment `gfx.s:512` "11 per
  non-black pixel pair, 00 per black"), and it DOES sub-byte shift 0–3 (`blit_do_sb0..sb3`). So:
  **per-pixel transparency keyed on source=black, + sub-byte shift.** It CANNOT render an
  **opaque-black** pixel (a `b`=index-0 pixel is keyed transparent). It built the converted-cel delta
  fine only because those cels' black WAS transparent.
- **(iii) `HAL_gfx_blit_sprite_masked`** — takes a **separate** mask array `U`, but **reloads it
  every row** (`gfx.s:857` at `emask_row`) → **per-COLUMN** (same mask each row) and **byte-aligned
  only** (`gfx.s:819`). So: separate mask (can express opaque-black) BUT no per-row variation, no shift.
- **The authored post needs BOTH**: a **separate per-pixel mask** (b=0 opaque vs t=0 transparent —
  both index 0, no free palette index to split them) AND **sub-byte shift** (placement sub 2).
  **Neither path provides both** → a **per-pixel masked COMPOSITE blit WITH sub-byte shift** is
  genuinely required. (i) was right (gap), (ii) right for converted cels, (iii) right for authored art.

## PLACEMENT PLAN (for the focused placement dispatch — NOT built here; HS-2/F1 = substantial)
Two findings that de-risk it:
1. **The RAIL needs NO mask.** Tiled W=8×10, every column is identical (`t,t,w,b,b,t,t,w`), so the
   80-px gap is just **horizontal bands**: white at rows 102 & 107, black at rows 103–104,
   transparent elsewhere — direct fills (like the striations). Only the **2 POSTS** need masking.
2. **A NO-NEW-PRIMITIVE 2-pass path exists** for each post (avoids the substantial shift-masked
   primitive): pre-shift the frozen art to sub-2 (build-time transform, pixels preserved,
   `authored.s` untouched) → **Pass 1** byte-aligned `HAL_gfx_blit_sprite` (transparent) of the
   white plane draws `w`; **Pass 2** byte-aligned `HAL_gfx_blit_stencil_punch` of the `b`-mask forces
   black at `b` — both byte-aligned so they align; `t` untouched (background shows). Alternative =
   build the general per-pixel masked+shift composite (the deferred **Stage-4 combatant primitive**).
   **The placement dispatch picks + must framebuffer-diff + Jay live-gate.** Placement target
   (unchanged): drop the spurious col-11 post; posts at **bytes 46 & 67, sub 2, row 100**; rail bands
   across px 190–269.

## Authored art (single-sourced)
`POST` grid is the single source of truth in the generator; **`RAIL = [row[3] for row in POST]`**
(asserted) — the rail is post col 3, never authored twice (HS-1). Color plane: w=3 b=0 t=0;
per-pixel mask: 11=opaque (w,b), 00=transparent (t). Emitted:
`content/scenery/scene6_wall_{post,rail}/authored.s` (color plane + `_mask` plane).

Gate artifacts (external, for Jay): `build/wall_ref/wall_post_rail_sheet.png` (post + rail, magenta
= transparent) and `build/wall_ref/wall_composite_true_spacing.png` (two posts + rail at the TRUE
computed G=80, on sky bg so transparency reads as background-shows).
