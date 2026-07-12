* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: dump05_imprison.bin
*         Apple II label: addr_AB7C
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=70  screen-col parity=EVEN
* [ref: karateka-coco3 docs/project/karateka-coco3-design-v0.1.md §6.7]

scene6_cliff_AB7C:
        fcb     8,4  ; height=8 rows, coco3_width=4 bytes/row (4px/byte)
        fcb     $AA,$AF,$C0,$10  ; row 0
        fcb     $AA,$A8,$00,$00  ; row 1
        fcb     $AA,$A8,$00,$00  ; row 2
        fcb     $AA,$A8,$00,$00  ; row 3
        fcb     $AA,$AA,$80,$10  ; row 4
        fcb     $AA,$AA,$80,$10  ; row 5
        fcb     $AA,$AA,$80,$10  ; row 6
        fcb     $AA,$AA,$80,$10  ; row 7
