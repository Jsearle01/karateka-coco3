* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: dump05_imprison.bin
*         Apple II label: addr_8557
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=0  screen-col parity=EVEN
* [ref: karateka-coco3 docs/project/karateka-coco3-design-v0.1.md §6.7]

scene6_player_8557:
        fcb     19,6  ; height=19 rows, coco3_width=6 bytes/row (4px/byte)
        fcb     $00,$3C,$00,$00,$F0,$00  ; row 0
        fcb     $00,$3F,$C2,$0F,$F0,$00  ; row 1
        fcb     $00,$FF,$0F,$C3,$FC,$00  ; row 2
        fcb     $03,$FF,$0F,$C3,$FC,$00  ; row 3
        fcb     $03,$FF,$FF,$FF,$FF,$00  ; row 4
        fcb     $0F,$FF,$F0,$3F,$FF,$00  ; row 5
        fcb     $0F,$FF,$C0,$0F,$FF,$C0  ; row 6
        fcb     $0F,$FF,$00,$0F,$FF,$C0  ; row 7
        fcb     $BF,$FF,$00,$03,$FF,$C0  ; row 8
        fcb     $BF,$FC,$00,$03,$FF,$C0  ; row 9
        fcb     $BF,$FC,$00,$00,$FF,$C0  ; row 10
        fcb     $BF,$FC,$00,$00,$FF,$C0  ; row 11
        fcb     $0F,$FC,$00,$00,$FF,$C0  ; row 12
        fcb     $0F,$FC,$00,$00,$FF,$00  ; row 13
        fcb     $0F,$FC,$00,$00,$FF,$00  ; row 14
        fcb     $0F,$FC,$00,$00,$FF,$00  ; row 15
        fcb     $00,$40,$00,$00,$04,$00  ; row 16
        fcb     $05,$40,$00,$00,$05,$40  ; row 17
        fcb     $05,$40,$00,$00,$05,$40  ; row 18
