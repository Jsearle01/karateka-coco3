* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: fight_engine.s
*         Apple II label: broderbund_logo_sprite_2
* Color model: adjacency + screen-col parity (MAME-verified, TASK 1/2 gate 2026-05-16).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=84
* [ref: karateka-coco3 docs/karateka-coco3-design-v0.1.md §6.7]

broderbund_logo_sprite_2_coco3:
        fcb     9,28  ; height=9 rows, coco3_width=28 bytes/row (4px/byte)
        fcb     $00,$FF,$00,$00,$00,$03,$C0,$00,$00,$3C,$00,$00,$00,$00,$0F,$00,$FC,$00,$00,$F0,$00,$00,$00,$00,$00,$00,$00,$00  ; row 0
        fcb     $03,$C3,$C0,$00,$00,$03,$C0,$00,$00,$3C,$00,$00,$00,$00,$0F,$03,$C0,$00,$03,$C3,$C0,$00,$00,$00,$00,$00,$00,$00  ; row 1
        fcb     $03,$C3,$C3,$F7,$C0,$3F,$C3,$F0,$3F,$7F,$C3,$EF,$0F,$C0,$FF,$03,$C0,$0F,$EF,$FF,$F7,$EF,$7C,$3F,$03,$F7,$F0,$00  ; row 2
        fcb     $03,$FF,$0F,$0F,$0A,$F7,$EF,$7E,$F0,$3E,$F7,$EF,$7E,$F7,$EF,$03,$F0,$3E,$F7,$C3,$C3,$EF,$7E,$F7,$EF,$0F,$7C,$00  ; row 3
        fcb     $03,$C3,$EF,$0F,$7E,$F7,$EF,$7E,$F0,$3E,$F7,$EF,$7E,$F7,$EF,$00,$FC,$3E,$F7,$C3,$C3,$EF,$7C,$03,$EF,$0F,$7C,$00  ; row 4
        fcb     $03,$C3,$EF,$0F,$7E,$F7,$EF,$F0,$F0,$3E,$F7,$EF,$7E,$F7,$EF,$00,$3F,$7E,$F7,$C3,$C3,$EF,$7C,$3F,$EF,$0F,$F0,$00  ; row 5
        fcb     $03,$C3,$EF,$0F,$7E,$F7,$EF,$00,$F0,$3E,$F7,$EF,$7E,$F7,$EF,$00,$0F,$7E,$F7,$C3,$C3,$EF,$7E,$F7,$EF,$0F,$00,$00  ; row 6
        fcb     $03,$C3,$EF,$08,$3E,$F7,$EF,$7E,$F0,$3E,$F7,$EF,$7E,$F7,$EF,$00,$0F,$7E,$F7,$C3,$C3,$EF,$7E,$F7,$EF,$0F,$7C,$00  ; row 7
        fcb     $03,$FF,$0F,$00,$F0,$3F,$03,$F0,$F0,$0F,$C0,$FC,$3E,$F0,$FC,$00,$FC,$0F,$C3,$C0,$F0,$F0,$F0,$3F,$EF,$03,$F0,$00  ; row 8
