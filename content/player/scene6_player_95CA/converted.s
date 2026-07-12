* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: dump05_imprison.bin
*         Apple II label: addr_95CA
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=0  screen-col parity=EVEN
* [ref: karateka-coco3 docs/project/karateka-coco3-design-v0.1.md §6.7]

scene6_player_95CA:
        fcb     6,7  ; height=6 rows, coco3_width=7 bytes/row (4px/byte)
        fcb     $FF,$FF,$FF,$FF,$F5,$57,$FF  ; row 0
        fcb     $FF,$F5,$7F,$FF,$F5,$50,$3F  ; row 1
        fcb     $FF,$F5,$57,$FF,$FF,$55,$7F  ; row 2
        fcb     $FF,$F5,$50,$00,$00,$00,$3F  ; row 3
        fcb     $FF,$F0,$15,$00,$00,$00,$01  ; row 4
        fcb     $FF,$F0,$00,$00,$00,$00,$3F  ; row 5
