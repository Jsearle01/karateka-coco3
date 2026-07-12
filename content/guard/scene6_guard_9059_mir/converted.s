* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: dump05_imprison.bin
*         Apple II label: addr_9059
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=0  screen-col parity=EVEN
* [ref: karateka-coco3 docs/project/karateka-coco3-design-v0.1.md §6.7]

scene6_guard_9059_mir:
        fcb     4,9  ; height=4 rows, coco3_width=9 bytes/row (4px/byte)
        fcb     $FF,$FF,$FF,$F0,$83,$FF,$FF,$FF,$FC  ; row 0
        fcb     $FF,$FF,$C0,$00,$A8,$00,$00,$FF,$FC  ; row 1
        fcb     $FF,$F0,$00,$00,$AA,$80,$00,$03,$FC  ; row 2
        fcb     $FF,$FF,$C0,$00,$00,$00,$00,$FF,$FC  ; row 3
