* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: sprite_data_9b00.s
*         Apple II label: player_run_legs_9D1E
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=0
* [ref: karateka-coco3 docs/karateka-coco3-design-v0.1.md §6.7]

player_run_legs_9D1E_coco3:
        fcb     24,5  ; height=24 rows, coco3_width=5 bytes/row (4px/byte)
        fcb     $03,$FF,$00,$3F,$00  ; row 0
        fcb     $03,$FF,$FF,$FF,$00  ; row 1
        fcb     $00,$FF,$FF,$FF,$C0  ; row 2
        fcb     $00,$FE,$FF,$FF,$C0  ; row 3
        fcb     $00,$0A,$FF,$FF,$C0  ; row 4
        fcb     $00,$0A,$AF,$FF,$C0  ; row 5
        fcb     $00,$0A,$AF,$FF,$C0  ; row 6
        fcb     $00,$00,$AF,$FF,$C0  ; row 7
        fcb     $00,$00,$3F,$FF,$F0  ; row 8
        fcb     $00,$00,$0F,$FF,$F0  ; row 9
        fcb     $00,$00,$0F,$FF,$F0  ; row 10
        fcb     $00,$00,$0F,$FF,$F0  ; row 11
        fcb     $00,$00,$0F,$FF,$F0  ; row 12
        fcb     $00,$00,$FF,$FF,$F0  ; row 13
        fcb     $00,$0F,$FF,$FF,$F0  ; row 14
        fcb     $00,$FF,$FF,$FF,$FC  ; row 15
        fcb     $0F,$FF,$FF,$EF,$FC  ; row 16
        fcb     $0F,$FF,$FC,$0F,$FC  ; row 17
        fcb     $AF,$FF,$C0,$0F,$FC  ; row 18
        fcb     $AA,$FC,$00,$0F,$FC  ; row 19
        fcb     $08,$00,$00,$0F,$FC  ; row 20
        fcb     $08,$00,$00,$08,$00  ; row 21
        fcb     $08,$00,$00,$0A,$80  ; row 22
        fcb     $00,$00,$00,$0A,$A8  ; row 23
