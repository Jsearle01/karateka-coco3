* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: sprite_data_9b00.s
*         Apple II label: eagle_head_9FD8
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=0
* [ref: karateka-coco3 docs/karateka-coco3-design-v0.1.md §6.7]

eagle_head_9FD8_coco3:
        fcb     6,4  ; height=6 rows, coco3_width=4 bytes/row (4px/byte)
        fcb     $00,$FF,$00,$00  ; row 0
        fcb     $00,$3F,$C0,$00  ; row 1
        fcb     $0F,$FF,$F0,$00  ; row 2
        fcb     $08,$3F,$FC,$00  ; row 3
        fcb     $00,$3F,$C8,$00  ; row 4
        fcb     $00,$3C,$AA,$80  ; row 5
