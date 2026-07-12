* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: dump05_imprison.bin
*         Apple II label: addr_8E0F
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=0  screen-col parity=EVEN
* [ref: karateka-coco3 docs/project/karateka-coco3-design-v0.1.md §6.7]

scene6_guard_8E0F_mir:
        fcb     8,7  ; height=8 rows, coco3_width=7 bytes/row (4px/byte)
        fcb     $00,$00,$00,$3F,$F0,$00,$F0  ; row 0
        fcb     $00,$00,$0F,$FF,$F0,$0F,$FE  ; row 1
        fcb     $0A,$80,$FF,$FF,$FF,$EF,$FF  ; row 2
        fcb     $0A,$AF,$FF,$EA,$FF,$FF,$FF  ; row 3
        fcb     $00,$AF,$FF,$EA,$AF,$FF,$FF  ; row 4
        fcb     $00,$0F,$FC,$0A,$AF,$FF,$FF  ; row 5
        fcb     $00,$0F,$C0,$3F,$FF,$FF,$FE  ; row 6
        fcb     $00,$00,$00,$00,$FF,$FC,$00  ; row 7
