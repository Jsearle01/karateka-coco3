* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: dump05_imprison.bin
*         Apple II label: addr_89CE
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=0  screen-col parity=EVEN
* [ref: karateka-coco3 docs/project/karateka-coco3-design-v0.1.md §6.7]

scene6_guard_89CE_mir:
        fcb     26,4  ; height=26 rows, coco3_width=4 bytes/row (4px/byte)
        fcb     $03,$FF,$FF,$F0  ; row 0
        fcb     $03,$C0,$3F,$F0  ; row 1
        fcb     $02,$00,$2B,$FC  ; row 2
        fcb     $02,$BF,$AB,$FC  ; row 3
        fcb     $02,$BF,$AB,$FC  ; row 4
        fcb     $00,$FF,$BF,$FC  ; row 5
        fcb     $00,$FF,$FF,$FC  ; row 6
        fcb     $00,$FF,$FF,$F0  ; row 7
        fcb     $03,$FF,$FF,$F0  ; row 8
        fcb     $03,$FF,$FF,$F0  ; row 9
        fcb     $03,$FF,$FF,$F0  ; row 10
        fcb     $03,$FF,$FF,$F0  ; row 11
        fcb     $03,$FF,$FF,$F0  ; row 12
        fcb     $03,$FF,$FF,$F0  ; row 13
        fcb     $03,$FF,$FF,$FC  ; row 14
        fcb     $03,$FF,$FF,$FC  ; row 15
        fcb     $03,$FF,$FF,$FC  ; row 16
        fcb     $00,$FF,$FF,$FC  ; row 17
        fcb     $00,$FF,$FF,$FC  ; row 18
        fcb     $00,$FF,$FF,$FC  ; row 19
        fcb     $00,$FF,$BF,$FC  ; row 20
        fcb     $00,$2A,$BF,$FC  ; row 21
        fcb     $00,$2A,$BF,$FC  ; row 22
        fcb     $02,$A0,$00,$20  ; row 23
        fcb     $00,$00,$02,$A0  ; row 24
        fcb     $00,$00,$2A,$A0  ; row 25
