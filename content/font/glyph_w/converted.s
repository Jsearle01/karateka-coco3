* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: sprite_data_0400.s
*         Apple II label: sprite_05d6
* Color model: adjacency + screen-col parity (MAME-verified, TASK 1/2 gate 2026-05-16).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=119
* [ref: karateka-coco3 docs/karateka-coco3-design-v0.1.md §6.7]

glyph_w_coco3:
        fcb     10,5  ; height=10 rows, coco3_width=5 bytes/row (4px/byte)
        fcb     $00,$00,$00,$00,$00  ; row 0
        fcb     $00,$00,$00,$00,$00  ; row 1
        fcb     $BF,$03,$F0,$03,$C0  ; row 2
        fcb     $0F,$00,$F0,$02,$00  ; row 3
        fcb     $03,$C0,$3C,$04,$00  ; row 4
        fcb     $03,$C0,$FC,$04,$00  ; row 5
        fcb     $00,$F2,$0F,$20,$00  ; row 6
        fcb     $00,$FF,$0F,$F0,$00  ; row 7
        fcb     $00,$3C,$03,$C0,$00  ; row 8
        fcb     $00,$3C,$03,$C0,$00  ; row 9
