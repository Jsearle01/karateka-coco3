* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: dump05 by addr (scene-5 floor, tbl_sprite_*_a)
*         Apple II label: floor_9600
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=0
* [ref: karateka-coco3 docs/project/karateka-coco3-design-v0.1.md §6.7]

floor_9600_coco3:
        fcb     12,11  ; height=12 rows, coco3_width=11 bytes/row (4px/byte)
        fcb     $00,$00,$00,$00,$00,$00,$00,$00,$00,$FE,$80  ; row 0
        fcb     $00,$00,$00,$00,$00,$00,$00,$00,$3F,$FE,$80  ; row 1
        fcb     $00,$00,$00,$00,$00,$00,$00,$3F,$FF,$FE,$80  ; row 2
        fcb     $00,$00,$00,$00,$00,$00,$3F,$FF,$FF,$FE,$80  ; row 3
        fcb     $00,$00,$00,$00,$00,$3F,$FF,$FF,$FE,$AA,$80  ; row 4
        fcb     $00,$00,$00,$00,$3F,$FF,$FF,$FE,$AA,$80,$00  ; row 5
        fcb     $00,$00,$00,$0F,$FF,$FF,$EA,$AA,$80,$00,$00  ; row 6
        fcb     $00,$00,$0F,$FF,$FF,$EA,$AA,$FE,$80,$00,$00  ; row 7
        fcb     $00,$03,$FF,$FF,$EA,$A8,$00,$FE,$80,$00,$00  ; row 8
        fcb     $00,$FF,$FF,$EA,$A8,$00,$00,$FE,$80,$00,$00  ; row 9
        fcb     $00,$FF,$EA,$A8,$00,$00,$00,$FE,$80,$00,$00  ; row 10
        fcb     $00,$AA,$AF,$E8,$00,$00,$00,$FE,$80,$00,$00  ; row 11
