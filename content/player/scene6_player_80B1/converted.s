* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: dump05_imprison.bin
*         Apple II label: addr_80B1
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=0  screen-col parity=EVEN
* [ref: karateka-coco3 docs/project/karateka-coco3-design-v0.1.md §6.7]

scene6_player_80B1:
        fcb     22,3  ; height=22 rows, coco3_width=3 bytes/row (4px/byte)
        fcb     $0F,$0F,$C0  ; row 0
        fcb     $3F,$0F,$00  ; row 1
        fcb     $3F,$FF,$00  ; row 2
        fcb     $3F,$FF,$00  ; row 3
        fcb     $3F,$FF,$00  ; row 4
        fcb     $3F,$FF,$00  ; row 5
        fcb     $3F,$FF,$00  ; row 6
        fcb     $0F,$FF,$00  ; row 7
        fcb     $0F,$FF,$00  ; row 8
        fcb     $0F,$FF,$00  ; row 9
        fcb     $0F,$FF,$C0  ; row 10
        fcb     $0F,$FF,$C0  ; row 11
        fcb     $03,$FF,$C0  ; row 12
        fcb     $03,$FF,$C0  ; row 13
        fcb     $03,$FF,$C0  ; row 14
        fcb     $03,$FF,$C0  ; row 15
        fcb     $00,$FF,$C0  ; row 16
        fcb     $00,$FF,$C0  ; row 17
        fcb     $00,$3F,$00  ; row 18
        fcb     $00,$15,$00  ; row 19
        fcb     $00,$15,$00  ; row 20
        fcb     $01,$55,$00  ; row 21
