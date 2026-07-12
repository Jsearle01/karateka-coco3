* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: dump05_imprison.bin
*         Apple II label: addr_8372
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=0  screen-col parity=EVEN
* [ref: karateka-coco3 docs/project/karateka-coco3-design-v0.1.md §6.7]

scene6_guard_8372_mir:
        fcb     13,7  ; height=13 rows, coco3_width=7 bytes/row (4px/byte)
        fcb     $00,$00,$00,$FF,$EA,$FF,$00  ; row 0
        fcb     $00,$00,$0F,$FF,$FF,$FF,$C0  ; row 1
        fcb     $00,$03,$FF,$FE,$FF,$FF,$F0  ; row 2
        fcb     $AA,$FF,$FF,$FE,$AF,$FF,$F0  ; row 3
        fcb     $AA,$FF,$FF,$FE,$AF,$FF,$F0  ; row 4
        fcb     $00,$FF,$FE,$FF,$EF,$FF,$F0  ; row 5
        fcb     $00,$FF,$C0,$FF,$FF,$FF,$F0  ; row 6
        fcb     $00,$00,$00,$FF,$FF,$FF,$C0  ; row 7
        fcb     $00,$00,$03,$FF,$FF,$FF,$C0  ; row 8
        fcb     $00,$00,$03,$FF,$FF,$C0,$00  ; row 9
        fcb     $00,$00,$0F,$FF,$FF,$C0,$00  ; row 10
        fcb     $00,$00,$03,$FF,$FF,$00,$00  ; row 11
        fcb     $00,$00,$00,$FF,$C0,$00,$00  ; row 12
