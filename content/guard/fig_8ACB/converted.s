* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: dump05 by addr
*         Apple II label: addr_8ACB
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=0
* [ref: karateka-coco3 docs/karateka-coco3-design-v0.1.md §6.7]

fig_8ACB_coco3:
        fcb     14,4  ; height=14 rows, coco3_width=4 bytes/row (4px/byte)
        fcb     $00,$0F,$FC,$00  ; row 0
        fcb     $00,$3F,$FF,$00  ; row 1
        fcb     $00,$FF,$FF,$00  ; row 2
        fcb     $00,$FF,$FF,$C0  ; row 3
        fcb     $00,$FF,$FF,$C0  ; row 4
        fcb     $00,$FF,$FF,$C0  ; row 5
        fcb     $00,$FF,$FF,$C0  ; row 6
        fcb     $00,$3F,$FF,$C0  ; row 7
        fcb     $00,$3F,$FF,$C0  ; row 8
        fcb     $00,$3F,$FF,$C0  ; row 9
        fcb     $00,$3F,$FF,$C0  ; row 10
        fcb     $00,$0F,$FF,$00  ; row 11
        fcb     $00,$0F,$FF,$00  ; row 12
        fcb     $00,$3F,$FF,$C0  ; row 13
