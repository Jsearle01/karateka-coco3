* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: sprite_data_0400.s
*         Apple II label: sprite_064c
* Color model: adjacency + screen-col parity (MAME-verified, TASK 1/2 gate 2026-05-16).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=119
* [ref: karateka-coco3 docs/karateka-coco3-design-v0.1.md §6.7]

glyph_comma_coco3:
        fcb     12,1  ; height=12 rows, coco3_width=1 bytes/row (4px/byte)
        fcb     $00  ; row 0
        fcb     $00  ; row 1
        fcb     $00  ; row 2
        fcb     $00  ; row 3
        fcb     $00  ; row 4
        fcb     $00  ; row 5
        fcb     $00  ; row 6
        fcb     $00  ; row 7
        fcb     $BC  ; row 8
        fcb     $BC  ; row 9
        fcb     $04  ; row 10
        fcb     $20  ; row 11
