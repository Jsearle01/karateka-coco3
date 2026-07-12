* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: dump05_imprison.bin
*         Apple II label: addr_AB94
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=70  screen-col parity=EVEN
* [ref: karateka-coco3 docs/project/karateka-coco3-design-v0.1.md §6.7]

scene6_cliff_AB94:
        fcb     4,3  ; height=4 rows, coco3_width=3 bytes/row (4px/byte)
        fcb     $FF,$FF,$C0  ; row 0
        fcb     $FF,$FF,$C0  ; row 1
        fcb     $FF,$FF,$C0  ; row 2
        fcb     $FF,$FF,$C0  ; row 3
