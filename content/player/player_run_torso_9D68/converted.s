* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: dump05_imprison.bin
*         Apple II label: addr_9D68
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=0  screen-col parity=EVEN
* [ref: karateka-coco3 docs/project/karateka-coco3-design-v0.1.md §6.7]

player_run_torso_9D68:
        fcb     15,4  ; height=15 rows, coco3_width=4 bytes/row (4px/byte)
        fcb     $00,$03,$FF,$00  ; row 0
        fcb     $00,$3F,$FF,$00  ; row 1
        fcb     $00,$FF,$FF,$C0  ; row 2
        fcb     $03,$FF,$FF,$C0  ; row 3
        fcb     $0F,$FF,$FF,$C0  ; row 4
        fcb     $0F,$FF,$FF,$C0  ; row 5
        fcb     $3F,$FF,$FF,$F5  ; row 6
        fcb     $3F,$FF,$FF,$F5  ; row 7
        fcb     $3F,$FF,$FF,$F0  ; row 8
        fcb     $3F,$FF,$FF,$F0  ; row 9
        fcb     $0F,$F0,$0F,$C0  ; row 10
        fcb     $0F,$F0,$00,$00  ; row 11
        fcb     $3F,$57,$F0,$00  ; row 12
        fcb     $3F,$57,$FF,$00  ; row 13
        fcb     $3F,$57,$FF,$00  ; row 14
