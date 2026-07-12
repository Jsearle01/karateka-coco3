* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: dump05_imprison.bin
*         Apple II label: addr_85F3
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=0  screen-col parity=EVEN
* [ref: karateka-coco3 docs/project/karateka-coco3-design-v0.1.md §6.7]

scene6_guard_85F3_mir:
        fcb     19,9  ; height=19 rows, coco3_width=9 bytes/row (4px/byte)
        fcb     $00,$00,$00,$00,$00,$3C,$00,$00,$00  ; row 0
        fcb     $00,$00,$00,$03,$FF,$FC,$00,$00,$00  ; row 1
        fcb     $00,$00,$00,$F0,$3F,$FF,$00,$00,$00  ; row 2
        fcb     $00,$00,$10,$FC,$3F,$FF,$00,$00,$00  ; row 3
        fcb     $00,$00,$FF,$FF,$FF,$FF,$C0,$00,$00  ; row 4
        fcb     $00,$03,$FF,$FF,$FF,$FF,$C0,$00,$00  ; row 5
        fcb     $00,$0F,$FF,$F0,$3F,$FF,$F0,$00,$00  ; row 6
        fcb     $00,$0F,$FF,$C0,$0F,$FF,$F0,$00,$00  ; row 7
        fcb     $00,$3F,$FF,$00,$03,$FF,$FC,$00,$00  ; row 8
        fcb     $00,$3F,$FC,$00,$00,$FF,$FF,$00,$00  ; row 9
        fcb     $00,$FF,$F0,$00,$00,$3F,$FF,$C0,$00  ; row 10
        fcb     $00,$FF,$F0,$00,$00,$0F,$FF,$F0,$00  ; row 11
        fcb     $03,$FF,$C0,$00,$00,$00,$FF,$F0,$00  ; row 12
        fcb     $03,$FF,$C0,$00,$00,$00,$3F,$FC,$00  ; row 13
        fcb     $0F,$FF,$00,$00,$00,$00,$0F,$FF,$00  ; row 14
        fcb     $0F,$FF,$00,$00,$00,$00,$03,$FF,$C0  ; row 15
        fcb     $00,$80,$00,$00,$00,$00,$00,$FE,$80  ; row 16
        fcb     $0A,$80,$00,$00,$00,$00,$00,$00,$A8  ; row 17
        fcb     $AA,$80,$00,$00,$00,$00,$00,$00,$A8  ; row 18
