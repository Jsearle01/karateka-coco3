* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: dump05_imprison.bin
*         Apple II label: addr_9E92
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=0  screen-col parity=EVEN
* [ref: karateka-coco3 docs/project/karateka-coco3-design-v0.1.md §6.7]

player_run_torso_9E92:
        fcb     12,4  ; height=12 rows, coco3_width=4 bytes/row (4px/byte)
        fcb     $00,$0F,$FC,$00  ; row 0
        fcb     $00,$0F,$FF,$00  ; row 1
        fcb     $00,$3F,$FF,$C0  ; row 2
        fcb     $00,$FF,$FF,$C0  ; row 3
        fcb     $03,$FF,$FF,$F0  ; row 4
        fcb     $03,$FF,$FF,$F0  ; row 5
        fcb     $0F,$FF,$FF,$FC  ; row 6
        fcb     $0F,$FF,$FF,$FC  ; row 7
        fcb     $0F,$FF,$FF,$FC  ; row 8
        fcb     $0F,$FF,$FF,$FF  ; row 9
        fcb     $03,$FF,$FF,$00  ; row 10
        fcb     $03,$FF,$00,$00  ; row 11
