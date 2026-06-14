* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: sprite_data_0400.s
*         Apple II label: sprite_04e6
* Color model: adjacency + screen-col parity (MAME-verified, TASK 1/2 gate 2026-05-16).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=119
* [ref: karateka-coco3 docs/karateka-coco3-design-v0.1.md §6.7]

glyph_l_coco3:
        fcb     10,2  ; height=10 rows, coco3_width=2 bytes/row (4px/byte)
        fcb     $BF,$00  ; row 0
        fcb     $0F,$00  ; row 1
        fcb     $0F,$00  ; row 2
        fcb     $0F,$00  ; row 3
        fcb     $0F,$00  ; row 4
        fcb     $0F,$00  ; row 5
        fcb     $0F,$00  ; row 6
        fcb     $0F,$00  ; row 7
        fcb     $0F,$00  ; row 8
        fcb     $0F,$FC  ; row 9
