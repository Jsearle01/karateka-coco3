# Disk-load catalog

Evidence base for `Q-512kb-architecture` (open-questions.md). One entry per
**real disk load**, characterized **when the port reaches the scene that
triggers it** (observe-in-context, not static inference). The 512 KB-vs-128 KB
decision drafts off this once the pattern is clear.

Status: **empty** — the first in-game loads trigger post-attract (P3+, when
game-start replaces the "pressed" placeholder).

| # | Scene / trigger | Transfers | Data or Code | Destination | Overlays? (replaces existing code?) | Notes |
|---|---|---|---|---|---|---|
| *(none yet)* | | | | | | |

**Why it matters:** data-only loads → clean MMU data-window paging (512 KB
easy); code-overlay loads → overlay manager needed (512 KB harder; complexity
scales with overlay count/granularity).
