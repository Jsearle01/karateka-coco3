* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: dump05_imprison.bin
*         Apple II label: addr_A572
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=0  screen-col parity=EVEN
* [ref: karateka-coco3 docs/project/karateka-coco3-design-v0.1.md §6.7]

scene6_climb_A572:
        fcb     22,7  ; height=22 rows, coco3_width=7 bytes/row (4px/byte)
        fcb     $AA,$AF,$FF,$FE,$FF,$F0,$00  ; row 0
        fcb     $00,$0F,$FF,$FE,$FF,$FC,$00  ; row 1
        fcb     $AA,$AF,$FF,$FF,$EF,$FC,$00  ; row 2
        fcb     $00,$0F,$FF,$FF,$0F,$FC,$00  ; row 3
        fcb     $AA,$AA,$FF,$FF,$EF,$FC,$00  ; row 4
        fcb     $00,$00,$FF,$FF,$F7,$FC,$00  ; row 5
        fcb     $AA,$A8,$0F,$FF,$FF,$FC,$00  ; row 6
        fcb     $00,$00,$00,$FF,$FF,$FC,$00  ; row 7
        fcb     $AA,$AA,$80,$0F,$FF,$FC,$00  ; row 8
        fcb     $00,$00,$00,$00,$FF,$FC,$00  ; row 9
        fcb     $AA,$AA,$80,$03,$FF,$FC,$00  ; row 10
        fcb     $15,$55,$00,$0F,$FF,$F0,$00  ; row 11
        fcb     $AA,$AA,$AA,$FF,$FF,$C0,$A8  ; row 12
        fcb     $15,$55,$57,$FF,$FF,$F5,$55  ; row 13
        fcb     $AA,$AA,$AF,$FF,$FF,$C0,$A8  ; row 14
        fcb     $15,$55,$01,$7F,$FF,$55,$55  ; row 15
        fcb     $AA,$AA,$81,$7F,$FF,$EA,$A8  ; row 16
        fcb     $00,$15,$50,$03,$FF,$55,$55  ; row 17
        fcb     $00,$00,$AA,$81,$0A,$AA,$A8  ; row 18
        fcb     $00,$00,$15,$01,$50,$00,$01  ; row 19
        fcb     $00,$00,$08,$01,$55,$00,$00  ; row 20
        fcb     $00,$00,$15,$00,$00,$00,$01  ; row 21
