* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: dump05_imprison.bin
*         Apple II label: addr_A4A4
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=0  screen-col parity=EVEN
* [ref: karateka-coco3 docs/project/karateka-coco3-design-v0.1.md §6.7]

scene6_climb_A4A4:
        fcb     22,4  ; height=22 rows, coco3_width=4 bytes/row (4px/byte)
        fcb     $55,$55,$40,$F0  ; row 0
        fcb     $00,$00,$F0,$20  ; row 1
        fcb     $55,$5F,$FF,$00  ; row 2
        fcb     $00,$3F,$FF,$C0  ; row 3
        fcb     $55,$FF,$FF,$C0  ; row 4
        fcb     $00,$FF,$FF,$F0  ; row 5
        fcb     $55,$FF,$FF,$F0  ; row 6
        fcb     $00,$FF,$FF,$F0  ; row 7
        fcb     $55,$FF,$FF,$F0  ; row 8
        fcb     $2A,$BF,$F0,$00  ; row 9
        fcb     $55,$5F,$FF,$00  ; row 10
        fcb     $2A,$0F,$FF,$A0  ; row 11
        fcb     $55,$5F,$FF,$00  ; row 12
        fcb     $2A,$AB,$FF,$00  ; row 13
        fcb     $55,$43,$FF,$00  ; row 14
        fcb     $00,$03,$FF,$00  ; row 15
        fcb     $00,$0F,$FC,$00  ; row 16
        fcb     $00,$0F,$FC,$00  ; row 17
        fcb     $00,$0F,$FC,$00  ; row 18
        fcb     $00,$3F,$FA,$A0  ; row 19
        fcb     $00,$3F,$D5,$40  ; row 20
        fcb     $00,$3F,$AA,$A0  ; row 21
