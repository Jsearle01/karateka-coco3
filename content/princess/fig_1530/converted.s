* converted.s
* CoCo3 sprite data � converted from Apple II source.
*
* ORIGIN: dump05_imprison.bin (by address)
*         Apple II label: addr_1530
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=0
* [ref: karateka-coco3 docs/karateka-coco3-design-v0.1.md �6.7]

fig_1530_coco3:
        fcb     43,4  ; height=43 rows, coco3_width=4 bytes/row (4px/byte)
        fcb     $03,$FF,$C0,$00  ; row 0
        fcb     $0F,$FF,$FC,$00  ; row 1
        fcb     $BF,$FF,$FC,$00  ; row 2
        fcb     $BF,$FC,$00,$00  ; row 3
        fcb     $BF,$C5,$40,$00  ; row 4
        fcb     $BF,$C5,$40,$00  ; row 5
        fcb     $BF,$C5,$40,$00  ; row 6
        fcb     $FF,$C4,$00,$00  ; row 7
        fcb     $FC,$54,$00,$00  ; row 8
        fcb     $FC,$5F,$00,$00  ; row 9
        fcb     $FC,$5F,$C0,$00  ; row 10
        fcb     $FC,$5F,$F0,$00  ; row 11
        fcb     $FC,$5F,$F0,$00  ; row 12
        fcb     $FC,$5F,$C0,$00  ; row 13
        fcb     $BC,$5F,$00,$00  ; row 14
        fcb     $20,$5F,$00,$00  ; row 15
        fcb     $00,$5F,$00,$00  ; row 16
        fcb     $00,$5F,$00,$00  ; row 17
        fcb     $03,$DF,$00,$00  ; row 18
        fcb     $0F,$DF,$00,$00  ; row 19
        fcb     $BF,$DF,$00,$00  ; row 20
        fcb     $BC,$5F,$00,$00  ; row 21
        fcb     $BC,$5F,$00,$00  ; row 22
        fcb     $05,$FF,$00,$00  ; row 23
        fcb     $00,$FF,$00,$00  ; row 24
        fcb     $03,$FF,$00,$00  ; row 25
        fcb     $03,$FF,$00,$00  ; row 26
        fcb     $03,$FF,$00,$00  ; row 27
        fcb     $03,$FF,$00,$00  ; row 28
        fcb     $03,$FF,$00,$00  ; row 29
        fcb     $03,$FF,$00,$00  ; row 30
        fcb     $03,$FF,$00,$00  ; row 31
        fcb     $0F,$FF,$00,$00  ; row 32
        fcb     $0F,$FF,$00,$00  ; row 33
        fcb     $0F,$FF,$00,$00  ; row 34
        fcb     $0F,$FF,$00,$00  ; row 35
        fcb     $0F,$FF,$00,$00  ; row 36
        fcb     $0F,$FF,$00,$00  ; row 37
        fcb     $BF,$FF,$2A,$A0  ; row 38
        fcb     $BF,$FF,$00,$00  ; row 39
        fcb     $BF,$FF,$2A,$A0  ; row 40
        fcb     $BF,$FF,$00,$00  ; row 41
        fcb     $FF,$C5,$40,$00  ; row 42
