* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: dump05_imprison.bin
*         Apple II label: addr_0B12
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=0  screen-col parity=EVEN
* [ref: karateka-coco3 docs/project/karateka-coco3-design-v0.1.md §6.7]

arrow_0B12:
        fcb     7,2  ; height=7 rows, coco3_width=2 bytes/row (4px/byte)
        fcb     $40,$00  ; row 0
        fcb     $54,$00  ; row 1
        fcb     $55,$40  ; row 2
        fcb     $55,$54  ; row 3
        fcb     $55,$40  ; row 4
        fcb     $54,$00  ; row 5
        fcb     $40,$00  ; row 6
