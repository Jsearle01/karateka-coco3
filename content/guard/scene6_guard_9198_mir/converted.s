* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: dump05_imprison.bin
*         Apple II label: addr_9198
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=0  screen-col parity=EVEN
* [ref: karateka-coco3 docs/project/karateka-coco3-design-v0.1.md §6.7]

scene6_guard_9198_mir:
        fcb     10,11  ; height=10 rows, coco3_width=11 bytes/row (4px/byte)
        fcb     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$C0,$FF,$FF,$F0  ; row 0
        fcb     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$C0,$FF,$FF,$F0  ; row 1
        fcb     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$F0,$FF,$FF,$F0  ; row 2
        fcb     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$F0  ; row 3
        fcb     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$F0  ; row 4
        fcb     $FF,$E8,$0A,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$F0  ; row 5
        fcb     $FF,$0A,$AA,$FF,$FF,$F0,$00,$00,$A8,$03,$F0  ; row 6
        fcb     $FF,$C0,$A8,$0F,$00,$00,$00,$00,$A8,$00,$F0  ; row 7
        fcb     $FF,$F0,$80,$00,$00,$00,$00,$00,$A8,$00,$10  ; row 8
        fcb     $FC,$00,$00,$00,$00,$00,$00,$00,$00,$0F,$F0  ; row 9
