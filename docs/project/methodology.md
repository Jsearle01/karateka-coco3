# Project Methodology Notes

This document captures methodology rules empirically established during
karateka-coco3 development. Rules here have been learned from actual
failures; they should survive session boundaries.

Provenance: P2.3a.6 closure Phase 2 retrospective (2026-05-17).

---

## Color verification

### The screenshot ≠ live display constraint

MAME's Lua `screen:snapshot()` does NOT faithfully capture palette-mapped
live display output for CoCo3 GIME 4-color graphics mode. The PNG captures
something earlier in the rendering pipeline — either raw indexed pixels or
pre-palette output. The live MAME window shows palette-mapped colors that
the PNG does not reflect.

**Empirical basis:** During P2.3a.6, multiple diagnostic cycles produced
wrong color claims by analyzing screenshots. The same binary running in the
same MAME session produced screenshots that Clyde analyzed as "2 colors"
while Jay's live observation confirmed "4 colors." File size comparisons
between runs also failed to correlate with actual visual change.

This constraint applies to all CoCo3 GIME 4-color (2bpp) mode tests. It
may or may not apply to text mode or other GIME modes — those have not been
tested.

### Verification roles

**Clyde (Claude Code) can verify autonomously:**
- Binary byte content (assembler output, `xxd`)
- Register values written by code (static analysis of FCB/STA sequences)
- Sprite pixel-index distribution (decode 2bpp bytes from .s files)
- Framebuffer address, VOFFSET value, HAL control flow
- Whether binary is freshly built from current source
- Log file messages, frame numbers, exec addresses, harness flow
- Framebuffer memory dumps: per-index pixel counts, position distributions

**Jay verifies (live MAME observation only):**
- What colors appear on the live MAME display
- Whether a remediation produced the intended visual result
- Logo positioning correctness
- Anything requiring direct visual perception

**Combined verdict structure:**
- Color-related verdict claims → Jay's live observation, never Clyde's
  screenshot analysis
- Structural verdict claims → Clyde's reports
- Combined claims → both layers, each with its source stated explicitly

### Forward-looking rules

**Rule 1 — No color identification from screenshots.**
`screen:snapshot()` PNG output is documentation only. Color claims come
from Jay's verbatim live observation OR from framebuffer dump + decode
combined with Jay's confirmation that rendered indices match expected visual
colors.

**Rule 2 — Live observation gate before "no visual change" conclusions.**
A remediation is not "no effect" based on screenshot comparison alone. The
correct conclusion from identical screenshot content or file sizes is:
"screenshots are inconclusive; live observation required." File as
UNVERIFIED until Jay observes.

**Rule 3 — Harness scripts and binary source must update together.**
When palette values, conventions, or addresses change, update all of these
simultaneously:
- The `.s` source file
- Shell script `echo` statements describing what is being tested
- Lua harness log messages describing palette values
- Inline HAL copy comment headers in test drivers

Stale comments in harness output create documentation–reality gaps that
corrupt inter-report analysis. (Pattern: `stale-harness-comment-conflates-values`)

**Rule 4 — Inline HAL copy changes require a declaration in commit messages.**
Test drivers embed inline copies of HAL routines with the note "Any changes
to production sources must be mirrored here." Any change to production
`gfx.s` or `sys.s` that affects a test driver must list which inline copies
were updated and in which files in the commit message. Makes synchronization
auditable from git history.

**Rule 5 — Structural vs visual claim labeling.**
Reports must clearly label which claims are structural (Clyde-verifiable:
byte content, register values, framebuffer dumps) and which are visual
(Jay-only: live display color identification). Do not blend the two.

---

## Framebuffer dump as canonical input signal

Per-task tooling: framebuffer memory dumps captured via the harness provide
Clyde a reliable color-adjacent signal that doesn't depend on screenshot
fidelity.

**What a framebuffer dump answers:**
"What 2bpp pixel-index bytes are present in the framebuffer at render time?"

**What a framebuffer dump does NOT answer:**
"What colors do those indices produce visually on screen?"

**Combined verification pattern:**
Given a known-correct palette descriptor confirmed once by Jay's live
observation:

1. Jay confirms live: "palette descriptor 0 produces orange at index-1,
   blue at index-2, white at index-3" (one-time confirmation per descriptor)
2. Subsequent runs: framebuffer dump shows N index-1 pixels at rows R
3. Conclusion: "framebuffer has N orange pixels at rows R per confirmed
   descriptor 0" — structural conclusion, no further live observation needed

This makes the framebuffer dump the canonical input-side verification for
all subsequent runs. Sprite blit correctness, HAL routing, and palette
descriptor integrity can all be verified structurally from dumps.

**Tooling:**
- `tools/lib/framebuffer_dump.lua` — MAME Lua helper; staged by run_*.sh
  to `C:\karateka-capture\tools\lib\`; called from each harness script
  after `screen:snapshot()`
- `tools/decode_framebuffer.py` — decodes 15360-byte Frame A/B dump;
  reports overall index counts, per-row summary, optional ASCII art and
  region analysis

**Usage:**
```bash
# Run harness (dumps to build/):
./tests/scripted/run_broderbund_splash_test.sh

# Decode the dump:
python3 tools/decode_framebuffer.py build/broderbund_splash_shot001_frameA.bin
python3 tools/decode_framebuffer.py build/broderbund_splash_shot001_frameA.bin --ascii
python3 tools/decode_framebuffer.py build/broderbund_splash_shot001_frameA.bin \
    --region 72,26,100,62  # Logo region
```

---

## Verification chain template

For visual-output features, the verification template is:

| Layer | What | Who | Method |
|-------|------|-----|--------|
| 1. Static | Code does what we think | Clyde | source analysis |
| 2. Build | Binary contains intended instructions | Clyde | xxd, wc -c |
| 3. Execution | Binary runs without crash | Clyde | log messages, exit state |
| 4. Framebuffer | Bytes land at correct addresses with correct values | Clyde | framebuffer dump + decode |
| 5. Visual | Rendered output looks correct | Jay | live MAME observation |

Each layer can fail independently; each must be verified independently.
Skipping layer 4 means relying on layer 5 alone for input-output
verification. Skipping layer 5 means assuming framebuffer-to-display
mapping is what we think (the mistake that caused false negatives in
P2.3a.6).

---

## Methodology patterns

Patterns identified during P2.3a.6 retrospective, available for future
reference:

- `screenshot-not-live-display` — MAME Lua `screen:snapshot()` does not
  capture palette-mapped live display; screenshots cannot substitute for
  Jay's live observation for color identification.

- `stale-harness-comment-conflates-values` — Shell script echoes and Lua
  log comments not updated after source changes; harness output describes
  old values while binary uses new values; log cannot be trusted as
  confirmation of what the binary actually does.

- `inline-hal-copy-documentation-gap` — Test driver header comments retain
  pre-followup descriptions after inline code was updated; header and code
  are out of sync; readers of the report reach wrong conclusions from
  comments.

- `file-size-as-color-proxy` — PNG file size used as a proxy for color
  content; unreliable because (a) the snapshot doesn't capture live display
  and (b) PNG compression depends on content distribution, not just color
  count.

---

## Candidate pool capture (convention clause)

This is a standing executor instruction, active for all tasks going forward.
Karateka is a live feeder to the cross-project methodology candidate pool
(`methodology-candidate-pool`).

**Candidate capture (pool write-through).** When a methodology candidate is
identified during a task — a recurring practice, convention, correction, or
observation that might generalize — capture it to the cross-project candidate
pool in the same motion as noting it locally:

1. Write a fresh single-instance entry to
   `seeds/karateka/live/<iso8601>-<slug>.md` in the pool clone
   (`/mnt/c/Projects/methodology-candidate-pool`), conforming to the pool's
   `SCHEMA.md` (`source: live`, `status: open`, one `instance_history` element
   with `initiator` set faithfully — `unknown` if not determinable, `n/a` if
   who-initiated is irrelevant; never guessed). karateka's historical notes
   don't record initiator, so `unknown` is the honest default for past-style
   observations — that's correct, not a gap to fill.
2. Commit and **push fire-and-forget**: the push is non-blocking. If it fails,
   the task is **not** blocked and the verdict is **not** gated — the local note
   is the durable record; the pool catches up later.
3. Do **not** read or edit existing pool entries during a task. Always write a
   new `live/` row. Folding live rows with prior entries is the reconciler's
   read-time job. The count-to-3 trigger is advisory only — promotion is the
   reconciler's cross-project job, not the project's.

Capture at first instance (losslessness over cleanliness). If unsure whether a
finding generalizes, capture it with `scope_judgment: unsure` and let the
reconciler decide.

Full mechanism and schema: see `convention-clause.md` and `ONBOARDING.md` in
the pool repo.

**Report line (mandatory in all task reports).**

Every Form A and Form B report must include:

> **Candidate(s) captured this task:** bulleted list of pool slug(s) written to
> `seeds/karateka/live/` this task, or **"None."**

Karateka has no separate report template file; Form A/B structure follows
methodology v0.7 (`docs/project/claude-orchestrated-methodology-v0_7.md`). This line is
a karateka-specific addition to both forms, making captured candidates visible at
verdict time so an omission is caught.

**Who-initiated linkage (for faithful initiator field going forward).**

When a task involves a strategy shift — scope decision, investigation direction,
approach change — the report's "User interaction during task" section should state
who initiated it (executor-originated vs orchestrator-prompted). This is the
source for setting `initiator` faithfully in pool entries rather than defaulting
to `unknown`. karateka's history doesn't record initiator; `unknown` remains
correct for observations without a clear initiator record.

---

*Last updated: KAR-WIRE-CLAUSE (2026-05-31). Append new patterns as they are
identified; do not delete confirmed patterns.*
