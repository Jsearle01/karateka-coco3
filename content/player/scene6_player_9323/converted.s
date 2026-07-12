* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: dump05_imprison.bin
*         Apple II label: addr_9323
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=0  screen-col parity=EVEN
* [ref: karateka-coco3 docs/project/karateka-coco3-design-v0.1.md §6.7]

scene6_player_9323:
        fcb     6,6  ; height=6 rows, coco3_width=6 bytes/row (4px/byte)
        fcb     $FF,$FF,$FF,$FF,$C3,$C0  ; row 0
        fcb     $FF,$FF,$FF,$FD,$55,$40  ; row 1
        fcb     $FD,$43,$FF,$F0,$55,$40  ; row 2
        fcb     $FD,$54,$00,$00,$55,$40  ; row 3
        fcb     $FD,$54,$00,$05,$43,$C0  ; row 4
        fcb     $FC,$00,$00,$00,$0F,$C0  ; row 5
