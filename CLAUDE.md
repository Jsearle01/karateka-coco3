# CLAUDE.md — Karateka CoCo3 Port Project
## Working Agreement v1.0
**Date:** 2026-07-02
**Version:** 1.0

---

## 1. Project Bindings

- **25.1** = build.bat + run_*_test
- **25.3** = Jay's MAME visual gate only
- **Capture path** = seeds/karateka/

These bindings are fixed for the life of this project. Never substitute alternatives without explicit human authorization.

---

## 2. Ground Truth Hierarchy

When reasoning about program behavior, sources are ranked strictly in this order:

1. Execution traces — highest authority
2. Memory dumps
3. Observed runtime behavior
4. Disassembled instruction sequences
5. Comments — lowest authority; treat as unverified hypothesis only

**When sources conflict, traces and memory dumps always override comments without exception.**

Always state explicitly which source you are using and why before drawing any behavioral conclusion. Never default to comments as a shortcut over trace or dump analysis.

**When behavioral uncertainty exists about any code path, generating a fresh trace or memory dump is always the correct first action. Consulting disassembly or comments before exhausting dynamic verification options is not permitted. Do not proceed on comment-based assumptions when dynamic verification is possible.**

---

## 2A. MAME Instrumentation Reference Files (check every dispatch)

Two standing reference files at the repo root capture every MAME instrumentation quirk, gotcha, working command/Lua syntax, and the harness tool that exercises each case — so MAME idioms are **looked up, not rediscovered each dispatch**:

- **`mame-idioms-apple2e-oracle.md`** — the `apple2e` / 6502 oracle target (`karateka_dissasembly_claude`).
- **`mame-idioms-coco3-port.md`** — the `coco3` / 6809 port target (`karateka-coco3`).

Cross-cutting idioms appear in both files; `mame-idioms-addendum.md` is folded into both (provenance only).

**These are mandatory read points, not optional references:**

1. **At the start of any dispatch that touches MAME** (any trace, watchpoint, breakpoint, snapshot, boot, or gate), **read the file for the relevant target first** and apply the applicable idioms before writing instrumentation. The single most load-bearing difference: **6502 read-taps silently false-0 (opcode-fetch bypass); 6809 read-taps work** — getting this wrong reads as "the code never ran."
2. **During a dispatch, whenever you are about to exercise a MAME function you have not already confirmed this session** (a new debugger command, a `bpset`/`wpset`/tap form, `tracelog`/`trace` action, `natkeyboard:post`, `execution_state`, a speed/GIME/FDC poke, an image-build step), **check the file for the verified syntax and known gotchas before running it** — do not rediscover by trial and error what the file already records (e.g. headless `-debug` hangs without `execution_state="run"`; the frame-notifier/tap GC-reference gotcha; bp-action `tracelog` is brace-free while trace-action is braced; `-seconds_to_run` is emulated seconds; Windows paths need forward slashes in Lua).
3. **When you discover a new MAME idiom, gotcha, or working syntax during a dispatch, add it to the applicable file** (both files if cross-cutting) so it is not rediscovered next time. Surface the addition in the Form B report.
4. **When you are looking for MAME functionality that is NOT already in use (a mode, config, flag, or option the project hasn't exercised), you MUST do an EXHAUSTIVE search of MAME's command line and machine options before concluding it does not exist.** Enumerate the actual surfaces — `-showusage` (global options), **`-listxml <machine>`** for the driver's `configuration`/`dipswitch`/`slot`/`device` ports (NOT a guessed `-listconfig`, which is not a MAME command), and the in-machine config/DIP ports (settable from Lua via `field.user_value`) — not a keyword grep that stops at the first miss. **"I didn't find it" is only valid after the exhaustive enumeration**; a premature "MAME can't do X" is a reportable error (e.g. the coco3 "Monitor Type" Composite/RGB config was missed this way and had to be corrected). State which surfaces you searched.

The MAME idioms files are *how* to get the reliable execution evidence §2 requires — they never override the ground-truth hierarchy or the visual-gate rules (§4), they serve them.

---

## 2B. Asset Protection Catalog (check before ANY conversion)

**`docs/project/protection-catalog.md` is a mandatory read point before converting, re-converting, or overwriting any asset.** Before running the converter (or any bulk convert) over a path, **check the catalog to confirm the target is not flagged ALTERED or PROTECTED.** Re-running the converter over a hand-edited/authored asset silently destroys work that cannot be reproduced from the oracle. If a target is flagged (or is not listed and has no verifiable oracle source), **stop and get Jay's ruling before overwriting it** — never convert over a flagged/protected path on assumption. When the catalog changes (a new altered cel found, a protected item resolved), update `docs/project/protection-catalog.md` and surface it in the Form B report.

---

## 2C. Methodology candidate capture — WHERE candidates go (so the reference stops getting lost)

The candidate-self-capture clause writes to a **separate repo, NOT this one.** It silently no-op'd for several dispatches because dispatches searched `seeds/karateka/` *relative to karateka-coco3* (the wrong repo) and, finding nothing, rerouted candidates to inline MAME idioms — that was **lost-reference drift papered over by rerouting**, not a missing directory. The reference, recorded so it stays found:

- **The pool is the `methodology-candidate-pool` repo**, a **sibling of karateka-coco3**: local path **`C:/Projects/methodology-candidate-pool/`** (Git-Bash `/c/Projects/methodology-candidate-pool/`); remote **`https://github.com/Jsearle01/methodology-candidate-pool.git`**. Karateka candidates live in **`seeds/karateka/live/`**.
- **Capture at the FIRST instance** as a NEW row: `seeds/karateka/live/<iso8601-date>-<slug>.md`. **New rows only — NEVER read or edit existing pool entries** (folding `seed/` + `live/` is the reconciler's read-time job).
- **Row schema** (YAML frontmatter + a one-line `Source:` provenance): `principle` · `slug` · `project: karateka` · `source: live` · `status: open` · `scope_judgment: methodology` · `parked_at_version/settled_in/settled_note: absent` · `instance_count: 1` · `instance_history:` one element (`date`, `task`, `context`, `initiator` — set faithfully, e.g. `clyde`; never guessed) · `why_might_generalize` (link related rows with `[[slug]]`) · `proposed_disposition` · `provenance_complete: true`. Copy the shape from any existing `seeds/karateka/live/*.md`.
- **Commit + push fire-and-forget** — non-blocking; a failed push NEVER gates a task. Report the captured slug(s) in the Form B "Candidate(s) captured" line.
- **Credential (known tech-debt):** the pool remote currently carries an **embedded credential in the URL** — Jay is aware and has authorized using it as-is for now; it wants **credential-helper migration + token rotation**. **NEVER copy the token into CLAUDE.md, a row, or any tracked file.** `git push` uses the remote as configured; nothing more.
- **Fallback:** if the repo can't be found or reached, **STOP and ask Jay** — do **NOT** create a `seeds/` directory inside karateka-coco3 (a shadow pool is worse than a lost reference). A repeated capture no-op is a **reset signal to re-establish the reference, not a reason to reroute to inline.**

---

## 2D. Authored authoritative docs — the Orchestrator owns the CONTENT; Clyde owns the COMMIT

**Clyde does NOT edit the body of the authored authoritative docs directly** — the **decision record** (`docs/project/decision-record_colour-output-sprite-sets.md`) and the **post-mortems** (`docs/project/port-postmortem*.md`). Findings surface in Clyde's Form B reports; the **Orchestrator** folds them into the authoritative text; **Clyde commits** the Orchestrator-provided result. **Rationale:** the rich reasoning behind these docs lives in the Orchestrator's context, not Clyde's environment, so parallel edits diverge — this split happened **twice** with the decision record (the coupling finding was the last direct Clyde edit; it has been reconciled in). This fits the standing split: **Jay authors / the Orchestrator drafts / Clyde renders.**

- **Before overwriting one of these with an Orchestrator-provided file, run the SUPERSET DIFF-CHECK** (hard gate): confirm every substantive line of the in-repo copy is present in the provided file (verbatim or explicitly superseded). **If the in-repo copy has content the provided file lost, STOP and surface the delta** — do not overwrite a non-superset (that silently loses content).
- Recording a finding **in a Clyde report** is always fine; editing these doc bodies is the Orchestrator's job.

---

## 3. PNG Handling Rules

PNG files are diagnostic artifacts for human review. The following rules are absolute:

- **Surface the PNG for human inspection immediately upon generation — before performing any analysis of its content**
- Human visual review always precedes any Clyde interpretation step
- Analysis of PNG content only proceeds if explicitly requested by Jay after visual review
- **Never read, analyze, or interpret PNG pixel content directly**
- **Never use PNG content as input for corrections or behavioral conclusions**
- PNG data may only be used if first converted to structured text output — coordinate arrays, color index tables, buffer contents, or equivalent — and only if Jay explicitly requests that analysis after reviewing the image
- All corrections based on visual output must come from Jay's explicit specification, not Clyde's interpretation

**Anchor Coordinates**
- Before any spatial correction task, scan relevant source files or data structures to derive current anchor coordinates
- Never use previously recorded coordinate values as anchors — object positions change as development progresses
- Always derive anchor coordinates fresh from current state
- Report candidate anchors to Jay for confirmation before executing any spatial correction

---

## 4. MAME Visual Gate (25.3)

- §6 25.3 remains open as **"pending Jay"** until Jay confirms the visual gate has been observed
- Clyde screenshot analysis is never authoritative for 25.3
- Marking 25.3 satisfied from Clyde's own screenshot analysis will be rejected
- **Standing gate monitor mode = RGB (2026-07-18).** Future visual gates render on **Monitor Type = RGB** (`screen_config`=1, set from Lua) with the RGB palette set — RGB is the dominant delivery target. **Composite** (Monitor Type=0) remains a valid gate when composite-specific verification is wanted (the composite pile / a hardware smoke test) — state which mode a given gate used. This changes only the default monitor mode; the exhaustive-enumeration rule (§2A.4) and "the fused 1:1 read is the colour gate" stay intact.

---

## 5. Timing Rules (C-35)

§1 elapsed value must be arithmetic on two machine-stamped artifacts:

- **t0** — quoted verbatim from the §0 receipt stamp
- **commit-time** — from `git show -s --format=%cI HEAD`

A separately hand-read stop time is estimate-grade and never feeds the band table. No exceptions.

---

## 6. Failed Approach Protocol

- Never retry a previously failed approach without explicit human authorization
- When a failure occurs, document it explicitly — what was tried, exact output, why it failed
- State the failure in the §8 Uncertainty Flags section of the report
- Wait for human instruction before attempting an alternative approach

---

## 7. Form B Report Structure

All task reports must follow this format exactly:

```
## Form B Report — T-<id>

### §1  Timing (C-35 — mandatory)
t0=<paste verbatim from §0 receipt stamp>
commit-time=<git show -s --format=%cI HEAD>
Elapsed: <commit-time − t0> min.
Predicted: <empirical band verbatim> / <legacy band verbatim>.
Classification: <sub-band-low | lower-half | midpoint | upper-half | over-band>.

### §2  Summary
<one paragraph: what this task delivered>

### §3  Files modified
- <path> — <delta nature>

### §4  Reasoning
<addresses the dispatch-named questions directly; mechanism, not restatement>

### §5  Verification (AC-by-AC)
- AC1 <text> — <evidence that satisfies it>
- AC2 <text> — <evidence that satisfies it>

### §6  Verdict-time evidence (§11)
25.1 fresh tool output (verbatim):
  <build.bat output>
  <run_<test> output>
25.2 bundled-artifact grep (if applicable): <verbatim>
25.3 operator-runtime-smoke: <Jay MAME visual gate — state "pending Jay" if not yet observed>

### §7  Reactive deviations
<§22.5 changes from spec, or: None.>

### §8  Uncertainty flags
<what is not yet certain, or: None.>

### §9  Follow-up candidates
<surfaced next-tasks, or: None.>

### §10 User interaction during task
<itemized, or: None.>

### §11 Candidate(s) captured this task
<seeds/karateka/ slugs, or: None.>

### §12 Commit
<hash>
```

---

## 9. Context Reset Procedure

Long sessions cause context window bloat. When CLAUDE.md rules are being ignored or previously prohibited behaviors reappear, the window is degraded. Do not redirect and continue — reset.

**Signal to watch for**
- Reverting to comment-based reasoning
- Analyzing PNG content before surfacing it
- Skipping anchor derivation
- Retrying previously failed approaches
- Any behavior explicitly prohibited by this document

**Reset procedure**

1. Stop the current task
2. Claude.ai generates a clean state summary capturing:
   - Last confirmed working state
   - Current verified anchor coordinates
   - Last completed task and what it established
   - Any open items or pending gates
   - Known dead ends to avoid
3. Start a fresh Clyde context
4. Feed the state summary plus CLAUDE.md as the first input
5. Resume from confirmed state only — never from assumed state

**At the start of each new subtask within a long session**

Explicitly re-read and acknowledge active CLAUDE.md constraints before proceeding. Do not carry forward assumptions from previous subtasks without verification.

---

## 8. General Behavioral Rules

- Task contracts specify task-specific requirements; this document specifies project invariants that apply to every task
- Project invariants in this document take precedence over task contract instructions where they conflict
- When in doubt, stop and surface uncertainty in §8 rather than proceeding on an assumption
