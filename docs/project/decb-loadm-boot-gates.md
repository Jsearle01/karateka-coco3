# DECB LOADM+EXEC front-end — the three verification gates (BUILD #3b-3)

**Verified against** `docs/ground-truth/disk-basic-unravelled.pdf` (Disk Basic Unravelled II,
the annotated DECB DOS source), line numbers per the extracted `build/tmp/decb.txt`. All
three gates settled BEFORE authoring (HS-1). **All PASS.**

## CoCo DECB low-RAM map (frames all three gates)
DECB's own storage is all ≥ $0600 (it zeroes $0600-$0989 at init, decb.txt:4053-4054):
DBUF0=$0600, DBUF1=$0700, FAT RAM $0800+, FCBs $094A+. **DECB uses nothing in $0100-$05FF.**
BUT $0100-$015F holds **Color/Extended BASIC's RAM vectors** — COMVEC=$0120, EXPJMP=$011D,
USR/RVEC hooks (decb.txt:17203,17245,1758-1778). The 6809 system stack lives HIGH in RAM
(top of user RAM, set by Color BASIC ROM), NOT in $01xx.

## G1 — FAT / granule reservation — **option (i) sufficient**
- FAT is **track 17, sector 2**; 68 granules, **9 sectors/granule, 2 granules/track**
  (decb.txt:83,309-313,6236). Directory on track 17 sectors 3-11.
- FAT byte: **$FF = free**; **bits 6&7 set = last granule** (+ used-sector count in bits 0-5);
  **bits 6&7 clear = link to next granule** (decb.txt:312-313,3792-3830).
- **FREE** scans only the FAT ($FF=free), never the directory (decb.txt:14755-14807).
  **DIR** reads only the directory (decb.txt:14258-14286). **Allocator** (LC7BF) skips any
  non-$FF granule, never consults the directory (decb.txt:6188-6238).
- **VERDICT (G1):** marking granules used in the FAT with **NO directory entry** is fully
  tolerated — allocator won't reuse them, FREE is correct, DIR shows no phantom file. A dummy
  directory entry is NOT required. **Best practice:** mark each reserved granule **$C9**
  (last-granule, 9 sectors) so no forward link dangles. [decb.txt:6188-6238,14755-14807]

## G2 — LOADM transfer-address / EXEC handoff — **LOADM"f":EXEC → transfer addr**
- ML file format: preamble **$00, len(2), load-addr(2)**, data; postamble **$FF, $0000,
  exec-addr(2)** (decb.txt:552-562).
- **LOADM does NOT auto-execute** — it loads and returns to `OK` (decb.txt:14929-14999).
- LOADM does **`STD EXECJP`** (EXECJP = DP $009D) with the file's transfer address
  (decb.txt:14935,17243). **Bare `EXEC` jumps through [EXECJP]** (parser in Ext BASIC ROM,
  $B4AA). So our stub (DECB binary, load=$8000, exec=$8000) → `LOADM"BOOT"` sets EXECJP=$8000
  → bare **`EXEC` jumps to $8000**. Boot command: `LOADM"BOOT":EXEC`. [decb.txt:14935]
- Directory entry (32 B): name(8)+ext(3)+**type(1)=2 for ML**+ascii(1)+first-granule(1)+
  bytes-in-last-sector(2) (decb.txt:338-351,3856-3888).

## G3 — $0100-$01FF during LOADM (THE ACUTE GATE) — **Class B (safe, pattern already met)**
- LOADM reads sectors into the FCB buffer (≥$0940) and copies to the load address ($8000 for
  BOOT); it does **not** read into or depend on $0100-$04FF (decb.txt:14957-14969).
- **LOADM fully completes before EXEC** (G2) — no in-flight DECB I/O during any later overwrite.
- `EXEC` transfers OUT of BASIC via [EXECJP]→$8000. The bootloader (3b-2, proven) then:
  (i) `orcc #$50` masks IRQ+FIRQ **first** (so no IRQ dispatches through $01xx vectors during
  the overwrite), disables the PIA IRQs, sets $FF90; (ii) `lds #$7F00` — its own stack, out of
  the $0100-$48FF game region; (iii) reads the game into $0100-$48FF; (iv) `jmp $0200` — **never
  returns to BASIC**. Because control never re-enters the interpreter, the clobbered
  $0100-$015F BASIC vectors are **inert** — never dispatched again.
- **CLASS B — safe WITH the boot pattern the bootloader ALREADY implements** (own stack out of
  range + interrupts masked + never return to BASIC). It would be **C (hostile)** only if the
  loaded code tried to `RTS` back to `OK` or call a ROM entry that dispatches through the
  clobbered $01xx vectors AFTER the overwrite — which the bootloader never does.
- **Consistent with the other two split-$01xx angles:** the margin probe (game stack + data
  safe), the streaming prediction (disk NMI pre-cleared), and now G3 (LOADM/BASIC don't need
  $01xx after EXEC hands off) all agree — after EXEC the page is ours.

## Gaps (authority-limited, do not change the verdicts)
1. Exact top-of-stack numeric address + the cold-start `LDS` are in Color BASIC ROM (not this
   book); known to be HIGH, far above $4823 → the EXEC-window stack doesn't collide with the
   game region. (Confirm precise value in color-basic-unravelled.pdf if ever needed.)
2. The EXEC parser (`JMP [EXECJP]`) is in Extended BASIC ROM; the WRITE side (`STD EXECJP` in
   LOADM) is confirmed here — sufficient for the boot chain.
