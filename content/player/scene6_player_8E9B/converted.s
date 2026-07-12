* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: dump05_imprison.bin
*         Apple II label: addr_8E9B
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=0  screen-col parity=EVEN
* [ref: karateka-coco3 docs/project/karateka-coco3-design-v0.1.md §6.7]

scene6_player_8E9B:
        fcb     8,2  ; height=8 rows, coco3_width=2 bytes/row (4px/byte)
        fcb     $7F,$FC  ; row 0
        fcb     $FF,$F0  ; row 1
        fcb     $FF,$50  ; row 2
        fcb     $F5,$00  ; row 3
        fcb     $F5,$50  ; row 4
        fcb     $F5,$50  ; row 5
        fcb     $15,$50  ; row 6
        fcb     $15,$00  ; row 7
