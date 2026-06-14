* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: sprite_data_0400.s
*         Apple II label: sprite_0626
* Color model: adjacency + screen-col parity (MAME-verified, TASK 1/2 gate 2026-05-16).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=119
* [ref: karateka-coco3 docs/karateka-coco3-design-v0.1.md §6.7]

glyph_i_coco3:
        fcb     10,1  ; height=10 rows, coco3_width=1 bytes/row (4px/byte)
        fcb     $00  ; row 0
        fcb     $00  ; row 1
        fcb     $BF  ; row 2
        fcb     $0F  ; row 3
        fcb     $0F  ; row 4
        fcb     $0F  ; row 5
        fcb     $0F  ; row 6
        fcb     $0F  ; row 7
        fcb     $0F  ; row 8
        fcb     $0F  ; row 9
