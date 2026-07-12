* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: dump05_imprison.bin
*         Apple II label: addr_8DA9
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=0  screen-col parity=EVEN
* [ref: karateka-coco3 docs/project/karateka-coco3-design-v0.1.md §6.7]

scene6_guard_8DA9_mir:
        fcb     12,6  ; height=12 rows, coco3_width=6 bytes/row (4px/byte)
        fcb     $00,$00,$00,$00,$00,$00  ; row 0
        fcb     $00,$00,$00,$00,$3F,$F0  ; row 1
        fcb     $00,$00,$00,$03,$FF,$C0  ; row 2
        fcb     $00,$00,$00,$3F,$FF,$C2  ; row 3
        fcb     $00,$00,$00,$3F,$FF,$02  ; row 4
        fcb     $00,$00,$03,$FF,$FF,$0F  ; row 5
        fcb     $00,$2B,$FF,$FF,$F0,$0F  ; row 6
        fcb     $2A,$AB,$FF,$FF,$C2,$0F  ; row 7
        fcb     $2A,$AB,$FF,$FF,$FC,$02  ; row 8
        fcb     $00,$00,$03,$FF,$C0,$42  ; row 9
        fcb     $2A,$AA,$BF,$FF,$FF,$FA  ; row 10
        fcb     $2A,$AB,$FF,$FF,$FF,$C2  ; row 11
