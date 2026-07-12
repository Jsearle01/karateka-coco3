* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: dump05_imprison.bin
*         Apple II label: addr_A865
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=209  screen-col parity=ODD
* [ref: karateka-coco3 docs/project/karateka-coco3-design-v0.1.md §6.7]

scene6_bg_A865:
        fcb     8,4  ; height=8 rows, coco3_width=4 bytes/row (4px/byte)
        fcb     $BF,$D5,$54,$20  ; row 0
        fcb     $BF,$C0,$00,$00  ; row 1
        fcb     $BF,$D5,$54,$00  ; row 2
        fcb     $BF,$C0,$00,$00  ; row 3
        fcb     $BF,$D5,$54,$20  ; row 4
        fcb     $BF,$C0,$00,$20  ; row 5
        fcb     $BF,$D5,$54,$20  ; row 6
        fcb     $BF,$C0,$00,$20  ; row 7
