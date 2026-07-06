# Autonomous Human–AI Collaboration Model (project-agnostic)

*A reusable model for delegating back-and-forth autonomous work to an orchestrator + executor while keeping a human in control of what actually matters. Derived from a working implementation (see Provenance) and lifted to a project-agnostic form: each abstraction is stated generally, with the occasional **Instance:** callout where a concrete example aids understanding. A reader from a different project should be able to follow the spine without knowing that implementation.*

**The three roles** (used throughout):

- **Operator** — the human. Delegates operations, holds the gate, reads the end-of-operation report. Removed from the per-step loop *by design*; never from the decisions that matter.
- **Orchestrator** — plans, dispatches work to the executor, judges results, and (autonomously) restructures-and-reissues. The only party with the whole picture.
- **Executor** — acts within an authorized sandbox: implements, tests, iterates. Reviews each dispatch before running it; aborts-and-reports if it discovers the dispatch was flawed.

---

## 1. The problem

A human wants to delegate substantive work to an AI orchestrator + executor that resolve issues back-and-forth **autonomously** — implement, test, iterate, without approving each step — yet still **always stop for design decisions and genuine concerns**. Two requirements make that safe to grant, and they reinforce each other:

1. **Isolation (blast-radius containment).** The autonomous agent must be unable to affect anything outside its authorized scope — and that must be **structural, not vigilance-based**. A check a bug could defeat is not containment; the architecture itself must make the out-of-scope action impossible.
2. **Flexible autonomy (selectable approval altitude).** The operator chooses, *per operation*, how hands-off to be — from per-step approval (watching closely) to whole-task hands-off — fixed for that operation's duration.

These are not separate features. They **converge on one structure**: a per-operation authorization that carries *both* the agent's scope and its approval altitude. And they reinforce each other — the isolation is what makes the autonomy safe to grant, because an autonomous operation's blast radius is contained **by construction**.

---

## 2. The model in one paragraph

The executor is **bound** to exactly one authorized sandbox (structural isolation). When the operator hands off an operation, they **select a granularity** for it (per-step → whole-task), fixed for the operation's duration. Within the operation, orchestrator and executor work autonomously inside the sandbox. The executor **reviews each dispatch before running it** and surfaces gaps/oversimplifications (pre-flight); if it discovers mid-run that the dispatch was flawed, it **aborts and reports** (no mid-run pause). The orchestrator then **restructures and reissues autonomously**, looping up to a retry limit — **until** it hits a design/decision point or a gate-boundary action, at which point it **stops for the operator.** Actions that escape the sandbox or are irreversible always gate, regardless of granularity. Every operation concludes with an **end-of-operation report** — the operator's complete after-the-fact view, traded for per-step oversight.

---

## 3. Structural isolation — contain by construction

The executor operates in exactly ONE authorized sandbox, and reaching anything outside it must be **impossible by architecture**, not merely **checked**.

- **A per-operation grant carries the scope.** The executor's authorization (credential / token / grant) names its sandbox. The scope is **confirmed at grant time** — the operator binds *this* sandbox — not discriminated-among-many at action time.
- **Enforcement is at aligned layers.** The routing that sends the executor's actions to its sandbox is constrained to the bound scope; an action targeting another scope is **rejected**, not free-resolved against a global set. Misdirection cannot succeed.
- **Out-of-scope attempts are blocked AND surfaced** (not silently denied). An attempt is a signal that something is wrong — worth the operator seeing.
- **The strongest realization is physical isolation** — one executor *process* per sandbox, so one cannot even *see* another's scope; a bug in a check can't cross a process boundary that shares no state. But the principle is **containment by construction**: physical-process isolation is one realization, a capability-scoped credential another. Choose the strongest the project can afford.

> **Instance (claude-bridge):** one daemon process per workspace, each holding a workspace-bound OAuth token; the auth layer rejects any tool call targeting a non-bound workspace. Isolation is physical, not a code-path that vigilance maintains.

---

## 4. Per-operation granularity — selectable approval altitude

- **Selected at the start of an operation, by the operator, for that operation — fixed for its duration.** Not changeable in flight. (The operator specifies how hands-off the operation they are *about to* delegate is; they do not steer it mid-run.)
- **A spectrum**, e.g.:
  - **per-step** — approve each gated step (watching closely);
  - **task** — approve once; the operation runs to completion (hands-off for this task);
  - **auto** — runs within bounds without prompting (most hands-off).
- **Tighten-only (the clamp): a per-binding default altitude exists; an operation may only TIGHTEN it, never loosen it.** The default is the operator-set **ceiling**; an operation may request a *more cautious* (finer) altitude, and the resolution takes the **stricter** of the two. It can **never** request a coarser altitude than the ceiling — **the gated party cannot widen its own gate.**
- **Fire-and-run.** Once launched at a chosen altitude, the operation runs to completion at it. To run finer, the operator launches the *next* operation finer (or cancels the current one). The operator does **not** tighten a running operation.

---

## 5. The autonomy floor — pre-flight, abort-and-report, the resolution loop, the report

Autonomy governs execution of an *agreed, sound* dispatch. It does **not** mean executing a flawed one blindly.

### 5.1 Pre-flight review (executor discipline)
Before committing to an autonomous run, the executor **reviews the dispatch** and surfaces gaps, oversimplifications, hidden assumptions, or scope problems the orchestrator may have missed — halting for resolution **before** the autonomous portion begins. This is **discipline** (how the executor is instructed to approach a dispatch), not a mechanical gate — no code detects "this dispatch is oversimplified."

### 5.2 Mid-run discovery (abort-and-report)
If the executor discovers *mid-run* that the dispatch was flawed (an assumption proves wrong three steps in), it **aborts the run and reports the concern.** It does **not** pause-and-ask. (Consistent with fire-and-run: no checkpointing, no pausable operations.)

### 5.3 The autonomous resolution loop (orchestrator-level)
On an abort-and-report (or a pre-flight halt), the **orchestrator** takes the concern, **restructures the dispatch** to address it, and **reissues** it — **autonomously, with no human** — as long as the concern is something restructuring can resolve. The loop needs no special architecture: it is the orchestrator reasoning about a report and making another dispatch.

**The loop halts and gates to the operator when:**
- it hits a **design/decision point** (§6 — the boundary the loop must respect), OR
- the **retry limit** is reached (a fixed N restructure-reissue cycles), OR
- the orchestrator recognizes it **cannot resolve the concern by restructuring.**

**The risk to manage (state it plainly):** the "resolve autonomously vs. gate" boundary is a judgment relocated to the orchestrator. The failure mode is the orchestrator restructuring *around* something that was actually a design decision the operator should have seen — **papering over a real question.** This is why §6's design/decision category is load-bearing for the loop, why the retry limit is a hard floor against a non-converging loop, and why the end-of-operation report (§5.4) is mandatory — it is the operator's *after-the-fact* check on exactly this failure mode.

### 5.4 The end-of-operation report (the accountability counterweight)
Removing the operator from the per-step loop creates an **observability debt**: they authorized an operation, stepped away, and must be able to learn what actually happened — including judgment calls the orchestrator made autonomously that they might, in hindsight, have wanted to weigh in on. **Every operation therefore concludes with an end-of-operation report**, regardless of granularity — even a fully hands-off "auto" operation ends with one. It is the *conclusion* of every operation, not itself gated. Per-step oversight is traded for **complete after-the-fact visibility**.

**Structure: the report is the log, annotated with meaning** — not two parallel artifacts (a raw log and a separate summary), which would let the narrative float free of the log and quietly omit a messy cycle. Instead:

1. **A mechanical interaction log — the authoritative spine.** The system records every transaction it can see — each dispatch and its result, each pre-flight halt, each abort-and-report, each restructure-reissue cycle, each gate event, each bounded side-effect (capture, publish, destination). **Guaranteed; cannot be omitted by the orchestrator.** It is the authoritative list of what happened; the report must account for all of it.
2. **An orchestrator narrative, keyed per-transaction.** The orchestrator — the only party with the whole picture — walks the log and, **for each logged transaction**, states: **what it was for** (its purpose); **what kind it was** (a clean dispatch; a *pre-flight hard-stop* and what was objected to; an *abort-and-report* and what was discovered; a *restructure-reissue* and **how many rounds** it took); **how it resolved**; and any **near-gate disclosure** attached to that transaction. The narrative is **factual / log-fidelity over interpretive** — "this dispatch was a hard-stop; the executor flagged X; I restructured; the reissue completed," not "the run went well." The operator forms their own assessment by reading the accounted log.

This per-transaction structure makes **omission structurally visible** (every log entry needs an accounting — an unaccounted entry is an obvious gap), gives the mechanical log its human context, and surfaces the **texture** of the run: a string of clean dispatches reads very differently from one hard-stop that took three rounds, and the report makes that legible at a glance.

**Required contents:**
- **Outcome vs. intent** (run-level) — what was accomplished against the dispatched goal. Did it do what was asked?
- **Per-transaction accounting** (the spine, above) — every logged transaction addressed: purpose, kind, round-count, resolution.
- **Near-gates / judgment calls — REQUIRED, PROMINENT, the highest-value content, attached per-transaction.** Every decision the orchestrator made autonomously that was *close to* the design/implementation boundary — calls that did **not** gate but plausibly *could* have — disclosed against the specific transaction where the call was made. This is the operator's hindsight check on the §5.3 papering-over risk: it surfaces the judgment calls so a bad one can be caught after the fact even though it did not gate in the moment. A run where nothing approached the boundary **says so explicitly**.
- **Autonomous-resolution summary** (run-level) — did the loop converge cleanly or struggle; was the retry limit approached or hit.
- **Gate events** — any transaction that hit an always-stop category (§6) and how it was handled.
- **External side-effects** — what was published/sent where, under what granularity-governed decision.

---

## 6. The gate boundary — what always stops for the operator

### 6.1 Core principle (mechanical)
> **Gate when an action escapes the authorized sandbox OR is irreversible. Run autonomously when it is within the sandbox and reversible.**

- **Within-sandbox + reversible → autonomous:** file edits, running tests, reversible refactors, in-scope commits, bounded side-channel writes (§6.3), and the publish of the sandbox's own completed work *governed by the chosen granularity* (under the binding, that work is already contained, so publishing it is the normal conclusion of an authorized operation — "whole-task autonomous" includes it; "watch closely" gates it).
- **Escapes-sandbox OR irreversible → always gate, regardless of granularity:** acting outside the bound scope (structurally blocked + surfaced); external services / new network endpoints; **sending or publishing anything externally**; spending money / deploying / production actions; **irreversible/destructive operations** (delete data, force-push, history rewrite, data-drop, `rm -rf`-class); and the recursive floor below.

### 6.2 The recursive floor (non-negotiable)
**The autonomy system must never autonomously modify the autonomy / permission / trust system itself.** The executor cannot restructure its way into widening its own permissions, changing its binding, altering gate categories, or touching credentials / tokens / trust config. **Changes to the gates are always human.** (This is the floor a self-modifying agent would otherwise dissolve — without it, every other floor is negotiable by the agent.)

### 6.3 Additional bounded side-channels (optional)
A *second* authorized write target can exist alongside the primary sandbox — provided it is **append-only, firewalled (a scope-limited credential that structurally cannot reach anything else), and reversible.** Writes there are categorically bounded-reversible-isolated — not "scary external pushes" — so they run autonomously.

> **Instance (claude-bridge):** an append-only methodology-candidate pool path, written via a pool-scoped credential that can reach nothing else.

### 6.4 Design / intent decisions (judgment — discipline-enforced)
These **always gate**, and they are **also the boundary the §5.3 loop must respect**:
- choosing between architecturally-different approaches;
- changing a task's **intent** vs. its **implementation** (implementation → autonomous; intent change → gate);
- departing from the dispatch's stated goal;
- introducing a new dependency, framework, or external service;
- tradeoffs with no objectively-correct answer.

These **cannot be mechanized** (no code detects "this is a design fork"); they are executor/orchestrator **discipline**, as reliable as the methodology. The orchestrator may autonomously restructure around **implementation** problems but must **gate on design/intent** problems.

### 6.5 Loop-state safety (mechanical)
- **Retry limit:** after **N** autonomous restructure-reissue cycles, gate to the operator regardless — a hard floor against a non-converging loop.
- **Voluntary escalation:** the executor may **choose** to gate even when no category forced it. It can always involve the operator.

---

## 7. Two enforcement layers — be honest about which is which

A model that pretends discipline is a guarantee is dangerous. State plainly which floors are mechanical and which are discipline:

- **Mechanical (structurally guaranteed):** the binding and its enforcement; the sandbox boundary; irreversible-op detection; the **recursive floor** (can't modify its own permissions); retry-limit counting; granularity lookup; and **the interaction log (§5.4) — guaranteed, cannot be omitted.**
- **Discipline (methodology / prompt-enforced, as-reliable-as-the-methodology):** pre-flight review; design-vs-implementation judgment; the resolution-loop boundary; voluntary escalation; and **the report narrative + its rigorous near-gate disclosure** — *bounded* by the mechanical log, which the operator can read directly to check the narrative against ground truth.

The placement is deliberate: the **catastrophic** floors (irreversible, security, sandbox-escape, scope) and the **accountability backstop** (the log) live in the **mechanical** layer; the **judgment** floors live in the **discipline** layer. Discipline is real — a well-run executor halts on ambiguity and invokes its conventions by name — but it is discipline, **not** a hard guarantee, and the model is honest about that.

---

## 8. What this deliberately does NOT include (scope discipline)

- **No interruptible / checkpointed operations.** Operations are fire-and-run to completion; granularity is set at start, not steered in flight.
- **No mid-run pause-and-ask channel.** Mid-run discovery is abort-and-report, not pause.
- **No live granularity dial.** Granularity affects the *next* operation, never the current one.

These exclusions are what keep the model a contained, adoptable shape rather than a major architecture project. They follow directly from "don't steer in flight; specify per-operation."

---

## Provenance

Derived from a real orchestrator-executor implementation (**claude-bridge** — a bridge connecting a Claude.ai project chat to a local development workspace via a per-workspace daemon, OAuth-bound auth, and a headless Claude Code SDK executor) and generalized into the project-agnostic form above. The original was reached through a design conversation grounded in multiple read-only reconnaissance passes before any design was committed — the **recon-before-design** discipline that kept it from being built on a wrong mental model (an assumed one-to-one binding vs. an inherited global one). That discipline is itself part of the model's pedigree: the structure here is what survived contact with the real system, not a whiteboard ideal.
