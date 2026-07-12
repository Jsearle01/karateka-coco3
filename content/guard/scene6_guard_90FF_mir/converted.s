* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: dump05_imprison.bin
*         Apple II label: addr_90FF
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=0  screen-col parity=EVEN
* [ref: karateka-coco3 docs/project/karateka-coco3-design-v0.1.md §6.7]

scene6_guard_90FF_mir:
        fcb     7,6  ; height=7 rows, coco3_width=6 bytes/row (4px/byte)
        fcb     $FF,$FF,$BF,$FF,$FF,$C0  ; row 0
        fcb     $FC,$2A,$BF,$FF,$FF,$C0  ; row 1
        fcb     $F0,$2A,$BF,$FF,$FF,$C0  ; row 2
        fcb     $42,$A0,$00,$20,$FF,$C0  ; row 3
        fcb     $00,$00,$02,$A0,$3F,$C0  ; row 4
        fcb     $40,$00,$2A,$A0,$0F,$C0  ; row 5
        fcb     $FF,$F0,$00,$03,$FF,$C0  ; row 6
