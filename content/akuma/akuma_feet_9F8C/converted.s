* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: sprite_data_9b00.s
*         Apple II label: akuma_feet_9F8C
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=0
* [ref: karateka-coco3 docs/karateka-coco3-design-v0.1.md §6.7]

akuma_feet_9F8C_coco3:
        fcb     9,11  ; height=9 rows, coco3_width=11 bytes/row (4px/byte)
        fcb     $2A,$00,$00,$00,$00,$00,$00,$00,$00,$2A,$A0  ; row 0
        fcb     $00,$04,$00,$00,$00,$00,$00,$00,$00,$40,$00  ; row 1
        fcb     $2A,$A0,$40,$00,$00,$00,$00,$00,$04,$2A,$A0  ; row 2
        fcb     $00,$20,$05,$54,$00,$00,$00,$55,$42,$00,$00  ; row 3
        fcb     $20,$2A,$00,$00,$55,$55,$54,$00,$2A,$02,$A0  ; row 4
        fcb     $02,$A0,$00,$00,$00,$00,$00,$00,$02,$A0,$00  ; row 5
        fcb     $02,$A0,$00,$00,$00,$00,$00,$00,$02,$A0,$00  ; row 6
        fcb     $02,$A0,$00,$00,$00,$00,$00,$00,$02,$A0,$00  ; row 7
        fcb     $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ; row 8
