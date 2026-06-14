# FORM B — Completion Report (Operator-Directed Repository Restructure)

**Executor:** Clyde · **Operator/Gate:** Jay · **Date:** 2026-06-14
**Nature:** Out-of-band housekeeping directed live by Jay (not a formal DISPATCH).
Four sequential reorganizations, each gated and committed independently. Reported
so the orchestrator can fold the new conventions into future dispatch templates.

## Outcome: COMPLETE — 4 restructures, all builds verified, all pushed

| # | Restructure | Commit | Result |
|---|-------------|--------|--------|
| 1 | `content/` → category folders | `556f6af` | 112 flat dirs → 11 sprite categories + 7 left-flat; 53 tracked-file renames (history preserved) |
| 2 | Preview PNG dirs | `06ecff3` | `build/preview/` + `content/engine-previews/` regrouped to match content/ categories; durable generator `tools/gen_previews.sh` added |
| 3 | Log files → `build/logs/` | `490b33e` | 44 flat logs → `{engine,scenes,unit,snapshots}/`; 17 `run_*.sh` rewritten to route future logs there |
| 4 | `docs/` split | `436715d` | `ground-truth/` (11 PDFs + SockmasterGime) vs `project/` (22 authored .md); all cross-refs rewritten |

## New conventions the orchestrator must know (affect future dispatches)
- **Sprite includes** now carry a category segment:
  `include "../../content/<category>/<dir>/converted.s"` (e.g.
  `content/princess/fig_1D00/…`). Categories: akuma, princess, guard, bird,
  floor, scenery, player, unsorted (cast); title, font, broderbund (prod).
- **Test logs** now land in `build/logs/<area>/` — scripts `mkdir` and redirect
  there automatically (areas: engine, scenes, unit, snapshots).
- **Doc paths** are now `docs/ground-truth/…` or `docs/project/…`. The converter
  emits `docs/project/karateka-coco3-design-v0.1.md` in provenance.
- **Preview regen**: `bash tools/gen_previews.sh` (mirrors content/ layout).

## Verification
- **Build clean after every step**: prod boot **7359 B** (unchanged throughout),
  sandbox 5308 B, trace 1702 B — all reorgs proven purely organizational (lwasm
  resolves every moved include).
- All 17 rewritten test scripts pass `bash -n`.
- Every `docs/<file>` reference (README, docs, session-notes, tools, `.s` header
  comments) confirmed to carry its new subdir.

## Staging discipline (standing rules honored)
- Stage-by-explicit-path throughout; never `git add -A`.
- Scene-5 cast content stays **untracked** (WIP); preview/log dirs are gitignored
  (durable artifacts = the generator + script routing).
- The **4 untracked reference docs** and 11 PDFs moved on disk but were **not
  staged**.
- `captures/*.json` and pre-existing `harness/smoke` line-ending drift left
  unstaged.

## Open / follow-up
- `content/unsorted/` holds 4 still-unidentified sprites
  (`fig_18D0/1CC4/1CD4/8EC1`) — to be reclassified when identified.
- Cast colors gated PASS, but more color issues may surface as scene-5 is
  assembled (carried from the prior color-fix report).
- Two doc-classification judgment calls (SockmasterGime + pop-design →
  ground-truth; methodology/process docs → project) are reversible if the
  orchestrator prefers otherwise.
