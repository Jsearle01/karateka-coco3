# HALT-based DD boot read primitive — design

**Read-only design (t0 `2026-07-05T04:43:12`).** Branch (b) DD+HALT is settled
(`a91d080`: the polled loop clears DD-at-0.89 only thin, ~+4.6 cyc + a DP hack;
HALT has no margin problem by construction). This designs the **BOOT** read
primitive around the CoCo HALT/NMI mechanism — adopting the *mechanism*, **not**
DECB's vector layout (the M1 lesson). Not code; the build is a separate gated
dispatch. Recon findings live in `fdc-read-primitive.md`; this is the design
artifact, separated by concern.

## Authorities (AC-1)
- **Behavioral authority:** `disk-basic-unravelled.pdf` — how DECB *uses* the HALT
  mechanism (DSKREG b7 enable, INTRQ→NMI completion, the transfer loop). This is
  what the design needs.
- **Physical wiring (HS-2):** the gate-level DRQ→HALT and INTRQ→NMI wiring is in the
  `Color Computer 3 Service Manual` schematics — **image-only (no text layer)**. Not
  fabricated, and **not needed to design**: Unravelled's behavioral description is
  sufficient. The one gate-level detail we deliberately do NOT pin (the exact CPU
  instruction boundary at which HALT takes effect) is flagged image-only —
  OCR/logic-trace only if a build ever needs it.
- **Vector/window authorities (in-repo):** `io-space-map.md`, `window-block-map.md`,
  `mc3-function-confirm.md`, `SockmasterGime.md`.

## HALT-enable mechanism (AC-2, P1 — MATCHED)
**DSKREG `$FF40` bit 7 = 1 enables the DRQ→HALT coupling.** Unravelled (line 398):
*"When the halt flag is high, the DRQ signal from the FDC will be connected to the
halt input of the 6809 … the 6809 will not process any instructions while the FDC is
processing data to or from the 6809."* So with b7=1, the CPU is **stalled by hardware
between bytes** and released when DRQ asserts (a byte is ready). **The transfer needs
no DRQ poll and no timing margin — the hardware does the waiting.** This is the whole
reason (b) has no margin problem: **the CPU physically cannot outrun the disk.**

## End-of-command mechanism (AC-3, P2 — MATCHED)
**INTRQ (command complete) → NMI**, and INTRQ **auto-clears HALT b7.** Unravelled
(line 398/400): *"when an FDC command such as … READ SECTOR is completed an interrupt
(INTRQ) is generated … The Color Computer connects this INTRQ signal to the … NMI pin
… whenever an FDC command (except `$D0` FORCE INTERRUPT) is completed, an NMI will be
generated"*; and b7 *"will be cleared whenever the FDC generates an INTRQ."* DECB
stores a jump vector (`DNMIVC`) + a flag (`NMIFLG`) so its NMI handler exits the
transfer loop. **We replace DECB's `DNMIVC`/`$01xx` structure with our own vector
(AC-5).**

## HALT transfer loop (AC-4, P3 — the "no margin" core)
DECB's proven shape is a **HALT-paced, NMI-terminated** read-store loop — the CPU
reads bytes as HALT releases them, and NMI breaks out at end-of-sector:
```
        ; DSKREG b7=1 (HALT armed); Read Sector $80 already issued; dest in X
rdloop  LDA   $FF4B        ; data reg — HALT holds the CPU here until the byte is ready
        STA   ,X+          ; store
        BRA   rdloop       ; loop forever; INTRQ→NMI breaks out at end-of-sector
```
**Why no margin (contrast to the polled loop):** the CPU is frozen between bytes, so
Lost Data from CPU-slowness *cannot* occur — the failure mode that made the polled
loop thin (`a91d080`) is absent by construction. **Loop termination is NMI, not a
byte count** (Unravelled: *"how to get out of this loop … solved with software"* via
INTRQ→NMI); our NMI handler unwinds the loop to the completion path. *(A byte-count
safety bound may be added defensively — a build detail.)* **HS-2 note:** the exact
instruction boundary at which HALT freezes the CPU is a cartridge-wiring detail
(schematic image-only); the design relies only on the behavioral guarantee (CPU can't
outrun the FDC), which is sufficient.

## NMI vector siting — the M1 lesson, verified (AC-5, P4 — MATCHED)
The 6809 NMI chain on the CoCo3 (SockmasterGime line 22):
```
NMI  $FFFC (ROM, hardware-decoded, unchangeable)  →  $FEFD  →  handler
```
`$FFFC-$FFFD` (ROM) always yields `$FEFD`; **`$FEFD-$FEFF` is our NMI secondary
vector** — a `JMP`/`LBRA` we install to point at *our* handler (DECB pointed it at
`$0109`; we do not inherit that). Siting, cross-checked against the in-repo maps:
| region | extent | contains our vector/handler? | safe? |
|--------|--------|------------------------------|-------|
| game load | `$0100-$4823` (`disk-boot-decb-overlap.md`) | no | ✅ below `$FExx` |
| framebuffer loader | `$8000-$FBFF` (`window-block-map.md`: fb B tail ends `$FBFF`) | no | ✅ below `$FE00` |
| **constant Vector Page** | **`$FE00-$FEFF`** (`io-space-map.md`: RAM, constant under **MC3=1**) | **`$FEFD` vector + a tiny handler in `$FE00-$FEED`** | ✅ **above both loads; MMU-constant** |

**Siting decision:** put the NMI secondary vector at `$FEFD` **and** the tiny NMI
handler in the free part of the constant Vector Page (`$FE00-$FEED`, 238 B below the
six secondary vectors at `$FEEE-$FEFF`). Both are **above the game load (`$4823`) and
above the framebuffer loader (`$FBFF`)**, and **constant under MC3=1** (pinned to
physical `$7FE00-$7FEFF` regardless of the MMU — `io-space-map.md` / `mc3-function-
confirm.md`). **Neither load can overwrite our NMI vector or handler.** This is the M1
lesson satisfied precisely: **our** vector, **safe** siting, **no** inheritance of
DECB's `$0100-$01xx` dispatch block (the exact structure whose collision crashed the
naive LOADM — `disk-boot-decb-overlap.md`). *(Depends on MC3=1, which prod already
sets and the banking design already requires — `mc3-function-confirm.md`.)*

## Full boot read sequence (AC-6, P5)
Interrupts: IRQ/FIRQ masked (`ORCC #$50`); **NMI stays enabled** (it's the completion
signal). Per sector (256 B, RSDOS DD):
1. **Init (once):** install `JMP our_nmi` at `$FEFD`; place `our_nmi` in `$FE00-$FEED`;
   set the completion flag cleared.
2. **DSKREG `$FF40`:** drive-select 0 + motor on (b3) + **density=DD (b5=1)** + **HALT
   enable (b7=1)** + precomp (b4, if track>22). Keep a RAM shadow (write-only latch).
3. **Motor spin-up wait** (drive-ready timer / RDY) — cold ~0.5–1 s.
4. **Position:** `Restore $04` (verify, 6 ms) if head lost → track 0; then load Data
   reg = target track, `Seek $14` (verify); wait Busy-clear (Status b0→0) / INTRQ.
5. **Sector reg `$FF4A`** = target sector (1-based).
6. **Read Sector:** write `$80` to Command `$FF48`.
7. **HALT transfer loop** (AC-4): `rdloop LDA $FF4B / STA ,X+ / BRA rdloop` — HALT
   paces it; **INTRQ→NMI** at end-of-sector fires `our_nmi`, which unwinds the loop
   and sets the completion flag. (INTRQ also auto-clears HALT b7.)
8. **Status check:** read Status `$FF48` once; error if **b4 RNF / b3 CRC / b2 Lost
   Data** (Lost-Data should never set under HALT — a set bit means a hardware fault,
   not CPU slowness). Retry (DECB uses an attempt counter) or fail.
9. **Next sector/track:** repeat 5–8; re-Seek on track change.

## Shared-source home + deferred wrappers (AC-7, P6, HS-4)
Per Jay's resolution: this primitive is **one source routine assembled into both** (i)
the framebuffer **stage-1 loader** (at its `$8000+` load address) and (ii) the
**resident** game image (at its address) — each linked at its own address, **no PIC**.
The NMI-vector install (step 1) is part of the primitive's init in each. **The boot
primitive is sequential** — it completes **before any banking flip** (HS-4), so it
needs no banking-coexistence logic. **Deferred, named-not-designed:** the
resident/streaming copy will additionally need (a) a **banking-coexistence wrapper**
(HALT transfer during a mid-game banking flip — a streaming concern) and (b) a
**speed-transition wrapper** if any fast-mode is ever used around I/O. These are
streaming-only and out of scope here.

## Deferred-open list (AC-8)
- **Streaming/banking HALT-coexistence** — mid-game disk transfer concurrent with a
  banking flip (block-7 remap while HALT is active). Streaming concern; not boot.
- **Runtime speed-transition wrapper** — only if fast-mode is ever used near I/O
  (the fast-mode FDC question is the contested branch (c), `bb3c3a3`, unresolved).
- **(a-DD) thin-margin polled fallback** (`a91d080`) — revivable if HALT's NMI/HALT
  coupling ever collides with the banking/interrupt design; would need a hardware
  Lost-Data test.
- **Gate-level HALT/NMI wiring** (HS-2) — Service Manual schematics are image-only;
  OCR/logic-trace only if a build needs the exact halt instruction boundary.
- **Motor spin-up / drive-ready timing** — the exact ready-poll (RDY vs a timer) is a
  build detail; DECB uses `RDYTMR`.

## Read-only confirm
No code/`.s`/build/harness; `build/karateka.bin` unchanged (SHA-1
`88eba89b15cdf17c8d25e082d2d3e1f3cce57d38`, 17978 B). One new design doc.
