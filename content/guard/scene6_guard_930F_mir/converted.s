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

scene6_guard_930F_mir:
        fcb     9,4  ; height=9 rows, coco3_width=4 bytes/row (4px/byte)
        fcb     $2B,$FF,$FF,$F0  ; row 0
        fcb     $2B,$FF,$FF,$F0  ; row 1
        fcb     $2A,$AB,$FF,$F0  ; row 2
        fcb     $2A,$0F,$FF,$F0  ; row 3
        fcb     $20,$FF,$FF,$F0  ; row 4
        fcb     $2B,$FC,$20,$F0  ; row 5
        fcb     $00,$02,$A0,$20  ; row 6
        fcb     $00,$02,$A0,$20  ; row 7
        fcb     $FF,$F0,$00,$20  ; row 8
