* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: dump05 by addr (scene-5 floor, tbl_sprite_*_a)
*         Apple II label: addr_971D
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=0
* [ref: karateka-coco3 docs/karateka-coco3-design-v0.1.md §6.7]

floor_971D_coco3:
        fcb     9,7  ; height=9 rows, coco3_width=7 bytes/row (4px/byte)
        fcb     $AA,$AA,$A8,$00,$00,$00,$00  ; row 0
        fcb     $00,$00,$00,$00,$00,$00,$00  ; row 1
        fcb     $AA,$AA,$AA,$A8,$00,$00,$00  ; row 2
        fcb     $00,$00,$00,$00,$00,$00,$00  ; row 3
        fcb     $AA,$AA,$AA,$AA,$A8,$00,$00  ; row 4
        fcb     $00,$00,$00,$00,$00,$00,$00  ; row 5
        fcb     $AA,$AA,$AA,$AA,$AA,$A8,$00  ; row 6
        fcb     $00,$00,$00,$00,$00,$00,$00  ; row 7
        fcb     $AA,$AA,$AA,$AA,$AA,$AA,$A8  ; row 8
