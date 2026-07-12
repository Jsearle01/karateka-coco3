* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: dump05_imprison.bin
*         Apple II label: addr_8ACB
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=0  screen-col parity=EVEN
* [ref: karateka-coco3 docs/project/karateka-coco3-design-v0.1.md §6.7]

scene6_player_8ACB:
        fcb     14,3  ; height=14 rows, coco3_width=3 bytes/row (4px/byte)
        fcb     $0F,$FC,$00  ; row 0
        fcb     $3F,$FF,$00  ; row 1
        fcb     $FF,$FF,$00  ; row 2
        fcb     $FF,$FF,$C0  ; row 3
        fcb     $FF,$FF,$C0  ; row 4
        fcb     $FF,$FF,$C0  ; row 5
        fcb     $FF,$FF,$C0  ; row 6
        fcb     $3F,$FF,$C0  ; row 7
        fcb     $3F,$FF,$C0  ; row 8
        fcb     $3F,$FF,$C0  ; row 9
        fcb     $3F,$FF,$C0  ; row 10
        fcb     $0F,$FF,$00  ; row 11
        fcb     $0F,$FF,$00  ; row 12
        fcb     $3F,$FF,$C0  ; row 13
