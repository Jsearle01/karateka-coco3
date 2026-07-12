* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: dump05_imprison.bin
*         Apple II label: addr_8A1E
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=0  screen-col parity=EVEN
* [ref: karateka-coco3 docs/project/karateka-coco3-design-v0.1.md §6.7]

scene6_player_8A1E:
        fcb     23,6  ; height=23 rows, coco3_width=6 bytes/row (4px/byte)
        fcb     $BF,$00,$00,$40,$00,$00  ; row 0
        fcb     $BF,$FC,$03,$C0,$00,$00  ; row 1
        fcb     $BF,$F0,$F0,$F0,$00,$00  ; row 2
        fcb     $BF,$F0,$F0,$F0,$00,$00  ; row 3
        fcb     $0F,$FF,$FF,$FC,$00,$00  ; row 4
        fcb     $0F,$FF,$FF,$FC,$00,$00  ; row 5
        fcb     $0F,$FF,$FF,$FC,$00,$00  ; row 6
        fcb     $0F,$FF,$FF,$FF,$00,$00  ; row 7
        fcb     $BF,$FF,$DF,$FF,$00,$00  ; row 8
        fcb     $BF,$FF,$DF,$FF,$C0,$00  ; row 9
        fcb     $BF,$FF,$03,$FF,$C0,$00  ; row 10
        fcb     $BF,$FF,$03,$FF,$F0,$00  ; row 11
        fcb     $BF,$FC,$00,$FF,$F0,$00  ; row 12
        fcb     $BF,$FC,$00,$FF,$F0,$00  ; row 13
        fcb     $FF,$F0,$00,$3F,$FC,$00  ; row 14
        fcb     $FF,$F0,$00,$3F,$FC,$00  ; row 15
        fcb     $FF,$F0,$00,$0F,$FC,$00  ; row 16
        fcb     $FF,$C0,$00,$0F,$FC,$00  ; row 17
        fcb     $FF,$C0,$00,$00,$40,$00  ; row 18
        fcb     $FF,$C0,$00,$00,$54,$00  ; row 19
        fcb     $40,$00,$00,$00,$55,$40  ; row 20
        fcb     $54,$00,$00,$00,$00,$00  ; row 21
        fcb     $55,$40,$00,$00,$00,$00  ; row 22
