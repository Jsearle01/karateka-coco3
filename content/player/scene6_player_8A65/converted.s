* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: dump05_imprison.bin
*         Apple II label: addr_8A65
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=0  screen-col parity=EVEN
* [ref: karateka-coco3 docs/project/karateka-coco3-design-v0.1.md §6.7]

scene6_player_8A65:
        fcb     20,8  ; height=20 rows, coco3_width=8 bytes/row (4px/byte)
        fcb     $00,$00,$F0,$00,$02,$00,$00,$00  ; row 0
        fcb     $00,$03,$FF,$04,$3F,$C0,$00,$00  ; row 1
        fcb     $00,$03,$FC,$3F,$0F,$F0,$00,$00  ; row 2
        fcb     $00,$0F,$FC,$3F,$0F,$FC,$00,$00  ; row 3
        fcb     $00,$0F,$FF,$FF,$FF,$FF,$00,$00  ; row 4
        fcb     $00,$3F,$FF,$FF,$FF,$FF,$C0,$00  ; row 5
        fcb     $00,$3F,$FF,$C0,$FF,$FF,$C0,$00  ; row 6
        fcb     $00,$FF,$FF,$00,$0F,$FF,$F0,$00  ; row 7
        fcb     $00,$FF,$FC,$00,$03,$FF,$F0,$00  ; row 8
        fcb     $03,$FF,$F0,$00,$00,$FF,$FC,$00  ; row 9
        fcb     $03,$FF,$F0,$00,$00,$3F,$FC,$00  ; row 10
        fcb     $03,$FF,$C0,$00,$00,$0F,$FF,$00  ; row 11
        fcb     $03,$FF,$00,$00,$00,$0F,$FF,$00  ; row 12
        fcb     $0F,$FF,$00,$00,$00,$03,$FF,$C0  ; row 13
        fcb     $0F,$FC,$00,$00,$00,$03,$FF,$C0  ; row 14
        fcb     $0F,$FC,$00,$00,$00,$00,$FF,$C0  ; row 15
        fcb     $0F,$FC,$00,$00,$00,$00,$FF,$C0  ; row 16
        fcb     $04,$00,$00,$00,$00,$00,$04,$00  ; row 17
        fcb     $54,$00,$00,$00,$00,$00,$05,$40  ; row 18
        fcb     $54,$00,$00,$00,$00,$00,$05,$54  ; row 19
