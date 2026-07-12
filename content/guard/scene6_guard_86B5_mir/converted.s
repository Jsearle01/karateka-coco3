* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: dump05_imprison.bin
*         Apple II label: addr_86B5
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=0  screen-col parity=EVEN
* [ref: karateka-coco3 docs/project/karateka-coco3-design-v0.1.md §6.7]

scene6_guard_86B5_mir:
        fcb     13,7  ; height=13 rows, coco3_width=7 bytes/row (4px/byte)
        fcb     $0A,$80,$00,$00,$AA,$FC,$00  ; row 0
        fcb     $0A,$80,$00,$FF,$EA,$FF,$C0  ; row 1
        fcb     $00,$80,$0F,$FF,$EA,$FF,$C0  ; row 2
        fcb     $00,$FC,$3F,$FF,$FE,$FF,$C0  ; row 3
        fcb     $03,$FF,$7F,$FF,$FE,$FF,$C0  ; row 4
        fcb     $0F,$FF,$FF,$FF,$FF,$FF,$C0  ; row 5
        fcb     $03,$FF,$FF,$FF,$FF,$FE,$80  ; row 6
        fcb     $00,$3F,$FF,$FF,$FF,$FE,$80  ; row 7
        fcb     $00,$03,$F0,$FF,$FF,$FE,$80  ; row 8
        fcb     $00,$00,$00,$FF,$FF,$FF,$C0  ; row 9
        fcb     $00,$00,$00,$FF,$FF,$FC,$00  ; row 10
        fcb     $00,$00,$00,$FF,$FF,$FC,$00  ; row 11
        fcb     $00,$00,$00,$0F,$FF,$C0,$00  ; row 12
