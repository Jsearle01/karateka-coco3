* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: dump05_imprison.bin
*         Apple II label: addr_9116
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=0  screen-col parity=EVEN
* [ref: karateka-coco3 docs/project/karateka-coco3-design-v0.1.md §6.7]

scene6_guard_9116_mir:
        fcb     6,9  ; height=6 rows, coco3_width=9 bytes/row (4px/byte)
        fcb     $FF,$FF,$C2,$0F,$FF,$FF,$FF,$FF,$FC  ; row 0
        fcb     $FF,$F0,$2A,$03,$FF,$FF,$FF,$BF,$FC  ; row 1
        fcb     $FF,$FA,$AA,$00,$00,$FF,$C2,$0F,$FC  ; row 2
        fcb     $FF,$F0,$00,$00,$00,$00,$2A,$03,$FC  ; row 3
        fcb     $FF,$C0,$00,$00,$00,$02,$AA,$0F,$FC  ; row 4
        fcb     $FF,$FF,$FF,$FF,$00,$00,$00,$0F,$FC  ; row 5
