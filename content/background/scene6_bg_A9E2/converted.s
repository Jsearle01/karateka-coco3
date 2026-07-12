* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: dump05_imprison.bin (sky floodfill)
*         Apple II label: addr_A9E2
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=0  screen-col parity=EVEN
* [ref: karateka-coco3 docs/project/karateka-coco3-design-v0.1.md §6.7]

scene6_bg_A9E2:
        fcb     3,27  ; height=3 rows, coco3_width=27 bytes/row (4px/byte)
        fcb     $AA,$AA,$80,$0A,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AF,$FF,$FC,$0A,$AA,$AA  ; row 0
        fcb     $AA,$80,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$FF,$F0,$AA,$AA  ; row 1
        fcb     $80,$0A,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$FF,$F0,$AA  ; row 2
