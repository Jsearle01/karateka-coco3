* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: sprite_data_logo.s
*         Apple II label: sprite_bd5d
* Color model: adjacency + screen-col parity (MAME-verified, TASK 1/2 gate 2026-05-16).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=0
* [ref: karateka-coco3 docs/karateka-coco3-design-v0.1.md §6.7]

title_k_flourish_coco3:
        fcb     11,3  ; height=11 rows, coco3_width=3 bytes/row (4px/byte)
        fcb     $00,$01,$00  ; row 0
        fcb     $00,$11,$10  ; row 1
        fcb     $01,$11,$11  ; row 2
        fcb     $11,$11,$11  ; row 3
        fcb     $01,$11,$11  ; row 4
        fcb     $00,$11,$11  ; row 5
        fcb     $00,$11,$11  ; row 6
        fcb     $00,$11,$11  ; row 7
        fcb     $00,$11,$11  ; row 8
        fcb     $00,$11,$11  ; row 9
        fcb     $00,$11,$11  ; row 10
