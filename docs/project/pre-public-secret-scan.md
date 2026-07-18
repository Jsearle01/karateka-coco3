# Pre-public secret / full-history scan — REDACTED summary (2026-07-18) — REPORT ONLY

**Result: CLEAN. No secrets found in the full history of `karateka-coco3` across all refs.**
Report-only — this scan **gates** Jay's go-public decision but does not authorize it. No history
was modified; no token rotated; no public flip. Prod `88eba89…` byte-identical (no build, no code change).

## Why this scan
Making a repo public exposes its **entire history** irreversibly, not just the current tree. A secret
ever committed (even if later removed) becomes public the moment the switch flips. A GitHub PAT is known
to have existed in this project's orbit (embedded in the **methodology-candidate-pool** remote URL — a
*different* repo), so a full-history scan of THIS repo was mandatory before going public.

## Scope (all refs, full history)
- Refs present: `refs/heads/main`, `refs/remotes/origin/main` (no stale branches/tags).
- Commits reachable from `--all`: **292** (gitleaks reports 291 commits scanned + working tree).
- Current `origin` remote: **SSH** (`git@github.com:…`) — no embedded credential in THIS repo's config.

## Tool + invocation
- **gitleaks 8.30.1** (winget `Gitleaks.Gitleaks`, release binary, hash-verified).
- Full-history, all-refs, redacted:
  `gitleaks git --log-opts="--all" --redact --report-format json --report-path <scratchpad>/gitleaks-report.json`
  → **`291 commits scanned … no leaks found`** (exit 0, empty report).
- Raw report kept **untracked** in the session scratchpad (never committed).

## Independent grep corroboration (redacted, full history `git log -p --all`)
| Check | Pattern | Result |
|---|---|---|
| GitHub token families | `ghp_` / `github_pat_` / `gho_` `ghu_` `ghs_` `ghr_` (with real payload) | **none** |
| Credential-in-URL (non-`git` user) | `://user:token@`, `<20+char>@github.com` | **none** |
| `@github.com` matches (all 10) | — | all literally **`git@github.com`** (the standard SSH user — benign, not a credential) |
| AWS / private key / Slack | `AKIA…`, `BEGIN … PRIVATE KEY`, `xox[baprs]-` | **none** |
| Added secret files (any commit) | `.env` `.pem` `.key` `.p12` `id_rsa` `credential` `secret` | **none** |

## The known methodology-pool PAT specifically
**Never committed to this repo.** It lived only in the *pool* repo's remote URL; no file in
`karateka-coco3` history (script, checked-in git config, `.remote`, Makefile, Lua/py harness, notes)
ever embedded it. `.git/config` is not history-committed and this repo's current remote is SSH anyway.

## Redacted findings table
**CLEAN: no secrets found in full history across all refs.** (The only `@github.com` occurrences are
`git@github.com` SSH-remote references in old status/notes docs — the SSH user is literally `git`, not a secret.)

## HARD-STOPs
None fired (clean result). Note: **a clean result does NOT authorize going public** — that flip, plus
the licence decision and README, remain Jay's calls. This dispatch only surfaces the evidence.
