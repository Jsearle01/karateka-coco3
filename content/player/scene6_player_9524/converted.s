* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: dump05_imprison.bin
*         Apple II label: addr_9524
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=0  screen-col parity=EVEN
* [ref: karateka-coco3 docs/project/karateka-coco3-design-v0.1.md §6.7]

scene6_player_9524:
        fcb     7,11  ; height=7 rows, coco3_width=11 bytes/row (4px/byte)
        fcb     $FF,$FF,$57,$FF,$FF,$FF,$FF,$F5,$7F,$FF,$F0  ; row 0
        fcb     $FF,$F5,$57,$FF,$FF,$FF,$FF,$F5,$7F,$FF,$F0  ; row 1
        fcb     $FF,$F5,$57,$FF,$FF,$FF,$FF,$F5,$57,$FF,$F0  ; row 2
        fcb     $FF,$F5,$57,$FF,$FF,$FF,$FF,$F5,$57,$FF,$F0  ; row 3
        fcb     $FF,$C0,$10,$00,$00,$00,$00,$00,$15,$0F,$F0  ; row 4
        fcb     $FF,$C0,$15,$00,$00,$00,$00,$00,$00,$0F,$F0  ; row 5
        fcb     $FF,$FC,$00,$00,$00,$00,$00,$00,$00,$FF,$F0  ; row 6
