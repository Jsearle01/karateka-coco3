* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: dump05_imprison.bin
*         Apple II label: addr_9E74
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=0  screen-col parity=EVEN
* [ref: karateka-coco3 docs/project/karateka-coco3-design-v0.1.md §6.7]

player_run_torso_9E74:
        fcb     14,4  ; height=14 rows, coco3_width=4 bytes/row (4px/byte)
        fcb     $00,$03,$F5,$00  ; row 0
        fcb     $00,$0F,$FF,$00  ; row 1
        fcb     $00,$3F,$FF,$00  ; row 2
        fcb     $00,$FF,$FF,$C0  ; row 3
        fcb     $00,$FF,$FF,$C0  ; row 4
        fcb     $00,$FF,$FF,$C0  ; row 5
        fcb     $00,$FF,$FF,$C0  ; row 6
        fcb     $03,$FF,$FF,$C0  ; row 7
        fcb     $03,$FF,$FF,$00  ; row 8
        fcb     $00,$FF,$FF,$00  ; row 9
        fcb     $00,$FF,$FC,$00  ; row 10
        fcb     $0F,$FF,$FC,$00  ; row 11
        fcb     $7F,$FF,$00,$00  ; row 12
        fcb     $7F,$FF,$50,$00  ; row 13
