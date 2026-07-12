* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: dump05_imprison.bin
*         Apple II label: addr_8C6A
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=0  screen-col parity=EVEN
* [ref: karateka-coco3 docs/project/karateka-coco3-design-v0.1.md §6.7]

scene6_guard_8C6A_mir:
        fcb     14,9  ; height=14 rows, coco3_width=9 bytes/row (4px/byte)
        fcb     $00,$00,$00,$00,$03,$F0,$00,$0F,$C0  ; row 0
        fcb     $00,$00,$00,$00,$3F,$FC,$10,$FF,$F0  ; row 1
        fcb     $00,$00,$00,$00,$FF,$F0,$F0,$FF,$FC  ; row 2
        fcb     $00,$00,$00,$0F,$FF,$F0,$F0,$FF,$FF  ; row 3
        fcb     $00,$00,$00,$3F,$FF,$FC,$03,$FF,$FF  ; row 4
        fcb     $00,$00,$00,$FF,$FF,$C0,$00,$FF,$FC  ; row 5
        fcb     $00,$00,$03,$FF,$FC,$00,$00,$3F,$FC  ; row 6
        fcb     $00,$00,$0F,$FF,$F0,$00,$00,$3F,$F0  ; row 7
        fcb     $00,$00,$3F,$FF,$00,$00,$00,$3F,$F0  ; row 8
        fcb     $00,$00,$FF,$FC,$00,$00,$00,$3F,$C0  ; row 9
        fcb     $00,$03,$FF,$F0,$00,$00,$00,$3F,$C0  ; row 10
        fcb     $00,$0A,$FF,$C0,$00,$00,$00,$0A,$80  ; row 11
        fcb     $00,$A8,$3F,$00,$00,$00,$00,$0A,$A8  ; row 12
        fcb     $0A,$80,$00,$00,$00,$00,$00,$00,$A8  ; row 13
