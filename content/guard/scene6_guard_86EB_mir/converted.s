* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: dump05_imprison.bin
*         Apple II label: addr_86EB
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=0  screen-col parity=EVEN
* [ref: karateka-coco3 docs/project/karateka-coco3-design-v0.1.md §6.7]

scene6_guard_86EB_mir:
        fcb     13,4  ; height=13 rows, coco3_width=4 bytes/row (4px/byte)
        fcb     $00,$00,$3F,$F0  ; row 0
        fcb     $00,$03,$FF,$FC  ; row 1
        fcb     $00,$0F,$FF,$FC  ; row 2
        fcb     $00,$0F,$FF,$FF  ; row 3
        fcb     $02,$AB,$FF,$FF  ; row 4
        fcb     $02,$AA,$BF,$FF  ; row 5
        fcb     $00,$2A,$BF,$FF  ; row 6
        fcb     $00,$3F,$FF,$FF  ; row 7
        fcb     $00,$0F,$FF,$FF  ; row 8
        fcb     $00,$0F,$FF,$FC  ; row 9
        fcb     $00,$0F,$FF,$FC  ; row 10
        fcb     $00,$0F,$FF,$FC  ; row 11
        fcb     $00,$0F,$FF,$C0  ; row 12
