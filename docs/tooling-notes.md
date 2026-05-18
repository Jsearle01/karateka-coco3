# Tooling Notes

Project-specific notes about tools used in karateka-coco3. For general toolchain patterns see ~/6502-6809-conversion-patterns/shared/T-toolchain/.

---

## sprite_convert.py: Label Stacking Behavior

**Discovered:** P2.4.4 (2026-05-17)
**Severity:** Workflow — affects correct extraction of named-letter sprites

### Problem

`sprite_convert.py` assumes a single label per data block. It extracts a sprite by finding the label, reading the sprite header (height, width bytes), and collecting the subsequent bitmap data until it reaches either the expected byte count or another label.

In `karateka_dissasembly_claude/src/`, some sprites have stacked labels: a human-readable named label immediately followed (at the same address, no data between them) by the address-based label. For example:

```asm
sprite_letter_p:
sprite_0534:
    .byte  $0A, $02    ; header: 10 rows, 2 bytes wide
    .byte  ...         ; bitmap data
```

When `sprite_convert.py` is given `sprite_letter_p` as the target label, it reads the header bytes, then immediately encounters `sprite_0534:`. The tool interprets this second label as the start of the next sprite block and stops collection. Result: only the 2-byte header is extracted; the bitmap data is missing.

### Effect

Extracted sprite file contains the header bytes only. Any render or analysis step downstream receives a degenerate sprite (height=10, width=2, data=empty). The tool does not error; it silently returns a truncated result.

### Workaround

Always use the address-based label (e.g., `sprite_0534`) rather than the named-letter label (e.g., `sprite_letter_p`) when invoking `sprite_convert.py`.

The address-based label is placed before the data without a stacked alias immediately following it. The tool's collection logic runs correctly from the address-based label because the next label it encounters is the genuine next sprite block.

```sh
# WRONG — produces truncated output:
python tools/sprite_convert.py sprite_letter_p

# CORRECT — produces full sprite:
python tools/sprite_convert.py sprite_0534
```

### Label Map Reference

The correspondence between named-letter labels and address-based labels for the "presents" glyph set is in `docs/conventions.md §18 label map table`. Consult that table when you have a named label and need the address label for tool invocation.

### Long-term fix

`sprite_convert.py` should be updated to skip a stacked label (a label at the same address as the current position, with no intervening data) rather than treating it as a block boundary. Until that fix is implemented, the address-based label workaround is required.

---

## lwasm: Whitespace Terminates Operand Expressions

See `~/6502-6809-conversion-patterns/shared/T-toolchain/lwasm-whitespace-terminates-operand-expression.md` for full details.

Short rule: never put spaces around operators in equ expressions or instruction operands.

```asm
; WRONG: space after LABEL terminates expression at LABEL
ADDR equ BASE + N*STRIDE

; CORRECT
ADDR equ BASE+N*STRIDE
```

Discovered P2.3a.8. Replaces the "N*SYMBOL bug" framing from P2.3a.7.
