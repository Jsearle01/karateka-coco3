* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: dump05_imprison.bin
*         Apple II label: addr_8AE9
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=0  screen-col parity=EVEN
* [ref: karateka-coco3 docs/project/karateka-coco3-design-v0.1.md §6.7]

scene6_guard_8AE9_mir:
        fcb     12,4  ; height=12 rows, coco3_width=4 bytes/row (4px/byte)
        fcb     $00,$00,$2B,$F0  ; row 0
        fcb     $00,$02,$BF,$FC  ; row 1
        fcb     $00,$03,$FF,$FF  ; row 2
        fcb     $00,$0F,$FF,$FF  ; row 3
        fcb     $00,$0F,$FF,$FF  ; row 4
        fcb     $00,$0F,$FF,$FF  ; row 5
        fcb     $00,$0F,$FF,$FF  ; row 6
        fcb     $00,$0F,$FF,$FF  ; row 7
        fcb     $00,$3F,$FF,$FC  ; row 8
        fcb     $00,$FF,$FF,$FC  ; row 9
        fcb     $00,$FF,$FF,$FC  ; row 10
        fcb     $03,$FF,$FF,$FC  ; row 11
