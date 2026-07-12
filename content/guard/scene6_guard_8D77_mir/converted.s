* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: dump05_imprison.bin
*         Apple II label: addr_8D77
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=0  screen-col parity=EVEN
* [ref: karateka-coco3 docs/project/karateka-coco3-design-v0.1.md §6.7]

scene6_guard_8D77_mir:
        fcb     12,6  ; height=12 rows, coco3_width=6 bytes/row (4px/byte)
        fcb     $20,$00,$00,$00,$00,$00  ; row 0
        fcb     $20,$00,$00,$00,$00,$00  ; row 1
        fcb     $2A,$AB,$FF,$FF,$FC,$00  ; row 2
        fcb     $02,$AB,$FF,$FF,$FF,$F0  ; row 3
        fcb     $02,$03,$FF,$FF,$FF,$F0  ; row 4
        fcb     $00,$03,$FF,$FF,$FF,$C0  ; row 5
        fcb     $00,$2A,$AB,$FF,$FF,$00  ; row 6
        fcb     $00,$2A,$AB,$FF,$FF,$00  ; row 7
        fcb     $00,$2A,$AB,$FF,$FF,$04  ; row 8
        fcb     $00,$00,$03,$FF,$FF,$04  ; row 9
        fcb     $00,$00,$03,$FF,$FF,$FD  ; row 10
        fcb     $00,$00,$00,$00,$0F,$FF  ; row 11
