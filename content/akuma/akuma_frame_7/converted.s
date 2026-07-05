* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: sprite_data.s
*         Apple II label: sprite_9956
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=120
* [ref: karateka-coco3 docs/karateka-coco3-design-v0.1.md §6.7]

akuma_frame_7_coco3:
        fcb     8,9  ; height=8 rows, coco3_width=9 bytes/row (4px/byte)
        fcb     $00,$00,$03,$FF,$FF,$FF,$00,$00,$00  ; row 0
        fcb     $00,$40,$3F,$FF,$FF,$FF,$F2,$AA,$A0  ; row 1
        fcb     $55,$40,$FF,$FF,$FF,$FF,$F2,$A0,$00  ; row 2
        fcb     $55,$43,$FF,$FF,$FF,$FF,$F2,$A0,$00  ; row 3
        fcb     $55,$40,$FF,$FF,$FF,$FF,$00,$00,$00  ; row 4
        fcb     $54,$00,$00,$FF,$FF,$FF,$00,$00,$00  ; row 5
        fcb     $54,$00,$00,$0F,$FF,$F0,$00,$00,$00  ; row 6
        fcb     $40,$00,$00,$00,$0F,$C0,$00,$00,$00  ; row 7
