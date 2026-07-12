* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: dump05_imprison.bin
*         Apple II label: addr_84A0
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=0  screen-col parity=EVEN
* [ref: karateka-coco3 docs/project/karateka-coco3-design-v0.1.md §6.7]

scene6_player_84A0:
        fcb     20,5  ; height=20 rows, coco3_width=5 bytes/row (4px/byte)
        fcb     $00,$20,$00,$00,$00  ; row 0
        fcb     $00,$3C,$00,$00,$40  ; row 1
        fcb     $00,$FF,$C2,$0F,$C0  ; row 2
        fcb     $00,$FF,$0F,$C3,$C0  ; row 3
        fcb     $03,$FF,$0F,$C3,$C0  ; row 4
        fcb     $03,$FF,$FF,$FF,$C0  ; row 5
        fcb     $0F,$FF,$C3,$FF,$C0  ; row 6
        fcb     $0F,$FF,$03,$FF,$C0  ; row 7
        fcb     $0F,$FF,$03,$FF,$C0  ; row 8
        fcb     $3F,$FC,$03,$FF,$C0  ; row 9
        fcb     $3F,$FC,$03,$FF,$C0  ; row 10
        fcb     $3F,$FF,$03,$FF,$C0  ; row 11
        fcb     $0F,$FF,$03,$FF,$C0  ; row 12
        fcb     $0F,$FF,$C3,$FF,$00  ; row 13
        fcb     $03,$FF,$C3,$FF,$00  ; row 14
        fcb     $00,$FD,$43,$FF,$00  ; row 15
        fcb     $00,$05,$40,$FF,$00  ; row 16
        fcb     $00,$05,$40,$04,$00  ; row 17
        fcb     $00,$04,$00,$55,$40  ; row 18
        fcb     $00,$00,$00,$05,$40  ; row 19
