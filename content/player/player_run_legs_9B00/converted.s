* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: sprite_data_9b00.s
*         Apple II label: player_run_legs_9B00
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=0
* [ref: karateka-coco3 docs/karateka-coco3-design-v0.1.md §6.7]

player_run_legs_9B00_coco3:
        fcb     21,8  ; height=21 rows, coco3_width=8 bytes/row (4px/byte)
        fcb     $00,$00,$00,$FF,$FF,$FF,$00,$00  ; row 0
        fcb     $00,$00,$00,$3F,$FF,$FF,$C0,$00  ; row 1
        fcb     $00,$00,$00,$3F,$FF,$FF,$F0,$00  ; row 2
        fcb     $00,$00,$00,$FF,$FF,$FF,$FC,$00  ; row 3
        fcb     $00,$00,$00,$FF,$FF,$FF,$FF,$00  ; row 4
        fcb     $00,$00,$00,$FF,$FF,$FF,$FF,$00  ; row 5
        fcb     $00,$00,$03,$FF,$FF,$7F,$FF,$C0  ; row 6
        fcb     $00,$00,$03,$FF,$FC,$03,$FF,$C0  ; row 7
        fcb     $00,$00,$0F,$FF,$F0,$00,$FF,$C0  ; row 8
        fcb     $00,$00,$3F,$FF,$C0,$00,$FF,$C0  ; row 9
        fcb     $00,$03,$FF,$FF,$00,$00,$FF,$C0  ; row 10
        fcb     $00,$0F,$FF,$FC,$00,$00,$FF,$C0  ; row 11
        fcb     $00,$FF,$FF,$C0,$00,$00,$FF,$C0  ; row 12
        fcb     $03,$FF,$FF,$00,$00,$00,$FF,$C0  ; row 13
        fcb     $0F,$FF,$F0,$00,$00,$00,$FF,$C0  ; row 14
        fcb     $0F,$FF,$00,$00,$00,$00,$80,$00  ; row 15
        fcb     $AA,$F0,$00,$00,$00,$00,$80,$00  ; row 16
        fcb     $A8,$00,$00,$00,$00,$00,$A8,$00  ; row 17
        fcb     $A8,$00,$00,$00,$00,$00,$A8,$00  ; row 18
        fcb     $08,$00,$00,$00,$00,$00,$0A,$80  ; row 19
        fcb     $0A,$80,$00,$00,$00,$00,$00,$00  ; row 20
