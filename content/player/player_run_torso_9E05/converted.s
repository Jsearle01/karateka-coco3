* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: dump05_imprison.bin
*         Apple II label: addr_9E05
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=0  screen-col parity=EVEN
* [ref: karateka-coco3 docs/project/karateka-coco3-design-v0.1.md §6.7]

player_run_torso_9E05:
        fcb     13,4  ; height=13 rows, coco3_width=4 bytes/row (4px/byte)
        fcb     $03,$FF,$00,$00  ; row 0
        fcb     $0F,$FF,$C0,$00  ; row 1
        fcb     $0F,$FF,$C0,$00  ; row 2
        fcb     $7F,$FF,$C0,$00  ; row 3
        fcb     $7F,$FF,$C0,$00  ; row 4
        fcb     $7F,$FF,$F0,$00  ; row 5
        fcb     $FF,$FF,$F0,$00  ; row 6
        fcb     $FF,$FF,$F0,$00  ; row 7
        fcb     $FF,$FF,$F0,$00  ; row 8
        fcb     $FF,$FF,$F0,$00  ; row 9
        fcb     $0F,$FF,$FF,$F5  ; row 10
        fcb     $00,$FF,$FF,$F5  ; row 11
        fcb     $F0,$0F,$FF,$F5  ; row 12
