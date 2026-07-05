* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: sprite_data_9b00.s
*         Apple II label: player_run_torso_9D97
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=0
* [ref: karateka-coco3 docs/karateka-coco3-design-v0.1.md §6.7]

player_run_torso_9D97_coco3:
        fcb     15,6  ; height=15 rows, coco3_width=6 bytes/row (4px/byte)
        fcb     $00,$03,$FF,$00,$00,$00  ; row 0
        fcb     $00,$3F,$FF,$C0,$00,$00  ; row 1
        fcb     $00,$FF,$FF,$F0,$00,$00  ; row 2
        fcb     $03,$FF,$FF,$F0,$00,$00  ; row 3
        fcb     $0F,$FF,$FF,$FC,$00,$00  ; row 4
        fcb     $3F,$FF,$FF,$FC,$00,$00  ; row 5
        fcb     $FF,$FF,$FF,$FF,$00,$00  ; row 6
        fcb     $FF,$FF,$FF,$FF,$00,$00  ; row 7
        fcb     $3F,$FF,$FF,$FF,$C0,$00  ; row 8
        fcb     $0F,$FF,$FF,$FF,$FF,$10  ; row 9
        fcb     $00,$00,$FF,$FF,$FF,$10  ; row 10
        fcb     $00,$00,$00,$3F,$FF,$10  ; row 11
        fcb     $3F,$FF,$00,$00,$00,$00  ; row 12
        fcb     $3F,$FF,$FF,$00,$00,$00  ; row 13
        fcb     $3F,$FF,$FF,$00,$00,$00  ; row 14
