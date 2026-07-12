* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: dump05_imprison.bin
*         Apple II label: addr_91D6
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=0  screen-col parity=EVEN
* [ref: karateka-coco3 docs/project/karateka-coco3-design-v0.1.md §6.7]

scene6_guard_91D6_mir:
        fcb     8,9  ; height=8 rows, coco3_width=9 bytes/row (4px/byte)
        fcb     $FF,$FF,$FF,$FF,$FF,$FC,$00,$00,$00  ; row 0
        fcb     $FA,$0F,$FF,$FF,$FF,$FF,$FF,$C0,$00  ; row 1
        fcb     $FA,$0F,$FF,$FF,$FF,$FF,$FF,$FF,$FC  ; row 2
        fcb     $FA,$AA,$BF,$FF,$FF,$BF,$FF,$FF,$FC  ; row 3
        fcb     $FA,$AA,$BF,$FF,$FA,$BF,$FF,$FF,$FC  ; row 4
        fcb     $F0,$2A,$BF,$FF,$AA,$AB,$FF,$FF,$FC  ; row 5
        fcb     $40,$20,$3F,$FF,$AA,$00,$FF,$FF,$C0  ; row 6
        fcb     $00,$00,$00,$00,$00,$00,$00,$00,$00  ; row 7
