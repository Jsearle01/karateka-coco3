* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: sprite_data_0400.s
*         Apple II label: sprite_051e
* Color model: adjacency + screen-col parity (MAME-verified, TASK 1/2 gate 2026-05-16).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=119
* [ref: karateka-coco3 docs/karateka-coco3-design-v0.1.md §6.7]

glyph_o_coco3:
        fcb     10,3  ; height=10 rows, coco3_width=3 bytes/row (4px/byte)
        fcb     $00,$00,$00  ; row 0
        fcb     $00,$00,$00  ; row 1
        fcb     $03,$FC,$00  ; row 2
        fcb     $04,$0F,$C0  ; row 3
        fcb     $BC,$03,$F0  ; row 4
        fcb     $BC,$00,$F0  ; row 5
        fcb     $BC,$00,$F0  ; row 6
        fcb     $BF,$00,$F0  ; row 7
        fcb     $0F,$C0,$40  ; row 8
        fcb     $00,$FF,$00  ; row 9
