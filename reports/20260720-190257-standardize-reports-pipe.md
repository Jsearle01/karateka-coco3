## Form B Report — T-standardize-reports-pipe

### §1  Timing (C-35)
t0=2026-07-20T19:02:57.606809800Z
commit-time (amendment)=cfff9a3 (`git show -s --format=%cI cfff9a3`)
Elapsed: ~6 min. (Docs/template release; no band quoted.)

### §2  Summary
Standardized the `reports/` delivery pipe (pipe was proven end-to-end: the Orchestrator
fetched `origin/wip:reports/2026-07-20-pipe-test.md`, HTTP 200, readable). Amended the
canonical dispatch template's §8 reporting section with the REPORT DELIVERY standard, the
`.gitignore`-phantom note, and the colon-free filename rule. Removed the proven bootstrap
dummy. This report itself is the first artifact written under the new standard (dogfood).

### §3  Files modified
- `docs/project/dispatch-template-canonical-for-store.md` — §8 gains the REPORT DELIVERY (standard) block + .gitignore-phantom note + colon-free filename rule.
- `reports/2026-07-20-pipe-test.md` — removed (bootstrap dummy, purpose served).
- `reports/20260720-190257-standardize-reports-pipe.md` — this report (new standard).

### §4  Reasoning
The amendment is placed in §8 (the Form-B/reporting area) as an always-present `« »` clause,
matching the style of the adjacent CANDIDATE(S) CAPTURED clause. The filename is colon-free
`YYYYMMDD-HHMMSS` because raw ISO `t0` carries `:`, invalid in Windows filenames where Clyde
runs; the compact form still sorts chronologically and stays unique. Kept the change scoped
to §8 per the dispatch — did not touch the "Serial vs parallel" summary or version header
(no scope creep). Housekeeping call: removed the dummy (the real reports are the example now).

### §5  Verification (AC-by-AC)
- AC (template amendment landed) — committed cfff9a3; the REPORT DELIVERY block + .gitignore note present in §8.
- AC (.gitignore note) — added verbatim near the reporting step; no `.gitignore` edit made (real report files stage/commit/push fine, proven by the dummy + this file).
- AC (prod byte-identical) — `88eba89 OK`; no `src/`/`build/` change (docs/template only).

### §6  Verdict-time evidence
25.1: template amendment commit `cfff9a3`; `prod 88eba89 OK`; `git diff src/ build/` empty.
25.3: N/A (no runtime surface) — the Orchestrator reading this file from `origin/wip:reports/` is the pipe's live confirmation.

### §7  Reactive deviations
None.

### §8  Uncertainty flags
None.

### §9  Follow-up candidates
None. (Orchestrator-side: verdict routine now fetches `origin/wip:reports/` and reads the latest `<YYYYMMDD-HHMMSS>-<slug>.md` first; inline paste is the fallback — recorded in the dispatch, not a Clyde action.)

### §10  User interaction during task
This dispatch (CLYDE RELEASE — standardize the reports/ pipe).

### §11  Candidate(s) captured
None.

### §12  Commit
Template amendment: cfff9a3 (wip). This report committed as a follow-on on wip (hash in git log); both pushed to origin/wip.
