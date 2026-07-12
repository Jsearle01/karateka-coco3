* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: dump05_imprison.bin
*         Apple II label: addr_92DF
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=0  screen-col parity=EVEN
* [ref: karateka-coco3 docs/project/karateka-coco3-design-v0.1.md §6.7]

scene6_player_92DF:
        fcb     4,11  ; height=4 rows, coco3_width=11 bytes/row (4px/byte)
        fcb     $FF,$05,$43,$FF,$FF,$FF,$FF,$F0,$43,$FF,$F0  ; row 0
        fcb     $FD,$54,$00,$00,$00,$00,$00,$00,$55,$FF,$F0  ; row 1
        fcb     $F0,$54,$00,$00,$00,$00,$00,$00,$54,$3F,$F0  ; row 2
        fcb     $FC,$00,$00,$00,$00,$00,$00,$00,$00,$FF,$F0  ; row 3
