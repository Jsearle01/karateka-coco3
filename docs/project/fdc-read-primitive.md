# FDC read-sector primitive — design reference (WD1773 + DECB Unravelled)

**Read-only recon.** The **polled single-sector READ** primitive only (write /
format / streaming-IRQ deferred). Every **address** is DECB-Unravelled-sourced;
every **command byte / status bit / timing** is WD1773-datasheet-sourced; nothing
is memory-sourced. This is a reference for the design step, **not code**.

**Division of labor (I-3):** the CoCo exposes the WD1773 as memory-mapped
registers whose *addresses* only the CoCo authority (DECB Unravelled) can supply;
the *register order, command semantics, status bits, and timing* come from the
WD1773 datasheet. Where both speak (register order), they agree.

## Authorities (AC-1; HS-1/HS-2 cleared)
- `docs/ground-truth/WD 1773 Floppy Disk Controller.pdf` — text-extractable; the
  chip datasheet (register semantics, commands, status, timing).
- `docs/ground-truth/WD177x-00.pdf`, `docs/ground-truth/WD179X.PDF` — **both
  image-only (0 text lines)**; used as cross-check *targets* but the WD1773 PDF
  carried the needed content, so the scans weren't required. (Finding: OCR them
  if a future task needs their raw text.)
- `docs/ground-truth/disk-basic-unravelled.pdf` — the CoCo Disk BASIC authority
  (`$FF40` DSKREG, `$FF48-$FF4B` base, density/HALT context).

## Register map (AC-2, P1 — MATCHED)
Base `$FF48` (Unravelled p… "ADDRESS $FF48 $FF49 $FF4A $FF4B"); register order +
A1/A0 selection (datasheet, "0 0 Status / 0 1 Track / 1 0 Sector / 1 1 Data"):
| CPU addr | A1 A0 | Read | Write | Authority |
|----------|-------|------|-------|-----------|
| `$FF40` | — | (write-only latch) | **DSKREG** control latch | addr: Unravelled p.(FDC/§`$FF40`) |
| `$FF48` | 0 0 | **Status** | **Command** | addr: Unravelled; fn: WD1773 |
| `$FF49` | 0 1 | Track | Track | addr: Unravelled; fn: WD1773 |
| `$FF4A` | 1 0 | Sector | Sector | addr: Unravelled; fn: WD1773 |
| `$FF4B` | 1 1 | Data | Data | addr: Unravelled; fn: WD1773 |

`$FF40` is **write-only**; DECB shadows it in RAM (`DRGRAM`) — a bare-metal driver
must likewise keep its own RAM image (can't read back the latch).

## DSKREG `$FF40` bit layout (AC-3, P2 — MATCHED; Unravelled §`$FF40` Control Functions)
| Bit | Function | Values |
|-----|----------|--------|
| 0 | Drive select 0 | |
| 1 | Drive select 1 | |
| 2 | Drive select 2 | |
| **3** | **Drive motor enable** | 0=motors off, 1=motors on |
| 4 | Write pre-compensation | 0=off, 1=on (Tandy: tracks >22) |
| 5 | **Density** | **0=single (FM), 1=double (MFM)** |
| 6 | Drive select 3 | |
| 7 | **HALT enable** | 0=disabled, 1=enabled — **we leave 0 (HS-4)** |

Bit 7 (HALT) is DECB's DRQ→HALT trick. **Our polled primitive sets bit 7 = 0**
(HALT disabled) and does **not** use the NMI-on-INTRQ path (HS-4). Drive 0, motor
on, single-or-double density, HALT off → e.g. `%00_1_0_1_00_1` families below.

## Motor is a latch bit, not a command (AC-4, P3 — MATCHED)
WD1773 datasheet pin table: **pin 20 = RDY/ENP on the WD1773** ("READY/ENABLE
PRECOMP") vs **MO (Motor On) on the WD1770/WD1772**. The **1773 has no Motor-On
output** — cross-checked with the flag summary: "h = Motor On Flag (Bit 3)
**(1770/2)**". So motor control is **only** the DSKREG bit-3 latch (Unravelled),
never a controller command. Confirmed by the *absence* of an MO pin on the 1773.
(Corollary: on the 1773, command **bit 3 is repurposed** — see AC-5.)

## Read Sector command byte (AC-5, P4 — MATCHED; datasheet Type II flag summary)
Type II Read Sector format (bit 7…0): `1 0 0 m S E C 0`
| Bit | Name | Datasheet meaning | Our value |
|-----|------|-------------------|-----------|
| 7-5 | opcode | `100` = Read Sector | `100` |
| 4 | **m** Multiple Sector | 0=single, 1=multiple | **0** (single) |
| 3 | **S** Side Compare (1773 only) | side # to compare (0/1) | **0** |
| 2 | **E** Settle delay | 0=none, 1=+30 ms | **0** (Type I verify already settled) |
| 1 | **C** Side Compare enable (1773 only) | 0=disable, 1=enable | **0** (no side compare) |
| 0 | — | 0 for Read (a0 is Write-only) | **0** |

→ **Read Sector = `$80`** (single, side 0, no side-compare, no extra settle). Use
`$84` only if a post-seek 30 ms settle is wanted without a verify seek. **Note the
1773 repurposing:** bit 3 = Side-Compare-value and bit 1 = Side-Compare-enable
(1773), *not* the 1770/2 motor/precomp bits — do not carry the 1770/2 meanings.

## Positioning — Type I Restore / Seek (AC-6/P6, AC-8/HS-5)
Type I: Restore = `0 0 0 0 h V r1 r0` (`$0x`); Seek = `0 0 0 1 h V r1 r0` (`$1x`).
- **V** (bit 2) Verify: **1** — verify head landed on the destination track (reads
  an ID field, compares Track reg, checks CRC; adds the 30 ms settle). Recommended.
- **h** (bit 3): the datasheet ties "h = Motor On/spin-up (1770/2)"; the 1773 has
  no MO, so bit 3 is not motor control here — **set 0**, flagged as a 1773-vs-1770/2
  nuance (spin-up is a 1770/2 concept; the 1773 uses the RDY input instead).
- **r1 r0** (bits 1-0) **stepping rate — WD1773 column only (HS-5):**
  `00`=6 ms, `01`=12 ms, `10`=2 ms, `11`=3 ms. **Use `00` = 6 ms/step** (safe for
  stock 5.25" drives). **Clock-domain assumption:** the WD1773 runs a **fixed
  8 MHz ±0.1% reference** (datasheet); these rates apply as-tabulated. The 179x
  family's "double when CLK=1 MHz" caveat is for the 179x external-clock wiring and
  **does not apply** to the 1773. (Do **not** use the WD1770-00 column 6/12/20/30.)
  → Restore+verify+6 ms = `$0C`? no — `0000 V=1 r=00` = `0000_0100` = **`$04`**;
  Seek+verify+6 ms = **`$14`**.

## Ordered polled read sequence (AC-6, P5/P6)
Interrupts masked (`ORCC #$50`); HALT off (DSKREG bit 7 = 0). Sector byte count =
**256** (RSDOS standard sector length; our `.dsk` build controls this).
1. **Select + motor on** — write DSKREG `$FF40` = drive-select 0 + motor(bit3=1) +
   density(bit5) + HALT(bit7)=0. Keep a RAM shadow. *(Unravelled)*
2. **Motor spin-up wait** — DECB uses a drive-ready timer; poll RDY / wait the
   drive's spin-up (~0.5–1 s cold). *(Unravelled: motor-off timer / ready)* — see
   the F4 gap note.
3. **Restore** (`$04`, verify, 6 ms) if head position unknown → head to track 0;
   wait Busy-clear (Status bit 0 → 0) / INTRQ. *(datasheet Type I)*
4. **Seek** — load **Track**? no: load the **Data register** with target track,
   write Seek `$14`; wait Busy-clear. (Or step-by-step.) *(datasheet Type I)*
5. **Load Sector register** `$FF4A` = target sector (1-based per format). *(datasheet)*
6. **Issue Read Sector** — write `$80` to Command `$FF48`. *(datasheet Type II)*
7. **Polled transfer loop** — per byte: poll Status `$FF48` **bit 1 (DRQ)** until
   set; read Data `$FF4B` (clears DRQ); store to dest; repeat ×256. *(datasheet:
   "DRQ … appears as status bit 1 during Read")*
8. **Completion + error check** — on Busy-clear/INTRQ, read Status once; check
   **bit 4 RNF**, **bit 3 CRC**, **bit 2 Lost Data**. Any set → error. *(datasheet:
   Lost Data bit 2, CRC bit 3, RNF bit 4)*

**No NMI, no HALT** — pure register poll (HS-4 / I-4).

## Status bits used (datasheet, Type II Read)
bit 0 Busy · **bit 1 DRQ** · **bit 2 Lost Data** · **bit 3 CRC Error** · **bit 4
Record Not Found** · bit 5 Record Type · bit 6 (0) · bit 7 Not Ready. INTRQ (and
Busy→0) signals completion; reading Status clears INTRQ.

## DRQ service-window arithmetic (AC-7, F3 — the feasibility gate)
Byte period = DRQ service window (must read Data before the next byte assembles or
**Lost Data**). 5.25″ 300 RPM: FM 125 kbps → **64 µs/byte**; MFM 250 kbps →
**32 µs/byte**. A minimal 6809 per-byte poll loop (read Status, rotate DRQ→carry,
branch, read Data, store, count, loop) ≈ **24 cycles**:
| CPU | cyc time | per-byte loop | FM (64 µs) | MFM (32 µs) |
|-----|----------|---------------|-----------|-------------|
| **0.89 MHz** | 1.12 µs | ~27 µs | ✅ **MAKES** (2.4× margin) | ⚠️ **FAILS** (only 5 µs margin; SAM DRAM-refresh + video DMA jitter → Lost Data) |
| **1.78 MHz** | 0.56 µs | ~13.5 µs | ✅ comfortable | ✅ **MAKES** (2.4× margin) |

**MFM @ 0.89 MHz is the one that fails** — and this is **authoritative, not just
arithmetic**: DECB Unravelled states plainly *"The slow clock speed of the Color
Computer will not allow data to be transferred in the 'normal' method … there is
just not enough time for this when operating at double density"* — the exact reason
DECB invented the DRQ→HALT trick. **Verdict:** a polled read is feasible for
**(a) single density (FM) at either CPU speed, or (b) double density (MFM) only at
1.78 MHz.** Since `imgtool coco_jvc_rsdos` makes a **standard double-density RSDOS
disk (MFM)**, the primitive must **switch the CPU to 1.78 MHz (`$FFD9`) for the
transfer** (safe bare-metal, interrupts masked) — or the loader disk is authored
single-density. This is a real design constraint, surfaced (F3 = FALSE for
MFM@0.89, TRUE otherwise).

## Prior-art sweep (AC-9, P7 — MATCHED: no reusable code)
- **pop-coco3:** repo **not present** in this topology (`../pop-coco3` absent) —
  no sweep possible; consistent with Jay's "no disk loader" ruling.
- **karateka_dissasembly_claude:** one hit —
  `docs/karateka-coco3-design-v0.1.md:121` "Floppy disk system via WD1773
  controller" (a design line, **no code**). The Apple oracle uses a *different*
  controller (soft-sectored state machine), **not reusable**.
- **this repo:** `src/hal/coco3-dsk/file.s` — `HAL_file_init` is a **no-op stub**
  (`[no-ref: CoCo3 FDC register addresses — resolve from CC3-TR]`, `andcc #$FE;
  rts`). A placeholder, **not an implementation** — this doc is its `[no-ref]`
  resolution. Other hits are `cfg/coco3.cfg` (MAME floppy config) + doc mentions.
- **Statement: no reusable FDC read code exists.** The primitive is derived fresh
  from the two authorities.

## Primitive interface (AC-10)
```
disk_read(track, sector, count, dest) -> (bytes_read, error)
  in : track  (0..34)      target cylinder
       sector (1..18)      target sector (RSDOS 256-B sectors)
       count  = 256        bytes to transfer (one sector)
       dest   (X)          destination buffer pointer
  out: bytes_read          bytes transferred
       error  (CC.C + A)   0=ok; else RNF(bit4)/CRC(bit3)/LostData(bit2) surfaced
  pre: interrupts masked; DSKREG motor-on + density set; CPU 1.78 MHz if MFM
```
**OPEN (do not resolve — for the design step):** the **boot-vs-runtime home** of
this code. A cold boot needs the reader resident *before* any RAM image loads
(boot-sector loader / ROM-call), yet the runtime engine also wants a reader —
**shared resident copy vs the loader chaining through a resident copy** is
unresolved. Named here; belongs to the loader-design task (ref
`disk-boot-decb-overlap.md`: naive DECB LOADM is unusable, so a bare-metal reader
like this is exactly what a real loader needs).

## CANDIDATES (report-note only)
- `src/hal/coco3-dsk/file.s:5-7` — `HAL_file_init` no-op stub with `[no-ref: CoCo3
  FDC register addresses]`; **this doc resolves that `[no-ref]`.** Reclassification
  candidate for the design step.
- `WD177x-00.pdf` / `WD179X.PDF` are **image-only** (no text layer) — sourcing
  note; OCR if their raw text is ever needed. (The WD1773 PDF sufficed.)
- DECB uses command `$D0` (Force Interrupt) at init to reset the controller
  (Unravelled `LC0F0`) — useful for the primitive's init/abort, datasheet Type IV.
