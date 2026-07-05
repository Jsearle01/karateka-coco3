* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: sprite_data.s
*         Apple II label: sprite_9908
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=120
* [ref: karateka-coco3 docs/karateka-coco3-design-v0.1.md §6.7]

akuma_frame_6_coco3:
        fcb     19,6  ; height=19 rows, coco3_width=6 bytes/row (4px/byte)
        fcb     $00,$00,$00,$00,$00,$00  ; row 0
        fcb     $00,$40,$00,$00,$00,$00  ; row 1
        fcb     $55,$43,$F0,$00,$00,$00  ; row 2
        fcb     $55,$5F,$FC,$00,$00,$00  ; row 3
        fcb     $55,$5F,$FF,$00,$00,$00  ; row 4
        fcb     $54,$3F,$FF,$C0,$00,$00  ; row 5
        fcb     $54,$3F,$FF,$F0,$00,$00  ; row 6
        fcb     $40,$0F,$FF,$FC,$00,$00  ; row 7
        fcb     $40,$03,$FF,$FF,$C0,$00  ; row 8
        fcb     $00,$00,$FF,$FF,$F0,$00  ; row 9
        fcb     $00,$00,$3F,$FF,$FC,$00  ; row 10
        fcb     $00,$00,$3F,$FF,$FF,$00  ; row 11
        fcb     $00,$00,$0F,$FF,$FF,$00  ; row 12
        fcb     $00,$00,$03,$FF,$FF,$00  ; row 13
        fcb     $00,$00,$03,$FF,$FF,$F0  ; row 14
        fcb     $40,$00,$00,$FF,$FF,$F2  ; row 15
        fcb     $40,$00,$00,$3F,$C2,$AA  ; row 16
        fcb     $40,$00,$00,$00,$00,$02  ; row 17
        fcb     $40,$00,$00,$00,$00,$02  ; row 18
