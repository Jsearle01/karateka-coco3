* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: dump05_imprison.bin
*         Apple II label: addr_95E4
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=0  screen-col parity=EVEN
* [ref: karateka-coco3 docs/project/karateka-coco3-design-v0.1.md §6.7]

scene6_player_95E4:
        fcb     7,7  ; height=7 rows, coco3_width=7 bytes/row (4px/byte)
        fcb     $FF,$F5,$7F,$FF,$FF,$FF,$FF  ; row 0
        fcb     $FF,$F5,$57,$FF,$FF,$FF,$FF  ; row 1
        fcb     $FF,$F0,$17,$FF,$FF,$FF,$FF  ; row 2
        fcb     $FF,$FF,$57,$FF,$FF,$50,$FF  ; row 3
        fcb     $FF,$FF,$50,$00,$00,$15,$7F  ; row 4
        fcb     $FF,$FF,$00,$00,$00,$15,$55  ; row 5
        fcb     $FF,$FF,$00,$00,$F0,$0F,$00  ; row 6
