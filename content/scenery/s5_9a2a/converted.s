* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: sprite_data.s
*         Apple II label: sprite_9a2a
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=120
* [ref: karateka-coco3 docs/karateka-coco3-design-v0.1.md §6.7]

s5_9a2a_coco3:
        fcb     18,6  ; height=18 rows, coco3_width=6 bytes/row (4px/byte)
        fcb     $FF,$FF,$00,$3F,$FF,$C0  ; row 0
        fcb     $FF,$FF,$00,$3F,$FF,$C0  ; row 1
        fcb     $FF,$FF,$00,$3F,$FF,$C0  ; row 2
        fcb     $FF,$F0,$00,$03,$FF,$C0  ; row 3
        fcb     $FF,$F0,$00,$03,$FF,$C0  ; row 4
        fcb     $FF,$F0,$00,$03,$FF,$C0  ; row 5
        fcb     $FF,$F0,$00,$03,$FF,$C0  ; row 6
        fcb     $FF,$F0,$00,$03,$FF,$C0  ; row 7
        fcb     $FF,$FF,$FF,$FF,$FF,$C0  ; row 8
        fcb     $FF,$FF,$FF,$FF,$FF,$C0  ; row 9
        fcb     $FF,$FF,$FF,$FF,$FF,$C0  ; row 10
        fcb     $FF,$FF,$FF,$FF,$FF,$C0  ; row 11
        fcb     $FF,$C3,$FF,$F0,$FF,$C0  ; row 12
        fcb     $FF,$C0,$00,$00,$FF,$C0  ; row 13
        fcb     $FF,$F0,$00,$00,$FF,$C0  ; row 14
        fcb     $FF,$F0,$00,$00,$3F,$C0  ; row 15
        fcb     $FF,$F0,$00,$00,$3F,$C0  ; row 16
        fcb     $FF,$F0,$00,$00,$0F,$C0  ; row 17
