* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: dump05_imprison.bin
*         Apple II label: addr_804D
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=0  screen-col parity=EVEN
* [ref: karateka-coco3 docs/project/karateka-coco3-design-v0.1.md §6.7]

scene6_guard_804D_mir:
        fcb     25,6  ; height=25 rows, coco3_width=6 bytes/row (4px/byte)
        fcb     $00,$0F,$C3,$FF,$FF,$C0  ; row 0
        fcb     $03,$FF,$F0,$FF,$FF,$80  ; row 1
        fcb     $FF,$FC,$00,$0F,$F0,$00  ; row 2
        fcb     $FF,$FC,$0F,$00,$00,$00  ; row 3
        fcb     $FF,$FF,$FC,$20,$00,$00  ; row 4
        fcb     $FF,$F0,$FC,$3F,$C0,$00  ; row 5
        fcb     $3F,$F0,$FC,$3F,$C0,$00  ; row 6
        fcb     $3F,$A0,$FF,$FF,$00,$00  ; row 7
        fcb     $2A,$A0,$3F,$FF,$00,$00  ; row 8
        fcb     $2A,$00,$3F,$FF,$00,$00  ; row 9
        fcb     $00,$00,$3F,$FF,$00,$00  ; row 10
        fcb     $00,$00,$3F,$FF,$00,$00  ; row 11
        fcb     $00,$00,$3F,$FC,$00,$00  ; row 12
        fcb     $00,$00,$3F,$FC,$00,$00  ; row 13
        fcb     $00,$00,$3F,$FC,$00,$00  ; row 14
        fcb     $00,$00,$3F,$FC,$00,$00  ; row 15
        fcb     $00,$00,$FF,$F0,$00,$00  ; row 16
        fcb     $00,$00,$FF,$F0,$00,$00  ; row 17
        fcb     $00,$00,$FF,$F0,$00,$00  ; row 18
        fcb     $00,$00,$FF,$C0,$00,$00  ; row 19
        fcb     $00,$00,$FF,$C0,$00,$00  ; row 20
        fcb     $00,$00,$3F,$00,$00,$00  ; row 21
        fcb     $00,$00,$2A,$00,$00,$00  ; row 22
        fcb     $00,$00,$2A,$00,$00,$00  ; row 23
        fcb     $00,$00,$02,$A0,$00,$00  ; row 24
