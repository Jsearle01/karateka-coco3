# Karateka — Tandy Color Computer 3 port

A clean-room **6809 assembly port** of the Apple II *Karateka* (Jordan Mechner,
1984) to the **Tandy Color Computer 3** (GIME, 128K). Faithful reproduction of
the original's graphics, animation, and behaviour on real CoCo3 hardware and in
MAME — targeted as **co-equal delivery** to both.

> **Status:** in active development. The intro/demo through the **scene-6
> attract fight** is the current frontier. The production ROM has been
> **byte-identical the entire project** — all scene-6 work lives in sandbox
> drivers and integrates into production deliberately (see *Invariants*).

---

## What this is

- A **native CoCo3 port**, not an emulation shim: real GIME 320×192×4
  explicit-palette graphics, a double-buffered page-flip sprite engine, and
  6809 code sized to a **stock 128K** machine.
- Driven by a **clean-room disassembly oracle** of the Apple II original —
  used as a behavioural reference to reproduce, not as code to translate.
- A study in **disciplined reverse engineering**: the hard part is not writing
  6809, it is establishing *what the original actually does* and proving the
  port matches it.

This is a preservation / homage project. *Karateka* and its assets are © Jordan
Mechner / Broderbund; this repository contains **original port code and
documentation only** — no copyrighted ROM, disk image, or asset data is
distributed here. Running or verifying the port against the original requires
your own legally-obtained copy.

---

## How the work is done — the CODM methodology

Development follows a three-role, three-artifact loop (Claude-Orchestrated
Development Methodology):

- **Jay (owner)** — holds visual/behavioural ground truth and gates every
  decision. His eye overrides trace and tool conclusions.
- **Orchestrator (planner/reviewer)** — writes a **verification plan** *before*
  work (a falsifiable hypothesis + predicted observations) and a **review
  verdict** *after* (confirmed / partially / not confirmed, per-prediction).
  Never edits the repo directly.
- **Clyde (executor)** — runs the work in-repo and produces an **execution
  report** (machine-stamped timing, evidence, deviations, uncertainty flags),
  pushing before reporting.

The loop is **plan → execute → verdict**, at investigation granularity. It
exists because the recurring failure mode on this project is a *plausible
conclusion that wasn't actually verified* — so every non-trivial claim is
gated on execution evidence, not description.

`CLAUDE.md` is the working agreement (invariants, conventions, gate recipes).

---

## Repository map

- `src/` — the port: engine (`engine/`), scene composites, HAL (`gfx.s`).
- `content/<category>/<dir>/converted.s` — converted sprite cels, categorised
  (`player`, `guard`, `princess`, `akuma`, `bird`, `floor`, `scenery`,
  `title`, `font`, `broderbund`, …).
- `harness/tools/` — the sprite converter, render/compare tools, MAME Lua trace
  harnesses.
- `docs/ground-truth/` — external authoritative references (hardware specs).
- `docs/project/` — authored project docs (see below).
- `dist/` — distribution presets (e.g. MAME monitor-mode `coco3.cfg`).
- `tests/` / `run_*` scripts — test drivers and their build/log plumbing.

The **production ROM** builds from `src/` only. Scene-6 work is staged in
**sandbox drivers** and is not in production until deliberately integrated.

### Authoritative documents (one home per fact)

- `docs/project/decision-record_colour-output-sprite-sets.md` — the
  colour / output-target / sprite-set reasoning (RGB vs composite, the palette,
  the clean/fringed rule, the monitor↔palette coupling).
- `docs/project/project-state-open-items-disk-boot-arc.md` — disk/boot open
  items, capacity, load model.
- The port post-mortems — the consolidated engineering narrative and lessons.
- `CLAUDE.md` — invariants, conventions, gate recipes, methodology pointers.

---

## Invariants (project-wide)

- **Stock 128K CoCo3.** The 512K expansion is a gated escalation, never an
  ambient default; every memory-budget decision confirms 128K fit first.
- **6809 only, not 6309.** No 6309-only instructions; timing claims grounded in
  real 6809 cycle counts at CoCo3 clock. Per-frame bulk copies are sliced
  across frames, never one-shot.
- **One sprite/animation engine** for the whole project — a CoCo3-native port of
  the oracle's sprite routines. No scene rolls its own blit.
- **Production byte-identical** — the shipped ROM's hash is a leak tripwire:
  nothing experimental reaches production until an integration step deliberately
  re-baselines it (at scene-6 integration). "Prod byte-identical" is both a
  safety rail and a wall crossed on purpose.
- **The oracle is authoritative through scene 4 only.** Past that, bytes are
  present but labels are unreliable — the running game + execution trace is the
  authority, and the disassembly is a hypothesis until execution-confirmed.

---

## Build & run

- Production build: `build.bat` (produces the byte-identical `karateka.bin`).
- Test/sandbox drivers: explicit `run_*` scripts (build + run + log).
- MAME is the primary visual gate. Monitor mode (RGB / Composite) is a machine
  configuration, not a CLI flag — set via the TAB menu, a preset `coco3.cfg`
  (`-cfg_directory`), or Lua. RGB is the current default gate (the dominant
  delivery target); composite presets are in `dist/`.

Prerequisites and per-tool usage are documented alongside the scripts and in
`CLAUDE.md`.

---

## Design ethos

**Look, don't theorise.** The scene-6 recon reached its true model only through
many rounds of live visual correction — every tidy theory that wasn't checked
against the running game turned out wrong. The project's central diagnostic
technique (classify draws by sprite-bank at the actual draw entry, not by
pointer dwell) exists because *"most motion" is not "the actor"* in a scrolling
scene. When trace and eye disagree, the eye wins and the trace is the thing on
trial.

---

## License

See `LICENSE` if present. Absent an explicit licence, this repository's original
port code and documentation are **all rights reserved** (source-visible, not
granted for reuse) — appropriate to a clean-room port with upstream IP
sensitivities. The original *Karateka* IP is not covered here and is not
distributed.
