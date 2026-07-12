* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: dump05_imprison.bin
*         Apple II label: addr_80DF
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=0  screen-col parity=EVEN
* [ref: karateka-coco3 docs/project/karateka-coco3-design-v0.1.md §6.7]

scene6_guard_80DF_mir:
        fcb     23,9  ; height=23 rows, coco3_width=9 bytes/row (4px/byte)
        fcb     $00,$00,$00,$00,$3F,$FC,$3F,$00,$00  ; row 0
        fcb     $00,$00,$00,$03,$FF,$FF,$FC,$3C,$00  ; row 1
        fcb     $00,$00,$00,$3F,$FF,$FF,$FC,$3F,$C0  ; row 2
        fcb     $00,$00,$03,$FF,$FF,$FF,$FF,$FF,$C0  ; row 3
        fcb     $00,$00,$3F,$FF,$FF,$F0,$0F,$FF,$C0  ; row 4
        fcb     $00,$03,$FF,$FF,$F0,$00,$0F,$FF,$C0  ; row 5
        fcb     $00,$3F,$FF,$FC,$00,$00,$0F,$FF,$C0  ; row 6
        fcb     $00,$FF,$FF,$C0,$00,$00,$0F,$FF,$C0  ; row 7
        fcb     $0A,$AF,$FC,$00,$00,$00,$0F,$FF,$C0  ; row 8
        fcb     $AA,$83,$C0,$00,$00,$00,$0F,$FF,$C0  ; row 9
        fcb     $A8,$00,$00,$00,$00,$00,$0F,$FF,$00  ; row 10
        fcb     $80,$00,$00,$00,$00,$00,$0F,$FF,$00  ; row 11
        fcb     $00,$00,$00,$00,$00,$00,$3F,$FF,$00  ; row 12
        fcb     $00,$00,$00,$00,$00,$00,$3F,$FF,$00  ; row 13
        fcb     $00,$00,$00,$00,$00,$00,$3F,$FF,$00  ; row 14
        fcb     $00,$00,$00,$00,$00,$00,$3F,$FC,$00  ; row 15
        fcb     $00,$00,$00,$00,$00,$00,$3F,$FC,$00  ; row 16
        fcb     $00,$00,$00,$00,$00,$00,$3F,$FC,$00  ; row 17
        fcb     $00,$00,$00,$00,$00,$00,$3F,$F0,$00  ; row 18
        fcb     $00,$00,$00,$00,$00,$00,$0F,$F0,$00  ; row 19
        fcb     $00,$00,$00,$00,$00,$00,$0A,$80,$00  ; row 20
        fcb     $00,$00,$00,$00,$00,$00,$0A,$80,$00  ; row 21
        fcb     $00,$00,$00,$00,$00,$00,$0A,$A8,$00  ; row 22
