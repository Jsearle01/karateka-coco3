# Orchestrator Briefing — karateka-coco3 (2026-06-12)

**Audience:** Orchestrator-Claude (the Claude.ai project chat).
**Purpose:** Bring you up to speed so we can begin orchestrating tasks against
the karateka-coco3 port. Read this once; it is the project's current ground
truth as of 2026-06-12.

---

## 1. Your role (three-role methodology)

This project runs on the **Claude-Orchestrated Development Methodology v0.7**.
Three roles:

- **Orchestrator-Claude (you):** run in this long-lived Claude.ai chat. You draft
  dispatches, issue verdicts, hold scope conversations with the operator, and
  maintain calibration/pattern notes. **You never directly modify code.**
- **Executor (Clyde / Claude Code):** runs locally in the repo on Windows.
  Receives a single-prompt dispatch, implements, builds, runs tests, commits,
  reports back.
- **Operator (Jay):** the human gate at every non-trivial decision. Confirms
  scope, runs visual gates, makes reshape calls.

Core disciplines: pre-task scope conversation before drafting a dispatch;
single-prompt dispatch with acceptance criteria + verification baked in;
recon-before-acting; verdict-time evidence (verbatim diffs, not summaries);
separate executor-verifiable claims from human-gated ones; specify report
format up front.

Methodology source-of-truth lives in two repos (GitHub, Jsearle01):
`Cluade_methodology_store` (the canonical book) and `methodology-candidate-pool`
(the inbox of proposed changes). A daemon-driven autonomous path exists
(claude-bridge) but is optional; today the loop is orchestrator-run.

---

## 2. The project

**karateka-coco3** — a faithful port of *Karateka* (Jordan Mechner, 1984, Apple
IIe) to the **Tandy Color Computer 3**, in native **6809/6309 assembly**.

**P2 target deliverable (= integration milestone INT-3):** a bootable CoCo3 disk
running the complete intro/attract sequence: Brøderbund logo → title → cliff
approach → demo combat → Akuma throne-room cutscene → loop.

**Method:** the verified Apple II **6502 disassembly is the source-of-truth
oracle**. The port is validated against it (reference captures, byte-identity,
visual parity). Porting is HAL-mediated — Apple II routines are often satisfied
by the CoCo3 HAL contract (ABSORBED-HAL) rather than literal translation.

---

## 3. Current status (engineering)

Phase: **P2 in progress; P3.1 complete.** Last engine advance 2026-05-21
(R-vbl + R-boot). Everything since has been environment/tooling (Section 6).

| Item | Status |
|---|---|
| P1 Foundations | Complete |
| P2.0–P2.2 (capture kit, timer/framesync, kernel/dispatch) | Complete |
| P2.3 blit/graphics engine (INT-1 scope) | Complete (2026-05-17 audit: 11 ABSORBED-HAL, 3 combat-path routines deferred) |
| P3.1 real HAL — R-vbl (GIME VBL IRQ) + R-boot (Brøderbund splash boot) | Complete & CONFIRMED (2026-05-21) |
| **P2.4 — canonical `intro.s` scene-1 path (R-p24)** | **NOT STARTED — sole remaining INT-1 blocker** |
| P2.5+, P4, P5 | Not started |

**INT-1 ("first scene displays correctly")** is one task from closed: R-p23,
R-vbl, R-boot are all CLOSED. **R-p24 (P2.4) is the only blocker.**

**What boots today:** from `build/karateka.bin`, the Brøderbund splash renders
(logo + "presents"), holds ~2.67s, blanks ~1.33s, real-VBL driven at ~60 Hz.
Verified live in MAME 2026-06-12: V-counter-rate PASS, scene screenshot confirmed.

**Key closed-work detail for R-boot** (matters for R-p24): CoCo3 BASIC leaves
PIA0 keyboard IRQ enabled, which traps the CPU. `HAL_sys_init` now disables
PIA0/PIA1 CA1/CA2/CB1/CB2 IRQs; **R-p24+ keyboard input must re-enable these
selectively.** Also `HAL_gfx_init` writes `$FF90=$6C` to preserve VBL IEN.

---

## 4. Repositories & locations (all native Windows now)

| Path | What | GitHub (Jsearle01) |
|---|---|---|
| `C:\Projects\karateka_coco3` | The port (this project) | `karateka-coco3` |
| `C:\Projects\karateka_dissasembly_claude` | Apple IIe 6502 oracle | `karateka_dissasembly_claude` |
| `C:\Projects\6502-6809-conversion-patterns` *(ref)* | Shared porting patterns | `6502-6809-conversion-patterns` |
| `C:\Projects\apple2-disasm-patterns` *(ref)* | Disassembly methodology patterns | `apple2-disasm-patterns` |

Pattern libs and the oracle are consumed **by path reference, no git coupling**.
Both project repos are clean and pushed to `main`.

---

## 5. Toolchain & environment (WSL fully removed)

Everything builds and tests natively on Windows. **No WSL anywhere.**

- **lwasm** (LWTOOLS 4.24, 6809/6309 assembler) — `C:\WIN_LWTools`, on PATH
- **cc65** (V2.19, 6502 suite — includes **`da65`** disassembler for the oracle)
  — `C:\cc65\bin`, on PATH
- **MAME** — `C:\mame\mame.exe`; ROMs in `C:\mame\roms` (apple2e + coco3 present)
- **Python 3.13** (`python`)
- Staging dir for MAME capture/boot tests: `C:\karateka-capture`

> Note: PATH entries were added to the **User** environment, so a freshly opened
> terminal sees `lwasm`, `ca65`, `da65`. Already-open shells need a restart.

### Build & test — karateka-coco3 (6809)
```
build.bat            REM -> build\karateka.bin (2171 B) + 10 test drivers
clean.bat
tests\scripted\run_*.bat   REM MAME test runners (native lwasm + C:\mame)
```
Automated MAME tests (PASS/FAIL verdict): `run_sys_init_test`, `run_gfx_init_test`,
`run_kernel_dispatch_test`, `run_timer_framesync_test`, `run_vbl_irq_test`,
`run_prod_boot_test`, `run_gfx_init_precheck` — **all 7 PASS as of 2026-06-12.**
Visual-observation runners (human watches MAME window, no auto verdict):
`run_visual_smoke_test`, `run_broderbund_splash_test`, `run_presents_test`,
`run_broderbund_presents_scene`, `run_sub_byte_shifter_test`, `run_prod_boot_visual`.

### Build & test — karateka_dissasembly_claude (6502 oracle)
```
build.bat                        REM python scripts\build_disk.py
scripts\smoke_test.bat           REM build + byte-identity + MAME boot (PASS/FAIL)
scripts\capture_reference.bat    REM regenerate reference captures
```
Smoke test verified PASS end-to-end (38 ranges byte-identical to
`dumps\dump01_intro.bin`; `karateka_built.dsk` boots in MAME).

> The Unix `Makefile`/`.sh` files remain in both repos for WSL/Linux use, but the
> native `.bat` path is the supported one on this machine.

---

## 6. What changed in the 2026-06-12 session (so you don't re-derive it)

- Migrated the entire dev environment from WSL to native Windows; installed
  lwasm + cc65 natively; verified both build pipelines and all MAME tests.
- Pulled the oracle repo from WSL to `C:\Projects` and de-WSL'd it (native `.bat`
  entrypoints + `scripts/validate_captures.py`). Committed + pushed both repos.
- Removed karateka-coco3, the oracle, lwtools, and cc65 from WSL (~1.6 GB freed).
- No engine code changed; project phase status is unchanged from 2026-05-21.

---

## 7. Verification discipline (apply to every dispatch verdict)

- **No color claims from screenshots.** Framebuffer dump (`tools/decode_framebuffer.py`)
  is the canonical pixel-verification signal.
- **Byte-identity** against the oracle dump is the strongest regression signal for
  reassembly (oracle repo).
- **V-counter-rate** confirms frame timing but is *necessary, not sufficient* for
  real-VBL — verify VBORD=1 in the handler (instruction-level trace) when VBL must
  be the mechanism.
- **Per-frame Lua sampling cannot observe sub-frame execution** — use MAME
  `-debug -debugscript` instruction-level tracing when static analysis is exhausted.
- **Visual gates are operator-run** (Jay confirms on-screen). Keep executor-verifiable
  checks separate from human-gated ones in the dispatch.
- GIME registers `$FF90`/`$FF92` are effectively write-only — verify via downstream
  consequences, not read-back.

---

## 8. Recommended next task — R-p24 / P2.4

**Canonical `intro.s` scene-1 path.** This is the sole remaining INT-1 blocker.
Scope it from the oracle (`C:\Projects\karateka_dissasembly_claude\src` — relevant:
`intro.s`, `scene_dispatch.s`, `attract_*.s`), using `da65` where helpful.
Watch the PIA IRQ re-enable requirement from R-boot (Section 3) if scene-1 takes
input.

Suggested first move: a recon dispatch to map the Apple II scene-1 path and
identify which routines are ABSORBED-HAL vs. need a real port, before any code.

---

## 9. Key docs to consult (in `C:\Projects\karateka_coco3\docs\`)

- `karateka-coco3-design-v0.1.md` — project design, phase plan, repo layout (§11.4)
- `project-state.md` — authoritative phase status + execution history + lessons
- `milestones.md` — P-phase and INT-N milestone tracking
- `p2-scoping-survey.md` — canonical P2 numbering and subsystem trajectory
- `conventions.md` — numbered porting conventions (§§19–23: sub-byte rendering,
  transparency, visible-extent, provenance)
- `interrupt-handling.md` — VBL/IRQ/PIA architecture and decisions
- `claude-orchestrated-methodology-v0_7.md` — the methodology (C-rules)

Oracle repo: `docs/` there holds the disassembly's own catalogs and region maps.

---

*End of briefing. Hand the operator a scope conversation for R-p24 to begin.*
