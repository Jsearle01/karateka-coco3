* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: sprite_data_9b00.s
*         Apple II label: player_run_legs_9CAF
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=0
* [ref: karateka-coco3 docs/karateka-coco3-design-v0.1.md §6.7]

player_run_legs_9CAF_coco3:
        fcb     19,3  ; height=19 rows, coco3_width=3 bytes/row (4px/byte)
        fcb     $00,$F1,$00  ; row 0
        fcb     $03,$FF,$C0  ; row 1
        fcb     $03,$FF,$C0  ; row 2
        fcb     $03,$FF,$00  ; row 3
        fcb     $03,$FF,$00  ; row 4
        fcb     $03,$FF,$00  ; row 5
        fcb     $0F,$FF,$00  ; row 6
        fcb     $0F,$FF,$00  ; row 7
        fcb     $0F,$FF,$00  ; row 8
        fcb     $0F,$FC,$00  ; row 9
        fcb     $0F,$FC,$00  ; row 10
        fcb     $0F,$FC,$00  ; row 11
        fcb     $3F,$FC,$00  ; row 12
        fcb     $3F,$FC,$00  ; row 13
        fcb     $3F,$FC,$00  ; row 14
        fcb     $3F,$C0,$00  ; row 15
        fcb     $01,$00,$00  ; row 16
        fcb     $01,$50,$00  ; row 17
        fcb     $01,$55,$00  ; row 18
