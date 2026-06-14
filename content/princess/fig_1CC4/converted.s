* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: dump05_imprison.bin (by address)
*         Apple II label: addr_1CC4
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=0
* [ref: karateka-coco3 docs/karateka-coco3-design-v0.1.md §6.7]

fig_1CC4_coco3:
        fcb     2,13  ; height=2 rows, coco3_width=13 bytes/row (4px/byte)
        fcb     $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ; row 0
        fcb     $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ; row 1
