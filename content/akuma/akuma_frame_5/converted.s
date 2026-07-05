* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: sprite_data.s
*         Apple II label: sprite_98d3
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=120
* [ref: karateka-coco3 docs/karateka-coco3-design-v0.1.md §6.7]

akuma_frame_5_coco3:
        fcb     17,4  ; height=17 rows, coco3_width=4 bytes/row (4px/byte)
        fcb     $00,$00,$00,$00  ; row 0
        fcb     $00,$40,$00,$00  ; row 1
        fcb     $55,$40,$FC,$00  ; row 2
        fcb     $55,$43,$FF,$00  ; row 3
        fcb     $55,$5F,$FF,$F0  ; row 4
        fcb     $54,$3F,$FF,$F0  ; row 5
        fcb     $54,$3F,$FF,$FC  ; row 6
        fcb     $40,$03,$FF,$FC  ; row 7
        fcb     $40,$03,$FF,$FF  ; row 8
        fcb     $00,$00,$FF,$FF  ; row 9
        fcb     $00,$00,$FF,$FF  ; row 10
        fcb     $00,$03,$FF,$FF  ; row 11
        fcb     $00,$03,$FF,$FF  ; row 12
        fcb     $2A,$0F,$FF,$FC  ; row 13
        fcb     $02,$0F,$FF,$F0  ; row 14
        fcb     $42,$AB,$FF,$C0  ; row 15
        fcb     $42,$A0,$3F,$00  ; row 16
