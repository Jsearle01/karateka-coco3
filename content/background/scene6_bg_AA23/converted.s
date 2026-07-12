* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: dump05_imprison.bin
*         Apple II label: addr_AA23
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=5  screen-col parity=ODD
* [ref: karateka-coco3 docs/project/karateka-coco3-design-v0.1.md §6.7]

scene6_bg_AA23:
        fcb     12,1  ; height=12 rows, coco3_width=1 bytes/row (4px/byte)
        fcb     $F0  ; row 0
        fcb     $F0  ; row 1
        fcb     $F0  ; row 2
        fcb     $F0  ; row 3
        fcb     $FC  ; row 4
        fcb     $00  ; row 5
        fcb     $00  ; row 6
        fcb     $00  ; row 7
        fcb     $F0  ; row 8
        fcb     $F0  ; row 9
        fcb     $F0  ; row 10
        fcb     $FC  ; row 11
