* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: dump05_imprison.bin
*         Apple II label: addr_8519
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=0  screen-col parity=EVEN
* [ref: karateka-coco3 docs/project/karateka-coco3-design-v0.1.md §6.7]

scene6_guard_8519_mir:
        fcb     20,5  ; height=20 rows, coco3_width=5 bytes/row (4px/byte)
        fcb     $00,$00,$00,$00,$08  ; row 0
        fcb     $00,$00,$F0,$00,$3C  ; row 1
        fcb     $00,$00,$FC,$10,$FC  ; row 2
        fcb     $00,$00,$10,$FC,$10  ; row 3
        fcb     $00,$00,$10,$FC,$10  ; row 4
        fcb     $00,$00,$3F,$FF,$F0  ; row 5
        fcb     $00,$00,$3F,$FF,$F0  ; row 6
        fcb     $00,$00,$3F,$FF,$F0  ; row 7
        fcb     $00,$00,$3F,$FF,$F0  ; row 8
        fcb     $00,$00,$0F,$FF,$C0  ; row 9
        fcb     $00,$00,$0F,$FF,$C0  ; row 10
        fcb     $00,$00,$3F,$FF,$C0  ; row 11
        fcb     $00,$00,$FF,$FF,$C0  ; row 12
        fcb     $00,$0F,$FF,$FF,$C0  ; row 13
        fcb     $00,$3F,$FF,$FF,$F0  ; row 14
        fcb     $00,$FF,$FF,$7F,$F0  ; row 15
        fcb     $0A,$AF,$F0,$0F,$F0  ; row 16
        fcb     $0A,$80,$00,$03,$C0  ; row 17
        fcb     $00,$80,$00,$0A,$A8  ; row 18
        fcb     $00,$A8,$00,$0A,$80  ; row 19
