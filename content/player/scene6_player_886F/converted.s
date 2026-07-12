* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: dump05_imprison.bin
*         Apple II label: addr_886F
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=0  screen-col parity=EVEN
* [ref: karateka-coco3 docs/project/karateka-coco3-design-v0.1.md §6.7]

scene6_player_886F:
        fcb     14,9  ; height=14 rows, coco3_width=9 bytes/row (4px/byte)
        fcb     $00,$00,$3F,$D4,$00,$00,$00,$00,$00  ; row 0
        fcb     $00,$0F,$FF,$D5,$FF,$F0,$00,$00,$00  ; row 1
        fcb     $00,$3F,$FF,$FD,$FF,$FF,$FF,$D5,$54  ; row 2
        fcb     $00,$FF,$FF,$FD,$FF,$FF,$FF,$C0,$54  ; row 3
        fcb     $03,$FF,$FF,$FD,$FF,$FF,$FF,$C0,$00  ; row 4
        fcb     $0F,$FF,$FD,$5F,$FF,$00,$00,$00,$00  ; row 5
        fcb     $0F,$FF,$D5,$5F,$FF,$00,$00,$00,$00  ; row 6
        fcb     $0F,$FF,$D5,$5F,$FF,$00,$00,$00,$00  ; row 7
        fcb     $03,$FF,$FF,$FF,$FF,$00,$00,$00,$00  ; row 8
        fcb     $00,$FF,$FF,$FF,$FC,$00,$00,$00,$00  ; row 9
        fcb     $00,$3D,$FF,$FF,$FC,$00,$00,$00,$00  ; row 10
        fcb     $00,$00,$FF,$FF,$FC,$00,$00,$00,$00  ; row 11
        fcb     $00,$00,$FF,$FF,$FC,$00,$00,$00,$00  ; row 12
        fcb     $00,$00,$3F,$FF,$C0,$00,$00,$00,$00  ; row 13
