* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: dump05_imprison.bin
*         Apple II label: addr_958E
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=0  screen-col parity=EVEN
* [ref: karateka-coco3 docs/project/karateka-coco3-design-v0.1.md §6.7]

scene6_player_958E:
        fcb     10,7  ; height=10 rows, coco3_width=7 bytes/row (4px/byte)
        fcb     $FF,$57,$FF,$FF,$FF,$FF,$FF  ; row 0
        fcb     $FF,$03,$FF,$FF,$FF,$FF,$FF  ; row 1
        fcb     $FF,$FF,$FF,$FF,$FF,$FF,$FF  ; row 2
        fcb     $FF,$FF,$FF,$FF,$FF,$FF,$FF  ; row 3
        fcb     $FF,$FF,$FF,$FF,$FF,$FF,$FF  ; row 4
        fcb     $FF,$FF,$FF,$FF,$FF,$FF,$FF  ; row 5
        fcb     $FF,$FF,$FF,$FF,$FF,$57,$FF  ; row 6
        fcb     $FF,$FF,$FF,$00,$00,$15,$0F  ; row 7
        fcb     $FF,$C0,$00,$00,$00,$15,$50  ; row 8
        fcb     $FF,$FF,$FF,$00,$00,$00,$01  ; row 9
