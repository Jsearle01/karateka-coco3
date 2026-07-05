* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: sprite_data_9b00.s
*         Apple II label: eagle_body_9FC4
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=0
* [ref: karateka-coco3 docs/karateka-coco3-design-v0.1.md §6.7]

eagle_body_9FC4_coco3:
        fcb     9,4  ; height=9 rows, coco3_width=4 bytes/row (4px/byte)
        fcb     $02,$AA,$A0,$00  ; row 0
        fcb     $2A,$AA,$A0,$00  ; row 1
        fcb     $2A,$AA,$AA,$00  ; row 2
        fcb     $2A,$AA,$AA,$00  ; row 3
        fcb     $2A,$AA,$AA,$00  ; row 4
        fcb     $2A,$AA,$AA,$00  ; row 5
        fcb     $02,$AA,$AA,$A0  ; row 6
        fcb     $02,$AA,$AA,$A0  ; row 7
        fcb     $00,$2A,$AA,$A0  ; row 8
