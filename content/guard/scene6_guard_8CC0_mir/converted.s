* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: dump05_imprison.bin
*         Apple II label: addr_8CC0
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=0  screen-col parity=EVEN
* [ref: karateka-coco3 docs/project/karateka-coco3-design-v0.1.md §6.7]

scene6_guard_8CC0_mir:
        fcb     12,9  ; height=12 rows, coco3_width=9 bytes/row (4px/byte)
        fcb     $00,$00,$00,$00,$00,$3C,$00,$00,$00  ; row 0
        fcb     $00,$00,$00,$00,$03,$FF,$C0,$00,$F0  ; row 1
        fcb     $00,$00,$00,$00,$3F,$FF,$C0,$3F,$F0  ; row 2
        fcb     $00,$00,$00,$00,$FF,$FF,$C0,$FF,$F0  ; row 3
        fcb     $00,$00,$00,$0F,$FF,$FF,$00,$FF,$F0  ; row 4
        fcb     $00,$00,$00,$FF,$FF,$F0,$00,$FF,$C0  ; row 5
        fcb     $00,$00,$0F,$FF,$FF,$00,$03,$FF,$C0  ; row 6
        fcb     $00,$00,$FF,$FF,$F0,$00,$03,$FF,$C0  ; row 7
        fcb     $08,$0A,$FF,$FF,$00,$00,$03,$FF,$00  ; row 8
        fcb     $0A,$AA,$FF,$F0,$00,$00,$00,$A8,$00  ; row 9
        fcb     $00,$A8,$0F,$00,$00,$00,$00,$A8,$00  ; row 10
        fcb     $00,$80,$00,$00,$00,$00,$00,$A8,$00  ; row 11
