* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: dump05_imprison.bin
*         Apple II label: addr_8D2A
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=0  screen-col parity=EVEN
* [ref: karateka-coco3 docs/project/karateka-coco3-design-v0.1.md §6.7]

scene6_guard_8D2A_mir:
        fcb     15,8  ; height=15 rows, coco3_width=8 bytes/row (4px/byte)
        fcb     $00,$00,$00,$00,$00,$02,$A0,$00  ; row 0
        fcb     $00,$00,$00,$00,$00,$02,$A0,$3C  ; row 1
        fcb     $00,$00,$00,$00,$00,$00,$2B,$FC  ; row 2
        fcb     $00,$00,$00,$00,$00,$00,$2B,$FC  ; row 3
        fcb     $00,$00,$00,$00,$2A,$BF,$FF,$FC  ; row 4
        fcb     $00,$00,$00,$00,$2A,$BF,$FF,$FC  ; row 5
        fcb     $00,$00,$00,$00,$20,$3F,$FF,$FC  ; row 6
        fcb     $00,$00,$00,$00,$00,$00,$0F,$FC  ; row 7
        fcb     $20,$00,$00,$03,$FF,$FC,$0F,$FC  ; row 8
        fcb     $20,$00,$03,$FF,$FF,$C0,$03,$FC  ; row 9
        fcb     $2A,$BF,$FF,$FF,$FF,$C3,$C0,$FC  ; row 10
        fcb     $2A,$BF,$FF,$FB,$FF,$FF,$F0,$3C  ; row 11
        fcb     $02,$BF,$FF,$FB,$FF,$FF,$FC,$04  ; row 12
        fcb     $00,$02,$AA,$AB,$FF,$FF,$FF,$00  ; row 13
        fcb     $00,$02,$AA,$AB,$FF,$FF,$F0,$00  ; row 14
