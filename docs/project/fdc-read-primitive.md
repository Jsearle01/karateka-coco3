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
> **CORRECTION (post-review, verdict on `ab02228`):** the first draft marked
> MFM@0.89 as an *arithmetic* FAIL and recommended "run at 1.78 MHz." Both were
> overreach. Corrected below: the FAIL is **empirical/margin, not arithmetic**, and
> the 1.78 MHz "fix" is **contradicted by the CoCo3 authority** — it is a contested
> branch, not the resolution. The safe default is a **single-density loader disk**.
> **FURTHER REFINED (see "Space budget and single-density viability" below):** the
> single-density-whole-disk option is subsequently **ruled out** by capacity
> (~87.5 KB SD < ~128 KB content) **and** the DD-only DECB bootstrap — so the live
> branches reduce to (b) DD+HALT and (c) DD+1.78. Read that section for the reversal.

Byte period = DRQ service window (must read Data before the next byte assembles or
**Lost Data**). 5.25″ 300 RPM: FM 125 kbps → **64 µs/byte**; MFM 250 kbps →
**32 µs/byte**. A minimal 6809 per-byte poll loop (read Status, rotate DRQ→carry,
branch, read Data, store, count, loop) ≈ **24 cycles**:
| CPU | cyc time | per-byte loop | FM (64 µs) | MFM (32 µs) |
|-----|----------|---------------|-----------|-------------|
| **0.89 MHz** | 1.12 µs | ~27 µs | ✅ **MAKES** (2.4× margin) | ⚠️ **makes on paper (27<32) but margin ~5 µs — fails in practice** |
| **1.78 MHz** | 0.56 µs | ~13.5 µs | ✅ comfortable | (arithmetically fine, but see fast-speed contra below) |

**On the MFM@0.89 cell — state it correctly:** by the arithmetic, 27 µs < 32 µs, so
it *makes the window on paper* by ~5 µs (~4-5 cycles). The FAIL is **not** carried by
the numbers; it is carried by (a) that margin being too thin to survive SAM
DRAM-refresh / video-DMA cycle-stealing, and (b) DECB Unravelled's empirical
testimony — *"the slow clock speed … will not allow data to be transferred in the
'normal' method … not enough time … when operating at double density"* — the exact
reason DECB built the DRQ→HALT trick. **A defensible FAIL, but an empirical/margin
FAIL, not an arithmetic one.**

**On "just run at 1.78 MHz" — CONTESTED, do not build against it.** The arithmetic
says fast speed makes the MFM window, but **whether the WD1773 is even accessible at
1.78 MHz on the CoCo3 is unverified and contradicted by the authority:**
- **Lomont p.11 (CoCo3-aware):** *"a lot of the timing-dependent things in the CoCo
  BASIC ROMs won't work right at any speed other than 'slow', like reading or writing
  cassettes and **disks**."* This aligns with Jay's stated instinct that the
  controller does not work at fast speed.
- **Mechanism, unresolved (A vs B):** Lomont attributes the breakage to *"the ROMs"*
  → suggests **(A) software delay-calibration** (the ROM's cycle-counted FDC
  status-valid delays — e.g. DECB's `EXG A,A` pauses at `LC0F0` — run half-length at
  2×, so the ROM misreads status). Our own primitive would be *immune* to (A) (we
  recalibrate delays). But the docs do **not** rule out **(B) cartridge-port
  SCS/register-strobe timing** going marginal at 1.78 MHz — which no software fixes.
  A→a custom fast driver might work; B→it can't. **The in-repo docs do not decide
  A vs B**; only a MAME/hardware test (or the CoCo3 Service Manual schematics, which
  are image-only) can. **Until decided, treat fast-speed FDC access as unsafe.**
- **Reframing the HALT trick (independence):** its existence is *also* evidence that
  fast speed was **not** a usable option — running the CPU at 2× is strictly simpler
  than wiring DRQ→HALT through the cartridge; DECB chose the hardware handshake, which
  is what you do only when fast speed isn't available/safe. (CoCo1/2 had no fast mode
  at all, so this is suggestive, not conclusive — but it points away from "go fast.")

**On Q1 (does RSDOS force slow for I/O?):** the Unravelled disassembly is **CoCo1/2**
Disk BASIC — it never touches `$FFD8/$FFD9` because those SAM speed registers didn't
exist on the CoCo1/2; its disk code is **slow-only by construction**. On the CoCo3 the
disk ROM is the same code (`disk11.rom`) and never switches to fast — so RSDOS disk
I/O runs at **0.89 MHz**, convergent with "slow is the sanctioned disk-I/O speed."

## Decision tree for the boot read (design step chooses; not a reviewer/recon call)
- **(a) Single-density (FM) loader disk @ 0.89 MHz — SAFE DEFAULT.** 64 µs window vs
  ~27 µs loop → comfortable polled read, **no HALT, no fast-speed dependency**. Costs
  standard-RSDOS double-density compatibility — but **we control the `.dsk` build**
  (`imgtool` / our own format, per `disk-boot-decb-overlap.md`), so a custom
  single-density boot format is ours to make. **Sidesteps both the fast-speed question
  and the HALT trick.** Strongest candidate if Jay's fast-speed concern holds.
- **(b) Double-density (MFM) + DRQ→HALT handshake @ 0.89 MHz.** Accept DECB's
  mechanism; **revisits HS-4** (the pure-polled goal is abandoned for the transfer
  inner loop). Works at slow speed; more complex; couples to the NMI/HALT path.
- **(c) Double-density (MFM) + 1.78 MHz polled — CONTESTED.** Requires fast-speed FDC
  access to be proven safe (Q2 above), which is unverified and Jay-doubted. **Do not
  build against this until a MAME/hardware test settles A vs B.**

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
  pre: interrupts masked; DSKREG motor-on + density set; CPU 0.89 MHz
       (per the decision tree: FM single-density @ 0.89 = safe default; the
        MFM@1.78 path is CONTESTED — do not assume it)
```
**Boot-vs-runtime home — RESOLVED out-of-band by Jay (post-review):** a **shared
source routine**, assembled into **both** the framebuffer stage-1 loader **and** the
resident game image at their respective load addresses — **no PIC requirement**. (The
recon's original "open" note is superseded.) Still a bare-metal reader per
`disk-boot-decb-overlap.md` (naive DECB LOADM is unusable).

## CANDIDATES (report-note only)
- `src/hal/coco3-dsk/file.s:5-7` — `HAL_file_init` no-op stub with `[no-ref: CoCo3
  FDC register addresses]`; **this doc resolves that `[no-ref]`.** Reclassification
  candidate for the design step.
- `WD177x-00.pdf` / `WD179X.PDF` are **image-only** (no text layer) — sourcing
  note; OCR if their raw text is ever needed. (The WD1773 PDF sufficed.)
- DECB uses command `$D0` (Force Interrupt) at init to reset the controller
  (Unravelled `LC0F0`) — useful for the primitive's init/abort, datasheet Type IV.

---

# Space budget and single-density viability

**Read-only follow-up (t0 `2026-07-05T04:01:01`).** Three measurements that decide
the single-vs-double-density loader branch: (1) how much data the original game
occupies, (2) CoCo single-density capacity, (3) whether stock RSDOS can read
single-density at all. **This partly reverses the previous "single-density is the
safe default" lean — see the synthesis.** No code/disk modified.

## Authorities + image + tooling (AC-1)
- Docs: `WD 1773 Floppy Disk Controller.pdf`, `WD177x-00.pdf`,
  `disk-basic-unravelled.pdf` (Disk BASIC Unravelled II — covers 1.0 + 1.1, WD1793
  controller). HS-1/HS-2 cleared.
- Disk images (oracle, read-only): `../karateka_dissasembly_claude/refs/Karateka.woz`
  (233 451 B, WOZ1 flux-level — preserves the copy protection);
  `../karateka_dissasembly_claude/dumps/karateka.dsk` (143 360 B = 35×16×256, the
  cracked sector image the disassembly uses).
- Tooling: `imgtool` present; no wozardry / applecommander / a2rimage.

## Oracle footprint (AC-2, P1 — MATCHED; raw-occupancy method per HS-3)
`imgtool dir apple2_dos33 karateka.dsk` → **"Unrecognized format"**: the disk has
**no standard DOS 3.3 catalog** (copy-protected/custom, as HS-3 anticipated). So the
split is by **raw track-occupancy** (data vs blank/low-entropy), *not* a VTOC read —
"couldn't read the catalog" is distinguished from "measured empty":
- **32 of 35 tracks carry data** (nonzero + high distinct-byte count); **1** low-
  entropy fill track (T6, single repeated byte); **2** blank (T33-34, all-zero).
- **Content ≈ 128 KB** (32 data tracks × 4096 B); free/unformatted ≈ 12 KB (3 tracks).
- **The game essentially fills its disk** (91 % of tracks). F1 (mostly-empty) did
  **not** fire.
- **PROXY CAVEAT (P1):** this is the *Apple* footprint. The CoCo port's graphics
  (320×192×2bpp, different palette/sprite format) and code (6809 vs 6502) differ, so
  128 KB is a **ballpark for content volume, not a byte-for-byte transfer**. Also
  it's the *cracked* image (data possibly consolidated vs the protected original).

## Single-density capacity (AC-3, P2 — MATCHED est.)
From the WD1773 data rates (datasheet line 147: **125 kbit/s FM / 250 kbit/s MFM**;
line 666: 128/256/512/1024-B sectors in either FM or MFM, "For FM, DDEN=1") + 5.25″
300 RPM track geometry:
| Density | Track cap (300 RPM) | Sectors/trk (256 B) | Disk (35 trk) | |
|---------|--------------------|--------------------|---------------|--|
| **DD (MFM)** | ~6250 B | **18** (RSDOS std) | **35×18×256 = 161 280 = 157.5 KB** | cited (RSDOS) |
| **SD (FM)** | ~3125 B | ~**10** | **35×10×256 = 89 600 ≈ 87.5 KB** | **ESTIMATE** |
**SD ≈ 56 % of DD.** *(HS-4: the SD figure is an estimate — FM ≈ half the bit
density → ~half the sectors; exact SD sectors/track depends on the format/gap choice
(datasheet line 1314: 30 B gap FM / 43 B MFM). Arithmetic shown; flagged estimate.
DD 18-sector figure is the RSDOS standard.)*

## RSDOS single-density read capability (AC-4, P3 — MATCHED: DD-only)
DECB/RSDOS **operates in double density.** Unravelled §FDC (line 400): *"…operate
the disk drives in **double density** mode at the low (.89 MHz) clock speed"* — and
the entire transfer mechanism (the DRQ→HALT trick) is described *"when operating at
double density."* The standard RSDOS disk is 35×18×256 **double density**, and the
DECB directory (track 17) + boot structures are DD. **No single-density read path is
documented** in the standard DECB entry; the DSKREG density bit (b5) is set to double
for normal operation. *(Honesty note: I confirmed the explicit double-density
operation statement and the absence of any documented SD path; I did not locate a
single "SD unsupported" instruction — the finding rests on DD-operation being
explicit and no SD path existing. F2 (RSDOS reads SD) did NOT fire.)*

## Bootstrap implication (AC-5) — the catch
Because stock DECB reads **DD only**, an **SD boot disk cannot be loaded by the
standard DECB entry.** So SD is usable **only for game-DATA tracks read by our own
polled primitive** (which sets DSKREG b5=0 itself) — **never for the DECB-loadable
stage-1.** And the first stage (getting *any* custom loader into RAM) must come
through the ROM/DECB, which reads DD → **the boot-visible portion of the disk must
be DD**, regardless of what the data tracks are.

## Space-budget synthesis + fit verdict (AC-6)
| | capacity | fits ~128 KB content? |
|--|----------|----------------------|
| SD whole-disk | ~87.5 KB | **NO** (128 > 87.5) |
| DD whole-disk | ~157.5 KB | **YES** (~30 KB headroom) |

**The ~128 KB proxy content does NOT fit a single SD side, but DOES fit a single DD
side.** Combined with the bootstrap catch, this **narrows/reverses the previous
task's "single-density is the safe default" lean (`bb3c3a3`, branch a):**
- **Branch (a) "single-density WHOLE disk" is NOT viable** — it fails on *both*
  counts: too small for the content **and** unbootstrappable by DECB.
- **The disk is double-density** (mandatory for the DECB bootstrap; required for the
  content to fit one side). So **our primitive must read DD tracks** — which pushes
  back to **branch (b) DD+HALT @ 0.89** or **branch (c) DD+1.78 (contested)** for the
  data reads. The comfortable-polled-FM-read benefit of SD is *only* reachable via a
  **mixed-density disk** (DD boot/stage-1 + a few SD data tracks), and even that
  can't hold ~110 KB of data in SD on the remaining tracks — so SD cannot carry the
  bulk. **SD is effectively ruled out as the storage strategy.**
- **Net for the loader design:** plan on **DD storage**, and resolve the DD-read
  mechanism via branch (b) HALT (revisits HS-4) or by settling the branch-(c)
  fast-speed A-vs-B question with a MAME/hardware test. The single-density escape
  hatch is closed by capacity + bootstrap.

*(If the CoCo port's actual content turns out materially smaller than the 128 KB
proxy — plausible, different asset format — SD whole-disk is still dead on the
bootstrap catch alone; only a mixed-density design could use SD, and only for a data
subset.)*

## CANDIDATES (report-note)
- This section **refines `bb3c3a3`**: the prior "branch (a) single-density = safe
  default" is withdrawn — SD is ruled out by capacity (~87.5 KB < ~128 KB) **and**
  the DD-only DECB bootstrap. The live branches are (b) DD+HALT and (c) DD+1.78.
- `../karateka_dissasembly_claude/refs/Karateka.woz` (flux) vs `dumps/karateka.dsk`
  (cracked sector image) — the footprint used the cracked `.dsk`; a flux analysis
  (needs wozardry, absent) could refine the original data/free split.
