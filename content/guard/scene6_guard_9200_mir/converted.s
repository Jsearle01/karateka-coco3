* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: dump05_imprison.bin
*         Apple II label: addr_9200
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=0  screen-col parity=EVEN
* [ref: karateka-coco3 docs/project/karateka-coco3-design-v0.1.md §6.7]

scene6_guard_9200_mir:
        fcb     10,13  ; height=10 rows, coco3_width=13 bytes/row (4px/byte)
        fcb     $FF,$FF,$FF,$FF,$FF,$A0,$3F,$FF,$FF,$FF,$FF,$FF,$C0  ; row 0
        fcb     $FF,$AB,$FF,$FF,$FF,$00,$00,$0F,$FF,$FF,$FF,$FF,$C0  ; row 1
        fcb     $FF,$A0,$FF,$FF,$FF,$FF,$FC,$0F,$FF,$FF,$FF,$FF,$C0  ; row 2
        fcb     $FF,$A0,$3F,$FF,$FF,$FF,$C0,$03,$FF,$FF,$FF,$FF,$C0  ; row 3
        fcb     $FF,$AA,$BF,$FF,$FF,$FF,$C3,$C0,$FF,$FF,$FF,$FF,$C0  ; row 4
        fcb     $FF,$AA,$BF,$FF,$FB,$FF,$FF,$F0,$3F,$FB,$FF,$FF,$C0  ; row 5
        fcb     $FF,$02,$BF,$FF,$FB,$FF,$FF,$FC,$04,$00,$FF,$FF,$C0  ; row 6
        fcb     $FF,$F0,$02,$AA,$AB,$FF,$FF,$FF,$00,$00,$03,$FF,$C0  ; row 7
        fcb     $FF,$FC,$02,$AA,$AB,$FF,$FF,$F0,$00,$00,$00,$FF,$C0  ; row 8
        fcb     $F0,$00,$00,$00,$00,$00,$00,$00,$3F,$FF,$FF,$FF,$C0  ; row 9
