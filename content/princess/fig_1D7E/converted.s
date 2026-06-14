* converted.s
* CoCo3 sprite data � converted from Apple II source.
*
* ORIGIN: dump05_imprison.bin (by address)
*         Apple II label: addr_1D7E
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=0
* [ref: karateka-coco3 docs/karateka-coco3-design-v0.1.md �6.7]

fig_1D7E_coco3:
        fcb     17,4  ; height=17 rows, coco3_width=4 bytes/row (4px/byte)
        fcb     $03,$FF,$F0,$00  ; row 0
        fcb     $03,$FF,$F0,$00  ; row 1
        fcb     $03,$FF,$F0,$00  ; row 2
        fcb     $03,$FF,$FC,$00  ; row 3
        fcb     $0F,$FF,$FC,$00  ; row 4
        fcb     $0F,$FF,$FC,$00  ; row 5
        fcb     $0F,$FF,$FC,$00  ; row 6
        fcb     $0F,$FF,$FC,$00  ; row 7
        fcb     $0F,$FF,$FC,$00  ; row 8
        fcb     $0F,$FF,$FC,$00  ; row 9
        fcb     $0F,$FF,$FF,$00  ; row 10
        fcb     $0F,$FF,$FF,$00  ; row 11
        fcb     $0F,$FF,$FF,$00  ; row 12
        fcb     $BF,$FF,$FF,$00  ; row 13
        fcb     $BF,$FF,$FC,$40  ; row 14
        fcb     $BF,$F0,$54,$00  ; row 15
        fcb     $05,$54,$00,$00  ; row 16
