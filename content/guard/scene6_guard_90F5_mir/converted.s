* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: dump05_imprison.bin
*         Apple II label: addr_90F5
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=0  screen-col parity=EVEN
* [ref: karateka-coco3 docs/project/karateka-coco3-design-v0.1.md §6.7]

scene6_guard_90F5_mir:
        fcb     4,4  ; height=4 rows, coco3_width=4 bytes/row (4px/byte)
        fcb     $F0,$08,$3F,$F0  ; row 0
        fcb     $80,$A8,$3F,$F0  ; row 1
        fcb     $0A,$A8,$3F,$F0  ; row 2
        fcb     $00,$00,$3F,$F0  ; row 3
