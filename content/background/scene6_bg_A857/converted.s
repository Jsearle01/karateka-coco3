* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: dump05_imprison.bin
*         Apple II label: addr_A857
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=237  screen-col parity=ODD
* [ref: karateka-coco3 docs/project/karateka-coco3-design-v0.1.md §6.7]

scene6_bg_A857:
        fcb     6,2  ; height=6 rows, coco3_width=2 bytes/row (4px/byte)
        fcb     $2A,$BC  ; row 0
        fcb     $2B,$FC  ; row 1
        fcb     $2B,$FC  ; row 2
        fcb     $BF,$FC  ; row 3
        fcb     $FF,$FC  ; row 4
        fcb     $FF,$FC  ; row 5
