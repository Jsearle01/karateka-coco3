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

The MAME idioms files are *how* to get the reliable execution evidence §2 requires — they never override the ground-truth hierarchy or the visual-gate rules (§4), they serve them.

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
