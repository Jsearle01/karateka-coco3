* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: dump05_imprison.bin
*         Apple II label: addr_876B
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=0  screen-col parity=EVEN
* [ref: karateka-coco3 docs/project/karateka-coco3-design-v0.1.md §6.7]

scene6_guard_876B_mir:
        fcb     14,9  ; height=14 rows, coco3_width=9 bytes/row (4px/byte)
        fcb     $00,$00,$00,$00,$00,$3F,$FC,$00,$00  ; row 0
        fcb     $00,$00,$00,$03,$FF,$FF,$FF,$C0,$00  ; row 1
        fcb     $2A,$AB,$FF,$FF,$FF,$FF,$FF,$F0,$00  ; row 2
        fcb     $2A,$03,$FF,$FF,$FF,$FF,$FF,$FC,$00  ; row 3
        fcb     $00,$03,$FF,$FF,$FF,$FF,$FF,$FC,$00  ; row 4
        fcb     $00,$00,$00,$00,$03,$FF,$FF,$FF,$00  ; row 5
        fcb     $00,$00,$00,$00,$03,$FF,$FF,$FF,$C0  ; row 6
        fcb     $00,$00,$00,$00,$03,$FF,$FF,$FF,$F8  ; row 7
        fcb     $00,$00,$00,$00,$03,$FF,$FF,$FF,$F8  ; row 8
        fcb     $00,$00,$00,$00,$00,$FF,$FF,$FF,$C0  ; row 9
        fcb     $00,$00,$00,$00,$00,$FF,$FF,$FF,$00  ; row 10
        fcb     $00,$00,$00,$00,$00,$FF,$FF,$FC,$00  ; row 11
        fcb     $00,$00,$00,$00,$00,$FF,$FF,$C0,$00  ; row 12
        fcb     $00,$00,$00,$00,$00,$FF,$FC,$00,$00  ; row 13
