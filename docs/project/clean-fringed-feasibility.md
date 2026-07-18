# clean|fringed feasibility — can the converter distinguish BODY from FRINGE-DERIVED? (2026-07-18) — REPORT ONLY, nothing implemented

## HS-C1 — the decode path (quoted) + the answer
Decode = `harness/tools/sprite_convert.py :: convert_sprite_to_coco3` (lines 141–261). Per row it pre-scans
with `_classify_row_convert` (returns, per ON pixel, `(pos_in_run, run_len, gap_before, pal_bit)`), then
assigns a 2-bit palette index via FOUR branches:
```
193  if run_len == 1:                              # ISOLATED -> chroma (blue/orange by parity)
198      row_indices[col] = (2 if parity else 1) if pal_bit==1 else 2
200  elif pos_in_run == 0 and gap == 1 and col>0:  # LEADING of adjacent run, gap 1:
205      row_indices[col-1] = chroma_idx           #   paint chroma at col-1 (a previously-OFF pixel)
206      row_indices[col]   = 3                     #   this ON pixel becomes WHITE (body)
209  else: row_indices[col] = 3                     # INTERIOR/TRAILING/leading-gap>=2 -> WHITE (body)
222-242  color-cell fill: a Black(0) flanked by the SAME chroma both sides -> filled with that chroma
                                                    #   (fills solid COLOURED regions, e.g. Akuma's robe)
```

**Answer: the classification is COMPUTED in the decode but NOT RETAINED — and the output index alone is
INSUFFICIENT to separate fringe from body.** The output is only the packed 2-bit index (0–3), and the
category→index map is many-to-one **across categories that need OPPOSITE treatment**:
- **index 1/2 (chroma)** is produced by (a) the **leading-edge artifact** at `col-1` (branch @205 — a pixel
  that was OFF, purely NTSC-derived = *fringe*), **and** (b) the **colour-cell fill** (branch @222 — a
  SOLID coloured **body**, e.g. Akuma's orange robe), **and** (c) isolated ON pixels (branch @198).
- **index 3 (white)** = body; **index 0** = off/transparent.

So you **cannot** derive `clean` by filtering the OUTPUT (e.g. "drop indices 1/2") — that erases solid
coloured **bodies**, not just edge fringe. Per HS-C1/F-C1: **`clean` is a CONVERTER CHANGE, not a flag on
existing output.** *Nuance (why it isn't a hard STOP):* the classifier need **not** be invented — the
decode's existing branch structure already separates the fringe mechanism (`@205` col-1 paint) from the
body (`@206/@209` white + `@222` colour-cell fill). The information EXISTS in the decode; it is discarded
at pack time. The required change is to **tag each pixel with its branch during the existing decode and
emit a second output** — a bounded converter change gated to Jay, not a new classifier.

## HS-C2 — proposed ONE-PASS / TWO-OUTPUT design (propose only — NOT implemented)
Convert **once, in the fringed coordinate frame.** During the existing per-pixel decode, tag each pixel
**body** vs **fringe-derived** from the branch it took. Then:
- **fringed output** = every pixel's colour (today's behaviour, unchanged).
- **clean output** = **body pixels at the same coordinates**, **transparent (index 0) at fringe coords.**

**Never two passes.** A separate clean pass re-runs `_classify_row_convert` **and the trailing
leading/trailing all-zero-column trim** (lines 351–370) independently. If clean removes a fringe pixel that
sat in the leftmost column, clean's leading-trim strips a **different** column count than fringed's →
clean's body starts at a different origin → **registration shift inside an identically-sized box** — the
exact "trims each frame's blanks independently" defect that broke the princess registration, on the fringe
axis. **Fix by construction:** derive geometry ONCE in fringed mode; clean **inherits fringed's L/R trim
counts** and never computes its own.

## HS-C3 — ⊇ vs REPLACE (finding)
- **Leading-edge fringe (@205):** `row_indices[col-1] = chroma` where `col-1` was OFF (Black 0) ⇒ fringe
  **ADDS** a colour at a previously-transparent coord ⇒ clean is transparent there ⇒ **fringed ⊇ clean
  holds** for this mechanism.
- **Colour-cell fill (@222):** ADDS chroma at an interior Black between same-chroma — but this is **BODY**
  (a solid colour cell), **kept** in clean. It ADDS, does not REPLACE, and must **not** be classified as
  fringe.
- **Isolated (@198):** colours an ON pixel (the bit is on) — its own colour, replaces nothing; body/fringe
  is **ambiguous** (a lone coloured dot). Needs a Jay ruling.
- **Fringing never REPLACES a body pixel's colour** (branch @205 sets the ON pixel to white-body and paints
  the *adjacent* off-pixel). So **the ⊇ model holds** — **but only if the classifier keys on the BRANCH
  (fringe = the `@205` leading-edge artifact), NOT on the output index** (which conflates fringe with the
  solid-colour body).

## HS-C4 — proposed pixel-level invariant (propose only)
> **`clean[x][y]` is transparent ⟺ `fringed[x][y]` is fringe-derived**, for **every** pixel; dims + origin
> **identical by construction** (clean inherits fringed's trim); **only colour indices differ** (fringe
> coords: chroma→transparent; body coords unchanged).

Stronger than a dims check — it catches the column-shift a dims-only assert would sail past.

## The load-bearing caveat for Jay (report, do not decide)
The intuitive model *"clean = remove the orange/blue, keep the white"* is **WRONG** — it deletes solid
coloured **bodies** (Akuma's orange robe, coloured HUD/title). The **output index does not distinguish
fringe-chroma from body-chroma; only the decode BRANCH does.** So `clean` mode requires the converter to
**retain the branch classification** (a converter change) **and a Jay ruling on the ambiguous categories** —
(i) isolated chroma: body or fringe? (ii) solid colour-cell bodies: kept as colour, or also cleaned? — per
sprite/category, since the *right* answer differs (a white knight's edge fringe should clean; Akuma's
orange robe should not). **Feasibility answer: FEASIBLE as a bounded one-pass/two-output converter change,
NOT a free output flag, and it needs Jay's definition of "fringe" per category before it's built.**

## MAME output mode (RGB vs composite) — the requested one-liner
The run invocation across the capture/palette tooling is `mame coco3 -rompath C:\mame\roms …` with **no
explicit monitor/RGB/composite flag** (e.g. `harness/tools/coco3_snap.lua`, `pal_sweep.lua`, my capture
runs) ⇒ **MAME's coco3 DEFAULT output.** The palette study's measured RGBs matched the **composite** decode
(bits5-4 intensity, bits3-0 hue), which is why it labelled itself "tuned-for = MAME composite" — but that
is an *inference from the sampled colours*, not an explicit `-composite`/RGB switch in the command. If the
RGB gate needs certainty, the monitor mode should be set explicitly (MAME coco3 machine-config monitor
type) rather than relied on as a default — flagged, not resolved here.
