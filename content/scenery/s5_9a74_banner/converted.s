* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: sprite_data.s
*         Apple II label: sprite_9a74
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=120
* [ref: karateka-coco3 docs/karateka-coco3-design-v0.1.md §6.7]

s5_9a74_banner_coco3:
        fcb     10,17  ; height=10 rows, coco3_width=17 bytes/row (4px/byte)
        fcb     $00,$08,$00,$FC,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ; row 0
        fcb     $00,$3C,$08,$3C,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$10,$00  ; row 1
        fcb     $0F,$FF,$FC,$3C,$00,$00,$FF,$C0,$00,$00,$3F,$F0,$FC,$3F,$00,$FC,$00  ; row 2
        fcb     $08,$3C,$00,$3E,$FF,$01,$00,$F0,$00,$00,$80,$3C,$3F,$C3,$C0,$3F,$00  ; row 3
        fcb     $00,$3C,$00,$3F,$03,$EF,$00,$00,$00,$03,$C0,$00,$3C,$03,$C0,$AF,$C0  ; row 4
        fcb     $00,$3C,$00,$3C,$03,$EF,$FF,$00,$00,$03,$FF,$C0,$3C,$03,$C1,$03,$F0  ; row 5
        fcb     $00,$3C,$00,$3C,$03,$EF,$00,$00,$00,$03,$C0,$00,$3C,$03,$EF,$00,$F0  ; row 6
        fcb     $00,$3C,$00,$3C,$03,$EF,$00,$00,$00,$03,$C0,$00,$3C,$03,$EF,$00,$F0  ; row 7
        fcb     $00,$3C,$3C,$3C,$0F,$03,$C0,$F0,$00,$00,$F0,$3C,$3C,$0F,$03,$C0,$F0  ; row 8
        fcb     $00,$0F,$F0,$3C,$0F,$C0,$FF,$C0,$00,$00,$3F,$F0,$3C,$0F,$C0,$FF,$00  ; row 9
