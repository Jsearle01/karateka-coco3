* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: dump05_imprison.bin
*         Apple II label: addr_9490
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=0  screen-col parity=EVEN
* [ref: karateka-coco3 docs/project/karateka-coco3-design-v0.1.md §6.7]

scene6_player_9490:
        fcb     21,7  ; height=21 rows, coco3_width=7 bytes/row (4px/byte)
        fcb     $FF,$FF,$FF,$FF,$FD,$FF,$FF  ; row 0
        fcb     $FF,$FF,$BF,$FF,$F0,$FF,$FF  ; row 1
        fcb     $FF,$FF,$03,$FF,$C0,$FF,$FF  ; row 2
        fcb     $FF,$FF,$C0,$3F,$05,$FF,$FF  ; row 3
        fcb     $FF,$FF,$D4,$04,$05,$FF,$FF  ; row 4
        fcb     $FF,$FF,$D5,$40,$54,$00,$00  ; row 5
        fcb     $FF,$FF,$C0,$55,$54,$05,$42  ; row 6
        fcb     $FF,$F0,$00,$55,$55,$54,$0F  ; row 7
        fcb     $FC,$05,$55,$5F,$DF,$C0,$3F  ; row 8
        fcb     $FF,$00,$5F,$DF,$FD,$43,$FF  ; row 9
        fcb     $FF,$F0,$05,$FF,$FD,$40,$FF  ; row 10
        fcb     $FF,$FF,$00,$FF,$FF,$D4,$0F  ; row 11
        fcb     $FF,$FF,$05,$5F,$D5,$55,$42  ; row 12
        fcb     $FF,$FC,$05,$5F,$D4,$00,$00  ; row 13
        fcb     $FF,$F0,$40,$05,$54,$3F,$FF  ; row 14
        fcb     $FF,$C0,$02,$04,$04,$0F,$FF  ; row 15
        fcb     $FF,$03,$FF,$05,$40,$43,$FF  ; row 16
        fcb     $FF,$FF,$FF,$05,$FC,$00,$FF  ; row 17
        fcb     $FF,$FF,$FF,$C0,$FF,$FC,$3F  ; row 18
        fcb     $FF,$FF,$FF,$C0,$FF,$FF,$FF  ; row 19
        fcb     $FF,$FF,$FF,$C3,$FF,$FF,$FF  ; row 20
