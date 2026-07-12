* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: dump05_imprison.bin
*         Apple II label: addr_8AE9
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=0  screen-col parity=EVEN
* [ref: karateka-coco3 docs/project/karateka-coco3-design-v0.1.md §6.7]

scene6_player_8AE9:
        fcb     12,4  ; height=12 rows, coco3_width=4 bytes/row (4px/byte)
        fcb     $03,$F5,$00,$00  ; row 0
        fcb     $0F,$FF,$50,$00  ; row 1
        fcb     $3F,$FF,$F0,$00  ; row 2
        fcb     $3F,$FF,$FC,$00  ; row 3
        fcb     $3F,$FF,$FC,$00  ; row 4
        fcb     $3F,$FF,$FC,$00  ; row 5
        fcb     $3F,$FF,$FC,$00  ; row 6
        fcb     $3F,$FF,$FC,$00  ; row 7
        fcb     $0F,$FF,$FF,$00  ; row 8
        fcb     $0F,$FF,$FF,$C0  ; row 9
        fcb     $0F,$FF,$FF,$C0  ; row 10
        fcb     $0F,$FF,$FF,$F0  ; row 11
