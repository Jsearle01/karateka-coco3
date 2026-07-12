* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: dump05_imprison.bin
*         Apple II label: addr_930F
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=0  screen-col parity=EVEN
* [ref: karateka-coco3 docs/project/karateka-coco3-design-v0.1.md §6.7]

scene6_player_930F:
        fcb     9,4  ; height=9 rows, coco3_width=4 bytes/row (4px/byte)
        fcb     $FF,$FF,$FD,$40  ; row 0
        fcb     $FF,$FF,$FD,$40  ; row 1
        fcb     $FF,$FD,$55,$40  ; row 2
        fcb     $FF,$FF,$05,$40  ; row 3
        fcb     $FF,$FF,$F0,$40  ; row 4
        fcb     $F0,$43,$FD,$40  ; row 5
        fcb     $40,$54,$00,$00  ; row 6
        fcb     $40,$54,$00,$00  ; row 7
        fcb     $40,$00,$FF,$F0  ; row 8
