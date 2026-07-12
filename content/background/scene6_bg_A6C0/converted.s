* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: dump05_imprison.bin
*         Apple II label: addr_A6C0
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=223  screen-col parity=ODD
* [ref: karateka-coco3 docs/project/karateka-coco3-design-v0.1.md §6.7]

scene6_bg_A6C0:
        fcb     6,4  ; height=6 rows, coco3_width=4 bytes/row (4px/byte)
        fcb     $2A,$00,$00,$00  ; row 0
        fcb     $55,$54,$00,$00  ; row 1
        fcb     $2A,$AA,$00,$00  ; row 2
        fcb     $55,$55,$54,$00  ; row 3
        fcb     $2A,$AA,$AA,$00  ; row 4
        fcb     $55,$55,$55,$54  ; row 5
