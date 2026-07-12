* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: dump05_imprison.bin
*         Apple II label: addr_9337
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=0  screen-col parity=EVEN
* [ref: karateka-coco3 docs/project/karateka-coco3-design-v0.1.md §6.7]

scene6_player_9337:
        fcb     4,7  ; height=4 rows, coco3_width=7 bytes/row (4px/byte)
        fcb     $F0,$43,$FF,$FF,$04,$3F,$FF  ; row 0
        fcb     $55,$40,$00,$00,$05,$5F,$FF  ; row 1
        fcb     $55,$40,$00,$00,$05,$43,$FF  ; row 2
        fcb     $40,$00,$00,$00,$00,$0F,$FF  ; row 3
