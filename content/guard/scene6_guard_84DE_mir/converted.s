* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: dump05_imprison.bin
*         Apple II label: addr_84DE
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=0  screen-col parity=EVEN
* [ref: karateka-coco3 docs/project/karateka-coco3-design-v0.1.md §6.7]

scene6_guard_84DE_mir:
        fcb     19,4  ; height=19 rows, coco3_width=4 bytes/row (4px/byte)
        fcb     $00,$20,$00,$04  ; row 0
        fcb     $00,$3C,$20,$FC  ; row 1
        fcb     $00,$20,$FC,$3C  ; row 2
        fcb     $00,$20,$FC,$3C  ; row 3
        fcb     $00,$3F,$FF,$FC  ; row 4
        fcb     $00,$3F,$FF,$FC  ; row 5
        fcb     $00,$3F,$FF,$F0  ; row 6
        fcb     $00,$3F,$FF,$F0  ; row 7
        fcb     $00,$3F,$FF,$F0  ; row 8
        fcb     $00,$FF,$FF,$F0  ; row 9
        fcb     $00,$FF,$FF,$F0  ; row 10
        fcb     $00,$FF,$FF,$F0  ; row 11
        fcb     $2B,$FF,$FF,$00  ; row 12
        fcb     $2A,$BF,$FF,$00  ; row 13
        fcb     $2A,$03,$FF,$00  ; row 14
        fcb     $20,$00,$FC,$00  ; row 15
        fcb     $20,$00,$20,$00  ; row 16
        fcb     $00,$02,$AA,$00  ; row 17
        fcb     $00,$02,$A0,$00  ; row 18
