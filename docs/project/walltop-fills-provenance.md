# Wall-top: why it's RMW fills, not a cel — provenance + cel-vs-fill cost (2026-07-19)

**Recon only.** Answers (A) how Jay's X/Y wall-top depiction became RMW fills, and (B) whether a
scrolling **cel** is cheap + worth it. Prod `88eba89…` byte-identical.

## PART A — provenance (FACT, from the commit trail): H-A TRUE (depiction → fills, never a cel)
The current 3-post wall-top went **directly from Jay's X/Y grid to RMW fills — it never was a cel.**
- **No wall-top post/rail cel ever existed** in history (`git log --all --diff-filter=A` on
  `content/**walltop*`/`AA27-AA30` = empty). No converter ever produced one.
- `scene6_cliff_walltop.s` (the fills) was **added at `8b41733`**, message verbatim: *"re-author to
  Jay 9x7 … decompose to opaque block + rail fills → **NO masked primitive** … idiom 11e (decompose
  to avoid masked primitive)."* Refined at `1bc84c1` *"render new posts CLEANLY as direct RMW fills."*
- **The reason (documented so it stops being a surprise):** the posts sit at **sub-byte** pixel
  columns (px 98/183/268 → byte 24.5 / 45.75 / 67.0; two of three are sub-byte). Rendering a
  sub-byte-positioned sprite the "normal" way needs a **masked sub-byte-shift blit primitive** the
  HAL didn't have. Rather than build that primitive, the design **decomposed** the depiction into an
  opaque block + direct row-fills (the hand-authored `wt_rmw`/`wt_bytes` tables) that bake the
  sub-byte pixels in. So RMW-fills was a **deliberate rendering choice to avoid a new primitive**, not
  an accident of conversion.
- Then ~15 per-Jay correction commits tuned geometry (posts px98/183/268, rail to px299, black wall,
  mirror post1, etc.) — all in the fills.

**The A3 wrinkle (drift, minor):** an OLDER, different wall-top used the `AA23`/`AA31` **cels**
(converted at stage-0 `7dc8d44`). The RMW re-author **PULLED** them (`23d544e`; crawl-driver comment
"old AA23/AA31 posts PULLED"). Those cels **still exist** in `content/scenery/` (used by the stage-3
static driver and the early Stage-A cuts, NOT by the gated wall-top). They are a *different, superseded*
interpretation — not the current design. Not urgent; note for a future content-hygiene pass.

## PART B — cel-vs-fill for the SCROLLING wall-top (cost, for Jay's decision)
**Key context the question half-assumed:** the wall-top **already scrolls** — in Stage A it's drawn
by `draw_climb_scenery_back` **before** the snapshot, so it's part of the strip band and slides for
**~0 extra per step** (it rides the amortized band copy, preserving its baked sub-byte positions since
the strip shifts by whole byte-columns). "Make it scroll" is not the driver; **tool-editability** is.

Cost of switching to a scrolling **cel** (blit at `col − shift` each step, wall-top = 51 B × 11 rows ≈
**561 bytes**), at CoCo3 1.79 MHz vs the tight Stage-A budget (blit frames ~10 ms; VBL 16.68 ms):
- **Byte-aligned cel, sub-byte baked in (subbyte 0):** ≈ 561 × ~10 cy ≈ **3.1 ms/step**. FITS (a blit
  frame → ~13 ms), and preserves the gated sub-byte look (baked into the cel pixels like the RMW).
  Cost is real but affordable.
- **"Clean" cel + runtime sub-byte blit (subbyte 2/3, to place px98/183 without baking):** ≈ 561 ×
  ~55 cy ≈ **17 ms/step → EXCEEDS the VBL.** This is *exactly* the masked-primitive cost idiom 11e
  decomposed the fills to avoid. Do not go here.
- **Composite semantics lost:** the wall-top's gated behaviors — the **fixed px99 black edge** and
  **overwrite-the-striations** — are **STRIP properties** (the `WALL_L` boundary + the fixed-left
  copy). A cel scrolls *entirely* (like `AA7D`); it has no fixed-edge/overwrite behavior. Going cel
  would **re-open** those layering fixes (each was a separate Jay gate) and re-solve them per-cel.

**Conversion cost (Clyde-effort) if Jay wants the cel:** convert the X/Y depiction → `converted.s`
(baking the sub-byte pixels), add a §2F registry + placement row, swap the RMW draw for a subbyte-0
cel blit at `col−shift`, and **re-solve the fixed-edge + overwrite composite** (the non-trivial part),
then re-gate visually. Moderate-to-heavy (the composite re-solve dominates).

## The call (Jay's)
- **Cost discriminator (measured/estimated):** fills = **0** extra/step; byte-aligned cel = **~3 ms**;
  sub-byte-blit cel = **~17 ms (over VBL)**. Fills win on cost.
- **Fidelity:** fills already deliver the gated sub-byte geometry AND the fixed-edge/overwrite
  composite. A cel keeps geometry (if baked) but **loses the composite** until re-solved.
- **Gain of cel:** tool-editability (the sprite tool edits cels, not fills) — the only advantage.
- **Recommendation to inform Jay (not a ruling):** fills are the cheaper *and* more faithful choice
  for the scrolling wall-top; the cel is worth it **only if** tool-editability is wanted enough to pay
  ~3 ms/step **and** re-do the composite. Unlike the static striations (fills clearly win), this
  scrolling case is genuinely a value judgment — but the cost/fidelity both favor fills. **Jay rules.**
