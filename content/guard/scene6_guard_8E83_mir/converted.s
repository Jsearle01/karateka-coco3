* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: dump05_imprison.bin
*         Apple II label: addr_8E83
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=0  screen-col parity=EVEN
* [ref: karateka-coco3 docs/project/karateka-coco3-design-v0.1.md §6.7]

scene6_guard_8E83_mir:
        fcb     11,4  ; height=11 rows, coco3_width=4 bytes/row (4px/byte)
        fcb     $0F,$FF,$F0,$00  ; row 0
        fcb     $FF,$FF,$FF,$00  ; row 1
        fcb     $FF,$FF,$FF,$E0  ; row 2
        fcb     $FF,$FF,$FF,$E0  ; row 3
        fcb     $FF,$FF,$FF,$F0  ; row 4
        fcb     $FF,$FC,$00,$00  ; row 5
        fcb     $FF,$FC,$00,$00  ; row 6
        fcb     $FF,$FC,$00,$00  ; row 7
        fcb     $FF,$FC,$00,$00  ; row 8
        fcb     $3F,$FC,$00,$00  ; row 9
        fcb     $3F,$FC,$00,$00  ; row 10
