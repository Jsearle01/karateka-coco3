* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: dump05_imprison.bin
*         Apple II label: addr_8DDB
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=0  screen-col parity=EVEN
* [ref: karateka-coco3 docs/project/karateka-coco3-design-v0.1.md §6.7]

scene6_guard_8DDB_mir:
        fcb     10,7  ; height=10 rows, coco3_width=7 bytes/row (4px/byte)
        fcb     $00,$00,$00,$00,$03,$FC,$00  ; row 0
        fcb     $2A,$00,$00,$FF,$FB,$FF,$00  ; row 1
        fcb     $2A,$00,$FF,$AB,$FB,$FF,$C0  ; row 2
        fcb     $02,$BF,$FF,$AA,$BF,$FF,$C0  ; row 3
        fcb     $00,$FF,$FF,$AA,$BF,$FF,$C0  ; row 4
        fcb     $00,$FF,$FF,$FF,$FF,$FF,$C0  ; row 5
        fcb     $00,$FF,$C3,$FF,$FF,$C0,$00  ; row 6
        fcb     $00,$00,$03,$FF,$FF,$C0,$00  ; row 7
        fcb     $00,$00,$03,$FF,$FF,$C0,$00  ; row 8
        fcb     $00,$00,$00,$FF,$FC,$00,$00  ; row 9
