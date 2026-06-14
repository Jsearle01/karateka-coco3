* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: dump05_imprison.bin (by address)
*         Apple II label: addr_1588
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=0
* [ref: karateka-coco3 docs/karateka-coco3-design-v0.1.md §6.7]

fig_1588_coco3:
        fcb     43,6  ; height=43 rows, coco3_width=6 bytes/row (4px/byte)
        fcb     $00,$00,$03,$FF,$00,$00  ; row 0
        fcb     $00,$00,$0F,$FF,$C0,$00  ; row 1
        fcb     $00,$00,$3F,$FF,$C0,$00  ; row 2
        fcb     $00,$00,$3C,$03,$C0,$00  ; row 3
        fcb     $00,$00,$3F,$17,$C0,$00  ; row 4
        fcb     $00,$00,$3F,$17,$C0,$00  ; row 5
        fcb     $00,$00,$0F,$17,$C0,$00  ; row 6
        fcb     $00,$00,$0F,$17,$C0,$00  ; row 7
        fcb     $00,$00,$0F,$17,$C0,$00  ; row 8
        fcb     $00,$00,$3F,$15,$50,$00  ; row 9
        fcb     $00,$01,$7F,$FF,$10,$00  ; row 10
        fcb     $00,$01,$7F,$FF,$10,$00  ; row 11
        fcb     $00,$01,$7F,$FF,$10,$00  ; row 12
        fcb     $00,$01,$7F,$FF,$10,$00  ; row 13
        fcb     $00,$01,$7F,$FF,$10,$00  ; row 14
        fcb     $00,$01,$57,$FF,$10,$00  ; row 15
        fcb     $00,$01,$57,$FF,$10,$00  ; row 16
        fcb     $00,$15,$0F,$F1,$50,$00  ; row 17
        fcb     $00,$10,$0F,$F1,$00,$00  ; row 18
        fcb     $00,$00,$3F,$FF,$00,$00  ; row 19
        fcb     $00,$00,$3F,$FF,$C0,$00  ; row 20
        fcb     $00,$00,$3F,$FF,$C0,$00  ; row 21
        fcb     $00,$00,$3F,$FF,$C0,$00  ; row 22
        fcb     $00,$00,$3F,$FF,$C0,$00  ; row 23
        fcb     $00,$00,$3F,$FF,$C0,$00  ; row 24
        fcb     $00,$00,$3F,$FF,$00,$00  ; row 25
        fcb     $00,$00,$3F,$FF,$00,$00  ; row 26
        fcb     $00,$00,$3F,$FF,$00,$00  ; row 27
        fcb     $00,$00,$3F,$FF,$00,$00  ; row 28
        fcb     $00,$00,$3F,$FF,$00,$00  ; row 29
        fcb     $00,$00,$3F,$FF,$00,$00  ; row 30
        fcb     $00,$00,$3F,$FF,$00,$00  ; row 31
        fcb     $00,$00,$3F,$FF,$00,$00  ; row 32
        fcb     $00,$00,$3F,$FF,$00,$00  ; row 33
        fcb     $00,$00,$3F,$FF,$C0,$00  ; row 34
        fcb     $00,$00,$3F,$FF,$C0,$00  ; row 35
        fcb     $00,$00,$FF,$FF,$C0,$00  ; row 36
        fcb     $00,$00,$FF,$FF,$C0,$00  ; row 37
        fcb     $AA,$AA,$FF,$7F,$CA,$80  ; row 38
        fcb     $00,$03,$FF,$7F,$C0,$00  ; row 39
        fcb     $AA,$AF,$FF,$0F,$F0,$80  ; row 40
        fcb     $00,$0F,$FC,$0F,$F0,$00  ; row 41
        fcb     $AA,$81,$50,$01,$50,$00  ; row 42
