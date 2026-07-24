* converted.s
* CoCo3 sprite data — SYNTHETIC filler (NOT from the oracle).
* Fills the 5px x 6-row gap between A6C0 (ends px258) and A684 (starts px264) at the arch
*   front-leg base. Jay-specified (2026-07-23): the oracle leaves this region as background
*   (verified: no sprite draws there in the $A0xx-$AFxx trace at $52=1B), but Jay wants it opaque
*   black to complete the base. All pixels index-0 (black); the opacity.s stencil marks px0-4 opaque
*   (5px) so, placed at col 64 sub 3 (px259), it covers screen px259-263 exactly — no overhang into
*   A6C0's colour edge (px<=258) or A684's white leg (px>=264).
*   start_col=256  screen-col parity=EVEN
scene6_bg_archfill1:
        fcb     6,2  ; height=6 rows, coco3_width=2 bytes/row (4px/byte)
        fcb     $00,$00  ; row 0
        fcb     $00,$00  ; row 1
        fcb     $00,$00  ; row 2
        fcb     $00,$00  ; row 3
        fcb     $00,$00  ; row 4
        fcb     $00,$00  ; row 5
