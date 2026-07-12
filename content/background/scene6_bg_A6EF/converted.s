* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: dump05_imprison.bin
*         Apple II label: addr_A6EF
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=258  screen-col parity=EVEN
* [ref: karateka-coco3 docs/project/karateka-coco3-design-v0.1.md §6.7]

scene6_bg_A6EF:
        fcb     18,2  ; height=18 rows, coco3_width=2 bytes/row (4px/byte)
        fcb     $0A,$A8  ; row 0
        fcb     $01,$50  ; row 1
        fcb     $0A,$A8  ; row 2
        fcb     $01,$50  ; row 3
        fcb     $0A,$A8  ; row 4
        fcb     $01,$50  ; row 5
        fcb     $0A,$A8  ; row 6
        fcb     $01,$50  ; row 7
        fcb     $0A,$A8  ; row 8
        fcb     $01,$50  ; row 9
        fcb     $0A,$A8  ; row 10
        fcb     $01,$50  ; row 11
        fcb     $0A,$A8  ; row 12
        fcb     $01,$50  ; row 13
        fcb     $0A,$A8  ; row 14
        fcb     $01,$50  ; row 15
        fcb     $0A,$A8  ; row 16
        fcb     $01,$50  ; row 17
