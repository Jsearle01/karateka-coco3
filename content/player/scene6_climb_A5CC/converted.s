* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: dump05_imprison.bin
*         Apple II label: addr_A5CC
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=0  screen-col parity=EVEN
* [ref: karateka-coco3 docs/project/karateka-coco3-design-v0.1.md §6.7]

scene6_climb_A5CC:
        fcb     7,3  ; height=7 rows, coco3_width=3 bytes/row (4px/byte)
        fcb     $00,$3F,$FC  ; row 0
        fcb     $00,$FF,$F0  ; row 1
        fcb     $00,$FF,$50  ; row 2
        fcb     $00,$F5,$00  ; row 3
        fcb     $00,$F5,$50  ; row 4
        fcb     $00,$F5,$50  ; row 5
        fcb     $03,$F5,$50  ; row 6
