* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: dump05_imprison.bin
*         Apple II label: addr_8B0F
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=0  screen-col parity=EVEN
* [ref: karateka-coco3 docs/project/karateka-coco3-design-v0.1.md §6.7]

scene6_player_8B0F:
        fcb     13,5  ; height=13 rows, coco3_width=5 bytes/row (4px/byte)
        fcb     $03,$D5,$40,$00,$00  ; row 0
        fcb     $0F,$FD,$F0,$00,$00  ; row 1
        fcb     $BF,$FF,$FC,$00,$00  ; row 2
        fcb     $BF,$FF,$FF,$00,$00  ; row 3
        fcb     $BF,$FF,$FF,$00,$00  ; row 4
        fcb     $BF,$FF,$FF,$C0,$00  ; row 5
        fcb     $BF,$FF,$FF,$C0,$00  ; row 6
        fcb     $BF,$FF,$FF,$F0,$00  ; row 7
        fcb     $0F,$FF,$FF,$FC,$00  ; row 8
        fcb     $0F,$FD,$55,$FD,$54  ; row 9
        fcb     $0F,$FD,$55,$FD,$54  ; row 10
        fcb     $0F,$FF,$D5,$FC,$00  ; row 11
        fcb     $00,$0F,$FF,$00,$00  ; row 12
