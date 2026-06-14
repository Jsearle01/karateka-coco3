* converted.s
* CoCo3 sprite data � converted from Apple II source.
*
* ORIGIN: dump05_imprison.bin (by address)
*         Apple II label: addr_1D00
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=0
* [ref: karateka-coco3 docs/karateka-coco3-design-v0.1.md �6.7]

fig_1D00_coco3:
        fcb     26,4  ; height=26 rows, coco3_width=4 bytes/row (4px/byte)
        fcb     $00,$0F,$F0,$00  ; row 0
        fcb     $00,$3F,$FC,$00  ; row 1
        fcb     $00,$FF,$FF,$00  ; row 2
        fcb     $03,$FF,$FF,$C0  ; row 3
        fcb     $0F,$FC,$54,$00  ; row 4
        fcb     $BF,$FC,$40,$00  ; row 5
        fcb     $BF,$C5,$40,$00  ; row 6
        fcb     $BF,$C4,$00,$00  ; row 7
        fcb     $FC,$54,$00,$00  ; row 8
        fcb     $FC,$5F,$00,$00  ; row 9
        fcb     $FC,$5F,$C0,$00  ; row 10
        fcb     $FC,$5F,$F0,$00  ; row 11
        fcb     $FC,$5F,$F0,$00  ; row 12
        fcb     $BC,$5F,$C0,$00  ; row 13
        fcb     $BC,$5F,$00,$00  ; row 14
        fcb     $00,$5F,$00,$00  ; row 15
        fcb     $00,$54,$00,$00  ; row 16
        fcb     $00,$54,$00,$00  ; row 17
        fcb     $03,$C5,$40,$00  ; row 18
        fcb     $0F,$FC,$40,$00  ; row 19
        fcb     $BF,$FC,$40,$00  ; row 20
        fcb     $BF,$FF,$00,$00  ; row 21
        fcb     $BF,$FF,$00,$00  ; row 22
        fcb     $0F,$FF,$C0,$00  ; row 23
        fcb     $03,$FF,$C0,$00  ; row 24
        fcb     $03,$FF,$C0,$00  ; row 25
