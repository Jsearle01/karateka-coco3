* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: dump05_imprison.bin
*         Apple II label: addr_90A7
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=0  screen-col parity=EVEN
* [ref: karateka-coco3 docs/project/karateka-coco3-design-v0.1.md §6.7]

scene6_guard_90A7_mir:
        fcb     4,11  ; height=4 rows, coco3_width=11 bytes/row (4px/byte)
        fcb     $FF,$FF,$FF,$FF,$FF,$C2,$0F,$FF,$FF,$FF,$F0  ; row 0
        fcb     $F0,$00,$00,$00,$00,$02,$A0,$00,$03,$FF,$F0  ; row 1
        fcb     $00,$00,$00,$00,$00,$02,$AA,$00,$00,$0F,$F0  ; row 2
        fcb     $40,$00,$00,$00,$00,$00,$00,$00,$03,$FF,$F0  ; row 3
