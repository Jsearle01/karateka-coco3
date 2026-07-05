* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: sprite_data_9b00.s
*         Apple II label: player_run_torso_9DD5
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=0
* [ref: karateka-coco3 docs/karateka-coco3-design-v0.1.md §6.7]

player_run_torso_9DD5_coco3:
        fcb     23,4  ; height=23 rows, coco3_width=4 bytes/row (4px/byte)
        fcb     $00,$0F,$FC,$00  ; row 0
        fcb     $00,$3F,$FF,$00  ; row 1
        fcb     $00,$FF,$FF,$00  ; row 2
        fcb     $00,$FF,$FF,$C0  ; row 3
        fcb     $00,$FF,$FF,$C0  ; row 4
        fcb     $03,$FF,$FF,$C0  ; row 5
        fcb     $03,$FF,$FF,$C0  ; row 6
        fcb     $03,$FF,$FF,$10  ; row 7
        fcb     $03,$FF,$FF,$10  ; row 8
        fcb     $03,$FF,$FF,$00  ; row 9
        fcb     $00,$FF,$FF,$00  ; row 10
        fcb     $00,$FF,$FF,$10  ; row 11
        fcb     $03,$FF,$FF,$10  ; row 12
        fcb     $03,$FF,$FF,$00  ; row 13
        fcb     $0F,$FF,$F0,$00  ; row 14
        fcb     $0F,$FF,$F0,$00  ; row 15
        fcb     $0F,$FF,$FC,$00  ; row 16
        fcb     $0F,$FF,$FC,$00  ; row 17
        fcb     $0F,$FF,$FC,$00  ; row 18
        fcb     $0F,$FF,$FF,$00  ; row 19
        fcb     $0F,$FF,$FF,$00  ; row 20
        fcb     $0F,$FF,$FF,$C0  ; row 21
        fcb     $0F,$FF,$FF,$C0  ; row 22
