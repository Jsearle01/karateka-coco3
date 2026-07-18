# MAME idioms & quirks — CoCo3 target (the Karateka port)

**Purpose:** a standing, self-contained reference so instrumentation and boot quirks on the
`coco3` target (the `karateka-coco3` port) are **looked up, not rediscovered each dispatch.**
Every entry is traced to the pass that established it and, where one exists, to the **tool**
that exercises it and the **exact command/Lua syntax** that works. Read this before
instrumenting or booting the port under MAME.

**Target:** `mame coco3`, 6809 CPU, ~0.89 MHz slow / ~1.78 MHz double-speed, GIME video +
MMU, WD1773 FDC on a 5.25″ floppy. **Prod baseline (never mutate under a read pass):**
`karateka.bin` SHA-1 `88eba89b15cdf17c8d25e082d2d3e1f3cce57d38`, 17978 B. **Co-equal target:**
a MAME **failure** on coco3 is a **shipping bug** (C-11 / I-BOTH), not deferrable to hardware
— but a MAME **success** on a hardware-edge question is **not** a hardware guarantee (§7).

> This file **incorporates** the earlier `mame-idioms-addendum.md` item A (GIME register
> ordering) and D (pixel-colour provenance), plus the cross-cutting debugger/Lua mechanics,
> tap-GC gotcha, and live-gate flags shared with the apple2e oracle.

---

## 1. The load-bearing one: **the CoCo3 has NO autoboot**
Inserting a disk **runs nothing.** There is no autoboot. The entry point is **Disk BASIC
(DECB)** — you reach the game by having DECB `LOADM` + `EXEC` the binary (or an equivalent
boot front-end). **Do not expect `-flop1 <disk>` to boot the game** — it mounts the disk;
DECB is the ROM running, and it does nothing until told. The boot path is DECB, whose live
low-RAM and IRQ-vector usage **overlap the game's load region** (§5). *Candidate:*
`coco3-has-no-autoboot-entry-is-DECB`. *Established:* disk-boot / DECB-overlap arc.

---

## 2. **Autoboot script ↔ interactive input are mutually exclusive** — use `natkeyboard:post`
MAME's `-autoboot_script` and interactive input don't coexist cleanly here. To drive DECB
(type `LOADM"…"` / `EXEC`) under automation, **post keystrokes to the natural keyboard**:
```lua
manager.machine.natkeyboard:post('LOADM"PROG"\r')   -- note the trailing \r (ENTER)
manager.machine.natkeyboard:post('EXEC\r')
```
Drive it **after boot settles** (~frame 240). The documented method: `disk11.rom` (Disk BASIC
ROM) + `imgtool` (build the image) + `mame coco3` + `natkeyboard:post`, working around the
autoboot mutual-exclusion. *Candidate:*
`mame-autoboot-and-interactive-are-mutually-exclusive-use-natkeyboard-post`. *Established:*
disk-boot / DECB-overlap verdict (AC-4 reachability).

---

## 3. Disk images: **`imgtool`**, `.dsk` vs DMK, and **MAME can't write DMK/SDF back**
- **`imgtool`** builds coco3 disk images for MAME. **A `.dsk` is always 18 sectors/track** —
  no native short-track fixture; a short-count / worst-case track points at **DMK** (or JVC).
- **JVC createopts came back empty; DMK is the format for track-geometry control** (DMK
  createopts unchecked at last note — verify before relying). Boot images are
  **whole-track-aligned** in our `.dsk` layout (keeps raw game tracks contiguous).
- **`.dsk` fixtures are gitignored / throwaway** — a shared fixture once broke an AC (3b-1);
  **generate per-task, don't share.**
- **MAME write-back is format-limited (a real gotcha).** **DMK and SDF are READ-ONLY** in
  MAME's floppy layer (`floptool` shows `dmk r-`, `sdf r-`) — a guest that formats a mounted
  `.dmk` runs fine but the file is **byte-unchanged on exit**. Only `jvc` and `coco_rawdsk`
  save back, and JVC is a **logical** image (discards physical sector order). So you **cannot
  image a guest-formatted disk to inspect its interleave**, and MAME Lua exposes no floppy
  track-data accessor.
  - **Workaround — in-session CPU hijack (§10 proxy pattern):** boot the guest, let it format
    in the in-memory floppy, then from Lua load a standalone read harness and time a read of
    the just-formatted disk (no write-back needed). **Validate the hijack with a control**
    (read a known-good pristine disk the same way; it must reproduce the normal time). Detect
    guest-op completion by watching FDC command writes (`$FF48`) for an idle gap.

*Candidates:* `dsk-is-always-18-sectors-use-DMK-for-short-tracks`,
`mame-dmk-writeback-hijack-proxy`. *Established:* BUILD #3b passes + the DECB-BACKUP refutation.

---

## 4. **Track-17 is the DECB directory** — mid-disk, do not overwrite
The DECB directory lives on **track 17, mid-disk.** A raw game-track span crossing track 17 is
**silent corruption** (bootloader reads directory as game data, or the raw layer overwrites
the directory). **Keep the raw game track range clear of track 17** (or account for it
explicitly); reserved raw tracks must stay **contiguous and clear of 17**, and DECB must
**tolerate the reservation** (it can flag reserved tracks as an inconsistency if done wrong).
*Candidate:* `decb-directory-is-track-17-keep-raw-tracks-clear`. *Established:* BUILD #3b-3.

---

## 5. The disk-boot overlap: **DECB `LOADM` overwrites `$010C`** (M1) — confirmed mechanism
When DECB `LOADM`s the binary, segment-1 lands on DECB's regions — specifically **M1: the
`$010C` IRQ-vector overwrite** (hang at `$C60F` in the trace). `$0100-$01FF` is **contested
during LOADM** — the M1 watchpoint on it pinpointed the overlap. The fix (a separate gated
task, M4): a bootable `.dsk` + a loader that avoids the overlap; the raw-underlayer approach
chains through this. **M2** (a second overlap hypothesis) was **unreachable/unproven** in the
trace — flagged, not smoothed over. *Candidate:* `decb-loadm-overwrites-010C-irq-vector`.
*Established:* disk-boot / DECB-overlap verdict (M1 confirmed by trace).

---

## 6. **The WD1773 FDC** — the CoCo3 disk-controller programming model
- **Four memory-mapped registers** in the `$FF4x` area (command/status, track, sector, data;
  command/status at **`$FF48`**) — confirm base/order against **DECB Unravelled** (register
  base/order is the F1 risk if assumed).
- **DECB assumes slow; it does not FORCE slow**, and **does not use HALT for double-density.**
  The absence of a `$FFD8` (slow-speed poke) in the disk path is the evidence — "assumes
  slow" ≠ "forces slow."
- **Capture the density / motor / settle sequence** (addresses, latch bits, DECB's
  motor/settle/density order) when tracing disk I/O.

*Candidate:* `decb-assumes-slow-does-not-force-slow`. *Established:* FDC read-primitive recon +
DECB speed passes.

---

## 7. What MAME **cannot** answer here — do not over-trust the emulator
MAME shows *behaviour*; only real hardware / a faithful timing model settles some questions.
Flag these **MAME-can't-confirm**; don't launder a clean run into "verified":
- **Fast-speed FDC survival** at ~1.78 MHz — doc-supported-**unsafe** (Lomont fast-speed ROM
  failure; MFM DD polling fails at 0.89 MHz empirically) but the **edge is not
  MAME-authoritative** → real silicon.
- **HALT + NMI-completion timing** — if the fix depends on HALT-enable / NMI-completion and
  there's no INTRQ path, it may be **UN-TESTABLE in MAME**; report as such (may still be
  correct, just not MAME-provable).
- **Seek-Error reliance / FDC edge fidelity** → real silicon.
- **GIME MMU 128K range conflict** — MAME does **not** resolve the doc-vs-hardware MMU-range
  question; tracked as a 25.3-H(divergence) item, not closed by a clean run.

**Rule:** a MAME **failure** on a co-equal target is a real bug (C-11); a MAME **success** on
a hardware-edge question (fast-speed FDC / HALT timing / MMU range) is **not** a hardware
guarantee — hold it as `inferred`, gate to silicon. *Candidate:*
`mame-success-on-a-hardware-edge-question-is-not-a-hardware-guarantee`. *Established:*
DD-slow-speed feasibility, DECB fast-speed viability, GIME-MMU recheck.

---

## 8. Speed control: **force-slow → do-I/O → restore-speed** wrapper
Where slow speed is needed for disk I/O, poke the speed down, do the transfer, restore.
`$FFD8`/`$FFD9` are the speed pokes (slow/fast). The **boot primitive itself doesn't need it**;
the wrapper is owned at the I/O-caller layer. DECB assumes slow but won't protect you at fast
speed (§6) — a missing `$FFD8` in a disk path means "assumes slow," not "forces slow."
*Established:* DD-at-slow-speed feasibility + FDC viability follow-up.

---

## 9. **GIME register write ORDER: palette must be written AFTER video mode** (addendum A)
A real hardware/emulator behaviour, not a style preference: **palette register writes
(`$FFB0-$FFB3`) do not latch correctly until the GIME's video mode is already set.** Writing
palette **before** `$FF98`/`$FF99` leaves the mid-range indices **not rendering** — only the
extremes ($00 black / $3F white) survive; indices 1/2 (orange, blue/cyan) come out wrong or
absent. **Symptom:** a four-band palette test shows only 2 bands; Brøderbund logos render
without orange/blue.

**The required order** (addresses confirmed present in `src/`):
1. **`$FF90`** (CoCo3 mode) **first** — the `$8000+` framebuffer needs CoCo3 mode for CPU
   access.
2. clear buffers.
3. GIME mode/offset/SAM setup: **`$FF98`/`$FF99`** (video mode + resolution), **`$FF9D`/
   `$FF9E`** (offset), **`$FF9C`**, **`$FF9F`**, **`$FFD9`**, **`$FFDF`**.
4. **palette `$FFB0-$FFB3` LAST.**

Empirical (GFXMODE3.ASM + Jay: "the GIME needs to be completely initialized before palette
values are written"), **not** Sockmaster-documented. Cost of not knowing it: the P2.3a
display-init arc burned multiple followups (followup-2 NOT CONFIRMED, chasing palette
*values* when the cause was *ordering*) before the reorder fixed it. *Candidate:*
`gime-palette-writes-must-follow-video-mode-set`. *Established:* P2.3a.6 followup-3 (the
reorder). Tool: `harness/tools/palette_derive.py` (index derivation),
`harness/tools/decode_framebuffer.py` (framebuffer verify).

---

## 9a. **OPAQUE blit + a sub-byte shift writes the shifted-in edge zeros as BLACK bars**
`HAL_gfx_blit_sprite_opaque` stores **every** pixel of the sprite's byte span. When the sprite is
placed with `blit_subbyte > 0`, the sub-byte shift brings **zeros (index-0 black) into the leading/
trailing edge pixels** of the partial edge bytes — and opaque mode writes them, so each shifted
sprite shows a **thin black vertical bar at its left and right edge** (a transparent blit keys these
out, so the bug only appears with opaque). **Symptom:** a stack of opaque backdrop sprites shows
1-2px black bars at every sub-byte-shifted sprite's edges (scene-6 Fuji: A9B8 sub1 + A948 sub2 →
4 bars at X144-145 / X174-175). **Fix (backdrop):** **byte-align** the sprites (`blit_subbyte = 0`);
the ≤3px position loss is negligible for a static backdrop and the shifted-in zeros disappear. (For
sub-pixel-critical actors, pad the cel's edge with the sky index or use a masked/transparent blit
instead.) *Established:* scene-6 Stage-1 Fuji backdrop gate. Tool: `harness/tools/scene6_stage1_confirm.lua`
+ a per-column black-count framebuffer scan.

## 9b. **Index-0 is overloaded (transparent-pad vs meaningful-black) — flood-fill to separate them**
The Apple→CoCo3 converter emits index-0 (black) for BOTH the sprite's meaningful black AND the
transparent bounding-box padding/edges, so a single opaque/transparent blit flag can't render both
right (opaque → padding shows as black boxes/bars; transparent → the real black shows sky). Separate
them by **flood-fill from the cel border through {index-0, index-2(sky-blue)}**: black *reached* from
the border is edge/outline (choose per the art); black *walled off by index-3 white* is interior. On
scene-6's Fuji, Jay's ruling was **edge-connected black = OPAQUE** (mountain outline), **white-
surrounded interior black = TRANSPARENT** (sky-holes → convert to blue), plus **fully-black columns =
trim-boundary artifact → blue**. Tool: `harness/tools/floodfill_bg_sky.py`. *Established:* scene-6
Stage-1 Fuji cel-data fix.

## 10. Instrumentation — **6809 read-taps WORK** (the key cross-target asymmetry) + shared Lua
- **On 6809, program-space read-taps DO fire** — unlike the 6502 oracle side, where opcode
  fetches bypass them. So the single most important cross-target difference: **on coco3 you
  can read-tap an execution address directly; on apple2e you can't** (use a bp / write-tap /
  watch-the-result there). *Candidate:* `6809-read-taps-work-6502-read-taps-dont`.
- **Tap-GC gotcha (cross-cutting, applies here too):** `install_read_tap`/`install_write_tap`
  and `emu.add_machine_frame_notifier` return an object you **must keep referenced** (`_G._tap
  = …`, `_G._n = …`) or it is garbage-collected and **silently stops firing** (empty log =
  false "never happens"). Taps work **headless** (no `-debug`).
- **The debugger/Lua toolkit is MAME-general** (same as apple2e §4) and useful on coco3 for
  boot-time watchpoints and forcing:
  ```lua
  pcall(function() manager.machine.debugger.execution_state="run" end)  -- unpause headless -debug (else HANGS)
  local cpu = manager.machine.devices[":maincpu"]
  cpu.debug:wpset(cpu.spaces["program"], "w", 0x010C, 2, nil, 'tracelog "M1 pc=%04X",pc; go')  -- catch the $010C overwrite
  cpu.debug:bpset(0xADDR, nil, 'pb@0xZP=0xNN; go')     -- force a value at a read
  manager.machine.debugger:command("trace C:/…/out.tr,0")   -- run any debugger cmd from Lua
  ```
  **Syntax:** registers `a b d x y u s pc cc dp` (6809 set); byte read `b@0xADDR`; poke
  `pb@0xADDR=v`; **bp-action `tracelog` is brace-FREE** (`tracelog "…",pc; go`), **trace-command
  action is BRACED** (`{tracelog "…",pc}`) — mixing fails silently. Debugger `printf` is **NOT
  captured headless** — use `tracelog` into an open trace. Write Lua output via `io.open`, not
  `print()` (console not captured).

*Established:* cross-target instrumentation note + the M1 `$010C` watchpoint + the shared
debugger toolkit from the `$6540` pass (commit `634e0c3`).

---

## 11. Visual authority is **Jay's live MAME**, never a Clyde snapshot
Every colour / position / on-screen claim is **Jay's** to gate off a live coco3 MAME run. The
CoCo3 side is **palette-based** (GIME explicit palette) — once colour is fixed on the Apple
read side, the CoCo3 index is baked correctly and there is nothing to re-check at render time;
but **whether it reads right on-screen is still Jay's eye**, and 25.3 is his MAME observation.
A `wpset` PC-confirm shows *code ran*, not *what it looks like*.

**Pixel-colour provenance (addendum D — applies to any capture file):** filename labels
("TRUE"/"reference"/"ground truth") establish nothing; **content + creation method +
timestamp** do. MAME's rendered palette ≠ the conversion tool's constants (MAME blue ≈
`(25,144,255)` vs tool `(0,0,255)`, the latter confirmed in `harness/tools/palette_derive.py`)
— a "ground truth" file with `(0,0,255)` is a tool render. **Automated-check tautology:**
"N/N pixels match the rule" is tautological if the rule generated the predictions — validate
against independently-grounded pixels. *Candidates:*
`tool-render-is-not-a-mame-capture-verify-by-pixel-colour`,
`automated-check-tautology-validate-against-ground-truth-not-rule-predictions`. *Established:*
standing; Content Wave 1 (commit `0b5825b`).

**`-nothrottle` snapshots lie for motion (cross-cutting, mirrored from the apple2e file §6).**
`-nothrottle` is fine for **traces** (full trace fast), but a `-nothrottle` **still-frame
snapshot manufactures phantom motion artifacts** — a mid-frame no-throttle grab ≠ the live
rendered frame. So a coco3 snapshot tool (`gate1_snap.lua` / `comp_snap.lua`, §13) is **not a
live gate**, and colour/position from a snapshot is not authoritative regardless — the on-screen
truth is Jay's live MAME (above). *Established:* the nothrottle/motion caveat +
`nothrottle-snapshots-unreliable-trust-live-gate`.

**Live-gate viewing flags (Jay's preference — viewing-only, no cadence change):**
```
mame coco3 -rompath C:\mame\roms -window -prescale 3 -resolution 1920x1152 -speed 8 \
     -autoboot_script tools\<gate>_live.lua
```
`-speed 8` (fast-watch; `-speed 16`/`-nothrottle` for max), `-prescale 3 -resolution
1920x1152` (3× window, size only). The `*_live.lua` loads the boot-excluded `.bin` and sets
PC. *Established:* `mame-live-gate-viewing-flags`.

### 11a. Prove a behavior-preserving RENDER refactor with a FRAMEBUFFER DIFF (not a re-gate)
For a "changed the code, not the output" refactor (extract a shared draw module, de-dup, reorganize
includes), the objective proof is a **framebuffer byte-diff**, not Jay's eye: dump **Frame A
`$8000-$BBFF`** (15360 B) at the driver's **hold PC** BEFORE the change, refactor, rebuild, dump
AFTER, `cmp` — require **byte-identical** for every affected driver. The pixel diff catches a
sub-visual one-pixel/one-colour drift the eye misses, is instant/repeatable, and doesn't spend a
human gate cycle (the live gate is for NEW visual behaviour). Pair with a single-source `grep` to
prove the structural goal (no duplicated routines remain). Dump via the same DECB-load Lua as the
`*_live`/`*_confirm` scripts, then `for a=0x8000,0xBBFF do o:write(string.char(mem:read_u8(a))) end`.
*Candidate:* `prove-a-render-refactor-with-a-framebuffer-diff-not-a-visual-re-gate`. *Established:*
scene-6 backdrop shared-include refactor (commit `7bfb24c`; both drivers pixel-identical pre/post).
Tool: `harness/tools/*` DECB-load pattern + a Frame-A dump.

### 11b. Render PNGs at NATIVE 1:1 square pixels — MAME `screen:snapshot()` STRETCHES
For oracle-vs-port **by-eye** matching, a MAME `screen:snapshot()` is NOT square-pixel: **apple2e
snaps are 560×192** — each logical HGR dot is rendered as **2 horizontal pixels** (280 logical → 560;
~97% of even-column pairs are identical, differing only at NTSC colour fringes), so at 1:1 the image
is ~2.9:1, badly horizontally stretched vs the real ~4:3 display. Precise visual matching is
impossible against a stretched render. **Fix (standing):** emit native-resolution 1:1 square-pixel
PNGs — **apple2e: halve the 560 width → 280×192** (NEAREST, keep the left of each pair; box-resize
blends the fringe); **coco3: decode the raw `$8000-$BBFF` framebuffer (2bpp MSB-first, 80 B/row) →
320×192** directly (already square, no MAME snapshot involved). Optionally **uniform integer upscale**
(×N NEAREST) for visibility — never fractional. Pixel-aspect is 1:1 **logical** (not 4:3 hardware-
corrected); use the SAME convention for both targets so an apple2e px X lines up with coco3 px X+20
(the port's +20 centering of 280-in-320). *Candidate:*
`render-native-square-pixel-pngs-mame-snapshot-stretches-apple2e-560-is-280-doubled`. *Established:*
wall-top reference capture 2026-07-14 (commit TBD). Tool: `harness/tools/render_square.py`
(`--apple2e <560png>` / `--coco3 <15360 dump>` / `--scale N`); pairs with `fbdump_stage.lua`.

### 11c. Render a cel PREVIEW in the REAL palette + a NON-palette transparency mark (decode the mask)
A sprite preview must use the **actual 4-index scene palette** the cel will ship in (0 blk / 1 orange
/ 2 blue / 3 white — MAME-authoritative RGB), and show **transparency in a colour that CANNOT occur
in that palette** (a **gray checkerboard**), with the convention **stated** in the image/report. Two
traps this avoids, both real defects on this project: (1) a **debug placeholder colour** (magenta)
reads as "the art is wrong" when it's a render artifact — Jay's gate flagged a magenta sheet whose
composite (same bytes) looked correct; the tell that it's the render not the art is *same source,
different output*. (2) The **index-0 collision**: opaque-black (`b`) and transparent (`t`) BOTH pack
to colour index 0 — distinguished ONLY by the mask plane. So a preview must **decode the MASK** (mask
00 → transparent-checker, 11 → `PALETTE[colour]`), not the colour index — ignore the mask and `t`
looks like whatever bg (blue), or a wrong flag paints it magenta. **Render FROM the packed
color+mask bytes** (and assert the decode matches the authored grid) so the preview is faithful to
what ships AND validates the packing. Emit **1:1 AND integer-NEAREST magnified** (factor stated).
*Candidate:* `render-cel-preview-in-real-palette-decode-the-mask-checkerboard-transparency-not-a-debug-colour`.
*Established:* wall post/rail preview fix 2026-07-15 (2nd preview defect after the 560-stretch).
Tool: `harness/tools/gen_wall_post_rail.py` (`render_from_planes`).
**Refinement (2026-07-16, HS-10):** DEFAULT the transparent background to the **real sky (index 2)** —
it shows the cel as it will actually appear (why the composite read right). Use the checkerboard
**only** when the cel's own palette **includes** the bg index (then sky is ambiguous). Post/rail
palette is {w=3,b=0} with no blue → sky default is unambiguous. `--bg sky|checker` (default sky).

### 11d. A cross-platform side-by-side MUST be reconciled onto ONE stated coordinate system
Comparing oracle (apple2e) vs port (coco3) pixel positions is worse than useless unless both are on
**one coordinate system with the mapping STATED** — else it invents a phantom offset. Apple HGR = 280
logical px (7 px/byte); CoCo3 = 320 px (4 px/byte); the bridge is the port's **+20 centering**:
`CoCo3_px = Apple_px + 20` ((320−280)/2), and the native oracle render is 280 wide (the 560 MAME snap
halved, §11b) → **pad it +20 left** into 320-space. Then integer-NEAREST only (no interpolation — it
blurs the boundaries being read), **stack vertically (oracle top / port bottom) with columns aligned**
(X-checking is the point, not literal left-right), overlay a **byte ruler** (4-px CoCo3 boundaries +
mark the target bytes), crop to the band, emit **1:1 + magnified**, and **print the mapping on the
image**. Sanity check the reconcile: oracle post (Apple col 23 sh5 = px166) +20 = **px186** must equal
the port target byte 46 sub 2 = 46*4+2 = **px186** — they land together only because sub 2 is the fix.
*Candidate:* `cross-platform-side-by-side-needs-one-stated-coordinate-system-plus20-integer-nearest`.
*Established:* wall-top placement side-by-side 2026-07-16. Tool: `harness/tools/walltop_side_by_side.py`.

### 11e. Decompose authored art into an OPAQUE block + uniform FILLS to avoid a masked-blit primitive
When authored art seems to need a per-pixel masked composite blit (opaque-black `b`=0 vs transparent
`t`=0, both index 0), **check whether the transparency is separable by geometry** before building the
primitive. The scene-6 wall post (9×7) put **every** `t` in **one column** (col 6) that is itself a
**uniform repeating rail** → the art decomposed into (a) **cols 0–5 = a fully-opaque block** (no `t`
anywhere → no mask; the plain opaque blit suffices — and `HAL_gfx_blit_sprite_opaque` DOES sub-byte
shift 0–3, sharing `blit_dispatch`), and (b) **col 6 = the rail = direct horizontal ROW-FILLS** (every
tiled column identical → white/black row-runs, no cel/mask/tiling). This **designed out** the
substantial Stage-4 masked-composite primitive entirely. **Assert the decomposition** (no `t` in the
opaque region; the transparent column == the fill pattern) — don't assume it. Watch the **§9a edge**:
an opaque *shifted* blit stamps the shifted-in leading pixels black (pre-shift with a sky-filled edge,
or flag for the gate). *Candidate:*
`decompose-authored-art-into-opaque-block-plus-uniform-fills-to-avoid-a-masked-blit-primitive`.
*Established:* wall-top 9×7 placement 2026-07-16 (`scene6_cliff_walltop.s`; framebuffer-diff-verified,
zero leak outside the band). The combatants may still need the primitive (non-decomposable art).
*Gotcha caught by the framebuffer-diff:* `ldd #colour` **clobbers B** — if a fill routine takes the
row in B, load the colour into **U** (survives `MUL`) instead; the diff flagged a stray row-0 fill.

---

## 12. Quick command idioms (coco3)
```bash
# Boot to DECB + drive it (needs disk11.rom present):
mame coco3 -flop1 <image.dsk>        # then natkeyboard:post 'LOADM"PROG"\r' / 'EXEC\r' (§2)
# Build an image:  imgtool ...        # .dsk = 18 sec/track fixed; DMK for track geometry (§3)
# Operator live-watch (§11):  -speed 8 -prescale 3 -resolution 1920x1152 -window -nomax
# Fast headless trace:  -nothrottle -video none -sound none -seconds_to_run <N> -script tools/<lua>.lua
# Headless DEBUGGER run:  add -debug AND unpause in Lua (execution_state="run", §10)
```
- **Windows-path-in-Lua gotcha (shared):** `"C:\k…"` is an invalid Lua escape → the script
  **silently fails** and MAME runs the full duration with **no tap, no error.** Use forward
  slashes (`C:/…`) or `\\`.
- **Script must be at MAME's cwd** (`-script tools/foo.lua` resolves from the run repo) —
  copy from `harness/tools/` if needed.
- **`-seconds_to_run` is EMULATED seconds**, not wall-clock; if a `-nothrottle` run drags for
  minutes real-time, throttle isn't in effect — fix the invocation.
- **Never mutate prod under a read pass:** `karateka.bin` `88eba89…` must stay byte-identical.

---

## 13. Tool index — which tool exercises each idiom
| Idiom | Tool |
|---|---|
| live visual gate (boot-excluded `.bin` + set PC) | `harness/tools/gate1_live.lua`, `gate2_live.lua`, `comp_live.lua` |
| gate trace / framebuffer verify | `harness/tools/gate1_trace.lua`, `gate2_trace.lua`, `decode_framebuffer.py` |
| GIME palette index derivation | `harness/tools/palette_derive.py` |
| sprite convert / parity / render | `harness/tools/sprite_convert.py`, `flip_parity_inplace.py`, `sprite_visualize.py` |
| snapshot capture (⚠ not a live gate) | `harness/tools/gate1_snap.lua`, `comp_snap.lua` |

---

## Appendix — candidate names (MAME cluster, coco3)
Sourced to specific disk-boot / FDC / GIME / display-init passes:
- `coco3-has-no-autoboot-entry-is-DECB`
- `mame-autoboot-and-interactive-are-mutually-exclusive-use-natkeyboard-post`
- `dsk-is-always-18-sectors-use-DMK-for-short-tracks` · `mame-dmk-writeback-hijack-proxy`
- `decb-directory-is-track-17-keep-raw-tracks-clear`
- `decb-loadm-overwrites-010C-irq-vector` · `decb-assumes-slow-does-not-force-slow`
- `mame-success-on-a-hardware-edge-question-is-not-a-hardware-guarantee`
- `gime-palette-writes-must-follow-video-mode-set`
- `6809-read-taps-work-6502-read-taps-dont`
- `tool-render-is-not-a-mame-capture-verify-by-pixel-colour`
  · `automated-check-tautology-validate-against-ground-truth-not-rule-predictions`
- **cross-cutting (shared, in the apple2e file's appendix):**
  `mame-frame-notifier-return-must-be-referenced-or-gcd`,
  `mame-debugger-printf-not-captured-headless-use-tracelog`,
  `mame-bp-action-tracelog-is-brace-free-trace-action-is-braced`.

---

## Cross-reference
The **Apple IIe / oracle** quirks (6502 read-tap bypass, watch-the-seed, seed-determinism of
the attract loop, `FD_STATEFORCE`, tap-every-draw-entry, trace-through-a-boundary,
`-nothrottle` motion-snapshot lie, boot-time-static bytes, the full debugger/Lua toolkit) are
in the companion **`mame-idioms-apple2e-oracle.md`**. The two targets differ most at §1/§10:
**6809 read-taps work; 6502 read-taps don't** — the single most important cross-target
difference. The debugger/Lua mechanics (`execution_state="run"` headless-unpause, `bpset`/
`wpset`, `b@`/`pb@`, `debugger:command`, trace+`tracelog`, the brace rule) and the
tap-GC/visual-provenance/`-seconds_to_run` gotchas are **shared** and appear in both files.

---

## Verify a VBL animation runs headless — sample the frame-index ZP + check for dwell-drift
To confirm a port ANIMATION actually runs (not just assembles), load the driver `.bin` into
coco3 (fbdump DECB-inject + set PC=exec, `harness/tools/fbdump_stage.lua` pattern) and sample
the controller's **frame-index ZP** (e.g. `cl_idx $40`, `cl_dwctr $41`) + `page_register $50`
every N frames. Two things fall out at once:
- **It runs** iff the index cycles through its range (crawl: `cl_idx` 0→6→0) and `page_register`
  toggles ($20↔$40 = double-buffer flipping).
- **Each render fits ONE VBL** iff the measured per-frame **dwell does not DRIFT** — if a heavy
  render (clean-restore + composite blit) overran its VBL, `HAL_time_vbl_wait` would miss the
  next VBL and the dwell would stretch run-to-run. Exact, stable dwells (21 / 7×5 / 60 VBL as
  authored) ⇒ the render completes within budget. This is a cheaper one-VBL-budget check than
  cycle-counting the render path. *Established:* climb-crawl first-animation build 2026-07-13
  (`scene6_climb_crawl_driver`, `climb_controller.s`).

### 11f. Verdict a placement on the OBSERVED framebuffer, never on the intended value
A placement report claimed "posts sub 2 → sub 1 → px 185" and was verdicted CONFIRMED on the *claim* —
the value that shipped was never measured. (It later turned out the sub-1 HAD landed, but that was luck,
not evidence.) **Fix the class like the art-bytes check does — with evidence:** (1) quote the placement
lines from the BUILT source (`grep`/`sed` of the real file post-edit, not a restatement of intent), and
(2) DUMP the framebuffer and report the OBSERVED pixel columns / band rows (`fbdump_stage.lua` +
per-pixel decode). If observed ≠ expected, STOP — do not reconcile in prose. Corollary: also measure the
CURRENT state before applying a "correction" — the delta may already be there (here the post was already
at px185, so "1px left" meant px184, not the dispatch's stated px185). *Candidate:*
`verdict-placement-on-the-observed-framebuffer-not-the-intended-value`. *Established:* wall-top placement
correction 2026-07-16 (`scene6_cliff_walltop.s`; posts measured at px184/268 post-edit).

### 11d. A "don't commit until X" hold needs an explicit RELEASE TRIGGER + SCOPE, or it strands work
The 07-12 Stage-3 WIP was held under *"don't commit Stage-3 until the static image is correct."* The
hold had **no release trigger and no scope**: when the static image *was* gated (the wall-top, months
later), nobody re-derived the hold, so the WIP sat in the working tree — and it had become
**load-bearing** (`scene6_backdrop.s`'s `draw_fuji_cels`/`fill_walltop` are called by the shipped
fallback). Consequences: (1) **the gated render was not reproducible from HEAD** — it lived only on
disk; (2) every subsequent *"file X unchanged"* byte-identity claim was **quietly ambiguous**
(unchanged vs HEAD, or vs the churned disk?). Confirm load-bearing cheaply before assuming: `git stash
<file>` → build → observe the failure (here: `Undefined symbol fill_walltop`/`draw_fuji_cels`) → pop.
**Rule:** a commit-hold must name (a) the exact **release trigger** and (b) its **scope** (which files
/ which change), or unrelated work accreting in the same working tree gets stranded and byte-identity
claims made afterwards are unsound. *Candidate:*
`a-dont-commit-until-X-hold-needs-an-explicit-release-trigger-and-scope`. *Established:* churn commit
2026-07-18 (`891dc63`).

### 11e. A transition/carryover artifact is ONLY visible in the LIVE sequence — per-item renders LIE
A **carryover** artifact (previous-pose pixels surviving into the next frame because the restore bbox
doesn't cover the previous pose's extent) exists **only in the running animation** — the state is
`restore-previous → draw-current`. **Rendering each pose standing alone on a clean substrate CANNOT
reproduce it** (there is no "previous" to leak), so every frame comes back innocent and the case is
**falsely closed**. This is exactly how the prior orange diagnosis answered the wrong question (it
tested the *substrate alone* at rows 152–168 — faithful, true — but the artifact is *carryover at the
player's lower body*). **Rule:** to capture carryover, run the gated build live and dump the DISPLAYED
framebuffer **once per pose, in sequence**, detected from the controller's frame index — never
independent per-pose renders. *Candidate:*
`carryover-artifact-only-in-live-sequence-per-item-renders-falsely-exonerate`. *Established:* per-pose
climb capture 2026-07-18 (`climb_pose_capture.lua`).

### 11f. Live per-pose capture: gate on the DWELL counter, not just the frame index (`cl_idx` reads 0 pre-init)
Capturing pose 0 of the crawl by "first frame where `cl_idx`($0040)==0, a couple frames after PC=exec"
grabbed a **half-drawn substrate**: the substrate blitting takes several frames after `PC=exec`, and
`cl_idx` reads 0 the whole time (ZP is 0 before `cl_init` writes it), and `page_register`($0050) still
read `$00` (uninitialized). The dump had only 123 rows of content vs 175–188 for real frames — an
invalid "anim_00." **Fix:** gate the capture on `cl_dwctr`($0041) `!= 0` — it is 0 until `cl_init` runs
`cl_load_dwell` (loads dwell 21) and is *never* left at 0 mid-crawl (`cl_tick` reloads it the same tick
it hits 0). So `cl_dwctr != 0` is the objective "init complete, pose 0 rendered on the fully-drawn clean
substrate" signal — the sanity anchor for HS-2 (anim_00 clean = clean **by construction**, first render
with no predecessor). Also: the DISPLAYED buffer = **opposite** of `page_register` (it holds the *back*
buffer; `cl_render` presents then toggles), so dump `(pr==$20)?$C000:$8000`. And per §11b, dump the
framebuffer **memory** and decode square-pixel — `scr:snapshot()` stretches and cannot show a 1px line.
*Candidate:* `gate-live-pose-capture-on-dwell-counter-not-frame-index-cl-idx-reads-0-preinit`.
*Established:* per-pose climb capture 2026-07-18.
