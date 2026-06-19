# Scene-5 1b GATE 2 — recon findings (authoritative, trace-confirmed)

Oracle: apple2e + `dumps/karateka.dsk` (boots straight into the imprisonment
cutscene). Disassembly: `src/display_7700.s`. Trace: `tools/trace_cell_arc.lua`
→ `cell_arc.log` (polls `$3B`/`$39`/`$84`/`$3A` per frame with dwell).

## GATE D2 (HS-0) — what the princess turn (`$39:=8`) keys off — PINNED

Source (`display_7700.s`, the cell loop `L7B6D`):
```
623  lda $3B / cmp #$0D / bcc L7B6D     ; loop (keep walking in) while clock < $0D
626  lda $39 / cmp #$01 / bne L7B6D     ; ...or while pose != $01 (walk not complete)
629  dec $3B                            ; trigger met -> $3B $0D->$0C
632  ldx #$13 / stx $39                 ; $39 = $13 (bow/setup)
635  lda #$05 / sta $84                 ; DOOR appears ($84=5)
639  ldx #$08 / stx $39                 ; $39 = $08 (TURN)
644  L7BAE: ... inc $39 ... cpx #$13    ; collapse loop $39 $08->$12
```

**Answer:** the turn keys off **`$3B >= $0D` AND `$39 == $01` (walk-complete)** —
NOT the door. The door (`$84=5`) is a **sibling** set 4 instructions before
`$39:=8` in the *same atomic block*; door + turn fire on the same frame. So the
visual is exactly "door appears, she turns to it," but the mechanism is a
**co-trigger**, not causal door→turn. Port wiring: fire both together when the
cell clock hits the trigger AND her walk-in completes.

Trace (`cell_arc.log`) confirms:
```
f5222  $3B=0D $39=01   <- trigger condition met (walk-complete @ clock $0D)
f5226  $3B=0C $39=13   <- dec $3B, $39=$13 (dwell 4)
f5235  $3B=0C $39=08 $84=05   <- TURN + DOOR, same frame
```

## HS-1 — oracle collapse holds — CONFIRMED (swap the controller's demo values)

From `cell_arc.log` dwell (apple2e frame = 1 VBL):

| pose | `$39` | dwell (VBL) | controller const | demo→oracle |
|------|------|-------------|------------------|-------------|
| turn-start (1530) | `$08` | **173** | PR_TURN0_HOLD | 40 → **173** |
| facing-left (169A) | `$0C` | **173** | PR_TF_DELAY | 75 → **173** |
| bow/setup (1867) | `$13` | ~9 (4 in oracle comment) | PR_BOW_HOLD | 30 → **9** |
| other turn/fall poses | — | ~11 | PR_POSE_CAD | 11 (already oracle) |

The two 173-VBL holds (the long "looks") are the load-bearing timing. Controller
constants are now `ifndef`-guarded so the Gate-2 driver overrides to oracle while
the sandbox keeps demo holds for watchability.

## Transition + cadence

- **Transition throne→cell at `$3B`=`$22`→`$04`** (f4895→f4905); `$39=$01`
  CONTINUOUS across the switch (P3 — her walk pose does not reset).
- Throne walk cadence **13 VBL/leg** (matches PR_CAD); cell walk-in ~10 VBL/leg
  (the port keeps PR_CAD=13 — minor; gate is the holds + the beats).
- Cell walk-in counts `$3B` `$04`→`$0D`.

## Port wiring (Gate 2)

- Throne walk drives the clock `$15`→`$22` (Gate 1 model) → at `$22`:
  TRANSITION (cell backdrop to both buffers + re-snapshot the clean buffer,
  princess walk-cycle preserved). Per Jay: she does NOT keep her throne X — the
  scene CUTS and she **re-enters at the cell doorway** (`CELL_ENTRY_PX`) walking in.
- Cell walk drives `$04`→`$0D` → at `$0D` + walk-complete: door appears + turn
  fires (co-trigger) → bow → turn(173) → facing-left(173) → collapse → halt.
