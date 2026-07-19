# Scene-6 build backlog — durable to-dos (2026-07-19)

The in-repo home for scene-6 build to-dos so they don't live only in dispatch prose.

## 1. Climb-shadow correction (OPEN — hand-authored, by Jay's eye)
The climb-phase shadows need a hand-authored correction. The open question is **black
transparent vs opaque** — whether the shadow's black pixels should composite transparently
(let the background show) or opaquely (solid black). This is a **by-eye** call: Jay authors
the correction and gates the visual result (25.3-M); Clyde does not decide the shadow model
from a snapshot (PNG rules). Pending a dispatch + Jay's ruling.

## 2. Wall-top = RMW fills — SETTLED (fills stand; cel is Jay-optional)
**Settled 2026-07-19** (see `walltop-fills-provenance.md`). The 3-post wall-top is rendered as
hand-authored **RMW fills** (`scene6_cliff_walltop.s`), by a **deliberate** decision at `8b41733`
to **decompose the depiction to opaque-block + rail fills and avoid a masked sub-byte-shift blit
primitive** (posts sit at sub-byte px 98/183). It never was a cel.
- **In the walk scroll it already scrolls for ~0 extra/step** (it rides the strip band).
- A scrolling **cel** would cost ~3 ms/step (byte-aligned, sub-byte baked) or ~17 ms (runtime
  sub-byte blit — over VBL, the cost the fills avoid), **and** would lose the strip's fixed-px99-
  edge + overwrite-striations composite (re-solve per-cel). The only gain is tool-editability.
- **Disposition:** fills STAND. Converting to a tool-editable cel is a **Jay-optional** follow-up
  (worth it only if tool-editability is wanted enough to pay the cost + re-solve the composite).

## 3. AA23/AA31 superseded-cel hygiene (OPEN — content decision, Jay's call)
The `content/scenery/scene6_cliff_AA23` and `…_AA31` cels are an **older, superseded** wall-top
interpretation (the gated wall-top uses the RMW fills, which **pulled** them — `23d544e`). They
still exist and are still referenced by the **stage-3 static driver** (`scene6_cliff.s`) and the
early Stage-A cuts. Whether to remove them is a **content decision (Jay's call)** — they can't be
removed while stage-3-static references them. Options: (a) leave (harmless, used by stage-3);
(b) migrate stage-3-static off them then remove. **Leave-for-Jay.**

---
*Prod `88eba89…` byte-identical throughout scene-6 work (all scene-6 rendering is in sandbox
drivers, not the prod ROM).*
