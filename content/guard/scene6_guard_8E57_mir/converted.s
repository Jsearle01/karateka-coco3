* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: dump05_imprison.bin
*         Apple II label: addr_8E57
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=0  screen-col parity=EVEN
* [ref: karateka-coco3 docs/project/karateka-coco3-design-v0.1.md §6.7]

scene6_guard_8E57_mir:
        fcb     11,2  ; height=11 rows, coco3_width=2 bytes/row (4px/byte)
        fcb     $F0,$00  ; row 0
        fcb     $F0,$00  ; row 1
        fcb     $FF,$FC  ; row 2
        fcb     $FF,$FF  ; row 3
        fcb     $FF,$FF  ; row 4
        fcb     $FF,$FF  ; row 5
        fcb     $FF,$FC  ; row 6
        fcb     $FF,$F0  ; row 7
        fcb     $FF,$F0  ; row 8
        fcb     $FF,$00  ; row 9
        fcb     $F0,$00  ; row 10
