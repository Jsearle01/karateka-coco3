# Top-of-memory I/O space map — exact hardware-decode boundary (banking gate)

**Read-only doc investigation.** The precise top-of-CPU-address-space map: which
addresses are **hardware-decoded** (always hit I/O/registers/vectors regardless of
the MMU — untouchable by banking) vs **mappable RAM** (usable). Resolves the
`$FF00`-vs-`$FC00` inconsistency the window-map report (`eec7c50`) flagged.
**No design, no code change.**

## The boundary — ONE number: `$FF00`
> **The hardware-decoded I/O page is the top 256 bytes, `$FF00-$FFFF`. RAM extends
> up to `$FEFF`.** `[Lomont §CoCo1/2/3 Register Ref, p.48: "All 3 CoCos have
> hardware interface registers in the 256 bytes from $FF00-$FFFF"; and p.10 CoCo1/2
> map row: `$FF00-$FFFF` = "I/O, machine configuration, reset vectors", listed
> separately from `$E000-$FEFF`]`

**`$FF00`, not `$FC00`.** The window-map report's `$FC00` shorthand and the project
`docs/project/memory-map.md` ("`$FC00-$FEFF Hardware I/O (PIA, SAM) 768 B`",
"`$FC00-$FFFF … hardware-decoded, not RAM`", §4.11) are **wrong** — they invent a
phantom 768 B of I/O. The PIAs are at `$FF00-$FF3F`, not `$FC00`; `$FC00-$FEFF`
is RAM. (memory-map.md correction is a §follow-up; not edited here — read-only.)

## The top-of-memory region table (AC-1)
Going up. Decode column: **HW** = hardware-decoded always (untouchable by banking) ·
**RAM** = mappable DRAM (usable).
| Range | Size | Decode | Contents / device | Source |
|-------|------|--------|-------------------|--------|
| …`$C000-$FDFF` | — | **RAM** | general DRAM (fb B tail lives at `$C000-$FBFF` today) | Lomont p.10; all-RAM mode |
| `$FE00-$FEFF` | 256 B | **RAM** (constant if MC3=1) | secondary interrupt vectors `$FEEE-$FEFF`; the **Vector Page** (`$7FE00-$7FEFF`) appears here when INIT0 `$FF90` bit 3 = 1 | SockmasterGime vec table; Lomont p.10 note; GIME-ref INIT0 |
| `$FF00-$FF1F` | 32 B | **HW** | PIA0 (keyboard, H/V-sync IRQ, joystick) | Lomont p.48 |
| `$FF20-$FF3F` | 32 B | **HW** | PIA1 (cassette, audio, cartridge, CoCo1/2 video) | Lomont p.49 |
| `$FF40-$FF5F` | 32 B | **HW** | Disk controller / SCS (spare chip select, gated by MC2) | Lomont p.50-53 |
| `$FF60-$FF8F` | 48 B | **HW** | misc external cartridge/peripheral decodes | Lomont p.54-59 |
| `$FF90-$FFBF` | 48 B | **HW** | **GIME registers** — INIT0/1, IRQ/timer, video, palette, **MMU `$FFA0-$FFAF`** | GIME-ref; SockmasterGime |
| `$FFC0-$FFDF` | 32 B | **HW** | SAM control (video/page/clock/`$FFDE`ROM/`$FFDF`RAM) | Lomont p.70-72 |
| `$FFE0-$FFF1` | 18 B | **HW** | reserved / not used | Lomont p.73; GIME-ref §16 |
| `$FFF2-$FFFF` | 14 B | **HW** | 6809 **primary interrupt vectors** (RESET/NMI/IRQ/FIRQ/SWI×3) | GIME-ref §16; SockmasterGime |

**I/O page = `$FF00-$FFFF` (256 B), 100% hardware-decoded.** Everything at/below
`$FEFF` is RAM.

## Mode dependence (AC-2)
The `$FF00` boundary is **invariant** — no mode moves it. Three bits change what sits
*below* it (RAM vs ROM, mapped vs constant), none change the I/O page:
1. **MC3 — INIT0 `$FF90` bit 3 ("DRAM at `$FEXX` held constant"):** 1 → `$FE00-$FEFF`
   is a **constant page** (physical `$7FE00-$7FEFF` appears there regardless of the
   MMU task registers), holding the secondary vectors; 0 → `$FE00-$FEFF` follows the
   MMU like ordinary RAM. **RAM either way.**
2. **ROM/RAM mode — MC1/MC0 (`$FF90` bits 1-0) + SAM `$FFDE`(ROM)/`$FFDF`(all-RAM):**
   selects whether `$C000-$FDFF` (MMU blocks `$3C-$3F`) reads system **ROM** or
   **RAM**. All-RAM mode (`$FFDF` written — this project's mode: framebuffers are RAM
   at `$8000-$FBFF`) → RAM. The I/O page `$FF00-$FFFF` stays I/O regardless.
3. **COCO bit (`$FF90` bit 7):** CoCo1/2 vs CoCo3 mode — does **not** move the I/O
   decode (all three CoCos decode I/O at `$FF00-$FFFF`).

## Banking implication (AC-3, HS-4)
- **Draw-framebuffer top edge — safe ceiling `$FDFF`.** RAM runs to `$FEFF`, but
  `$FE00-$FEFF` is the constant secondary-vector page (MC3=1) — clobbering the
  vectors at `$FEEE-$FEFF` breaks interrupts. So the highest a framebuffer / banked
  buffer should reach is **`$FDFF`** (leaving `$FE00-$FEFF` for the vector page and
  `$FF00-$FFFF` for I/O). The current fb B stops at `$FBFF` — **conservative; 512 B
  of RAM (`$FC00-$FDFF`) is left on the table** below the safe ceiling.
- **Block-7 (`$E000-$FFFF`) usable RAM — 7.5 KB, not 7 KB.** `$E000-$FDFF` (7.5 KB)
  is usable RAM; `$FE00-$FEFF` (256 B) is the constant vector page (RAM, reserve for
  secondary vectors); **only `$FF00-$FFFF` (256 B) is I/O** — untouchable.
  **Correction to the window-map report:** block-7 I/O is **256 B (`$FF00-$FFFF`)**,
  NOT 1 KB (`$FC00-$FFFF`); block-7 usable RAM reaches `$FDFF` (7.5 KB), not `$FBFF`
  (7 KB). The report's `$FBFF` fb top is safe but 512 B short of the real ceiling.
- **Vectors always-decoded — interrupt-safe through MMU swaps: CONFIRMED, with one
  condition.**
  - **Primary vectors `$FFF0-$FFFF`:** always hardware-decoded — GIME-ref §16:
    *"In CoCo3 mode with MMUEN=1, these addresses are always decoded by the ROM/I/O
    page regardless of MMU task register settings, ensuring vectors remain accessible
    at all times."* Always reachable through any block-7 remap.
  - **Secondary vectors `$FEEE-$FEFF` (in `$FEXX` RAM):** reachable through a block-7
    remap **only if MC3=1**, which pins `$FE00-$FEFF` to the constant physical Vector
    Page (`$7FE00-$7FEFF`) independent of the MMU. **Banking rule: keep MC3=1** so the
    secondary-vector chain survives when block 7 is remapped to draw a banked buffer.
    With MC3=1 + the hardware-decoded primary vectors, **interrupts are safe across
    MMU swaps.**

## Tech-Ref availability (AC-4, HS-3)
The CoCo3 Tech Ref **is in-repo, but the two Tandy PDFs are scanned images with no
text layer** (`Color Computer 3 Service Manual (Tandy) (1).pdf`, `Color Computer
Technical Reference Manual (Tandy).pdf` → `pdftotext` yields 0 lines). The
extractable authorities used here:
- **`GIME_Reference_Manual.pdf`** — *compiled from the Tandy CoCo3 Service Manual
  (26-3334)*, text-extractable. Source of the register map + §16 vectors-always-
  decoded.
- **`Lomont_CoCoHardware.pdf`** (Chris Lomont, *CoCo 1/2/3 Hardware Programming*
  v0.82) — text-extractable. Source of the `$FF00-$FFFF` 256-byte I/O page, the
  PIA/SCS addresses, and the `$FE00-$FEFF` vector-page note.
- **`docs/ground-truth/SockmasterGime.md`** — the GIME register/vector table (MC3,
  secondary vectors).
**No gap:** the boundary is fully pinned from extractable authorities; the two
scanned Tandy PDFs (image-only) were not needed. (Recommendation, if a future task
needs the raw Tandy scans: OCR them — they currently carry no searchable text.)

## Read-only confirm (AC-5)
No code change; `build/karateka.bin` unchanged (17978 B); `src/`, `build.bat`
untouched. The layout DESIGN consuming this map is stage-2, not here.
