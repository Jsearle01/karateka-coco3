* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: dump05_imprison.bin (by address)
*         Apple II label: addr_16CC
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=0
* [ref: karateka-coco3 docs/karateka-coco3-design-v0.1.md §6.7]

fig_16CC_coco3:
        fcb     36,7  ; height=36 rows, coco3_width=7 bytes/row (4px/byte)
        fcb     $00,$00,$0F,$FC,$00,$00,$00  ; row 0
        fcb     $00,$00,$FF,$FF,$00,$00,$00  ; row 1
        fcb     $00,$00,$FF,$FF,$C0,$00,$00  ; row 2
        fcb     $00,$00,$03,$FF,$C0,$00,$00  ; row 3
        fcb     $00,$00,$15,$7F,$C0,$00,$00  ; row 4
        fcb     $00,$00,$15,$7F,$F0,$00,$00  ; row 5
        fcb     $00,$00,$15,$7F,$F0,$00,$00  ; row 6
        fcb     $00,$00,$01,$7F,$F0,$00,$00  ; row 7
        fcb     $00,$00,$15,$7F,$FC,$00,$00  ; row 8
        fcb     $00,$01,$7F,$F7,$FC,$00,$00  ; row 9
        fcb     $00,$01,$7F,$F1,$7C,$00,$00  ; row 10
        fcb     $00,$01,$7F,$FF,$10,$00,$00  ; row 11
        fcb     $00,$15,$7F,$FF,$15,$00,$00  ; row 12
        fcb     $00,$10,$03,$FF,$F1,$00,$00  ; row 13
        fcb     $00,$10,$00,$3F,$F1,$50,$00  ; row 14
        fcb     $00,$15,$00,$3F,$C0,$10,$00  ; row 15
        fcb     $00,$01,$00,$3F,$F0,$10,$00  ; row 16
        fcb     $00,$00,$00,$3F,$FC,$00,$00  ; row 17
        fcb     $00,$00,$00,$FF,$FC,$00,$00  ; row 18
        fcb     $00,$00,$03,$FF,$FC,$00,$00  ; row 19
        fcb     $00,$00,$0F,$FF,$FC,$00,$00  ; row 20
        fcb     $00,$00,$3F,$FF,$F0,$00,$00  ; row 21
        fcb     $00,$00,$3F,$FF,$F0,$00,$00  ; row 22
        fcb     $00,$00,$FF,$FF,$C0,$00,$00  ; row 23
        fcb     $00,$03,$FF,$FF,$00,$00,$00  ; row 24
        fcb     $00,$03,$FF,$F0,$00,$00,$00  ; row 25
        fcb     $00,$0F,$FF,$F0,$00,$00,$00  ; row 26
        fcb     $00,$0F,$FF,$F0,$00,$00,$00  ; row 27
        fcb     $00,$03,$FF,$FF,$00,$00,$00  ; row 28
        fcb     $00,$00,$FF,$FF,$C0,$00,$00  ; row 29
        fcb     $00,$00,$FF,$FF,$F0,$00,$00  ; row 30
        fcb     $AA,$A8,$3F,$FF,$FC,$AA,$A8  ; row 31
        fcb     $00,$00,$3F,$EF,$FF,$00,$00  ; row 32
        fcb     $AA,$AA,$AF,$F7,$FF,$CA,$A8  ; row 33
        fcb     $00,$00,$0F,$F0,$3F,$F0,$00  ; row 34
        fcb     $AA,$81,$50,$01,$50,$00,$00  ; row 35
