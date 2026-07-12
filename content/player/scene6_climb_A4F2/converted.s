* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: dump05_imprison.bin
*         Apple II label: addr_A4F2
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=0  screen-col parity=EVEN
* [ref: karateka-coco3 docs/project/karateka-coco3-design-v0.1.md §6.7]

scene6_climb_A4F2:
        fcb     21,7  ; height=21 rows, coco3_width=7 bytes/row (4px/byte)
        fcb     $AA,$AA,$FF,$F0,$FF,$FC,$00  ; row 0
        fcb     $00,$00,$FF,$FE,$FF,$F0,$00  ; row 1
        fcb     $AA,$AF,$FF,$FC,$3F,$F0,$00  ; row 2
        fcb     $00,$0F,$FF,$FF,$FF,$C0,$00  ; row 3
        fcb     $AA,$AF,$FF,$FF,$FF,$00,$00  ; row 4
        fcb     $00,$0F,$FF,$FF,$FF,$C0,$00  ; row 5
        fcb     $AA,$AF,$FF,$FF,$FF,$FC,$00  ; row 6
        fcb     $00,$03,$FF,$FF,$FF,$FC,$00  ; row 7
        fcb     $AA,$AA,$FF,$F0,$FF,$FC,$00  ; row 8
        fcb     $15,$55,$7F,$FC,$0F,$FC,$00  ; row 9
        fcb     $AA,$AA,$AF,$FF,$7F,$FE,$A8  ; row 10
        fcb     $15,$55,$57,$FF,$7F,$F5,$55  ; row 11
        fcb     $AA,$AA,$AA,$FF,$FF,$FE,$A8  ; row 12
        fcb     $15,$55,$57,$FF,$FF,$F5,$55  ; row 13
        fcb     $AA,$AA,$AF,$FF,$FF,$FE,$A8  ; row 14
        fcb     $00,$15,$7F,$FE,$FF,$F5,$55  ; row 15
        fcb     $00,$00,$FF,$F5,$00,$AA,$A8  ; row 16
        fcb     $00,$03,$FF,$F5,$50,$00,$01  ; row 17
        fcb     $00,$03,$FF,$C1,$55,$00,$00  ; row 18
        fcb     $00,$01,$7F,$00,$00,$00,$01  ; row 19
        fcb     $00,$01,$0A,$AA,$AA,$AA,$A8  ; row 20
