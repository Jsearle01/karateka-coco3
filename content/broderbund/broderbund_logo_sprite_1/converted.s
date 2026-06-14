* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: fight_engine.s
*         Apple II label: broderbund_logo_sprite_1
* Color model: adjacency + screen-col parity (MAME-verified, TASK 1/2 gate 2026-05-16).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=119
* [ref: karateka-coco3 docs/karateka-coco3-design-v0.1.md §6.7]

broderbund_logo_sprite_1_coco3:
        fcb     14,9  ; height=14 rows, coco3_width=9 bytes/row (4px/byte)
        fcb     $00,$00,$00,$20,$00,$00,$02,$00,$00  ; row 0
        fcb     $00,$00,$00,$FC,$00,$00,$0F,$C0,$00  ; row 1
        fcb     $00,$00,$FC,$20,$FC,$0F,$C2,$0F,$C0  ; row 2
        fcb     $00,$03,$C3,$FF,$0F,$BC,$3F,$F0,$F0  ; row 3
        fcb     $00,$00,$F0,$00,$3C,$0F,$00,$03,$C0  ; row 4
        fcb     $00,$00,$20,$00,$20,$02,$00,$02,$00  ; row 5
        fcb     $00,$00,$3C,$00,$F0,$43,$C0,$0F,$00  ; row 6
        fcb     $00,$00,$0F,$FC,$43,$F0,$5F,$FC,$00  ; row 7
        fcb     $00,$00,$00,$05,$F0,$43,$C4,$00,$00  ; row 8
        fcb     $00,$00,$00,$0F,$0F,$FC,$3C,$00,$00  ; row 9
        fcb     $00,$00,$00,$03,$C0,$00,$F0,$00,$00  ; row 10
        fcb     $00,$00,$00,$00,$40,$00,$40,$00,$00  ; row 11
        fcb     $00,$00,$00,$00,$F0,$03,$C0,$00,$00  ; row 12
        fcb     $00,$00,$00,$00,$3F,$FF,$00,$00,$00  ; row 13
