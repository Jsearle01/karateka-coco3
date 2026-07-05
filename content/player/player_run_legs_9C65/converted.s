* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: sprite_data_9b00.s
*         Apple II label: player_run_legs_9C65
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=0
* [ref: karateka-coco3 docs/karateka-coco3-design-v0.1.md §6.7]

player_run_legs_9C65_coco3:
        fcb     24,5  ; height=24 rows, coco3_width=5 bytes/row (4px/byte)
        fcb     $00,$03,$FF,$CA,$80  ; row 0
        fcb     $00,$0F,$FF,$CA,$80  ; row 1
        fcb     $00,$0F,$FF,$FC,$80  ; row 2
        fcb     $00,$0F,$FF,$FF,$00  ; row 3
        fcb     $00,$0F,$FF,$FF,$00  ; row 4
        fcb     $00,$03,$FF,$FF,$C0  ; row 5
        fcb     $00,$03,$FF,$FF,$C0  ; row 6
        fcb     $00,$03,$FF,$FF,$F0  ; row 7
        fcb     $00,$03,$FF,$FF,$FC  ; row 8
        fcb     $00,$03,$FF,$FF,$FC  ; row 9
        fcb     $00,$03,$FF,$FF,$FF  ; row 10
        fcb     $00,$0F,$FF,$FF,$FF  ; row 11
        fcb     $00,$0F,$FF,$FF,$FC  ; row 12
        fcb     $00,$3F,$FF,$FF,$F0  ; row 13
        fcb     $00,$FF,$FF,$FF,$00  ; row 14
        fcb     $00,$FE,$FF,$FC,$00  ; row 15
        fcb     $03,$CA,$FF,$C0,$00  ; row 16
        fcb     $0F,$CA,$AF,$00,$00  ; row 17
        fcb     $7F,$FC,$80,$00,$00  ; row 18
        fcb     $7F,$FF,$08,$00,$00  ; row 19
        fcb     $0F,$FC,$00,$00,$00  ; row 20
        fcb     $AA,$F0,$00,$00,$00  ; row 21
        fcb     $A8,$00,$00,$00,$00  ; row 22
        fcb     $0A,$80,$00,$00,$00  ; row 23
