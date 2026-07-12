* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: dump05_imprison.bin
*         Apple II label: addr_A4D2
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=0  screen-col parity=EVEN
* [ref: karateka-coco3 docs/project/karateka-coco3-design-v0.1.md §6.7]

scene6_climb_A4D2:
        fcb     6,9  ; height=6 rows, coco3_width=9 bytes/row (4px/byte)
        fcb     $20,$00,$00,$0F,$FF,$FF,$C0,$00,$00  ; row 0
        fcb     $00,$00,$0F,$FF,$FF,$FF,$FC,$00,$00  ; row 1
        fcb     $20,$03,$FF,$FF,$FF,$FF,$FF,$D5,$40  ; row 2
        fcb     $00,$0F,$FF,$FF,$FD,$40,$FF,$05,$40  ; row 3
        fcb     $20,$03,$FF,$FF,$D5,$40,$00,$00,$40  ; row 4
        fcb     $2B,$C0,$FF,$FF,$D5,$40,$00,$00,$00  ; row 5
