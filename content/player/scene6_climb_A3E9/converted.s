* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: dump05_imprison.bin
*         Apple II label: addr_A3E9
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=0  screen-col parity=EVEN
* [ref: karateka-coco3 docs/project/karateka-coco3-design-v0.1.md §6.7]

scene6_climb_A3E9:
        fcb     8,6  ; height=8 rows, coco3_width=6 bytes/row (4px/byte)
        fcb     $3C,$00,$00,$0F,$FE,$A8  ; row 0
        fcb     $3F,$F0,$00,$03,$FC,$15  ; row 1
        fcb     $FF,$FF,$C0,$00,$F0,$A8  ; row 2
        fcb     $FF,$FF,$C0,$00,$0A,$81  ; row 3
        fcb     $FF,$FF,$C0,$0A,$AA,$A8  ; row 4
        fcb     $FF,$FF,$C0,$15,$55,$55  ; row 5
        fcb     $FF,$FF,$EA,$AA,$AA,$A8  ; row 6
        fcb     $FF,$55,$55,$55,$55,$55  ; row 7
