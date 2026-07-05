# Disk-boot / DECB-overlap — doc map + DECB-boot TRACE (M1 confirmed)

**Read-only, two-phase.** The harness loads `karateka.bin` **directly into RAM,
bypassing DECB** (`mem:write_u8` + set PC) — the real disk-boot path is never
exercised. This investigation maps the risk (Phase 1) and **proves it by booting
through DECB in MAME** (Phase 2). **Verdict: M1 (load collision) CONFIRMED by
trace — a naive `LOADM"KARATEKA"` HANGS during load; the code never loads.** No
fix here (separate gated task). Prod `karateka.bin` unchanged (17978 B); the test
`.dsk` + Lua were throwaway (outside the repo, removed).

## AC-0 — boot mechanism
- **Build:** `lwasm --decb` → `build/karateka.bin`, a **DECB-format (LOADM-
  compatible) segmented binary**: preamble `00 lenHi lenLo addrHi addrLo`, data,
  postamble `FF 00 00 execHi execLo`. Segments: **`$0100`+18** (IRQ dispatch
  stubs), **`$0200`+8238**, **`$223E`+9702** → code image **`$0100-$4823`**;
  **EXEC=`$0200`**.
- **Intended path (design doc `karateka-coco3-design-v0.1.md`):** "bare-metal
  CoCo3, floppy initially… single HAL target: RSDOS floppy disk (coco3-dsk)…
  bootable `build/karateka_fresh.dsk`… WD1773." So: RSDOS floppy, `LOADM`/`EXEC`
  or a boot loader. **BUT that bootable `.dsk` is an unbuilt M4 deliverable** —
  there is **no `.dsk` build step in `build.bat` and no disk tooling in-repo**.
- **Current reality:** `karateka.bin` is **direct-loaded by the harness only**
  (`harness/tools/*.lua`, `tests/scripted/*.lua`: parse the DECB blocks, write
  bytes to RAM, set `PC=EXEC`). DECB is entirely bypassed; the real boot path is
  **defined but unrealized/untested**.

## AC-1 — DECB resident map (from docs, cited)
Authority: `disk-basic-unravelled.pdf`, `color-basic-unravelled.pdf`,
`SockmasterGime.md`.
- **Direct page `$0000-$00FF`** — Color BASIC + Disk BASIC variables (survives our
  load: our image starts at `$0100`).
- **RAM interrupt vectors / dispatch `$0100-$01xx`** — DECB installs its
  interrupt routing here (secondary vectors JMP to handlers). SockmasterGime:
  `IRQ $FFF8(ROM) → $FEF7 → $010C`; `FIRQ $FFF6 → $FEF4 → $010F`; etc. **DECB's
  disk reader is interrupt-driven → these `$010x` vectors must stay intact during
  a disk read.**
- **`$0400-$05FF`** — text screen (VIDRAM=`$0400`).
- **Disk RAM `$0600` up** (disk-basic-unravelled p… "At the beginning of Disk RAM
  are two sector-length (256-byte) I/O buffers… **DBUF0** [`$0600`] is the main
  I/O buffer… involved in virtually all disk data transfers… DBUF1 [`$0700`]…
  Following these are four buffers for the File Allocation Tables… After these are
  the variables Disk Basic uses"). Init (`LC00C`): zeroes `DBUF0…DFLBUF`, then
  `FCBADR = DFLBUF+$100`, 2 default FCBs (`FCBACT=2`), then `TXTTAB` above. So
  DECB's disk working set spans **`$0600` … ~`$0Exx`** (DBUF0/1, FAT buffers, DP-
  adjacent variables, FCBs).
- **Stack** — Color BASIC cold start sets `S = TOPRAM`; measured **`S=$7F2B`** at
  the prompt (top of the DECB 64K RAM window). **Not** in `$0100-$4823` → the
  stack is *not* the collision.
- **LOADM** (`LCFC1`): opens the file via an FCB, reads preamble/postamble +
  data blocks, streams to the load address — the FCB's 256-byte buffer + DBUF0 are
  live throughout.

**M1 static reasoning:** our load image **`$0100-$4823` subsumes DECB's entire
disk working set** — the `$0100` interrupt vectors AND the `$0600-$0Exx` buffers/
FCBs — all written *while DECB is mid-load using them*. Predicted: LOADM cannot
survive. **Watch-list for Phase 2:** `$0100-$0111` (IRQ vectors), `$0600` (DBUF0),
the FCB region, PC, and whether `$0200`/`$4000` ever populate.

## AC-2 — our footprint
Load: DECB segments `$0100-$0111`, `$0200-$220D`, `$223E-$4823` (17978 B on disk,
EXEC `$0200`). Run: adds runtime BSS — CLEAN_BUF `$4A00`, FLIP_BUF `$7E80`,
framebuffers `$8000-$FBFF` — **not in the load image** (written at runtime).

## AC-3 / AC-4 — the DECB-boot TRACE (Phase 2; trace is authority, HS-4)
**Reachable:** `disk11.rom` (Disk Extended Color BASIC) ships inside
`coco3.zip`; `imgtool create coco_jvc_rsdos … ; put … KARATEKA.BIN` builds a
`.dsk`; `mame coco3 -ext fdc -flop1 kboot.dsk` boots DECB to the "OK" prompt
(PC in the ROM poll loop `$A7D5`, `S=$7F2B`, `DP=$00`).
**Instrumentation (HS-6):** `-autoboot_command` and `-autoboot_script` are
**mutually exclusive** (both hook the one autoboot slot) — a script silently
disables the typed command. Working method: the Lua script itself posts keys via
`manager.machine.natkeyboard:post("LOADM\"KARATEKA\"\n")` **and** observes memory
(verified: a `POKE16000,42` posted this way lands `$3E80=42`).

**The trace — `LOADM"KARATEKA"` posted at the prompt:**
| checkpoint | PC | DBUF0 writes | `$0200` | `$4000` |
|-----------|-----|------|------|------|
| pre-LOADM | `$A7D5` (poll) | 0 | `$00` | `$FF` |
| during | `$C60F` (Disk BASIC ROM) | 512 (2 sectors) | `$00` | `$FF` |
| +10 s | `$C60F` — **frozen** | 512 — **frozen** | `$00` | `$FF` |

**HANG — never returns; code never loads.** Characterization (PC samples over
consecutive frames): `$010D → $010C → $FEF9 → $FEF7 → $C60F → $C60F …` and:
- `DBUF0 $0600` = `4B 41 52 41 54 45 4B 41 42 49 4E 02` = **"KARATEKABIN\x02"** —
  the *directory entry*: LOADM read the directory, found the file, began loading.
- `$0100-$0111` = `3B 12 12 3B 12 12 …` (RTI/NOP) — **our dispatch-stub segment
  loaded over DECB's `$0100` RAM interrupt vectors**.
- `$0200`=`$00`, `$4000`=`$FF` — the main code segments **never loaded**.

**M1 mechanism (trace-confirmed, exact):** LOADM loads segment 1 (`$0100-$0111`)
**first**, overwriting DECB's IRQ routing at `$010C` with our RTI stub. DECB's
disk reader is interrupt-driven; the next IRQ (`$FFF8→$FEF7→$010C`) lands on our
stub instead of DECB's disk-service handler → the read never completes → the CPU
spins `$C60F ↔ $FEF7/$010C`. **The load hangs before the `$0200+` code is ever
written.** The static hypothesis (footprint subsumes DECB's `$0600-$0Exx`) is
*confirmed and refined*: the **first** fatal collision is the `$0100` interrupt-
vector region (loaded first), which kills DECB before it even reaches the `$0600`
buffer overlap.

**M2 (post-EXEC state mismatch): UNREACHABLE via LOADM** — M1 hangs the load, so
the binary never starts under DECB; M2 cannot manifest on this path. The DECB-vs-
harness initial-state divergence surface *is* captured for when a real loader
exists: **DECB@prompt** `DP=$00, S=$7F2B, MMU $FFA0-A7 = 38 39 3A 3B 3C 3D 3E 3F,
TR($FF91)=$1B (task 1)`; **harness** writes bytes to the power-on MMU map and sets
`PC=$0200` with the binary's `HAL_sys_init` establishing GIME/MMU/DP itself. (The
binary re-establishes its own state, so M2 is *likely* benign — but unproven,
because M1 blocks reaching it.)

## AC-5 — verdict + banking implication
- **Verdict: M1 — real disk-boot collision. A naive BASIC `LOADM` of
  `karateka.bin` cannot work** (hangs during load, code never loads), because the
  load footprint `$0100-$4823` overwrites DECB's live interrupt vectors + disk
  buffers. This is the classic reason CoCo software boots via a **loader** (raw
  sector reads, no DECB FCB/buffer/vector dependency), not a BASIC LOADM into low
  RAM. The intended bootable `.dsk`/loader is the **unbuilt M4 deliverable**.
- **Banking implication:** M1 is about the **load footprint** (`$0100-$4823`),
  which banking does **not** change — the framebuffers (`$8000-$FBFF`) are runtime
  BSS, never loaded. **So banking neither causes nor worsens M1.** But the meta-
  finding is load-bearing: the **entire** memory placement (code *and* the banking
  design) is **harness-only-validated**; the real boot path doesn't exist yet.
  **When the M4 loader is built it must (a) not depend on DECB's low-RAM
  structures during load (raw boot, or relocate/stage), and (b) the banking
  placement must be re-validated under that real loader** — neither is proven
  today.

## Reproduce (trace)
```
imgtool create coco_jvc_rsdos kboot.dsk ; imgtool put coco_jvc_rsdos kboot.dsk build/karateka.bin KARATEKA.BIN
mame coco3 -ext fdc -flop1 kboot.dsk -rompath <roms> -autoboot_script <lua>
  # lua posts: manager.machine.natkeyboard:post('LOADM"KARATEKA"\n') at the prompt,
  # then watch PC (freezes $C60F) + $0200/$4000 (never load).
```

## Read-only confirm
No fix, no code/layout change; `build/karateka.bin` unchanged (17978 B). Test
`.dsk` + Lua were throwaway (in `C:\karateka-capture`, outside the repo, removed).
