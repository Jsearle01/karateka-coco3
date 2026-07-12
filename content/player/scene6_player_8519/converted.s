* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: dump05_imprison.bin
*         Apple II label: addr_8519
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=0  screen-col parity=EVEN
* [ref: karateka-coco3 docs/project/karateka-coco3-design-v0.1.md §6.7]

scene6_player_8519:
        fcb     20,5  ; height=20 rows, coco3_width=5 bytes/row (4px/byte)
        fcb     $04,$00,$00,$00,$00  ; row 0
        fcb     $0F,$00,$03,$C0,$00  ; row 1
        fcb     $0F,$C2,$0F,$C0,$00  ; row 2
        fcb     $02,$0F,$C2,$00,$00  ; row 3
        fcb     $02,$0F,$C2,$00,$00  ; row 4
        fcb     $03,$FF,$FF,$00,$00  ; row 5
        fcb     $03,$FF,$FF,$00,$00  ; row 6
        fcb     $03,$FF,$FF,$00,$00  ; row 7
        fcb     $03,$FF,$FF,$00,$00  ; row 8
        fcb     $00,$FF,$FC,$00,$00  ; row 9
        fcb     $00,$FF,$FC,$00,$00  ; row 10
        fcb     $00,$FF,$FF,$00,$00  ; row 11
        fcb     $00,$FF,$FF,$C0,$00  ; row 12
        fcb     $00,$FF,$FF,$FC,$00  ; row 13
        fcb     $03,$FF,$FF,$FF,$00  ; row 14
        fcb     $03,$FF,$BF,$FF,$C0  ; row 15
        fcb     $03,$FC,$03,$FD,$54  ; row 16
        fcb     $00,$F0,$00,$00,$54  ; row 17
        fcb     $05,$54,$00,$00,$40  ; row 18
        fcb     $00,$54,$00,$05,$40  ; row 19
