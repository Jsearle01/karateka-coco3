* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: dump05_imprison.bin
*         Apple II label: addr_8D0A
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=0  screen-col parity=EVEN
* [ref: karateka-coco3 docs/project/karateka-coco3-design-v0.1.md §6.7]

scene6_guard_8D0A_mir:
        fcb     6,9  ; height=6 rows, coco3_width=9 bytes/row (4px/byte)
        fcb     $00,$00,$00,$00,$0F,$FF,$FF,$00,$00  ; row 0
        fcb     $02,$00,$00,$03,$FF,$FF,$FF,$FF,$C0  ; row 1
        fcb     $02,$00,$00,$FF,$FF,$BF,$FF,$FF,$C0  ; row 2
        fcb     $02,$AA,$BF,$FF,$FA,$BF,$FF,$FF,$00  ; row 3
        fcb     $00,$2A,$BF,$FF,$AA,$AB,$FF,$FF,$00  ; row 4
        fcb     $00,$20,$3F,$FF,$AA,$00,$FF,$FF,$00  ; row 5
