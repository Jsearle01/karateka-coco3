* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: dump05_imprison.bin
*         Apple II label: addr_89CE
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=0  screen-col parity=EVEN
* [ref: karateka-coco3 docs/project/karateka-coco3-design-v0.1.md §6.7]

scene6_player_89CE:
        fcb     26,4  ; height=26 rows, coco3_width=4 bytes/row (4px/byte)
        fcb     $03,$FF,$FF,$F0  ; row 0
        fcb     $03,$FF,$00,$F0  ; row 1
        fcb     $0F,$F5,$00,$10  ; row 2
        fcb     $0F,$F5,$7F,$50  ; row 3
        fcb     $0F,$F5,$7F,$50  ; row 4
        fcb     $0F,$FF,$7F,$C0  ; row 5
        fcb     $0F,$FF,$FF,$C0  ; row 6
        fcb     $03,$FF,$FF,$C0  ; row 7
        fcb     $03,$FF,$FF,$F0  ; row 8
        fcb     $03,$FF,$FF,$F0  ; row 9
        fcb     $03,$FF,$FF,$F0  ; row 10
        fcb     $03,$FF,$FF,$F0  ; row 11
        fcb     $03,$FF,$FF,$F0  ; row 12
        fcb     $03,$FF,$FF,$F0  ; row 13
        fcb     $0F,$FF,$FF,$F0  ; row 14
        fcb     $0F,$FF,$FF,$F0  ; row 15
        fcb     $0F,$FF,$FF,$F0  ; row 16
        fcb     $0F,$FF,$FF,$C0  ; row 17
        fcb     $0F,$FF,$FF,$C0  ; row 18
        fcb     $0F,$FF,$FF,$C0  ; row 19
        fcb     $0F,$FF,$7F,$C0  ; row 20
        fcb     $0F,$FF,$55,$00  ; row 21
        fcb     $0F,$FF,$55,$00  ; row 22
        fcb     $01,$00,$01,$50  ; row 23
        fcb     $01,$50,$00,$00  ; row 24
        fcb     $01,$55,$00,$00  ; row 25
