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

scene6_guard_8A1E_mir:
        fcb     23,6  ; height=23 rows, coco3_width=6 bytes/row (4px/byte)
        fcb     $00,$00,$80,$00,$3F,$40  ; row 0
        fcb     $00,$00,$F0,$0F,$FF,$40  ; row 1
        fcb     $00,$03,$C3,$C3,$FF,$40  ; row 2
        fcb     $00,$03,$C3,$C3,$FF,$40  ; row 3
        fcb     $00,$0F,$FF,$FF,$FC,$00  ; row 4
        fcb     $00,$0F,$FF,$FF,$FC,$00  ; row 5
        fcb     $00,$0F,$FF,$FF,$FC,$00  ; row 6
        fcb     $00,$3F,$FF,$FF,$FC,$00  ; row 7
        fcb     $00,$3F,$FE,$FF,$FF,$40  ; row 8
        fcb     $00,$FF,$FE,$FF,$FF,$40  ; row 9
        fcb     $00,$FF,$F0,$3F,$FF,$40  ; row 10
        fcb     $03,$FF,$F0,$3F,$FF,$40  ; row 11
        fcb     $03,$FF,$C0,$0F,$FF,$40  ; row 12
        fcb     $03,$FF,$C0,$0F,$FF,$40  ; row 13
        fcb     $0F,$FF,$00,$03,$FF,$C0  ; row 14
        fcb     $0F,$FF,$00,$03,$FF,$C0  ; row 15
        fcb     $0F,$FC,$00,$03,$FF,$C0  ; row 16
        fcb     $0F,$FC,$00,$00,$FF,$C0  ; row 17
        fcb     $00,$80,$00,$00,$FF,$C0  ; row 18
        fcb     $0A,$80,$00,$00,$FF,$C0  ; row 19
        fcb     $AA,$80,$00,$00,$00,$80  ; row 20
        fcb     $00,$00,$00,$00,$0A,$80  ; row 21
        fcb     $00,$00,$00,$00,$AA,$80  ; row 22
