* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: dump05_imprison.bin
*         Apple II label: addr_83A8
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=0  screen-col parity=EVEN
* [ref: karateka-coco3 docs/project/karateka-coco3-design-v0.1.md §6.7]

scene6_player_83A8:
        fcb     13,7  ; height=13 rows, coco3_width=7 bytes/row (4px/byte)
        fcb     $00,$0F,$55,$00,$00,$01,$50  ; row 0
        fcb     $00,$FF,$F7,$FF,$00,$01,$50  ; row 1
        fcb     $03,$FF,$F7,$FF,$F0,$01,$00  ; row 2
        fcb     $03,$FF,$FF,$F7,$FC,$3F,$00  ; row 3
        fcb     $03,$FF,$FF,$57,$FE,$FF,$C0  ; row 4
        fcb     $03,$FF,$FF,$57,$FF,$FF,$F0  ; row 5
        fcb     $03,$FF,$FF,$7F,$FF,$FF,$C0  ; row 6
        fcb     $00,$FF,$FF,$FF,$FF,$FC,$00  ; row 7
        fcb     $00,$FF,$FF,$FF,$0F,$C0,$00  ; row 8
        fcb     $00,$FF,$FF,$FF,$00,$00,$00  ; row 9
        fcb     $00,$0F,$FF,$FF,$00,$00,$00  ; row 10
        fcb     $00,$3F,$FF,$FF,$00,$00,$00  ; row 11
        fcb     $00,$03,$FF,$F0,$00,$00,$00  ; row 12
