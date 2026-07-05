# MC3 (INIT0 $FF90 bit 3) — full-function confirmation (high-placement banking gate)

**Read-only doc confirmation.** Before the banking layout locks **high placement**
(draw slot `$C000-$FBFF`, blocks 6-7; freed `$8000-$BBFF` contiguous with code) —
which makes **MC3=1 load-bearing** (the draw slot spans block 7, block 7 holds the
secondary-vector page `$FE00-$FEFF`, a whole-block MMU remap would move it, MC3=1's
constant-page override protects it) — confirm what MC3 *actually* does: is it purely
the constant-vector-page bit, or does it carry other functions / interactions /
costs? **No design, no code change.**

## Verdict (one line)
**MC3=1 is a cheap, idiomatic, single-function invariant that prod ALREADY sets and
already depends on.** Its only documented function is the constant-vector-page; its
only cost is committing `$FE00-$FEFF` (256 B, which our layout doesn't use as free
RAM); prod runs `$FF90=$4C`/`$6C` (both MC3=1) today. **→ High placement proceeds;
banking's MC3=1 is a NO-OP, not a change.**

## AC-0 — the constant-vector-page function (confirmed + cited)
MC3=1 makes `$FE00-$FEFF` a **constant page** — the physical Vector Page
(`$7FE00-$7FEFF`, holding the secondary interrupt vectors) appears there regardless
of the MMU task registers. Three independent in-repo sources, all agreeing:
- **GIME ref** (compiled from Tandy Service Manual 26-3334), `$FF90` INIT0 table:
  bit 3 **MC3 = "DRAM at `$FEXX` held constant."** Standard CoCo3 operating value
  given as **`$4C`** = `0100_1100` (COCO=0, MMUEN=1, IEN=0, FEN=0, **MC3=1**, MC2=1).
- **Lomont** (*CoCo 1/2/3 Hardware Programming* v0.82, p.60 INIT0): **MC3 "1 = Vector
  RAM at FEXX enabled, 0 = disabled."** p.10 note: *"the Vector Page RAM at
  `$7FE00-$7FEFF` (when enabled) will appear instead of the RAM or ROM at
  `$FE00-$FEFF` (see INIT0 (`$FF90`) Bit 3)."*
- **SockmasterGime.md**, INIT0 bit 3: **MC3 "1=RAM at FExx is constant (secondary
  vectors)."** Vector chain: `$FFF2(ROM) → $FEEE → $0100`, etc.

## AC-1 — anything else / interactions (surveyed)
**All three sources attribute exactly ONE function to MC3: the constant-`$FEXX`
vector page. None attributes any other effect** — no impact on video, on the general
memory map outside `$FE00-$FEFF`, on the timer/IRQ system, and no listed interaction
with the COCO bit, MMUEN, IEN/FEN, MC2 (SCS), or MC0/MC1 (ROM map). The INIT0 register
is laid out as **eight independent single-purpose bits**, which is strong evidence the
bits don't cross-couple.
- **The one genuine interaction (part of the function, not a side effect):** MC3=1
  *overrides* both the MMU and the ROM/RAM mode for `$FE00-$FEFF` — Lomont: the vector
  page appears "instead of the **RAM or ROM** at `$FE00-$FEFF`." So MC3=1's constant
  page takes precedence over whatever the MMU / ROM-RAM mode would otherwise place at
  those 256 bytes. That is precisely the protection high placement needs.
- **HS-3 honesty:** the docs are **explicit** on the constant-page role and **silent**
  on any other effect. The "no other function" conclusion rests on (a) three
  independent sources describing only the constant-page role and (b) the per-bit
  independent-function register layout — **not** on any source that positively
  enumerates "MC3 has no other effect." Stated as absence-of-contrary-evidence, not a
  positive doc claim.

## AC-2 — the cost of MC3=1
The cost is exactly **256 bytes**: `$FE00-$FEFF` is committed to the fixed physical
Vector Page instead of being general MMU-mapped RAM in the current window. **For our
layout this cost is already spent / irrelevant:** the framebuffer ends at `$FBFF`
(and the high-placement draw slot `$C000-$FBFF` stops at `$FBFF`), so `$FE00-$FEFF`
sits in the gap **above** the draw slot and **below** the `$FF00-$FFFF` I/O page — we
never use it as free RAM. No other cost is documented (MC3 doesn't slow the CPU, gate
a graphics mode, or disable anything we use). And per the `$FF00` I/O verdict
(`bb64b22`), MC3=1 is *required* for interrupt-safety through MMU swaps — so it's a
benefit we need, not a burden.
- **Design detail (reassuring):** when a framebuffer physical page is mapped into
  window block 7 to draw, the bytes at window offset `$FE00-$FEFF` hit the constant
  vector page (MC3=1 override), **not** the framebuffer — i.e. a block-7-mapped buffer
  has a 256-byte "hole" there. **No collision for us:** the draw slot `$C000-$FBFF`
  never reaches `$FE00`, so the framebuffer never needs those bytes.

## AC-3 — reset default + current prod state (HS-4)
- **Current prod state: MC3=1, already, by design — a NO-OP for banking.**
  - `src/hal.inc:107` — `KCOCO3_INIT0_COCO3 equ $4C  ; $FF90 = COCO=0, MMUEN=1, MC3=1, MC2=1`.
  - `src/hal/coco3-dsk/gfx.s:144` — `sta $FF90` writes `$4C` (initial CoCo3 activation).
  - `src/hal/coco3-dsk/gfx.s:128,133` — `HAL_time_init` later writes `$FF90=$6C`
    (`0110_1100`) to add IEN=1 for the GIME VBL IRQ; **MC3 stays 1** ("All bits this
    function requires are preserved in `$6C`").
  - `src/hal/coco3-dsk/sys.s:15-26` — prod's **interrupt dispatch already depends on
    MC3=1**: "After `$FF90=$4C` is written, MC3=1 locks `$FExx` as constant — they
    cannot be overwritten … BASIC's `$FExx` routing remains in effect (locked by MC3=1
    in `$FF90=$4C`)." The `$FFxx→$FExx→$01xx` three-level chain relies on it.
- **Reset default:** the sources don't state an explicit INIT0 reset value; the GIME
  powers up in **CoCo1/2-compatible mode** (COCO=1) with the CoCo3 vector page off.
  Immaterial here — prod's `HAL_sys_init` establishes MC3=1 immediately and holds it.

## AC-4 — design implication
**Proceed with high placement.** MC3=1 is:
- **cheap** — a single bit, the *standard* CoCo3 operating value (`$4C`);
- **idiomatic** — it's what RSDOS/DECB CoCo3 setups use, and what prod already writes;
- **single-function** — only the constant-vector-page, no other documented effect;
- **near-zero-cost** — commits 256 B (`$FE00-$FEFF`) our layout doesn't use as RAM;
- **already satisfied** — prod runs MC3=1 (`$4C`/`$6C`) and its interrupt dispatch
  already depends on it.

So the high-placement / contiguity design carries **no new MC3 requirement and no MC3
cost we care about**. The low-placement / avoid-block-7 alternative is **not** needed
on MC3 grounds. (One caveat for the design, not a blocker: keep the draw slot ≤ `$FBFF`
so it never overlaps the MC3-protected vector page — which the current `$C000-$FBFF`
slot already does.)

## Read-only confirm (AC-5)
No code change; `build/karateka.bin` unchanged (17978 B); `src/`, `build.bat`
untouched. This confirms an input to the layout design; the design itself is stage-2.
