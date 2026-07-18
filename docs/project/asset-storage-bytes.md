# Asset storage in BYTES — the figure that had never been produced (2026-07-18) — REPORT ONLY, arithmetic only, no recommendation

**All figures = ACTUAL ASSEMBLED DATA BYTES:** `2 + H*W` per cel (H = rows, W = coco3_width bytes/row,
from each cel's first `fcb H,W` line). Not `.s` text size, not counts.

## Total cel data by category (280 cels)
| category | cels | data bytes |
|---|---:|---:|
| player | 89 | 8,421 |
| guard | 69 | 5,879 |
| princess | 17 | 2,284 |
| scenery | 14 | 2,054 |
| title | 7 | 1,710 |
| background | 24 | 1,631 |
| floor | 8 | 1,499 |
| akuma | 14 | 1,463 |
| font | 27 | 794 |
| broderbund | 3 | 762 |
| bird | 3 | 78 |
| hud | 2 | 32 |
| unsorted | 2 | 32 |
| initial_palette | 1 | 2 |
| **GRAND TOTAL** | **280** | **26,641** |

## CROSS storage-doubling (in bytes)
The scene-6 converter emits a **shared/CROSS** cel (facing-trace has BOTH draw-A and draw-B) **twice** —
player variant (orange, no mirror) + guard variant (blue, `--mirror`) — `stage0_convert_scene6.py`.
From the converter's own manifest (`build/scene6-stage0-manifest.csv`, a shared ptr = appears in both a
player and a guard row): **42 distinct source ptrs → 84 output cels.** The **extra bytes from the second
variant = 3,702 B** (the 42 guard `--mirror` copies; the 42 player copies sum 3,709 B — the mirror trims
leading/trailing blank columns per-copy, so the two differ by ~7 B total). **≈ 3.70 KB, ~14 % of the
26,641 B total.** *(This doubling already exists in `content/` today — it is not the clean|fringed
doubling.)*

## 128KB headroom + does a SECOND full cel set fit? (arithmetic only)
Stock budget = **131,072 B**.
- **(a) prod code** = `build/karateka.bin` = **17,978 B** (confirmed).
- **(b) total cel data** = **26,641 B** (upper bound — see caveat).
- **(c) headroom now** = 131,072 − 17,978 − 26,641 = **86,453 B free.**
- **(d) second full set:** `(a) + 2·(b)` = 17,978 + 53,282 = **71,260 ≤ 131,072 → FITS**, with
  **59,812 B slack.**

**Caveat:** (b) sums ALL 280 `content/` cels on disk, including untracked scene-6 outputs/variants not
necessarily linked into the shipped 17,978-B build — so (b) is an **upper bound**; the true shipped cel
footprint is ≤ 26,641, which only **increases** the slack. **The fit conclusion is conservative. No
recommendation; 512KB is a gated Jay-only escalation, not assumed.**

## Size-parity fact (HS-B3) — confirmed
The bitmap is 2bpp (4 px/byte); transparency = index 0, a stored 2-bit value like any other. A **clean** cel
(body pixels, index-0 where fringe was) has the **same H and W → the same `2 + H*W`** as fringed — replacing
fringe indices with 0 changes stored VALUES, not row stride or row count. **⇒ a clean set saves ZERO
storage** (so the clean|fringed decision is a *look* decision, not a storage-saving one). Consistent with
the byte format.
