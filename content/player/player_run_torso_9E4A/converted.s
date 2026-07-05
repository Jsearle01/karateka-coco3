* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: sprite_data_9b00.s
*         Apple II label: player_run_torso_9E4A
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=0
* [ref: karateka-coco3 docs/karateka-coco3-design-v0.1.md §6.7]

player_run_torso_9E4A_coco3:
        fcb     20,3  ; height=20 rows, coco3_width=3 bytes/row (4px/byte)
        fcb     $00,$3C,$80  ; row 0
        fcb     $00,$FF,$C0  ; row 1
        fcb     $03,$FF,$C0  ; row 2
        fcb     $0F,$FF,$F0  ; row 3
        fcb     $0F,$FF,$F0  ; row 4
        fcb     $0F,$FF,$F0  ; row 5
        fcb     $7F,$FF,$F0  ; row 6
        fcb     $7F,$FF,$F0  ; row 7
        fcb     $7F,$FF,$C0  ; row 8
        fcb     $7F,$FF,$C0  ; row 9
        fcb     $7F,$FF,$C0  ; row 10
        fcb     $7F,$F0,$00  ; row 11
        fcb     $7F,$F0,$00  ; row 12
        fcb     $FF,$FF,$C0  ; row 13
        fcb     $FF,$FF,$C0  ; row 14
        fcb     $FF,$FF,$00  ; row 15
        fcb     $FF,$FF,$00  ; row 16
        fcb     $7C,$AF,$00  ; row 17
        fcb     $7C,$A8,$00  ; row 18
        fcb     $7C,$A8,$00  ; row 19
