* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: dump05_imprison.bin
*         Apple II label: addr_A4A4
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=70  screen-col parity=EVEN
* [ref: karateka-coco3 docs/project/karateka-coco3-design-v0.1.md §6.7]

scene6_climb_A4A4:
        fcb     22,4  ; height=22 rows, coco3_width=4 bytes/row (4px/byte)
        fcb     $AA,$AA,$80,$F0  ; row 0
        fcb     $00,$00,$F0,$10  ; row 1
        fcb     $AA,$AF,$FF,$00  ; row 2
        fcb     $00,$3F,$FF,$C0  ; row 3
        fcb     $AA,$FF,$FF,$C0  ; row 4
        fcb     $00,$FF,$FF,$F0  ; row 5
        fcb     $AA,$FF,$FF,$F0  ; row 6
        fcb     $00,$FF,$FF,$F0  ; row 7
        fcb     $AA,$FF,$FF,$F0  ; row 8
        fcb     $15,$7F,$F0,$00  ; row 9
        fcb     $AA,$AF,$FF,$00  ; row 10
        fcb     $15,$0F,$FF,$50  ; row 11
        fcb     $AA,$AF,$FF,$00  ; row 12
        fcb     $15,$57,$FF,$00  ; row 13
        fcb     $AA,$83,$FF,$00  ; row 14
        fcb     $00,$03,$FF,$00  ; row 15
        fcb     $00,$0F,$FC,$00  ; row 16
        fcb     $00,$0F,$FC,$00  ; row 17
        fcb     $00,$0F,$FC,$00  ; row 18
        fcb     $00,$3F,$F5,$50  ; row 19
        fcb     $00,$3F,$EA,$80  ; row 20
        fcb     $00,$3F,$55,$50  ; row 21
