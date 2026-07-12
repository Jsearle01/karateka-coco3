* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: dump05_imprison.bin
*         Apple II label: addr_A45A
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=0  screen-col parity=EVEN
* [ref: karateka-coco3 docs/project/karateka-coco3-design-v0.1.md §6.7]

scene6_climb_A45A:
        fcb     24,6  ; height=24 rows, coco3_width=6 bytes/row (4px/byte)
        fcb     $00,$03,$FF,$C0,$00,$00  ; row 0
        fcb     $00,$0F,$FF,$00,$00,$00  ; row 1
        fcb     $00,$0F,$F5,$00,$00,$00  ; row 2
        fcb     $FF,$FF,$50,$00,$00,$00  ; row 3
        fcb     $FF,$FF,$55,$00,$00,$00  ; row 4
        fcb     $FF,$FF,$F5,$00,$00,$00  ; row 5
        fcb     $FF,$FF,$F5,$00,$00,$00  ; row 6
        fcb     $FF,$FF,$FC,$00,$00,$00  ; row 7
        fcb     $FF,$C3,$FF,$00,$00,$00  ; row 8
        fcb     $FF,$C0,$FF,$C0,$00,$00  ; row 9
        fcb     $FF,$FC,$3F,$F0,$00,$00  ; row 10
        fcb     $FF,$FC,$0F,$F0,$00,$00  ; row 11
        fcb     $FF,$FC,$0F,$FC,$00,$00  ; row 12
        fcb     $7F,$FC,$03,$FF,$00,$00  ; row 13
        fcb     $7F,$FE,$AA,$FF,$EA,$80  ; row 14
        fcb     $7F,$F5,$55,$7F,$55,$00  ; row 15
        fcb     $7F,$FE,$A8,$15,$0A,$80  ; row 16
        fcb     $FF,$F5,$55,$55,$55,$00  ; row 17
        fcb     $FF,$EA,$AA,$81,$0A,$80  ; row 18
        fcb     $FF,$F5,$55,$55,$55,$00  ; row 19
        fcb     $10,$AA,$AA,$AA,$AA,$80  ; row 20
        fcb     $15,$00,$00,$01,$55,$00  ; row 21
        fcb     $15,$50,$00,$00,$AA,$80  ; row 22
        fcb     $00,$00,$00,$01,$55,$00  ; row 23
