* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: dump05_imprison.bin
*         Apple II label: addr_A548
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=0  screen-col parity=EVEN
* [ref: karateka-coco3 docs/project/karateka-coco3-design-v0.1.md §6.7]

scene6_climb_A548:
        fcb     10,7  ; height=10 rows, coco3_width=7 bytes/row (4px/byte)
        fcb     $20,$00,$00,$0F,$FF,$F0,$00  ; row 0
        fcb     $00,$00,$00,$0F,$FF,$D4,$00  ; row 1
        fcb     $20,$00,$00,$FF,$FF,$D5,$40  ; row 2
        fcb     $00,$00,$3F,$FF,$F0,$05,$40  ; row 3
        fcb     $20,$0F,$FF,$FF,$FD,$40,$00  ; row 4
        fcb     $00,$FF,$FF,$FF,$FD,$40,$00  ; row 5
        fcb     $20,$0F,$FF,$FF,$F0,$00,$00  ; row 6
        fcb     $04,$03,$FF,$FF,$F0,$00,$00  ; row 7
        fcb     $BF,$C0,$FF,$FF,$C0,$00,$00  ; row 8
        fcb     $BF,$FD,$FF,$FF,$00,$00,$00  ; row 9
