# MAME coco3 `gime:artifacting` — located + classified (2026-07-18) — RECON, report only

## Located (HS-1, full `-listxml coco3` enumeration — not a grep)
Dumped the full XML (`build/mame_xml/coco3_listxml.xml`, 3931 lines, gitignored). The candidate, raw:
```
<configuration name="Artifacting" tag="gime:artifacting" mask="3">
    <confsetting name="Off"      value="0"/>
    <confsetting name="Standard" value="1" default="yes"/>
    <confsetting name="Reverse"  value="2"/>
</configuration>
```
Driver scope (HS-3): it is on the **coco3 GIME device** — the coco3 machine (`sourcefile="trs/coco3.cpp"`)
uses `device_ref name="gime_ntsc"`, and the config's tag is `gime:artifacting`. It is **distinct from the
CoCo1/2 VDG artifacting** (a separate `<configuration name="Artifacting" tag=":artifacting">` at line 1270,
on a different referenced device). The only other coco3 video config is **`Monitor Type`
(`screen_config`: Composite=0 default / RGB=1)** — found last dispatch. Full enumeration done; those two
are the only artifact/composite/monitor video configs at the coco3 level.

## Classification (HS-2/HS-4): **A — emulator composite-render model** (with stated confirmation limits)
**A (emulator composite-render model)**, not B (a real monitor-independent GIME register). Basis:
- **Config identity:** "Artifacting" with an **Off / Standard / Reverse phase** IS the classic composite
  **NTSC artifact-colour** model — artifact colour is an emergent property of the composite colour-carrier
  (the "Reverse" *phase* flip is inherently a composite-signal concept). The GIME chip has **no
  "artifacting" register**; it outputs composite + RGB simultaneously and artifacting lives only on the
  composite side. So this is MAME **modelling the composite artifact colours**, a rendering knob.
- **Behavioural cross-check (HS-4):** measured the same anim_02 climb frame across Monitor×Artifacting —
  under **RGB the render is invariant** to artifacting (Off == Standard), consistent with a composite-only
  model (A), inconsistent with a monitor-independent GIME mode (B).

**Confirmation limits — stated honestly (per §2A.4 paranoia):**
1. **No MAME source tree is present locally** (only the release binary), so I could not quote the `.cpp`
   locus that ties it to the composite/NTSC render path. The A call rests on config identity + behaviour,
   not a source read.
2. **I could not behaviourally *exercise* artifacting on this port's content** — because (below) it is a
   **no-op for Karateka**, so the composite-vs-RGB discriminator had no signal to distinguish A from a
   no-op. Confirming composite-only behaviourally would need a 1-bit/2-colour high-res test frame (out of
   scope: recon only, no build).
This is **not B and not architecturally ambiguous** (there is no such GIME register; it is the composite
artifact model) — so no STOP-and-surface-as-architecture is warranted (HS-6 not triggered).

## The load-bearing finding: it is a NO-OP for Karateka
Measured, same anim_02 frame (`gime_artifact_snapshot.lua`):
| Monitor | Artifacting Off / Standard / Reverse | blue $2D | orange $26 |
|---|---|---|---|
| Composite | **all three pixel-identical** | (54,179,247) | (245,115,58) |
| RGB | **both identical** (Off==Std) | (255,0,255) | (255,85,0) |

`gime:artifacting` changes **nothing** for this port, under either monitor. **Why:** Karateka renders in
the GIME **4-colour palette mode** (320×192×2bpp, real palette registers); artifacting only applies to the
**1-bit/2-colour high-res modes** where alternating pixels NTSC-artifact into colour. A palette-mode frame
has no artifacting to model. Render: `build/gime_artifact/gime_artifact_off_std_rev_x3.png` (three identical
composite panels).

## HS-7 — 25.3-H unchanged
Artifacting is an **emulator model**, not real silicon — 25.3-H is not closed either way. And since it is a
**no-op for our content**, it neither narrows nor affects the composite gap for Karateka: irrelevant, not
helpful. (The RGB side of the eventual clean-vs-fringed gate remains MAME-doable via Monitor Type=RGB; the
composite side's fidelity to real hardware still needs a CoCo3 — this flag does not change that.)

## Recon hygiene
No build/asset/converter/palette/pipeline change. Prod `88eba89…` byte-identical; fallback `1e4b608e…`
untouched; oracle read-only. XML dump gitignored.
