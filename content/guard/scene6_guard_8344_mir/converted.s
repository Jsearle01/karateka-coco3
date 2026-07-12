* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: dump05_imprison.bin
*         Apple II label: addr_8344
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=0  screen-col parity=EVEN
* [ref: karateka-coco3 docs/project/karateka-coco3-design-v0.1.md §6.7]

scene6_guard_8344_mir:
        fcb     11,7  ; height=11 rows, coco3_width=7 bytes/row (4px/byte)
        fcb     $00,$00,$00,$3F,$FA,$A0,$00  ; row 0
        fcb     $00,$00,$03,$FF,$FB,$FC,$00  ; row 1
        fcb     $2A,$00,$3F,$FF,$BF,$FF,$C0  ; row 2
        fcb     $2A,$BF,$FF,$FF,$AB,$FF,$F0  ; row 3
        fcb     $00,$3F,$FF,$FF,$AB,$FF,$F0  ; row 4
        fcb     $00,$3F,$FF,$FF,$FB,$FF,$F0  ; row 5
        fcb     $00,$00,$03,$FF,$FF,$FF,$F0  ; row 6
        fcb     $00,$00,$0F,$FF,$FF,$FF,$F0  ; row 7
        fcb     $00,$03,$DF,$FF,$FF,$FF,$C0  ; row 8
        fcb     $00,$FF,$C3,$FF,$FF,$FF,$00  ; row 9
        fcb     $0F,$F0,$00,$3F,$FC,$00,$00  ; row 10
